--!strict
-- E15 (e) — how-to 03 §4 VirtualList verbatim + §5 Throttle swap + Blocker, and how-to 05 theme tokens used in rows.
local q = require("./round13-e15-probe-types-settings")
local D = q.Declaration
local ROW = 50
local BUFFER = 3

local isDark = q.Source(true)
type ColorPalette = { Background: Color3, Accent: Color3 }
local LIGHT: ColorPalette = { Background = Color3.fromRGB(248, 249, 250), Accent = Color3.fromRGB(13, 110, 253) }
local DARK: ColorPalette = { Background = Color3.fromRGB(18, 18, 18), Accent = Color3.fromRGB(66, 153, 225) }
local palette = isDark:Compute(function(dark)
    return if dark:Get() then DARK else LIGHT
end)
local function token(key: string)
    return palette
        :Apply(q.Operator.Indexed<<Color3>>(key))
        :Apply(q.Animate({
            Time = 0.25,
            Style = Enum.EasingStyle.Quad,
            Direction = Enum.EasingDirection.Out,
        }))
end
local Tokens = { Background = token("Background"), Accent = token("Accent") }

local function VirtualList(props: { Items: { { id: string, label: string } } })
    local items = props.Items
    local scrollY = q.Source(0)
    local viewportHeight = q.Source(600)
    local gatedScrollY = scrollY:Apply(q.Throttle { Time = 0.1 })
    local blocker = q.Blocker()

    local window = gatedScrollY:Compute(function(y, _previous, height)
        local first = math.floor(y:Get() / ROW) + 1
        local count = math.ceil(height:Get() / ROW) + 1
        local startIndex = math.max(1, first - BUFFER)
        local endIndex = math.min(#items, first + count + BUFFER)
        local slice = {}
        for i = startIndex, endIndex do
            table.insert(slice, { item = items[i], absIndex = i })
        end
        return slice
    end, viewportHeight):Apply(blocker)

    local rows = q.Slot<<Instance>>():List(window, function(ctx: any): (any, any)
        local entry, prev, ud = ctx.Item, ctx.Prev, ctx.UserData
        if entry == q.KeyGone then
            return nil, ud
        end
        if prev then
            if ud.abs:Get() ~= entry.absIndex then
                ud.abs:Set(entry.absIndex)
            end
            return prev, ud
        end
        local abs = q.Source(entry.absIndex)
        local position: q.State<UDim2> = abs:Compute(function(a)
            return UDim2.new(0, 0, 0, (a:Get() - 1) * ROW)
        end)
        local row = D.Frame {
            Size = UDim2.new(1, 0, 0, ROW),
            Position = position,
            BackgroundColor3 = Tokens.Background,
            q.OnDestroyed(function() print("row gone") end),
            D.TextLabel {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = Tokens.Accent,
                Text = entry.item.label,
            },
        }
        return row, { abs = abs }
    end, function(entry)
        return entry.item.id
    end)

    return D.ScrollingFrame {
        Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.new(0, 0, 0, #items * ROW),
        ScrollBarThickness = 6,
        q.OnChange("CanvasPosition", function(pos: Vector2)
            scrollY:Set(pos.Y)
        end),
        q.OnChange("AbsoluteWindowSize", function(size: Vector2)
            viewportHeight:Set(size.Y)
        end),
        rows,
    }, blocker
end

local list, blocker = VirtualList { Items = { { id = "a", label = "A" } } }
blocker:On()
isDark:Set(false)
blocker:Off()
local _ = list
