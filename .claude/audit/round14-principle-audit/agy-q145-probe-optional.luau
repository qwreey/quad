--!strict
type Effect = { x: number }
type EffectFnOpt = (self: Effect) -> (((dying: boolean) -> ())?)
local a: EffectFnOpt = function(self: Effect) -- two branches: cleanup / nil
	if self.x > 0 then
		return function(_d: boolean) end
	end
	return nil
end
local b: EffectFnOpt = function(_self: Effect) -- no return at all
	print("x")
end
local c: EffectFnOpt = function(_self: Effect) -- bare return
	return
end
local d: EffectFnOpt = function(_self: Effect) -- cleanup only
	return function(_d: boolean) end
end
local e: EffectFnOpt = function(_self: Effect) -- wrong: number
	return 5
end
print(a, b, c, d, e)
