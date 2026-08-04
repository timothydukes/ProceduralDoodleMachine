# PDM Phase 0 — Results Analysis v1

Runs: mac × {JAVA2D, P2D, P3D}, pi × {P2D, P3D} + MIDI check + 20-min
thermal soak (P3D). A pi/JAVA2D run was not performed and is not needed —
JAVA2D is eliminated on two independent grounds below. Raw CSVs and
per-run summaries live alongside this file.

Context that matters when reading the numbers: the Pi's display ran at
1280×720, so the 720p tier composites 1:1; the Mac's screen was 1440×900,
so every tier pays a scaling blit. The Pi's 720p numbers are the honest
"real instrument" case.

## Max sustainable load (≥30 fps, 3 s windows)

| Test (720p internal)              | pi P2D | pi P3D | mac P2D | mac P3D | mac JAVA2D |
|-----------------------------------|--------|--------|---------|---------|------------|
| T1 long lines (full-field)        | 2000   | 2000   | 2000    | 2000    | none       |
| T2 curveVertex vertices           | 2000   | 2000   | 8000    | 8000    | none       |
| T3 sketchy strokes (≤160 px, ×2)  | 4000   | 4000   | 2000    | 2000    | none       |
| T4 translucent ellipses + wipe    | 800    | 800    | 6400    | 6400    | none       |
| T5 extra full-res buffers         | 2      | 2      | 12*     | 12*     | none       |
| T6a heavy shader filter passes    | none   | none   | 24*     | 24*     | skip       |
| T6b feedback warp iterations      | 1      | 1      | 16      | 24*     | skip       |

\* = ladder maxed, true limit higher.

1080p internal on the Pi: effectively dead (only trivial loads pass).
On the Mac, roughly half the 720p budgets.

## Findings

1. **JAVA2D is eliminated.** On the Mac it managed 8–13 fps at the
   *lowest* load of every test — the per-frame software-scaled blit of the
   internal buffer dominates. It also has no shader support, which the
   instrument wants. No pi run required to reach this conclusion.
2. **P2D and P3D are equivalent on the Pi** (identical budgets within
   noise, both on the V3D GL driver). The choice is therefore free on
   performance grounds and can be made on capability grounds.
3. **Internal resolution locks at 1280×720.** The Pi cannot carry 1080p
   internal buffers for any nontrivial style. Recommendation: also run the
   Pi's HDMI *output* at 1280×720 so the final composite stays 1:1 (this
   is the measured configuration; upscaling to a 1080p display would add
   an unmeasured blit cost).
4. **Stroke budgets are length-dependent.** 4000 short double-drawn
   sketchy strokes pass where 4000 full-field lines fail — rasterized
   pixel count, not segment count, is the cost. T1 is the pessimistic
   bound; T3 is the realistic doodle case. (The Pi beating the Mac on
   T3/T4 is the 1:1-vs-scaled composite plus vsync interplay, not a
   faster GPU.)
5. **The heavy-GLSL road is closed on the Pi; the light-GLSL road is one
   lane wide.** A single full-res generative `filter()` pass runs at
   21 fps — unusable. One lightweight texture-warp pass (feedback style)
   sustains 34 fps; two collapse to 16 (each `beginDraw/endDraw`
   iteration forces a pipeline sync). Policy consequence: at most one
   light shader pass per frame, no multi-pass chains, and any per-style
   shader must be proven in that style's study.
6. **Buffer budget: two extra full-res composited buffers** on top of the
   main surface. Accumulation styles should plan for one persistent
   buffer, two where necessary.
7. **Thermals are a non-issue** in the current physical setup: 20 minutes
   at working load, fps flat at 35.8±0.2 for the entire run, SoC max
   47.2 °C (throttle threshold is 80 °C), zero throttle events. Result is
   contingent on the current case/cooling arrangement.
8. **MIDI pipeline confirmed** on the Pi: mean CC inter-event gap
   2–4 ms across three captures (max-gap outliers are pauses in wiggling,
   not latency). No concerns for Phase 1.

## Working budgets (Pi, 720p, written into PDM_SPEC v0.2 §3.1)

Budgets take roughly a two-thirds margin below the measured cliff, since
the failing steps landed just under floor (29–30 fps) and styles will add
logic cost on top of raw drawing.

| Resource (per frame)                        | Measured max | Budget |
|---------------------------------------------|--------------|--------|
| Long full-field lines                       | 2000         | 1300   |
| Short sketchy strokes (double-drawn)        | 4000         | 2600   |
| curveVertex vertices                        | 2000         | 1300   |
| Translucent ellipses (~60 px) over full wipe| 800          | 500    |
| Extra full-res offscreen buffers            | 2            | 2 (prefer 1) |
| Light shader warp passes                    | 1            | 1      |
| Heavy generative shader passes              | 0            | 0      |
