--!strict
--[[
	검증 대상: 컴포넌트 경계에서 props.Modifier/props.Ref를 "or None"으로
	감싸 넘기는 필수 관용구가 실제로 nil-hole 문제를 막아주는지, 그리고
	`export type Params = {...}`로 타입 체크되는 컴포넌트 하나가 실제
	Luau에서 문제없이 짜이는지.

	배경: ROADMAP.md M0 5번째 항목, .claude/base/component-composition-plan.md
	"필수 관용구" 절, .claude/research/pre-implementation-audit.md 1-5.

	두 가지 방법으로 확인 필요함:
	1. 런타임 동작(nil-hole 재현) 확인: `luau 06-component-boundary-nil-hole-props.luau`
	2. 타입 체크(Params 타입, Modifier/Ref 타입 흉내) 확인:
	   `luau-analyze 06-component-boundary-nil-hole-props.luau`
	   (luau-analyze가 로컬에 없으면 Luau 공식 릴리즈 CLI 툴체인 필요 —
	   https://github.com/luau-lang/luau/releases, 또는 lune/rojo 배포판)
]]

local None = setmetatable({}, { __tostring = function()
	return "<None>"
end }) :: any

-- Modifier/Ref를 아주 얇게 흉내낸 타입(실제 구현 API 모양과 다를 수 있음,
-- 여기선 오직 "props.Modifier or None" 패턴의 타입/런타임 동작만 검증)
type FakeModifier = { isModifier: true }
type FakeRef = { isRef: true }

export type Params = {
	Modifier: FakeModifier?,
	Ref: FakeRef?,
	Text: string,
}

local function MyComponent(props: Params)
	-- 핵심 관용구 — 이게 없으면 아래 "BAD" 케이스처럼 nil-hole이 생김
	local children = {
		props.Modifier or None,
		props.Ref or None,
		props.Text,
		"fixed-child-1",
		"fixed-child-2",
	}
	return children
end

print("=== BAD: or None 없이 raw로 꽂았을 때 ===")
local badProps: Params = { Text = "hello" } -- Modifier/Ref 둘 다 안 넘김
local badChildren = { badProps.Modifier, badProps.Ref, badProps.Text, "fixed-child-1", "fixed-child-2" }
print("bad #t =", #badChildren, "(정의된 대로면 5, 하지만 앞쪽 nil-hole 때문에 불안정할 수 있음)")
for i, v in badChildren do
	print("  bad[" .. tostring(i) .. "] =", tostring(v))
end

print()
print("=== GOOD: or None 관용구 사용 ===")
local goodChildren = MyComponent(badProps)
print("good #t =", #goodChildren, "(항상 5여야 함)")
for i = 1, #goodChildren do
	print("  good[" .. tostring(i) .. "] =", tostring(goodChildren[i]))
end

print()
print("=== 대조군: Modifier/Ref 둘 다 넘겼을 때도 동일하게 동작하는가 ===")
local fullProps: Params = {
	Modifier = { isModifier = true },
	Ref = { isRef = true },
	Text = "hello",
}
local fullChildren = MyComponent(fullProps)
print("full #t =", #fullChildren, "(항상 5)")

--[[
	확인 포인트 (런타임 실행):
	1. bad #t가 5가 아니거나(예: 3), 순회 시 앞쪽 두 슬롯이 이상하게 뒤로
	   밀리거나 사라지는가 — 이게 실제 nil-hole 버그의 재현.
	2. good/full 양쪽 모두 #t가 정확히 5이고, 순서(Modifier자리, Ref자리,
	   Text, fixed-child-1, fixed-child-2)가 항상 지켜지는가.

	확인 포인트 (luau-analyze 타입 체크):
	1. `export type Params`가 옵셔널 Modifier?/Ref? 필드로 문제없이
	   타입체크되는가.
	2. `props.Modifier or None`에서 None을 `any`로 캐스팅해뒀는데, 이걸
	   실제 Modifier/None 유니온 타입으로 더 정확히 표현하려면 어떤 타입
	   선언이 필요한지(예: `type Slot<T> = T | typeof(None)`류) 실 Luau
	   에러 메시지를 보고 판단해볼 것 — 지금 파일은 `any` 캐스팅으로
	   일단 회피해뒀음, 이 부분은 M7/M8 실제 구현 시 정확한 타입을 찾아야 함.
]]
