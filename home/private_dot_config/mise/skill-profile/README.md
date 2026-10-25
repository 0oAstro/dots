# Skill profile

The profile lists `emil-design-eng`, `grilling`, and `poteto-mode` for automatic selection. Other installed skills have `disable-model-invocation: true` and `user-invocable: true`. The profile omits `setup-pstack` and `setup-matt-pocock-skills`, but retains supporting files that other skills reference.

Mise builds the profile from its installed packages. Content-addressed snapshots keep upstream files unchanged. Chez moi links Claude and Cursor to the profile. Pi keeps the original pstack extension package and reads skills from the profile, so existing sessions do not load two extension copies. Prime reads full copies of its bundled skill folders, including Python modules.

## Refresh and verify

Run `skill-profile sync` to refresh the shared copies. Run `skill-profile verify` to check flags, links, entry points, and omitted setup skills.

On a host with Hermes, run `skill-profile hermes-sync`, then `skill-profile hermes-verify`. Hermes has no command-only flag. The adapter moves native skills into `~/.hermes/skills/.archive`, exposes only the entry points, and creates native slash-command bundles for archived skills. It preserves the essential native `hermes-agent` skill as a visible exception. It sets only `skills.external_dirs` and `skills.auto_load` through the Hermes CLI.

Hermes sync keeps original skill bodies, support files, and existing bundles. An identical reinstalled skill moves into `.archive/.previous`. A changed reinstall with an existing archive path stops before moving files.

Mise's postinstall hook refreshes both profiles after upgrades. A failed Hermes environment stops Hermes sync rather than installing dependencies or selecting another Python environment.

## Native checks

Pi's resource loader reports the three automatic skills. From `/tmp`, `prime prompt --json` shows the actual available-skills section. Claude's interactive `/skills` menu labels the other installed skills as user-only.

Cursor's slash menu proves discovery and explicit invocation, not model visibility. Cursor's server-managed skills and cloud plugins are outside this profile. Their model visibility remains NOT VERIFIED.

The Hermes adapter's verify command runs the installed discovery, list, archive-view, and bundle-invocation functions without a model call. Aardvark's Hermes environment currently lacks PyYAML, so its live profile remains NOT VERIFIED until that environment is repaired.
