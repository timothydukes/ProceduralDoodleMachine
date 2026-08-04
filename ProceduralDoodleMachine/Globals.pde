// Approved global mappings (spec §4.2-§4.4) and the per-frame state update.

void updateState(float dtReal) {
  // copy raws from the MIDI thread
  for (int i = 0; i < 8; i++) { st.slider[i] = nano.sliders[i]; st.knob[i] = nano.knobs[i]; }

  st.zoom        = st.slider[0];
  st.rot         = rotateDetent(st.knob[0]);
  st.panX        = st.slider[1];
  st.panY        = st.knob[1];
  st.density     = st.slider[2];
  st.strokeW     = st.knob[2];
  st.colorCtl    = st.slider[6];
  st.hueLfoSpeed = st.knob[6];
  st.speed       = speedCurve(st.slider[7]);
  st.paletteIx   = paletteIndex(st.knob[7]);
  st.palette     = palettes[st.paletteIx];

  float lfoDt = HUE_LFO_USES_REAL_TIME ? dtReal : dtReal * st.speed;
  st.hueLfoPhase = (st.hueLfoPhase + hueLfoRate(st.hueLfoSpeed) * lfoDt) % 360.0;

  st.dt = dtReal * st.speed;
  st.t += st.dt;
}

// §4.3: flat zero zone (0.47, 0.53); smoothstep to ±PI at the ends.
// smoothstep has zero slope at both ends: C1 at the detent edge, and full
// deflection lands exactly on ±PI.
float rotateDetent(float v) {
  if (v > 0.47 && v < 0.53) return 0;
  if (v >= 0.53) return  PI * smoothstepU((v - 0.53) / 0.47);
  return              -PI * smoothstepU((0.47 - v) / 0.47);
}

float smoothstepU(float u) {
  u = constrain(u, 0, 1);
  return u * u * (3 - 2 * u);
}

// §4.4: f(0)=0 frozen, f(0.5)=1x, f(1)=5x.
float speedCurve(float v) {
  return (pow(16, v) - 1) / 3.0;
}

// Knob 8 -> 12 palettes, stepped. Top of range folds into the last bank slot.
int paletteIndex(float v) {
  return min(int(v * palettes.length), palettes.length - 1);
}

// Hue LFO rate in degrees/second. Squared for a gentle low end; 0 -> off.
float hueLfoRate(float v) {
  return HUE_LFO_MAX_DPS * v * v;
}

// ---- recommended helpers for styles (not mandated by spec) ----

// [INTERPRETIVE] Zoom helper satisfying §4.2 semantics: exponential scale,
// ~0.18x (small image on background) to ~2.8x (a full-frame figure extends
// beyond the screen borders). Styles may use this or interpret zoom
// themselves, provided they respond sensibly.
float zoomScale(float v) {
  return pow(2, lerp(-2.5, 1.5, v));
}

// [INTERPRETIVE] Stroke-weight helper: 0.5px hairline to 8px marker.
float strokePx(float v) {
  return lerp(0.5, 8.0, v * v);
}
