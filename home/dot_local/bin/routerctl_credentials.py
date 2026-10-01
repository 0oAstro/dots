"""Small, private XDG credential-profile reader shared by routerctl drivers.

The file is intentionally read-only from the CLI.  Profiles are stored in
~/.config/routerctl/credentials.json (or ROUTERCTL_CREDENTIALS_FILE) and must
not be group/world-readable.
"""
from __future__ import annotations

import json
import os
from pathlib import Path


class CredentialError(RuntimeError):
    """The local credential profile is malformed or insufficiently private."""


def credentials_path() -> Path:
    override = os.environ.get("ROUTERCTL_CREDENTIALS_FILE")
    if override:
        return Path(override).expanduser()
    config_home = Path(os.environ.get("XDG_CONFIG_HOME", "~/.config")).expanduser()
    return config_home / "routerctl" / "credentials.json"


def load_credentials() -> dict[str, object]:
    path = credentials_path()
    if not path.exists():
        return {}
    mode = path.stat().st_mode & 0o777
    if mode & 0o077:
        raise CredentialError(f"credentials file must be private (0600 or stricter): {path}")
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise CredentialError(f"could not read credentials file {path}: {exc}") from exc
    if not isinstance(payload, dict):
        raise CredentialError(f"credentials file must contain a JSON object: {path}")
    return payload


def stored(provider: str, field: str, default: str | None = None) -> str | None:
    profile = load_credentials().get(provider)
    if not isinstance(profile, dict):
        return default
    value = profile.get(field)
    return str(value) if value is not None else default
