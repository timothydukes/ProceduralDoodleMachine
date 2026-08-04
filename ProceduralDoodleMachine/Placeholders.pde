// PlaceholderMode — Phase 1 stand-ins for all 24 style/mode slots.
// Purpose: prove every wire (buttons, all ten global mappings, palette
// quantization, clock, guardrail) before real aesthetic work. Six visual
// flavors cycle across the 24 slots so neighboring slots look distinct.
//
// Global responses (so the acceptance checklist can verify each):
//   zoom    -> figure scale (zoomScale helper)
//   rotate  -> figure rotation
//   pan     -> figure translation (+-40% of frame)
//   density -> element count (4 .. ~220, well under §3.1 budgets)
//   strokeW -> strokeWeight (strokePx helper)
//   s7      -> hue spread across elements (placeholder meaning only)
//   hue LFO -> base hue drift, quantized to the active palette
//   palette -> bg + ink constraint
//   speed   -> all motion runs on s.t
// All placeholders are animate-temporality (cleared frames); accumulation
// plumbing is exercised when the first accumulating style study lands.

class PlaceholderMode extends DoodleMode {
  int styleIx, modeIx, flavor;
  int degradeSteps = 0;   // guardrail demo: each degrade() halves count

  PlaceholderMode(int styleIx, int modeIx) {
    this.styleIx = styleIx;
    this.modeIx = modeIx;
    this.flavor = (styleIx * 3 + modeIx) % 6;
  }

  void activate(PdmState s) { degradeSteps = 0; }
  void update(PdmState s, float dt) {}
  void degrade() { degradeSteps = min(degradeSteps + 1, 4); }

  void render(PdmState s, PGraphics g) {
    g.background(s.palette.bg());
    g.pushMatrix();
    g.translate(g.width / 2 + (s.panX - 0.5) * g.width * 0.8,
                g.height / 2 + (s.panY - 0.5) * g.height * 0.8);
    g.rotate(s.rot);
    float sc = zoomScale(s.zoom);
    g.scale(sc);

    int n = int(map(s.density, 0, 1, 4, 220)) >> degradeSteps;
    n = max(n, 2);
    g.strokeWeight(strokePx(s.strokeW) / sc);   // keep apparent weight stable-ish under zoom
    g.noFill();

    float hueSpan = s.colorCtl * 360;           // s7 placeholder meaning: hue spread
    for (int i = 0; i < n; i++) {
      g.stroke(s.palette.quantize(s.hueLfoPhase + i * hueSpan / max(n, 1)));
      drawElement(g, s, i, n);
    }
    g.popMatrix();
  }

  void drawElement(PGraphics g, PdmState s, int i, int n) {
    float t = s.t;
    switch (flavor) {
      case 0: { // concentric polygons
        int sides = 3 + i % 7;
        float r = 14 + i * 9;
        polygon(g, 0, 0, r, sides, t * 0.1 * ((i % 2 == 0) ? 1 : -1));
        break;
      }
      case 1: { // spokes
        float a = i * TWO_PI / n + t * 0.25;
        g.line(0, 0, 260 * cos(a), 260 * sin(a));
        break;
      }
      case 2: { // drifting grid dots
        int side = max(1, ceil(sqrt(n)));
        float cell = 480.0 / side;
        float x = (i % side - (side - 1) / 2.0) * cell;
        float y = (i / side - (side - 1) / 2.0) * cell;
        float w = cell * 0.3 * (1 + 0.4 * sin(t + i));
        g.ellipse(x, y, w, w);
        break;
      }
      case 3: { // seeded scribble walks
        g.beginShape();
        float x = -240 + (i % 8) * 68, y = -200 + (i / 8) * 60;
        for (int v = 0; v < 10; v++) {
          x += 40 * (noise(i * 13.7, v * 0.5, t * 0.15) - 0.5);
          y += 40 * (noise(i * 7.3, v * 0.5 + 50, t * 0.15) - 0.5);
          g.vertex(x, y);
        }
        g.endShape();
        break;
      }
      case 4: { // nested rotated squares
        float r = 16 + i * 8;
        polygon(g, 0, 0, r, 4, i * 0.22 + t * 0.12);
        break;
      }
      case 5: { // lissajous ribbon segments
        float a = i / (float) n * TWO_PI;
        float b = (i + 1) / (float) n * TWO_PI;
        g.line(280 * sin(2 * a + t * 0.4), 180 * sin(3 * a),
               280 * sin(2 * b + t * 0.4), 180 * sin(3 * b));
        break;
      }
    }
  }

  void polygon(PGraphics g, float cx, float cy, float r, int sides, float rot0) {
    g.beginShape();
    for (int k = 0; k < sides; k++) {
      float a = rot0 + k * TWO_PI / sides;
      g.vertex(cx + r * cos(a), cy + r * sin(a));
    }
    g.endShape(CLOSE);
  }
}
