#!/usr/bin/env python3
"""Hyperfine target: fresh login shell through its first editable prompt.

Usage: hyperfine --warmup 3 --runs 20 'python3 tests/startup.py'
An optional argument selects another ZDOTDIR for before/after comparisons.
Includes harness overhead; does not type commands or write shell history.
"""
import fcntl
import os
from pathlib import Path
import pty
import select
import signal
import struct
import sys
import tempfile
import termios
import time

root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]
shell = "/opt/homebrew/bin/zsh" if Path("/opt/homebrew/bin/zsh").exists() else "/bin/zsh"
env = os.environ.copy()
for key in list(env):
    if key.startswith(("MISE_", "__MISE_", "HERDR_", "P9K_", "_P9K_")):
        del env[key]
env.update(PATH=f"{Path.home()}/.local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin",
           TERM="xterm-256color", COLORTERM="truecolor", BENCH_ZDOTDIR=str(root))
env.pop("NO_COLOR", None)

with tempfile.TemporaryDirectory(prefix="zsh-startup-") as fixture:
    env.update(ZDOTDIR=fixture, BENCH_STARTUP=fixture)
    setup = 'export ZDOTDIR=$BENCH_ZDOTDIR\n'
    restore = '\nexport ZDOTDIR=$BENCH_STARTUP\n'
    Path(fixture, ".zshenv").write_text(setup + 'source "$ZDOTDIR/.zshenv"' + restore)
    Path(fixture, ".zprofile").write_text(setup +
        '[[ ! -r "$ZDOTDIR/.zprofile" ]] || source "$ZDOTDIR/.zprofile"' + restore)
    Path(fixture, ".zshrc").write_text(setup + '''source "$ZDOTDIR/.zshrc"
unset HISTFILE
SAVEHIST=0
autoload -Uz add-zle-hook-widget
_bench_ready() { print; print -r -- ZD_BENCH_READY; }
add-zle-hook-widget line-init _bench_ready
''')
    pid, fd = pty.fork()
    if pid == 0:
        # Keep cwd stable across runs; only the startup wrapper is temporary.
        os.chdir(tempfile.gettempdir())
        os.execve(shell, ["zsh", "-il"], env)
    fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", 38, 140, 0, 0))
    output = b""
    deadline = time.monotonic() + 15
    try:
        while time.monotonic() < deadline:
            if not select.select([fd], [], [], max(0, deadline-time.monotonic()))[0]:
                break
            try:
                data = os.read(fd, 65536)
            except OSError:
                break
            output += data
            if b"\r\nZD_BENCH_READY\r\n" in output:
                break
            for _ in range(data.count(b"\x1b[6n")):
                os.write(fd, b"\x1b[1;1R")
            for _ in range(data.count(b"\x1b[?2004$p")):
                os.write(fd, b"\x1b[?2004;2$y")
        if b"\r\nZD_BENCH_READY\r\n" not in output:
            raise RuntimeError("shell did not reach its first editable prompt")
    finally:
        # Only this disposable test shell; interactive zsh can ignore SIGTERM.
        try:
            os.kill(pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        os.waitpid(pid, 0)
        os.close(fd)
