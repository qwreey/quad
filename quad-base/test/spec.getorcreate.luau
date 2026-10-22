--[[
	`q:GetOrCreate(key, build)` / `q:AssertProvider(name, versionPattern)` — the two surfaces for consumers that
	are not providers (component kits as factories of q). Contract: research/kit-packaging-plan.md 3.7
	(user decisions 2026-10-22): the cache lives in the instance (strong key, strong value — gone with it), a
	build that asks for its own key errors, a build that threw can be retried, nil is not a cacheable result;
	the assert compares the provider's declared `Backend.provider` record (name + version pattern), not the
	provider function.
]]

local Quad = require("../src")
-- strict mode does not declare `collectgarbage` — the standard luau CLI has it (Roblox does not)
local collectgarbage = (_G :: any).collectgarbage :: () -> ()

local function throws(fn: () -> (), needle: string)
	local ok, err = pcall(fn)
	assert(not ok, "expected an error containing " .. needle)
	assert(string.find(tostring(err), needle, 1, true), tostring(err))
end

print("=== 1. GetOrCreate — the first call builds with q, later calls return the same value ===")
do
	local q = Quad.NewModule()
	local runs = 0
	local seen: any = nil
	local function build(m)
		runs += 1
		seen = m
		return { n = runs }
	end
	local a = q:GetOrCreate(build, build)
	local b = q:GetOrCreate(build, build)
	assert(a == b and runs == 1, "same key -> same value, build ran once")
	assert(seen == q, "build receives the instance")
	-- any value is a key: a string key is a separate entry even with the same build
	local c = q:GetOrCreate("kit_7", build)
	assert(c ~= a and runs == 2 and q:GetOrCreate("kit_7", build) == c, "string key")
	-- another instance has its own cache
	local other = Quad.NewModule()
	assert(other:GetOrCreate(build, build) ~= a and runs == 3, "per instance")
	print("PASS")
end

print()
print("=== 2. GetOrCreate — a build asking for its own key errors; a build that threw can be retried ===")
do
	local q = Quad.NewModule()
	local function loop(m): any
		return m:GetOrCreate(loop, loop)
	end
	throws(function()
		q:GetOrCreate(loop, loop)
	end, "Quad0284")
	-- after the cycle error the key is not stuck: a later build for it runs
	assert(q:GetOrCreate(loop, function()
		return "ok"
	end) == "ok", "the cycle left no mark")

	local fail = true
	local function flaky(): any
		if fail then
			error("boom")
		end
		return { ok = true }
	end
	throws(function()
		q:GetOrCreate(flaky, flaky)
	end, "boom")
	fail = false
	assert(q:GetOrCreate(flaky, flaky).ok, "retried after the throw")
	print("PASS")
end

print()
print("=== 3. GetOrCreate — entry gates and nil results ===")
do
	local q = Quad.NewModule()
	throws(function()
		q:GetOrCreate(nil, function()
			return 1
		end)
	end, "Quad0282")
	throws(function()
		q:GetOrCreate("k", 5 :: any)
	end, "Quad0283")
	throws(function()
		q:GetOrCreate("nil", function(): any
			return nil
		end)
	end, "Quad0285")
	print("PASS")
end

print()
print("=== 4. GetOrCreate — the cached value holding q does not keep q alive ===")
do
	local weak = setmetatable({}, { __mode = "v" }) :: { q: any }
	local function build(m)
		return {
			back = function()
				return m
			end,
		}
	end
	do
		local q = Quad.NewModule()
		weak.q = q
		q:GetOrCreate(build, build)
	end
	for _ = 1, 5 do
		collectgarbage()
	end
	assert(weak.q == nil, "the instance was collected with its cache")
	print("PASS")
end

print()
print("=== 5. AssertProvider — passes on the declared name + matching version, throws otherwise ===")
do
	local q = Quad.NewModule()
	throws(function()
		q:AssertProvider("fake", "1.*.*")
	end, "Quad0287")
	local function FakeProvider(m: any)
		m.Backend.provider = table.freeze({ name = "fake", version = "1.2.0" })
		return {}
	end
	q:UseProvider(FakeProvider)
	q:AssertProvider("fake", "1.2^.0^")
	q:AssertProvider("fake", "0.*.*|1.*.*")
	throws(function()
		q:AssertProvider("quad-roblox", "1.*.*")
	end, "Quad0288")
	throws(function()
		q:AssertProvider("fake", "1.3^.0^")
	end, "Quad0289")
	throws(function()
		q:AssertProvider("fake", 1 :: any)
	end, "Quad0286")
	print("PASS")
end
