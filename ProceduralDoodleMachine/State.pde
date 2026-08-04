// PdmState — the single object every DoodleMode receives. Carries raw
// normalized controls, derived globals (spec §4.2-§4.4), the shared clock,
// the active palette, and the internal render target.

class PdmState {
  // raw normalized controls (0.0-1.0), copied once per frame from PdmNano
  float[] slider = new float[8];
  float[] knob = new float[8];

  // derived globals (spec §4.2)
  float zoom;          // slider 1 raw (styles interpret; helper: zoomScale())
  float rot;           // knob 1 -> radians via detent map (§4.3)
  float panX, panY;    // slider 2 / knob 2 raw (0.5 = centered)
  float density;       // slider 3 raw
  float strokeW;       // knob 3 raw (helper: strokePx())
  float colorCtl;      // slider 7 raw (meaning defined per style)
  float hueLfoSpeed;   // knob 7 raw
  float hueLfoPhase;   // degrees, advances continuously (Config policy)
  float speed;         // slider 8 -> multiplier via (16^v - 1)/3 (§4.4)
  int paletteIx;       // knob 8 -> 0..11 stepped
  Palette palette;

  // shared clock (§4.4): t advances by dt = dtReal * speed
  float t = 0;
  float dt = 0;

  // active selection
  int styleIx = 0, modeIx = 0;
  boolean booted = false;

  // internal render target (720p, spec §3) — same object passed to render()
  PGraphics pg;
}
