--!strict
type Effect = { x: number }
type EffectFnU = ((self: Effect) -> ()) | ((self: Effect) -> (((dying: boolean) -> ())?))
local function take(fn: EffectFnU) end
take(function(self: Effect)
	if self.x > 0 then
		return function(_d: boolean) end
	end
	return nil
end)
take(function(_self: Effect) print("x") end)
take(function(_self: Effect) return end)
take(function(_self: Effect) return function(_d: boolean) end end)
take(function(_self: Effect) return 5 end)
-- current variadic form, for comparison
type EffectFnV = (self: Effect) -> ...((dying: boolean) -> ())
local function takeV(fn: EffectFnV) end
takeV(function(self: Effect)
	if self.x > 0 then
		return function(_d: boolean) end
	end
	return nil
end)
takeV(function(_self: Effect) print("x") end)
