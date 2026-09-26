--!strict
-- Is State:Apply (function-arm, factory: State<T> -> U) subject to the §1 hole
-- like :Compute is, or safe because it returns literal U (typing-limits table row
-- "그대로 반환(-> U): 정상")? q105-check scratch, not repo source.
local Setup = require("./_setup")
local QT = require("../../../../quad-roblox/luau_packages/quad_types")
local q = Setup.q

local count = q.Source(0)

-- factory returns a State<number> (mirrors q.Operator.Sum's shape)
local function Sum(n: number)
	return function(s: QT.State<number>): QT.State<number>
		return s:Compute(function(c: QT.StateData<number>): number
			return c:Get() + n
		end)
	end
end

local unannotated = count:Apply(Sum(10))
local wrong: string = unannotated -- should be a TypeError if Apply is constrained
local wrong2: string = unannotated:Get() -- should be a TypeError if Apply is constrained

print(wrong, wrong2)
