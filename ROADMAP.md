# ROADMAP.md

quad-v2 구현 단계 실행 계획. 설계 근거/아키텍처 자체는 여기 안 옮겨적음 —
`.claude/base/`가 소스, 여긴 **순서와 진행 상황**만. 마일스톤 시작할 때
체크박스를 세분화해서 늘려도 되고, 끝나면 체크만 하면 됨 — 살아있는 문서.

**2026-08-04 세션에 준비만 해둔 상태 — 아직 M0도 시작 안 함.** 다음 세션은
바로 M0부터.

## M0 — 스켈레톤 + 기술검증 (스파이크, "진짜" 마일스톤 아님)

최종 소스 트리를 그대로 만들기 전에, 지금까지 **추론만으로 확정하고 실제
Luau 코드로 부딪혀본 적 없는 세 가지**를 던지는 코드로 검증하는 단계 —
`.claude/base/` 감사에서 나온 결론(2026-08-04). 여기서 뭔가 어긋나면
`architecture.md`/`bind-system-plan.md` 등을 이 시점에 고치는 게 정상 —
실패가 아니라 이 단계의 목적.

- [ ] Store/State push-invalidate → pull-recompute propagation을 실제로
      짜보기(다이아몬드 의존성 케이스 포함 — 이미 invalid면 전파 중단되는지)
- [ ] Source가 State를 구조적으로 만족하는 제네릭 타입(`:Compute<U>(self:
      Source<T>, ...) -> State<U>`류, self 타이핑 + State 참조 혼합)이
      Luau 솔버에서 안전하게 추론되는지 확인(2026-08-06 후속 세션,
      `base/store-semantics.md` "Source가 State를 만족함" 절 — `State<T>`가
      `Source`를 참조하지 않는 단방향 의존으로 두면 위험한 상호 재귀는
      피할 수 있어 보이나 실제 검증 전엔 확정 아님)
- [ ] `process`/`retract` 재귀 재-process 디스패치를 실제로 짜보기(store-bind
      핸들러 하나 + `isHandlable` 우선순위 스캔 포함)
- [ ] props 순회의 "배열 파트 먼저, 해시 파트 나중" 두 패스 계약이 실제
      Luau 테이블에서 관찰한 대로 동작하는지 확인, `PreRef` pre-pass +
      일반 `Ref`/`CreatedRef`의 위치 기반 순서까지 최소 스파이크로 검증
      (2026-08-07 세 번째 세션, `base/bind-system-plan.md` "`phase` 옵션
      폐기 → 위치로 표현, `PreRef` 신설" 절)
- [ ] `props.Modifier`/`props.Ref` named-parameter로 받는 컴포넌트 하나 작성,
      `export type Params = {...}`로 타입 체크되는지 확인
      (`component-composition-plan.md` 최종 결론 1번)
- [ ] 위 과정에서 소스 트리/메커니즘 문서에 고칠 부분이 생기면 그 자리에서
      `.claude/base/` 갱신

**통과 기준**: 세 개 다 Luau에서 자연스럽게 짜이는 게 확인되면 M1 진행.
안 되면 여기서 관련 `base/` 문서부터 고치고 재시도.

## M1 — 실제 스캐폴딩

- [ ] `quad-base/`, `quad-roblox/` 폴더 + 각 `wally.toml`
- [ ] 루트 `default.project.json`, `.luaurc`(`architecture.md` "구현 착수:
      소스 트리 구조 확정" 절 그대로)
- [ ] quad-base용 최소 mock 테스트 하네스(Vide `test/mock.luau` 선례, 순수
      `luau` CLI, `architecture.md` "테스트 전략" 절 참고)
- [ ] 이 시점부터 `.claude/qa-request/`/`.claude/archive/` 폴더 실사용 시작

## M2 — 디스패치 엔진

- [ ] `Dispatch/init.luau`(`process`/`retract` 엔진, `isHandlable` 우선순위 스캔)
- [ ] `Handler.luau`(핸들러 계약 타입)
- [ ] `LifetimeHandle.luau`/`PerInstanceState.luau` **인터페이스만**(타입
      계약, 실 구현 없음 — quad-roblox 실 구현은 M8) — 원래 M8에만
      있었으나 M4(StoreBind의 `Connected` 확인)/M6(Slot의 `canExecute`)이
      이미 이 인터페이스를 전제로 서술돼 있어 로드맵 순서가 역전돼
      있었음(`pre-implementation-audit.md` 우선순위1-9, `question.md` 2번
      — 2026-08-07 세 번째 세션에 반영)
- [ ] mock 대상 테스트

## M3 — Store/State/Source

- [ ] `Source.luau`/`State.luau`/`Store.luau`
- [ ] `store.key` dot-access 타입 추론 확인
- [ ] `Blocker.luau`(`base/blocker-plan.md` 참고 — 여러 Source를
      한꺼번에 바꿔도 파생값 재계산/재대입이 한 번만 되게 하는 primitive,
      State와 밀접히 연관돼 있어 같은 마일스톤에서 개발)
- [ ] mock 대상 테스트

## M4 — 첫 end-to-end 반응형 업데이트

- [ ] `Dispatch/StoreBind.luau`(재귀 재실행 로직, 엔진 무관)
- [ ] mock 대상으로 "store 값 바꾸면 `process`가 다시 호출된다" 확인

## M5 — quad-roblox 최소 프로바이더

- [ ] `RobloxFactory.luau`(BaseModule 뮤테이션, 재호출 가드)
- [ ] `DI/init.luau`(제네릭 생성자 + ~25개 정적 필드)
- [ ] `Handlers/Property.luau`, `Handlers/InstanceChild.luau`
- [ ] 실제 Roblox에서 첫 `Frame{...}` 렌더 확인 — **Studio 작업이라
      `HUMAN_TODO.md` 1번(계정 분리) 먼저 되어야 진행 가능, `SAFETY.md` 준수**

## M6 — Slot

- [ ] "여러 Slot이 형제로 섞일 때 순서 보장" 열린 질문 확인(`slot-plan.md`) —
      Roblox 단일 백엔드로는 급하지 않으면 스킵하고 진행 가능
- [ ] base `Dispatch/Slot.luau`(추상 재조정) + quad-roblox `Handlers/Slot.luau`
      (실제 Parent 조작)

## M7 — Modifier

- [ ] flatten-before-dispatch, immutable `table.clone` 체이닝
- [ ] `Modifier.Override(mod1, mod2, ...)`(가칭, 구 `Merge`) — 필드별 raw
      덮어쓰기, 특별한 State/함수 분기 불필요(`modifier-plan.md` 9번)
- [ ] `State<Modifier>` 조합 타입 차단 확인(`modifier-plan.md` 7번, UB 확정)
- [ ] `:Apply(factory)` 팩토리 함수 체이닝(`modifier-plan.md` 8번, 예약 키
      `Apply`가 제네릭 `__index` 필드 setter와 안 겹치는지 확인)
- [ ] `:Peek<<T>>(key): T|State<T>|nil` 필드 읽기 접근자 +
      `isState(x): boolean`(weak-key 레지스트리 기반, quad-base 공용
      유틸 — `modifier-plan.md` 9번, `bind-system-plan.md`의 `isState` 절)
- [ ] 인라인 키로 modifier 필드를 명시적으로 지우는 문제 확인 — `None`
      (가칭) 센티널 프리미티브 도입 여부(`modifier-plan.md` 2-1번, 아직
      미정 — 착수 전 사용자 확인 필요, 확정 안 되면 이번 마일스톤은
      스킵하고 다음으로 미뤄도 됨)

## M8 — Ref

- [ ] `CreatedRef` 메커니즘(숫자 슬롯 참가자) + `PreRef`(children 배열
      전용, Modifier/Store 타입 차단, 위치 무관 호이스팅 pre-pass —
      `base/bind-system-plan.md` "`phase` 옵션 폐기 → 위치로 표현,
      `PreRef` 신설" 절)
- [ ] Ref 콜백/대기자 실행 루프(`type(v)=="thread"`면 resume+소진,
      함수면 호출+유지 — 같은 배열 하나로 통합)
- [ ] `LifetimeHandle` quad-roblox 실제 구현(Instance 생존 확인, 인터페이스
      자체는 M2로 이동됨)
- [ ] `PerInstanceState` quad-roblox 실제 구현(weak-keyed table, 인터페이스
      자체는 M2로 이동됨)

## M9 — 컴포넌트 합성 레이어

- [ ] 플레인 함수 컴포넌트 관례 문서화/예제
- [ ] `props.Modifier`/`props.Ref` 전달 관례를 정식 컴포넌트로 검증(M0
      스파이크를 정식화)

## M10 — Event / Attribute / Tag

- [ ] `Handlers/Event.luau`(`ReflectionService` 기반 자동 판별)
- [ ] `Handlers/Attribute.luau`
- [ ] `Handlers/Tag.luau`(`CollectionService`)

## M11 — Tween

- [ ] `research/tween-plan.md` 남은 옵션 이름 확정(구조는 이미 확정)
- [ ] `Handlers/Tween.luau`(높은 우선순위 store-bind 핸들러, 기본 오버라이드
      Cancel)

## 특정 마일스톤에 안 묶이고 병행 가능

- [ ] 용어 정리 스윕 — `State`/`DI`/`PerInstanceState`/`Slot` 등
      (`.claude/question.md` 1번), 최종 이름 확정되는 대로 아무 시점에나
- [ ] 각 마일스톤 완료 시 `.claude/qa-request/`/`.claude/archive/`에 기록,
      필요하면 `CLAUDE.md` "최근 세션 요약"도 갱신

## 백로그 (스코프 밖 — 필요성이 실제로 드러나면 그때 설계)

- [ ] `research/existing-instance-bind-plan.md` — Modifier 정적 flatten과
      긴장 관계 있음, 재검토 시 그 문서부터 다시 볼 것
- [ ] 범용 렌더 디버깅 도구로서의 quad-mock(Tween mock 등 동적 동작 포함,
      M1의 quad-base 테스트용 mock과는 별개)
- [ ] `quad-debug`/`quad-debug-roblox-plugin` — 실물 Instance→코드 위치
      역추적 Studio 플러그인(`research/debug-tooling-plan.md`). 위
      quad-mock과 목적이 다름(오프라인 검증 vs 실시간 라이브 관찰) —
      단 trace 이벤트 스키마를 공유할 여지는 있음, 그 문서 참고. M2/M3/M5
      구현 시 훅 확장 지점만 고려해두면 이 항목 자체는 지금 착수 불필요.
- [ ] v1 마이그레이션 가이드 + `objectListClass.__newIndex` 오타 기능 재현 테스트
- [ ] Slot 형제 순서 보장(다중 백엔드 관점) — Roblox만이면 급하지 않음
