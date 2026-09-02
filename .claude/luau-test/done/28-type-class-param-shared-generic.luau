--!strict
--[[
	28 — `<Class>Param<E>` 공유 제네릭이 두 소비자(D.<Class> / D.Mapper.<Class>)를
	실제 Luau 타입으로 통과하는지 (claim-plan §7-12·§9가 요구한 luau-analyze
	스파이크). 검증 대상은 **메커니즘**(한 Param 타입을 E만 갈아 끼워 두 리턴
	타입이 공유)이지 필드 유니언의 정확한 구성(H-298 §4 대기)이 아니다 —
	필드 타입은 자리표시자.

	실행: `luau-analyze <이 파일>` — 기대 진단은 음성 대조군 **정확히 3건**
	(아래 NEG 주석 줄): (1) D.Frame children에 MapperDescriptor 거부,
	(2) props에 `Parent` 거부(H-142 — Param에 필드 자체가 없음 + 여분 필드
	거부), (3) Mapper 디스크립터를 Frame 자리에 대입 거부.
	그 외 진단이 나오면 메커니즘이 깨진 것.

	[2026-09-02 실측] 기대 3건만 발생 — 통과. round14 단위 ② 착수 전 확인.
]]

type State<T> = { Get: (self: State<T>) -> T }
type None = { __none: true }
type MapperDescriptor = { __mapper: true }
type MapperRoot = { __mapperRoot: true }
type Frame = { __frame: true, Name: string }
type TextLabel = { __textLabel: true, Name: string }

-- 자리표시자 children 원소(H-298 전엔 최소형): 생성물 Instance 타입 유니언
type NewChild = Frame | TextLabel

type FrameParam<E> = {
	[number]: E,
	Size: (number | State<number> | None)?,
	Name: (string | State<string> | None)?,
	MouseButton1Click: ((() -> ()) | State<() -> ()> | None)?,
	-- `Parent` 필드는 의도적으로 없다(H-142) — 덤프 층 제외의 타입판
}

local D = {}
D.Frame = (nil :: any) :: (FrameParam<NewChild>) -> Frame

local Mapper = {}
Mapper.Frame = (nil :: any) :: (key: string | MapperRoot) -> (FrameParam<NewChild | MapperDescriptor>) -> MapperDescriptor

local child: TextLabel = nil :: any
local desc: MapperDescriptor = nil :: any

-- ── 양성: 같은 Param을 두 소비자가 공유, E만 다름 ──────────────────
local f: Frame = D.Frame({ Size = 5, Name = "a", child })
local d: MapperDescriptor = Mapper.Frame("Body")({ Size = 5, child, desc })
local d2: MapperDescriptor = Mapper.Frame((nil :: any) :: MapperRoot)({ Name = "r" })
print(f, d, d2)

-- ── 음성 대조군(정확히 3건) ─────────────────────────────────────────
local n1 = D.Frame({ desc }) -- NEG 1: D children에 MapperDescriptor 불가
local n2 = D.Frame({ Parent = f }) -- NEG 2: props에 Parent 불가(H-142)
local n3: Frame = Mapper.Frame("x")({}) -- NEG 3: 디스크립터는 Frame이 아님
print(n1, n2, n3)
