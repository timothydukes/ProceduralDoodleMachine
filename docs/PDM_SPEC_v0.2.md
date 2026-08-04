# PDM_SPEC v0.2 — Procedural Doodle Machine

A specification for a MIDI-controlled Processing video synthesizer dedicated to
procedural-doodle computer graphics. Given this spec and a description of an
animation style, a developer (human or LLM) should be able to produce a
complete style class conforming to the instrument.

Status: v0.2 — v0.1 (approved) + Phase 0 benchmark results folded into §3.
Changes from v0.1 are confined to §3, new §3.1, and §9. One new
**[INTERPRETIVE]** item (renderer choice, §3) awaits approval; all v0.1
interpretive items were approved as delivered.

---

## 1. Identity and scope

- Name: **Procedural Doodle Machine (PDM)**.
- Purely generative. No camera, video, or audio input. Silent instrument.
- A live instrument: PDM's HDMI output feeds a larger modular video setup
  (mixer / effects chain). No preset saving, no in-program frame capture or
  screen recording. Capture is external (HDMI).
- 8 animation styles × 3 modes each, selected by the nanoKONTROL2's 24
  S/M/R buttons. Exactly one style+mode active at any time.
- Modes within a style may be entirely different drawing algorithms sharing
  only a family resemblance (e.g., a 3-D figure style: mode 1 cross-hatching,
  mode 2 one-point perspective, mode 3 charcoal/crayon shading). The class
  interface (§7) is designed for this.
- Aesthetic center of gravity: clean-ish geometry executing doodle
  *procedures*. Noise and texture model imperfections of the hand, not
  ink/paper physics. Accuracy/noise level and line quality vary per style.

## 2. Hardware and platform requirements

- Primary target: **Raspberry Pi 4 Model B rev 1.5, 8 GB**, Raspberry Pi OS
  Bookworm 64-bit.
- Development convenience platform: macOS (mid-2015 MacBook Pro, macOS 12.7.6).
  Same repo, same code, no platform branches. The Pi is authoritative for all
  performance decisions.
- Controller: **Korg nanoKONTROL2**, factory default scene/CC map. Hard
  requirement — no keyboard fallback. The controller is pure input; no LED
  feedback is used.
- **Processing 4.3** on both platforms. Install steps documented in
  `docs/INSTALL.md`.
- If the nanoKONTROL2 is not detected at launch, exit with a clear message.
  No hotplug support.
- Final-phase goal: Pi boots headless directly into the instrument. During
  development, launched from the desktop.

## 3. Rendering (locked by Phase 0; see benchmarks/RESULTS_v1.md)

- `fullScreen()` and `noCursor()` always.
- `colorMode(HSB, 360, 100, 100, 100)` globally.
- Renderer: **P3D**. **[INTERPRETIVE]** Phase 0 measured P2D and P3D as
  equivalent on the Pi and JAVA2D as unusable, so the choice is free on
  performance grounds; P3D is selected because one planned style family is
  explicitly 3-D (one-point perspective mode), and P3D provides real 3-D
  transforms where P2D would require manual projection. Cost of reversal to
  P2D later: one line plus per-style retesting.
- Internal render resolution: **1280×720, fixed**. 1080p internal is
  prohibited on the Pi (Phase 0: no nontrivial style survives it). The Pi's
  HDMI output should also run at 1280×720 so the final composite stays 1:1;
  upscaling to a 1080p display adds unmeasured blit cost.
- Performance floor: **30 fps**, confirmed as the working pass/fail line.
- GLSL policy: **narrow but open.** At most **one lightweight texture-warp
  shader pass per frame** (feedback-style). Heavy per-pixel generative
  shaders and multi-pass chains are prohibited (a single `filter()` pass of
  a moderate generative shader ran at 21 fps on the Pi). Any style that uses
  its one shader pass must prove it inside that style's study sketch on the
  Pi before porting.
- Frame-rate guardrails: each style declares its own FPS floor and
  degradation mechanism, chosen during its study phase. Primary lever:
  element-count reduction (budgets in §3.1 leave room for this). Secondary
  lever: internal resolution drop to 960×540. Raising resolution is never a
  lever.
- Thermal: Phase 0 soak showed zero throttling over 20 minutes at working
  load (SoC max 47.2 °C) in the current physical setup; sustained sets are
  safe. Re-verify if the Pi's case/cooling changes.
- Temporality is a per-style property: some styles accumulate marks (with
  clearing, pruning, or fading of old marks), others clear every frame and
  animate moving figures.

### 3.1 Per-frame complexity budgets (Pi, 720p internal)

Budgets sit ~⅓ below the measured cliff to leave room for style logic and
degradation headroom. A style's nominal (pre-degradation) load must fit the
budget; the measured max is the absolute ceiling.

| Resource per frame                                   | Measured max | Budget |
|------------------------------------------------------|--------------|--------|
| Long full-field lines                                | 2000         | 1300   |
| Short sketchy strokes (≤~160 px, double-drawn)       | 4000         | 2600   |
| `curveVertex` vertices                               | 2000         | 1300   |
| Translucent ~60 px ellipses over a full-screen wipe  | 800          | 500    |
| Extra full-res offscreen buffers composited          | 2            | 2 (prefer 1) |
| Light shader warp passes                             | 1            | 1      |
| Heavy generative shader passes                       | 0            | 0      |

Costs are rasterization-bound: budgets scale with drawn pixel length/area,
not primitive count (4000 short strokes pass where 4000 full-field lines
fail). Styles mixing categories must stay proportionally under budget.

## 4. Control surface

### 4.1 Conventions

- All analog values normalized to **0.0–1.0 immediately on read**.
- Controls are always live. No soft-takeover / pickup. On any style or mode
  switch, the incoming style activates with all parameters set from the
  *current physical* slider/knob positions plus global state.

### 4.2 Global analog assignments

| Control  | Function        | Semantics |
|----------|-----------------|-----------|
| Slider 1 | Zoom            | Zoom out → smaller image on the background. Maximum zoom in → drawing extends beyond the screen borders. |
| Knob 1   | Rotate          | 0.0 → −π, 1.0 → +π, center → 0, with a soft detent at center (§4.3). |
| Slider 2 | Pan left/right  | |
| Knob 2   | Pan up/down     | |
| Slider 3 | Density         | Minimum → mostly background, a few minimal lines. Maximum → horror vacui. Meaning of "density" is per-algorithm. |
| Knob 3   | Stroke weight   | |
| Slider 7 | Color control   | Per-style; each style specifies what this does. |
| Knob 7   | Hue LFO speed   | 0.0 → no hue rotation at all. Hue rotation is quantized to the active palette (§5). |
| Slider 8 | Master speed    | 0.0 → frozen, 0.5 → 1×, 1.0 → 5× (§4.4). |
| Knob 8   | Palette         | Stepped selection through the fixed bank of 12 (§5). |

Strips 4, 5, 6 (three sliders + three knobs) are **free per style**.

Zoom, rotate, and pan are **parameters passed into each style**, not a global
post-transform. Each style must respond sensibly; "sensibly" is defined
per style during its study phase.

### 4.3 Rotate detent mapping

Raw knob value `v ∈ [0,1]` maps to rotation `θ ∈ [−π, +π]` with a flat zero
zone: `v ∈ (0.47, 0.53)` maps to exactly 0, and the mapping is smooth
(C¹-continuous) outside the zone. Concrete curve (approved v0.1): for
`v ≥ 0.53`, `θ = π · smoothstep-remap((v − 0.53)/0.47)`; mirrored below.
Edge easing is tuned the first time it's played.

### 4.4 Master speed curve

Fixed points: `f(0) = 0` (frozen), `f(0.5) = 1`, `f(1) = 5`, roughly
exponential. Approved curve: `speed(v) = (16^v − 1) / 3`. The 5× ceiling is
negotiable after aesthetic testing.

All styles consume a single shared clock: `t += dt · speed`. Continuous time
only; no tempo or beat concept exists anywhere in the instrument.

### 4.5 Buttons

- The 24 S/M/R buttons form 8 columns × 3 rows. **Column = style, row =
  mode.** Pressing any button activates that style in that mode.
- Transport buttons (track ◀ ▶, cycle, marker set ◀ ▶, rewind, ff, stop,
  play, record): **reserved, unassigned**. High-level global adjustments will
  be assigned here in a later phase.

### 4.6 Mapping consistency rule

Within a style, free-control mappings stay constant across its three modes.
Exception: when modes genuinely require different parameters, mappings may be
overloaded or redefined per mode — but any parameter *shared* by two modes of
the same style must map identically in both.

## 5. Color and palettes

- Default look: black background, high-saturation lines.
- A fixed bank of **12 palettes**, shared globally across all styles,
  stepped through with knob 8.
- A palette is a **constraint / filter / restriction on the displayable
  colors**, not a fixed assignment. The bank includes (final list to be
  settled during development): monochromatic black & white; full-saturation
  rainbow; minimal-video full-saturation full-brightness RGB/CMYK; pastel;
  organic; several more; and inverted variants.
- Hue LFO rotation (knob 7) is clamped/quantized to the active palette's
  allowed colors.
- Background / ground / accent **roles are defined per style**. On inverted
  palettes, roles are reversed/inverted.

## 6. Library and citation policy

- **Vendor everything.** All third-party code — including the nanoKONTROL
  MIDI library and the Handy sketchy-rendering library — is copied as source
  into the project folder (Processing tabs or the sketch `code/` directory as
  appropriate per library), modified as needed. No Processing-IDE-installed
  libraries.
- Maximize reuse of prior art and existing code; cite everything.
- `docs/CREDITS.md` is maintained from the first commit: every vendored
  library, adapted algorithm, and inspiration source, with URL, author,
  original license, and a note on what was modified.
- Vendored files retain their original license headers. Original PDM code is
  MIT-licensed. If a vendored library's copyleft terms conflict with
  distributing the combined work this way, the conflict is flagged at
  vendoring time with options (relicense the repo vs. reimplement the
  technique with citation).
- Known intended sources so far: Handy (Jo Wood, giCentre — hand-drawn
  sketchy rendering, native Processing); techniques from Wood et al.,
  "Sketchy Rendering for Information Visualization" (also the basis of
  rough.js); a text/cursive generation source TBD for the asemic-writing
  style; nanoKONTROL2 access library TBD (korgnano or equivalent, vendored).

## 7. Program architecture

- Single Processing sketch folder. One `.pde` tab per style class, plus core
  tabs: main (setup/draw/orchestration), MIDI input, palette system, shared
  utilities, and vendored library tabs.
- Because modes are potentially unrelated algorithms, a style is a thin
  container of three mode objects:

```java
abstract class DoodleMode {
  // Called on activation (style/mode switch, and boot).
  // params: all 16 normalized analog values; globals: palette, zoom,
  // rotate, pan, density, strokeWeight, colorCtl, time.
  abstract void activate(PdmState s);
  abstract void update(PdmState s, float dt);   // dt already speed-scaled
  abstract void render(PdmState s, PGraphics g);
  // Guardrail hook: called when fps < this mode's declared floor.
  void degrade() {}
  float fpsFloor() { return 20; }               // per-mode default, tunable
}

class DoodleStyle {
  String name;
  DoodleMode[] modes = new DoodleMode[3];
}
```

- Accumulating modes own their persistent `PGraphics` buffer(s); animating
  modes draw to the shared frame. Buffer lifecycle (create on activate,
  release on deactivate) is the mode's responsibility. Budget: §3.1.
- Boot state: style 1, mode 1, parameters read from physical positions.

## 8. Repository

- Public GitHub repo. Layout:

```
ProceduralDoodleMachine/       # main Processing sketch
studies/                       # one self-contained sketch per style candidate
benchmarks/                    # Phase 0 suite + results + analysis
docs/                          # PDM_SPEC, CREDITS.md, INSTALL.md, FORK_GUIDE.md
```

- Style workflow: each style is developed and aesthetically refined as a
  separate self-contained sketch in `studies/`; only when satisfactory is it
  ported as a class into the main sketch. Studies remain in the repo for
  future forkers.
- `docs/FORK_GUIDE.md` (written at completion): short guide for forks using
  a different MIDI controller.
- Delivered files carry version suffixes (`_v1`, `_v2`, …) to avoid
  copy collisions between the Downloads folder and the project folder; git
  history is additionally authoritative.

## 9. Development phases

- **Phase 0 — Pi benchmarking. COMPLETE.** Results and analysis:
  `benchmarks/RESULTS_v1.md`; raw CSVs and summaries committed alongside.
  Outcomes locked into §3/§3.1: renderer P3D (pending approval), 720p
  internal, 30 fps floor, one-light-shader-pass GLSL policy, complexity
  budgets, thermal clearance, MIDI pipeline confirmed.
- **Phase 1 — Skeleton.** Main sketch: MIDI layer, global controls, palette
  system, style/mode switching, clock, with placeholder styles.
- **Phases 2..n — Style studies.** One style at a time: brainstorm → study
  sketch → aesthetic refinement iterations → port into main sketch.
  The 8-style list is provided and iterated collaboratively before Phase 2.
- **Late phases.** Transport button assignments; headless boot; FORK_GUIDE.

Every phase gates on explicit approval before implementation.

---

*PDM_SPEC v0.2 — supersedes v0.1. Open item: renderer choice (§3).*
