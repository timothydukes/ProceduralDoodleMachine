# PDM_SPEC v0.1 — Procedural Doodle Machine

A specification for a MIDI-controlled Processing video synthesizer dedicated to
procedural-doodle computer graphics. Given this spec and a description of an
animation style, a developer (human or LLM) should be able to produce a
complete style class conforming to the instrument.

Status: DRAFT v0.1 — pending review. Items marked **[INTERPRETIVE]** are
implementation choices made by the spec author where the requirements left a
gap; each requires explicit approval or revision.

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

## 3. Rendering conventions

- `fullScreen()` and `noCursor()` always.
- `colorMode(HSB, 360, 100, 100, 100)` globally.
- Renderer (JAVA2D / P2D / P3D) and GLSL policy: **decided by Phase 0
  benchmarking on the Pi** (§9). GLSL is desired wherever the Pi supports it
  at acceptable cost.
- Working performance target pending Phase 0: 720p @ 30 fps.
- Frame-rate guardrails: each style declares its own FPS floor and its own
  degradation mechanism (internal resolution drop, element-count reduction,
  or both), chosen during that style's study phase. Floors are discovered by
  playing the instrument, not fixed in advance.
- Temporality is a per-style property: some styles accumulate marks (with
  clearing, pruning, or fading of old marks), others clear every frame and
  animate moving figures.

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
(C¹-continuous) outside the zone.

**[INTERPRETIVE]** Concrete candidate: for `v ≥ 0.53`,
`θ = π · smoothstep-remap((v − 0.53)/0.47)`; mirrored for `v ≤ 0.47`. Whether
the approach to the detent edge is linear or eased is an aesthetic call to be
settled the first time it's played.

### 4.4 Master speed curve

Fixed points: `f(0) = 0` (frozen), `f(0.5) = 1`, `f(1) = 5`, roughly
exponential. The 5× ceiling is negotiable after aesthetic testing.

**[INTERPRETIVE]** Concrete candidate satisfying all three fixed points
exactly: `speed(v) = (16^v − 1) / 3`.

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
  MIT-licensed. **[INTERPRETIVE]** If a vendored library's copyleft terms
  conflict with distributing the combined work this way, the conflict is
  flagged at vendoring time with options (relicense the repo vs. reimplement
  the technique with citation).
- Known intended sources so far: Handy (Jo Wood, giCentre — hand-drawn
  sketchy rendering, native Processing); techniques from Wood et al.,
  "Sketchy Rendering for Information Visualization" (also the basis of
  rough.js); a text/cursive generation source TBD for the asemic-writing
  style; nanoKONTROL2 access library TBD (korgnano or equivalent, vendored).

## 7. Program architecture

**[INTERPRETIVE]** — the interface below is a proposal codifying the
requirements in §1 and §4; approve or revise before Phase 1.

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
  release on deactivate) is the mode's responsibility.
- Boot state: style 1, mode 1, parameters read from physical positions.

## 8. Repository

- Public GitHub repo. Layout:

```
ProceduralDoodleMachine/       # main Processing sketch
studies/                       # one self-contained sketch per style candidate
benchmarks/                    # Phase 0 suite + results tables
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

- **Phase 0 — Pi benchmarking (robust and expansive).** Renderer comparison
  (JAVA2D/P2D/P3D), line/stroke throughput at 720p and 1080p (raw primitives
  and Handy-style multi-stroke rendering), offscreen PGraphics costs,
  alpha-blend fill rate, GLSL support and cost on the V3D driver (full-res
  fragment passes, ping-pong feedback), MIDI latency sanity check, thermal
  throttling over a sustained 20-minute run. Output: results tables committed
  to `benchmarks/`, and hard budgets + renderer/GLSL policy written back into
  this spec (v0.2).
- **Phase 1 — Skeleton.** Main sketch: MIDI layer, global controls, palette
  system, style/mode switching, clock, with placeholder styles.
- **Phases 2..n — Style studies.** One style at a time: brainstorm → study
  sketch → aesthetic refinement iterations → port into main sketch.
  The 8-style list is provided and iterated collaboratively before Phase 2.
- **Late phases.** Transport button assignments; headless boot; FORK_GUIDE.

Every phase gates on explicit approval before implementation.

---

*PDM_SPEC v0.1 — draft for review. Changes on approval are folded into v0.2
along with Phase 0 results.*
