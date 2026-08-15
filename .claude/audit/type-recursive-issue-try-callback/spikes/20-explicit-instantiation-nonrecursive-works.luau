--!strict
-- Baseline / positive control: explicit double-angle instantiation
-- (Foo<<T,U>>(...)) on a NON-recursive generic function. This is the
-- formulation `/code-review` flagged as never having been tried in the
-- prior `type-recursive-issue-try-callback/` batch (which only tried
-- implicit-inference calls like `Map(arr, fn)`).
local function Map<T, U>(arr: {T}, fn: (T) -> U): {U}
	local out = {}
	for i, v in arr do
		out[i] = fn(v)
	end
	return out
end

local arr: {number} = {1, 2, 3}

-- explicit instantiation, callback param UNANNOTATED
local result = Map<<number, string>>(arr, function(a)
	local check: number = a  -- a should be inferred as `number`
	return tostring(a)
end)

local ok: string = result[1]      -- should be fine
local wrong: number = result[1]   -- should ERROR (result is {string})
