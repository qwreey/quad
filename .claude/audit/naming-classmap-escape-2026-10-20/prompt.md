# Naming review — the class-map escape in quad (a reactive UI library for Roblox)

You are reviewing ONE public API name. Judge it from the point of view of library USERS (Roblox developers writing Luau with the new type solver). Everything you need is below — do not look for files. Reply in Korean, concisely.

## Context
- quad's typed surface takes a Roblox class NAME first, curried, and checks everything against the engine's class types:
  - `local Frame = q.Elem "Frame"` → element constructor; `Frame { Size = …, Visible = true }`
  - `local FrameModifier = q.Modifier "Frame"` → immutable default-property bag factory
  - `q.Spread "Frame" { … }` → one-shot bag spread into an element
  - `q.Mapper "Frame" (key) { … }`, `q.OnChange "Frame" "Visible" (fn)`, `q.OnEvent "Frame" "MouseEnter" (fn)`, `q.Out "ScrollingFrame" "CanvasSize" (source)`
  - Other top-level names: `q.Raw` (untyped base building blocks), `q.Backend` (ops a backend fills in), `q.NewModule()` (a fresh module copy), `q.None`, `q.Source`, `q.State`.
- The class names those functions accept come from a built-in class map that is deliberately SMALL and GUI-centric (Frame, TextLabel, ScrollingFrame, UI* layout classes, ScreenGui …, about 30). A larger built-in map makes the type checker give up ("Code is too complex"), so 3D/world classes such as `Part`, `Beam`, `Sound`, `ParticleEmitter` are not in it: `q.Elem "Part"` is a type error.
- **The escape (to be named).** A generic function that takes the user's OWN class map as an explicit type argument and returns the same curried surface bound to that map:
  ```luau
  local W = q.???<<{ Part: Part, Beam: Beam, BasePart: BasePart }>>()
  local Part = W.Elem "Part"            -- fully typed: Part { Anchored = 5 } is an error
  local s = W.Spread "BasePart" { Anchored = true }
  local m = W.Modifier "BasePart" ()
  -- W.Elem "Prt" is an error (not a key of the user's map)
  ```
  - Runtime: it returns the same functions as the built-in surface (the runtime never needed the map; it only changes types). No arguments at runtime.
  - It is the ONLY escape: there is no untyped `any` escape. Users typically write it once in a shared module (`return q.???<<World>>()`) or at the top of a file.
  - The user is responsible for the map being right (`{ Part: Frame }` would lie).
- Working name so far: `With`. Other candidates seen: `Classes`, `ForClasses`, `Extend`, `Using`, `Bind`, `Surface`, `ClassMap`.

## What to judge
Pick the best name for `q.???`. Consider: does the call site `q.???<<{ Part: Part }>>()` read naturally; does it say "same surface, for these classes"; collisions with Roblox (`Instance`, `ClassName`, `:IsA`, services), Luau (the `class` syntax RFC, `typeof`, type functions), and the library's own names above; how it reads in the shared-module form.

## Answer format
- verdict on `With`: keep / change
- best name (yours) and up to three alternatives, each with one line of reasoning
- confusion risk for each (low / medium / high) and why
Finish with at most three lines on anything about the mechanism itself that the name should warn about. Mark guesses as 추정.
