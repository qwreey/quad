--!strict
--[[
	Demo context — the shared state every demo section reads. One instance per DemoWindow; the Sources here are what
	"input fields bound to a shared Source shown elsewhere" means in the sections (Inputs writes them, Basic / Plots /
	RuntimeInfo read them).
]]

local Devui = require("./Kit")
local q = require("../Quad")

type Source<T> = q.Source<T>

export type Context = {
	Style: Devui.Style,
	Overlay: Devui.Overlay,
	-- shared values
	Counter: Source<number>,
	Name: Source<string>,
	Volume: Source<number>,
	Tint: Source<Color3>,
}

local Context = {}

function Context.new(style: Devui.Style?, overlay: Devui.Overlay?): Context
	return {
		Style = style or Devui.Style.default,
		Overlay = overlay or Devui.Overlay.getDefault(),
		Counter = q.Source(0),
		Name = q.Source("quad"),
		Volume = q.Source(40),
		Tint = q.Source(Color3.fromRGB(66, 150, 250)),
	}
end

return Context
