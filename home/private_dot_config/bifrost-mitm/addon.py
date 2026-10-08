"""Send Claude Code's model calls to Bifrost while it believes it talks to api.anthropic.com.

Only api.anthropic.com is decrypted (see --allow-hosts in the unit). A POST to
/v1/messages that carries the virtual key (x-bf-vk) goes to Bifrost with the
client's own headers. Everything else, including Remote Control's session and
WebSocket traffic, goes to Anthropic with x-bf-vk stripped, so the virtual key
never leaves the tailnet. Without the key (BIFROST_VIRTUAL_KEY unset) the call
goes direct, since Bifrost would reject it.

Routing uses mitmproxy's built-in options. They are set here, not in the unit,
so editing this file reloads the proxy without dropping open connections.
"""

import os

from mitmproxy import ctx, http

UPSTREAM = os.environ.get("BIFROST_ANTHROPIC_URL", "https://bifrost.shau.me/anthropic").rstrip("/")
MODEL_CALL = r"~m POST & ~u ^https://api\.anthropic\.com/v1/messages"


def running() -> None:
    ctx.options.update(
        map_remote=[rf"|{MODEL_CALL} & ~hq x-bf-vk|^https://api\.anthropic\.com/|{UPSTREAM}/"],
        modify_headers=[f"|!({MODEL_CALL})|x-bf-vk|"],
    )


def responseheaders(flow: http.HTTPFlow) -> None:
    flow.response.stream = True
