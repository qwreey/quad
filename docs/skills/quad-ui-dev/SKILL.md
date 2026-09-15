---
name: quad-ui-dev
description: >-
  Dense code-generation and architecture guide for building Roblox UI with the Quad
  reactive framework. Covers Source/State ontology, DOMless Slot lists, 3-tier Modifier
  priority, Studio prefab Claiming, Tween/Animate transitions, and nil-hole defense.
---

# Quad UI Development Engine (Agent Specification)

Reference for agents generating Luau UI code with **Quad**, a DOMless reactive UI
framework for Roblox. Every claim here is checked against `quad-base`/`quad-roblox` and
their specs. When a symbol is not listed here, grep the source rather than invent one.

**References**: `references/code-recipes.md` (runnable patterns), `references/rules-and-invariants.md`
(verbatim error strings → fix), `references/v1-migration.md` (porting a **quad v1** codebase:
mapping table, removed features, strict-mode blockers).

---

## 0. Live Docs — fetch the real page before you assert

This skill is a compressed summary. The published docs at <https://quad.qwreey.moe/> are the
user-facing source of truth (snippets there are executed on the mock backend and type-checked
with the new solver). **When a user asks something this file does not answer, or when you need to
verify a signature, an error string, or a contract, fetch the page's plain-markdown twin instead
of guessing.**

- **URL rule**: append `.md.txt` to any page path — `https://quad.qwreey.moe/<track>/<page>.md.txt`
  (Korean is the root locale, so there is no `/ko/` prefix; an English tree, when it exists, lives
  under `/en/…`). Example: `https://quad.qwreey.moe/reference/core/06-slot.md.txt`. The response is
  `text/plain` markdown with only `title`/`description` frontmatter. There is no `llms.txt` index —
  use the map below.
- **Map (what to fetch for what)**:
  - `reference/00-index` — every public symbol → its page. Start here for name lookups.
  - `reference/core/01`…`11` (module, Source, State, Store, Observer·Effect, Slot, Ref, Modifier,
    Tag·Attr, sentinels, predicates), `reference/sugar/01`…`06` (Context, Operator,
    Debounce·Throttle, lifecycle hooks, Fallback·Traceback, Blocker), `reference/roblox/01`…`06`
    (install, `D`, `D.Modifier`, Claim·Mapper, OnChange, Tween·Animate), `reference/extend/01`·`02`
    (backend provider / dispatch handler contracts). One type per page: signature → args → return →
    example → behavior → **error table (verbatim strings)** → related.
  - `how-to/01`…`09` — recipes: component boundary conventions, form validation, long lists,
    RemoteEvent/input bridging, theming, headless testing, Studio `Claim`, v1 migration, and the
    error-reading appendix (`09`).
  - `getting-started/00`…`19` — the linear tutorial (one counter grows chapter by chapter). Fetch a
    chapter when the user is learning, not for lookups.
  - `overview/01` (comparison with Fusion/Vide/react-lua, design trade-offs, what is missing and
    why), `overview/02` (for quad v1 users).
  - `quadnomicon/01`…`11` — internals (revision/epoch, Slot prefix-sum tree, memory topology,
    markers, ownership, liveness gate, dispatch engine, …). Only when the question is "how is it
    implemented".
  - `/changelog/` — full CHANGELOG (Keep a Changelog; `[Unreleased]` first). Version pages also exist
    under `/changelog-versions/`.
- **Precedence when sources disagree**: source code > reference page > this skill. Never invent a
  symbol that neither the index nor the source lists.

## 1. Quick Reference & Core Invariants

### 1.1 Environment & Imports

`quad-base` and `quad-roblox` are two separate modules; there is no `Quad.QuadRoblox`.
Distribution is pesde (`qwreey/quad_base`, `qwreey/quad_roblox`, `qwreey/quad_types`, roblox target
→ one `roblox_packages/` folder; see `getting-started/00-installation`). The docs' convention is one
setup module (`ReplicatedStorage/Client/UI/Quad`) that installs the provider once and re-exports the
types, required as `require("@game/ReplicatedStorage/Client/UI/Quad")` — follow the project's
layout if it differs.

```luau
--!strict
-- install path depends on the project layout
local Quad = require(<quad-base module>)              -- already a live instance
local QuadRoblox = require(<quad-roblox module>).QuadRoblox
local QuadTypes = require(<quad-types module>)        -- types only
local q = Quad:UseProvider(QuadRoblox)                -- installs D / OnChange / Animate / Tween / isTween
local D = q.Declaration
```

Snippets below assume this prologue.

- `require(quad-base)` **is** the default instance; `Quad.New()` only for isolated ones.
- `UseProvider` is one slot per module: a *different* provider function errors
  (`UseProvider: this Quad module already has a provider`); the same one is a no-op.
- Types come from `quad-types` (`QuadTypes.State<T>`, `Source<T>`, `Slot<T>`, `Store<T>`,
  `Provider<T>`, `Context`) and the generated `Declaration` module (`DeclarationModule.FrameModifier`,
  `DeclarationModule.Field<T>`, …). **`q.State<T>` does not exist on the module value itself** — `q` is a value, not a type (the `q.State<T>` form in the reference works only because the setup module re-exports the types under its own name).

### 1.2 Core Ontological Grammar

| Concept | Constructor / Type | Mutability | Key Methods & Rules |
| :--- | :--- | :--- | :--- |
| **`Source<T>`** | `q.Source(init)` | Writable root | `:Get()`, `:Set(v)`, `:Emit()`. Propagates synchronously. |
| **`State<T>`** | Return of `:Compute`/`:Apply`/`:Gate` | Read-only derived | `:Get()`, `:Compute(fn, ...deps)`, `:Depend(...)`, `:Apply(f)`, `:Observer(fn)` (see 6.3). |
| **`Store`** | `q.Store{ key = q.Source(v) }` | Bag of Sources | Reset per field: `store.Field:Set(v)`. |
| **`Context`** | `q.Context()` | Explicit value bag | Keys are `q.Context.Provider(name?)`. Passed through props — no tree walk. |
| **`Slot`** | `q.Slot<<T>>(initial?)` | Dynamic child container | `:Add(el, index?)`, `:Remove(index)`, `:Replace`, `:Splice`, `:Clear`, `:List(...)`, `:Single(...)`. DOMless. |
| **`Modifier`** | `q.Modifier{...}` / `D.Modifier.<Class>()` | Immutable property bag | Chaining clones (`mod:Size(...)`). Later array entry wins. |
| **`Ref<T>`** | `q.Ref<<Frame?>>(nil)`, `q.PreRef(...)`, `q.PostRef(...)` | Instance box | The initial value is a required argument at the type level (`Ref: <T>(default: T)`; the runtime does not check). `ref.Value` may be nil; `ref:Unwrap()` errors when empty; `:Wait()` awaits the NEXT `:Set`. |
| **`Tween<T>`** | `q.Tween{ Value = v, Time = 0.3 }` | Value container | `Value` must be plain (never a State). `Override`, `Dedup`. |
| **`Animate`** | `q.Animate{ Time = 0.2, ... }` | Applicative sugar | `state:Apply(q.Animate{ Time = 0.2 })`. |
| **`Debounce`/`Throttle`** | `q.Debounce{ Time = 0.3 }` | Time gate | `state:Apply(q.Debounce{...})`. Optional `Handle = q.Ref(nil)`. |
| **`Operator`** | `q.Operator.*` | Named combinators | `Not`, `Sum`, `Product`, `Min`, `Max`, `Clamp`, `Band`/`Bor`/`Bxor`/`Bnot`/`Shl`/`Shr`, `Alternative`, `Indexed`. |
| **`Claim`** | `q.Claim(inst, desc)` | Prefab binding | Takes an existing tree into quad ownership. Two args — the descriptor is required. |

Values that belong in the **array part** of a props table, never as hash keys:
`Ref`/`PreRef`/`PostRef`, `Observer`, `EffectHandle`, `Slot`, `Modifier`, `Tag`, `Attr`,
`q.OnChange(...)`, `q.OnCreated/OnRendered/OnDestroyed(...)`, and child instances.
`AttrKey` is the exception — a hash key: `[q.AttrKey("Hp")] = hpState` (see 6.2).

---

## 2. Reactive Primitives: Strict Agent Rules

### 2.1 Trailing Dependencies for `:Compute`

`fn` receives `(selfHandle, previous, ...depHandles)`. **Every dep arrives as a State
handle, not as a value** — read it with `:Get()`. `#dep` or `dep .. ""` on a handle does
not error, it silently produces garbage (`#handle` is `0`).

```luau
local firstName, lastName = q.Source("Ada"), q.Source("Lovelace")

-- 1 compute node, deps passed as trailing arguments
local fullName = firstName:Compute(function(self, prev, last)
    return `{self:Get()} {last:Get()}`
end, lastName)
```

`state:Depend(...)` is supported (it mints one extra node that passes the receiver's value through and
also re-publishes when the given deps change — no callback, no values passed) — not prohibited.

### 2.2 Nesting and Stores

- `State<State<T>>` is **supported**. In a property/child slot the inner state is
  subscribed too (`StoreBind` re-dispatches the unwrapped value at `index + 1`), so the
  inner `:Set` updates the instance. As a `:Compute` dependency only the outer handle is
  subscribed — the inner `:Set` does not recompute; read it via the outer or `q.Operator.Indexed`.
- A `Store` inside a `Source`/`State` is allowed but **not reactive per field**: the
  outer state fires only when the whole value is replaced. Use `q.Operator.Indexed` for a
  reactive field read.
- A `Modifier` inside a `Source` errors: `Source: cannot hold a Modifier as a Source value`.
- To reset a form, set the individual `Source` fields: `store.Name:Set("")`.

### 2.3 Operator Combinators via `:Apply`

```luau
local Op = q.Operator
local isVisible, price, tax, shipping = q.Source(true), q.Source(100), q.Source(5), q.Source(3)
local rawPos, maxBound = q.Source(150), q.Source(100)
local optionalName = q.Source<<string?>>(nil)
local theme = q.Source({ Primary = "red" })

local isHidden   = isVisible:Apply(Op.Not)                     -- unary
local totalPrice = price:Apply(Op.Sum(tax, shipping))          -- n-ary, plain numbers or States
local clamped    = rawPos:Apply(Op.Clamp(0, maxBound))
local safeName   = optionalName:Apply(Op.Alternative("Guest")) -- State<T?> -> State<T>
local primary    = theme:Apply(Op.Indexed<<string>>("Primary"))  -- caller supplies the result type
```

`Op.Indexed` needs an explicit type argument — the key is not enough to infer it.
`And`/`Or`, comparisons, and `Sub`/`Div` deliberately do not exist.

---

## 3. Component Authoring & Modifier Precedence

### 3.1 Component Contract

A component is a plain function returning an `Instance` or a `Slot`. Do not mutate its
`props` table (convention — quad neither freezes nor copies it).

```luau
export type ButtonProps = {
    Text: string | QuadTypes.State<string>,
    -- the handler type must match the engine signature exactly, arity included
    OnClick: (inputObject: InputObject, clickCount: number) -> (),
    Modifier: any?,   -- or DeclarationModule.IntoTextButton for a typed boundary
}

local function Button(props: ButtonProps)
    return D.TextButton {
        -- 1. inline properties (highest priority)
        Text = props.Text,
        AutoButtonColor = true,

        -- 2. events: engine arguments only, no `self`
        Activated = props.OnClick,

        -- 3. modifiers / children in the array part
        props.Modifier or q.None,
    }
end
```

`props.Modifier or q.None` is mandatory: a `nil` in the array part is a hole that breaks
the array walk, and the drive dies inside bookkeeping rather than at the author's line.

### 3.2 3-Tier Modifier Priority

1. **Inline properties** on the element table always win.
2. Among modifiers in the array part, the **later** one wins per field.
3. `Modifier.Overridden(A, B)` (or `A:Overridden(B)`) — `B` wins per field.

### 3.3 Typed Modifiers & Downcasting

```luau
-- both forms exist: builder chain and table call
local buttonMod = D.Modifier.TextButton():BackgroundTransparency(0.5):Text("Go")
local sameThing = D.Modifier.TextButton{ BackgroundTransparency = 0.5, Text = "Go" }

local base = D.Modifier.GuiObject():Visible(true)
local checked   = base:AsTextButton():Text("ok")            -- CHECKED: one method per subclass
local unchecked = base:As<<DeclarationModule.TextLabelModifier>>()     -- UNCHECKED: caller asserts the type
```

`:As<<T>>()` performs no class check (its optional string argument only names a custom
class). Prefer the generated `:As<Class>()` methods — their existence is the check.

### 3.4 Multi-Store Prop Passing via `Context`

`Context` is an explicit bag passed through props; it does not walk the tree.

```luau
type ThemeStore = QuadTypes.Store<{ Accent: QuadTypes.Source<Color3> }>
local themeStore = q.Store { Accent = q.Source(Color3.fromRGB(0, 120, 255)) }

-- 1. provider keys: distinct table identities, use an explicit type argument to give them a type
local ThemeProvider = q.Context.Provider<<ThemeStore>>("Theme")

-- 2. populate at the root; :Set mutates the bag and returns it
local ctx = q.Context():Set(ThemeProvider, themeStore)

-- 3. leaves read with :Get (errors when unset) or :Peek (nil when unset)
local theme = ctx:Get(ThemeProvider)
```

`:Set(provider, nil)` is rejected — absence means "not set".

---

## 4. The Slot Engine

### 4.1 DOMless Fragment Nature

Slots create no container `Frame`: their children mount directly under the parent
Instance and coexist with `UIListLayout` / `UIGridLayout`.

### 4.2 Keyed `Slot:List` with `userdata` Recycling

`updateFn(ctx) -> (result, userdata)` with `ctx = { Item, Index, Offset, Prev, UserData }` — a fresh
table per call, so closures created inside may capture `ctx`. `ctx.Offset` is a
read-only `State<number>`. Return `ctx.Prev` to keep an element, `q.Detach` to unmount but keep it
alive, `nil`/`q.None` to destroy it. `ctx.Item` is `q.KeyGone` when a key left the data (`ctx.Index` is `0` then).

Under `--!strict` the `ctx` parameter and the return pack must be annotated, and the
slot needs its element type: `q.Slot<<Instance>>()`.

```luau
type ItemData = { Id: string, Title: string }
type RowUD = { titleSrc: QuadTypes.Source<string>, orderSrc: QuadTypes.Source<number> }
type RowCtx = {
    Item: ItemData | QuadTypes.KeyGone,
    Index: number,
    Offset: QuadTypes.State<number>,
    Prev: QuadTypes.SlotItem<Instance>?,
    UserData: RowUD?,
}

local function ItemList(itemsState: QuadTypes.State<{ ItemData }>)
    local slot = q.Slot<<Instance>>()

    slot:List(itemsState, function(ctx: RowCtx): (any, RowUD?)
        if ctx.Item == q.KeyGone then
            return nil -- key gone: destroy
        end
        local data = ctx.Item :: ItemData
        local prev, ud = ctx.Prev, ctx.UserData
        if prev and ud then
            ud.titleSrc:Set(data.Title)     -- mutate cached Sources, reuse the Instance
            ud.orderSrc:Set(ctx.Index)
            return prev, ud
        end

        local titleSrc = q.Source(data.Title)
        local orderSrc = q.Source(ctx.Index)
        local row = D.Frame {
            LayoutOrder = orderSrc,
            D.TextLabel { Text = titleSrc },
        }
        return row, { titleSrc = titleSrc, orderSrc = orderSrc }
    end, function(item: ItemData)
        return item.Id -- stable unique key; duplicates error
    end)

    return slot
end
```

`keyFn` is the 3rd argument and `opts` the 4th (`slot:List(data, updateFn, keyFn?, opts?)`). Physical reordering is not performed —
order is expressed through `LayoutOrder`.

### 4.3 Non-owning `Slot:Single`

Same `updateFn(ctx)` shape as `List`, `ctx.Index` included — one `updateFn` can serve both.
With `{ OwnsElements = false }` a replaced element is unmounted (`Parent = nil`) instead of
destroyed, so it can be mounted somewhere else.

```luau
local selected = q.Source<<Instance?>>(nil)
local slot = q.Slot<<Instance>>()
slot:Single(selected, nil, { OwnsElements = false })
-- selected:Set(other) now unparents the previous element instead of destroying it
```

---

## 5. Studio UI Binding (`q.Claim`)

`q.Claim(inst, descriptor)` takes an existing tree (a Studio prefab clone) into quad
ownership and drives it. Both arguments are required; it returns the same instance.
The descriptor is built from `D.Mapper` and maps children by `Name`.

```luau
local M = D.Mapper

local function InventoryCard(template: Instance, itemData: { Id: string, Name: string, IconId: string })
    local card = template:Clone()

    return q.Claim(card, M.Frame(M.Root)({
        M.TextLabel("ItemName")({ Text = itemData.Name }),
        M.ImageLabel("Icon")({ Image = itemData.IconId }),
        BackgroundTransparency = 0.25,          -- props of the claimed root
    }))
end
```

Mapped children take the same props as `D.*` calls (values, States, Modifiers, events),
and freshly built `D.*` children may be mixed into the same array.

### Invariants of `Claim`

1. **Claim-once**: an Instance can be claimed once. Instances made by `D.*` are already
   claimed — `nativeClaim: Instance is already claimed by quad`.
2. **One-shot descriptor**: a `M.<Class>(key)({...})` value is consumed by the `Claim`
   that uses it — `Claim: mapper descriptor was already used (descriptors are one-shot)`.
3. **Own-all**: quad owns the resolved children; external code must not add or remove
   them directly. Never claim a shared engine container such as `PlayerGui` — mount a
   quad-made `ScreenGui` under it instead. Both are conventions quad cannot detect (no
   error is raised; Roblox has no reparent hook) — violating them desyncs bookkeeping.

---

## 6. Animations, Styling, and Events

### 6.1 `Tween` and `Animate`

```luau
local hoverSrc, targetSrc = q.Source(false), q.Source(UDim2.new())

-- Animate: applicative sugar over a derived State
local btnColor = hoverSrc:Compute(function(self)
    return if self:Get() then Color3.fromRGB(60, 60, 60) else Color3.fromRGB(35, 35, 35)
end):Apply(q.Animate { Time = 0.2, Style = Enum.EasingStyle.Quad })

-- Tween: a first-class value emitted from a Compute
local positionState = targetSrc:Compute(function(self)
    return q.Tween {
        Value = self:Get(),   -- plain value; a State here errors
        Time = 0.5,
        Override = "Cancel",  -- "Cancel" (default) or "Finish"
        Dedup = true,         -- skip when the target equals the recorded one
    }
end)
```

The first assignment snaps to the value; later emissions run an engine tween.

### 6.2 `Tag` and `Attr`

- `q.Tag("A", "B")` — reference-counted CollectionService tag set, array part.
  A name list must not contain `nil` **or** `q.None`; filter it before passing.
- `q.Attr{ Level = 3 }`, `q.StringAttr("Title", v)`, `q.NumberAttr`, `q.BooleanAttr` —
  array part. `[q.AttrKey("Hp")] = hpState` is a hash key; it drives correctly but the
  generated prop types do not cover it, so prefer the array-part forms in `--!strict`.
- `q.None` as an attribute value deletes the attribute in the engine. A **State whose value
  becomes `nil` also deletes it** (`setAttr(inst, name, nil)`). In a group table `Attr{ X = nil }`
  the key simply does not exist (no entry, no error); a value that DISAPPEARS from a replaced
  group is NOT unset — the old attribute persists until an explicit `None`/nil. Only the scalar
  sugars (`StringAttr`/`NumberAttr`/`BooleanAttr`) reject `nil`
  (`value of "X" must not be nil — use None to delete`).

### 6.3 Refs and Lifecycle Hooks

`PreRef` in the array part is filled in a pre-pass, before the rest of the props table
is driven. `ref:Unwrap()` returns the value or errors when empty
(`Ref:Unwrap: the Ref is empty (Value is nil) — not filled yet, or never placed`) — it is
the way to drop `nil` from the type.

```luau
local function InteractiveCard()
    local cardRef = q.PreRef<<TextButton?>>(nil)   -- strict needs the element type

    return D.TextButton {              -- Frame has no Activated; use a GuiButton class
        cardRef,
        Activated = function()
            cardRef:Unwrap().BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        end,
        q.OnRendered<<TextButton>>(function(inst)
            -- children and properties are set; the instance may or may not be parented yet
        end),
    }
end
```

- `q.OnCreated<<Class>>(fn)` → a `PreRef`: runs right after instantiation, before
  anything else.
- `q.OnRendered<<Class>>(fn)` → a `PostRef`: runs after this instance's own children and
  properties are mounted. **It does not guarantee that the instance is parented**, so
  do not read `AbsoluteSize`/`AbsolutePosition` there.
- `q.OnDestroyed(fn)` → an `EffectHandle`: runs on leaf death.

All three go in the array part; multiple registrations fire in array order. Give the two
Ref-returning hooks their element type explicitly (`q.OnCreated<<Frame>>(...)`) —
without it `--!strict` fails with `Type functions do not currently support types of the form '*error-type*'` whenever the callback annotates or uses `inst`.

`state:Observer(fn)` fires once at registration and then **holds** further changes — a
fresh Observer has `Subscribed == false`. Bind it by putting the handle in an array part
(it then lives and dies with that instance), or call `:Subscribe()`. `q.Effect(fn, ...deps)`
behaves the same way; its cleanup return is optional.

### 6.4 Reactive Time Gates

```luau
local searchInput = q.Source("")
local debouncedQuery = searchInput:Apply(q.Debounce { Time = 0.3, MaxTime = 1.0 })

local scrollPos = q.Source(0)
local throttledScroll = scrollPos:Apply(q.Throttle { Time = 0.05 })
```

`Time` is required and may be a number or a `State<number>`. `MaxTime` is Debounce-only.
`Leading`/`Trailing` may not both be `false`. `Handle = q.Ref(nil)` yields a per-`Apply`
control handle; one handle per `:Apply`.

### 6.5 Component Error Boundaries

```luau
local function ProfileCard(userId: number): TextLabel
    return D.TextLabel { Text = `user {userId}` }   -- may error
end

local SafeProfile = q.Fallback(ProfileCard, function(err)
    return D.TextLabel { Text = "Failed to load profile" }
end)
local Traced = q.Traceback(ProfileCard, function(err, trace) return D.TextLabel { Text = trace } end)
```

`err` is `any` — never assume it is a string. The base function must have a return type
the solver can see; `Fallback` returns `Ok | Err`.

---

## 7. Negative Constraints

| Anti-pattern | Observed result | Correct form |
| :--- | :--- | :--- |
| Nil hole in the array part `{ a, nil, b }` | The drive dies on the hole: `Dispatch.recompute: sourceList[2] is nil — a nil hole in the numeric-key part of props ({ a, nil, b })? fill the optional slot with q.None; …` | `{ a, q.None, b }`, or `props.X or q.None` |
| `Modifier` as a hash key | `Modifier: a Modifier cannot be a value of key "..." — place it in the array part` | Put the value in the array part |
| `PreRef`/`PostRef`/`Observer` as a hash key | `PreRef: must be an array item, not the value of a string key` (same shape for `PostRef:`/`Observer:`) | Put the value in the array part |
| `Ref`/`Slot`/`Tag` as a hash key | `Dispatch: no handler matched key <K> (value: table, brand: Ref)` (brand `Slot`/`Tag` likewise) | Put the value in the array part |
| Reading a `:Compute` dep without `:Get()` | No error — `#handle` is `0`, concatenation is garbage | `dep:Get()` |
| `Modifier` inside a `Source` | `Source: cannot hold a Modifier as a Source value` | Keep modifiers out of reactive values |
| `q.Tween{ Value = someState }` | `Tween: Value must be a plain value, not a State` | `state:Apply(q.Animate{...})`, or build the Tween inside a `:Compute` |
| `q.Claim(inst)` with one argument | `Claim: second argument must be a D.Mapper descriptor` | `q.Claim(inst, D.Mapper.<Class>(D.Mapper.Root)({...}))` |
| Reusing a `D.Mapper` descriptor | `Claim: mapper descriptor was already used (descriptors are one-shot)` | Build a fresh descriptor per `Claim` |
| `A:Add(B); B:Add(A)` | Immediate error: `Slot:Add: cannot add a Slot to itself or to one of its own descendants (that would be a cycle)` | Keep the slot graph acyclic |
| `Parent = ...` as a prop | `Dispatch: no handler matched key Parent (value: Instance, brand: Inst)` (the `value:` part is `typeof(v)`) | Set `.Parent` from outside after creation |
| `Activated` on a `Frame` | `Dispatch: no handler matched key Activated (value: function)`; `FrameParam` has no such field in `--!strict` | Use `TextButton`/`ImageButton` |
| `AbsoluteSize` read inside `OnRendered` | No error, but `PostRef` guarantees only the subtree — parenting is explicitly not guaranteed | Read it later, from an event or an explicit connection |
