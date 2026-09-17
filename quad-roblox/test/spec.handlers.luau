--[[
	M5 단위 ③ 계약 — `Handlers/Property.luau`(Reflection 멤버십 매치,
	`Parent`·비프로퍼티 거부) + `Handlers/InstanceChild.luau`(`H-134` 부기
	순서·`H-154` dedup·내림 철거). 정본: dispatch-core `H-134` 블록,
	ROADMAP M5 체크박스 3.

	CLI 실주행 심 셋(전부 의도된 주입면):
	- `getfenv(D.New).Instance` — 생성 D의 lazy 전역(단위 ② spec 선례)
	- `getfenv(Property install 함수).game` — Reflection 심(디스크립터 배열
	  `.Name` 모양은 2026-09-02 Studio 실측 그대로)
	- `q.Backend.isInst` — `H-40`이 "주입 술어"로 만든 그 자리(mock 인식으로 교체)
]]

local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local installProperty = require("../src/Handlers/Property")
local installEvent = require("../src/Handlers/Event") -- M10: 문자열 키는 Event 리플렉션도 지난다
local mock = require("../../quad-base/test/mock")
local Instance = mock.Instance

local SPEC_FILE = "spec.handlers.luau"

-- Reflection 심 — 실측된 디스크립터 모양({ Name = ... } 배열, 상속 포함)
-- 실측 모양 그대로: 쓰기 가능하면 Permits.Write 키 존재, 읽기 전용은 부재.
-- ⭐ "Parent"를 목록에 **넣는다** — 실물 Reflection이 포함하므로(실측),
-- H-142를 지키는 건 오직 핸들러의 `k ~= "Parent"` 가드 한 줄이고 spec은
-- 그 줄의 회귀를 잡아야 한다(리뷰 발견 — 빼두면 멤버십 실패가 가드를 가림).
local W = { Write = "" }
local REFLECTED: { [string]: { any } } = {
	Frame = {
		{ Name = "Name", Permits = W },
		{ Name = "Size", Permits = W },
		{ Name = "BackgroundTransparency", Permits = W },
		{ Name = "Visible", Permits = W },
		{ Name = "ZIndex", Permits = W },
		{ Name = "Parent", Permits = W },
		{ Name = "AbsoluteSize", Permits = {} }, -- 읽기 전용 대조군(H-302)
	},
	TextLabel = {
		{ Name = "Name", Permits = W },
		{ Name = "Text", Permits = W },
		{ Name = "Visible", Permits = W },
	},
}
local reflectionCalls: { [string]: number } = {}
-- 공유 심(mock.gameShim — 리뷰 반영) + 이 spec만의 호출 카운터 래핑(7절)
local counted = setmetatable({}, {
	__index = function(_, className)
		reflectionCalls[className] = (reflectionCalls[className] or 0) + 1
		return REFLECTED[className]
	end,
}) :: any
local gameShim = mock.gameShim(counted)

local q: any = Quad.New():UseProvider(QuadRoblox)
;(getfenv(installProperty) :: any).game = gameShim -- Property 모듈 env에 주입
;(getfenv(installEvent) :: any).game = gameShim -- Event 모듈도 같은 심(이벤트 미선언 → 매치 없음)
;(getfenv(q.Declaration.New) :: any).Instance = { new = mock.Instance.new }
q.Backend.isInst = mock.isMockInstance -- 주입 술어 교체(파일 헤더)
q.errorNamespace.setFuncLevel((require("../luau_packages/quad_types") :: any).ERROR_LEVEL_SURFACE, q.Backend.isInst)

print("=== 1. Property — Reflection 멤버십 매치로 실프로퍼티만 세팅 ===")
do
	local f = q.Declaration.Frame({ Name = "Styled", Size = 42, Visible = true }) :: any
	assert(f.Name == "Styled" and f.Size == 42 and f.Visible == true, "properties assigned through the pipeline")
	print("PASS")
end

print()
print("=== 2. 비프로퍼티 문자열 키·Parent 키 — 매치 핸들러 없음 error(H-142 배선) ===")
do
	local ok, err = pcall(function()
		q.Declaration.Frame({ Bogus = 1 })
	end)
	assert(not ok, "a non-property string key must not silently pass")
	mock.assertBlamesUser(err, SPEC_FILE, "bogus key")

	local f = Instance.new("Frame")
	q.Backend.nativeClaim(f)
	local ok2 = pcall(function()
		q.Dispatch.process(f, "Parent", Instance.new("Frame"), 1)
	end)
	assert(not ok2, "the Parent key must never match any handler (H-142 — 심이 Parent를 포함하므로 이 거부는 가드 한 줄의 몫)")

	-- H-302: 읽기 전용 프로퍼티는 매치 자체가 안 된다(쓰기 표면만)
	local ok3 = pcall(function()
		q.Dispatch.process(f, "AbsoluteSize", 5, 1)
	end)
	assert(not ok3, "read-only properties must not match (H-302 write-permit filter)")
	print("PASS")
end

print()
print("=== 3. InstanceChild — 마운트 + H-134 부기(오프셋 산술이 실제로 선다) ===")
do
	local c1, c2 = Instance.new("TextLabel"), Instance.new("TextLabel")
	q.Backend.nativeClaim(c1); q.Backend.nativeClaim(c2) -- 2026-09-16: static children must be quad-owned (spec 11)
	c1.Name, c2.Name = "A", "B"
	local f = q.Declaration.Frame({ c1, c2 }) :: any
	assert(c1.Parent == f and c2.Parent == f, "both static children mounted")
	assert(q.Bookkeeping.getOffsetAt(f, 1) == 0 and q.Bookkeeping.getOffsetAt(f, 2) == 1, "H-39/H-134: each terminal registered length 1 — offsets 0,1")
	print("PASS")
end

print()
print("=== 4. 교체·철거 — 옛 자식은 내림(파괴 아님), H-154 dedup은 detach를 접는다 ===")
do
	local c1, c3 = Instance.new("TextLabel"), Instance.new("TextLabel")
	q.Backend.nativeClaim(c1); q.Backend.nativeClaim(c3)
	c1.Name, c3.Name = "Old", "New"
	local f = q.Declaration.Frame({ c1 }) :: any

	-- 같은 값 재발행 — dedup: Parent가 nil로 내려가는 전이가 없어야 한다
	local nilTransitions = 0
	c1:GetPropertyChangedSignal("Parent"):Connect(function()
		if c1.Parent == nil then
			nilTransitions += 1
		end
	end)
	q.Dispatch.process(f, 1, c1, 1)
	assert(c1.Parent == f and nilTransitions == 0, "H-154: same-value re-emission never detaches")

	-- 교체 — 옛 자식은 내려가고(살아있음) 새 자식이 그 자리에
	q.Dispatch.process(f, 1, c3, 1)
	assert(c1.Parent == nil and c1.Name == "Old", "old child demoted, NOT destroyed")
	assert(c3.Parent == f, "replacement mounted")
	-- 위치 2의 오프셋(=자리 1의 길이 합)이 살아있는 부기를 실제로 핀한다 —
	-- 위치 1의 0은 부트스트랩 경로라 공허(리뷰 발견)
	assert(q.Bookkeeping.getOffsetAt(f, 2) == 1, "replacement kept length 1 at position 1 (real bookkeeping pin)")

	-- 단순 철거 — retractFrom 경유
	q.Dispatch.retractFrom(f, 1, 1)
	assert(c3.Parent == nil, "plain retraction demotes the child")
	assert(q.Bookkeeping.getOffsetAt(f, 2) == 0, "retract set length 0 (H-134 retract bookkeeping)")
	print("PASS")
end

print()
print("=== 5. 반응형 자식 — State<Instance>가 StoreBind → InstanceChild로 흐른다 ===")
do
	local c1, c2 = Instance.new("TextLabel"), Instance.new("TextLabel")
	q.Backend.nativeClaim(c1); q.Backend.nativeClaim(c2)
	c1.Name, c2.Name = "R1", "R2"
	local src = q.Source(c1)
	local f = q.Declaration.Frame({ src }) :: any
	assert(c1.Parent == f, "reactive child mounted through StoreBind unwrap")
	src:Set(c2)
	assert(c1.Parent == nil and c2.Parent == f, "re-emission demotes old, mounts new")
	print("PASS")
end

print()
print("=== 6. 반응형 프로퍼티(탐사자 🟡-1 승격) — StoreBind(HIGH)>Property(NORMAL)가 load-bearing ===")
do
	-- 이 우선순위가 회귀하면 mock에선 `inst.Size = <State 테이블>`이 조용히
	-- 성공한다(property bag) — 그래서 실값 단언으로 핀한다
	local src = q.Source(10)
	local f = q.Declaration.Frame({ Size = src }) :: any
	assert(f.Size == 10, "reactive property drove the unwrapped value, not the State table")
	src:Set(20)
	assert(f.Size == 20, "re-emission reaches the property")
	-- 평문 전환 — 옛 observer는 죽어서 stale 쓰기가 없어야 한다
	q.Dispatch.process(f, "Size", 5, 1)
	assert(f.Size == 5, "plain value replaces the reactive binding")
	src:Set(30)
	assert(f.Size == 5, "dead store cannot overwrite (old observer retracted)")
	print("PASS")
end

print()
print("=== 7. Reflection 캐시(탐사자 🟡-2a·b 승격) — 클래스당 정확히 1회 + 멤버십 분리 ===")
do
	local before = reflectionCalls.Frame or 0
	q.Declaration.Frame({ Visible = true })
	q.Declaration.Frame({ Visible = false })
	assert((reflectionCalls.Frame or 0) - before <= 1, "GetPropertiesOfClass is cached per class (at most one new call)")
	-- 클래스별 분리 — TextLabel의 Text는 Frame에선 프로퍼티가 아니다
	local ok = pcall(function()
		q.Declaration.Frame({ Text = "nope" })
	end)
	assert(not ok, "membership is per-class (Text is not a Frame property)")
	print("PASS")
end

print()
print("=== 8. 타입 교대(탐사자 🟡-2c·d 승격) — child↔None↔nil에서 형제 오프셋 추적 + StoreBind 경유 dedup ===")
do
	local c1, c2, sib = Instance.new("TextLabel"), Instance.new("TextLabel"), Instance.new("TextLabel")
	q.Backend.nativeClaim(c1); q.Backend.nativeClaim(c2); q.Backend.nativeClaim(sib)
	local src = q.Source(c1 :: any)
	local f = q.Declaration.Frame({ src, sib }) :: any
	assert(c1.Parent == f and q.Bookkeeping.getOffsetAt(f, 2) == 1, "reactive child contributes length 1")

	src:Set(q.None) -- NoneHandler → nil 재귀 → NilHandler(길이 0)
	assert(c1.Parent == nil and q.Bookkeeping.getOffsetAt(f, 2) == 0, "None hands off to NilHandler — sibling offset follows")

	src:Set(c2 :: any)
	assert(c2.Parent == f and q.Bookkeeping.getOffsetAt(f, 2) == 1, "back to a child — offset restored")

	-- StoreBind 경유 같은 값 재발행 — dedup이 재발행 경로에서도 detach를 접는다
	local nilTransitions = 0
	c2:GetPropertyChangedSignal("Parent"):Connect(function()
		if c2.Parent == nil then
			nilTransitions += 1
		end
	end)
	src:Set(c2 :: any)
	assert(c2.Parent == f and nilTransitions == 0, "H-154 dedup holds through the StoreBind re-emission path")

	src:Set(nil :: any) -- 진짜 nil — NilHandler 직행
	assert(c2.Parent == nil and q.Bookkeeping.getOffsetAt(f, 2) == 0, "reactive nil unmounts and zeroes the length")
	print("PASS")
end

print()
print("=== 9. Property nil 쓰기(Q33 (a), 2026-09-08 — M10 skip-defense 역전) — None/nil 재발행은 nil을 쓴다(오브젝트 참조 해제 경로; 못 받는 타입은 엔진이 에러) ===")
do
	local src = q.Source(true)
	local f = q.Declaration.Frame({ Visible = src }) :: any
	assert(f.Visible == true, "initial reactive write")
	-- mock의 프로퍼티 백은 nil 대입을 받아주므로 회귀는 "값이 nil이 됐는가"로 핀한다
	src:Set(q.None) -- NoneHandler → nil 재귀 → Property(키 매치, v == nil)
	assert(f.Visible == nil, "None re-dispatch WRITES nil (release path)")
	src:Set(true)
	src:Set(nil :: any)
	assert(f.Visible == nil, "plain nil writes nil too")
	src:Set(false)
	assert(f.Visible == false, "a real value writes again")
	print("PASS")
end

print()
print("=== 10. Modifier(M7 단위 ②) — D.Frame { mod, … }: flatten이 drive 안에서 돌아 필드가 프로퍼티로 앉는다 ===")
do
	local src = q.Source(3)
	local mod = q.Modifier():Name("FromMod"):ZIndex(src):Visible(false)
	local f = q.Declaration.Frame({ mod, Visible = true }) :: any
	assert(f.Name == "FromMod" and f.ZIndex == 3, "modifier fields landed as properties (State unwrapped)")
	assert(f.Visible == true, "inline key beats the modifier")
	src:Set(4)
	assert(f.ZIndex == 4, "reactive field stays live")
	-- 자식과 섞여도 오프셋 무영향
	local c = Instance.new("TextLabel")
	q.Backend.nativeClaim(c)
	local f2 = q.Declaration.Frame({ q.Modifier():Name("M"), c }) :: any
	assert(c.Parent == f2 and q.Bookkeeping.getOffsetAt(f2, 2) == 0 and f2.Name == "M", "sentinel slot contributes 0; child mounts")
	print("PASS")
end

print()
print()
print("=== 11. 미claim 정적 자식 거부 — Slot 게이트와 대칭(2026-09-16 사용자 결정, question.md §2) ===")
do
	-- quad-roblox specs run the REAL LifetimeHandle over mock instances, so this exercises the
	-- real predicate (gchold setup) — no override needed.
	local foreign, owned = Instance.new("TextLabel"), Instance.new("TextLabel")
	q.Backend.nativeClaim(owned)
	local ok, err = pcall(function() return q.Declaration.Frame({ foreign }) end)
	assert(not ok and string.find(tostring(err), "InstanceChild: this Instance is not claimed by quad", 1, true) ~= nil, "unclaimed static child rejected: " .. tostring(err))
	assert(foreign.Parent == nil, "no bookkeeping/parenting happened before the raise")
	mock.assertBlamesUser(err, "spec.handlers.luau", "static-child gate blames the D.Frame line")
	local f = q.Declaration.Frame({ owned }) :: any
	assert(owned.Parent == f, "claimed child mounts")
	print("PASS")
end

print()
print("=== 12. 정적 자식 소유권 자리(round10 Q48 (a), 2026-09-17 사용자 결정) — Slot과 같은 레지스트리, 한 값은 한 자리 ===")
do
	local c = q.Declaration.TextLabel({}) :: any
	local a = q.Declaration.Frame({ c }) :: any
	assert(c.Parent == a, "first static seat mounts")
	-- (1) a second static seat refuses instead of silently re-parenting
	local ok, err = pcall(function() return q.Declaration.Frame({ c }) end)
	assert(not ok and string.find(tostring(err), "Bookkeeping.claimOwnerAt: this element is already mounted elsewhere", 1, true) ~= nil, "double static mount rejected: " .. tostring(err))
	assert(c.Parent == a, "the first tree keeps its child")
	mock.assertBlamesUser(err, SPEC_FILE, "double-mount raise blames the D.Frame line")
	-- (2) the same child twice in one Declaration
	local c2 = q.Declaration.TextLabel({}) :: any
	local ok2, err2 = pcall(function() return q.Declaration.Frame({ c2, c2 }) end)
	assert(not ok2 and string.find(tostring(err2), "already mounted elsewhere", 1, true) ~= nil, "{c, c} rejected: " .. tostring(err2))
	-- (3) a Slot cannot take a statically seated child, and a static seat cannot take a Slot element
	local ok3, err3 = pcall(function() return q.Slot():Add(c) end)
	assert(not ok3 and string.find(tostring(err3), "Slot:Add: this element is already mounted", 1, true) ~= nil, "Slot refuses a static child: " .. tostring(err3))
	local e = q.Declaration.TextLabel({}) :: any
	local s = q.Slot({ e })
	local ok4, err4 = pcall(function() return q.Declaration.Frame({ e }) end)
	assert(not ok4 and string.find(tostring(err4), "already mounted elsewhere", 1, true) ~= nil, "static seat refuses a Slot element: " .. tostring(err4))
	-- (4) dispose refuses a seated child; after the seat is retracted it is disposable
	local ok5, err5 = pcall(function() q.dispose(c) end)
	assert(not ok5 and string.find(tostring(err5), "dispose: this value is still held by a Slot or a mounted position", 1, true) ~= nil, "dispose refuses a seated static child: " .. tostring(err5))
	-- (c2 stays seated in the half-built Frame above — a raise mid-Declaration leaves the seats
	-- taken so far, as any handler raise does; use a fresh child here)
	local c4 = q.Declaration.TextLabel({}) :: any
	local st = q.Source(c4)
	local b = q.Declaration.Frame({ st }) :: any
	assert(c4.Parent == b, "reactive static seat mounts")
	st:Set(nil)
	assert(c4.Parent == nil, "retracted")
	q.dispose(c4) -- seat released by the retractor — allowed now
	-- (5) `H-154` dedup: re-emitting the same child keeps the seat (no release/reclaim) and stays mounted
	local c3 = q.Declaration.TextLabel({}) :: any
	local st3 = q.Source(c3)
	local p3 = q.Declaration.Frame({ st3 }) :: any
	st3:Set(c3)
	assert(c3.Parent == p3, "same-value re-emit keeps the child mounted")
	local ok6 = pcall(function() return q.Declaration.Frame({ c3 }) end)
	assert(not ok6, "still seated after the dedup re-emit")
	s:Clear()
	q.dispose(e)
	print("PASS")
end

print()
print("=== 13. round10 Q58 (나) (2026-09-17) — quad-roblox 핸들러끼리는 우선순위 동률이 없다(q.debug 설치 시 tie 출력 0): Event·OnChange는 NORMAL - 1 ===")
do
	local printed = {}
	local env = getfenv(q.Dispatch.addHandler) :: any
	local oldPrint = rawget(env, "print")
	env.print = function(...: any) table.insert(printed, table.concat({ ... }, " ")) end
	local q2: any = Quad.New()
	q2.debug = true
	q2:UseProvider(QuadRoblox)
	env.print = oldPrint
	for _, line in printed do
		assert(string.find(line, "priority tie", 1, true) == nil, "tie line printed: " .. line)
	end
	local byName = {}
	for _, h in q2.Dispatch.listHandlers() do byName[h.name] = h.priority end
	assert(byName.Event == byName.Property - 1 and byName.OnChange == byName.InstanceChild - 1, "band offsets")
	print("PASS")
end

print("=== ALL PASS ===")
