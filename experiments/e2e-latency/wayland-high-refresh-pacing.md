# High-refresh Wayland frame-pacing experiment

Upstream context: https://github.com/ValveSoftware/gamescope/issues/2412

## Goal

Characterize whether high-refresh Wayland pacing degrades on this system and whether mouse activity changes the timing path.

Treat every suspected mechanism as a hypothesis until traces support it.

## Primary questions

- Does the issue reproduce on the target NVIDIA/CachyOS system?
- Is it Wayland-specific, or also visible with DRM / SDL?
- Does mouse motion change image-acquire timing, presentation feedback, wakeups, or only observed frame-time cadence?
- How does the effect scale with refresh rate?
- Does VRR change the behavior?

## Test matrix

Run the smallest Vulkan workload first.

| Variable | Values |
| --- | --- |
| backend | Wayland, DRM, SDL where practical |
| refresh | 60, 120, 144, 240 Hz where supported |
| VRR | off, on |
| input | stationary, continuous mouse motion |

Use randomized or ABBA ordering. Hold workload, resolution, clocks, power state, and compositor configuration constant.

## Record

- gamescope commit
- kernel
- NVIDIA driver
- session/compositor
- display model
- refresh rate
- VRR state
- frame interval `p50/p95/p99/p99.9`
- doubled or missed presentation intervals
- `vkAcquireNextImageKHR` wall time if instrumented
- presentation-feedback timestamps
- predicted vblank
- timer-arm timestamp
- wake timestamp
- CPU/GPU utilization and clocks

## Timeline to reconstruct

```text
presentation feedback
  -> next-vblank prediction
  -> wake deadline chosen
  -> timer armed
  -> thread wakes
  -> image acquire
  -> render/submit
  -> present
  -> actual presentation
```

## Promotion gate

Do not post upstream until at least one exists:

1. reproducible cross-run evidence with traces;
2. a narrowed causal hypothesis supported by instrumentation; or
3. a small patch with before/after measurements.

## Deliverables

- [ ] baseline reproduction
- [ ] ABBA matrix
- [ ] raw trace bundle
- [ ] causal timeline
- [ ] minimal patch or useful negative result
- [ ] upstream-ready note for `ValveSoftware/gamescope#2412`

## Instrumented branch

This branch adds trace-only markers; it does not intentionally alter pacing policy.

Markers:

- `latency-wayland feedback`: host presentation timestamp -> callback arrival age
- `latency-wayland feedback-discarded`
- `latency-vblank mark`: observed presentation interval and feedback age
- `latency-vblank arm`: chosen wake and target-vblank timestamps
- `latency-vblank timerfd`: actual poll time vs scheduled wake
- `latency-vblank process`: steamcompmgr dispatch time vs scheduled wake

Capture an instrumented run with:

```sh
./experiments/e2e-latency/capture-env.sh
./experiments/e2e-latency/capture-trace.sh ./build/src/gamescope -- vkcube
```

The capture helper follows gamescope's existing ftrace/GPUVis workflow and conditionally enables scheduler, DRM-vblank, and fence events that exist on the host.
