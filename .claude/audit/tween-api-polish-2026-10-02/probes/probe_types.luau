--!strict
local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local q = Quad.New():UseProvider(QuadRoblox)

local function _t()
	-- T1: Animate on a number State fed into a UDim2 slot — is the mismatch caught?
	local n = q.Source(0)
	local _f1 = q.Declaration.Frame({ Size = n:Apply(q.Animate({ Time = 0.3 })) })
	-- T2: the same mismatch without Animate (control: must be caught)
	local _f2 = q.Declaration.Frame({ Size = n })
	-- T3: Tween value of the wrong type directly (control)
	local _f3 = q.Declaration.Frame({ Size = q.Tween({ Value = 5 }) })
	-- T4: callback value param inferred? (should be number)
	local _t4 = q.Tween({ Value = 5, Completed = function(_inst, _prop, v)
		local s: string = v -- expect an error if v: number
	end })
	-- T5: Animate callbacks are TweenCallback<any> — value is any
	local _a5 = q.Animate({ Completed = function(_inst, _prop, v)
		local s: string = v -- any: no error expected
	end })
	-- T6: Override typo
	local _t6 = q.Tween({ Value = 5, Override = "finish" })
	-- T7: Animate with an option typo key (Duration) — strict catches?
	local _a7 = q.Animate({ Duration = 0.3 })
	-- T8: Tween with an unknown key
	local _t8 = q.Tween({ Value = 5, Duration = 0.3 })
end
return nil
