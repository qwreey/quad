--!nocheck
--[[
	Spread (3.4.0, `.claude/research/release-3.4.0-plan.md` 단위 3) — `q.Raw.Spread` and its `drive` pre-pass.
	Canon: `.claude/research/component-flatten-sugar-plan.md` 5절 (2026-10-16 + 2026-10-20 Add·CRUD):
	one level deep (Spreads met in the constructor / `:Append` are flattened there), "the first one in place
	wins" (inline keys are the first layer, then Spreads in order; Modifiers only fill what is left), array
	values append at the Spread's position, a Spread is locked once placed or spread, `:Append` takes only a
	Spread and returns nothing, `q.debug` reports a function value dropped by an earlier Spread.
]]

local QuadTypes = require("../luau_packages/quad_types")
local mock = require("./mock")
local SpreadModule = require("../src/Dispatch/Spread")

local q = mock.newQuad()
local Instance = mock.Instance
local Spread = q.Raw.Spread
local Modifier = q.Raw.Modifier
local None = q.None
local StateKey = SpreadModule._StateKey

local function keysOf(s: any): { [any]: any }
	return s[StateKey].keys
end
local function arrayOf(s: any): { any }
	return s[StateKey].array
end
local function expectError(f: () -> (), code: string, label: string)
	local ok, err = pcall(f)
	assert(not ok, label .. ": expected " .. code)
	assert(string.find(tostring(err), code, 1, true) ~= nil, label .. ": wrong error " .. tostring(err))
	mock.assertBlamesUser(err, "spec.spread.luau", label)
end
-- a hash handler that records what each key received, and the spec leaf for array values
local hashLog: { [string]: any } = {}
local sources = {}
local leafLog: { string } = {}
mock.addSpecLeaf(q, sources, leafLog)
q.Dispatch.addHandler({
	name = "SpecHash",
	isHandlable = function(_inst, k, _v)
		return type(k) == "string"
	end,
	priority = q.Dispatch.HANDLER_PRIORITY_LOW,
	process = function(_inst, k, v, _index)
		hashLog[k] = v
		return q.Void
	end,
} :: QuadTypes.Handler)

print("=== 1. 생성 — 인라인 키가 첫 층, 안쪽 Spread는 그 자리에서 펴지고(깊이 1) 잠긴다, 먼저 자리 잡은 것이 이긴다 ===")
do
	local inner1 = Spread { A = "inner1", B = "inner1", "x" }
	local inner2 = Spread { B = "inner2", C = "inner2", "y" }
	local s = Spread { A = "direct", "first", inner1, "mid", inner2, "last" }
	local k = keysOf(s)
	assert(k.A == "direct", "an inline key beats every nested Spread")
	assert(k.B == "inner1", "the earlier nested Spread wins over the later one")
	assert(k.C == "inner2", "a key only the later Spread has is still filled")
	assert(table.concat(arrayOf(s), ",") == "first,x,mid,y,last", "array values in place: " .. table.concat(arrayOf(s), ","))
	assert(inner1[StateKey].locked and inner2[StateKey].locked, "nested Spreads are locked (they were copied)")
	assert(not s[StateKey].locked, "the new Spread itself is not locked")
	assert(s.__quadSpread == true and tostring(s) == "Spread", "runtime tag is `true` (the class lives in the type)")
	print("PASS")
end

print()
print("=== 2. :Append — Spread만 받고 반환 없음, 더한 쪽은 빈 키만 채움(먼저가 이김), 배열은 뒤에, 인자는 잠김 ===")
do
	local s = Spread { A = "direct", "a" }
	local add1 = Spread { A = "add1", B = "add1", "b" }
	local add2 = Spread { B = "add2", "c" }
	local r = table.pack(s:Append(add1))
	assert(r.n == 0, ":Append returns nothing")
	s:Append(add2)
	local k = keysOf(s)
	assert(k.A == "direct" and k.B == "add1", "first one in place wins across Appends")
	assert(table.concat(arrayOf(s), ",") == "a,b,c", "array values append in order")
	assert(add1[StateKey].locked and add2[StateKey].locked, "an appended Spread is locked")
	expectError(function()
		add1:Append(Spread {})
	end, "Quad0275", "a locked Spread refuses :Append")
	expectError(function()
		s:Append(s)
	end, "Quad0275", "a Spread cannot be appended to itself")
	expectError(function()
		s:Append({ X = 1 })
	end, "Quad0276", ":Append takes a Spread, not a plain table")
	expectError(function()
		s:Append(Modifier():X(1))
	end, "Quad0276", ":Append takes a Spread, not a Modifier")
	print("PASS")
end

print()
print("=== 3. drive — 인라인 > 앞 Spread > 뒤 Spread > Modifier, 배열 값은 Spread 자리에, 놓이면 잠김(다시 놓기는 됨) ===")
do
	table.clear(hashLog)
	table.clear(leafLog)
	local s1 = Spread { Size = "s1", Text = "s1", Color = "s1", "s1a", "s1b" }
	local s2 = Spread { Text = "s2", Color = "s2", Name = "s2" }
	local mod = Modifier():Color("mod"):Name("mod"):Rotation("mod")
	local inst = Instance.new("Frame")
	q.Dispatch.drive(inst, { "lead", s1, mod, s2, "tail", Size = "inline" })
	assert(hashLog.Size == "inline", "inline beats the Spreads")
	assert(hashLog.Text == "s1", "the earlier Spread beats the later one")
	assert(hashLog.Color == "s1", "a Spread beats a Modifier")
	assert(hashLog.Name == "s2", "a later Spread still beats a Modifier")
	assert(hashLog.Rotation == "mod", "the Modifier fills what no Spread set")
	assert(q.Bookkeeping.getOffsetAt(inst, 2) == 1, "lead at slot 1; the Spread's array values took its place")
	assert(q.Bookkeeping.getOffsetAt(inst, 4) == 3, "s1a and s1b follow lead in order")
	assert(s1[StateKey].locked and s2[StateKey].locked, "placed Spreads are locked")
	-- a locked Spread can be placed again (reuse is not refused by the Spread itself)
	table.clear(hashLog)
	q.Dispatch.drive(Instance.new("Frame"), { s2 })
	assert(hashLog.Name == "s2", "a locked Spread is still readable / placeable")
	expectError(function()
		s1:Append(Spread {})
	end, "Quad0275", ":Append after placement")
	-- a Modifier inside a Spread goes to the Modifier stage at the Spread's position
	table.clear(hashLog)
	q.Dispatch.drive(Instance.new("Frame"), { Spread { Modifier():Size("inner mod") }, Size = None })
	assert(hashLog.Size == nil, "inline None still wins over the Modifier carried by the Spread")
	table.clear(hashLog)
	q.Dispatch.drive(Instance.new("Frame"), { Spread { Modifier():Size("inner mod") } })
	assert(hashLog.Size == "inner mod", "a Modifier carried by a Spread is flattened like one written in place")
	print("PASS")
end

print()
print("=== 4. 자리 에러 — 평범한 테이블만, 문자 키 자리의 Spread는 생성·drive 양쪽에서 거부(사용자 줄 blame) ===")
do
	expectError(function()
		Spread(nil)
	end, "Quad0273", "Spread(nil)")
	expectError(function()
		Spread(Modifier():X(1))
	end, "Quad0273", "Spread(a Modifier)")
	expectError(function()
		Spread { Hooks = Spread {} }
	end, "Quad0274", "a Spread at a key in the constructor")
	expectError(function()
		q.Dispatch.drive(Instance.new("Frame"), { Hooks = Spread {} })
	end, "Quad0277", "a Spread at a key in an element")
	print("PASS")
end

print()
print("=== 5. q.debug — 앞 Spread에 밀려난 함수 값만 한 줄(직접 쓴 키에 덮인 것·함수 아닌 값은 0줄, debug 꺼지면 0줄) ===")
do
	local env: any = getfenv(SpreadModule.expand)
	local lines: { string } = {}
	local function capture(f: () -> ())
		table.clear(lines)
		local old = rawget(env, "print")
		env.print = function(...: any)
			table.insert(lines, table.concat({ ... }, " "))
		end
		local ok, err = pcall(f)
		env.print = old
		assert(ok, tostring(err))
	end
	local fa, fb = function() end, function() end
	q.debug = true
	capture(function()
		q.Dispatch.drive(Instance.new("Frame"), { Spread { Leave = fa }, Spread { Leave = fb } })
	end)
	assert(#lines == 1 and string.find(lines[1], 'key "Leave"', 1, true) ~= nil, "one line for the dropped handler: " .. table.concat(lines, " | "))
	capture(function()
		q.Dispatch.drive(Instance.new("Frame"), { Spread { Leave = fb }, Leave = fa })
	end)
	assert(#lines == 0, "an inline key overriding a Spread's handler is explicit — silent")
	capture(function()
		q.Dispatch.drive(Instance.new("Frame"), { Spread { Size = 1 }, Spread { Size = 2 } })
	end)
	assert(#lines == 0, "non-function values are not reported")
	local built = Spread { Spread { Leave = fa } }
	built:Append(Spread { Leave = fb })
	capture(function()
		q.Dispatch.drive(Instance.new("Frame"), { built })
	end)
	assert(#lines == 1 and string.find(lines[1], "while building", 1, true) ~= nil, "a drop inside the Spread is reported when it is placed: " .. table.concat(lines, " | "))
	q.debug = false
	capture(function()
		q.Dispatch.drive(Instance.new("Frame"), { Spread { Leave = fa }, Spread { Leave = fb } })
	end)
	assert(#lines == 0, "debug off: silent")
	print("PASS")
end

print()
print("=== 6. 스텁 — q.Elem 등 백엔드 계약 이름은 프로바이더 전엔 Quad0108, q.NewModule·q.Raw.Mapper가 있다 ===")
do
	local bare = require("../src").NewModule()
	for _, name in { "Elem", "Modifier", "Spread", "Mapper", "OnChange", "OnEvent", "Out", "ForClasses" } do
		local ok, err = pcall(function()
			bare[name]("Frame")
		end)
		assert(not ok and string.find(tostring(err), "Quad0108", 1, true) ~= nil and string.find(tostring(err), name, 1, true) ~= nil, name .. " stub: " .. tostring(err))
	end
	assert(type(bare.NewModule) == "function" and bare.NewModule ~= nil, "q.NewModule")
	assert(type(bare.Raw.Mapper) == "function" and (bare :: any).newMapperClass == nil, "q.Raw.Mapper is the mapper class factory (q.newMapperClass is gone)")
	assert(getmetatable(bare.Raw.Modifier) ~= nil and bare.Raw.Modifier.TypedFactory ~= nil, "q.Raw.Modifier is base's Modifier constructor")
	assert((bare :: any).New == nil, "q.New is gone (q.NewModule)")
	print("PASS")
end

print()
print("ALL PASS")
