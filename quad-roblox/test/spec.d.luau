--[[
	M5 단위 ② 계약 — 생성된 `D`(quad-roblox/src/D/init.luau, gen-d.py 산출물).
	정본: bind-system-plan.md 인스턴스 생성 절(커링·별칭·범위·Parent 제외),
	round14 `H-295`~`H-299`. 실제 Instance 생성(①~④ 파이프라인 실주행)은 CLI에
	Roblox 전역이 없어 못 돈다 — 그 몫은 Studio 스모크(클래스 실생성)와 단위
	⑤(첫 렌더)가 진다. 여기선 산출물의 구조 계약만 고정한다.
]]

local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
-- mock에선 quad를 만들지 않는 헬퍼만 빌린다(사본 혼입 주의 — spec.robloxfactory 헤더)
local mock = require("../../quad-base/test/mock")
local q: any = QuadRoblox(Quad.New())

print("=== 1. D 설치(H-299) — module.D, 별칭 전부 함수, New 포함 ===")
do
	local D = q.D
	assert(type(D) == "table", "factory installs module.D")
	assert(type(D.New) == "function", "generic New is exposed for out-of-scope classes")
	local n = 0
	for name, v in D :: { [string]: any } do
		if name == "Mapper" then
			-- 단위 ④ — 디스크립터 생성기 테이블(Root 센티널 + 클래스별 별칭)
			assert(type(v) == "table" and v.Root ~= nil, "D.Mapper carries Root + aliases")
			for mname, mv in v :: { [string]: any } do
				if mname ~= "Root" then
					assert(type(mv) == "function", "Mapper." .. mname .. " must be an alias")
				end
			end
		else
			assert(type(v) == "function", name .. " must be a function (alias or New)")
		end
		n += 1
	end
	assert(n >= 3, "aliases + New + Mapper exist")
	print(`PASS ({n - 2} aliases + New + Mapper)`)
end

print()
print("=== 2. 범위 관찰 계약 — H-296 (a) 화이트리스트 트리오 존재, defs-드롭 클래스 부재 ===")
do
	local D = q.D
	-- 계층식 몫의 대표들
	for _, name in { "Frame", "TextLabel", "ScreenGui", "SurfaceGui", "UIListLayout", "UICorner", "ViewportFrame" } do
		assert(type(D[name]) == "function", name .. " must be generated (hierarchy rule)")
	end
	-- 명시 화이트리스트 트리오(vide 반례 — ViewportFrame·그룹핑 실수요)
	for _, name in { "Folder", "Camera", "WorldModel" } do
		assert(type(D[name]) == "function", name .. " must be generated (explicit whitelist)")
	end
	-- 핀 defs보다 새로운 클래스는 통째로 드롭된다(api-surface.json dropped가 소스)
	assert(D.InputActionLabel == nil, "defs-gated class must be absent until defs are bumped")
	-- 서비스/비생성 클래스는 범위 밖
	assert(D.Players == nil and D.GuiObject == nil, "services and abstract classes are out of scope")
	-- H-301(실측): Deprecated/NotBrowsable/Internal/capability-gated 클래스 제외
	for _, name in { "GuiMain", "RelativeGui", "AdGui", "TextChannelWindow", "VideoDisplay" } do
		assert(D[name] == nil, name .. " must be excluded (H-301 class-level rules)")
	end
	print("PASS")
end

print()
print("=== 3. 커링 계약 — New(name)은 함수(2단계 호출), 별칭은 이미 1회 적용된 것 ===")
do
	local D = q.D
	local curried = D.New("Frame")
	assert(type(curried) == "function", "New(name) returns the props-taking stage")
	-- 별칭과 커링 결과는 같은 모양(둘 다 props 함수) — 실행은 Roblox 전역 필요라 여기까지
	print("PASS")
end

-- (별칭↔api-surface 1:1 정합과 Parent 부재는 CLI 런타임에서 파일을 못 읽어
--  여기 못 둔다(Luau엔 io가 없음) — 전자는 생성기가 한 루프로 둘을 찍어
--  구조상 보장되고, 후자는 scripts/test.sh의 grep 게이트가 커밋 산출물을 직접 본다.)

print()
print("=== 4. H-238 — D의 함수 전부 SURFACE 태그(리뷰 발견 반영 — 실제 태그 레벨 조회) ===")
do
	local QuadTypes = require("../luau_packages/quad_types")
	local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE
	local D = q.D
	assert(q.errorNamespace.getFuncLevel(D.New) == SURFACE, "New itself must be tagged")
	assert(q.errorNamespace.getFuncLevel(D.Frame) == SURFACE, "aliases must be tagged (stage closures)")
	assert(q.errorNamespace.getFuncLevel(D.UIListLayout) == SURFACE, "every alias, not just Frame")
	-- 범위 밖 클래스의 폴백 경로(H-238의 원 발견 지점) — New(name)이 갓 만든
	-- 스테이지도 태그돼 나와야 blame이 사용자 줄에 닿는다
	assert(q.errorNamespace.getFuncLevel(D.New("SomeOutOfScopeClass")) == SURFACE, "fresh stage from New(name) must be tagged")
	print("PASS")
end

print()
print("=== 5. 파이프라인 CLI e2e(탐사자 관측 반영) — getfenv 주입으로 ①~④ 실주행 ===")
do
	-- 생성 D는 전역 `Instance`를 스테이지 안에서 lazy 참조한다 — CLI엔 그
	-- 전역이 없지만 D 모듈 env에 mock을 주입하면 파이프라인이 실주행된다
	-- (getfenv는 env를 비최적화하지만 테스트 전용이라 무방). 단언은 단위
	-- ③ 이후에도 안정한 것만: ① 생성 + ② nativeClaim까지.
	local D = q.D
	getfenv(D.New :: any).Instance = { new = mock.Instance.new }
	local frame = D.Frame({}) :: any
	assert(mock.isMockInstance(frame) and frame.ClassName == "Frame", "① 물리 생성 완주(mock)")
	local ok, err = pcall(function()
		q.nativeClaim(frame)
	end)
	assert(not ok and string.find(tostring(err), "already claimed", 1, true) ~= nil, "② New가 nativeClaim을 이미 걸었다: " .. tostring(err))
	-- 범위 밖 폴백도 같은 파이프라인
	local part = D.New("Part")({}) :: any
	assert(mock.isMockInstance(part) and part.ClassName == "Part", "범위 밖 New(name)(props)도 완주")
	print("PASS")
end

print()
print("=== ALL PASS ===")
