local template = script.Parent:WaitForChild("ItemCard")
local clicks = q.Source(0)
local clickText: q.State<string> = clicks:Compute(function(c)
    return `클릭 횟수: {c:Get()}`
end)

q.Claim(template, M.Frame(M.Root)({
    M.TextLabel("ItemName")({ Text = "검" }),
    M.ImageLabel("ItemIcon")({ Image = "rbxassetid://1" }),
    M.TextButton("ActionButton")({
        Text = clickText,
        Activated = function()
            clicks:Set(clicks:Get() + 1)
        end,
    }),
    Visible = true,
}))
