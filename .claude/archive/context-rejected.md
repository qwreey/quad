# [기각됨] `Context`(트리 하위 암묵 전파) + 대안이었던 "레이어드 Store"

**기각 일시**: 2026-08-06~07. **현재 유효한 설계**: 명시적 타입 강제
Store 전달(`props.Theme: Store<Theme>`처럼 컴포넌트가 필요한 걸 named
parameter로 명시적으로 요구) + 오버라이드가 필요한 지점에서
`Store({...부모값, 변경필드=새값})`을 한 번 명시적으로 만들어 그 지점부터
평소처럼 prop으로 넘기는 것 — 새 primitive 없이 이미 있는 Modifier의
"merge, 나중 게 이김" 패턴 재사용. **base/ 포인터**: named parameter로
경계를 넘기는 일반 패턴은 `base/component-composition-plan.md` "1. Named
parameter로 경계를 넘김" 절, merge 패턴 자체는 `base/modifier-plan.md`
2번 절 — 이 결정 자체가 새 primitive를 만들지 "않기로" 한 것이라 전용
base/ 절이 따로 없고 기존 두 절의 재사용으로 충분함이 이 파일의 결론.
이 파일은 더 이상 능동적으로 참고할 필요 없음(구현에 안 씀) — "왜 Context가
없는가"가 `quadnomicon`(프레임워크 설계자용 심화 콘텐츠) 소재로 가치 있어서
사유를 통째로 보존해둔 것.

## 무엇을 검토했었나

React `Context`/Vue `provide`-`inject`류, 트리 상위에서 값을 하나 심어두면
중간 컴포넌트가 명시적으로 전달하지 않아도 하위 어디서든 그 값을 읽을 수
있는 암묵적 전파 메커니즘.

### 난이도 판정 요약

서브에이전트 조사 결과: 동기적 저작 트리에 한정한 얕은 버전(Fusion
`Contextual`류 코루틴 키 weak table push-pop)은 구현 난이도 **낮음**이지만,
quad가 정상 패턴으로 확정한 "Slot에 이벤트 핸들러/코루틴에서 비동기로
자식이 추가되는 경우"엔 **에러 없이 조용히 기본값으로 폴백**하는 함정이
있음. 완전 자동(비동기 추가까지 자동 전파)은 Roblox Luau에
thread-local/async-context-propagation 훅이 없어 **사실상 불가**(플랫폼
한계, Node `AsyncLocalStorage`/Python `contextvars`도 "자동"이 아니라
"async 경계마다 명시적 캡처+재진입"으로 같은 문제를 품).

## 기각 이유

얕은 버전조차: (1) `base/slot-plan.md`가 정상 패턴으로 명시한 Slot 비동기
추가에서 가장 먼저, 가장 조용히 깨짐. (2) `research/debug-tooling-plan.md`의
"모든 연결은 선언된 그래프여야 한다"는 quad-debug 철학과 충돌하는 안 보이는
채널을 만듦.

## 대안이었던 "레이어드 Store"도 철회 (사용자 반박 수용)

Context 대신 권고했던 대안 — "레이어드 Store"(자식 Source 모음이 없는
키는 부모로 `__index` 폴백)도 사용자 반박으로 철회됨:

- quad는 이미 **타입으로 강제되는 명시적 Store 전달**을 갖고 있고, 이건
  Context의 "Provider 안 넣으면 조용히 기본값/에러"보다 **더 안전**하다
  (컴파일타임에 걸림 vs 런타임에 조용히 새는 값) — Context보다 나은 지점.
- "필드 일부만 오버라이드, 나머지는 부모 값 그대로"가 필요하면, 오버라이드
  지점에서 `Store({...부모값, 변경필드=새값})`을 **한 번 명시적으로**
  만들어서 그 지점부터 평소처럼 prop으로 넘기면 끝 — Modifier가 이미 쓰는
  "merge, 나중 게 이김" 패턴 재사용 가능, 새 primitive 불필요. 레이어드
  Store(읽는 시점에 몇 단계를 거슬러 올라가는지 안 보이는 자동 폴백)는
  정확히 Context와 같은 이유(디버깅 어려움 — "이 값이 왜 이거지?"를
  추적하려면 부모 체인을 다 훑어야 함)로 얻는 것보다 잃는 게 크다.
- 서드파티 라이브러리가 뭔가 필요하면, 타입이 강제하는 명시적 요구
  (`props.Theme: Store<Theme>`)가 "몰래 안 줘서 죽는다"보다 나은 실패
  모드 — Slot 기반 저작 모델(부모가 자손을 직접 구성)에서도 이런 요청은
  자연스럽게 props로 흐른다.

## 결론

Context, 레이어드 Store 둘 다 프리미티브로 만들지 않음. "왜 Context가
없는가"(명시적 Store 전달이 이미 그 역할을 하고, 타입 강제가 Context의
실패 모드보다 안전하다는 논증)는 `quadnomicon` 에세이 후보로 등록
(`research/documentation-content-map.md` 참고).
