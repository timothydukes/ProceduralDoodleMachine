// DoodleMode / DoodleStyle per spec §7, plus the registry and guardrail.
// One deviation from the §7 listing, anticipated by its prose: an explicit
// deactivate() hook so accumulating modes can release their buffers on
// switch-away ("release on deactivate is the mode's responsibility").

abstract class DoodleMode {
  abstract void activate(PdmState s);            // style/mode switch-in, and boot
  void deactivate(PdmState s) {}                 // release buffers here
  abstract void update(PdmState s, float dt);    // dt already speed-scaled
  abstract void render(PdmState s, PGraphics g); // g.beginDraw/endDraw handled by Main
  void degrade() {}                              // guardrail hook (§3)
  float fpsFloor() { return DEFAULT_FPS_FLOOR; }
}

class DoodleStyle {
  String name;
  DoodleMode[] modes = new DoodleMode[3];
  DoodleStyle(String name, DoodleMode m0, DoodleMode m1, DoodleMode m2) {
    this.name = name;
    modes[0] = m0; modes[1] = m1; modes[2] = m2;
  }
}

// Phase 1: all 24 slots are placeholders proving the plumbing. Each real
// style replaces one row here as its study graduates (spec §8-§9).
void buildStyles() {
  styles = new DoodleStyle[8];
  for (int sIdx = 0; sIdx < 8; sIdx++) {
    styles[sIdx] = new DoodleStyle("placeholder-" + (sIdx + 1),
      new PlaceholderMode(sIdx, 0),
      new PlaceholderMode(sIdx, 1),
      new PlaceholderMode(sIdx, 2));
  }
}

// Frame-rate guardrail (§3): rolling fps estimate; if the active mode sits
// below its declared floor for >2 s, call degrade(), at most once per 3 s.
// [INTERPRETIVE] thresholds; per-style tuning happens in study phases.
class Guardrail {
  float ema = 60;
  int belowSince = -1;
  int lastDegrade = -10000;
  int degradeCount = 0;

  void tick(PdmState s, DoodleMode m) {
    ema = lerp(ema, frameRate, 0.05);
    if (ema < m.fpsFloor()) {
      if (belowSince < 0) belowSince = millis();
      if (millis() - belowSince > 2000 && millis() - lastDegrade > 3000) {
        m.degrade();
        lastDegrade = millis();
        degradeCount++;
      }
    } else {
      belowSince = -1;
    }
  }
}
