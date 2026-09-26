-- source: references/code-recipes.md:312-354
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
