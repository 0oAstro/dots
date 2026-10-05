---
description: Show pstack installation paths
argument-hint: "[status]"
---
Report the pstack package at `~/.local/share/mise/installs/http-pstack/latest` (installed and upgraded by mise as `http:pstack`; run `mise ls http:pstack` for the version), its Pi tool mapping at `plugins/pstack/skills/poteto-mode/references/pi-tools.md` inside it, the standing instruction file at `~/.pi/agent/AGENTS.md`, and the role sheet at `~/.pi/agent/pstack-models.md`. Check that these paths exist and that `pi list` shows the package. Do not load the full poteto-mode skill or start delegates. Note that the pstack Pi extension injects the routing instruction and the role sheet into the system prompt. Arguments: $ARGUMENTS
