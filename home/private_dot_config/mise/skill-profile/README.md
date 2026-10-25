# Skill profile

The profile lists `emil-design-eng`, `grilling`, and `poteto-mode` for automatic selection. Other installed skills have `disable-model-invocation: true` and `user-invocable: true`. The profile omits `setup-pstack` and `setup-matt-pocock-skills`, but retains supporting files that other skills reference.

Mise builds the profile from its installed packages. Content-addressed snapshots keep upstream files unchanged. Chez moi links Claude to the profile. Pi keeps the original pstack extension package and reads skills from the profile, so existing sessions do not load two extension copies. Prime reads full copies of its bundled skill folders, including Python modules.

## Refresh and verify

Run `skill-profile sync` to refresh the shared copies. Run `skill-profile verify` to check flags, links, entry points, and omitted setup skills.

## Native checks

Pi's resource loader reports the three automatic skills. From `/tmp`, `prime prompt --json` shows the actual available-skills section. Claude's interactive `/skills` menu labels the other installed skills as user-only.

Cursor is outside this profile. Its pstack plugin manages Cursor's skills.
