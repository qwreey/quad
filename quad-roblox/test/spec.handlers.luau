--[[
	M5 단위 ③ 계약 — `Handlers/Property.luau`(Reflection 멤버십 매치,
	`Parent`·비프로퍼티 거부) + `Handlers/InstanceChild.luau`(`H-134` 부기
	순서·`H-154` dedup·내림 철거). 정본: dispatch-core `H-134` 블록,
	ROADMAP M5 체크박스 3.

	CLI 실주행 심 셋(전부 의도된 주입면):
	- `getfenv(D.New).Instance` — 생성 D의 lazy 전역(단위 ② spec 선례)
	- `getfenv(Property install 함수).game` — Reflection 심(디스크립터 배열
	  `.Name` 모양은 2026-09-02 Studio 실측 그대로)
	- `q.isInst` — `H-40`이 "주입 술어"로 만든 그 자리(mock 인식으로 교체)
]]

local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local installProperty = require("../src/Handlers/Property")
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
local gameShim = {
	GetService = function(_self: any, name: string): any
		assert(name == "ReflectionService", "only ReflectionService is shimmed")
		return {
			GetPropertiesOfClass = function(_s: any, className: string): { any }
				return REFLECTED[className] or {}
			end,
		}
	end,
}

local q: any = QuadRoblox(Quad.New())
;(getfenv(installProperty) :: any).game = gameShim -- Property 모듈 env에 주입
;(getfenv(q.D.New) :: any).Instance = { new = mock.Instance.new }
q.isInst = mock.isMockInstance -- 주입 술어 교체(파일 헤더)
q.errorNamespace.setFuncLevel(q.isInst, (require("../luau_packages/quad_types") :: any).ERROR_LEVEL_SURFACE)

print("=== 1. Property — Reflection 멤버십 매치로 실프로퍼티만 세팅 ===")
do
	local f = q.D.Frame({ Name = "Styled", Size = 42, Visible = true }) :: any
	assert(f.Name == "Styled" and f.Size == 42 and f.Visible == true, "properties assigned through the pipeline")
	print("PASS")
end

print()
print("=== 2. 비프로퍼티 문자열 키·Parent 키 — 매치 핸들러 없음 error(H-142 배선) ===")
do
	local ok, err = pcall(function()
		q.D.Frame({ Bogus = 1 })
	end)
	assert(not ok, "a non-property string key must not silently pass")
	mock.assertBlamesUser(err, SPEC_FILE, "bogus key")

	local f = Instance.new("Frame")
	q.nativeClaim(f)
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
	c1.Name, c2.Name = "A", "B"
	local f = q.D.Frame({ c1, c2 }) :: any
	assert(c1.Parent == f and c2.Parent == f, "both static children mounted")
	assert(q.Dispatch.getOffsetAt(f, 1) == 0 and q.Dispatch.getOffsetAt(f, 2) == 1, "H-39/H-134: each terminal registered length 1 — offsets 0,1")
	print("PASS")
end

print()
print("=== 4. 교체·철거 — 옛 자식은 내림(파괴 아님), H-154 dedup은 detach를 접는다 ===")
do
	local c1, c3 = Instance.new("TextLabel"), Instance.new("TextLabel")
	c1.Name, c3.Name = "Old", "New"
	local f = q.D.Frame({ c1 }) :: any

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
	assert(q.Dispatch.getOffsetAt(f, 2) == 1, "replacement kept length 1 at position 1 (real bookkeeping pin)")

	-- 단순 철거 — retractFrom 경유
	q.Dispatch.retractFrom(f, 1, 1)
	assert(c3.Parent == nil, "plain retraction demotes the child")
	assert(q.Dispatch.getOffsetAt(f, 2) == 0, "retract set length 0 (H-134 retract bookkeeping)")
	print("PASS")
end

print()
print("=== 5. 반응형 자식 — State<Instance>가 StoreBind → InstanceChild로 흐른다 ===")
do
	local c1, c2 = Instance.new("TextLabel"), Instance.new("TextLabel")
	c1.Name, c2.Name = "R1", "R2"
	local src = q.Source(c1)
	local f = q.D.Frame({ src }) :: any
	assert(c1.Parent == f, "reactive child mounted through StoreBind unwrap")
	src:Set(c2)
	assert(c1.Parent == nil and c2.Parent == f, "re-emission demotes old, mounts new")
	print("PASS")
end

print()
print("=== ALL PASS ===")
