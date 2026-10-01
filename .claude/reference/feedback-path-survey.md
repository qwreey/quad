# 되먹임 경로 처리 — 다른 반응형 라이브러리 조사 (2026-10-01)

**[2026-10-01 신설 — 사용자 요청]** *"우리 말고도 다른 라이브러리도 pull/push 가 많을텐데, 그런 곳에서는 되먹임 경로를 어떻게 처리하는지 한번 리서치 띄워볼래?"* — sonnet 리서치 한 패스(읽기 전용, 공식 문서·소스 WebFetch + 로컬 클론 `/code/Projects/quad-scratch/refs/`). quad의 결정은 레퍼런스 `docs/reference/core/05-observer-effect.md`의 "Observer는 최종 소비자" 문단(정본)과 `base/source-state-plan.md`의 "Compute 순수성" 절 2026-10-01 문단(경위). **숫자·인용은 fetch 요약 기준**이라 근거로 쓸 땐 출처를 다시 열 것. 못 본 것은 끝의 "미완".

## 라이브러리별 요지

- **SolidJS** — 1.x는 memo/computed 안 쓰기를 막지 않음(`createComputed`는 프리미티브 제작용으로 쓰기 전제, 앱은 `createMemo`); 2.0 베타는 dev에서 소유 스코프 안 쓰기를 `REACTIVE_WRITE_IN_OWNED_SCOPE` 에러(이벤트·타이머 면제, signal별 `ownedWrite`) — `solidjs/solid` 이슈 #3500. effect 자기 의존성 쓰기는 큐로 같은 파동 안 처리, `Updates.length > 10e5`면 throw(dev만 메시지, `packages/solid/src/reactive/signal.ts`). 문서: effect 안 signal 쓰기는 피하고 memo로(<https://docs.solidjs.com/concepts/effects>).
- **Vue 3** — computed getter는 문서상 순수(<https://vuejs.org/guide/essentials/computed.html>), 런타임 강제 미확인. 스케줄러가 job별 `RECURSION_LIMIT = 100` 초과 시 경고하고 그 job 스킵, dev 전용(`packages/runtime-core/src/scheduler.ts`); `ALLOW_RECURSE` job은 자기 재큐잉 허용(켜는 API 경로 미확인).
- **Preact Signals** — computed 안 쓰기 런타임 검사는 현 main에서 못 찾음(ESLint 규칙 `signals/no-signal-write-in-computed` — 검색 요약). setter에서 `batchIteration > 100`이면 `"Cycle detected"` throw, 실행 중 재진입도 같은 에러, dev/prod 동일. 대안 `.peek()`/`untracked` (<https://preactjs.com/guide/v10/signals/>).
- **MobX** — computed 부작용 금지(문서 규칙). reaction 수렴 한도 `MAX_REACTION_ITERATIONS = 100`, 초과 시 에러 *로그* + 큐 비움(throw 아님). `enforceActions`는 되먹임 방어가 아니라 쓰기 위치 규율. 문서: "reaction이 다른 observable을 갱신한다면 그걸 computed로 바꿔라, 예외는 드물다" (<https://mobx.js.org/reactions.html>).
- **Svelte 5** — `$derived` 안 쓰기는 런타임 에러 `state_unsafe_mutation`. `$effect` 플러시 `> 1000`이면 `effect_update_depth_exceeded`("an effect reads and writes the same piece of state"), 수렴하는 재실행은 OK라고 명시. 대안 `$derived`·함수 바인딩 `bind:value={get, set}`·`untrack`·`$effect.pre`(스크롤 보정).
- **Angular signals** — computed 안 쓰기 NG0600 에러(대안 computed·`linkedSignal`·이벤트/effect로 이동·`untracked`). effect 안 쓰기는 v19에서 `allowSignalWrites` 제거로 기본 허용 — 이유는 플래그가 정당한 쓰기까지 막았다는 것(블로그 403, 검색 요약 — 신뢰도 중간). effect는 "마지막 수단". `linkedSignal` 용례: 소스 변경 시 선택값 리셋·보존, 단위 양방향 변환.
- **React** — 파생 개념 없음. "You might not need an effect"(<https://react.dev/learn/you-might-not-need-an-effect>): effect로 state 맞추기 네 패턴(prop 변경 리셋 → `key`, 일부 조정 → 렌더 중 계산·`prevItems` 비교, 부모 통지·effect 체인 → 이벤트 핸들러에서 한 번에)을 피하라; effect가 맞는 곳은 외부 시스템 동기화·레이아웃 측정·외부 스토어(`useSyncExternalStore`). `NESTED_UPDATE_LIMIT = 50`.
- **TC39 Signals 제안** — computed 안 쓰기 허용(유연성·호환 위해 비강제). `Watcher` notify 안 읽기·쓰기는 에러(무효화 통지 중 그래프 불안정 — 작업은 큐로 미룸). 계산 재귀 읽기는 에러. effect·반복 한도는 범위 밖.
- **Fusion 0.3**(`dphfox/Fusion@2790f7b`) — 평가 중(`busy`) 노드 재평가·무효화 순회는 `infiniteLoop` 에러, 무효화 전파에 시간 한도(1초 × `safetyTimerMultiplier`). Computed 안 쓰기 금지 코드는 못 찾음(추정: 규약).
- **Vide**(`centau/vide@452060a`) — strict 모드에서만 같은 노드 재진입 에러(strict는 effect를 두 번 실행해 순수성 점검), 반복 한도 없음, source는 같은 값 쓰기 조기 반환. 문서: effect로 source 갱신은 가능하나 피하고 derive를 우선.
- **Charm**(`littensy/charm@b05f3a9`) — 되먹임·사이클 한도·파생 안 쓰기 검사 못 찾음. `listen`은 getter가 읽은 것만 구독(콜백이 읽은 건 비추적) — 추적과 부작용의 분리가 설계 수단.

## 표 (파생 안 쓰기 / effect 자기 의존성 쓰기 / 상류 vs 다른 대상 구분)

| 라이브러리 | 파생 안 쓰기 | effect 자기 의존성 쓰기(한도·초과 시) | 구분 |
|---|---|---|---|
| Solid | 1.x 허용, 2.0 dev 에러 | 큐, 10e5 초과 throw | 없음 |
| Vue 3 | 문서 금지(강제 미확인) | 100회 경고+스킵, dev만 | 없음 |
| Preact | 무검사(lint) | 100 batch, "Cycle detected" throw | 없음 |
| MobX | 문서 금지 | 100회 에러 로그+큐 비움 | 없음 |
| Svelte 5 | 에러 | 1000 플러시 에러 | 없음 |
| Angular | 에러 NG0600 | v19+ 허용, 한도 미확인 | 위치만(computed 금지/effect 허용) |
| React | 해당 없음 | 50 중첩 | 없음 |
| TC39 | 허용 | 범위 밖(notify 안 읽기·쓰기 에러) | 없음 |
| Fusion | 무검사(추정) | `busy` 재진입 + 1초 시간 한도 | 없음 |
| Vide | 무검사 | 한도 없음, strict만 재진입 에러 | 없음 |
| Charm | 미확인 | 미확인 | 없음 |

조사 범위 안에서 "자기 상류만 막고 다른 대상은 허용"하는 구조적 구분은 없었다 — 다들 횟수(50/100/1000/10e5)나 재진입 플래그로 사후 감지한다. 같은 값에서 멈추는 되쓰기는 정상이라는 구조는 있다(Svelte "수렴하면 OK", Vide·Preact의 같은 값 조기 반환) — quad의 엔진 왕복 예외와 같은 부류.

## 되먹임이 필요하다고 드는 용례와 해법(조사 요약 — 해석은 추정 포함)

선택값을 소스 변경에 맞춰 리셋·보존(`linkedSignal`, React `key`·렌더 중 비교, Solid 2.0 쓰기 가능 memo 구상, Svelte `$derived` 재할당), 단위 양방향 변환(`linkedSignal`, 함수 바인딩), 부모 통지·effect 체인 상태 기계(이벤트 핸들러에서 한 번에), 레이아웃 측정 후 재배치·스크롤 보정(React 레이아웃 effect, Svelte `$effect.pre`), 외부 저장소 동기화(`useSyncExternalStore`, watch). 입력 정규화·clamp·폼 리셋을 이름 붙여 다룬 공식 문서는 못 찾음.

## 메인 판정(2026-10-01) — quad 원칙으로 막히는가

리서치 소견은 "선택값 리셋"과 "레이아웃 측정 후 되먹임"을 quad에서 막힐 후보로 들었으나 메인 판정은 둘 다 막히지 않는다: 선택값 리셋은 목록 Source를 보는 Observer가 **다른 대상**(선택 Source)을 Set하는 모양이라 정상이고(Effect로 쓰면 자기 의존성 Set — 지연 재실행으로 정의), 레이아웃 측정은 `q.Out`/`OnChange`로 엔진 값을 받아 State로 내리는 엔진 왕복이라 정의된 예외다. 막히는 것은 "관측 대상 자체를 되써서 다듬기"뿐이고 그건 Effect로 옮기거나 입력 자리에서 깎는 대안이 있다. quad가 다른 점: (1) Observer에서 "다른 대상 / 자기 상류"를 구분하는 것은 선례가 없다, (2) 다른 라이브러리는 effect 반복에 숫자 한도 + 에러/경고를 정의하는데 quad는 무한 반복을 UB로 두고 debug에서만 한도(`Quad0263`, 1만)를 둔다, (3) 파생 안 쓰기를 Svelte·Angular·Solid 2.0은 런타임 에러로 막고 quad는 UB + debug 감지기다. 도그푸딩 관찰 항목(ROADMAP 백로그)은 그대로 유효.

## 미완

Preact computed 안 쓰기 검사의 과거 이력, Angular effect 반복 한도 숫자, Vue `ALLOW_RECURSE`를 켜는 API, Charm 사이클 처리, 각 라이브러리의 비동기(yield/await) 중 파생·effect 규칙, 입력 정규화를 다룬 공식 문서.
