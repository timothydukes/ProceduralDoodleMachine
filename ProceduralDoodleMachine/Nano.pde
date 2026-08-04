// PdmNano — original MIDI input layer for the Korg nanoKONTROL2, factory
// default scene, built directly on javax.sound.midi (JDK). No vendored
// library (Phase 1 decision). Device matching follows the approach proven
// in benchmarks/PDM_Bench_v1 on both machines.
//
// Factory CC map (Korg nanoKONTROL2 Parameter Guide):
//   sliders CC 0-7 | knobs CC 16-23
//   S buttons CC 32-39 | M CC 48-55 | R CC 64-71
//   transport: play 41, stop 42, rew 43, ff 44, rec 45, cycle 46,
//              track< 58, track> 59, marker-set 60, marker< 61, marker> 62
// Buttons send 127 on press, 0 on release (momentary). Selection acts on
// the press edge only — pure radio-button semantics, releases ignored.
//
// Thread note: send() runs on the MIDI thread; fields written there and
// read in draw() are volatile. Analog writes are single-array-slot stores;
// the pendingStyle/pendingMode pair is consumed by clearing pendingStyle.

static final int[] TRANSPORT_CCS = {41, 42, 43, 44, 45, 46, 58, 59, 60, 61, 62};
static final String[] TRANSPORT_NAMES =
  {"play", "stop", "rew", "ff", "rec", "cycle", "trk<", "trk>", "set", "mk<", "mk>"};

class PdmNano {
  volatile float[] sliders = new float[8];
  volatile float[] knobs = new float[8];
  volatile int pendingStyle = -1;
  volatile int pendingMode = 0;
  volatile boolean[] transportDown = new boolean[TRANSPORT_CCS.length];
  volatile boolean[] touched = new boolean[16];   // debug: which controls have reported
  volatile int lastCc = -1, lastVal = -1;         // debug
  String deviceName = "(none)";
  MidiDevice dev = null;

  PdmNano() {
    for (int i = 0; i < 8; i++) { sliders[i] = DEFAULT_ANALOG; knobs[i] = DEFAULT_ANALOG; }
    knobs[6] = DEFAULT_HUE_LFO;   // knob 7: hue LFO off at boot
  }

  boolean open() {
    try {
      for (MidiDevice.Info info : MidiSystem.getMidiDeviceInfo()) {
        String n = (info.getName() + " " + info.getDescription()).toLowerCase();
        if (!n.contains("nano")) continue;
        MidiDevice d = MidiSystem.getMidiDevice(info);
        if (d.getMaxTransmitters() == 0) continue;   // need an input port
        d.open();
        d.getTransmitter().setReceiver(new Receiver() {
          public void send(MidiMessage msg, long ts) {
            if (!(msg instanceof ShortMessage)) return;
            ShortMessage sm = (ShortMessage) msg;
            if (sm.getCommand() != ShortMessage.CONTROL_CHANGE) return;
            handleCC(sm.getData1(), sm.getData2());
          }
          public void close() {}
        });
        dev = d;
        deviceName = info.getName();
        println("MIDI: opened " + deviceName);
        return true;
      }
    } catch (Exception e) {
      println("MIDI open failed: " + e.getMessage());
    }
    return false;
  }

  void handleCC(int cc, int val) {
    lastCc = cc; lastVal = val;
    if (cc >= 0 && cc <= 7) {
      sliders[cc] = val / 127.0;
      touched[cc] = true;
    } else if (cc >= 16 && cc <= 23) {
      knobs[cc - 16] = val / 127.0;
      touched[8 + (cc - 16)] = true;
    } else if (val > 0) {                       // press edge only
      if (cc >= 32 && cc <= 39)      { pendingMode = 0; pendingStyle = cc - 32; }
      else if (cc >= 48 && cc <= 55) { pendingMode = 1; pendingStyle = cc - 48; }
      else if (cc >= 64 && cc <= 71) { pendingMode = 2; pendingStyle = cc - 64; }
      else setTransport(cc, true);
    } else {
      setTransport(cc, false);
    }
  }

  void setTransport(int cc, boolean down) {
    for (int i = 0; i < TRANSPORT_CCS.length; i++)
      if (TRANSPORT_CCS[i] == cc) { transportDown[i] = down; return; }
  }

  void close() {
    if (dev != null) { try { dev.close(); } catch (Exception e) {} dev = null; }
  }
}
