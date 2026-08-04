// Debug HUD — toggled with Z, defaults off. Dev tool; the live instrument
// output is clean when off. Shows raws, deriveds, selection, palette,
// guardrail, transport states, MIDI activity.

void drawDebug() {
  int pad = 10;
  int lh = 18;
  textSize(13);
  textAlign(LEFT, TOP);

  String[] lines = new String[10];
  lines[0] = "PDM debug  |  fps " + nf(frameRate, 0, 1) + " (ema " + nf(guardrail.ema, 0, 1)
           + ")  |  midi: " + nano.deviceName + "  last CC " + nano.lastCc + "=" + nano.lastVal;
  lines[1] = "style " + (st.styleIx + 1) + " (" + styles[st.styleIx].name + ")  mode "
           + (st.modeIx + 1) + "  |  palette " + (st.paletteIx + 1) + " " + st.palette.name
           + "  |  degrades " + guardrail.degradeCount;
  lines[2] = "sliders " + rawRow(st.slider);
  lines[3] = "knobs   " + rawRow(st.knob);
  lines[4] = "zoom " + nf(st.zoom, 0, 2) + " (x" + nf(zoomScale(st.zoom), 0, 2) + ")"
           + "  rot " + nf(degrees(st.rot), 0, 1) + "deg"
           + "  pan " + nf(st.panX, 0, 2) + "/" + nf(st.panY, 0, 2);
  lines[5] = "density " + nf(st.density, 0, 2)
           + "  strokeW " + nf(st.strokeW, 0, 2) + " (" + nf(strokePx(st.strokeW), 0, 1) + "px)"
           + "  s7 " + nf(st.colorCtl, 0, 2);
  lines[6] = "speed " + nf(st.speed, 0, 2) + "x  t " + nf(st.t, 0, 1)
           + "  hueLFO " + nf(st.hueLfoSpeed, 0, 2) + " phase " + nf(st.hueLfoPhase, 0, 0) + "deg";
  StringBuilder tr = new StringBuilder("transport ");
  for (int i = 0; i < TRANSPORT_CCS.length; i++)
    if (nano.transportDown[i]) tr.append(TRANSPORT_NAMES[i]).append(" ");
  lines[7] = tr.toString();
  StringBuilder tc = new StringBuilder("touched ");
  for (int i = 0; i < 8; i++) tc.append(nano.touched[i] ? "S" : ".");
  tc.append(" ");
  for (int i = 0; i < 8; i++) tc.append(nano.touched[8 + i] ? "K" : ".");
  lines[8] = tc.toString() + "   (untouched controls still at boot defaults)";
  lines[9] = "[Z] hide";

  noStroke();
  fill(0, 0, 0, 70);
  rect(0, 0, width, pad * 2 + lh * lines.length);
  fill(0, 0, 100);
  for (int i = 0; i < lines.length; i++) text(lines[i], pad, pad + i * lh);
}

String rawRow(float[] a) {
  StringBuilder sb = new StringBuilder();
  for (int i = 0; i < a.length; i++) sb.append(nf(a[i], 0, 2)).append(i < a.length - 1 ? " " : "");
  return sb.toString();
}
