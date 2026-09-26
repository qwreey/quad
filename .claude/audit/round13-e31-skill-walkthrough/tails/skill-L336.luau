-- mock Instance has no :Clone(); hand the function a stand-in whose Clone returns a fresh mock tree
local tmpl = mock.Instance.new("Frame")
local n = mock.Instance.new("TextLabel"); n.Name = "ItemName"; n.Parent = tmpl
local i = mock.Instance.new("ImageLabel"); i.Name = "Icon"; i.Parent = tmpl
local card = InventoryCard({ Clone = function() return tmpl end }, { Id = "1", Name = "Sword", IconId = "rbxassetid://1" })
local kids = {} for _, c in card:GetChildren() do kids[c.Name] = c end
print("claimed:", card == tmpl, kids.ItemName.Text, kids.Icon.Image, card.BackgroundTransparency)
