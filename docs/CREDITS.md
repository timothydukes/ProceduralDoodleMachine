# PDM — Credits and Sources

Maintained from the first commit per PDM_SPEC §6. Every vendored library,
adapted algorithm, and inspiration source is listed here with origin,
license, and what was modified. Original PDM code is MIT-licensed;
vendored files retain their original license headers.

## Platform

- **Processing 4.3** — Ben Fry, Casey Reas, and the Processing Foundation.
  https://processing.org — core libraries LGPL. Used as the runtime; not
  vendored.

## Algorithms and techniques (adapted or planned)

- **Sketchy-stroke cost model (PDM_Bench_v1, test T3).** The
  double-stroke-with-jitter technique and hachure fills follow
  Wood, J., Isenberg, P., Isenberg, T., Dykes, J., Boukhelifa, N.,
  Slingsby, A., "Sketchy Rendering for Information Visualization,"
  IEEE Transactions on Visualization and Computer Graphics 18(12), 2012.
  Benchmark implementation is original; it approximates the per-mark cost
  of the Handy library ahead of vendoring it.
- **Handy** — Jo Wood, giCentre, City University London.
  https://github.com/gicentre/handy — hand-drawn sketchy rendering for
  Processing. PLANNED VENDOR for the hand-drawn styles; license to be
  verified and recorded here at vendoring time.
- **rough.js algorithm notes** — Preet Shihn,
  https://shihn.ca/posts/2020/roughjs-algorithms/ — supplementary
  reference on sketchy-line/ellipse construction (same lineage as the
  Wood et al. paper). Reference only; no code taken.
- **Ping-pong feedback buffers (PDM_Bench_v1, test T6b).** Two-buffer
  video-feedback with a warp shader is common practice in the
  Processing/openFrameworks live-video communities; see e.g. Andrei Jay's
  VSERPI ecosystem (https://andreijaycreativecoding.com) for context.
  Implementation here is original.

## Prior art / design context (no code taken)

- **ANIPUNK** — the author's own earlier spec for MIDI-controlled
  Processing programs; PDM inherits several conventions (HSB color mode,
  normalized controls, fullScreen/noCursor) as documented in PDM_SPEC.
- **EYESY** (Critter & Guitari) — mode-per-script Pi video synth;
  structural precedent for style/mode selection.
- **VSERPI** (Andrei Jay), **r_e_c_u_r / recurBOY** (cyberboy666 et al.)
  — Raspberry Pi video-instrument ecosystem; precedent for the Pi 4 +
  class-compliant MIDI controller platform choice.

## Pending

- nanoKONTROL2 MIDI access library (to vendor in Phase 1; candidate:
  korgnano — origin and license to be verified and recorded here).
- Asemic writing / cursive generation source (style TBD).
