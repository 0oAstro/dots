# GitHub identities

Unconfigured repositories use 0oAstro (Astro). Existing repository-local author
and signing overrides are not erased automatically.

Run inside a repository:

```sh
git identity astro
git identity hemant
git identity
```

The `hemant` shortcut selects the GitHub account `merak-max`; account names,
commit authors, email addresses, and key paths are unchanged.

Selection is saved in the repository's Git config, so it also applies to its
linked worktrees. It does not change the globally active GitHub CLI login.
GitHub HTTPS credentials follow `identity.account`, defaulting to 0oAstro.
GitHub SSH-style remote URLs are transparently rewritten to HTTPS.

`gh` itself is mise's and follows the globally active login. Switch it with
`gh auth switch --hostname github.com --user ACCOUNT`, or request a token with
`gh auth token --hostname github.com --user ACCOUNT`.

## Hemant signing-key registration

The local key is `$HOME/.ssh/id_ed25519_merak_signing`; never share that file.
Only its `.pub` file is uploaded. Registration was completed and verified against
the `merak-max` account on September 11, 2026. The key is titled
`aardvark git signing (merak-max)`. No further setup is needed.

For future reauthorization or key registration:

```sh
gh auth switch --hostname github.com --user merak-max
gh auth refresh --hostname github.com --scopes admin:ssh_signing_key
# Inside the repository that should use Hemant:
git identity hemant
git identity --register-key
```

Both Astro's and Hemant's local signing keys are registered with their respective
GitHub accounts. Local signing was tested for both identities.
