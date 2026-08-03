// PDM_Bench_v1 — Phase 0 benchmark suite for the Procedural Doodle Machine
// See PDM_SPEC v0.1 §9. Runs an automated battery of rendering tests,
// then offers an optional MIDI responsiveness check and (Pi) thermal soak.
//
// USAGE: set RENDERER_CHOICE in the CONFIG tab, press Run, hands off.
// Three runs per machine (JAVA2D, P2D, P3D). Results are written as CSV +
// plain-text summary into this sketch folder.
//
// Original code, MIT license. Methodology notes / prior-art citations in
// docs/CREDITS.md of the PDM repository.

import javax.sound.midi.*;

// ---- run modes ----
static final int MODE_RUN = 0;      // automated battery in progress
static final int MODE_MENU = 1;     // battery done, waiting for M/T/Q
static final int MODE_MIDI = 2;     // MIDI responsiveness check
static final int MODE_THERMAL = 3;  // 20-minute thermal soak (Pi)
int mode = MODE_RUN;

// ---- resolution tiers (internal render buffers, scaled to screen) ----
int[][] RES = { {1280, 720}, {1920, 1080} };
String[] RES_NAME = { "720p", "1080p" };
PGraphics[] pgTier = new PGraphics[2];

// ---- runner state ----
ArrayList<Stage> stages = new ArrayList<Stage>();
int sIx = 0, rIx = 0, lIx = 0;
static final int PH_SETTLE = 0, PH_MEASURE = 1;
int phase = PH_SETTLE;
int phaseStart;         // millis
int framesInWindow = 0;
int lastPassLoad = -1;
float lastPassFps = -1;
float liveFps = 0;      // most recent completed window fps, for HUD

// carried into thermal test: max sustainable sketchy load at 720p
int t3Max720 = 4000;    // [INTERPRETIVE] fallback if T3 didn't complete

boolean glAvailable;
PShader genShader, warpShader;
boolean shadersOk = false;

String machineLabel, rendererLabel, stamp;

void settings() {
  String r = P2D;
  if (RENDERER_CHOICE.equals("P3D")) r = P3D;
  else if (RENDERER_CHOICE.equals("JAVA2D")) r = JAVA2D;
  else if (!RENDERER_CHOICE.equals("P2D"))
    println("WARNING: unknown RENDERER_CHOICE '" + RENDERER_CHOICE + "', using P2D");
  fullScreen(r);
}

String rendererString() {
  if (RENDERER_CHOICE.equals("P3D")) return P3D;
  if (RENDERER_CHOICE.equals("JAVA2D")) return JAVA2D;
  return P2D;
}

void setup() {
  noCursor();
  frameRate(120);  // attempt to lift the cap; vsync may still hold 60 on GL
  colorMode(HSB, 360, 100, 100, 100);

  String os = System.getProperty("os.name").toLowerCase();
  machineLabel = os.contains("mac") ? "mac" : "pi";  // [INTERPRETIVE] two-machine world
  rendererLabel = RENDERER_CHOICE.toLowerCase();
  stamp = nf(year(),4) + nf(month(),2) + nf(day(),2) + "_" + nf(hour(),2) + nf(minute(),2);

  glAvailable = !RENDERER_CHOICE.equals("JAVA2D");

  // internal render tiers
  for (int i = 0; i < 2; i++) {
    pgTier[i] = createGraphics(RES[i][0], RES[i][1], rendererString());
    pgTier[i].beginDraw();
    pgTier[i].colorMode(HSB, 360, 100, 100, 100);
    pgTier[i].background(0);
    pgTier[i].endDraw();
  }

  if (glAvailable) {
    try {
      genShader = loadShader("gen.glsl");
      warpShader = loadShader("warp.glsl");
      shadersOk = true;
    } catch (Exception e) {
      shadersOk = false;
      note("SHADER LOAD FAILED: " + e.getMessage());
    }
  }

  buildStages();
  openCsv();
  note("PDM_Bench_v1  machine=" + machineLabel + "  renderer=" + rendererLabel
       + "  screen=" + width + "x" + height + "  " + stamp);
  note("fps floor=" + FPS_FLOOR + "  window=" + WINDOW_SEC + "s  settle=" + SETTLE_SEC + "s");

  phaseStart = millis();
}

void draw() {
  switch (mode) {
    case MODE_RUN:     drawRun();     break;
    case MODE_MENU:    drawMenu();    break;
    case MODE_MIDI:    drawMidi();    break;
    case MODE_THERMAL: drawThermal(); break;
  }
}

// ---------------- automated battery ----------------

void drawRun() {
  Stage st = stages.get(sIx);

  // skip GL-only stages when unavailable
  if (st.needsGL && !(glAvailable && shadersOk)) {
    note(st.name + ": SKIPPED (renderer has no shader support)");
    csvRow(st.name, "-", st.loadName, 0, 0, "skip");
    nextStage();
    return;
  }

  background(0);
  renderLoad(st, rIx, st.ladder[lIx]);
  hud(st);

  int now = millis();
  if (phase == PH_SETTLE) {
    if (now - phaseStart >= SETTLE_SEC * 1000) {
      phase = PH_MEASURE;
      phaseStart = now;
      framesInWindow = 0;
    }
  } else {
    framesInWindow++;
    float elapsed = (now - phaseStart) / 1000.0;
    if (elapsed >= WINDOW_SEC) {
      float fps = framesInWindow / elapsed;
      liveFps = fps;
      boolean pass = fps >= FPS_FLOOR;
      csvRow(st.name, RES_NAME[rIx], st.loadName, st.ladder[lIx], fps, pass ? "pass" : "fail");
      if (pass) {
        lastPassLoad = st.ladder[lIx];
        lastPassFps = fps;
        lIx++;
        if (lIx >= st.ladder.length) finishRes(st, "ladder maxed");
        else { phase = PH_SETTLE; phaseStart = millis(); }
      } else {
        finishRes(st, "fell below floor");
      }
    }
  }
}

void finishRes(Stage st, String why) {
  String line;
  if (lastPassLoad < 0)
    line = st.name + " @ " + RES_NAME[rIx] + ": NONE sustainable (lowest load already < "
           + int(FPS_FLOOR) + " fps)";
  else
    line = st.name + " @ " + RES_NAME[rIx] + ": max " + st.loadName + " = " + lastPassLoad
           + " (" + nf(lastPassFps, 0, 1) + " fps; " + why + ")";
  note(line);

  if (st.id == 3 && rIx == 0 && lastPassLoad > 0) t3Max720 = lastPassLoad;

  rIx++;
  lIx = 0;
  lastPassLoad = -1; lastPassFps = -1;
  phase = PH_SETTLE; phaseStart = millis();
  if (rIx >= 2) nextStage();
}

void nextStage() {
  releaseStageResources();
  rIx = 0; lIx = 0;
  lastPassLoad = -1; lastPassFps = -1;
  phase = PH_SETTLE; phaseStart = millis();
  sIx++;
  if (sIx >= stages.size()) {
    note("--- automated battery complete ---");
    saveSummary();
    mode = MODE_MENU;
  }
}

// ---------------- menu ----------------

void drawMenu() {
  background(0);
  fill(0, 0, 100);
  textAlign(LEFT, TOP);
  textSize(constrain(height / 45, 12, 22));
  float y = 20;
  text("PDM_Bench_v1 — AUTOMATED TESTS COMPLETE (" + machineLabel + " / " + rendererLabel + ")", 20, y);
  y += 40;
  text("[M] MIDI responsiveness check (plug in nanoKONTROL2 first)", 20, y); y += 26;
  text("[T] 20-minute thermal soak (Pi; runs sketchy scene at load " + t3Max720 + ")", 20, y); y += 26;
  text("[Q] save summary + quit", 20, y); y += 40;
  text("Results so far:", 20, y); y += 26;
  int start = max(0, summaryLines.size() - 24);
  for (int i = start; i < summaryLines.size(); i++) {
    text(summaryLines.get(i), 20, y);
    y += 22;
  }
}

void keyPressed() {
  if (mode == MODE_MENU) {
    if (key == 'm' || key == 'M') startMidiTest();
    if (key == 't' || key == 'T') startThermal();
    if (key == 'q' || key == 'Q') { saveSummary(); closeCsv(); exit(); }
  } else if (mode == MODE_RUN) {
    if (key == 's' || key == 'S') {  // manual skip of a stuck stage
      note(stages.get(sIx).name + ": SKIPPED MANUALLY");
      nextStage();
    }
  } else if (mode == MODE_MIDI || mode == MODE_THERMAL) {
    if (key == 'q' || key == 'Q') { endSideTest(); }
  }
}

// ---------------- HUD ----------------

void hud(Stage st) {
  int barH = max(28, height / 24);
  noStroke();
  fill(0, 0, 0);
  rect(0, height - barH, width, barH);
  fill(0, 0, 100);
  textAlign(LEFT, CENTER);
  textSize(constrain(barH - 12, 10, 20));
  String ph = (phase == PH_SETTLE) ? "settle" : "measure";
  text("stage " + (sIx + 1) + "/" + stages.size() + "  " + st.name
       + "  |  " + RES_NAME[rIx] + "  |  " + st.loadName + "=" + st.ladder[lIx]
       + "  |  " + ph + "  |  last window " + nf(liveFps, 0, 1) + " fps  |  [S] skip stage",
       12, height - barH / 2);
}
