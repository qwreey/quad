--[[
	Store 계약 — `.claude/base/store-plan.md` "Store = Source들의 이름 붙은 모음 (명시적 초기화)" /
	"타입 추론 문제 — `store.key`(dot-access)를 1급 경로로 확정" / "`store.key` 레코드 필드 타이핑".
	`H-122`(isSource 화이트리스트) / `H-153`(예약 이름 런타임 가드, 그림자 = store 자신) / `H-83`(무인자).
]]

local Quad = require("../src")
local QuadTypes = require("../luau_packages/quad_types")

type Source<T> = QuadTypes.Source<T>
type State<T> = QuadTypes.State<T>

local Source, Store = Quad.Source, Quad.Store

print("=== 1. 명시적 초기화 — store.key는 넣은 Source 그 자체, 평범한 레코드 필드 ===")
do
	local hp, name = Source(100), Source("x")
	local s = Store({ hp = hp, name = name })
	assert(s.hp == hp and s.name == name, "fields are the very Sources passed in")
	assert(rawget(s, "hp") == hp, "shadow = the store itself (H-153)")
	assert(Quad.isStore(s) and not Quad.isSource(s), "brand")
	local v: number = s.hp:Get()
	assert(v == 100, "typed dot-access")
	s.hp:Set(5)
	assert(hp:Get() == 5, "Set goes to the same Source")
	-- 무주석 콜백 파라미터 추론이 사는 선언 스타일(§1②) — analyze가 지킨다
	local doubled: State<number> = s.hp:Compute(function(x)
		return x:Get() * 2
	end)
	assert(doubled:Get() == 10, "Compute through a store field")
	print("PASS")
end

print()
print("=== 2. defaults 검증 (H-122) — isSource 화이트리스트, level 2, 영어 ===")
do
	local ok, err = pcall(function()
		Store({ hp = 100 } :: any)
	end)
	assert(not ok and string.find(tostring(err), "not a Source", 1, true) ~= nil, "raw value rejected: " .. tostring(err))
	assert(string.find(tostring(err), "spec.store.luau", 1, true) ~= nil, "level 2 points at the caller")
	local ok2 = pcall(function()
		Store({ ok = Source(1), bad = Quad.Ref(1) } :: any)
	end)
	assert(not ok2, "a Ref is not a Source")
	-- H-204: the bag itself is validated before clone — a non-table used to die
	-- inside table.clone, a bare Source got an error naming a Source-internal field.
	local ok3, err3 = pcall(function()
		Store(5 :: any)
	end)
	assert(not ok3 and string.find(tostring(err3), "must be a table", 1, true) ~= nil, "non-table defaults: " .. tostring(err3))
	assert(string.find(tostring(err3), "spec.store.luau", 1, true) ~= nil, "level 2 points at the caller")
	local ok4, err4 = pcall(function()
		Store(Source(100) :: any)
	end)
	assert(not ok4 and string.find(tostring(err4), "plain table", 1, true) ~= nil, "bare Source as defaults: " .. tostring(err4))
	local ok5 = pcall(function()
		Store(setmetatable({}, { __metatable = "locked" }) :: any)
	end)
	assert(not ok5, "protected metatable rejected before clone")
	print("PASS")
end

print()
print("=== 3. 예약 이름 (H-153) — 생성자 순회와 Of 둘 다 error(level 2) ===")
do
	for _, name in { "Of", "Names", "__reservedCheck" } do
		local ok, err = pcall(function()
			Store({ [name] = Source(1) } :: any)
		end)
		assert(not ok and string.find(tostring(err), "reserved", 1, true) ~= nil, name .. " in defaults: " .. tostring(err))
		local s = Store({} :: {})
		local ok2, err2 = pcall(function()
			s:Of(name)
		end)
		assert(not ok2 and string.find(tostring(err2), "reserved", 1, true) ~= nil, name .. " via Of: " .. tostring(err2))
		assert(string.find(tostring(err2), "spec.store.luau", 1, true) ~= nil, "level 2")
	end
	-- H-201: Of exists for computed names, so a computed nil/number must error
	-- here (nil used to allocate a Source then die at an internal frame; a number
	-- silently broke `Names(): { string }`).
	local s = Store({} :: {})
	local okNil, errNil = pcall(function()
		s:Of(nil :: any)
	end)
	assert(not okNil and string.find(tostring(errNil), "Of name must be a string", 1, true) ~= nil, "nil Of name: " .. tostring(errNil))
	assert(string.find(tostring(errNil), "spec.store.luau", 1, true) ~= nil, "level 2 points at the caller")
	local okNum, errNum = pcall(function()
		s:Of(123 :: any)
	end)
	assert(not okNum and string.find(tostring(errNum), "Of name must be a string", 1, true) ~= nil, "number Of name: " .. tostring(errNum))
	assert(#s:Names() == 0, "nothing was allocated by the rejected names")
	print("PASS")
end

print()
print("=== 4. :Of — 없는 이름은 그 자리에서 만들어 저장(lazy가 남는 유일한 자리), 있으면 그것 ===")
do
	local s = Store({ hp = Source(1) })
	local dyn: Source<boolean> = s:Of<<boolean>>("dyn")
	assert(Quad.isSource(dyn) and dyn:Get() == nil, "created as Source(nil)")
	assert(s:Of("dyn") == dyn, "same name → same Source")
	assert(rawget(s, "dyn") == dyn, "stored on the store itself")
	assert(s:Of("hp") == s.hp, "declared keys are reachable through Of too")
	print("PASS")
end

print()
print("=== 5. :Names — defaults 키 + Of가 만든 키, 메소드는 안 셈, 팬텀 필드도 없음 ===")
do
	local s = Store({ hp = Source(1), name = Source("n") })
	local function set(list: { string }): { [string]: true }
		local t = {}
		for _, k in list do
			t[k] = true
		end
		return t
	end
	local names = set(s:Names())
	assert(names.hp and names.name and not names.Of and not names.Names and not names.__reservedCheck, "declared keys only")
	assert(#s:Names() == 2, "count")
	s:Of("dyn")
	assert(set(s:Names()).dyn == true and #s:Names() == 3, "Of adds to Names")
	assert(rawget(s, "__reservedCheck") == nil, "phantom field has no runtime counterpart")
	print("PASS")
end

print()
print("=== 6. 빈 Store (H-83/H-157) — 무인자도 유효 ===")
do
	local e = Store({} :: {})
	assert(#e:Names() == 0, "no names")
	local d: Source<number> = e:Of("x")
	assert(Quad.isSource(d), "Of works on an empty store")
	local e2 = (Quad.Store :: any)()
	assert(Quad.isStore(e2) and #e2:Names() == 0, "no-arg form (or {} guard)")
	print("PASS")
end

print()
print("=== 7. 인스턴스별 팩토리 (H-174) — Of가 자기 quad의 Source를 만든다 ===")
do
	local other = Quad.New()
	local s = other.Store({} :: {})
	local d = s:Of("x")
	assert(getmetatable(d :: any) == getmetatable(other.Source(0) :: any), "Of uses the module's own Source, read at call time")
	assert(getmetatable(d :: any) ~= getmetatable(Quad.Source(0) :: any), "not the top-level instance's")
	print("PASS")
end

print()
print("=== ALL PASS ===")
