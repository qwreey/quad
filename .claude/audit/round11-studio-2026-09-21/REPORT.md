# round11 실측 라운드 — Studio 샌드박스(2026-09-21~)

원장 `.claude/qa-request/post-implementation-review-round11.md`의 실기기 실측 항목(HUMAN_TODO 10~12, Q62 네 입구, B″-8, tweenSlots GC, 물리 순서)을 **작게 하나씩** sonnet 서브에이전트로 잰다. 조건(사용자 확인 2026-09-18): 샌드박스 실험 플레이스 `Place1.rbxl`, 스크래치 인스턴스만 만들고 전부 파괴, 기존 트리는 읽기도 고치기도 안 함. 사용자 지시(2026-09-21): **코드는 바꾸지 않고 사용자 의견을 기록해 나간다** — 반영은 뒤에 묶어서.

## 1. `GetPropertyChangedSignal("className")` — 소문자 Deprecated 별칭 (HUMAN_TODO 10, 탐사 J′)

**측정(2026-09-21, sonnet, `execute_luau` Edit)**: `f = Instance.new("Frame")`.

| 항목 | 결과 |
|---|---|
| `GetPropertyChangedSignal("className")` / `"archivable"` | ok, `RBXScriptSignal` 반환 |
| `GetPropertyChangedSignal("name")` / `"parent"` | 에러 `name is not a valid property name.` / `parent …` |
| 대조군 `"ClassName"`/`"Archivable"`/`"Name"` | ok |
| `f.className`/`f.archivable`/`f.name` 읽기 | ok (`"Frame"`/`true`/`"Frame"`) |
| `archivable` 시그널 + `f.Archivable = false` (+`task.wait` 둘) | **0회** |
| 대조군 `Archivable` 시그널 + 같은 변경 | **1회** |
| `className` 시그널 + `f.Name = …` | 0회 — 단 `ClassName`은 원래 안 바뀌므로 이 프로브는 "죽은 시그널" 증명이 아님(결론엔 무관: 어느 쪽이든 절대 발화 안 함) |

부수: Deferred 기본이라 뮤테이션 직후 동기 카운트는 0, `task.wait` 뒤에 잡힘(1차 시도 대조군까지 0 → 2차로 확인).

**사실**: 소문자 별칭은 표면이 일관되지 않다(`className`/`archivable`은 시그널이 만들어지지만 발화하지 않는 죽은 시그널, `name`/`parent`는 생성 자체 거부). 생성 표면의 소문자 별칭은 둘 — 읽기 `Object.className`(31 클래스), 쓰기 `Camera.focus`. Deprecated 태그로 실린 것은 열 개(`className`·`focus`·`Draggable`·`DistanceLowerLimit`/`DistanceUpperLimit`·`FontSize`×3·`TextWrap`×3), Hidden 허용목록 넷(`Font`×3·`Transparency`).

**사용자 의견(2026-09-21)**: *"소문자 별칭들에 대한 동작은 roblox 측에서도 deprecated 라서 우리가 보장할 것이 없어. 문서화로 끝나는 범위이고, 우리가 표면에서 주든 말든 큰 문제 없다 봄. Deprecated 를 통으로 유지한다기 보단, 자주 쓰이던 것들만 유지해준다였어. remove 나 destroy 처럼 안 쓰이는건 지워도 돼. 특히 소문자는 quad v1 이 있기도 전의 요소야. 그리고 v1 이 바로 compat 하게 연결되지 못한다는게, 중간자가 있어야한다는게 지금 상황이고 마이그레이션에 있어서 재작성은 불가피하기에 자잘한 요소는 멈춰둬도 돼. 다만 재작성에 노고가 많이 드는 Font 등 일부 표면을 놔둔다는건데."* — 즉 2026-09-09의 "Deprecated 통째" 규칙(`PROP_TAG_LEGACY`)은 메인이 넓게 적은 것이고 의도는 허용목록.

**메인 의견**: Hidden처럼 Deprecated도 허용목록으로. 남길 후보 `Font`·`Transparency`·`FontSize`·`TextWrap`, 뺄 후보 `className`·`Camera.focus`·`DistanceLowerLimit`/`DistanceUpperLimit`, `Draggable`은 사용자 판단. 타입 표면만 바뀌는 변경(BREAKING 주간 안), 생성기 규칙 + 표면 JSON. **반영은 보류(사용자 지시) — 결정: (대기)**.
