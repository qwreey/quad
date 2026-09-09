# Quad Rules & Invariants (Diagnostic Cheat Sheet)

Runtime error text → cause → fix, plus the typing rules that bite in `--!strict`.
Message substrings below are copied from the source; match on them, do not paraphrase.

---

## 1. Quick Diagnostic Blame Map

| Error message substring | Root cause in agent code | Fix |
| :--- | :--- | :--- |
| `Tag: names must be strings, Tags, or a plain {...} list of those — a name list cannot have nil holes` | A `nil` gap in a name list: `{ "Tag1", nil, "Tag2" }` | Filter the list before passing it. `q.None` is **not** a substitute — it is rejected as "a table with a metatable" |
| `Ref: Wait() must be called from a yieldable coroutine` | `ref:Wait()` on a non-yieldable thread | Call it inside `task.spawn`, or pass a thread to register a waiter without yielding |
| `Ref:Unwrap: the Ref is empty (Value is nil) — not filled yet, or never placed` | `:Unwrap()` before the Ref was filled, or the Ref was never put in an array part | Place the `PreRef` in the children array; unwrap only after the instance exists |
| `nativeClaim: Instance is already claimed by quad` | `q.Claim` on the same Instance twice, or on something `D.*` produced | Claim only unmanaged instances |
| `bindLifetime: Instance is not claimed by quad` | A foreign Instance (never created by `D.*` nor claimed), or an already-destroyed one | `q.Claim(inst, descriptor)` first; never reuse a destroyed Instance |
| `Claim: second argument must be a D.Mapper descriptor` | `q.Claim(inst)` with one argument | `q.Claim(inst, D.Mapper.<Class>(D.Mapper.Root)({ ... }))` |
| `Modifier: a Modifier cannot be a value of key "..." — place it in the array part` | `{ Modifier = myMod }` as a hash key | Put it in the array part: `{ myMod }` |
| `Source: cannot hold a Modifier as a Source value` | `q.Source(someModifier)` | Keep Modifiers out of reactive values |
| `Tween: Value must be a plain value, not a State` | `q.Tween { Value = myState }` | `myState:Apply(q.Animate{...})`, or build the Tween inside a `:Compute` |
| `Slot:List: duplicate key ...` | `keyFn` returned the same key for two items | Return a unique identifier (e.g. `item.Id`) |
| `Slot:Remove: index must be a positive integer (got ...)` | `slot:Remove(childInstance)` — CRUD takes indices | `slot:Remove(slot:IndexOf(child))` |
| `Slot: destroyed Slot cannot be an element` / `... cannot be mounted` / `... cannot be reused` | Reusing a Slot whose owner Instance was destroyed | Create a fresh `q.Slot()` |
| `Slot:Add: cannot add a Slot to itself or to one of its own descendants (that would be a cycle)` | Circular parenting: `a:Add(b); b:Add(a)` | Keep the slot graph acyclic — this errors immediately, it does not recurse |
| `Context:Get: no value for Provider(...)` | Reading a provider key the Context never `:Set` | `:Set` it at the root, or probe with `:Peek` |
| `Context:Set: value for ... must not be nil` | `ctx:Set(provider, nil)` | Absence is "not set" — omit the key |
| `Debounce: Time must be a non-negative number or a State<number> (got ...)` | Negative or wrong-typed `Time` in `q.Debounce`/`q.Throttle` (`Throttle:` for the throttle) | Pass a non-negative number of seconds or a `State<number>` |
| `Operator.Sum: Apply target must be a State (got ...)` | Calling an operator factory on a plain value | Use `:Apply` on a State: `myState:Apply(q.Operator.Not)` |
| `Dispatch: no handler matched key Parent (value: ..., brand: Inst)` | `Parent = someInstance` as a prop | `Parent` is not a prop — set `.Parent` from outside after creation |
| `Dispatch.recompute: sourceList[N] is nil — bookkeeping is broken` | A `nil` hole in the array part of a props table | Use `q.None`: `props.Modifier or q.None` |

---

## 2. Strict Typing & Solver Invariants

### 2.1 Variance

`State<T>` is **invariant** in an annotated variable: `local x: State<Instance> = someStateOfFrame`
fails. Input positions are covariant markers, so the same value *does* go into a
`Slot<Instance>` element slot, a child array, or a Modifier field.

- Annotate derived states with the concrete class: `QuadTypes.State<Frame>`.
- Types live in `quad-types` and the generated `D` module — `q.State<T>` is not a type.

### 2.2 Modifier Downcasting

```luau
local base = D.Modifier.GuiObject():Visible(true)
local checked = base:AsTextButton():Text("go")                    -- CHECKED (one method per subclass)
local forced  = base:As<<DModule.TextLabelModifier>>()            -- UNCHECKED, caller asserts
```

`:As<<T>>()` does no class check; its optional string argument only names a custom class.
Prefer `:As<Class>()` — the method existing *is* the check.

### 2.3 Event Callback Signatures

Event handlers receive the engine arguments directly, with **no `self`**:

```luau
-- correct
Activated = function(inputObject, clickCount) end

-- wrong: there is no leading self
-- Activated = function(self, inputObject) end
```

In `--!strict` the declared handler type must match the generated prop type exactly,
arity included — a `() -> ()` field does not satisfy
`Activated: (((inputObject: InputObject, clickCount: number) -> ()) | StateMarker<...> | None)?`. Spell the
engine signature out in component prop types.

### 2.4 `q.OnChange` vs Events

`q.OnChange(name, fn)` is a descriptor value and belongs in the **array part**, not as a
hash key. The callback receives the new property value:

```luau
D.TextBox {
    q.OnChange("Text", function(newText: string)
        print("Text changed to:", newText)
    end),
}
```

### 2.5 `:Compute` / `:Observer` callback shapes

- `state:Compute(fn, ...deps)` → `fn(selfHandle, previous, ...depHandles)`. Every dep is
  a **handle**; `#dep` is silently `0`. Read with `dep:Get()`.
- `state:Observer(fn)` → `fn(targetState, observer, emitFrom?)`. The value is **not**
  passed — call `targetState:Get()`.
- A fresh `Observer`/`EffectHandle` fires once at registration and is then **not
  subscribed** (`Subscribed == false`): later changes are held, not delivered. Put the
  handle in an array part to bind it to that instance's lifetime (delivery resumes with one
  catch-up; `Subscribed` stays `false` — that flag only reflects `:Subscribe()`), or call
  `:Subscribe()` on an unbound handle (replays the held change once; calling it on a bound
  handle errors `Observer: already bound to an Instance`). Silent "my observer never fires" bugs are
  almost always this.
- `slot:List(data, updateFn, keyFn?, opts?)` → `updateFn(item, index, offset, prev, ud)`.
- `slot:Single(state, updateFn?, opts?)` → `updateFn(item, offset, prev, ud)` (no index).
