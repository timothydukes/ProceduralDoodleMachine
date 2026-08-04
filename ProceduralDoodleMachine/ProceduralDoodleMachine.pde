// Procedural Doodle Machine — Phase 1 skeleton
// Spec: docs/PDM_SPEC_v0.2.md (approved). Renderer P3D, 720p internal,
// nanoKONTROL2 factory map, 8 styles x 3 modes (placeholders in Phase 1).
//
// Original code, MIT license. Sources and citations: docs/CREDITS.md.

import javax.sound.midi.*;

PdmNano nano;
PdmState st;
Palette[] palettes;
DoodleStyle[] styles;
Guardrail guardrail;
PGraphics pg;

boolean debugOn = false;        // Z toggles; dev tool, defaults off
String fatalMsg = null;
int fatalSince = 0;
int lastMillis;

void settings() {
  fullScreen(P3D);
}

void setup() {
  noCursor();
  frameRate(60);
  colorMode(HSB, 360, 100, 100, 100);

  pg = createGraphics(INTERNAL_W, INTERNAL_H, P3D);
  pg.beginDraw();
  pg.colorMode(HSB, 360, 100, 100, 100);
  pg.background(0);
  pg.endDraw();

  buildPalettes();
  buildStyles();
  guardrail = new Guardrail();

  st = new PdmState();
  st.pg = pg;

  nano = new PdmNano();
  if (!nano.open()) {
    // Spec §2: exit with a clear message if the controller is absent.
    // [INTERPRETIVE] message is shown on screen for a few seconds before
    // exiting, so a desktop launch doesn't just vanish silently.
    fatalMsg = "nanoKONTROL2 not found.\nPlug it in and relaunch.";
    fatalSince = millis();
    println("FATAL: " + fatalMsg.replace('\n', ' '));
  }

  // Boot state: style 1 mode 1. NOTE: MIDI cannot report physical control
  // positions until each control is first moved (nanoKONTROL2 has no
  // position dump in the factory scene), so "read from physical positions"
  // is satisfied lazily: defaults below apply until first touch, then the
  // physical value takes over. [INTERPRETIVE] defaults: everything 0.5
  // (rotate 0, speed 1x, pans centered) except hue LFO speed = 0 (no
  // rotation, per its own zero-means-off semantics).
  switchTo(0, 0);
  lastMillis = millis();
}

void draw() {
  if (fatalMsg != null) { drawFatal(); return; }

  // real dt, clamped against stalls
  int now = millis();
  float dtReal = min((now - lastMillis) / 1000.0, 0.1);
  lastMillis = now;

  // pending style/mode switch from the MIDI thread (radio-button select)
  int ps = nano.pendingStyle, pm = nano.pendingMode;
  if (ps >= 0) {
    nano.pendingStyle = -1;
    switchTo(ps, pm);
  }

  updateState(dtReal);

  DoodleMode m = activeMode();
  m.update(st, st.dt);
  pg.beginDraw();
  m.render(st, pg);
  pg.endDraw();

  image(pg, 0, 0, width, height);   // 1:1 when display is 720p (recommended)

  guardrail.tick(st, m);
  if (debugOn) drawDebug();
}

DoodleMode activeMode() {
  return styles[st.styleIx].modes[st.modeIx];
}

void switchTo(int styleIx, int modeIx) {
  if (st.styleIx == styleIx && st.modeIx == modeIx && st.booted) return;
  if (st.booted) activeMode().deactivate(st);
  st.styleIx = styleIx;
  st.modeIx = modeIx;
  st.booted = true;
  activeMode().activate(st);
}

void keyPressed() {
  if (key == 'z' || key == 'Z') debugOn = !debugOn;
}

void drawFatal() {
  background(0);
  fill(0, 100, 100);
  textAlign(CENTER, CENTER);
  textSize(constrain(height / 20, 16, 48));
  text(fatalMsg, width / 2, height / 2);
  if (millis() - fatalSince > 6000) exit();
}

void exit() {
  if (nano != null) nano.close();
  super.exit();
}
