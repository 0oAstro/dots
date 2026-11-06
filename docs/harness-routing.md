# Harness routing

Claude Code retains its existing single-account authentication, settings, and model default. Cursor CLI retains its existing backend because its documented configuration has no arbitrary inference-provider endpoint.

## Routes

| Harness | Claude OAuth | Bedrock | Azure |
| --- | --- | --- | --- |
| Pi, including teacher and REA profiles | Native Anthropic Messages; account A is the default Claude route | Existing native provider, explicitly selectable | Existing direct provider |
| Droid | Native Anthropic Messages; Opus OAuth A is the default, with Haiku OAuth A and Fable OAuth A for light and heavy Tasks | Existing plain Claude names and Kimi entries | Existing direct models and medium Task role |
| Prime | Native Anthropic Messages; separate A/B entries | Excluded, earlier signing checks failed and the current direct probe exits without completing inference | Existing default and role selections remain |
| fx | Separate `cliproxy-a` and `cliproxy-b` providers through Chat Completions translation | Not supported natively | Existing default provider and live model choice remain |

`home/.chezmoitemplates/` owns settings defaults. Pi's `home/dot_pi/private_agent/models.json` owns Claude OAuth metadata and Azure models. Prime's models template reuses those two providers with environment-variable names for authentication. The deployed broker's configuration and onboarding instructions live in `/opt/docker/cliproxyapi/AGENTS.md`.

Opus 5.5, Fable 5.1, and Haiku 5.5 each have `a/<model>` and `b/<model>` routes. The broker requires unique credential prefixes. No combined pool, unprefixed Claude default, or cross-provider fallback is configured. Selecting account B never happens automatically when A is unavailable. In Pi and Prime, examples are `cliproxy/a/claude-opus-5-5` and `cliproxy/b/claude-opus-5-5`. In Droid, examples are `custom:Opus-5.5-OAuth-A-0` and `custom:Opus-5.5-OAuth-B-0`; the existing `custom:Opus-5.5-0` remains Bedrock. In fx, `fx provider cliproxy-a` selects the account-A Claude connection, and `fx provider azure` restores the Azure connection.

## Credentials and launch

`CLIPROXY_API_KEY` authenticates inference to `https://cliproxy.shau.me`, which is reachable only on the tailnet. Its source is the existing age-encrypted `agents.env` file. chezmoi installs that file with mode `0600`; `.zshenv` exports this variable alongside the existing Azure pair and `FIRECRAWL_API_KEY`. No Claude Code or Pi OAuth credential is imported into the broker. New shells inherit the new variable; existing processes need a new launch environment.

Account sign-ins and prefix assignment are required before inference works. Configured model entries and process health are not evidence of working subscription authentication, streaming, or refresh. Both account routes remain unverified until real OAuth sign-ins and requests complete. CLIProxyAPI's Chat Completions conversion is an additional translation layer for fx, not native Anthropic Messages support in fx.

Catalog cost metadata is an API-price estimate, not a subscription invoice or a measurement of remaining subscription quota. The broker's usage statistics cover only requests observed by the broker.

## App-owned selections

The existing `modify_` templates preserve live model choices, thinking levels, model scopes, and Droid custom models. Fresh installations receive repository defaults. Initial integration updates those app-owned fields explicitly, retaining Azure choices, existing Bedrock entries, and unrelated custom models. Subsequent chezmoi applies preserve later explicit selections, including Bedrock. Only managed harness paths are applied; `.claude` is excluded from this integration.
