# Rewriting quad v1 code to v2 (agent reference)

For agents porting a **quad v1** codebase (`Quad.Init(id)` / `Class "Frame"` / `Store.GetStore`)
to the current quad. There is no automatic converter — every v1 idiom is rewritten by hand.
Read `SKILL.md` first; this file only covers what changes coming *from v1*.

## 0. Toolchain (do this before anything else)

Nothing type-checks without all four flags:

```
luau-lsp analyze --flag:LuauSolverV2=true --flag:LuauTarjanChildLimit=160000 \
  --flag:LuauSubtypingIterationLimit=100000 --flag:LuauTypeInferIterationLimit=1000000 \
  --definitions=<roblox defs> <files>
```

- No `LuauSolverV2` → quad's own sources fail to parse: `TypeError: read keyword is illegal here`.
- No `LuauTarjanChildLimit` → even `D.Frame { Name = "x" }` dies:
  `TypeError: Internal error: Code is too complex to typecheck!`

Bootstrap: `require(path).Init(id)` → two modules plus `Quad:UseProvider(QuadRoblox)`.
`require(quad-base)` **is** the default instance; there is no id-keyed instance registry
(`Quad.New()` for an isolated one; share state by exporting the `Store` or via `q.Context`).

## 1. Mapping table

| v1 | v2 |
| :--- | :--- |
| `Class "Frame"` → `Frame {...}` | `D.Frame {...}` |
| `Class "<class not in D>"` | `D.New<<T>>("ClassName")(props)` |
| `Frame "id" {...}` | removed (id lookup is gone) |
| `Mount(parent, obj)` | `obj.Parent = parent` (`Parent` is never a prop) |
| `Mount(to, a, b)` | array part; a children **variable** only as `{ table.unpack(children) }`, last element |
| `mounts:Add(item)` / `mounts:Unmount()` | `q.Slot<<Instance>>()` + `:Add(el, index?)` / `:Clear()`; keyed data → `slot:List` |
| `[Event "Activated"] = fn(self, ...)` | hash key `Activated = fn(...)`, **no `self`**, arity must match |
| `[Event.Prop "Text"] = fn` | `q.OnChange("Text", fn)` in the array part (fn gets the new value) |
| `Event.Created` / `Event.CreatedAsync` | `q.OnCreated<<T>>(fn)` / `q.OnRendered<<T>>(fn)` |
| `Class.Extend()` + `:Render(props)` | a plain function |
| `:Init` + `props:Default("Size", v)` | `props.Size or default` |
| `:AfterRender(obj)` | `q.OnRendered<<T>>(fn)` — parenting NOT guaranteed |
| `:Unload` | `q.OnDestroyed(fn)` |
| `self "_button"` linker | `q.PreRef(nil :: TextButton?)` in the array part + `ref:Unwrap()` |
| `Store.GetStore("myStore")` | `q.Store { key = q.Source(v) }` — no name lookup; **defaults must be Sources** |
| `myStore "color"` | `store.color` (the very Source passed in) |
| `myStore.NewKey = v` (undeclared) | `store:Of<<T>>("NewKey")` — the only dynamic door; annotation mandatory |
| `register:With(fn)` | `state:Compute(fn, ...deps)` — deps arrive as **handles**, read with `:Get()` |
| `register:With(table)` | `state:Apply(q.Operator.Indexed<<V>>(key))` |
| `register:Add(v)` | `state:Apply(q.Operator.Sum(v))` — **numbers only** |
| `register:Default(v)` | `state:Apply(q.Operator.Alternative(v))` |
| `register:Tween{ Time = 2 }` | `state:Apply(q.Animate { Time = 2 })` |
| `register:Register(fn)` | `state:Observer(fn)` — callback gets `(targetState, observer, emitFrom?)`, not the value |
| `register:Observe(fn)` | `Observer` + `:Subscribe()`, or `q.Effect(fn, ...deps)` |
| `Style {...}`; `Frame { s }` | `D.Modifier.<Class>{...}` in the array part; later entry wins |
| `Corner` / `PaddingAll` / `PaddingAllOffset` / `Scale` | `UICorner` / `UIPadding` / `UIPaddingOffset` / `UIScale` |
| `Font = Enum.Font.X` | works — kept in the generated `D` as engine-legacy (Roblox tags it `Hidden`), marked `-- @deprecated`. Fine for a literal port; `FontFace = Font.fromEnum(...)` is the current API. Same for `FontSize` / `TextWrap` / `Transparency` |

**`:With` is a name clash, not a rename.** v1 `register:With(fn)` = derive → v2 `:Compute(fn, ...deps)`.
v2's `state:With(...)` exists and is a *different* API (it mints one extra node). Never map by name alone.

## 2. Removed, with no drop-in replacement

- **id lookup** — `Frame "id" {}`, `Store.GetObject/GetObjects/AddObject`, `objectList`. Use `q.Tag`
  for classification, and a `Ref` placed *at the element* for a direct reference.
  **`Ref` is not an id-lookup replacement**: it wraps an instance you already hold, it does not find one.
- **`Style "Child" {}`** (name-targeted styling) — pass a `Modifier` to the element itself.
- **`Init(QuadId)` namespaces** — singleton + opt-in `Quad.New()`.
- **`Class.Extend` OOP surface** — `Getter` / `Setter` / `UpdateTriggers` / `:Update()`. Updates are
  per-property; there is no re-render.
- **register metatable chaining** (`:With`→`:Add`→`:Tween` accumulating) — each step is an explicit node.
- **imperative tweens** — `Tween.RunTween` / `RunTweens` / `StopTween` / `StopPropertyTween` /
  `IsTweening` / `IsPropertyTweening`, `Tween.Easings.*`, function easings, `CallBack`/`OnStepped`/
  `Ended`, tweening plain tables. Only declarative `q.Tween{}` / `q.Animate{}`; overlap is settled by
  `Override = "Cancel" | "Finish"`.
- **`Apply(inst){props}` rebinding** — rejected; only `q.Claim(inst, D.Mapper…)` survives (claim-once,
  all direct children mapped, never a shared engine container).
- **`Signal.Bindable` / `Disconnecter`** — cleanup is bound to instance lifetime; disconnect your own
  connections in `q.OnDestroyed`.
- **`Quad.Lang`, `tracker.lua` (hot reload), `Quad.Round`, `customWarn`, `RoundSize`** — out of scope.
  The surviving shorthands are exactly `UICorner` / `UIPadding` / `UIPaddingOffset` / `UIScale`.

## 3. Strict-mode blockers (verbatim diagnostic heads)

| Literal v1 translation | Diagnostic | Fix |
| :--- | :--- | :--- |
| inline unannotated `:Compute` in a prop table | `Expected this to be '(StateData<number>, UDim2?, ...any) -> UDim2' but got '(t1) -> UDim2 …'` | annotate params `QuadTypes.StateData<T>`; hoist to a local |
| `q.Slot()` | `… but got 'Slot<unknown>'` | `q.Slot<<Instance>>()`; single angle brackets are a **SyntaxError** |
| `q.OnCreated(fn)` | `Type functions do not currently support types of the form '*error-type*'` | `q.OnCreated<<Frame>>(fn)` (same for `OnRendered`) |
| key not in generated `D` (v1 `Corner`/`PaddingAllOffset`/`Scale`) | `Expected this to be 'number', but got '"Corner"'` + an array-union mismatch line | this two-line shape means "no such property" (the key is read as an array index) |
| event callback with leading `self` | `Expected this to be '((() -> ()) \| None \| StateMarker<() -> ()>)?' but got '(unknown, unknown, unknown) -> ()'` | drop `self`, match engine arity |
| `Activated` on a `Frame` | `Expected this to be 'number', but got '"Activated"'` | use a `GuiButton` class |
| `nil` in the array part | `the 2nd component of the union is 'nil', which is not a subtype of …` | `props.X or q.None` |
| prebuilt props table `D.Frame(props)` | `Expected this to be 'FrameParam<…>' … 'string' is not exactly 'StateMarker<string>'` | bidirectional inference only works at the literal site |
| children array variable `D.ScreenGui(children)` | same family of param mismatch | `D.ScreenGui { table.unpack(children) }` |
| `q.Store()` then `store.Text = v` | `Cannot add property 'Text' to table '{ } & { Names: …, Of: … }'` | declare in defaults, or `store:Of<<string>>("Text")` |
| `State<Frame>` into a `State<Instance>` param | `'Frame' is not exactly 'Instance'` (hundreds of lines) | `State<T>` is invariant — declare inputs as the generated prop type (covariant marker) or `State<Instance>` |
| `Slot:List` updateFn returning `nil` first | `Expected this to be 'nil', but got 'TextLabel'` | annotate the return pack: `): (any, UD?)` |
| `q.Context.Provider("Theme")` uncast | `Get()` resolves to `unknown`, fails at the prop site | `:: QuadTypes.Provider<T>` |
| `q.Ref(nil)` | `… but got 'Ref<nil>'` | `q.Ref(nil :: Frame?)` |
| `[q.AttrKey("Hp")] = v` | `Expected this to be 'number', but got 'AttrKeyObject'` | runtime is fine, types are not opened — use array-part `q.Attr{...}` / `q.NumberAttr(...)` |
| `D.New("Folder")({...})` result used | `Type 'unknown' does not have key 'Name'` | `D.New<<Folder>>("Folder")({...})` |
| `Text = 42` | `Expected this to be '(None \| StateMarker<string> \| string)?', but got 'number'` | `tostring(42)` |
| `Op.Sum(UDim2 …)` | `None of the overloads for function that accept 2 arguments are compatible` | arithmetic/bitwise operators are number-only; other types go through `:Compute` |

Explicit type arguments use **double** angle brackets: `q.Slot<<Instance>>()`,
`q.OnCreated<<Frame>>(fn)`, `store:Of<<string>>("Text")`, `D.New<<Folder>>("Folder")`,
`q.Operator.Indexed<<Color3>>("Primary")`.

## 4. What strict mode does NOT catch

1. **Nil hole in the array part when the props type is loose.** With a precise element type the
   union mismatch is reported; with `any?` (the shape a v1 untyped props bag translates into) it
   passes silently and dies at runtime inside bookkeeping:
   `Dispatch.recompute: sourceList[1] is nil — bookkeeping is broken`.
   Always write `or q.None`, and do not type props as `any`.
2. **`store:Of("x")` without a type argument** yields `Source<any>`, disabling checking downstream.
   Keys added by `Of` after the fact land on the **next** re-dispatch.
3. **`q.Store { k = plainValue }`** type-checks but errors at construction:
   `Store: default for "k" is not a Source`. Wrap every default in `q.Source(...)`.
4. **`store.key = v`** replaces the field wholesale and loses the `Source`. Use `store.key:Set(v)`.
