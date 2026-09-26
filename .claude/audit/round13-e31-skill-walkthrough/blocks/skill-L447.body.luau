-- source: SKILL.md:447-461
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
