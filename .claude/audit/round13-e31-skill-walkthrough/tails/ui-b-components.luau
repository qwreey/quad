local kids = {}
for _, c in card:GetChildren() do table.insert(kids, c.Name .. ":" .. c.ClassName) end
print("children (physical):", table.concat(kids, ", "))
print("BackgroundTransparency inline wins:", card.BackgroundTransparency, "Visible from mod:", card.Visible)
print("bg (inactive):", card.BackgroundColor3.R)
local btn
for _, c in card:GetChildren() do if c.ClassName == "TextButton" then btn = c end end
print("inline Text beats modifier Text:", btn.Text)
btn.Activated:Fire("input", 1)
local body; for _, c in card:GetChildren() do if c.Name == "Body" then body = c end end
print("after click:", body.Text, "bg:", card.BackgroundColor3.R)
