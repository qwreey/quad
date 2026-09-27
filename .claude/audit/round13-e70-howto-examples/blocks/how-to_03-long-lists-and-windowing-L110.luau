local ROW = 50
local BUFFER = 3

local function VirtualList(props: { Items: { { id: string, label: string } } })
    local items = props.Items
    local scrollY = q.Source(0)
    local viewportHeight = q.Source(600)

    -- 보이는 구간을 반응형으로 잘라낸다(후행 의존성: fn(self, previous, ...deps))
    local window = scrollY:Compute(function(y, _previous, height)
        local first = math.floor(y:Get() / ROW) + 1
        local count = math.ceil(height:Get() / ROW) + 1
        local startIndex = math.max(1, first - BUFFER)
        local endIndex = math.min(#items, first + count + BUFFER)
        local slice = {}
        for i = startIndex, endIndex do
            table.insert(slice, { item = items[i], absIndex = i })
        end
        return slice
    end, viewportHeight)

    local rows = q.Slot<<Instance>>():List(window, function(ctx: any): (any, any)
        local entry, prev, ud = ctx.Item, ctx.Prev, ctx.UserData
        if entry == q.KeyGone then
            return nil, ud
        end
        if prev then
            -- 화면에 남아 있는 행: 절대 위치만 갱신하고 Instance는 재활용
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
            BackgroundTransparency = 1,

            D.TextLabel {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = entry.item.label,
            },
        }
        return row, { abs = abs }
    end, function(entry)
        return entry.item.id
    end) -- 생성자의 제네릭은 추론되지 않는다 — `q.Slot<<Instance>>()`처럼 명시 타입 인자로 준다

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
    }
end
