// Stage definitions and load renderers for the automated battery.
//
// Every test draws into an offscreen PGraphics at the tier resolution
// (720p / 1080p) and composites it scaled to the physical screen. This
// mirrors the internal-resolution degradation guardrail from PDM_SPEC §3,
// so the guardrail mechanism itself is exercised by every measurement.

class Stage {
  int id;
  String name;      // short name used in CSV/summary
  String loadName;  // what the ladder counts
  int[] ladder;     // ascending load steps
  boolean needsGL;
  Stage(int id, String name, String loadName, int[] ladder, boolean needsGL) {
    this.id = id; this.name = name; this.loadName = loadName;
    this.ladder = ladder; this.needsGL = needsGL;
  }
}

void buildStages() {
  // [INTERPRETIVE] Ladder ranges chosen to bracket plausible Pi4/Mac limits;
  // geometric steps (~2x) so each stage finishes in a handful of windows.
  stages.add(new Stage(1, "T1_lines",    "lines",      new int[]{500, 1000, 2000, 4000, 8000, 16000, 32000, 64000, 128000}, false));
  stages.add(new Stage(2, "T2_curves",   "vertices",   new int[]{500, 1000, 2000, 4000, 8000, 16000, 32000, 64000},         false));
  stages.add(new Stage(3, "T3_sketchy",  "strokes",    new int[]{250, 500, 1000, 2000, 4000, 8000, 16000, 32000},           false));
  stages.add(new Stage(4, "T4_alpha",    "ellipses",   new int[]{100, 200, 400, 800, 1600, 3200, 6400, 12800},              false));
  stages.add(new Stage(5, "T5_buffers",  "buffers",    new int[]{1, 2, 3, 4, 6, 8, 10, 12},                                 false));
  stages.add(new Stage(6, "T6_filter",   "passes",     new int[]{1, 2, 4, 6, 8, 12, 16, 24},                                true));
  stages.add(new Stage(7, "T7_feedback", "iterations", new int[]{1, 2, 4, 6, 8, 12, 16, 24},                                true));
}

void renderLoad(Stage st, int resIx, int load) {
  PGraphics g = pgTier[resIx];
  switch (st.id) {
    case 1: loadLines(g, load);   break;
    case 2: loadCurves(g, load);  break;
    case 3: loadSketchy(g, load); break;
    case 4: loadAlpha(g, load);   break;
    case 5: loadBuffers(resIx, load); return;  // composites to screen itself
    case 6: loadFilter(g, load);   break;
    case 7: loadFeedback(resIx, load); return; // composites to screen itself
  }
  image(g, 0, 0, width, height);
}

// ---- T1: raw line throughput ----
void loadLines(PGraphics g, int n) {
  g.beginDraw();
  g.background(0);
  g.strokeWeight(1);
  g.randomSeed(1234);           // identical geometry every frame of a window
  for (int i = 0; i < n; i++) {
    g.stroke((i * 7) % 360, 100, 100);
    g.line(g.random(g.width), g.random(g.height), g.random(g.width), g.random(g.height));
  }
  g.endDraw();
}

// ---- T2: curveVertex polylines (50 vertices each) ----
void loadCurves(PGraphics g, int totalVerts) {
  int perLine = 50;
  int lines = max(1, totalVerts / perLine);
  g.beginDraw();
  g.background(0);
  g.noFill();
  g.strokeWeight(1);
  g.randomSeed(2345);
  for (int i = 0; i < lines; i++) {
    g.stroke((i * 13) % 360, 100, 100);
    g.beginShape();
    float x = g.random(g.width), y = g.random(g.height);
    for (int v = 0; v < perLine; v++) {
      x += g.random(-40, 40);
      y += g.random(-40, 40);
      g.curveVertex(x, y);
    }
    g.endShape();
  }
  g.endDraw();
}

// ---- T3: sketchy strokes (Handy/rough.js-style cost model) ----
// Each "stroke" = the same segment drawn twice with independent endpoint
// jitter (the double-stroke technique of Wood et al. / rough.js). Every
// 20th stroke additionally triggers a hachure-filled circle (11 chords at
// 45 degrees). [INTERPRETIVE] This approximates Handy's per-mark cost
// without vendoring the library yet; real Handy also bows midpoints, which
// is a comparable per-vertex cost.
void loadSketchy(PGraphics g, int strokes) {
  g.beginDraw();
  g.background(0);
  g.strokeWeight(1.5);
  g.randomSeed(3456);
  float ca = cos(QUARTER_PI), sa = sin(QUARTER_PI);
  for (int i = 0; i < strokes; i++) {
    g.stroke((i * 11) % 360, 90, 100);
    float x1 = g.random(g.width),  y1 = g.random(g.height);
    float x2 = x1 + g.random(-160, 160), y2 = y1 + g.random(-160, 160);
    for (int pass = 0; pass < 2; pass++) {
      float j = 2.5;
      g.line(x1 + g.random(-j, j), y1 + g.random(-j, j),
             x2 + g.random(-j, j), y2 + g.random(-j, j));
    }
    if (i % 20 == 0) {  // hachure-filled circle
      float cx = g.random(g.width), cy = g.random(g.height), r = 40;
      for (int k = -5; k <= 5; k++) {
        float d = k * r / 6.0;
        float half = sqrt(max(r * r - d * d, 0));
        // chord endpoints in local space, rotated 45 degrees
        float lx1 = -half, lx2 = half;
        g.line(cx + lx1 * ca - d * sa, cy + lx1 * sa + d * ca,
               cx + lx2 * ca - d * sa, cy + lx2 * sa + d * ca);
      }
    }
  }
  g.endDraw();
}

// ---- T4: alpha-blend fill rate ----
void loadAlpha(PGraphics g, int n) {
  g.beginDraw();
  g.noStroke();
  g.fill(0, 0, 0, 10);              // full-buffer translucent trail wipe
  g.rect(0, 0, g.width, g.height);
  g.randomSeed(4567);
  float t = millis() / 1000.0;
  for (int i = 0; i < n; i++) {
    g.fill((i * 17) % 360, 100, 100, 20);
    float x = g.random(g.width) + 30 * sin(t + i);
    g.ellipse(x, g.random(g.height), 60, 60);
  }
  g.endDraw();
}

// ---- T5: offscreen buffer count + compositing ----
PGraphics[] t5bufs = null;
int t5K = -1, t5Res = -1;

void loadBuffers(int resIx, int K) {
  if (t5bufs == null || t5K != K || t5Res != resIx) {
    t5bufs = new PGraphics[K];
    for (int i = 0; i < K; i++) {
      t5bufs[i] = createGraphics(RES[resIx][0], RES[resIx][1], rendererString());
      t5bufs[i].beginDraw();
      t5bufs[i].colorMode(HSB, 360, 100, 100, 100);
      t5bufs[i].background(0, 0);
      t5bufs[i].endDraw();
    }
    t5K = K; t5Res = resIx;
  }
  for (int i = 0; i < K; i++) {
    PGraphics b = t5bufs[i];
    b.beginDraw();
    b.clear();
    b.strokeWeight(1);
    b.randomSeed(100 + i);
    for (int L = 0; L < 50; L++) {
      b.stroke((i * 40 + L * 5) % 360, 100, 100);
      b.line(b.random(b.width), b.random(b.height), b.random(b.width), b.random(b.height));
    }
    b.endDraw();
  }
  background(0);
  tint(0, 0, 100, 60);
  for (int i = 0; i < K; i++) image(t5bufs[i], 0, 0, width, height);
  noTint();
}

// ---- T6a: full-res fragment filter passes ----
void loadFilter(PGraphics g, int passes) {
  g.beginDraw();
  g.background(0);
  g.noStroke();
  g.randomSeed(6789);
  for (int i = 0; i < 20; i++) {
    g.fill((i * 31) % 360, 100, 100);
    g.ellipse(g.random(g.width), g.random(g.height), 120, 120);
  }
  genShader.set("time", (float) (millis() / 1000.0));
  for (int p = 0; p < passes; p++) g.filter(genShader);
  g.endDraw();
}

// ---- T6b: ping-pong feedback iterations ----
// Classic two-buffer video-feedback pattern (see docs/CREDITS.md).
PGraphics fbA = null, fbB = null;
int fbRes = -1;

void loadFeedback(int resIx, int iterations) {
  if (fbA == null || fbRes != resIx) {
    fbA = createGraphics(RES[resIx][0], RES[resIx][1], rendererString());
    fbB = createGraphics(RES[resIx][0], RES[resIx][1], rendererString());
    for (PGraphics b : new PGraphics[]{fbA, fbB}) {
      b.beginDraw();
      b.colorMode(HSB, 360, 100, 100, 100);
      b.background(0);
      b.endDraw();
    }
    fbRes = resIx;
  }
  float t = millis() / 1000.0;
  for (int it = 0; it < iterations; it++) {
    PGraphics src = fbA, dst = fbB;
    dst.beginDraw();
    dst.shader(warpShader);
    dst.image(src, 0, 0, dst.width, dst.height);
    dst.resetShader();
    // inject a moving seed line so the feedback has content
    dst.strokeWeight(3);
    dst.stroke((t * 60) % 360, 100, 100);
    float cx = dst.width / 2, cy = dst.height / 2;
    dst.line(cx, cy, cx + 300 * cos(t * 1.7 + it), cy + 300 * sin(t * 1.3 + it));
    dst.endDraw();
    PGraphics tmp = fbA; fbA = fbB; fbB = tmp;
  }
  image(fbA, 0, 0, width, height);
}

// ---- free per-stage resources so stages don't pollute each other ----
void releaseStageResources() {
  t5bufs = null; t5K = -1; t5Res = -1;
  fbA = null; fbB = null; fbRes = -1;
  System.gc();  // [INTERPRETIVE] nudge; PGraphics have no explicit dispose in Processing 4
}
