--!nocheck
local H = require("./harness")
local q, D = H.q, H.D
UDim2 = H.EG.UDim2
UDim = H.EG.UDim
Color3 = H.EG.Color3
task = H.task

local toasts = q.Source({})

local toastList = q.Slot()
toastList:List(toasts, function(ctx)
	if ctx.Item == q.KeyGone then
		return nil, ctx.UserData
	end
	if ctx.Prev then
		return ctx.Prev, ctx.UserData
	end
	local toast = ctx.Item
	return D.TextLabel {
		Text = toast.Text,
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = Color3.fromRGB(40, 40, 48),
	}, ctx.UserData
end, function(item)
	return item.Id
end)

local nextToastId = 0

local function pushToast(text)
	nextToastId += 1
	local id = nextToastId

	local next = table.clone(toasts:Get())
	table.insert(next, { Id = id, Text = text })
	toasts:Set(next)

	task.delay(3, function()
		local kept = {}
		for _, item in toasts:Get() do
			if item.Id ~= id then
				table.insert(kept, item)
			end
		end
		toasts:Set(kept)
	end)
end

local toastHost = D.Frame {
	D.UIListLayout { Padding = UDim.new(0, 4) },
	toastList,
}

print("children before push:", #toastHost:GetChildren())
pushToast("첫 토스트")
pushToast("둘째 토스트")
print("children after 2 pushes (UIListLayout + 2 labels = 3):", #toastHost:GetChildren())
for _, c in toastHost:GetChildren() do
	if c.ClassName == "TextLabel" then print(" label text:", c.Text) end
end

H.runTask(3)
print("children after 3s (toasts expire, UIListLayout only = 1):", #toastHost:GetChildren())
