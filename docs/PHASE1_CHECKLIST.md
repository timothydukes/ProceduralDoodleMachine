# PDM Phase 1 — Acceptance Checklist

Run this on the Pi with the nanoKONTROL2 connected and the HDMI display at
1280×720. Launch: open `ProceduralDoodleMachine/ProceduralDoodleMachine.pde`
in Processing 4.3, press Run. (Also worth one pass on the Mac afterward.)

Press **Z** once at the start to show the debug HUD — most checks read
from it. Press Z again at the end to confirm the output is clean with it
off.

1. **Boot.** Sketch opens fullscreen, no cursor, placeholder style 1 mode 1
   drawing on black. HUD shows `style 1 ... mode 1`, `midi:` names the
   controller, fps ≥ 55.
2. **Buttons — all 24.** Press every S, M, and R button, all 8 columns.
   Each press switches immediately; HUD tracks style = column, mode = row
   (S=1, M=2, R=3). Neighboring slots look visually distinct. Pressing the
   currently active button again: nothing happens (no flicker/reset).
3. **Sliders/knobs live-adopt.** Before touching anything, note the HUD
   `touched` row shows all dots (boot defaults active). Move slider 1;
   its dot becomes `S` and zoom responds from that moment. This is the
   expected lazy adoption — MIDI cannot report positions before first
   movement.
4. **Zoom (slider 1).** Bottom: small figure floating on background.
   Top: figure clearly extends beyond all four screen edges.
5. **Rotate (knob 1).** Full left: upside down. Full right: upside down.
   Center: upright — and confirm a lazy near-center position (not
   precisely 12 o'clock) still reads `rot 0.0deg` on the HUD.
6. **Pan (slider 2 / knob 2).** Figure translates horizontally /
   vertically; centered at 0.5.
7. **Density (slider 3).** Bottom: a few minimal elements. Top: dense.
8. **Stroke weight (knob 3).** Hairline → marker.
9. **s7 (slider 7).** On the rainbow palette: at 0 all elements share one
   color; raising it spreads hues across elements.
10. **Hue LFO (knob 7).** At 0: colors static (HUD phase frozen). Raise:
    colors drift, snapping between palette colors (quantized, not smooth).
    On the b/w palette: no visible color change at any LFO speed.
11. **Master speed (slider 8).** At 0: motion frozen (color LFO keeps
    drifting — by design). At center: normal. Top: fast (~5×). HUD `speed`
    reads ~0.00 / ~1.00 / ~5.00 at those positions.
12. **Palette (knob 8).** Sweeping steps through all 12 (HUD shows
    name); inverted palettes flip to light backgrounds.
13. **Switch semantics.** Set some sliders to extremes, switch style —
    the new style adopts the current physical values immediately.
14. **Transport.** Hold each transport button; HUD `transport` row shows
    its name while held. No other effect (reserved).
15. **Guardrail (synthetic).** Not testable at placeholder loads —
    placeholders sit far under budget by design. Verified per-style later.
16. **Absent-controller exit.** Quit, unplug the nanoKONTROL2, relaunch:
    a clear on-screen message, then the sketch exits by itself.
17. **Clean output.** Z off: no text or overlay anywhere on the output.
18. **fps.** With HUD on, worst observed fps across all 24 slots at max
    density: note the number. Expected well above 30 everywhere.

Report any failing number by step; include HUD readings where relevant.
