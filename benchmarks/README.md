# PDM Phase 0 — Benchmark Run Instructions

Goal: 3 automated runs per machine (one per renderer), plus one optional
MIDI check per machine and one 20-minute thermal soak on the Pi.
Total hands-on time is small; each automated run is ~6–12 minutes of
watching the screen.

## One-time setup (each machine)

1. Make sure Processing 4.3 is installed (see `docs/INSTALL.md`).
2. Pull the repo so `benchmarks/PDM_Bench_v1/` exists locally:
   ```
   cd ~/Documents/ProceduralDoodleMachine
   git pull
   ```

## Per-run procedure

1. Open Processing 4.3.
2. File → Open → navigate to
   `ProceduralDoodleMachine/benchmarks/PDM_Bench_v1/PDM_Bench_v1.pde` → Open.
3. Click the **CONFIG** tab (tab bar under the toolbar). Confirm the top
   line reads the renderer you want for this run:
   ```java
   static final String RENDERER_CHOICE = "P2D";
   ```
   Run order: `"P2D"` first, then `"P3D"`, then `"JAVA2D"`.
4. Press the **Run** button (▶). The sketch goes fullscreen and runs by
   itself. The bar at the bottom shows current stage, resolution, load,
   and the last measured fps. Do not interact; just let it finish.
   - If a stage appears frozen for more than ~2 minutes, press **S** to
     skip that stage (it will be recorded as skipped).
5. When the screen shows **AUTOMATED TESTS COMPLETE**:
   - Optional (once per machine is enough): plug in the nanoKONTROL2,
     press **M**, and wiggle any knob or slider continuously for 10
     seconds. Results append automatically.
   - **Pi only, once, on the P2D run** (or whichever renderer wins —
     can be repeated later): press **T** to start the 20-minute thermal
     soak. Leave it completely alone until it returns to the menu.
   - Press **Q** to save and quit.
6. For the next run, change the CONFIG line to the next renderer
   (step 3) and repeat.

## After all runs on a machine

The results files are inside the sketch folder itself
(`benchmarks/PDM_Bench_v1/`), named like:

```
pdm_bench_pi_p2d_20260802_1430.csv
pdm_summary_pi_p2d_20260802_1430.txt
pdm_thermal_pi_p2d_20260802_1510.csv
```

Commit and push them:

```
cd ~/Documents/ProceduralDoodleMachine
git add benchmarks/
git commit -m "Phase 0 results: <machine>"
git push
```

(On the second machine, `git pull` first.)

Then paste or upload the `pdm_summary_*.txt` files (and the thermal CSV)
into the chat for analysis. Renderer choice, GLSL policy, and complexity
budgets get locked into PDM_SPEC v0.2 from these numbers.

## Notes

- On OpenGL renderers, vsync may cap fps at your display's refresh rate
  (typically 60). This does not affect the pass/fail measurements, which
  only care about the 30 fps floor, but it does mean "max fps" numbers
  are ceilings, not raw throughput.
- The Pi should be run with its normal case/cooling in the position it
  will actually be played in — the thermal test is only meaningful under
  real conditions.
- If the sketch fails to start on the Pi with a GL error under P2D/P3D,
  note the exact console message and report it; that is itself a Phase 0
  result.
