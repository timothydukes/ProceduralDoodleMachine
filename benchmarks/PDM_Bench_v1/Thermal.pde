// T9 (optional, Pi): 20-minute thermal soak.
// Runs the T3 sketchy scene at the maximum sustainable 720p load measured
// earlier this run (fallback 4000 strokes), logging fps and SoC temperature
// once per second to a dedicated CSV. Answers: does throttling erode the
// budgets over the length of a real set?

PrintWriter thermalLog = null;
int thermalStartMs, thermalSecLogged, thermalWindowStart, thermalWindowFrames;

void startThermal() {
  String name = "pdm_thermal_" + machineLabel + "_" + rendererLabel + "_" + stamp + ".csv";
  thermalLog = createWriter(sketchPath(name));
  thermalLog.println("sec,fps,temp_c");
  thermalStartMs = millis();
  thermalWindowStart = thermalStartMs;
  thermalWindowFrames = 0;
  thermalSecLogged = 0;
  note("T9_thermal: started, load=" + t3Max720 + " strokes @ 720p, "
       + THERMAL_MINUTES + " min");
  mode = MODE_THERMAL;
}

void drawThermal() {
  background(0);
  loadSketchy(pgTier[0], t3Max720);
  image(pgTier[0], 0, 0, width, height);
  thermalWindowFrames++;

  int now = millis();
  if (now - thermalWindowStart >= 1000) {
    float fps = thermalWindowFrames * 1000.0 / (now - thermalWindowStart);
    float temp = readTempC();
    thermalSecLogged++;
    thermalLog.println(thermalSecLogged + "," + nf(fps, 0, 1) + "," + nf(temp, 0, 1));
    thermalLog.flush();
    thermalWindowStart = now;
    thermalWindowFrames = 0;

    // HUD
    int remain = THERMAL_MINUTES * 60 - thermalSecLogged;
    fill(0, 0, 0); noStroke();
    rect(0, height - 40, width, 40);
    fill(0, 0, 100);
    textAlign(LEFT, CENTER);
    textSize(16);
    text("THERMAL SOAK  " + nf(fps, 0, 1) + " fps  " + nf(temp, 0, 1) + " C  "
         + (remain / 60) + ":" + nf(remain % 60, 2) + " remaining  [Q] abort",
         12, height - 20);

    if (thermalSecLogged >= THERMAL_MINUTES * 60) {
      note("T9_thermal: complete (" + thermalSecLogged + " s logged; see thermal CSV)");
      endSideTest();
    }
  }
}

float readTempC() {
  // Pi: millidegrees C in sysfs. Mac: not exposed without third-party tools;
  // returns -1 there. [INTERPRETIVE] thermal test is Pi-only per plan.
  try {
    String[] s = loadStrings("/sys/class/thermal/thermal_zone0/temp");
    if (s != null && s.length > 0) return Integer.parseInt(s[0].trim()) / 1000.0;
  } catch (Exception e) {}
  return -1;
}

void closeThermalLog() {
  if (thermalLog != null) { thermalLog.flush(); thermalLog.close(); thermalLog = null; }
}
