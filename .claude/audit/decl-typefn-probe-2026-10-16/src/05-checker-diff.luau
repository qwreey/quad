--!strict
-- [P5] 체커 간 클래스 데이터 차이를 타입 함수 안의 예외 처리(Lib의 Policy — Deny/DenyIn/Inject 데이터)로 흡수할 수 있는가
-- (사용자 가설, declaration-surface-plan.md 1절 "타입 함수에서 예외처리를 넣어가며 처리하는게 더 나을지도").
-- 9/16 실측 차이: Hidden `Transparency`(사용자 VSCode defs엔 없음), Studio `keyof<Frame>`의 deprecated `BackgroundColor`·`DataCost`,
-- 이벤트 표현(defs 테이블 vs Studio extern), deprecated `FontSize`/`TextWrap`(luau-lsp defs 어디에도 없음, Studio엔 있음),
-- 읽기 전용 표시 없음(전 환경 rw).
-- 아래 `Report<C>`는 Policy를 적용한 **뒤의** 표면을 print한다(진단으로 뜬다 — Studio는 스크립트 분석 창).
-- 보고할 것: [R] 줄 전부(스크립트 분석 창 복사). 세 환경에서 `props=`/`events=`/`injected={…}`와 watch 목록이 같아지면
-- "예외 처리로 흡수"가 성립한 것이다. 특히 Studio에서 injected가 비어야(Studio는 원래 갖고 있으므로) 하고,
-- `BackgroundColor=-`·`DataCost=-`(Deny)·`MouseEnter=event:(number, number) -> ()`(extern 경로)여야 한다.
local L = require("./Lib")

type R1 = L.Report<Frame>
type R2 = L.Report<TextLabel>
type R3 = L.Report<TextButton>
type R4 = L.Report<ImageButton>
type R5 = L.Report<UIScale> -- Scale은 쓸 수 있어야(DenyIn은 WorldModel에만)
type R6 = L.Report<WorldModel>
type R7 = L.Report<UIShadow> -- Mode는 Deny(덤프: 핀 defs보다 새 Enum.ApplyShadowMode)

-- CLI vsc(사용자 VSCode 재구성 — 확장 1.70.1 + PluginSecurity defs + 동기 플래그 + override):
--   [R] Frame … props=38 events=26 injected={Transparency}
--   [R] TextLabel … props=57 events=26 injected={FontSize,TextWrap,Transparency}
--   [R] TextButton … props=63 events=34 injected={FontSize,TextWrap,Transparency}
--   [R] ImageButton … props=58 events=34 injected={Transparency}
--   [R] UIScale … props=5 events=9 / WorldModel … props=8 events=9 / UIShadow … props=13 events=9
--   watch: BackgroundColor=- DataCost=- AbsoluteSize=- ClassName=- Parent=- MouseEnter=event:(number, number) -> ()
-- CLI pin(레포 핀 1.69.0 + scripts/roblox-defs): Frame·TextLabel·TextButton·ImageButton·UIScale 개수 **같음**, injected만 다름
--   (핀 defs엔 Hidden Transparency가 있어 `{}`/`{FontSize,TextWrap}`). WorldModel 7·UIShadow 11 — 핀 defs가 덤프보다 오래돼
--   `UseWorkspaceCollisionGroups`·`Inset`·`ShowBehindParent`가 없다(버전 차이 — 예외 처리로는 못 메움).
-- 31 클래스 전체 대조(harness/compare-gen.py → out/compare-gen-*.txt): 정책 적용 뒤 키 집합이 생성 D의 <Class>Param과
--   vsc 28/31·pin 29/31 클래스에서 글자까지 같다. 다른 클래스는 전부 API 버전 차이(vsc defs가 덤프보다 새것: Camera
--   OrthographicMode 등·Folder IconTint·UIDragDetector Selectable).
-- extern 이벤트 경로(Studio 모양)는 harness/extern-shim/05b(CLI 전용)에서 따로 — out/cli-05b.txt.

-- 전체 키 목록 — 환경끼리 한 줄씩 대조하기 위한 것(뒤에 `+`가 붙은 이름은 Inject로 채운 것)
type N1 = L.Names<Frame>
type N2 = L.Names<TextButton>
type N3 = L.Names<WorldModel>
type N4 = L.Names<UIShadow>

-- 흡수 확인 — 아래 넷은 세 환경 모두 같은 결과여야 한다
local TextLabel = L.New<<TextLabel>>("TextLabel")
local Frame = L.New<<Frame>>("Frame")
local a = TextLabel({ FontSize = Enum.FontSize.Size14, TextWrap = true, Font = Enum.Font.Arial }) -- 정상(Inject)
local b = Frame({ Transparency = 0.5 }) -- 정상(Inject — VSCode defs엔 원래 없음)
local c = Frame({ DataCost = 1 }) -- 에러여야 정상(Deny — Studio엔 원래 있음)
local d = Frame({ MouseEnter = function(x, y) end }) -- 정상(이벤트 경로 — Studio는 extern)
-- CLI(vsc·sync·pin 같음): c만 에러 두 건(키 `"DataCost"` + 값), a·b·d 무진단.

return { a, b, c, d }
