--!nocheck
local Quad = require("../../../quad-roblox/luau_packages/quad_base")

local customWidgetNamespace = {
	Button = function(props: any): any
		return props
	end,
}

local function CustomProvider(quad: any)
	quad.Backend.nativeInsert = function(target: any, _offset: number, elements: { any })
		for _, element in elements do
			element.Parent = target
		end
	end
	-- ... 나머지 19개 슬롯 ...

	return {
		Widget = customWidgetNamespace,
	}
end

local q = Quad.New():UseProvider(CustomProvider)
print("installed:", q.Widget.Button({ x = 1 }).x)
print("nativeInsert present:", q.Backend.nativeInsert ~= nil)
