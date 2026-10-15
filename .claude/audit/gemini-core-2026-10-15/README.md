# Gemini 재검사 2026-10-15 — 3.2.0 이후 코어 변경의 라운드 사이 상호작용

3.3.0 전 재검사 셋 중 하나(`delegate-agy`, `gemini-3.8-flash-high`, 격리 worktree `review-core-320`). 원문 `AGY_REPORT.md`, 프로브 `probes/`
(그 worktree의 `quad-base/test/`·`quad-roblox/test/`에 두고 `mise exec -- luau <경로>`로 돌던 것). **판정은 메인**(아래) — 확정된 동작 결함 0.

- **결함 1(Property 첫 세팅 재진입 — "High") → UB, 결함 아님.** 프로브 둘(`tmp.probe_orphan_tween`, `tmp.probe_first_snap_dedup`)은 `q.OnChange` 콜백이
  **자기가 불린 자리에 다른 값을 `q.Dispatch.process`로 직접 넣는** 장면이다 — `Property.luau` 머리 주석과 `core/07`이 정의하지 않은 동작으로 적은 바로 그 경우(정의된 왕복은
  엔진이 quad가 쓴 값을 되돌려 주는 것). 정의된 경로인 State 쪽(`tmp.probe_first_set_reentry` — 콜백이 그 자리를 모는 Source에 Tween을 넣음)은 메인이 직접 돌려 정상:
  재진입이 Observer 설치 동안 붙들렸다가 뒤에 적용되고(`S99`), `retractFrom`이 그 트윈을 취소한다(`X99`). 주석의 "첫 세팅은 재확인이 필요 없다"는 정의된 경로에서 맞다.
- **결함 2(잘못된 값을 쥔 State를 마운트된 Slot에 넣으면 사슬 동결 — "High") → 결정된 결과.** round14 Q170 최종 닫힘(2026-10-06)에서 메인이 같은 장면(`Quad0156`·사슬 `Quad0167`
  동결)을 실측해 보였고 사용자가 lazy 모델(State 원소는 마운트·재조정 때 검사, 사전 `:Get()` 없음)을 골랐다. 던진 뒤 상태는 관측(Q160·Q183). Gemini가 제안한 pcall 안전망은
  "사용자 코드를 pcall로 감싸지 않는다" 원칙과 부딪히고, 사전 검사는 Q170이 되돌린 것.
- **결함 3(`destroySlotTree` 소유 분기가 `_materializing`을 안 내림 — "Medium") → 무해.** 같이 `_destroyed = true`가 서고 `settle`·`WhenIdle`은 파괴된 Slot을 idle로 본다.
  파괴 도중 던진 경우의 대기는 `Slot/init.luau` `settle` 주석이 이미 적은 계약("던진 연산은 그 Slot을 올린 채 두고, 요청은 파괴될 때까지 기다린다").
- **수렴 1(CHANGELOG 101행)** — 같은 날 opus 점검(`audit/surface-convergence-2026-10-15/`)과 독립으로 같은 것을 찾음, 이미 정정됨.
- **수렴 2(CHANGELOG 43행에 BREAKING 표기 없음) → 맞음, 고침.** 엔진 호출 창 안의 조상 CRUD 거부와 `Extract` 회복 폐기는 같은 성격의 113행(마운트 창)과 같이 BREAKING.
- 4.2절의 "곧 또 BREAKING이 날 자리" 넷은 추정 — 릴리즈 정책의 진동은 10-12에 닫혔고, `WhenIdle`의 전역 목록은 사용자 결정(세 시선 검토 뒤)이며 취소 토큰은 관측된 요구 없음.
