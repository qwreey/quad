--!strict
--[[
	검증 대상(타입 전용): `H-305` (d′) — 백엔드 표면(`D`)을 `UseProvider`
	확장(`Self & P`)으로 실으면 소비자까지 캐스트 0으로 풀 타입이 흐르는지.
	`done/23`(AddPlugin 체이닝 + CheckedQuad 생존)의 확장판 — 이번엔 P가
	실전 모양(커링 `New`·별칭·중첩 `Mapper` 테이블)이고, 음성 대조군으로
	**호출 인자 타입 위반까지** 잡히는 걸 단언한다(H10-3의 setmetatable
	콜러블 형태가 못 하던 것 — `Self & P`는 테이블∩테이블(거주)이라
	함수∩테이블(무거주, H10-3/H10-4)과 계열이 다르다).

	원 실측은 2026-09-02 스크래치(`addplugin-spike/`, luau-lsp 새 솔버 +
	luau-analyze 판정 일치 — 세션
	`session/2026-09-02-04-h305-useprovider.md`), 이 파일은 그 승격판.

	실행: `luau-analyze 29-type-useprovider-extension-d.luau`
	기대: 아래 "음성 대조군" 두 줄의 TypeError **정확히 2건**(+ 미사용
	변수 lint 2건)만. 양성 경로가 조용하면 통과, 음성이 조용하면 D가
	any로 뭉개진 것(실패).
]]

local QuadTypes = require("../../../quad-types/src")
type Quad = QuadTypes.Quad

-- 생성 D를 본뜬 네임스페이스 타입(실물은 gen-d.py 산출 `export type D` —
-- 31클래스라 여기선 축소형; 규모 축은 test.sh의 LuauTarjanChildLimit 항목,
-- `typing-limits.md` 8.5절)
type FrameParam = { Name: string?, Size: number? }
type D = {
	New: (className: string) -> (props: any) -> any,
	Frame: (props: FrameParam) -> any,
	Mapper: { Root: any, Frame: (key: any) -> (props: any) -> any },
}
type RobloxExt = { D: D }

local function RobloxProvider<T>(quad: T): RobloxExt
	-- 프로바이더 본문 안 CheckedQuad 배선(가상 필드 강제 참조)도 생존
	local checked: QuadTypes.CheckedQuad<T, "0.0.0"> = quad :: any
	local _forceCheck = checked.__versionCheck
	return (nil :: any) :: RobloxExt
end

type SpringExt = { Spring: (initial: number) -> { Target: (self: any, v: number) -> () } }
local function SpringPlugin<T>(quad: T): SpringExt
	return (nil :: any) :: SpringExt
end

local Quad = (nil :: any) :: Quad
-- 프로바이더(1슬롯) 먼저, 플러그인(다수) 체이닝 — 실전 순서
local q = Quad:UseProvider(RobloxProvider)
local q2 = q:AddPlugin(SpringPlugin)

-- 양성 경로 — 전부 클린이어야 함
local f = q2.D.Frame({ Name = "hello", Size = 3 })
local curried = q2.D.New("Part")
local mapped = q2.D.Mapper.Frame("Key")({})
local spring = q2.Spring(1)
local src = q2.Source(1) -- base 메소드가 교집합 2겹을 뚫고 살아 있는가
local none = q2.None
local _use = { f, curried, mapped, spring, src, none }

-- 음성 대조군 — 아래 두 줄이 각각 정확히 TypeError를 내야 한다
local badArg = q2.D.Frame({ Name = 123 }) -- Name: string? 위반(인자 검사 살아있음)
local badKey = q2.D.Bogus -- 없는 필드

print("type-only spike; findings are in analyze output")
