#!/usr/bin/env bash
set -euo pipefail

DEFAULT="${PROVISIONING_SCRIPT_DEFAULT:-https://raw.githubusercontent.com/vast-ai/base-image/refs/heads/main/derivatives/pytorch/derivatives/comfyui/provisioning_scripts/default.sh}"
CUSTOM="${PROVISIONING_SCRIPT_CUSTOM:-}"

echo "[wrapper] Running default provisioning: $DEFAULT"
tmp="/tmp/vast_default.sh"
curl -L --fail --retry 5 --retry-delay 2 -o "$tmp" "$DEFAULT"
chmod +x "$tmp"
bash "$tmp"

if [[ -n "$CUSTOM" ]]; then
  echo "[wrapper] Running custom provisioning: $CUSTOM"
  tmp2="/tmp/custom_provision.sh"
  curl -L --fail --retry 5 --retry-delay 2 -o "$tmp2" "$CUSTOM"
  chmod +x "$tmp2"
  bash "$tmp2"
else
  echo "[wrapper] No PROVISIONING_SCRIPT_CUSTOM set, skipping."
fi

echo "[wrapper] Done."