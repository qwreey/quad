# Naming review — devui (a developer UI kit for Roblox)

You are reviewing public API names for a UI kit. Judge them from the point of view of the kit's USERS (Roblox developers writing tool UIs). Everything you need is below — do not look for files. Reply in Korean, concisely.

## Context
- devui is a Dear ImGui / Iris-inspired developer UI kit for Roblox, built on a reactive library (quad). It is retained-mode: widgets are functions taking a props table; reactive values are `State<T>` (read-only) and `Source<T>` (writable). Inspired by ImGui/Iris, not bound to follow them.
- Existing names in the kit that set conventions:
  - Window static flags: `NoTitleBar`, `NoResize`, `NoMove`, `NoClose`, `NoCollapse` (booleans, ImGui style).
  - `MenuToggle` (a checkable menu row) takes `Checked: State<boolean>` (controlled) or `Value: Source<boolean>`.
  - `Window` takes `Focused: Source<boolean>?` — an OUTPUT the window writes (is it the focused window).
  - `InputText` has `FieldModifier` for its inner TextBox (prefix `Field` = the inner box).
  - Style metric tokens follow ImGui/Iris names: `FrameRounding`, `WindowPadding`, `FramePadding`, `ItemSpacing`, `ScrollbarSize`, `PopupRounding`; color tokens like `Button`, `ButtonHovered`, `ButtonActive`, `Tab`, `TabActive`.
  - `Interaction.drag({ OnBegin = fn(x, y), OnMove = fn(x, y, dx, dy), OnEnd = fn(x, y, dx, dy, cancelled), Enabled = State<boolean>? })`.
- Roblox name collisions to keep in mind: `GuiObject.Active` (whether the element sinks input), `GuiButton.Selected` (gamepad selection), `TextBox:IsFocused()`, `TextBox.Focused` / `FocusLost` events.

## Names to judge
1. **Button on-state.** A prop on `Button`/`SmallButton` that makes the button show its "on" look (the `ButtonActive` color) — a toggle button such as a filter chip or "show bookmarks". Value `boolean | State<boolean>`. Proposed: `Checked`. Candidates seen: `Active`, `Selected`, `Toggled`, `On`, `Pressed`, `Highlighted`.
2. **Tab bar without pages.** A boolean flag on `TabBar` that draws only the tab buttons (no page container; the caller shows content elsewhere — used as a segmented selector). Proposed: `NoPages`.
3. **Tab corner radius token.** A Style metric for the tab buttons' corner radius (today they use `FrameRounding`). Proposed: `TabRounding` (ImGui has a style var of this name).
4. **Per-frame drag callback.** An option on `Interaction.drag` called every frame while a drag is active, even when the pointer does not move (for edge auto-scroll). Signature `(dt, x, y) -> ()`. Proposed: `OnTick`. Candidates: `OnFrame`, `OnStep`, `OnHeartbeat`, `WhileDragging`, `OnHold`.
5. **Already implemented, sanity check (renaming is still possible before release):**
   a. `InputText` prop `Focused: Source<boolean>?` — TWO-WAY: setting true asks for keyboard focus (taken once the box is on screen), false releases it; the user's own focus changes are written back. (Note `Window.Focused` is output-only.)
   b. `Window` prop `ContentSize: Source<Vector2>?` — OUTPUT: the window writes the room its children get (visible content area minus padding).
   c. `VirtualRows` — a widget: virtualized list of fixed-height rows (only visible rows exist, pooled). Props `Count: State<number>`, `Row: (index: State<number?>) -> Instance`, `RowHeight`, `Overscan`, `ScrollTo: Source<number?>` (write a row index to scroll it into view).

## Answer format (per item)
- verdict: keep / change
- best name (yours) and up to two alternatives, each with one line of reasoning
- confusion risk with Roblox / ImGui / the kit's own names (low / medium / high) and why
Finish with at most three lines on anything the set as a whole gets wrong (consistency between items). Mark guesses as 추정.
