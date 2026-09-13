#!/usr/bin/env python3
"""Exercise automatic invalidation with disposable tools, never real installs."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]

SCRIPT = r'''
setopt err_return no_aliases
export XDG_CACHE_HOME=$2/cache XDG_CONFIG_HOME=$2/config
export ZDOTS_TEST_COUNTER=$2/calls
path=($2/bin $path)
fpath=($1/functions $fpath)
cd -- "$2"
source "$1/lib/generated.zsh"
count() { local -a calls=( ${(f)"$(< "$ZDOTS_TEST_COUNTER")"} ); print $#calls; }
compdef() { :; }
_test_fallback() { (( ++fallbacks )); }

typeset -A _zdots_completion_generators=(test-tool 'test-tool native')
typeset -A _zdots_completion_catalog_versions=(test-tool 1)
typeset -A _zdots_completion_fallbacks=(test-tool _test_fallback)
autoload -Uz _zdots_native_completion
service=test-tool
_zdots_native_completion || exit 1
[[ $ZDOTS_TEST_LOADED == native && $(count) == 1 ]]
_zdots_native_completion || exit 1
[[ $(count) == 1 ]]
print 'PASS native completion generates once, then reuses cache'

# A binary replacement and a catalog update must both invalidate, on their own.
print '# replacement binary' >> "$2/bin/test-tool"
_zdots_native_completion || exit 1
[[ $(count) == 2 ]]
_zdots_completion_catalog_versions[test-tool]=2
_zdots_native_completion || exit 1
[[ $(count) == 3 ]]
print 'PASS native cache follows binary and catalog changes'

_zdots_completion_generators[test-tool]='test-tool unsupported'
_zdots_completion_catalog_versions[test-tool]=3
integer fallbacks=0
_zdots_native_completion || exit 1
_zdots_native_completion || exit 1
[[ $(count) == 4 && $fallbacks == 2 ]]
print 'PASS unsupported generators fall back without rerunning on each Tab'

_zdots_source_generated test-tool integration || exit 1
[[ $ZDOTS_TEST_LOADED == integration && $(count) == 5 ]]
_zdots_source_generated test-tool integration || exit 1
[[ $(count) == 5 ]]
# Project directories/config changes alone do not duplicate pure integration code.
print '# project configuration' > mise.toml
_zdots_source_generated test-tool integration || exit 1
[[ $(count) == 5 ]]
_zdots_source_generated test-tool other-arguments || exit 1
[[ $ZDOTS_TEST_LOADED == other-arguments && $(count) == 6 ]]
mkdir "$2/other-project"
cd "$2/other-project"
_zdots_source_generated test-tool other-arguments || exit 1
[[ $(count) == 6 ]]
mkdir "$2/new-version"
cp "$2/bin/test-tool" "$2/new-version/test-tool"
path=("$2/new-version" $path)
_zdots_source_generated test-tool other-arguments || exit 1
[[ $(count) == 7 ]]
path=("$2/bin" $path)
_zdots_source_generated test-tool other-arguments || exit 1
[[ $(count) == 7 ]]
print 'PASS integration cache follows executable/arguments, not working directory'
'''


def main():
    with tempfile.TemporaryDirectory(prefix="zdots-cache-") as fixture:
        target = Path(fixture)
        (target / "bin").mkdir()
        tool = target / "bin/test-tool"
        tool.write_text("#!/bin/sh\n"
                        'printf "call\\n" >> "$ZDOTS_TEST_COUNTER"\n'
                        '[ "$1" != unsupported ] || exit 1\n'
                        'printf "typeset -g ZDOTS_TEST_LOADED=%s\\n" "$1"\n')
        tool.chmod(0o700)
        env = os.environ.copy()
        subprocess.run([shutil.which("zsh"), "-dfc", SCRIPT, "cache-test",
                        str(ROOT), fixture], env=env, check=True)


if __name__ == "__main__":
    main()
