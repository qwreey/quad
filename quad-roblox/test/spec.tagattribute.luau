--!nocheck
--[[
	M10 엔진 축(2026-09-03) — quad-roblox `EngineOps.luau`의 Tag/Attr op
	셋(`addTag`/`removeTag`/`setAttr`)이 base 핸들러(`Tag.luau`/
	`Attr/Key.luau`/`Attr/init.luau`)의 호출 계약대로 엔진에 닿는가.
	정본: `dispatch-core-plan.md` "base가 소유하는 핸들러와 주입되는 엔진 op",
	`tag-plan.md`(배치 `{string}`·깜빡임 방지), `attribute-plan.md`(nil = 삭제,
	클로저는 setAttr를 안 부른다).

	CLI 실주행 심(spec.handlers 관용구): `getfenv(EngineOps install).game`에
	mock의 `gameShim` — CollectionService 네 멤버가 mock 인스턴스의 태그 저장소
	위에서 돈다. Attr는 mock 인스턴스의 `SetAttribute`/`GetAttribute` 그대로.
	실물 CollectionService/SetAttribute 회귀는 Studio 실측
	(`audit/m10-engine-axis-studio-2026-09-03.md`).
]]

local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local installEngineOps = require("../src/EngineOps")
local mock = require("../../quad-base/test/mock")
local Instance = mock.Instance

local SPEC_FILE = "spec.tagattribute.luau"

;(getfenv(installEngineOps) :: any).game = mock.gameShim({})

local function newQuad()
	return Quad.New():UseProvider(QuadRoblox)
end

local function tagsOf(inst)
	return table.concat(mock.getTags(inst), ",")
end

print("=== 1. 설치 — 프로바이더가 세 op을 심는다(스텁 아님), H-238 태깅 ===")
do
	local q = newQuad()
	local bare = Quad.New()
	assert(q.addTag ~= bare.addTag and q.removeTag ~= bare.removeTag and q.setAttr ~= bare.setAttr, "ops replaced the base stubs")
	local ok, err = pcall(function()
		bare.addTag(Instance.new("Frame"), { "a" })
	end)
	assert(not ok and string.find(tostring(err), "addTag is not available", 1, true), "bare module still guides: " .. tostring(err))
	print("PASS")
end

print()
print("=== 2. Tag — 배치 addTag / 깜빡임 없는 diff / nil로 전량 제거 (CollectionService 경유) ===")
do
	local q = newQuad()
	local inst = Instance.new("Frame")
	q.nativeClaim(inst) -- 실물 생명주기 계약: 미claim 루트는 bindLifetime이 거부
	local src = q.Source(q.Tag("a", "b"))
	q.Dispatch.drive(inst, { src })
	assert(tagsOf(inst) == "a,b", "initial tags via CollectionService:AddTag: " .. tagsOf(inst))
	src:Set(q.Tag("b", "c"))
	assert(tagsOf(inst) == "b,c", "diffed to b,c: " .. tagsOf(inst))
	src:Set(nil)
	assert(tagsOf(inst) == "", "all removed: " .. tagsOf(inst))
	print("PASS")
end

print()
print("=== 3. Attr — 단일 키·그룹·반응형 값·nil 삭제 (inst:SetAttribute 경유) ===")
do
	local q = newQuad()
	local inst = Instance.new("Frame")
	q.nativeClaim(inst)
	local hp = q.Source(5)
	q.Dispatch.drive(inst, { [q.AttrKey("Hp")] = hp, [q.AttrKey("Title")] = "quad" })
	assert(inst:GetAttribute("Hp") == 5 and inst:GetAttribute("Title") == "quad", "single keys written")
	hp:Set(9)
	assert(inst:GetAttribute("Hp") == 9, "reactive value follows: " .. tostring(inst:GetAttribute("Hp")))
	hp:Set(nil)
	assert(inst:GetAttribute("Hp") == nil, "nil deletes the attribute")

	local inst2 = Instance.new("Frame")
	q.nativeClaim(inst2)
	q.Dispatch.drive(inst2, { q.Attr({ Level = 3, Name = "x" }) })
	assert(inst2:GetAttribute("Level") == 3 and inst2:GetAttribute("Name") == "x", "group written through the single-key path")
	print("PASS")
end

print()
print("=== 4. 실물 계약 경계 — 태그 이름은 문자열만 (CollectionService가 거부하는 값은 base 검증이 먼저 막는다) ===")
do
	local q = newQuad()
	local ok, err = pcall(function() q.Tag(42) end)
	assert(not ok, "non-string tag name rejected at the constructor")
	mock.assertBlamesUser(err, SPEC_FILE, "Tag constructor blame")
	print("PASS")
end

print()
print("=== ALL PASS ===")
