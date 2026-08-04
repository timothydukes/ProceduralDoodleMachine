// Palette system v1 (spec §5). A palette is a constraint on displayable
// colors: styles ask for a hue (usually base + hue-LFO phase) and receive
// the nearest color the palette permits. Background/ground/accent roles
// are chosen per style from bg()/ink()/accent(); inverted palettes swap
// role colors at construction. The 12-bank contents are PROVISIONAL until
// real styles exist to judge them against (spec §5: settled during
// development).

class Palette {
  String name;
  boolean inverted;
  int bgCol;
  int[] allowed;      // ink candidates, stored as HSB ints
  int accentCol;

  Palette(String name, boolean inverted, int bgCol, int[] allowed, int accentCol) {
    this.name = name; this.inverted = inverted;
    this.bgCol = bgCol; this.allowed = allowed; this.accentCol = accentCol;
  }

  int bg() { return bgCol; }
  int accent() { return accentCol; }
  int ink(int i) { return allowed[abs(i) % allowed.length]; }

  // Quantize a requested hue (degrees) to the nearest allowed color by
  // circular hue distance. Single-color palettes return that color.
  int quantize(float hueDeg) {
    if (allowed.length == 1) return allowed[0];
    hueDeg = ((hueDeg % 360) + 360) % 360;
    int best = allowed[0];
    float bestD = 1e9;
    for (int c : allowed) {
      float d = abs(hue(c) - hueDeg);
      d = min(d, 360 - d);
      if (d < bestD) { bestD = d; best = c; }
    }
    return best;
  }
}

void buildPalettes() {
  palettes = new Palette[12];
  int white = color(0, 0, 100), black = color(0, 0, 0);

  // full-saturation rainbow: 12 hues
  int[] rainbow = new int[12];
  for (int i = 0; i < 12; i++) rainbow[i] = color(i * 30, 100, 100);

  // minimal-video RGB/CMYK: 6 primaries/secondaries at full sat+bri
  int[] video = new int[6];
  for (int i = 0; i < 6; i++) video[i] = color(i * 60, 100, 100);

  // pastel: 8 hues, low sat, high bri
  int[] pastel = new int[8];
  for (int i = 0; i < 8; i++) pastel[i] = color(i * 45, 28, 100);
  int[] pastelDeep = new int[8];   // darker pastels for light-ground variant
  for (int i = 0; i < 8; i++) pastelDeep[i] = color(i * 45, 38, 72);

  // organic: greens/browns/ochres  [INTERPRETIVE] first draft
  int[] organic = {
    color(95, 60, 55), color(80, 55, 70), color(60, 70, 75),
    color(40, 75, 80), color(28, 80, 65), color(18, 65, 45), color(140, 40, 50)
  };
  int[] organicDeep = {
    color(95, 55, 40), color(60, 60, 55), color(35, 70, 55), color(20, 60, 35)
  };

  // single-hue monos  [INTERPRETIVE] "a few more" slots: warm + cool
  int[] amber = { color(35, 100, 100), color(35, 80, 85), color(35, 100, 70) };
  int[] cyan  = { color(190, 90, 45), color(190, 100, 65), color(200, 80, 35) };

  int wA = color(35, 100, 100), aA = color(200, 100, 100);

  //                 name              inv    bg     allowed      accent
  palettes[0]  = new Palette("bw",            false, black, new int[]{white}, white);
  palettes[1]  = new Palette("bw-inv",        true,  white, new int[]{black}, black);
  palettes[2]  = new Palette("rainbow",       false, black, rainbow,          white);
  palettes[3]  = new Palette("rainbow-inv",   true,  white, rainbow,          black);
  palettes[4]  = new Palette("video",         false, black, video,            white);
  palettes[5]  = new Palette("video-inv",     true,  white, video,            black);
  palettes[6]  = new Palette("pastel",        false, black, pastel,           white);
  palettes[7]  = new Palette("pastel-inv",    true,  color(50, 8, 100), pastelDeep, black);
  palettes[8]  = new Palette("organic",       false, color(40, 15, 10), organic, wA);
  palettes[9]  = new Palette("organic-inv",   true,  color(45, 20, 96), organicDeep, color(18, 65, 30));
  palettes[10] = new Palette("amber",         false, black, amber,            white);
  palettes[11] = new Palette("cyan-inv",      true,  color(195, 15, 96), cyan, aA);
}
