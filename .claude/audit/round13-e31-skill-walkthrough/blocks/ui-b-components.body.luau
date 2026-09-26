-- E31 walkthrough (b): two components — props, a Slot of children, Modifier factories.
-- GAP-1: SKILL's typed boundary names `DeclarationModule.IntoTextButton`, but the prologue never binds
-- DeclarationModule and the only public path (pesde install) is the quad-roblox ROOT re-export.
local QuadRobloxModule = require("../../../quad-roblox/src")

-- Modifier factories (GAP-3: SKILL shows Modifiers but not the "function returning a Modifier" pattern)
local function Rounded(transparency: number): QuadRobloxModule.GuiObjectModifier
    return D.Modifier.GuiObject():BackgroundTransparency(transparency):Visible(true)
end
local function Highlight(active: QuadTypes.State<boolean>): QuadRobloxModule.FrameModifier
    local bg = active:Compute(function(self)
        return if self:Get() then Color3.fromRGB(255, 200, 0) else Color3.fromRGB(40, 40, 40)
    end)
    return D.Modifier.Frame():BackgroundColor3(bg)
end

export type ButtonProps = { -- §3.1
    Text: string | QuadTypes.State<string>,
    OnClick: (inputObject: InputObject, clickCount: number) -> (),
    Modifier: QuadRobloxModule.TextButtonModifier?, -- IntoTextButton? (SKILL §3.1) fails strict here — see ui-b0
}
local function Button(props: ButtonProps)
    return D.TextButton {
        Text = props.Text,
        AutoButtonColor = true,
        Activated = props.OnClick,
        props.Modifier or q.None,
    }
end

-- GAP-4: SKILL says "a component returns an Instance or a Slot" and "Slot goes in the array part",
-- but never shows a component RECEIVING children; this is my guess (props.Children: Slot).
export type CardProps = {
    Title: string | QuadTypes.State<string>,
    Modifier: QuadRobloxModule.FrameModifier?,
    Children: QuadTypes.Slot<Instance>?,
}
local function Card(props: CardProps)
    return D.Frame {
        Name = "Card",
        BackgroundTransparency = 0, -- inline: must win over every Modifier (§3.2 tier 1)
        props.Modifier or q.None,
        D.TextLabel { Name = "Title", Text = props.Title },
        props.Children or q.None,
    }
end

local active = q.Source(false)
local clicks = q.Source(0)
local label = clicks:Compute(function(self)
    return `clicked {self:Get()}`
end)
local card = Card {
    Title = "Hello",
    Modifier = q.Modifier.Overridden(Rounded(0.5), Highlight(active)),
    Children = q.Slot<<Instance>>({
        D.TextLabel { Name = "Body", Text = label },
        Button {
            Text = "Go",
            OnClick = function()
                clicks:Set(clicks:Get() + 1)
                active:Set(not active:Get())
            end,
            Modifier = D.Modifier.TextButton():Text("from-mod"),
        },
    }),
}
print(card)
