# Keep the process extension bundle current

Pi loads a validated local bundle of all three process extensions. It retains the original npm package and its skill. If cache files are missing, edited, or incompatible with the current inputs or Pi executable, the adapter loads the original source instead. Startup never runs a build.

The generated bundle lives under `/tmp/pi-processes-fast-1000/`. A reboot or temporary-file cleanup can remove it. Pi still works, but the measured startup improvement requires a valid bundle.

## Rebuild after package updates, Pi updates, or cache removal

Record the runtime from the actual Pi executable. Do not use `bun build.ts --runtime` for this step because it records the external Bun runtime.

```sh
pi --offline --no-session -ne \
  -e /home/ec2-user/scratch/pi-startup-20260930/runtime-identity.ts \
  -p /startup-runtime </dev/null
bun /home/ec2-user/.pi/agent/local/pi-processes-fast/build.ts \
  /home/ec2-user/scratch/pi-startup-20260930/pi-runtime.json
```

The builder rejects unknown dependencies and unsupported emitted runtime imports. If preparation fails, leave the original-source fallback active. Do not edit generated JavaScript.

## Restore the original extension selection

In `/home/ec2-user/.pi/agent/settings.json`, replace these two package entries:

```json
{"source":"npm:@aliou/pi-processes","extensions":[]},
"local/pi-processes-fast"
```

with the original entry:

```json
"npm:@aliou/pi-processes"
```

Keep all unrelated settings. Restart Pi after changing extension selection.

## Rerun the retained checks

```sh
python3 /home/ec2-user/scratch/pi-startup-20260930/benchmark.py \
  --label recheck --samples 7 --complete-init --persist
PROCESSES_TEST_ADAPTER=/home/ec2-user/.pi/agent/local/pi-processes-fast/index.ts \
PROCESSES_TEST_LABEL=adapter \
  pi --offline --no-session -ne \
  -e /home/ec2-user/scratch/pi-startup-20260930/processes-behavior.ts \
  -p /processes-behavior </dev/null
python3 /home/ec2-user/scratch/pi-startup-20260930/processes-tui.py \
  --entry /home/ec2-user/.pi/agent/local/pi-processes-fast/index.ts --label adapter
```

The behavior fixture starts local shell processes and verifies stdin, exit events, output, watches, stop, clear, and shutdown. The TUI fixture opens and closes the overview, logs, and dock. These checks do not make model or network requests.
