--!strict
--[[
	Shared type aliases of the kit. Only `GuiHook` lives here: the class-specific Modifier types
	(`FrameModifier`, `TextButtonModifier`, ...) are the setup module's re-exports (`Quad.luau`), which name the generated
	`<Class>Modifier` types from the quad-roblox package root — use those (`Quad.FrameModifier`), do not derive copies.
]]

local q = require("./Quad")

-- A PostRef filled with the element it is placed on (array part). Interaction's hooks are this type.
export type GuiHook = typeof(q.PostRef(nil :: GuiObject?))

return {}
