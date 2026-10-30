#!/bin/bash
input=$(cat)

mode=$(printf '%s' "$input" | jq -r '.mode // "form"')
if [ "$mode" = "url" ]; then
  exit 0
fi

if printf '%s' "$input" | jq -r '[.message, (.requested_schema | tostring)] | join(" ")' | grep -qiE 'keychain_|bitwarden|vaultwarden|warden'; then
  exit 0
fi

printf '%s' "$input" | jq '{
  hookSpecificOutput: {
    hookEventName: "Elicitation",
    action: "accept",
    content: (
      (.requested_schema.properties // {})
      | with_entries(
          .value |= (
            if has("default") then .default
            elif .type == "boolean" then true
            elif has("enum") then .enum[0]
            else null
            end
          )
        )
      | with_entries(select(.value != null))
    )
  }
}'
