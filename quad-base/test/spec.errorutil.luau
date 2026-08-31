--[[
	quad-error contract — the user's experiment file assertions, kept as a
	standing spec (round12 `H-231`; design/API are the user's own).
	Level tags are layer numbers; errorAt blames the line *inside* the
	outermost frame tagged with the layer, errorBefore blames that frame's
	caller. Untagged functions are layer 0; no match falls back to the raise
	site. The tag map is weak-keyed.
]]

local QuadError = require("../luau_packages/quad_error")

-- 네임스페이스 형태(사용자 결정 — 사본 분리 문제): 유틸은 상태 없는 생성자,
-- 태그 맵은 네임스페이스 인스턴스에 산다. 여기선 자체 네임스페이스로 계약만 검증.
local Err = QuadError.new()

-- strict 모드에서 `collectgarbage`는 선언 안 된 전역 — 표준 luau CLI엔 있다(Roblox엔 없음)
local collectgarbage = (_G :: any).collectgarbage :: () -> ()

-- 호출한 자리의 현재 줄 번호
local function curline(): number
	return (debug.info(2, "l") :: any) :: number
end

local function assertBlames(err: any, wantLine: number, wantMsg: string)
	local msg = tostring(err)
	assert(
		string.find(msg, `:{wantLine}: {wantMsg}`, 1, true) ~= nil,
		`error should blame line {wantLine}: got "{msg}"`
	)
end

print("=== 1. errorAt — 태그된 프레임 **안**의 줄을 blame ===")
do
	local raiseLine = 0
	local callLine = 0
	local function inner()
		raiseLine = curline() + 1
		Err.errorAt("boom-inner", 4)
	end
	Err.setFuncLevel(inner, 4)
	local function outer()
		callLine = curline() + 1
		inner()
	end
	Err.setFuncLevel(outer, 3)

	local ok, err = pcall(outer)
	assert(not ok, "errorAt raises")
	assertBlames(err, raiseLine, "boom-inner") -- 레이어 4(=inner) 안의 errorAt 호출 줄

	local ok2, err2 = pcall(outer)
	assert(not ok2, "second raise still errors")
	local _ = err2
	-- 레이어 3(=outer)을 겨냥하면 outer 안(inner를 부른 줄)이 blame
	local function inner3()
		Err.errorAt("boom-outer", 3)
	end
	Err.setFuncLevel(inner3, 4)
	local function outer3()
		callLine = curline() + 1
		inner3()
	end
	Err.setFuncLevel(outer3, 3)
	local ok3, err3 = pcall(outer3)
	assert(not ok3, "outer-layer target raises")
	assertBlames(err3, callLine, "boom-outer")
	print("PASS")
end

print()
print("=== 2. errorBefore — 태그된 프레임의 **호출부**를 blame ===")
do
	local function inner()
		Err.errorBefore("boom-before", 3)
	end
	Err.setFuncLevel(inner, 4)
	local function outer()
		inner()
	end
	Err.setFuncLevel(outer, 3)

	local callSite = 0
	local ok, err = pcall(function()
		callSite = curline() + 1
		outer()
	end)
	assert(not ok, "errorBefore raises")
	assertBlames(err, callSite, "boom-before") -- outer(레이어 3)를 부른 줄
	print("PASS")
end

print()
print("=== 3. 최상단부터 스캔 — 같은 태그가 겹치면 **바깥쪽**이 이긴다(샌드위치에 강건) ===")
do
	local outerCall = 0
	local function deep()
		Err.errorAt("boom-outermost", 7)
	end
	local function mid()
		deep()
	end
	-- mid는 태그 안 함(익명 중간 클로저 흉내) — 그래도 스캔이 끊기지 않는다
	local function entry()
		outerCall = curline() + 1
		mid()
	end
	Err.setFuncLevel(deep, 7)
	Err.setFuncLevel(entry, 7) -- 같은 레이어 태그가 안팎에 둘 — 바깥(entry)이 매치
	local ok, err = pcall(entry)
	assert(not ok, "sandwiched raise still errors")
	assertBlames(err, outerCall, "boom-outermost") -- entry 안의 줄(= 바깥 매치)
	print("PASS")
end

print()
print("=== 4. 무태그 기본 — 매치 없으면 raise 자리로 폴백, 등록 안 된 함수는 level 0 ===")
do
	assert(Err.getFuncLevel(function() end) == QuadError.ERROR_LEVEL_DEFAULT, "untagged -> ERROR_LEVEL_DEFAULT (0)")
	local ok, err = pcall(function()
		Err.errorAt("boom-nomatch", 99)
	end)
	assert(not ok, "no matching layer still raises")
	assert(string.find(tostring(err), "boom-nomatch", 1, true) ~= nil, "message survives the fallback")
	print("PASS")
end

print()
print("=== 5. 태그 맵은 weak — 죽은 함수의 태그가 맵을 붙잡지 않는다 ===")
do
	local probe: { [number]: any } = setmetatable({}, { __mode = "v" }) :: any
	-- 팩토리 경유 + 업밸류 캡처 — (a) 무업밸류 클로저는 프로토에 캐싱돼 안 죽고,
	-- (b) 같은 프레임에서 인라인 생성하면 죽은 레지스터가 붙잡아 GC 관측이 안 된다
	-- (둘 다 이 spec을 쓰며 실측 — mock의 `false or` 관용구와 같은 계열)
	local function makeTagged(): any
		local upvalue = {}
		local fn = function()
			return upvalue
		end
		Err.setFuncLevel(fn, 5)
		assert(Err.getFuncLevel(fn) == 5, "tag readable while alive")
		return fn
	end
	probe[1] = makeTagged()
	collectgarbage()
	collectgarbage()
	assert(probe[1] == nil, "tagging must not pin the function (weak-key map)")
	print("PASS")
end

print()
print("=== ALL PASS ===")
