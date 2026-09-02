--[[
	M5 단위 ④ 계약 — `Claim` + `D.Mapper`(정본: `claim-plan.md` §2~§7 —
	DFS 해석·bottom-up drive·배열 슬롯 교체·1회용 디스크립터·이중 claim
	error·루트 센티널·New 자식 혼입). CLI 실주행은 mock 트리 위 —
	`nativeFindChild`(실물 op, `inst:FindFirstChild`)가 mock에도 그대로
	먹는다(덕 타이핑). 주입면은 spec.handlers와 동일 셋.
]]

local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local installProperty = require("../src/Handlers/Property")
local mock = require("../../quad-base/test/mock")
local Instance = mock.Instance

local W = { Write = "" }
local REFLECTED: { [string]: { any } } = {
	Frame = { { Name = "Name", Permits = W }, { Name = "BackgroundTransparency", Permits = W } },
	TextLabel = { { Name = "Name", Permits = W }, { Name = "Text", Permits = W } },
}
local gameShim = mock.gameShim(REFLECTED)

local q: any = Quad.New():UseProvider(QuadRoblox)
;(getfenv(installProperty) :: any).game = gameShim
;(getfenv(q.D.New) :: any).Instance = { new = mock.Instance.new }
q.isInst = mock.isMockInstance

-- "이미 있는 트리" — Studio/Clone 사본의 mock 대역
local function makeTemplate()
	local root = Instance.new("Frame")
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Parent = root
	local list = Instance.new("Frame")
	list.Name = "List"
	list.Parent = root
	local inner = Instance.new("TextLabel")
	inner.Name = "Inner"
	inner.Parent = list
	return root, title, list, inner
end

local M = q.D.Mapper

print("=== 1. 기본 Claim — 소유 + 매핑 자식 props 적용 + 배열 슬롯 교체·부기 ===")
do
	local root, title = makeTemplate()
	local out = q.Claim(root, M.Frame(M.Root)({
		M.TextLabel("Title")({ Text = "Hello" }),
		BackgroundTransparency = 0.25,
	}))
	assert(out == root, "Claim returns the same inst (<T> passthrough)")
	assert(title.Text == "Hello", "mapped child got its props driven")
	assert(root.BackgroundTransparency == 0.25, "root props driven too")
	-- 소유 실증: 재claim은 nativeClaim의 셋업-유무 판정으로 error(§7-10)
	local ok = pcall(function()
		q.nativeClaim(root)
	end)
	assert(not ok, "root is now quad-owned (double claim errors)")
	local ok2 = pcall(function()
		q.nativeClaim(title)
	end)
	assert(not ok2, "resolved children are claimed as well")
	-- 배기 부기: 매핑 자식이 정적 자식으로 부기됨(위치 2의 오프셋 = 자리 1 길이)
	assert(q.Dispatch.getOffsetAt(root, 2) == 1, "resolved child registered length 1 via InstanceChildHandler")
	print("PASS")
end

print()
print("=== 2. 중첩 매핑 — DFS bottom-up, 안쪽 먼저 drive ===")
do
	local root, _, list, inner = makeTemplate()
	q.Claim(root, M.Frame(M.Root)({
		M.Frame("List")({
			M.TextLabel("Inner")({ Text = "deep" }),
		}),
	}))
	assert(inner.Text == "deep", "nested mapped child driven")
	local ok = pcall(function()
		q.nativeClaim(list)
	end)
	assert(not ok, "intermediate mapped inst claimed")
	print("PASS")
end

print()
print("=== 3. 1회용 디스크립터 — 재사용은 error(PreRef _fired 관용구) ===")
do
	local rootA = select(1, makeTemplate())
	local rootB = select(1, makeTemplate())
	local desc = M.Frame(M.Root)({})
	q.Claim(rootA, desc)
	local ok, err = pcall(function()
		q.Claim(rootB, desc)
	end)
	assert(not ok and string.find(tostring(err), "one%-shot") ~= nil, "descriptor reuse must error: " .. tostring(err))
	mock.assertBlamesUser(err, "spec.claim.luau", "reuse")
	print("PASS")
end

print()
print("=== 4. 인자 검증 — 디스크립터가 아니면 즉시 error ===")
do
	local root = select(1, makeTemplate())
	local ok, err = pcall(function()
		q.Claim(root, { not_a_descriptor = true })
	end)
	assert(not ok, "non-descriptor must be rejected")
	mock.assertBlamesUser(err, "spec.claim.luau", "bad desc")
	print("PASS")
end

print()
print("=== 5. New 자식 혼입(§7-3) — 매핑과 생성이 한 배열에 ===")
do
	local root, title = makeTemplate()
	local made = q.D.TextLabel({ Text = "fresh" })
	q.Claim(root, M.Frame(M.Root)({
		M.TextLabel("Title")({ Text = "mapped" }),
		made,
	}))
	assert(title.Text == "mapped" and made.Parent == root, "mapped + freshly-made children coexist")
	assert(q.Dispatch.getOffsetAt(root, 3) == 2, "both positions bookkept (lengths 1+1)")

	-- H-304: None 채움(관용구) 뒤의 디스크립터도 해석된다 — drive 동형 순회
	local root2, title2 = makeTemplate()
	q.Claim(root2, M.Frame(M.Root)({
		q.None, -- 조건부 자리의 관용구(`or None`)
		M.TextLabel("Title")({ Text = "after-none" }),
	}))
	assert(title2.Text == "after-none", "descriptor after a None filler is still resolved (H-304)")
	print("PASS")
end

print()
print("=== 6. 반응형 — claim된 트리에서 store-bind가 그대로 돈다 ===")
do
	local root, title = makeTemplate()
	local src = q.Source("a")
	q.Claim(root, M.Frame(M.Root)({
		M.TextLabel("Title")({ Text = src }),
	}))
	assert(title.Text == "a", "reactive prop drove on claim")
	src:Set("b")
	assert(title.Text == "b", "re-emission reaches the claimed tree (owned like a New-made one)")
	print("PASS")
end

print()
print("=== 7. 탐사자 승격 — New 배열의 디스크립터 no-match / Claim 표면 이중 claim / 깊이 2 반응형+혼입 ===")
do
	-- §2 load-bearing: New children엔 MapperDescriptor가 오면 안 되고, 오면 no-match
	local ok, err = pcall(function()
		q.D.Frame({ M.TextLabel("X")({}) })
	end)
	assert(not ok and string.find(tostring(err), "no handler matched", 1, true) ~= nil, "descriptor in New children must hit no-match: " .. tostring(err))

	-- Claim 표면 경유의 이중 claim(New-made inst)
	local made = q.D.Frame({})
	local ok2, err2 = pcall(function()
		q.Claim(made, M.Frame(M.Root)({}))
	end)
	assert(not ok2 and string.find(tostring(err2), "already claimed", 1, true) ~= nil, "claiming a New-made inst errors through the Claim surface")
	mock.assertBlamesUser(err2, "spec.claim.luau", "double claim via Claim")

	-- 깊이 2 매핑 자식의 반응형 + New 혼입 동시(탐사 스파이크 A 승격)
	local root, _, list, inner = makeTemplate()
	local src = q.Source("d2")
	local made2 = q.D.TextLabel({ Text = "mixed" })
	q.Claim(root, M.Frame(M.Root)({
		M.Frame("List")({
			M.TextLabel("Inner")({ Text = src }),
			made2,
		}),
	}))
	assert(inner.Text == "d2" and made2.Parent == list, "depth-2 reactive + New mix drove")
	src:Set("d2b")
	assert(inner.Text == "d2b", "depth-2 re-emission reaches the claimed subtree")
	assert(q.Dispatch.getOffsetAt(list, 3) == 2, "mapped(1) + made(1) bookkept at depth 2")
	print("PASS")
end

print()
print("=== ALL PASS ===")
