# Naming review — Spread input names in quad (a reactive UI library for Roblox)

You are reviewing public API names. Judge them from the point of view of library USERS (Roblox developers writing UI in Luau). Everything you need is below — do not look for files. Reply in Korean, concisely.

## Context
- Elements are built with a props table: `Frame { Size = ..., MouseEnter = fn, child, ref, modifier }`. The hash part holds properties and events; the array part holds children and "descriptors" (Refs, Modifiers, `OnChange`/`OnEvent` descriptors, …). Constructors are fetched by class name and kept at the top of a file: `local Frame = Elem "Frame"`.
- **Modifier** — an IMMUTABLE, reusable property bag: `local FrameModifier = Modifier "Frame"`, `FrameModifier():BackgroundTransparency(0.5)`. Every setter returns a new value. Placed in an element's array part, it supplies DEFAULTS: keys written inline win over it; among several Modifiers the later one wins. It cannot carry Refs or event handlers. Types: `Modifier<C>` (full value with methods) and the input-position marker `ModifierInto<C>` = "a Modifier that may be placed into class C" (C itself or any ancestor class, e.g. a `GuiObject` Modifier into a `TextBox`; a sibling class is refused).
- **Spread** (new) — a MUTABLE, one-shot bag of anything you could write in an element's table: `Spread "Frame" { Size = ..., OnEvent "Frame" "MouseEnter" (fn), PostRef(...), someModifier }`. Placed in an element's array part, its keys and array values are spread into the element as if written there (name taken from JS `{...t}`). It can carry Refs, event descriptors, children and Modifiers — things a Modifier cannot. It is locked once it is placed in an element or nested into another Spread.
  - `s:Add(otherSpread)` appends another Spread into `s` (flattened immediately, so a Spread is always one level deep). It returns nothing. Key precedence is "first one in place wins": keys written inline in `s`'s constructor beat keys of Spreads nested/added to it, and an earlier-added Spread beats a later-added one. The same rule at an element: `Frame { Size = A, s1, s2 }` → inline beats `s1` beats `s2`. Array values are always appended in order. (Modifiers run after Spreads and only fill keys still empty.)
  - Types: `Spread<C>` is the full value (has `:Add`). The input-position marker — what a component prop or `:Add` accepts — is proposed as `SpreadInto<C>` = "a Spread that may be placed into class C" (C or an ancestor class), parallel to `ModifierInto<C>`.
- Other quad type names: `State<T>` / `StateMarker<T>`, `Modifier<C>`, `ModifierInto<C>`, `ModifierField<T>`, `Props<C>`, `PropsArrayItem<C>`, `ElemCtor<C>`, `OnEventDescriptor<K>`. Rule in the library: "a marker type is for input positions only; positions that need methods take the full type".
- UI kits built on quad expose components with props. Today a component that wraps an inner element takes `Modifier: ModifierInto<Frame>?` for its root and a prefixed Modifier for an inner element, e.g. `InputText { FieldModifier = ... }` (the inner TextBox) and `SliderNum { TrackModifier = ... }` (the slider track). Kits never expose a Ref to their root or inner elements today.

## Names to judge
1. **`SpreadInto<C>`** — the input-position marker type for a Spread that may be placed into class C (used in component prop types and as `:Add`'s parameter).
2. **`FieldSpread` / `TrackSpread`** — new kit props, kept NEXT TO `FieldModifier` / `TrackModifier` (not replacing them), that take a `SpreadInto<TextBox>` / `SpreadInto<Frame>` for the inner element, so a user can attach a Ref, event descriptors, etc. to the inner box. The common path (defaults only) stays `FieldModifier`.
3. **`:Add`** — sanity check given the "first one in place wins" rule: adding a Spread never overrides keys already in the bag (it only fills missing keys; array values append). Does `Add` read correctly, or does it suggest "the added one overrides"?

## Answer format (per item)
- verdict: keep / change
- best name (yours) and up to two alternatives, each with one line of reasoning
- confusion risk with Roblox / Luau / JS / the library's own names (low / medium / high) and why
Finish with at most three lines on anything the set as a whole gets wrong (consistency between items, with Modifier's "later wins" vs Spread's "first wins"). Mark guesses as 추정.
