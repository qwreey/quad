# ROADMAP.md

quad-v2 구현 단계 실행 계획. 설계 근거/아키텍처 자체는 여기 안 옮겨적음 —
`.claude/base/`가 소스, 여긴 **순서와 진행 상황**만. 마일스톤 시작할 때
체크박스를 세분화해서 늘려도 되고, 끝나면 체크만 하면 됨 — 살아있는 문서.

**2026-08-04 세션에 준비만 해둔 상태로 신설, 이후 여러 세션에 걸쳐 설계가
확정될 때마다 각 마일스톤 체크박스가 계속 갱신돼왔음 — 그래도 아직 M0
자체는 시작 안 함.** 다음 세션은 바로 M0부터.

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
      Luau 솔버에서 안전하게 추론되는지 확인(2026-08-06 세 번째 세션,
      `base/store-semantics.md` "Source가 State를 만족함" 절 — `State<T>`가
      `Source`를 참조하지 않는 단방향 의존으로 두면 위험한 상호 재귀는
      피할 수 있어 보이나 실제 검증 전엔 확정 아님)
- [ ] `process`(+반환 retractor 클로저) 재귀 재-process 디스패치를 실제로
      짜보기(store-bind 핸들러 하나 + `isHandlable` 우선순위 스캔 포함)
- [ ] props 순회의 "배열 파트 먼저, 해시 파트 나중" 두 패스 계약이 실제
      Luau 테이블에서 관찰한 대로 동작하는지 확인, `PreRef` pre-pass +
      일반 `Ref`의 위치 기반 순서까지 최소 스파이크로 검증
      (2026-08-07 세 번째 세션, `base/bind-system-plan.md` "`phase` 옵션
      폐기 → 위치로 표현, `PreRef` 신설" 절) — **PreRef pre-pass의 소진은
      `nil`이 아니라 `None`으로(2026-08-07 열 번째 세션 정정, 사용자가
      Luau REPL로 반례 제시 — 키가 듬성듬성해지면 순회가 index 순서를
      전혀 안 지킴), 이 경로는 nil-hole 위험이 아예 없도록 설계됐으므로
      "구멍 있는 테이블 순회" 자체를 검증할 필요는 없어짐(같은 절 "왜
      `nil`이 아니라 `None`인가" 참고)**
- [ ] `props.Modifier`/`props.Ref` named-parameter로 받는 컴포넌트 하나 작성,
      `export type Params = {...}`로 타입 체크되는지 확인
      (`component-composition-plan.md` 최종 결론 1번) — **`props.Modifier or
      None`/`props.Ref or None` 관용구(2026-08-07 열 번째 세션 확정,
      `component-composition-plan.md` "필수 관용구" 절)로 nil-hole을 막는
      케이스를 반드시 포함할 것 — caller가 Modifier/Ref를 안 넘겨도
      `or None`이 항상 non-nil을 보장하므로 `{nil, ref, child}`류 리터럴
      구멍 자체가 안 생김(`research/pre-implementation-audit.md` 1-5).
      M0에서 검증할 것은 "어떻게 막을지"가 아니라 이 관용구가 실제로
      타입 체크/런타임 양쪽에서 문제없이 동작하는지**
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

> **⚠️ 착수 전 필독 — 아래 체크리스트는 *현행* 모델(래핑 핸들러가 재-dispatch
> 전에 `Dispatch.retractFrom`을 선행 호출)을 기준으로 쓰여 있고, 그 모델은
> 교체가 예정돼 있습니다.** 새 모델("하강 diff": 선행 `retractFrom`을 폐기하고
> `Dispatch.process`가 **핸들러를 먼저 비교** — 같으면 그 자리 클로저에 새
> 값을 넘기고 자기 `process` 재호출, 다르면 그 자리부터 전량 철거)은
> `.claude/research/dispatch-redispatch-diff-plan.md`에 있고, `.claude/question.md`
> **0-Z**(Attribute 이름 소유권) 하나만 정해지면 base와 이 문서에 한 번에
> 반영됩니다. **0-Z가 미해결인 채로 M2/M4/M10을 구현하면 곧 갈아엎어야 하는
> 코드를 짜게 됩니다** — 먼저 0-Z를 해소할 것. (base 4개 문서에도 같은 취지의
> ⚠️ 배너가 달려 있는데, ROADMAP에만 없어서 2026-08-13 감사에서 지적됨.)


- [ ] `Dispatch/init.luau` — `Dispatch.getHandler(inst,k,v): Handler?`(순수
      스캔, `isHandlable`+`priority`) / `Dispatch.process(inst,k,v,index)`
      (오케스트레이터: 그 인덱스 점유 여부 체크 → getHandler → 매치된
      핸들러의 `.process`를 불러 **그 반환값(retractor 클로저)을
      `chains`의 그 인덱스에 저장**) / `Dispatch.retractFrom(inst,k,index,v)`
      (아래 항목) / `Dispatch.addHandler(handler)`(레지스트리 등록,
      quad-roblox가 팩토리 뮤테이션 시점에 호출) / `Dispatch.drive(inst,
      flattened)`(배열→해시 두 패스 순회하며 각 `(k,v)`에
      `Dispatch.process(inst,k,v,1)` 호출 — `bind-system-plan.md`의 `None`
      센티널 절, 2026-08-07 여덟 번째 세션에 네이밍 확정).
      **[2026-08-13 다섯 번째 세션 전면 재설계]** "이전 담당자와 다르면
      그 `retract`"라는 옛 diff 모델은 폐기 — 정리 책임은 전적으로
      재귀/래핑 핸들러(`StoreBind`/`NoneHandler`)가 재-dispatch 전에
      스스로 `retractFrom`을 부르는 쪽에 있고, `Dispatch.process`는
      diff를 하지 않음
- [ ] `Handler.luau`(핸들러 계약 타입: `isHandlable(inst,k,v)`/`priority`/
      `process(inst,k,v,index) -> (hintValue)->()` **3종** — `isHandlable`도
      `inst`를 받도록 확정(2026-08-07 여덟 번째 세션), 별도 `retract` 필드는
      `process` 반환값으로 합쳐짐(2026-08-13 다섯 번째 세션))
- [ ] `Brand.luau`(공유 weak-key 레지스트리, `Brand.set(x,tag)`/
      `Brand.get(x)` — `isState`뿐 아니라 `isObserver`/`isEffect`/`isTag`/
      `isAttributeKey`/`isAttribute`/`isTween`/`isBlocker`/`isSource`/
      `isStore`/`isSlot`/`isRef`/`isPreRef`/`isModifier`(2026-08-07 열 번째
      세션 추가 — 원래 태그 목록에서 빠져있었음. **[정정, 2026-08-09
      열한 번째 세션]** `isRef`/`isPreRef`는 `isState`처럼 상위-하위 관계로
      재정정됨 — `isPreRef`가 가장 구체적인 항등, `isRef`는 그 위에 얹혀
      `isPreRef`도 `true`로 통과시킴(PreRef가 Ref 런타임을 재사용하는
      것과 정합). `(v=Ref)` children leaf 매치 핸들러는 이제
      `isRef(v) and not isPreRef(v)`로 명시적으로 좁혀야 함. `isModifier`는
      여전히 단순 항등, 상위 개념 없음. **[정정, 2026-08-11 아홉 번째
      세션]** `isAttribute` 하나였던 게 `isAttributeKey`(단일 키 DI 키
      predicate, 해시파트 `k`를 판별)와 `isAttribute`(그룹 값 predicate,
      array-part `v`를 판별, `isTag`와 같은 결)로 분리됨 — 그룹
      `Attribute(...)` 프리미티브 신설로 같은 이름이 서로 다른 두
      대상(키 vs 값)을 가리키게 돼서 갈라짐, `base/attribute-plan.md`
      참고) 전부의 기반. `isNone`만 예외로 레지스트리 없이 `x == None`
      항등 비교 — `bind-system-plan.md`의 `Brand` 절, 2026-08-07 여덟
      번째 세션 신설)
- [ ] `Relate.luau`(전체가 quad-base, 순수 Lua — `base/relate-plan.md`) —
      `Relate()` 비싱글톤 생성자, `:SetWeak`/`:GetWeak`/`:SetStrong`/`:GetStrong`.
      `inst`(첫 인자)는 항상 weak, `StrongMap`/`WeakMap` 서브테이블은 lazy
      생성(첫 `Set` 호출 시에만), `WeakMap`은 공유 메타테이블(`{__mode="v"}`)
      재사용 — 구 `base.perInstanceState(inst)`/`PerInstanceState.luau`를
      대체(2026-08-08 세션 신설).
- [ ] `LifetimeHandle.luau` **인터페이스만**(`bindLifetime(inst,value)`/
      `unbindLifetime(inst,value)`/`canExecute(inst,value)` 탑레벨 함수
      타입 계약, 실 구현 없음 — quad-roblox 실 구현은 M8) — 원래 M8에만
      있었으나 M4(StoreBind의 `Connected` 확인)/M6(Slot의 `canExecute`)이
      이미 이 인터페이스를 전제로 서술돼 있어 로드맵 순서가 역전돼
      있었음(`pre-implementation-audit.md` 우선순위1-9, `question.md`
      2번 — 2026-08-07 네 번째 세션에 반영).
      **`canExecute`는 `(inst, value) -> boolean`으로 재확정(2026-08-08
      세션, `(handle)` 단일 인자 서술을 대체)** — Observer/Effect는 자기
      `Subscribed` 상태를 먼저 확인, 그 다음 `inst`의 공유 gcconn(`Relate`로
      저장)의 `.Connected`를 봄. **`unbindLifetime(inst,value)` 추가
      (2026-08-09 여섯 번째 세션)** — `inst` 전체 죽기 전에 특정 값 하나만
      조기 해제(`Dispatch.setLength`가 State 재등록 시 이전 Observer를
      정리하는 데 씀), gchold 내부 구조를 호출부가 몰라도 되게 캡슐화.
      `bindLifetime`/`unbindLifetime`/`canExecute` 셋 다 네임스페이스
      없이 탑레벨 함수로 export(`Dispatch.xxx`류 시스템 네임싱과 구분,
      `isState`/`isObserver`와 같은 1급 프리미티브 취급) — `base/
      lifecycle-pattern.md`의 "`bindLifetime`/`canExecute`/`unbindLifetime`
      — 확정" 절 참고. **Observer/Effect 값에는 `bindLifetime`/
      `unbindLifetime`도 M3의 `canBound` 게이트를 확인/세팅** — children
      배열 leaf 부착이 실제로는 `bindLifetime` 호출이라서(M3 체크박스
      참고, 구현 순서상 M2가 M3의 `canBound`를 참조하게 됨에 유의)
- [ ] `Dispatch.setLength(inst,i,len:number|State<number>)`/
      `Dispatch.setOffsetSource(inst,i,offset:Source<number>|None)` —
      array part 형제 순서 보장(Length/Offset 누적합→`LayoutOrder` 리액티브
      바인딩), array part 모든 number 인덱스에 대해 둘 다 호출 필수(생략
      UB, Handler 구현체 작성자만의 계약) — `recompute`는 leaf-lifetime
      경로(`bindLifetime`/`unbindLifetime`)로 등록, `:Subscribe()` 아님
      (2026-08-09 여섯 번째 세션, `base/bind-system-plan.md` "Length/Offset"
      절 — `base/slot-plan.md` "여러 Slot이 섞일 때 순서 보장" 해소)
- [ ] 핸들러 계약 검증: `process`가 retractor 클로저를 **반환하지 않는**
      핸들러를 등록하면 리뷰/린트에서 걸러내기(정리할 게 없어도 항상
      `function() end`를 반환 — `Dispatch.retractFrom`이 nil 체크 없이
      호출, `base/bind-system-plan.md` "핸들러 계약" 절, 2026-08-08 세션
      / **2026-08-13 다섯 번째 세션에 별도 `retract` 필드가 `process`
      반환값으로 합쳐지며 대상만 바뀜**)
- [ ] 우선순위 동률/매치 실패 처리(2026-08-12 열일곱 번째 세션 확정,
      `base/bind-system-plan.md` "우선순위 동률/매치 실패 처리" 절) —
      `HANDLER_PRIORITY_HIGH`/`_NORMAL`/`_LOW` 등 목적별 우선순위 상수,
      매치 실패(`isHandlable`을 만족하는 핸들러 없음)는 `Brand`+`typeof(v)`
      출력 후 즉시 error(provider 초기화 확인 안내 포함 — provider
      미주입 상태도 이 경로로 자동 커버, `pre-implementation-audit.md`
      1-3/1-4), 핸들러 등록/정렬 시점 동률 감지 print 경고 +
      `Dispatch.listHandlers()` 디버그 유틸
- [ ] `Dispatch/Leaf.luau` — `(i:number, v=Ref/Observer/PreRef)` children-array
      leaf 매칭 Handler, `StoreBind.luau`와 같은 층위(범용/엔진무관) —
      quad-base 소속으로 확정(2026-08-08 두 번째 세션, `base/
      bind-system-plan.md` "Dispatch는 프리미티브가 아니다" 절)
- [ ] `chains`(Relate 기반, `{[inst(weak)]={[k]={[index]=retractor}}}` —
      **핸들러 배열이 아니라 재귀 깊이 인덱스→retractor 클로저 맵**) +
      `Dispatch.retractFrom(inst,k,index,v)` — 재귀 재-dispatch(StoreBind/
      NoneHandler)의 정리를 다단 체인까지 정확히 전파(2026-08-08 세 번째
      세션 신설, **2026-08-13 다섯 번째 세션 인덱스 기반 전면 재설계** —
      `base/bind-system-plan.md` "Dispatch 체인" 절,
      `pre-implementation-audit.md` 1-2번 "이전 핸들러 추적" 항목 해소).
      `Dispatch.process(inst,k,v,index)`가 반환 클로저를 그 인덱스에
      저장하는 것도 이 항목에 포함. **구현 시 반드시 지킬 것**:
      - `chains:SetStrong(inst,k,list)`는 `handler.process` 호출 **전에** —
        뒤에 두면 재귀 위임이 자기 테이블을 만들었다가 바깥이 덮어써
        하위 retractor가 통째로 유실됨(2026-08-13 감사에서 잡힌 버그)
      - `handler.process` 호출 전에 그 인덱스에 no-op 점유 마커를 박아
        `list`를 구멍 없는 시퀀스로 유지(hole 있는 테이블의 `#`는 Lua가
        보장 안 함) + 같은 index 재진입도 가드에 걸리게
      - 점유 체크는 `getHandler`/`handler.process`보다 **먼저**(핸들러
        부작용 낭비 없음)
      - 다른 키로 위임할 땐 항상 `index=1`, 같은 키 재귀는 `index+1`;
        `Dispatch.drive`의 진입도 항상 `1`
- [ ] mock 대상 테스트

## M3 — Store/State/Source

- [ ] `Source.luau`/`State.luau`/`Store.luau`
- [ ] `store.key` dot-access 타입 추론 확인 — Luau `type function`
      (`WrapStore`/`ProcessStoreType`)으로 `Store<T>`가 `T`의 각 필드를
      `Source`로 감싼 레코드 타입을 합성 가능함을 확인(2026-08-12 열일곱
      번째 세션, `base/bind-system-plan.md` "`store.key` 레코드 필드
      타이핑" 절) — 실제 문법이 통과하는지는
      `luau-test`의 `16-type-store-key-typefunction.luau`로 실측 필요
- [ ] `:Compute(fn, ...)` — trailing args로 추가 의존성 직접 받는 sugar
      (2026-08-11 세션, `base/bind-system-plan.md` "`:Compute(fn, ...)`"
      절) — `:With(...):Compute(fn)` 체인과 달리 노드 1개(Compute 노드
      자신에 구독만 추가)로 끝나야 함, 새 노드 생성 없이 구현되는지 M0/M3
      스파이크에서 확인. `Effect`/`Observer`는 대칭 sugar 없이 `:With` 명시
      유지(의도적 비대칭, 같은 절 참고)
- [ ] trailing deps를 `fn`에 lazy positional 인자로도 노출(`fn(self,
      previous?, dep1, ..., depN)` — 순서는 Luau 값 레벨 `...`가 파라미터
      리스트 맨 끝이어야 하는 것과 같은 이유로 `previous?`가 deps 팩
      **앞**에 와야 함, 2026-08-11 후속 세션 제안 → 같은 날 세 번째
      세션에 순서 정정, `base/bind-system-plan.md` "trailing deps를 fn에
      lazy positional 인자로도 노출" 절) — 방향/순서는 확정,
      `luau-test`의 `15-type-compute-trailing-deps-typepack.luau`로
      이형 다중 deps를 제네릭 타입 팩으로 표현 가능한지만 실측 필요(안
      되면 동종 타입 dep 1개로 한정)
- [ ] `Blocker.luau`(`base/blocker-plan.md` 참고 — 여러 Source를
      한꺼번에 바꿔도 파생값 재계산/재대입이 한 번만 되게 하는 primitive,
      State와 밀접히 연관돼 있어 같은 마일스톤에서 개발)
- [ ] `state:Apply(factory)`(`base/bind-system-plan.md` "`state:Apply(factory)`"
      절, 2026-08-07 일곱 번째 세션) — `factory(self)`를 체이닝 문법으로
      부르는 순수 설탕, `factory: (State<T>) -> U): U`로 열린 타입. Source도
      기존 `:With`/`:Compute` 델리게이션에 얹혀 자동 포함
- [ ] `state:Observer(fn)` — children 배열 leaf 참가자, **등록 즉시 1회
      실행 확정**(`base/bind-system-plan.md`의 Observer 절), `isObserver`
      판별자, canExecute 게이팅, `:Subscribe()`/`:Unsubscribe()`
- [ ] `Effect(fn, state?)`(`base/effect-plan.md`) — `state` 생략 시 설치
      1회+leaf 사망 시 확정 정리, `state` 지정 시 내부적으로
      `state:Observer(...)`를 조합해 재실행+cleanup 체이닝(React
      `useEffect` 동형). Observer 구현 이후에 착수(의존 관계).
      `EffectHandle:Subscribe()`/`:Unsubscribe()`도 추가(leaf 없이 쓰는
      모듈/스크립트 레벨 Effect) — `:Unsubscribe()`는 Observer와 달리
      마지막 cleanup을 1회 트리거해야 함(2026-08-07 일곱 번째 세션)
- [ ] Observer/Effect 이중 바인딩 금지 — `canBound(handle)` predicate로
      `:Subscribe()`(전역)와 `bindLifetime`(inst-scoped, leaf 부착도
      내부적으로 이걸 호출)이 동시에 걸리면 즉시 `error`(`base/
      bind-system-plan.md` "이중 바인딩 금지" 절, 2026-08-07 일곱 번째
      세션 신설, 이름은 2026-08-09 세션에 `canBound`로 확정, 같은 날
      여섯 번째 세션에서 "leaf 부착=bindLifetime 호출"로 정정 — 진짜
      독립 경로는 둘뿐). `canBound`의 내부 플래그는 `canExecute`가 보는
      `.Subscribed`와 같은 필드 — `bindLifetime`/`unbindLifetime`도
      (Observer/Effect 값에 한해) 이 필드를 세팅/해제
- [ ] mock 대상 테스트

## M4 — 첫 end-to-end 반응형 업데이트

> **⚠️ M2의 ⚠️ 배너와 같은 주의** — 재디스패치 모델이 교체 예정,
> `question.md` 0-Z 먼저 해소할 것.


- [ ] `Dispatch/StoreBind.luau`(재귀 재실행 로직, 엔진 무관 — 재-dispatch
      전 `Dispatch.retractFrom(inst,k,index+1,realv)` 호출 필수, 그 다음
      `Dispatch.process(inst,k,realv,index+1)`. `base/bind-system-plan.md`
      "Dispatch 체인" 절)
- [ ] mock 대상으로 "store 값 바꾸면 `process`가 다시 호출된다" +
      "이전 값이 다른 타입이면 이전 `process`가 반환했던 retractor 클로저가
      정확히 불린다" 확인 + **`State<State<T>>`(값이 또 State/Source)가
      인덱스 N/N+1로 안 겹치고 정상 동작하는지**(2026-08-13 다섯 번째
      세션에 UB→정상 지원으로 재정정) + **최초 마운트 직후 첫 재발행에서
      인덱스 2의 retractor가 실제로 불리는지**(위 M2의 `SetStrong` 순서
      버그가 정확히 여기서 증상으로 나타남)

## M5 — quad-roblox 최소 프로바이더

- [ ] `RobloxFactory.luau`(BaseModule 뮤테이션, 재호출 가드)
- [ ] `DI/init.luau`(제네릭 생성자 + ~25개 정적 필드)
- [ ] `Handlers/Property.luau`, `Handlers/InstanceChild.luau`
- [ ] 실제 Roblox에서 첫 `Frame{...}` 렌더 확인 — **Studio 작업이라
      `HUMAN_TODO.md` 1번(계정 분리) 먼저 되어야 진행 가능, `SAFETY.md` 준수**

## M6 — Slot

> **⚠️ M2의 ⚠️ 배너와 같은 주의** — 아래 "`SlotHandler.process`는 claim
> 실패 시에도 파괴적 클로저를 반환해야 함(`retractFrom`은... 항상 소비)"
> 항목은 현행(교체 예정) 재-dispatch 모델을 전제로 쓰여 있음.
> `question.md` 0-Z 먼저 해소할 것.

- [ ] **[2026-08-13 여섯 번째 세션 — 이 세션의 Slot 결정 전부, 구현 전 필독]**
      - **`State<Slot>` 교체 = 파괴가 아니라 언마운트**(`state<Frame>`와 동일).
        비파괴 경로 `unmountSlotTree`를 `destroySlotTree`와 별도로 구현 —
        차이는 딱 둘: 실제 `Destroy()`를 안 하고, 자식 `releaseOwner`도 안 함
        (자식은 계속 그 slot 소유라 통째로 재마운트 가능 = 포탈).
        **쓰는 자리 둘**: `SlotHandler.process`가 반환하는 클로저, `:List`의
        `reconcile`. **여전히 파괴인 것**: 명시적 `Remove`/`Clear`/`dispose`.
      - **해제 시 owner 등록 되돌리는 순서 고정** —
        `setOffsetSource(inst,k,None)` **먼저**, `setLength(inst,k,0)` **나중**.
        반대로 하면 `setLength` 안의 `recompute`가 죽는 중인 서브트리의 offset
        `Source`에 헛된 `:Set()`을 날림. `recompute`는 `sourceList[i]`가 `nil`
        이어도 `None`처럼 skip(방어), 해제 시 `slot.Offset = nil`.
      - **소유권 판정을 둘로 분리** — nested(`rawAdd`)는 엄격 `claimOwner`
        (같은 owner 재클레임도 error, `Slot{a,a}` 차단, 반환값 없음),
        top-level은 `claimOwnerAt(element, inst, k)`(정확히 같은 `(inst,k)`의
        spurious 재발행만 `false`, `Frame{slot,slot}`은 error).
        `releaseOwner`는 불일치 시 즉시 error.
      - **`rawRemove`가 `releaseOwner`를 부를 것**(옛 의사코드에서 누락돼 있었음),
        **`destroySlotTree`가 자식 소유권 반납 + `_mounted`/`_mountedInst` 복원**
        (GC에 맡기면 재사용이 GC 타이밍 의존으로 비결정적 실패).
      - **`SlotHandler.process`는 claim 실패 시에도 파괴적 클로저를 반환해야 함**
        — no-op을 반환하면 다음 진짜 교체 때 정리 주체가 사라짐(`retractFrom`은
        클로저가 early-return해도 체인에서 항상 소비하므로).
      - 전부 `base/slot-plan.md`에 반영돼 있고, `luau-test/19` C 섹션이
        소유권 분기를 음성 대조군까지 포함해 실측 검증함.
- [ ] **`dispose(value)`** — 대상이 아직 어느 트리에 의해 살아있길 요구되면
      **파괴를 거부하고 즉시 error**(떼어내주지 않음 — 떼는 건 `Set`=언마운트의
      몫). 엔진은 `Destroy`/`Clear`에 에러를 안 내지만 quad 자료구조가 깨지므로,
      quad가 관리 중인 값을 안전하게 지우는 유일한 경로. 마운트 위치는
      `elementOwner`가 이미 알고 있어 새 부기 불필요. 시그니처/대상 범위는
      `.claude/question.md` 0-B에서 미확정

- [x] **"여러 Slot이 형제로 섞일 때 순서 보장" 해소**(2026-08-09 여섯 번째
      세션) — `Dispatch.setLength`/`setOffsetSource` 메커니즘, `base/
      bind-system-plan.md` "Length/Offset" 절. `Slot.Length: State<number>`도
      이때 확정(CRUD/`:List` 여부 무관 항상 노출, 순서 계산과 "n개 검색됨"
      UI 둘 다 겸함) — 구현 시 이 두 API를 `:List`/CRUD의 `raw*`가 호출.
- [x] **Slot의 `Add`/`Remove`/`Extract`/`ExtractAll`/`Clear`/`Move`/`Swap`/
      `Get`/`IndexOf`/`Splice` CRUD 의미론 확정** (2026-08-09 세 번째 세션,
      2026-08-09 열한 번째 세션에 식별 기준 재정정, `Splice`는 2026-08-12
      열다섯 번째 세션 신설 — **[2026-08-13 5차 감사에서 추가] `Splice`가
      이 체크리스트에 누락돼 있었음, `luau-test/20`으로 산술 실측 통과됨**)
      — 에러 조건까지 전부 확정
      (`base/slot-plan.md` "CRUD API 확정"). "재마운트 시 즉시 throw"도
      `isMounted` 이중 추적 분리로 개별 element/Slot 컨테이너 기준이
      명확히 갈림(같은 문서 "`isMounted` 이중 추적 분리" 절).
      **[정정, 2026-08-09 열한 번째 세션] 식별 기준을 element 레퍼런스에서
      인덱스 기준으로 전환** — `Remove(index)`/`Extract(index, newElement?)`
      (O(n) 또는 O(1))/`Move(oldIndex, newIndex)`(O(n))/`Swap(indexA,
      indexB)`(O(1)) 전부 인덱스, `Add(element, index?)`만 element를 직접
      받음(새로 넣는 대상이라 참조가 당연히 있음). 호출부가 `Add` 리턴값을
      안 담고 흘려버리는 경우가 흔해 레퍼런스 기준이 오히려 실사용과 안
      맞았음 — 레퍼런스만 있으면 `IndexOf(element): number?`로 인덱스를
      구하면 됨. `ExtractAll(): {T}`(Clear의 비파괴 버전), `Get(index): T?`
      신설(`get`/`set` 드롭했던 걸 재추가). `Extract(index, newElement?)` —
      `newElement` 지정 시 O(1) 제자리 교체(이전 element 반환), 기존엔
      교체하려면 Extract+Add 이중 O(n) 시프트가 필요했던 문제 해결. 공개
      mutate 메소드 전부 "가드 확인 + `raw*` 위임" 얇은 wrapper(`Get`/
      `IndexOf`는 순수 읽기라 가드 대상 아님). base/roblox 경계에
      mount/unmount 외 reposition 훅 추가됨. **`Slot<T>()` 제네릭화, 요소
      타입 제약 확정** — `nil`/`None` 둘 다 raw 요소로 금지(Slot 안엔
      실제 마운트 가능한 `T`만), 핸들러 계층 값(Ref/PreRef/Observer/
      Effect/Modifier)은 self-ref 컨텍스트가 없어 의미 불성립이라 즉시
      error(`Modifier` 필드와 같은 판별 메커니즘 재사용) — `DI.InstSlot =
      Slot<<Instance>>`(`DI` 네임스페이스 이름 자체는 `question.md` 1번
      용어정리 대기 중, 여기선 잠정 표기)가 quad-roblox의 사실상 유일한
      Slot 타입.
- [ ] `Slot:List(data, updateFn, keyFn?)` — 키 기반 동적 컬렉션 재조정,
      `keyFn(item, index) -> key` 생략 시 원본 `data` 배열 위치(raw index)를
      그대로 key로 사용(중간 삽입/삭제 시 identity 보존 안 됨, 캐스케이드
      갱신 — 흔한 업계 관행과 같은 트레이드오프).
      `updateFn<UD=any>(item, index: number, offset: Source<number>, prev: T?,
      userdata: UD?): (T|nil, UD?)`가 **매 reconcile 사이클마다 호출**
      (filter/toggle 지원 — 첫 반환값 `nil` 시 실제 파괴, `Visible` 토글
      아님, 200+ 항목에서 lazy하지 않은 문제 회피), `prev` 그대로 반환하면
      저비용 재사용 경로. 파라미터 순서는 반환값 순서(`prev`류 먼저,
      `userdata`류 나중)와 맞춤(2026-08-11 세션 정정, 원래 `userdata`가
      `prev`보다 앞이었음).
      **`updateFn`의 `index`는 `keyFn`의 raw `index`(원본 `data` 배열
      위치)와 다른 값** — "이번 사이클에 살아남으면 차지할 압축된 마운트
      위치"(`candidateIndex`, filter로 압축됨), `key`와도 무관(순서/레이아웃
      전용, 식별 목적 아님) — 문서화 시 셋(원본 raw index/`key`/`updateFn`의
      `index`)을 혼동하지 않게 주의. **`offset`은 `Slot.Offset`을 그대로
      전달**(형제 Slot/정적 자식 누적합, `base/bind-system-plan.md`의
      "Length/Offset" 절) — `index`/`offset` 둘 다 **raw 값으로만 전달,
      `Slot`/Handler가 `LayoutOrder` 등을 자동으로 세팅해주지 않음**
      (2026-08-11 세션 확정 — 자동 바인딩은 컴포넌트가 이미 지정한 값을
      매직으로 덮어쓰는 문제가 있어 기각, 실제 반영은 전적으로 `updateFn`
      몫). `:List`가 `Source`를 대신 안 만듦 — item/index를 반응형으로
      감쌀지는 `updateFn`이 `userdata`에 직접 관리, **"버림(`nil` 반환)/
      다시 그림(`prev==nil`, 항상 새 `Source`로 처음부터 올바른 값 생성)/
      source만 갱신(`prev` 재사용, 값 다를 때만 `:Set`)" 세 갈래를
      `updateFn`이 명시적으로 나눠야 낭비 없음** — 재사용 중인 Source에
      미리 `:Set()`해뒀다가 결국 새로 그리게 되면 그 `:Set()`은 아무도
      안 구독한 상태라 무의미한 연산이 됨, `updateFn`만 이 갈래를 정확히
      알아 낭비를 피할 수 있음(반환값 두 개는 서로 독립, `result`가 `nil`이어도
      `userdata`는 명시적으로 반환 안 하는 한 안 지워짐). 정리 루프는
      `mounted`가 아니라 직전 사이클 `keyIndex` 전체를 순회해야 함
      (`userdata`만 살아있는 채로 key가 완전히 사라지는 케이스 커버).
      `userdata = userdata or {}` lazy-init 패턴이 Luau 제네릭에서 잘
      좁혀지는지 실측 필요. **`userdata`는 GC-native 값만 허용,
      `:Subscribe()`한 Observer류 명시적 cleanup 필요한 값은 UB** —
      `item`을 nilable로 바꿔 최종 제거 시 정리 훅을 한 번 더 부르는 안은
      기각(Slot 부모 자체가 Destroy되는 경로에선 이 훅이 전혀 안 불려서
      절반만 동작, `retract`가 Destroy 시 안 불리는 것과 같은 이유).
      (2026-08-09 세 번째 세션 확정, `offset`/raw `index`/세 갈래 구조는
      2026-08-11 세션 추가 확정, `base/slot-plan.md` "`Slot:List(...)`" 절)
      구현.
      **`data:Observer(fn)` 구독은 `:List()` 호출 시점이 아니라 Slot
      마운트 시점까지 lazy — `Dispatch.setLength`와 같은 패턴으로
      `bindLifetime(inst,observer)`(마운트 이후 `:List()`가 불리면
      `self._mounted` 확인 후 즉시 활성화)** (2026-08-09 일곱 번째 세션,
      `base/slot-plan.md` "`Slot:List(...)`"의 "구독 시점" 절)
      **`Slot.Offset: Source<number>`도 `Slot.Length`처럼 공개 필드로
      노출 — Slot 마운트 시점에 `Dispatch.setOffsetSource`가 등록하는
      바로 그 Source를 `self.Offset`으로도 저장**(2026-08-11 세션,
      `base/bind-system-plan.md`의 "Slot.Length와 Slot.Offset은 별개" 절)
- [ ] base `Dispatch/Slot.luau`(추상 재조정, mount/unmount/reposition 3훅) +
      quad-roblox `Handlers/Slot.luau`(실제 Parent 조작 + reposition —
      `SetSiblingIndex` 또는 `LayoutOrder` 기반이면 no-op, 구현 선택)
- [x] **`Slot:Single(state, updateFn?)` 확정** — `:List`를 0/1개짜리
      배열로 감싸는 순수 sugar, `index` 없이 `offset`/`prev`/`userdata`만
      전달, 고정 key로 `prev` 재사용 보장(2026-08-11 세션, `base/
      slot-plan.md` "`Slot:Single`" 절). **[2026-08-11 일곱 번째 세션]**
      `updateFn`이 선택 인자로 완화됨(기본값 identity) — 아래 반응형
      raw 요소 항목 참고.
- [x] **Slot-in-Slot 중첩 확정** — 요소 타입 제약에서 `Slot` 배제 해제
      (`T = Instance | Slot<Instance>`, 자기 참조 제네릭은 실측 필요).
      `Dispatch.setLength`/`setOffsetSource`를 물리 inst 대신 **Slot
      자신을 owner 키**로 재사용하는 재귀 `attachSlot`으로 최상위/중첩
      마운트 통합(새 프리미티브 없음). `Slot.Length`가 raw 개수에서
      "요소별 기여도의 합"으로 의미 변경. 파괴는 재귀적 `Clear()`가
      아니라 flat `destroySlotTree`(파괴 walk + `unbindLifetime` walk,
      outer 쪽 recompute는 1회만) — 물리 target이 살아있는 채로 논리
      서브트리만 죽는 경우 명시적 `unbindLifetime` 필요(GC-native 정리의
      예외 케이스). DOM 백엔드가 nested Slot을 실제 `<div>` 중첩으로
      매핑하는 안은 기각(Fragment와 같은 이유로 wrapper-less 유지 필요) —
      숫자 기반 메커니즘이 web에도 그대로 필요하나, `insertBefore`/
      `removeChild`가 물리적으로 밀고 당겨줘서 이미 배치된 형제 재작성은
      불필요(2026-08-11 세션, `base/slot-plan.md` "Slot-in-Slot 중첩" 절).
- [x] **`Slot(initial?: {T})` 생성자로 확장** — "인자 없는 빈 생성자로
      확정"을 뒤집음, `:Add` 반복 호출 sugar일 뿐(새 마운트 로직 없음).
      `initial ~= nil`이면(빈 테이블도) 즉시 `_crudUsed = true` — 상태상
      `Add→Remove`와 동일하므로. **`_crudUsed` ↔ `_listed` 상호 배타
      가드 신설** — 기존엔 `:List` 설치 후 수동 CRUD만 막았지 반대(수동
      CRUD 후 `:List` 설치)는 안 막아서 `:List`의 reconcile이 기존
      요소를 모른 채 충돌하는 gap이 있었음(2026-08-11 세션, `base/
      slot-plan.md` "CRUD API 확정" 절).
- [x] **`recompute` off-by-one 버그 수정**(2026-08-11 세션, `base/
      bind-system-plan.md` "Length/Offset" 절) — `sum` 누적과
      `offset:Set` 순서가 뒤바뀌어 `Offset`이 자기 자신을 포함해버리던
      버그(예: 유일한 자식인데도 `Offset`이 0이 아니게 됨) 수정. 재진입
      방지 가드는 검토 후 기각 — 각 Slot이 `Relate(자기 자신)`으로
      독립된 `bk`를 가져서 nesting만으로는 같은 `bk`가 재진입되는 경로
      자체가 없음이 재추적으로 확인됨. 진짜 재진입(부작용이 recompute
      도중 같은 Slot의 length에 다시 쓰기)은 `Source⊇State`의 "단방향"
      원칙과 같은 카테고리의 위반으로 **명시적 UB 명명**(방어 로직 없음,
      기존 "일반적 재진입 방어 안 함" 원칙과 정합). `offset`/`sum`은
      0-based 개수, `index`는 1-based Lua 관례라는 것도 명시.
- [x] **반응형 raw 요소 — `State<T>`/`Source<T>`도 Slot 요소로 허용**
      (2026-08-11 일곱 번째 세션, 같은 세션에 정정) — `Slot:Add`가 받는
      실제 타입은 `T | State<T> | Source<T>`(임의 깊이 조합 가능).
      **[정정] 최초 검토한 "position-keyed StoreBind 구독 + Length를
      Compute로 파생" 안은 기각**(nilable 지원하려면 배열 파트 `None`을
      다시 끌어들여야 하고, Length 계산에 예외가 생기고, `Move`/`Swap`이
      인덱스-구독 동기화 부담을 짐 — `:List`가 element 아닌 `key` 기준인
      이유와 정면 충돌) — **새 메커니즘 없이 순수 `:Single` sugar로
      확정**: `isState(element)`면 그 자리에 내부적으로 `Slot():
      Single(element)`(updateFn 생략 시 identity 기본값)를 대신 삽입.
      `_elements`엔 `None`이 절대 안 들어감(비어있는 nested Slot이 자연히
      Length 0 기여), raw 직접 전달 요소에만 여전히 non-nil 요구.
      `:Single`의 `updateFn`도 이 sugar가 성립하도록 선택 인자로 완화
      (`Slot:Single(state, updateFn?)`, 기본값 identity). `:Single`/`:List`와는
      대체 관계가 아니라 같은 메커니즘 위의 다른 `updateFn`일 뿐 — raw
      `State<T>` 요소(identity)는 coarse swap, `updateFn` 직접 지정 시
      `prev`/`userdata` patch-reuse + `offset` 접근(`:Single`이 애초에
      생긴 이유). **부수 발견(사용자)**: `:List`의 `reconcile`이
      nested-Slot 결과를 반환하는 아이템 다음 형제의 압축 `index`를
      그 결과의 `.Length`만큼 건너뛰도록 `pos` 커밋 공식도 같이 수정
      (`pos = candidateIndex - 1 + (isSlot(result) and result.Length:Get()
      or 1)`) — 안 그러면 멀티루트 아이템 다음 형제의 LayoutOrder가
      겹침. `base/slot-plan.md` "반응형 raw 요소" 절.

## M7 — Modifier

- [ ] `Modifier()`(빈 인스턴스 바닥 생성자, 2026-08-07 열 번째 세션
      명시 — `Source(default)`/`Ref(default)`/`Store({defaults})`와 같은
      `Type(args)` 팩토리 관습, `modifier-plan.md` 3번)
- [ ] flatten-before-dispatch(`isModifier(v)`로 배열 항목 중 Modifier만
      판별해 필드 merge, 나머지는 안 건드리고 통과 — 2026-08-07 열 번째
      세션 명시, `modifier-plan.md` 1번), immutable `table.clone` 체이닝 —
      `table.clone`이 메타테이블을 복사 아닌 참조로 공유해 제네릭 `__index`
      기반 체이닝이 안 끊긴다는 메커니즘은 확인됨(2026-08-12 열일곱 번째
      세션, `modifier-plan.md` "`table.clone`의 정확한 동작" 절) — 실제
      Luau 실행 확인은 `luau-test`의 `17-modifier-index-tableclone-chaining.luau`
- [ ] `Modifier.Overridden(mod1, mod2, ...)`(이름 확정, 구 `Merge`→`Override`,
      2026-08-08 세션) — 필드별 raw 덮어쓰기, 특별한 State/함수 분기
      불필요(`modifier-plan.md` 9번)
- [ ] `Overridden`가 서브타입 관계인 서로 다른 Modifier 타입(예: `FrameModifier`/
      `GuiObjectModifier`)을 섞을 때의 타입 시그니처 — **[해소됨,
      2026-08-13 첫 실측 라운드]** `luau-test/09`로 실측 완료, 우려대로
      깨짐 확인됨 → `Overridden(...: any): any`로 느슨하게 열어두는 게
      실제 구현 방향(`modifier-plan.md` 9-2번)
- [ ] `State<Modifier>` 조합에 `isModifier` 기반 명시적 error 적용
      (`modifier-plan.md` 7번, 2026-08-09 세션 확정) — 타입 차단은
      되면 좋은 보너스로 선택 검증(필수 아님)
- [ ] `:Apply(factory)` 팩토리 함수 체이닝(`modifier-plan.md` 8번, 예약 키
      `Apply`가 제네릭 `__index` 필드 setter와 안 겹치는지 확인)
- [ ] `:Peek<<T>>(key): T|State<T>|nil` 필드 읽기 접근자 +
      `isState(x)`/`isSource(x): boolean`(`Brand` 공유 레지스트리 기반 —
      `modifier-plan.md` 9번, `bind-system-plan.md`의 `Brand` 절, M2의
      `Brand.luau`에 이미 구현돼 있어야 함)
- [ ] 인라인 키/setter로 modifier 필드를 명시적으로 지우는 `None` 센티널
      (이름 확정, `modifier-plan.md` 2-1번, `Peek` 반환 타입에 `None` 추가) +
      이를 `nil`로 재디스패치하는 base 내장 `NoneHandler`
      (`bind-system-plan.md`의 `None` 센티널 절, M2 dispatch 엔진의
      "이전 매치 핸들러 추적" 항목과 함께 구현 — `StoreBind` 핸들러와
      동일한 재귀 재디스패치 패턴이라 새 메커니즘 아님) — `None` 센티널
      자체는 확정 완료지만, **⚠️ M2 배너와 같은 주의**: `NoneHandler`가
      쓰는 재-dispatch 배관(선행 `retractFrom` 호출)은 재디스패치 모델
      교체 대상이라 `question.md` 0-Z 먼저 해소할 것
- [ ] 프로퍼티류 필드 타입에 `T' = T | Tween<T>` 치환 반영(타입 생성
      스크립트가 `Position: UDim2` 자리를 `UDim2 | Tween<UDim2>`로 만들면
      끝, Modifier 런타임/`__index` 자체엔 변경 없음 — `modifier-plan.md`
      10번, 2026-08-10 세션, `base/tween-plan.md`)

## M8 — Ref

- [ ] `Ref.luau`(`.Value` 읽기 전용 필드 + `:Set(value)`/`:Callback(fn)`/
      `:Wait(thread?)`, 전부 self 반환) + `PreRef.luau`(별도 파일, Ref
      런타임 재사용 + children 배열 전용, Modifier/Store 타입 차단,
      위치 무관 호이스팅 pre-pass — `base/bind-system-plan.md` "`phase`
      옵션 폐기 → 위치로 표현, `PreRef` 신설" 절 + "API 모양" 절)
- [ ] `(v=Ref)` 매치 핸들러 — children 배열의 숫자 슬롯에 놓인
      `Ref(default)` 인스턴스를 인식해 바인드(별도 `CreatedRef` 래퍼
      없음 — 이름 자체가 폐기됨, 아래 참고)
- [ ] `PreRef` pre-pass — 새 `Dispatch.*` 함수 없이 `Dispatch.drive(inst,
      flattened)` 자신이 두 패스(배열→해시) 루프 전에 배열 파트를 훑어
      `PreRef` 항목만 fire(Dispatch.process/getHandler 우회하는 raw 루프,
      `flatten` 함수에는 얹지 않음 — 재바인드 시 flatten 재호출 가능성과
      충돌하므로 기각). 복수 `PreRef`는 배열 index 순서 그대로(별도 규칙
      없음). fire된 슬롯은 그 자리에서 소진(`None` 처리, `nil` 아님 —
      2026-08-07 열 번째 세션 정정)해 이어지는 정상 두 패스에 다시 노출
      안 되게 함 — `base/bind-system-plan.md` "PreRef" 절
- [ ] `PreRef` 동적 경로 가드 Handler — `{isHandlable = v is PreRef,
      process = error(...)}` 형태로 정상 우선순위 레지스트리에 등록,
      `NoneHandler`와 같은 "한 값 종류 전담" 패턴. 리터럴 배열 경로는
      pre-pass가 이미 소진시키므로 이 Handler가 매치되면 곧 타입 차단을
      우회한 버그라는 뜻 — 같은 절 참고
- [ ] Ref 콜백/대기자 실행 루프(`type(v)=="thread"`면
      `coroutine.resume(v, self)`+`nil`로 소진(2026-08-09 열한 번째
      세션 최종 정정 — 순서 안 중요 + 슬롯 재사용 위해 `None`이 아닌
      `nil`, `table.insert` 대신 빈 슬롯 선형 탐색 등록), 함수면
      `v(value)` 호출+유지 — 같은 배열 하나로 통합). `:Wait(thread?)`는
      `thread`가 `nil`이면
      `coroutine.running()` 캡처+yield, 있으면 등록만 하고 즉시 `self`
      반환(남의 thread를 여기서 대신 정지시킬 수 없어서)
- [ ] `LifetimeHandle` quad-roblox 실제 구현 — `bindLifetime`/`canExecute`
      본체(`GetPropertyChangedSignal("ClassName")` 연결 트릭으로 gcconn 확보,
      `Relate:SetStrong`으로 gcconn/gchold 저장 — 인터페이스 자체는 M2로
      이동됨, `Relate` 자체는 quad-base라 quad-roblox 쪽 재구현 없음)

## M9 — 컴포넌트 합성 레이어

- [ ] 플레인 함수 컴포넌트 관례 문서화/예제
- [ ] `props.Modifier`/`props.Ref` 전달 관례를 정식 컴포넌트로 검증(M0
      스파이크를 정식화)

## M10 — Event / OnChange / Attribute / Tag

> **⚠️ M2의 ⚠️ 배너와 같은 주의** — 재디스패치 모델이 교체 예정이고,
> 특히 **Attribute 이름 소유권(`question.md` 0-Z)이 이 마일스톤의 직접
> 대상**임. 0-Z 먼저 해소할 것.


- [ ] `Handlers/Event.luau`(`ReflectionService` 기반 자동 판별)
- [ ] `Handlers/OnChange.luau`(`OnChange(name)` DI 키 팩토리+Handler,
      `GetPropertyChangedSignal` 바인딩 — 제네릭 없이 콜백 타입은 인라인
      명시, 이름별 weak 캐시로 `OnChange(a) == OnChange(a)` 동등성 보장
      (`AttributeKey`와 동일 기법), `base/onchange-plan.md`, 2026-08-10
      세션 확정·2026-08-11 아홉 번째 세션 후속(캐시))
- [ ] `Handlers/AttributeKey.luau`(단일 키 `AttributeKey<<T>>(name)`/
      `BooleanAttribute`류 DI 키 팩토리+Handler — 메커니즘/`None`/`retract`
      불필요 확정, 이름별 weak 캐시로 동등성 보장, 타입 파라미터화 이름만
      착수 전 확인, `base/attribute-plan.md`)
- [ ] `Attribute.luau`(quad-base — 그룹 값 타입+API: `Attribute(store1,
      store2, ...)`/`Merged`, `Tag`와 동형 array-part 값 객체,
      `base/attribute-plan.md`)
- [ ] `Handlers/Attribute.luau`(quad-roblox — 그룹 `process`가 이름마다
      공개 `AttributeKey(name)`로 `Dispatch.process(inst,key,source,1)`만
      부르고, 반환 클로저가 **자기가 등록한 이름 전부**에
      `Dispatch.retractFrom(inst,key,1,nil)`. 실제 `SetAttribute`/store-bind
      구독은 전부 단일 키 경로 재사용(중복 구현 없음).
      **`process` 안에서 `retractFrom`을 먼저 부르면 안 됨** — 인덱스 1이
      무조건 비워져 소유권 충돌 점유 체크가 무력화됨(2026-08-13 감사),
      `base/attribute-plan.md` "메커니즘" 절)
- [ ] `Tag.luau`(quad-base — 값 타입+immutable clone 체이닝: `Tag(...)`/
      `:Added`/`:Removed`/`:Contains`/`:Apply`/`Merged`, `base/tag-plan.md`
      — 2026-08-08 세 번째 세션 array-part 값 객체로 재설계, 구 해시 파트
      모델은 `archive/tag-hash-key-model-reversed.md`)
- [ ] `Handlers/Tag.luau`(quad-roblox — `CollectionService` 글루만,
      `isHandlable`은 `isTag(v)`. **`AddTag`는 온전히 `process`, `RemoveTag`는
      온전히 반환 클로저** — 이름별 홀더 집합(`tagNameMap`, 위치 `k` 기준
      참조 카운트)이 비었을 때만 실제 `RemoveTag`, 그마저도 `hintValue`가
      그 이름을 `Contains`하면 skip해 깜빡임 방지(전체 삭제 후 재생성
      금지). `process` 쪽 별도 diff 없음, `kTagMap`도 불필요(클로저가 `v`를
      직접 캡처) — 2026-08-12 열한 번째 / 2026-08-13 네·다섯 번째 세션,
      `base/tag-plan.md` "메커니즘" 절)

## M11 — Tween

**[2026-08-10 세션, 구조 재설계]** 독립 Dispatch 핸들러 모델에서 값-레벨
`Tween<T>` 래퍼 모델로 전환 — 상세는 `base/tween-plan.md`(전면
재작성), 구 모델은 `archive/tween-special-bind-key-reversed.md`.

- [ ] `quad-base/Tween.luau`(값 타입만 — `Tween(opts)` 팩토리, `isTween`/
      `TweenTag` Brand, `Value: T` plain만 받고 State 재귀 없음)
- [ ] `Handlers/Property.luau`에 `isTween(realv)` 분기 추가(기존
      `Handlers/Tween.luau` 독립 핸들러는 폐기) + 3-상태 릴레이션 슬롯
      (`RobloxTween | true | nil` — `nil`=첫 세팅, `true`=세팅됨/트윈
      없음, 엔진 객체=활성 트윈) + 첫 세팅은 무조건 애니메이션 없이
      스냅(hasBeenSet 억제) + 활성 트윈 정리는 override 정책 완료 후에만
      새 값 세팅(순서 뒤바뀌면 트윈 다음 프레임이 방금 세팅한 값을 덮어씀)
- [x] **override 정책 확정 완료**(2026-08-12 세션, `base/tween-plan.md`
      "확정: `Tween{...}` 최종 모양" 절) — 검토했던 4가지가 **`Tween.Cancel`
      (기본)/`Tween.Finish` 2값으로 압축**됨(로블록스 `TweenBase` API 현실상
      나머지가 관찰상 Cancel과 동일). Tween→plain 전환도 두 옵션 모두
      "정리 후 즉시 덮어쓰기"로 수렴해 5번째 옵션 불필요로 확정.
      **구현 시 순서 주의**: 이전 트윈 정리 → 그 다음 새 값 세팅
- [x] **트윈 옵션 값 모양 확정 완료**(2026-08-12 세션, `base/tween-plan.md`)
      — `Info: TweenInfo?` 우선 + 편의 필드(`Time`/`Style`/...) 폴백,
      기본값은 로블록스 `TweenInfo.new()` 자체 기본값과 일치. 옵션 필드는
      전부 plain만(State 불가)
- [ ] `quad-roblox/Animate.luau` — **시그니처도 이미 확정 완료**(2026-08-12
      두 번째/세 번째 세션, `base/tween-plan.md`): `Tween` opts(`Value` 제외)를
      `T|State<T>`로 받아 각 필드를 resolve한 뒤 `Tween{...}`을 반환하는
      `function(self)...end` — `:Apply(Animate{...})`로 체이닝(`:Compute`가
      아님, `research/operator-sugar-plan.md` "왜 `:Apply`인가"). `CanAnimate`
      필드 포함(`false`면 `Tween`으로 안 감싸고 plain 값 그대로). M11은
      **구현만** 하면 됨
- [x] **`initValue`(진입 애니메이션) — 에이전트 범위 제외로 확정**
      (2026-08-12 세션, 사용자가 직접 처리하기로) — 재검토 항목 아님

## 특정 마일스톤에 안 묶이고 병행 가능

- [ ] 용어 정리 스윕 — `State`/`DI`/`Slot` 등(`PerInstanceState`는 `Relate`로
      대체·해소됨) — `.claude/question.md` 1번, 최종 이름 확정되는 대로
      아무 시점에나
- [ ] 각 마일스톤 완료 시 `.claude/qa-request/`/`.claude/archive/`에 기록,
      필요하면 `CLAUDE.md` "세션 히스토리"도 갱신(전체 원문은
      `.claude/session/`에, CLAUDE.md엔 2~4줄 요약+링크만 — 2026-08-11
      재구조화 세션 참고)

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
