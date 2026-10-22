# Third-party notices

This kit is **inspired by** Iris (https://github.com/SirMallard/Iris, commit 801973f) — the widget set,
the Dear ImGui look and the default dark/light color and size values follow Iris's `lib/config.lua`.
No Iris source code is copied; the API is quad's retained-mode reactive idiom, not Iris's immediate mode.

Iris is distributed under the MIT License, Copyright (c) 2024 Michael_48.
Iris itself is based on Dear ImGui (https://github.com/ocornut/imgui, MIT, Copyright (c) 2014-2026 Omar Cornut).

The default icons (`Style.luau` `DEFAULT_ICONS`: RightTriangle, DownTriangle, Close, ResizeGrip, CheckMark,
BlankSquare) are the image assets Iris uses (`lib/widgets/init.lua` `widgets.ICONS`, commit 801973f), referenced by the
same asset ids; the kit ships no copy of the images. Replace them through a Style's `Icons` if you need your own.
