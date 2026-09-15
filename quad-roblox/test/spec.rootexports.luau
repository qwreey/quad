--!strict
--[[
	Generated root re-exports (2026-09-15, public surface (28) provisional) — only the aliases that will
	not change go public for now: `Field<T>`/`FieldOut<T>` (class-independent). Per-class types wait for
	the planned type-function factoring of the generated Declaration module (user).
	Positive only; the body is not executed (spec.modifiertypes convention).
]]

local Quad = require("../luau_packages/quad_base")
local Root = require("../src")

local q = Quad.New():UseProvider(Root.QuadRoblox)

local function _neverCalled()
	local frame = q.Declaration.Modifier.Frame():Visible(true)
	local size: Root.Field<UDim2> = UDim2.new()
	local peeked: Root.FieldOut<UDim2>? = frame:Size(size):Peek<<UDim2>>("Size")
	return peeked
end

print("=== ALL PASS ===")
