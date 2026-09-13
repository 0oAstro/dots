#!/usr/bin/env python3
"""Real-PTY smoke tests. Never execute a selected completion or read user history."""
import base64
import fcntl
import os
import pty
import re
import select
import shutil
import signal
import struct
import tempfile
import termios
import time

ANSI = re.compile(rb"\x1b(?:\[[0-?]*[ -/]*[@-~]|\][^\x07\x1b]*(?:\x07|\x1b\\))")


class Shell:
    def __init__(self, cwd, **env):
        self.pid, self.fd = pty.fork()
        if self.pid == 0:
            os.chdir(cwd)
            # Do not report test pane state into a real Herdr workspace.
            for key in list(os.environ):
                if key.startswith("HERDR_"):
                    del os.environ[key]
            os.environ.update(TERM="xterm-256color", **env)
            os.execv(shutil.which("zsh"), ["zsh", "-il"])
        fcntl.ioctl(self.fd, termios.TIOCSWINSZ, struct.pack("HHHH", 38, 140, 0, 0))
        self.output = b""
        startup = self.drain(0.8)
        if re.search(rb'parse error|invalid function definition|unmatched [\'\"]', startup):
            self.close()
            raise AssertionError(f"shell startup error: {startup[-3000:]!r}")
        self.run(" unset HISTFILE; SAVEHIST=0; fc -p /dev/null; "
                 "_zdots_test_buffer() { local encoded=$(print -rn -- \"$BUFFER\" | base64 | tr -d '\\n'); print -r -- \"ZDTEST<$encoded>\"; BUFFER=; zle redisplay; }; "
                 "zle -N _zdots_test_buffer; bindkey '^X^G' _zdots_test_buffer; "
                 "_zdots_test_line_ready() { if [[ ${_zdots_test_command_pending:-0} == 1 ]]; then unset _zdots_test_command_pending; print; print -r -- ZD_COMMAND_READY; fi; }; "
                 "autoload -Uz add-zle-hook-widget; add-zle-hook-widget line-init _zdots_test_line_ready; "
                 "functions[_fzf_completion_post]+=$'\\nprint -rn -- ZD_COMPLETION_DONE > /dev/tty'; print ZD_READY")
        self.expect(b"\r\nZD_READY\r\n")

    def send(self, data):
        os.write(self.fd, data if isinstance(data, bytes) else data.encode())

    def paste(self, code):
        self.send(b"\x1b[200~" + code.encode() + b"\x1b[201~")

    def run(self, code):
        self.output = b""
        self.paste(code + "; typeset -g _zdots_test_command_pending=1")
        self.send(b"\r")
        self.expect(b"\r\nZD_COMMAND_READY\r\n")

    def drain(self, duration=0.2, until=None):
        deadline = time.monotonic() + duration
        while time.monotonic() < deadline:
            ready, _, _ = select.select([self.fd], [], [], max(0, deadline-time.monotonic()))
            if not ready:
                break
            try:
                data = os.read(self.fd, 65536)
            except OSError:
                break
            # Answer cursor queries like a terminal, not a pipe.
            for _ in range(data.count(b"\x1b[6n")):
                self.send(b"\x1b[1;1R")
            for _ in range(data.count(b"\x1b[?2004$p")):
                self.send(b"\x1b[?2004;2$y")
            self.output += data
            if until is not None and until(ANSI.sub(b"", self.output)):
                break
        return ANSI.sub(b"", self.output)

    def expect(self, needle, timeout=8):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            clean = self.drain(deadline - time.monotonic(),
                               until=lambda output: needle in output)
            if needle in clean:
                return clean
        raise AssertionError(f"missing {needle!r}: {clean[-2200:]!r}")

    def matching_candidates(self):
        deadline = time.monotonic() + 8
        while time.monotonic() < deadline:
            clean = self.drain(deadline - time.monotonic(), until=lambda output:
                               re.search(rb'(?<![0-9])[1-9][0-9]*/[1-9][0-9]*', output))
            if re.search(rb'(?<![0-9])[1-9][0-9]*/[1-9][0-9]*', clean):
                return
        raise AssertionError(f"no matching candidates: {clean[-1000:]!r}")

    def buffer(self):
        self.output = b""
        self.send(b"\x18\x07")
        self.expect(b"ZDTEST<")
        clean = self.drain(0.2)
        match = re.search(rb'ZDTEST<([A-Za-z0-9+/=]*)>', clean)
        assert match, clean[-1200:]
        return base64.b64decode(match[1]).decode()

    def complete(self, line, query, expected):
        self.output = b""
        self.paste(line)
        started = time.monotonic()
        self.send(b"\t")
        self.expect(b"complete")
        latency = time.monotonic() - started
        self.output = b""
        self.send(query)
        self.matching_candidates()
        self.drain(0.2)
        self.send(b"\r")
        self.expect(b"ZD_COMPLETION_DONE")
        self.drain(0.1)
        selection = ANSI.sub(b"", self.output)
        result = self.buffer()
        assert result.startswith(expected), (line, query, result, expected, selection[-500:])
        print(f"PASS Tab ({latency * 1000:.0f} ms): {line!r} -> {result!r}", flush=True)

    def close(self):
        # The shell may be inside a picker; SIGTERM targets only this test shell.
        os.kill(self.pid, signal.SIGTERM)
        os.close(self.fd)
        os.waitpid(self.pid, 0)


def main():
    with tempfile.TemporaryDirectory(prefix="zdots-zle-") as fixture:
        for name in ("alpha one.txt", "alpha'two.txt", "alpha\\three.txt", "beta.txt"):
            with open(os.path.join(fixture, name), "w") as f:
                f.write("preview fixture\n")
        os.mkdir(os.path.join(fixture, "alpha dir"))
        os.mkdir(os.path.join(fixture, "beta dir"))
        shell = Shell(fixture)
        try:
            shell.complete("herdr ", "workspace", "herdr workspace")
            shell.complete("mise ", "activate", "mise activate")
            shell.complete("uv ", "sync", "uv sync")
            shell.complete("eza --", "icons", "eza --icons")
            shell.complete("bun ", "install", "bun install")
            shell.complete("cat alpha", "one", "cat alpha\\ one.txt")
            shell.complete("cat alpha", "two", "cat alpha\\'two.txt")
            shell.complete("cat alpha", "three", "cat alpha\\\\three.txt")
            # Exercise pre-quoted provider candidates as well as native zsh.
            shell.run("compdef _carapace_completer cat; print ZD_CARAPACE")
            shell.expect(b"\r\nZD_CARAPACE\r\n")
            shell.complete("cat alpha", "one", "cat alpha\\ one.txt")
            shell.complete("cat alpha", "two", "cat alpha\\'two.txt")
            shell.complete("cat alpha", "three", "cat alpha\\\\three.txt")

            shell.output = b""
            shell.paste("cat alpha")
            shell.send(b"\t")
            shell.expect(b"complete")
            shell.send(b"\x03")
            shell.drain(0.3)
            assert shell.buffer() == "cat alpha"
            print("PASS completion cancellation preserves input", flush=True)

            shell.run("print -s -- $'printf synthetic_history_first\\nprintf synthetic_history_second'; print ZD_SEEDED")
            shell.expect(b"\r\nZD_SEEDED\r\n")
            shell.output = b""
            shell.send(b"\x12")
            shell.expect(b"history")
            shell.send("synhisfirst")
            shell.drain(0.25)
            shell.send(b"\r")
            shell.drain(0.3)
            result = shell.buffer()
            assert "synthetic_history_first" in result and "synthetic_history_second" in result, result
            print("PASS fuzzy history and multiline preservation", flush=True)

            shell.output = b""
            shell.paste("cat ")
            shell.send(b"\x14")
            shell.expect(b"files")
            shell.send("beta.txt")
            shell.drain(0.25)
            shell.expect(b"preview fixture")
            shell.send(b"\r")
            shell.drain(0.3)
            assert shell.buffer() == "cat beta.txt "
            print("PASS native Ctrl-T and always-visible preview", flush=True)

            shell.output = b""
            shell.send(b"\x1bc")
            shell.expect(b"directories")
            shell.send("alpha dir")
            shell.drain(0.25)
            shell.send(b"\r")
            shell.drain(0.4)
            shell.run("print -r -- ZD_CWD:$PWD")
            shell.expect(("ZD_CWD:" + os.path.realpath(fixture) + "/alpha dir").encode())
            print("PASS native Alt-C and directory preview", flush=True)
        finally:
            shell.close()


if __name__ == "__main__":
    main()
