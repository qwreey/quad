<!-- quad-v2 세션 로그 원문 — CLAUDE.md에서 이전됨(2026-08-11 정리 세션). -->
<!-- 이 파일은 quadnomicon 개발로그 소재용 원자료로, 당시 시행착오(정정 전 서술 포함)를 그대로 보존함. -->
<!-- 현재 유효한 설계는 이 파일이 아니라 base//research//archive/가 최종 소스 — 이 파일 안의 판단이 이후 세션에서 뒤집혔을 수 있음. -->

## 2026-08-10 세 번째 세션 — `OnChange` 특수 키 신설: `GetPropertyChangedSignal`
바인딩, 제네릭 없이 확정

사용자가 `GetPropertyChangedSignal`을 어떻게 다뤄야 할지 물으며 시작 —
이벤트는 이미 평범한 문자열 키(`inst[key]`가 곧 Signal)로 확정돼 있는데,
`GetPropertyChangedSignal(name)`은 프로퍼티 이름을 인자로 받아야 하고 그
이름이 "값 세팅" 키 네임스페이스와 겹쳐서 같은 패턴을 못 씀 — 사용자가
`[OnChange "PropertyName"] = function(v) ... end` 형태(타입은 콜백에 직접
명시)와 "`OnChange.PropertyName`을 전부 코드 생성"하는 대안 두 가지를
제시하며 의견을 물음.

**확정**: `OnChange(name)` DI 키 팩토리, **제네릭 타입 파라미터 없음** —
`Attribute<<T>>`와 달리 콜백 파라미터 타입은 호출부가 직접 명시. 이미
확정된 "이벤트 바인딩은 콜백 시그니처를 Luau가 검증 못 하는 대가를
받아들인다"는 결정과 같은 급의 트레이드오프라 새로 정당화할 것 없다는 게
근거 — 오히려 `Attribute`처럼 제네릭으로 정확히 맞추려 들면 이벤트 키보다
더 엄격한 걸 요구하는 셈이라 일관성이 깨짐. 프로퍼티별 정적 코드 생성 안은
기각(`archive/onchange-per-property-codegen-rejected.md`) — Attribute의
정적 지름길은 타입 파라미터가 좁고 고정된 프리미티브 집합(~10종)에서만
와서 지름길 후보가 유한한데, 프로퍼티는 클래스마다 이름/타입 집합이 전부
달라 (클래스 수 × 프로퍼티 수) 규모로 폭발함 — 겉보기엔 비슷한 절충
같지만 실제로는 규모가 다른 문제.

패키지 경계는 **전부 quad-roblox**(`Handlers/OnChange.luau`, `Attribute`와
같은 배치 — `GetPropertyChangedSignal` 자체가 Roblox 엔진 API라 base에 둘
값 타입/API 레이어가 없음). `process`는 `GetPropertyChangedSignal(name):Connect`,
`retract`는 `:Disconnect` — 일반 `Handlers/Event.luau`와 같은 결. **`State<function>`
지원도 새 메커니즘 없이 해소** — 이미 확정된 "이벤트도 store-bind 가능
(`false`로 disconnect)" 메커니즘이 그대로 적용됨, `OnChangeHandler`는
`process`/`retract`만 구현하면 범용 `Dispatch/StoreBind.luau`가 State/Source
언랩+재귀 재-dispatch를 알아서 해줌.

`base/onchange-plan.md`(신규)/`base/bind-system-plan.md`(이벤트 네이밍 절
교차 참조)/`base/architecture.md`(소스트리 `Handlers/OnChange.luau`)/
`ROADMAP.md`(M10 제목·체크박스)/`.claude/README.md`(base/archive 인덱스)
전부 반영 완료.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터, luau-test 결과 확인
우선) — 이번 세션도 순수 설계 확정이라 M0 착수 우선순위 자체는 그대로.

