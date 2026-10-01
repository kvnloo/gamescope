#!/usr/bin/env bash
set -u

out="${1:-gamescope-latency-env-$(date +%Y%m%d-%H%M%S).txt}"

run() {
  printf '\n$ %s\n' "$*"
  "$@" 2>&1 || true
}

{
  printf 'captured_at='
  date --iso-8601=seconds
  run git rev-parse HEAD
  run uname -a
  run cat /etc/os-release
  run gamescope --version
  run nvidia-smi
  run vulkaninfo --summary
  run hyprctl version
  run hyprctl monitors -j
  run loginctl show-session "${XDG_SESSION_ID:-}" -p Type -p Desktop -p Remote
} > "$out"

printf 'wrote %s\n' "$out"
