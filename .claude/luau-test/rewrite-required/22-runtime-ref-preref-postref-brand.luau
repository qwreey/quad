--[[
	검증 대상(런타임): `isRef`/`isPreRef`/`isPostRef` predicate 합성이
	`base/ref-plan.md`/`base/brand-plan.md`에 적힌 대로 동작하는지 —
	`isPreRef`/`isPostRef`는 같은 층위의 가장 구체적인 항등(서로
	배타적 형제)이고 `isRef`가 그 위에 얹히는 상위 개념(OR로 합성).
	그리고 `Dispatch/Leaf.luau`의 `(v=Ref)` 매치 핸들러가
	`isRef(v) and not isPreRef(v) and not isPostRef(v)`로 **명시적으로
	좁혀야만** PreRef/PostRef를 잘못 삼키지 않는다는 것.

	**[2026-08-19 신설]** `13-type-ref-preref-subtype.luau`(타입 전용)의
	런타임 절반을 분리 + PostRef까지 확장한 것 — 원본은 PreRef만 다뤘고
	타입/런타임이 한 파일에 있어 A의 더미 스텁이 B의 실행을 막았음
	(`luau-test/STATUS.md` 🟠 항목). PostRef 확장은 ROADMAP의 재작성
	지침("같은 `Ref` 런타임 재사용 + 브랜드 태그만 다른 형제라 A/B 둘 다
	그대로 확장").

	배경: `.claude/base/ref-plan.md`의 "`PostRef`" 절
	("`isPostRef`는 `isPreRef`와 같은 층위의 가장 구체적인 항등 체크이고,
	`isRef`가 그 위에 얹히는 상위 개념 — `Dispatch/Leaf.luau`의 일반 Ref
	매치는 이제 `isRef(v) and not isPreRef(v) and not isPostRef(v)`").

	실행: `luau 22-runtime-ref-preref-postref-brand.luau`
]]

local Brand = {}
local registry = setmetatable({}, { __mode = "k" })
function Brand.set(x, tag)
	registry[x] = tag
end
function Brand.get(x)
	return registry[x]
end

local RefTag, PreRefTag, PostRefTag = {}, {}, {}

local function isPreRef(x)
	return Brand.get(x) == PreRefTag
end
local function isPostRef(x)
	return Brand.get(x) == PostRefTag
end
local function isRef(x)
	-- PreRef/PostRef는 Ref의 하위 개념(둘 다 OR로 얹음), 서로는 배타적 형제
	return isPreRef(x) or isPostRef(x) or Brand.get(x) == RefTag
end

local function makeRef()
	local self = {}
	Brand.set(self, RefTag)
	return self
end
local function makePreRef()
	local self = {}
	Brand.set(self, PreRefTag)
	return self
end
local function makePostRef()
	local self = {}
	Brand.set(self, PostRefTag)
	return self
end

local ref1 = makeRef()
local preref1 = makePreRef()
local postref1 = makePostRef()

print("=== 1. isRef/isPreRef/isPostRef 기본 동작 ===")
print("isRef(ref1) =", isRef(ref1), "(true여야 함)")
print("isPreRef(ref1) =", isPreRef(ref1), "(false — Ref는 PreRef가 아님)")
print("isPostRef(ref1) =", isPostRef(ref1), "(false — Ref는 PostRef가 아님)")
print("isRef(preref1) =", isRef(preref1), "(true — PreRef는 Ref의 하위 개념)")
print("isPreRef(preref1) =", isPreRef(preref1), "(true)")
print("isPostRef(preref1) =", isPostRef(preref1), "(false — PreRef/PostRef는 서로 배타적 형제)")
print("isRef(postref1) =", isRef(postref1), "(true — PostRef도 Ref의 하위 개념)")
print("isPreRef(postref1) =", isPreRef(postref1), "(false — 서로 배타적 형제)")
print("isPostRef(postref1) =", isPostRef(postref1), "(true)")

assert(isRef(ref1) == true)
assert(isPreRef(ref1) == false)
assert(isPostRef(ref1) == false)
assert(isRef(preref1) == true, "PreRef는 isRef를 통과해야 함 (2026-08-09 재정정의 핵심)")
assert(isPreRef(preref1) == true)
assert(isPostRef(preref1) == false, "PreRef/PostRef는 서로 배타적이어야 함")
assert(isRef(postref1) == true, "PostRef도 isRef를 통과해야 함")
assert(isPreRef(postref1) == false, "PreRef/PostRef는 서로 배타적이어야 함")
assert(isPostRef(postref1) == true)

-- Dispatch/Leaf.luau의 (v=Ref) 매치 핸들러 흉내 — PreRef/PostRef를
-- 잘못 삼키면 안 됨(둘 다 자기 전담 핸들러가 따로 처리)
local function leafRefHandlerIsHandlable(v)
	return isRef(v) and not isPreRef(v) and not isPostRef(v)
end

print()
print("=== 2. Leaf의 (v=Ref) 핸들러가 PreRef/PostRef를 잘못 삼키지 않는가 ===")
print("leafRefHandlerIsHandlable(ref1) =", leafRefHandlerIsHandlable(ref1), "(true — 일반 Ref는 처리해야 함)")
print("leafRefHandlerIsHandlable(preref1) =", leafRefHandlerIsHandlable(preref1), "(false — PreRef 전담 핸들러 몫)")
print("leafRefHandlerIsHandlable(postref1) =", leafRefHandlerIsHandlable(postref1), "(false — PostRef 전담 핸들러 몫)")

assert(leafRefHandlerIsHandlable(ref1) == true, "일반 Ref가 Leaf 핸들러에서 거부됨 (버그)")
assert(leafRefHandlerIsHandlable(preref1) == false, "PreRef가 Leaf 핸들러에 잘못 잡힘 (버그)")
assert(leafRefHandlerIsHandlable(postref1) == false, "PostRef가 Leaf 핸들러에 잘못 잡힘 (버그)")

print()
print("모든 assert 통과 — isRef(v) and not isPreRef(v) and not isPostRef(v) 조합이 기대대로 동작함")

--[[
	확인 포인트:
	1. 위 assert가 전부 통과하는가.
	2. `isPreRef(postref1)`/`isPostRef(preref1)`이 둘 다 `false` —
	   PreRef/PostRef가 서로를 오인하지 않는 진짜 배타적 형제인지가 이
	   파일이 13번(PreRef만 다뤘던 원본)보다 새로 넓힌 부분.
]]
