--!strict
local q = require("./s10-config")
local D = q.Declaration

type Toast = { Id: number, Text: string }

local toasts = q.Source<<{ Toast }>>({})

local toastList = q.Slot<<Instance>>()
toastList:List(toasts, function(ctx)
	if ctx.Item == q.KeyGone then
		return nil, ctx.UserData
	end
	if ctx.Prev then
		return ctx.Prev, ctx.UserData
	end
	local toast = ctx.Item :: Toast
	return D.TextLabel {
		Text = toast.Text,
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = Color3.fromRGB(40, 40, 48),
	}, ctx.UserData
end, function(item)
	return item.Id
end)

local nextToastId = 0

local function pushToast(text: string)
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
print(toastHost, pushToast)
