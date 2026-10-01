#!/usr/bin/env bash
set -euo pipefail

if (( $# == 0 )); then
  echo "usage: $0 <command> [args...]" >&2
  echo "example: $0 ./build/src/gamescope -- vkcube" >&2
  exit 2
fi

tracefs=/sys/kernel/tracing
marker="$tracefs/trace_marker"

if [[ ! -w "$marker" ]]; then
  cat >&2 <<EOF
$marker is not writable.

One-time setup:
  sudo chmod 0755 $tracefs
  sudo chmod 0222 $marker

Then restart the traced gamescope process before capturing.
EOF
  exit 1
fi

out="${LATENCY_TRACE_OUT:-trace-gamescope-latency-$(date +%Y%m%d-%H%M%S).dat}"
available="$(trace-cmd list -e 2>/dev/null || true)"
args=()

add_event() {
  local event="$1"
  if grep -Fq "$event" <<<"$available"; then
    args+=( -e "$event" )
  fi
}

add_event sched:sched_switch
add_event sched:sched_waking
add_event sched:sched_wakeup
add_event sched:sched_wakeup_new
add_event drm:drm_vblank_event
add_event drm:drm_vblank_event_queued
add_event drm:drm_vblank_event_delivered
add_event fence:fence_signaled

echo "writing $out"
exec trace-cmd record -i "${args[@]}" -o "$out" -- "$@"
