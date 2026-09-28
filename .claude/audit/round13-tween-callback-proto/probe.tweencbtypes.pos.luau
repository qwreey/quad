--!strict
-- PROTO probe (round13 tween-callback-structure §8-1): strict POSITIVES — expect 0 diagnostics
local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local Types = require("../src/types")
local q = Quad.New():UseProvider(QuadRoblox)

local function _pos()
	-- P1 zero-arg callbacks (the 2026-09-21 shape) still fit
	local t0 = q.Tween({ Value = 90, Time = 0.2, Started = function() end, Completed = function() end, Cancelled = function() end })
	-- P2 three-arg callbacks, value typed by T
	local t3 = q.Tween({ Value = 90, Time = 0.2, Completed = function(inst: Instance, prop: string, value: number)
		local _a, _b, _c = inst.Name, prop:upper(), value + 1
	end })
	-- P3 three-arg callbacks, unannotated (inferred)
	local t3u = q.Tween({ Value = UDim2.new(), Completed = function(inst, prop, value)
		local _a, _b, _c = inst, prop, value
	end })
	-- P4 Wrapped with identity Map
	local w: Types.Tween<number> = t3:Wrapped(function(cb)
		return cb:Map(function(f)
			return f
		end)
	end)
	-- P5 Wrapped returning an explicit set (drop Started, keep Completed)
	local w2 = t0:Wrapped(function(cb)
		return { Completed = cb.Completed }
	end)
	-- P6 Mapped(fn, wrap) — value number -> UDim, callbacks rewired
	local m: Types.Tween<UDim> = t3:Mapped(function(v: number): UDim
		return UDim.new(0, v)
	end, function(cb)
		return cb:Map(function(f)
			return function(inst: Instance, prop: string, _value: UDim)
				f(inst, prop, 1)
			end
		end)
	end)
	-- P7 Mapped(fn) still one-arg
	local m1: Types.Tween<number> = t3:Mapped(function(v: number): number return v * 2 end)
	-- P8 results still fit Declaration slots
	local f = q.Declaration.Frame({ Rotation = w, BackgroundTransparency = m1, Size = t3u })
	local c = q.Declaration.UICorner({ CornerRadius = m })
	return t0, w2, f, c
end
return _pos
