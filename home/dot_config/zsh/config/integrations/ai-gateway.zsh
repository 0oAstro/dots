# Route Claude Code through Bifrost while it still talks to api.anthropic.com,
# so Remote Control and every other first-party-only feature keep working. The
# bifrost-mitm user service (~/.config/bifrost-mitm) sends model calls to
# Bifrost and passes everything else through. Bifrost routes by the claude.ai
# OAuth token in Authorization; the virtual key and harness tag ride along as
# custom headers. Do not set ANTHROPIC_AUTH_TOKEN here; it replaces the claude.ai
# login and disables connectors. Bypass for one run with `HTTPS_PROXY= claude`.
# Pi/Prime: 1h Anthropic prompt cache (default 5m), matching Claude Code; 24h on
# OpenAI where the provider supports it.
export PI_CACHE_RETENTION=long

if [[ -n ${BIFROST_VIRTUAL_KEY:-} ]]; then
  export ANTHROPIC_CUSTOM_HEADERS="x-bf-vk: $BIFROST_VIRTUAL_KEY"$'\n'"x-bf-lh-harness: claude-code"
  claude() {
    HTTPS_PROXY=http://127.0.0.1:18899 NODE_EXTRA_CA_CERTS=$HOME/.mitmproxy/mitmproxy-ca-cert.pem command claude "$@"
  }
fi
