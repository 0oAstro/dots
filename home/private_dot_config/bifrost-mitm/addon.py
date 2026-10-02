"""Send Claude Code's model calls to Bifrost while it believes it talks to api.anthropic.com.

Only api.anthropic.com is decrypted (see --allow-hosts in the unit). Model calls
go to Bifrost with the client's own headers (OAuth Authorization, x-bf-vk).
Every other request, including Remote Control's session and
WebSocket traffic, goes to Anthropic with the x-bf-* headers stripped so the
virtual key never leaves the tailnet.
"""

import os
from urllib.parse import urlsplit

from mitmproxy import http

UPSTREAM = urlsplit(os.environ.get("BIFROST_ANTHROPIC_URL", "https://bifrost.shau.me/anthropic"))
MODEL_PATHS = ("/v1/messages",)


def request(flow: http.HTTPFlow) -> None:
    req = flow.request
    if req.pretty_host != "api.anthropic.com":
        return
    # Without a virtual key (e.g. BIFROST_VIRTUAL_KEY unset) Bifrost would 401, so go direct.
    if req.method == "POST" and req.path.startswith(MODEL_PATHS) and "x-bf-vk" in req.headers:
        req.scheme = UPSTREAM.scheme
        req.host = UPSTREAM.hostname
        req.port = UPSTREAM.port or (443 if UPSTREAM.scheme == "https" else 80)
        req.path = UPSTREAM.path.rstrip("/") + req.path
        req.headers["host"] = UPSTREAM.netloc
        return
    for name in [h for h in req.headers if h.lower().startswith("x-bf-")]:
        del req.headers[name]


def responseheaders(flow: http.HTTPFlow) -> None:
    flow.response.stream = True
