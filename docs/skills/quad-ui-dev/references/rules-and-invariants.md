# Quad Rules & Invariants (Diagnostic Cheat Sheet)

Runtime error text → cause → fix, plus the typing rules that bite in `--!strict`.
Message substrings below are copied from the source; match on them when diagnosing, do not paraphrase. They are diagnostics, not API — never branch on message text in user code (wording may change without notice).

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
| `Slot: destroyed Slot cannot be an element` / `... cannot be mounted` / `... cannot be reused` | Reusing a Slot that was **destroyed as an element** — an owning parent Slot `:Remove`/`:Clear`d it, its `:List` key disappeared, or `q.dispose(slot)` ran | Create a fresh `q.Slot()` |
| `... (if its owner was destroyed outside quad — inst:Destroy() — the value went with it ...)` | A different case, appended as a note to other messages ("already mounted", `dispose:`): the mount target Instance was destroyed outside quad | Extract the value before destroying its owner, as with an Instance |
| `Slot: this element is not claimed by quad — build it with the Declaration or take it over with Claim first (an Instance made by another quad module instance also counts as not claimed here)` | Putting an Instance quad does not own (`Instance.new`, another library's tree) into a Slot (`Add`/constructor/`Replace`/`Splice`/`List`) | `q.Claim` it first, or build it with `D.<Class> { … }` — Slot never claims on your behalf |
| `InstanceChild: this Instance is not claimed by quad — build it with the Declaration or take it over with Claim first (…)` | The same rule at a static numeric-key slot: `D.Frame { Instance.new("TextLabel") }` | `q.Claim` it first, or build it with `D.<Class> { … }` |
| `Claim: no child matched key {key} under {inst} (mapper {class}) — a child with that name must also be a {class}` | The template has no child by that name, or the child by that name is not that class (`IsA`) — e.g. `M.TextLabel("Kid")` over an `ImageLabel` named Kid | Fix the name or the mapper class to match the template |
| `Bookkeeping.claimOwnerAt: this element is already mounted elsewhere — multiple mounts are not allowed` | One value, one seat: the same Instance put under two parents (`D.Frame { c }` twice, `{ c, c }`), a Slot element placed as a static child, a shorthand-managed child (`_quad_round`) placed anywhere | Retract it from the first seat (`:Set(nil)` the State holding it, or `slot:Extract`) before re-using it; build a second Instance if you need two |
| `State: Compute fn is already running for this value — a dependency cycle (…), a yield inside the fn, or an earlier read that threw (…)` | A `:Compute` fn reads its own result (directly or via a downstream State), yields and is read again meanwhile, or threw on an earlier read of the same value generation | Break the cycle (read only upstream nodes), never yield in a Compute; after a throw, fix and `:Set` the upstream — the fn runs again on the new generation |
| `Slot: cannot mutate a Slot while it is being mounted — …` | A `:List`/`:Single` `updateFn` (first mount) or an Observer fired during the mount did `Add`/`Remove`/… or `:List` on an **ancestor** Slot that is being mounted | Keep `updateFn` to building this item (its own child Slots are fine); mutate ancestors after the mount, from an Observer |
| `Slot:Add: cannot add a Slot to itself or to one of its own descendants (that would be a cycle)` | Circular parenting: `a:Add(b); b:Add(a)` | Keep the slot graph acyclic — this errors immediately, it does not recurse |
| `Context:Get: no value for Provider(...)` | Reading a provider key the Context never `:Set` | `:Set` it at the root, or probe with `:Peek` |
| `Context:Set: value for ... must not be nil` | `ctx:Set(provider, nil)` | Absence is "not set" — omit the key |
| `Debounce: Time must be a non-negative number or a State<number> (got ...)` | Negative or wrong-typed `Time` in `q.Debounce`/`q.Throttle` (`Throttle:` for the throttle) | Pass a non-negative number of seconds or a `State<number>` |
| `Operator.Sum: Apply target must be a State (got ...)` | Calling an operator factory on a plain value | Use `:Apply` on a State: `myState:Apply(q.Operator.Not)` |
| `Dispatch: no handler matched key Parent (value: ...)` | `Parent = someInstance` as a prop | `Parent` is not a prop — set `.Parent` from outside after creation |
| `Bookkeeping.recompute: sourceList[N] is nil — a nil hole in the numeric-key part of props ({ a, nil, b })? fill the optional slot with q.None; …` | A `nil` hole in the array part of a props table | Use `q.None`: `props.Modifier or q.None` |

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
local forced  = base:As<<DeclarationModule.TextLabelModifier>>()            -- UNCHECKED, caller asserts
```

`:As<<T>>()` does no ancestry check. Its optional string argument must be an already
registered Modifier class name — an unknown one raises `Modifier: unknown modifier class "..."` —
and it only retags; it never checks that the value really is that class.
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
- A fresh `Observer`/`Effect` fires once at registration and is then **not
  subscribed** (`Subscribed == false`): later changes are held, not delivered. Put the
  handle in an array part to bind it to that instance's lifetime (delivery resumes with one
  catch-up; `Subscribed` stays `false` — that flag only reflects `:Subscribe()`/`:WeakSubscribe()`), or call
  `:Subscribe()` on an unbound handle (replays the held change once; calling it on a bound
  handle errors `Observer: already bound to an Instance`). Silent "my observer never fires" bugs are
  almost always this.
- `slot:List(data, updateFn, keyFn?, opts?)` → `updateFn(ctx) -> (result, userdata)`, `ctx = { Item, Index, Offset, Prev, UserData }`
  (a fresh table per call — closures may capture `ctx`; `Index` is `0` on a `KeyGone` call).
- `slot:Single(state, updateFn?, opts?)` → the same `updateFn(ctx)` shape, `Index` included (one `updateFn` can serve both).
