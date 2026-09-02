# M5 단위 ② Studio 스모크 — 생성 범위의 실기기 검증

**상태**: 완료(2026-09-02). `scripts/gen-d.py`가 산출한 생성 범위
(`quad-roblox/dump/api-surface.json`의 클래스 집합)를 Studio MCP
`execute_luau`(Edit, "Place1")로 실검 — **범위 판정식(H-296 (a))이 실제
엔진에서 전량 생성 가능한 집합을 내는가**가 질문.

## 1차 실행 — FAIL 1건이 곧 `H-301` 발견

정제 전 36클래스 중 **`RelativeGui` 생성 실패**: `The current thread cannot
create 'RelativeGui' (lacking capability RobloxScript)` — 덤프 태그
(`NotReplicated`뿐)로는 드러나지 않는 capability 게이트. 함께 점검하니
클래스 수준 배제 규칙 자체가 없었다: `GuiMain`(Deprecated),
`TextChannelWindow`/`VideoDisplay`(NotBrowsable), `AdGui`(MemoryCategory
Internal)가 사용자 표면이 아닌데 생성 대상에 들어 있었다. → 생성기에
클래스 제외 규칙(`Deprecated`/`NotBrowsable`/`Internal` + 실측 denylist
`RelativeGui`) 반영, `H-296` (a)의 "creatable" 취지를 실측으로 구체화
(round14 `H-301` ①).

부수 확인: Frame 대표 프로퍼티 4종 쓰기·`MouseEnter` Connect 왕복 정상,
`InputActionLabel`(핀 defs 게이트로 드롭된 클래스)은 **엔진에선 생성
가능** — 드롭 사유가 defs이지 엔진이 아님을 관측(defs 승급 시 자동 복귀).

## 2차 실행 — 정제된 전 클래스 전량 생성 성공

정제 후 클래스 전량(개수·목록은 `api-surface.json`이 소스)
`Instance.new` **전량 성공, FAIL 0** — 생성물은 전부 Destroy(잔여 0).

## 남긴 것

- `D` 실주행(①~④ 파이프라인이 실물 위에서 — props·자식·store-bind까지)은
  파일 동기화 수단이 필요해 **단위 ⑤(첫 렌더)** 몫 — 이 스모크는 범위
  집합의 유효성까지만.
- 스크립트 원문은 세션 트랜스크립트(클래스 목록 전사물 — 명세는
  `api-surface.json` + 이 표).
