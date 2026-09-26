-- source: SKILL.md:336-348
local M = D.Mapper

local function InventoryCard(template: Instance, itemData: { Id: string, Name: string, IconId: string })
    local card = template:Clone()

    return q.Claim(card, M.Frame(M.Root)({
        M.TextLabel("ItemName")({ Text = itemData.Name }),
        M.ImageLabel("Icon")({ Image = itemData.IconId }),
        BackgroundTransparency = 0.25,          -- props of the claimed root
    }))
end
