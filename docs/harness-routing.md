# Harness routing

Claude Code retains its existing single-account authentication, settings, and model default. Cursor CLI retains its existing backend because its documented configuration has no arbitrary inference-provider endpoint.

## Routes

| Harness | Claude OAuth | Bedrock | Azure |
| --- | --- | --- | --- |
| Pi, including teacher and REA profiles | Native Anthropic Messages; one primary/fallback pool is the default Claude route | Existing native provider, explicitly selectable | Existing direct provider |
| Droid | One OAuth entry per model; Opus OAuth is the default, with Haiku OAuth and Fable OAuth for light and heavy Tasks | Existing plain Claude names and Kimi entries | Existing direct models and medium Task role |
| Prime | Native Anthropic Messages; one primary/fallback pool | Excluded, earlier signing checks failed and the current direct probe exits without completing inference | Existing default and role selections remain |
| fx | One `cliproxy` provider through Chat Completions translation | Not supported natively | Existing default provider and live model choice remain |

`home/.chezmoitemplates/` owns settings defaults. Pi's `home/dot_pi/private_agent/models.json` owns Claude OAuth metadata and Azure models. Prime's models template reuses those two providers with environment-variable names for authentication. The deployed broker's configuration and onboarding instructions live in `/opt/docker/cliproxyapi/AGENTS.md`.

Opus 5.5, Fable 5.1, and Haiku 5.5 each have one `oauth/<model>` route backed by both Claude subscriptions. Their saved priorities remain `0` and `-10`: the primary is preferred, and the backup is eligible on primary failure or unavailability. This is not equal load balancing. Fill-first selection and the initial retry round can try both identities. No extra retry rounds, cooldown waits, different-model fallback, or cross-provider fallback is configured. Antigravity retains priority `-20` and is outside the Claude pool.

Session affinity preserves a selected identity for cache reuse, including a backup binding after the primary recovers. New sessions prefer the primary. Pi sends its session-affinity header. In Pi and Prime, an example is `cliproxy/oauth/claude-opus-5-5`. In Droid, the default is `custom:Opus-5.5-OAuth-0`; the existing `custom:Opus-5.5-0` remains Bedrock. In fx, `fx provider cliproxy` selects the pooled Claude connection, and `fx provider azure` restores the Azure connection.

## Credentials and verification

`CLIPROXY_API_KEY` authenticates inference to `https://cliproxy.shau.me`, which is reachable only on the tailnet. Its source is the existing age-encrypted `agents.env` file. chezmoi installs that file with mode `0600`; `.zshenv` exports this variable alongside the existing Azure pair and `FIRECRAWL_API_KEY`. No Claude Code or Pi OAuth credential is imported into the broker. Existing processes need a new launch environment when an environment variable changes.

Both Claude subscriptions are signed in and respond through native Anthropic streaming. Pi's native pooled adapter returns a response. Expiry-driven refresh and fault-triggered fallback are not fault-injection tested. fx uses Chat Completions conversion, not native Anthropic Messages. Catalog cost metadata is an API-price estimate, not a subscription invoice or remaining subscription quota. Broker usage statistics cover only requests observed by the broker.

## Cloud upstream capability

CLIProxyAPI v8.0.58 can configure Azure OpenAI v1 groups: the API-key Codex executor uses Responses for Sol and Astra; OpenAI compatibility uses Chat Completions for GLM and DeepSeek. These are protocol-processing executors. Azure remains direct in this deployment. The broker has no native AWS SigV4 or ambient AWS credential-chain inference executor, so the existing EC2-role Bedrock connection cannot simply move into it. An AWS bearer-compatible endpoint requires separate protocol, model, and credential verification.

## App-owned selections

The existing `modify_` templates preserve live model choices, thinking levels, scopes, and Droid custom models. Fresh installations receive repository defaults. Pool migration collapses the former A/B entries, retaining Azure choices, existing Bedrock entries, and unrelated custom models. Later explicit selections survive subsequent chezmoi applies. Only managed harness paths are applied; `.claude` is excluded.
