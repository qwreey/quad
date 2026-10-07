# Third-party notices

- **Material Design 3** (https://m3.material.io) — design tokens (color roles, type scale, shape, elevation,
  motion, state-layer opacities) follow the public Material 3 specification. Material Design is by Google.
- **RoStrapUI** (https://github.com/RoStrap/RoStrapUI, commit 792da9d) — MIT License, Copyright (c) 2017
  Nevermore. Studied as a reference for ripple/shadow behavior; no source code is copied.
- **qwreey MaterialUI** (https://github.com/qwreey/qwreey.roblox.plugins, commit 7b6552a, `libs/MaterialUI`)
  — MIT License, Copyright (c) 2021 qwreey75 (the same author as this kit). Studied as a reference; two motions are
  ported from it: the `Radio` selection uses its radio sprite-sheet image asset (`rbxassetid://4667411351`, 10 frames
  of 40x40) and frame timing, and the `Checkbox` toggle reproduces its four-edge-bar close/open motion (re-implemented
  with Frames, no image).
- **Color picker** — the `ColorPicker` component is a port of the author's own color picker
  (`colorPicker-ignoreme.rbxm`, Copyright (c) qwreey), republished here under this kit's MIT License.
- **Wave textures** — `assets/wavy-progress-sheet-1024.png` (the `WavyProgress` amplitude sprite sheet, published as
  `rbxassetid://96568777229073`) and the earlier single texture `assets/wavy-progress-512x128.png` (`rbxassetid://78445787165309`, no
  longer used) were generated for this kit by `assets/gen-wave.py`; they are not derived from Material Design artwork or any
  third-party asset.
- **Arc pieces** — `assets/circular-arc-sheet-1024.png` (the `CircularProgress` arc-piece sprite sheet, published as
  `rbxassetid://97823357785454`) was generated for this kit by `assets/gen-arc.py`; it is not derived from Material Design
  artwork or any third-party asset.
  The earlier gutterless sheets were replaced because packed cells showed seam specks (2026-10-07).
