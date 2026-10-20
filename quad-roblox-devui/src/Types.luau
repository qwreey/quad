--!strict
--[[
	Shared type aliases of the kit. Only `GuiHook` lives here: the Modifier/Spread types (`Modifier<C>`, `ModifierInto<C>`,
	`SpreadInto<C>`, ...) are the setup module's re-exports (`Quad.luau`) of the quad-roblox package root's generic names —
	use those (`Quad.ModifierInto<Frame>`), do not derive copies.
]]

local q = require("./Quad")

-- A PostRef filled with the element it is placed on (array part). Interaction's hooks are this type.
export type GuiHook = typeof(q.PostRef(nil :: GuiObject?))

return {}
