-- source: references/code-recipes.md:162-181
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
