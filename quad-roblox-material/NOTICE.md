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
- **Material Design Icons** (https://github.com/google/material-design-icons) — Apache License 2.0, Copyright Google
  Inc. (the IconPack plugin's notice reads "Google INC.", 2016). The kit's built-in icons (`src/Icons.luau`: check, close,
  arrow_drop_down/up, keyboard_arrow_left/right/down, edit, date_range, keyboard, schedule, menu, more_vert — "baseline" style) are these icons as image assets
  uploaded to Roblox by the author's icon account (`qwreey74_icon`) for the IconPack Studio plugin; the ids come from its
  dump (qwreey/qwreey.roblox.plugins@7b6552a, `IconPack.Plugin/res/IconDump.lua`). The images are not modified; the kit
  references them by asset id and ships no copy. The gallery (`gallery/Navigation.luau`, not part of the kit) also references
  more of the same set by id for its navigation demos: inbox, send, favorite, delete (drawer destinations); home, explore,
  bookmark, person, settings, search, star, arrow_back, add, share, attach_file, mic, image, format_bold, format_italic,
  format_underlined, undo, redo, palette (navigation bar / rail, app bars, toolbars — each checked as an image asset,
  AssetTypeId 1, creator qwreey74_icon, 2026-10-08). Apache 2.0 text:
  https://www.apache.org/licenses/LICENSE-2.0
- **Ripple disc** — `assets/ripple-disc-1024.png` (the pressed-ripple texture, published as `rbxassetid://89858938964426`) was
  generated for this kit by `assets/gen-disc.py`; it is not derived from Material Design artwork or any third-party asset.
