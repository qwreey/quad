--!strict
--[[
	검증 대상(타입 전용): `quad-types`의 `CheckedQuad<T>`(버전 체크
	type function)가 실제 `quad-base`가 구현하는 `Quad` 타입과 맞물려
	동작하는지 — 그리고 검증 후에도 `AddPlugin<Self,P>`의 제네릭 체이닝이
	안 깨지는지.

	배경: 2026-08-19 세션 대화 — quad-roblox가 `QuadRoblox(Quad):
	QuadRoblox`처럼 quad-base 인스턴스를 **런타임 주입**으로 받게 되면서,
	pesde의 semver 충돌 방지가 이 관계엔 안 걸리게 됨(선언된 의존성이
	아니라 그냥 함수 인자라서) — 그 빈 자리를 메꾸는 컴파일 타임 버전
	체크. `quad-types/src/init.luau`의 `CheckVersion`/`CheckedQuad` 절
	참고.

	**이 파일이 재현하는 핵심 함정(처음 시도했다가 깨진 것들)**:
	1. `error()`는 못 씀 — type function 자체가 실패한 걸로 판정돼서
	   버려짐. `print(...)` + `return types.never` 조합만
	   "TypeError: <메시지>"로 정확히 뜬다.
	2. 체크를 함수 본문 안의 로컬 타입 별칭으로 두면(`type _Check =
	   CheckVersion<T>`) 제네릭이 인스턴스화될 때마다 재평가되지 않아
	   진단이 아예 안 뜬다 — 리턴 타입/필드 타입처럼 **호출부마다 실제로
	   해석돼야 하는 자리**에 박아 넣어야 함.
	3. **[가장 중요, 가장 늦게 발견]** `CheckVersion<T>`가 `T`를 단순
	   패스스루(`return t`)해도, 그 결과 타입이 **한 번이라도 type
	   function을 거쳤다는 이력만으로** 이후 `AddPlugin<Self,P>` 같은
	   제네릭 self 메소드 체이닝이 조용히 깨짐("Expected this to be
	   exactly 'P & Self', but got 'P & Self'"류의 앞뒤가 같은 의미 없는
	   진단). 그래서 검증 결과는 **원본 타입과 절대 안 섞이는 별도
	   가상 필드**(`__versionCheck`)로 격리해야 하고, 그 필드를 실제로
	   참조해야만 평가가 일어난다(lazy) — 이 파일의 `_forceCheck` 줄이
	   그 필수 스텝을 보여줌.

	실행: `luau-analyze 23-type-quadtypes-checkversion-addplugin.luau`
]]

local QuadTypes = require("../../../quad-types/src")

type RobloxExt = { Frame: (self: any) -> string }

-- quad-roblox가 실제로 쓰게 될 패턴 — 검증과 확장은 별도 스텝(합치면 3번
-- 함정에 걸림)
local function CheckQuad<T>(quad: T): QuadTypes.CheckedQuad<T>
	return quad :: any
end

local function installRobloxBackend(_self: QuadTypes.Quad): RobloxExt
	return nil :: any
end

-- 실제 quad-base가 구현하는 Quad 타입 그대로(버전 일치)
local goodQuad: QuadTypes.Quad = nil :: any

-- 다른 버전을 흉내 — 구조는 같지만 Version 리터럴만 다름
local badQuad = {
	Version = "9.9.9" :: "9.9.9",
	debug = false,
	New = (nil :: any) :: () -> any,
	RunInit = (nil :: any) :: (self: any, initFn: (any) -> any) -> (),
	AddPlugin = (nil :: any) :: <Self, P>(self: Self, pluginFn: (Self) -> P) -> Self & P,
}

-- 1) 버전이 맞으면: 강제 참조 후 통과 + AddPlugin 체이닝까지 그대로 살아있어야 함
local checked = CheckQuad(goodQuad)
local _forceCheck = checked.__versionCheck -- ⚠️ 필수 — 없으면 검증이 조용히 스킵됨

local withRoblox = checked:AddPlugin(installRobloxBackend)
local okFrame: string = withRoblox:Frame()
local okDebug: boolean = withRoblox.debug
print(okFrame)

type SpringPlugin = { Spring: (self: any, v: number) -> number }
local function springFn(_self: QuadTypes.Quad): SpringPlugin
	return nil :: any
end
local withSpring = withRoblox:AddPlugin(springFn)
local spring: number = withSpring:Spring(1)
local stillFrame: string = withSpring:Frame() -- 먼저 추가한 RobloxExt도 안 사라짐

-- 2) 버전이 다르면 강제 참조 시점에 TypeError가 나야 함(음성 대조군)
local checkedBad = CheckQuad(badQuad)
local _forceCheckBad = checkedBad.__versionCheck

print(okDebug, spring, stillFrame)
