# PDM — Installation

Both machines run **Processing 4.3** (pinned; see PDM_SPEC §2). Processing
bundles its own Java — no separate Java install is needed.

## MacBook (mid-2015 MacBook Pro, Intel, macOS 12)

1. In a browser, go to **processing.org/download**.
2. Under Processing 4.3, download the **macOS (Intel 64-bit)** build
   (`.zip`). The 2015 MacBook Pro is Intel — do not take the Apple
   Silicon build.
3. Double-click the downloaded zip in Downloads; it unpacks to
   `Processing.app`.
4. Drag `Processing.app` into `/Applications`.
5. First launch only: right-click (or Ctrl-click) `Processing.app` →
   **Open** → **Open** in the Gatekeeper dialog. After that it opens
   normally.
6. Verify: Processing → About Processing should say 4.3.

If processing.org's front page only offers a newer version, use the
"Earlier releases" / GitHub releases link on that page and pick 4.3.

## Raspberry Pi 4 (Raspberry Pi OS Bookworm 64-bit)

1. In the Pi's browser, go to **processing.org/download** and download
   the **Linux ARM64** build of Processing 4.3 (`.tgz`). (Bookworm
   64-bit needs arm64, not the 32-bit armhf build.)
2. Open a terminal and run:
   ```
   cd ~
   tar xzf ~/Downloads/processing-4.3*.tgz
   sudo mv processing-4.3 /opt/
   sudo ln -s /opt/processing-4.3/processing /usr/local/bin/processing
   ```
   (If the extracted folder has a slightly different name, `ls ~` after
   the tar step and use that name in the `mv`.)
3. Launch with `processing` from a terminal, or from the desktop menu if
   it registered one.
4. Verify: Help → About should say 4.3.

## Repository

```
cd ~/Documents
git clone https://github.com/YOUR_USERNAME/ProceduralDoodleMachine.git
```

Day-to-day: `git pull` before working on a machine, commit and `git push`
after. See `benchmarks/README.md` for the Phase 0 run procedure.
