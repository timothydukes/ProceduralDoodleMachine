// T8 (optional, interactive): MIDI responsiveness sanity check.
// Uses javax.sound.midi from the JDK directly — no vendored library needed
// in Phase 0. Confirms the nanoKONTROL2 is visible to Java on this machine
// and reports CC event timing statistics while you wiggle a control.

java.util.List<Long> ccTimes = java.util.Collections.synchronizedList(new ArrayList<Long>());
MidiDevice midiDev = null;
String midiStatus = "";
long midiFirstMs = -1;
static final int MIDI_CAPTURE_SEC = 10;
static final int MIDI_TIMEOUT_SEC = 30;
int midiStartMs;

void startMidiTest() {
  ccTimes.clear();
  midiFirstMs = -1;
  midiStatus = "searching for nanoKONTROL2...";
  midiStartMs = millis();
  mode = MODE_MIDI;

  try {
    MidiDevice.Info[] infos = MidiSystem.getMidiDeviceInfo();
    for (MidiDevice.Info info : infos) {
      String n = (info.getName() + " " + info.getDescription()).toLowerCase();
      if (!n.contains("nano")) continue;
      MidiDevice d = MidiSystem.getMidiDevice(info);
      if (d.getMaxTransmitters() == 0) continue;   // want an input port
      d.open();
      d.getTransmitter().setReceiver(new Receiver() {
        public void send(MidiMessage msg, long ts) {
          if (msg instanceof ShortMessage) {
            ShortMessage sm = (ShortMessage) msg;
            if (sm.getCommand() == ShortMessage.CONTROL_CHANGE) {
              ccTimes.add(System.nanoTime());
            }
          }
        }
        public void close() {}
      });
      midiDev = d;
      midiStatus = "FOUND: " + info.getName() + " — wiggle any knob/slider for "
                   + MIDI_CAPTURE_SEC + " s";
      return;
    }
    midiStatus = "nanoKONTROL2 NOT FOUND (check cable, then press Q and retry)";
  } catch (Exception e) {
    midiStatus = "MIDI error: " + e.getMessage();
  }
}

void drawMidi() {
  background(0);
  fill(0, 0, 100);
  textAlign(LEFT, TOP);
  textSize(constrain(height / 40, 12, 24));
  text("MIDI RESPONSIVENESS CHECK", 20, 20);
  text(midiStatus, 20, 60);
  int n = ccTimes.size();
  if (n > 0 && midiFirstMs < 0) midiFirstMs = millis();
  text("CC events captured: " + n, 20, 100);

  boolean capturedEnough = midiFirstMs > 0 && millis() - midiFirstMs >= MIDI_CAPTURE_SEC * 1000;
  boolean timedOut = millis() - midiStartMs >= MIDI_TIMEOUT_SEC * 1000;
  if (capturedEnough || (timedOut && midiDev != null)) {
    finishMidiTest();
  } else if (timedOut) {
    note("T8_midi: controller not found");
    endSideTest();
  }
  text("[Q] abort", 20, 140);
}

void finishMidiTest() {
  int n = ccTimes.size();
  if (n < 2) {
    note("T8_midi: too few events (" + n + ")");
  } else {
    long minGap = Long.MAX_VALUE, maxGap = 0, sum = 0;
    synchronized (ccTimes) {
      for (int i = 1; i < n; i++) {
        long gap = ccTimes.get(i) - ccTimes.get(i - 1);
        minGap = Math.min(minGap, gap); maxGap = Math.max(maxGap, gap); sum += gap;
      }
    }
    float meanMs = (sum / (float)(n - 1)) / 1e6;
    float maxMs = maxGap / 1e6;
    String line = "T8_midi: " + n + " CC events in " + MIDI_CAPTURE_SEC
                  + " s; mean gap " + nf(meanMs, 0, 2) + " ms, max gap " + nf(maxMs, 0, 1) + " ms";
    note(line);
    csvRow("T8_midi", "-", "cc_events", n, meanMs, "info");
  }
  endSideTest();
}

void endSideTest() {
  if (midiDev != null) { try { midiDev.close(); } catch (Exception e) {} midiDev = null; }
  closeThermalLog();
  saveSummary();
  mode = MODE_MENU;
}
