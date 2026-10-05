--!strict
--[[
	Material 3 shape scale (corner radii, dp = px): None 0, ExtraSmall 4, Small 8, Medium 12, Large 16,
	ExtraLarge 28, Full (pill / circle). Pure numbers; `Radius.Full` is `nil` on purpose — "full" is not a
	pixel radius, it is "half of the shorter side", which `UICorner` expresses as a scale: use
	`Shape.corner(role)` to get the `UDim` for `UICorner`.

	Note: `UICorner` clamps its radius to half of the shorter side, so any radius larger than the object
	simply renders as a pill/circle — `Full` = `UDim.new(0.5, 0)` is the exact, size-independent form.
]]

export type Role = "None" | "ExtraSmall" | "Small" | "Medium" | "Large" | "ExtraLarge" | "Full"

local Radius: { [Role]: number? } = {
	None = 0,
	ExtraSmall = 4,
	Small = 8,
	Medium = 12,
	Large = 16,
	ExtraLarge = 28,
	Full = nil,
}

local function corner(role: Role): UDim
	local px = Radius[role]
	if px == nil then
		return UDim.new(0.5, 0)
	end
	return UDim.new(0, px)
end

return {
	Radius = Radius,
	corner = corner,
}
