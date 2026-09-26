-- source: references/code-recipes.md:248-299
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
