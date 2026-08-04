// Constants. Spec references: PDM_SPEC_v0.2 §3 (resolution, floor),
// §4 (controls), §5 (palettes).

static final int INTERNAL_W = 1280;
static final int INTERNAL_H = 720;

static final float DEFAULT_FPS_FLOOR = 30.0;

// Boot defaults until first physical touch (see Main setup note).
static final float DEFAULT_ANALOG = 0.5;
static final float DEFAULT_HUE_LFO = 0.0;

// Hue LFO: max rotation rate in degrees/second at knob 7 = 1.0.
// [INTERPRETIVE] 180 deg/s max, squared response for a gentle low end.
static final float HUE_LFO_MAX_DPS = 180.0;

// [INTERPRETIVE] Hue LFO runs on real time, not the master-speed clock:
// freezing motion (slider 8 = 0) should not freeze the global color drift.
// Flip this if aesthetic testing disagrees.
static final boolean HUE_LFO_USES_REAL_TIME = true;
