# Quad UI Code Recipes

Copy-paste recipes for agents generating Roblox UI with Quad. Every recipe below assumes
this prologue once per module; nothing else is implicit.

```luau
--!strict
-- install path depends on the project layout
local Quad = require(<quad-base module>)              -- already a live instance
local QuadRoblox = require(<quad-roblox module>).QuadRoblox
local QuadTypes = require(<quad-types module>)        -- types only: State<T>, Source<T>, Slot<T>, Provider<T>
local q = Quad:UseProvider(QuadRoblox)                -- installs D / OnChange / Animate / Tween / isTween
local D = q.D
```

---

## 1. Counter Component (Source + Animated Colour)

```luau
local function Counter()
    local count = q.Source(0)

    local countText = count:Compute(function(self)
        return `Count: {self:Get()}`
    end)

    local frameBg = count:Compute(function(self)
        return if self:Get() > 5 then Color3.fromRGB(220, 50, 50) else Color3.fromRGB(50, 120, 220)
    end):Apply(q.Animate {
        Time = 0.2,
        Style = Enum.EasingStyle.Quad,
    })

    return D.ScreenGui {
        ResetOnSpawn = false,

        D.Frame {
            Size = UDim2.fromOffset(200, 100),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = frameBg,

            D.TextLabel {
                Size = UDim2.new(1, 0, 0.5, 0),
                Text = countText,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 1,
            },

            D.TextButton {
                Size = UDim2.new(1, 0, 0.5, 0),
                Position = UDim2.new(0, 0, 0.5, 0),
                Text = "Increment (+1)",
                Activated = function()
                    count:Set(count:Get() + 1)
                end,
            },
        },
    }
end

return Counter
```

The `:Compute` callback's first parameter is the **self handle** — read it with `:Get()`.
`Activated` needs a `GuiButton` class (`TextButton`/`ImageButton`); `Frame` has no such
event.

---

## 2. Keyed List with `userdata` Recycling

`updateFn(item, index, offset, prev, ud) -> (result, ud)`; `keyFn` is the 3rd argument (`slot:List(data, updateFn, keyFn?, opts?)`).
Return `prev` to reuse an element, `q.Detach` to unmount but keep it, `nil`/`q.None` to
destroy it. `item` is `q.KeyGone` when a key disappeared from the data. There is no
virtualization here — every row exists; only the Instances and their Sources are recycled.
Under `--!strict` the callback parameters and its return pack must be annotated, and the
slot needs its element type: `q.Slot<<Instance>>()`.

```luau
export type Item = {
    Id: string,
    Title: string,
    Score: number,
}
type RowUD = {
    titleSrc: QuadTypes.Source<string>,
    scoreSrc: QuadTypes.Source<string>,
    orderSrc: QuadTypes.Source<number>,
}

local function Leaderboard(itemsState: QuadTypes.State<{ Item }>)
    local slot = q.Slot<<Instance>>()

    slot:List(itemsState, function(
        item: Item | QuadTypes.KeyGone,
        physIndex: number,
        offset: QuadTypes.Source<number>,
        prev: QuadTypes.SlotItem<Instance>?,
        ud: RowUD?
    ): (any, RowUD?)
        if item == q.KeyGone then
            return nil -- the key left the data: destroy the row
        end
        local data = item :: Item
        if prev and ud then
            -- recycle path: mutate the cached Sources, reuse the Instance
            ud.titleSrc:Set(data.Title)
            ud.scoreSrc:Set(`Score: {data.Score}`)
            ud.orderSrc:Set(physIndex)
            return prev, ud
        end

        local titleSrc = q.Source(data.Title)
        local scoreSrc = q.Source(`Score: {data.Score}`)
        local orderSrc = q.Source(physIndex)

        local row = D.Frame {
            LayoutOrder = orderSrc,
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = Color3.fromRGB(30, 30, 30),

            D.TextLabel {
                Size = UDim2.new(0.7, 0, 1, 0),
                Text = titleSrc,
                TextColor3 = Color3.fromRGB(255, 255, 255),
            },

            D.TextLabel {
                Size = UDim2.new(0.3, 0, 1, 0),
                Position = UDim2.new(0.7, 0, 0, 0),
                Text = scoreSrc,
                TextColor3 = Color3.fromRGB(200, 200, 100),
            },
        }

        return row, { titleSrc = titleSrc, scoreSrc = scoreSrc, orderSrc = orderSrc }
    end, function(item: Item)
        return item.Id -- stable unique key; a duplicate errors with `Slot:List: duplicate key ...`
    end)

    return slot
end
```

The slot is a child, not a container: put it in the array part of a parent element and
its rows mount directly under that Instance.

---

## 3. Studio Prefab Binding (`q.Claim`)

`q.Claim(inst, descriptor)` takes an existing tree into quad ownership and drives it in
one call. The descriptor comes from `D.Mapper`: `M.<Class>(key)(props)`, where `key` is
the child's `Name` and `M.Root` marks the claimed instance itself. `Claim` returns the
same instance. A descriptor value is one-shot — build a fresh one per call.

```luau
local M = D.Mapper

local function BindPlayerCard(
    prefab: Instance,
    playerState: QuadTypes.State<{ Name: string, Level: number }>
)
    local nameText = playerState:Compute(function(self)
        return self:Get().Name
    end)
    local levelText = playerState:Compute(function(self)
        return `Lv. {self:Get().Level}`
    end)

    return q.Claim(prefab, M.Frame(M.Root)({
        M.TextLabel("PlayerName")({ Text = nameText }),
        M.TextLabel("PlayerLevel")({ Text = levelText }),
    }))
end
```

Mapped children accept the same props as `D.*` calls (plain values, States, Modifiers,
events), and freshly built `D.*` children may be mixed into the same array. Claiming an
Instance twice — including anything `D.*` produced — errors with
`nativeClaim: Instance is already claimed by quad`.

---

## 4. Form Validation (Store + trailing `:Compute`)

```luau
local function RegistrationForm()
    local form = q.Store {
        Username = q.Source(""),
        Password = q.Source(""),
    }

    -- one compute node; both deps arrive as State handles
    local isValid = form.Username:Compute(function(self, prev, pwd)
        return #self:Get() >= 3 and #pwd:Get() >= 6
    end, form.Password)

    local submitColor = isValid:Compute(function(self)
        return if self:Get() then Color3.fromRGB(0, 180, 80) else Color3.fromRGB(80, 80, 80)
    end)

    return D.Frame {
        Size = UDim2.fromOffset(300, 200),

        D.TextBox {
            PlaceholderText = "Username (min 3 chars)",
            q.OnChange("Text", function(newText)
                form.Username:Set(newText)
            end),
        },

        D.TextBox {
            PlaceholderText = "Password (min 6 chars)",
            q.OnChange("Text", function(newText)
                form.Password:Set(newText)
            end),
        },

        D.TextButton {
            Text = "Submit",
            BackgroundColor3 = submitColor,
            AutoButtonColor = isValid,
            Activated = function()
                if isValid:Get() then
                    print("Submitting:", form.Username:Get())
                end
            end,
        },
    }
end
```

`q.OnChange(name, fn)` is a descriptor and goes in the **array part**, not as a hash key.
`#pwd` on the raw dep handle would be `0` with no error — always `:Get()` first.

---

## 5. Debounced Search Bar

```luau
local function SearchBar(onSearch: (string) -> ())
    local rawQuery = q.Source("")

    local debouncedQuery: QuadTypes.State<string> = rawQuery:Apply(q.Debounce {
        Time = 0.3,
        MaxTime = 1.2, -- Debounce-only: force a pass after 1.2s of continuous input
    })

    local hasQuery = rawQuery:Compute(function(self)
        return #self:Get() > 0
    end)

    -- the Observer callback receives (targetState, observer, emitFrom) — NOT the value.
    -- A fresh Observer is NOT subscribed: putting it in an array part binds it to that
    -- instance's lifetime (`:Subscribe()` instead, for one not tied to an instance).
    local searchObserver = debouncedQuery:Observer(function(target)
        local text = target:Get()
        if #text > 0 then
            onSearch(text)
        end
    end)

    local inputRef = q.PreRef<<TextBox?>>(nil)   -- strict needs the element type

    return D.Frame {
        Size = UDim2.new(1, 0, 0, 40),
        searchObserver,

        D.TextBox {
            inputRef,
            Size = UDim2.new(1, -40, 1, 0),
            PlaceholderText = "Search items...",
            q.OnChange("Text", function(text)
                rawQuery:Set(text)
            end),
        },

        D.TextButton {
            Size = UDim2.fromOffset(36, 36),
            Position = UDim2.new(1, -38, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            Visible = hasQuery,
            Text = "X",
            Activated = function()
                rawQuery:Set("")
                inputRef:Unwrap().Text = ""
            end,
        },
    }
end
```

`ref:Unwrap()` errors when the Ref is empty; it is the way to strip `nil` from the type
rather than an `if inst then` guard. `:Wait()` always waits for the *next* `:Set`, so it
never returns for an already-filled Ref.

---

## 6. Multi-Store `Context` Propagation

`Context` is an explicit bag handed down through props — there is no tree lookup.
`Context.Provider(name?)` returns an opaque identity; give it an explicit type argument to attach a value type.

```luau
type ThemeStore = QuadTypes.Store<{
    Background: QuadTypes.Source<Color3>,
    Accent: QuadTypes.Source<Color3>,
}>
type InventoryStore = QuadTypes.Store<{ Coins: QuadTypes.Source<number> }>

local ThemeProvider = q.Context.Provider<<ThemeStore>>("Theme")
local InventoryProvider = q.Context.Provider<<InventoryStore>>("Inventory")

local function CoinDisplay(props: { Context: QuadTypes.Context })
    local inventory = props.Context:Get(InventoryProvider) -- errors when unset; :Peek gives nil
    local theme = props.Context:Get(ThemeProvider)

    local coinText = inventory.Coins:Compute(function(self)
        return `Coins: {self:Get()}`
    end)

    return D.TextLabel {
        Text = coinText,
        TextColor3 = theme.Accent,
    }
end

local function RootApp()
    local themeStore = q.Store {
        Background = q.Source(Color3.fromRGB(20, 20, 20)),
        Accent = q.Source(Color3.fromRGB(0, 120, 255)),
    }
    local inventoryStore = q.Store {
        Coins = q.Source(100),
    }

    local ctx = q.Context()
        :Set(ThemeProvider, themeStore)
        :Set(InventoryProvider, inventoryStore)

    return D.ScreenGui {
        ResetOnSpawn = false,
        CoinDisplay { Context = ctx },   -- components are plain functions, not D.* entries
    }
end
```

`ctx:Set(provider, nil)` is rejected — absence is "not set", so drop the key instead.
