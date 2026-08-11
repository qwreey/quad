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
- [ ] `process`/`retract` 재귀 재-process 디스패치를 실제로 짜보기(store-bind
      핸들러 하나 + `isHandlable` 우선순위 스캔 포함)
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

- [ ] `Dispatch/init.luau` — `Dispatch.getHandler(inst,k,v): Handler?`(순수
      스캔, `isHandlable`+`priority`) / `Dispatch.process(inst,k,v)`(오케
      스트레이터: getHandler → 이전 담당자와 다르면 그 `retract` → 새
      핸들러의 `.process`) / `Dispatch.addHandler(handler)`(레지스트리
      등록, quad-roblox가 팩토리 뮤테이션 시점에 호출) / `Dispatch.drive(inst,
      flattened)`(배열→해시 두 패스 순회하며 각 `(k,v)`에 `process` 호출 —
      `bind-system-plan.md`의 `None` 센티널 절, 2026-08-07 여덟 번째 세션에
      네이밍 확정). "이 키를 지금 누가 담당 중인가" bookkeeping은
      `Dispatch.drive`가 아니라 `Dispatch.process` 호출 자체 내부에서
      갱신할 것(재귀 재-process 시에도 자연히 갱신되게 — 안 그러면 재귀
      재디스패치를 쓰는 케이스(`StoreBind`, `NoneHandler`)에서 매
      사이클 불필요한 `retract`가 반복 호출될 위험)
- [ ] `Handler.luau`(핸들러 계약 타입: `isHandlable(inst,k,v)`/`priority`/
      `process`/`retract` — `isHandlable`도 `inst`를 받도록 확정, 2026-08-07
      여덟 번째 세션 정정)
- [ ] `Brand.luau`(공유 weak-key 레지스트리, `Brand.set(x,tag)`/
      `Brand.get(x)` — `isState`뿐 아니라 `isObserver`/`isEffect`/`isTag`/
      `isAttribute`/`isTween`/`isBlocker`/`isSource`/`isStore`/`isSlot`/
      `isRef`/`isPreRef`/`isModifier`(2026-08-07 열 번째 세션 추가 — 원래
      태그 목록에서 빠져있었음. **[정정, 2026-08-09 열한 번째 세션]**
      `isRef`/`isPreRef`는 `isState`처럼 상위-하위 관계로 재정정됨 —
      `isPreRef`가 가장 구체적인 항등, `isRef`는 그 위에 얹혀
      `isPreRef`도 `true`로 통과시킴(PreRef가 Ref 런타임을 재사용하는
      것과 정합). `(v=Ref)` children leaf 매치 핸들러는 이제
      `isRef(v) and not isPreRef(v)`로 명시적으로 좁혀야 함. `isModifier`는
      여전히 단순 항등, 상위 개념 없음) 전부의 기반. `isNone`만 예외로
      레지스트리 없이 `x == None` 항등 비교 — `bind-system-plan.md`의
      `Brand` 절, 2026-08-07 여덟 번째 세션 신설)
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
- [ ] 핸들러 계약 검증: `retract` 필드가 없는 핸들러를 등록하면 리뷰/린트에서
      걸러내기(no-op이라도 필드 자체는 항상 정의 — `Dispatch.process`가 핸들러
      교체 시 nil 체크 없이 호출, `base/bind-system-plan.md` "핸들러 계약"
      절, 2026-08-08 세션)
- [ ] `Dispatch/Leaf.luau` — `(i:number, v=Ref/Observer/PreRef)` children-array
      leaf 매칭 Handler, `StoreBind.luau`와 같은 층위(범용/엔진무관) —
      quad-base 소속으로 확정(2026-08-08 두 번째 세션, `base/
      bind-system-plan.md` "Dispatch는 프리미티브가 아니다" 절)
- [ ] `chains`(Relate 기반, `{[inst(weak)]={[k]={handler,handler,...}
      (strong 순서 배열)}}`) + `Dispatch.retractUnder(inst,k,keep,v)` —
      재귀 재-dispatch(StoreBind/NoneHandler)의 retract를 다단
      체인까지 정확히 전파(2026-08-08 세 번째 세션, `base/
      bind-system-plan.md` "Dispatch 체인" 절 — `pre-implementation-audit.md`
      1-2번 "이전 핸들러 추적" 항목 해소). `Dispatch.process`가 매치될
      때마다 체인에 push하는 것도 이 항목에 포함
- [ ] mock 대상 테스트

## M3 — Store/State/Source

- [ ] `Source.luau`/`State.luau`/`Store.luau`
- [ ] `store.key` dot-access 타입 추론 확인
- [ ] `:Compute(fn, ...)` — trailing args로 추가 의존성 직접 받는 sugar
      (2026-08-11 세션, `base/bind-system-plan.md` "`:Compute(fn, ...)`"
      절) — `:With(...):Compute(fn)` 체인과 달리 노드 1개(Compute 노드
      자신에 구독만 추가)로 끝나야 함, 새 노드 생성 없이 구현되는지 M0/M3
      스파이크에서 확인. `Effect`/`Observer`는 대칭 sugar 없이 `:With` 명시
      유지(의도적 비대칭, 같은 절 참고)
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

- [ ] `Dispatch/StoreBind.luau`(재귀 재실행 로직, 엔진 무관 — 재-dispatch
      전 `Dispatch.retractUnder(inst,k,self,realv)` 호출 필수, `base/
      bind-system-plan.md` "Dispatch 체인" 절)
- [ ] mock 대상으로 "store 값 바꾸면 `process`가 다시 호출된다" +
      "이전 값이 다른 타입이면 이전 핸들러의 `retract`가 정확히 불린다"
      확인

## M5 — quad-roblox 최소 프로바이더

- [ ] `RobloxFactory.luau`(BaseModule 뮤테이션, 재호출 가드)
- [ ] `DI/init.luau`(제네릭 생성자 + ~25개 정적 필드)
- [ ] `Handlers/Property.luau`, `Handlers/InstanceChild.luau`
- [ ] 실제 Roblox에서 첫 `Frame{...}` 렌더 확인 — **Studio 작업이라
      `HUMAN_TODO.md` 1번(계정 분리) 먼저 되어야 진행 가능, `SAFETY.md` 준수**

## M6 — Slot

- [x] **"여러 Slot이 형제로 섞일 때 순서 보장" 해소**(2026-08-09 여섯 번째
      세션) — `Dispatch.setLength`/`setOffsetSource` 메커니즘, `base/
      bind-system-plan.md` "Length/Offset" 절. `Slot.Length: State<number>`도
      이때 확정(CRUD/`:List` 여부 무관 항상 노출, 순서 계산과 "n개 검색됨"
      UI 둘 다 겸함) — 구현 시 이 두 API를 `:List`/CRUD의 `raw*`가 호출.
- [x] **Slot의 `Add`/`Remove`/`Extract`/`ExtractAll`/`Clear`/`Move`/`Swap`/
      `Get`/`IndexOf` CRUD 의미론 확정** (2026-08-09 세 번째 세션, 2026-08-09
      열한 번째 세션에 식별 기준 재정정) — 에러 조건까지 전부 확정
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
      error(`Modifier` 필드와 같은 판별 메커니즘 재사용) — `D.InstSlot =
      Slot<<Instance>>`가 quad-roblox의 사실상 유일한 Slot 타입.
- [ ] `Slot:List(data, updateFn, keyFn?)` — 키 기반 동적 컬렉션 재조정,
      `keyFn` 생략 시 index를 그대로 key로 사용(중간 삽입/삭제 시 identity
      보존 안 됨, 캐스케이드 갱신 — 흔한 업계 관행과 같은 트레이드오프).
      `updateFn<UD=any>(item, index, userdata: UD?, prev: T?): (T|nil, UD?)`가
      **매 reconcile 사이클마다 호출**(filter/toggle 지원 — 첫 반환값
      `nil` 시 실제 파괴, `Visible` 토글 아님, 200+ 항목에서 lazy하지 않은
      문제 회피), `prev` 그대로 반환하면 저비용 재사용 경로. `:List`가
      `Source`를 대신 안 만듦 — item/index를 반응형으로 감쌀지는
      `updateFn`이 `userdata`에 직접 관리(반환값 두 개는 서로 독립,
      `result`가 `nil`이어도 `userdata`는 명시적으로 반환 안 하는 한 안
      지워짐). 정리 루프는 `mounted`가 아니라 직전 사이클 `keyIndex`
      전체를 순회해야 함(`userdata`만 살아있는 채로 key가 완전히 사라지는
      케이스 커버). `userdata = userdata or {}` lazy-init 패턴이 Luau
      제네릭에서 잘 좁혀지는지 실측 필요. **`userdata`는 GC-native 값만
      허용, `:Subscribe()`한 Observer류 명시적 cleanup 필요한 값은 UB** —
      `item`을 nilable로 바꿔 최종 제거 시 정리 훅을 한 번 더 부르는 안은
      기각(Slot 부모 자체가 Destroy되는 경로에선 이 훅이 전혀 안 불려서
      절반만 동작, `retract`가 Destroy 시 안 불리는 것과 같은 이유).
      (2026-08-09 세 번째 세션 확정,
      `base/slot-plan.md` "`Slot:List(...)`" 절) 구현.
      **`data:Observer(fn)` 구독은 `:List()` 호출 시점이 아니라 Slot
      마운트 시점까지 lazy — `Dispatch.setLength`와 같은 패턴으로
      `bindLifetime(inst,observer)`(마운트 이후 `:List()`가 불리면
      `self._mounted` 확인 후 즉시 활성화)** (2026-08-09 일곱 번째 세션,
      `base/slot-plan.md` "`Slot:List(...)`"의 "구독 시점" 절)
- [ ] base `Dispatch/Slot.luau`(추상 재조정, mount/unmount/reposition 3훅) +
      quad-roblox `Handlers/Slot.luau`(실제 Parent 조작 + reposition —
      `SetSiblingIndex` 또는 `LayoutOrder` 기반이면 no-op, 구현 선택)

## M7 — Modifier

- [ ] `Modifier()`(빈 인스턴스 바닥 생성자, 2026-08-07 열 번째 세션
      명시 — `Source(default)`/`Ref(default)`/`Store({defaults})`와 같은
      `Type(args)` 팩토리 관습, `modifier-plan.md` 3번)
- [ ] flatten-before-dispatch(`isModifier(v)`로 배열 항목 중 Modifier만
      판별해 필드 merge, 나머지는 안 건드리고 통과 — 2026-08-07 열 번째
      세션 명시, `modifier-plan.md` 1번), immutable `table.clone` 체이닝
- [ ] `Modifier.Overridden(mod1, mod2, ...)`(이름 확정, 구 `Merge`→`Override`,
      2026-08-08 세션) — 필드별 raw 덮어쓰기, 특별한 State/함수 분기
      불필요(`modifier-plan.md` 9번)
- [ ] `Overridden`가 서브타입 관계인 서로 다른 Modifier 타입(예: `FrameModifier`/
      `GuiObjectModifier`)을 섞을 때의 타입 시그니처 실 Luau 테스트
      (`modifier-plan.md` 9-2번, 미검증 — 안 되면 일단 `Overridden(...: any):
      any`로 느슨하게 열어두고 이 항목으로 되돌아올 것)
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
      동일한 재귀 재디스패치 패턴이라 새 메커니즘 아님) — 확정 완료
- [ ] 프로퍼티류 필드 타입에 `T' = T | Tween<T>` 치환 반영(타입 생성
      스크립트가 `Position: UDim2` 자리를 `UDim2 | Tween<UDim2>`로 만들면
      끝, Modifier 런타임/`__index` 자체엔 변경 없음 — `modifier-plan.md`
      10번, 2026-08-10 세션, `research/tween-plan.md`)

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

- [ ] `Handlers/Event.luau`(`ReflectionService` 기반 자동 판별)
- [ ] `Handlers/OnChange.luau`(`OnChange(name)` DI 키 팩토리+Handler,
      `GetPropertyChangedSignal` 바인딩 — 제네릭 없이 콜백 타입은 인라인
      명시, `base/onchange-plan.md`, 2026-08-10 세션 확정)
- [ ] `Handlers/Attribute.luau`(`base/attribute-plan.md` — 메커니즘/`None`/
      `retract` 불필요 확정, 타입 파라미터화 이름만 착수 전 확인)
- [ ] `Tag.luau`(quad-base — 값 타입+immutable clone 체이닝: `Tag(...)`/
      `:Added`/`:Removed`/`:Contains`/`:Apply`/`Merged`, `base/tag-plan.md`
      — 2026-08-08 세 번째 세션 array-part 값 객체로 재설계, 구 해시 파트
      모델은 `archive/tag-hash-key-model-reversed.md`)
- [ ] `Handlers/Tag.luau`(quad-roblox — `CollectionService` process/retract
      글루만, `isHandlable`은 `isTag(v)`. `retract`는 이제 의미 있음(값이
      Tag가 아니게 되면 전체 삭제), 같은 Tag끼리 바뀌는 diff는 `process`가
      자기 `Relate` 저장분과 비교해서 처리 — 전체 삭제 후 재생성 금지(랙
      유발), `base/tag-plan.md` 참고)

## M11 — Tween

**[2026-08-10 세션, 구조 재설계]** 독립 Dispatch 핸들러 모델에서 값-레벨
`Tween<T>` 래퍼 모델로 전환 — 상세는 `research/tween-plan.md`(전면
재작성), 구 모델은 `archive/tween-special-bind-key-reversed.md`.

- [ ] `quad-base/Tween.luau`(값 타입만 — `Tween(opts)` 팩토리, `isTween`/
      `TweenTag` Brand, `Value: T` plain만 받고 State 재귀 없음)
- [ ] `Handlers/Property.luau`에 `isTween(realv)` 분기 추가(기존
      `Handlers/Tween.luau` 독립 핸들러는 폐기) + 3-상태 릴레이션 슬롯
      (`RobloxTween | true | nil` — `nil`=첫 세팅, `true`=세팅됨/트윈
      없음, 엔진 객체=활성 트윈) + 첫 세팅은 무조건 애니메이션 없이
      스냅(hasBeenSet 억제) + 활성 트윈 정리는 override 정책 완료 후에만
      새 값 세팅(순서 뒤바뀌면 트윈 다음 프레임이 방금 세팅한 값을 덮어씀)
- [ ] override 정책 4가지(기본 Cancel/Override/Delete-restart/
      Move-to-end-restart) 중 기본값 외 옵션 키 이름/시그니처 확정,
      Tween→plain 전환에 5번째 옵션이 필요한지 확인
- [ ] `research/tween-plan.md` "트윈 옵션 값 모양" 확정(TweenInfo 그대로
      vs 편의 필드+기본값 — 소견은 후자)
- [ ] `quad-roblox/Animate.luau`(편의 콤비네이터 — `:Apply`로 체이닝,
      `useTween` 우회는 이걸로 자연히 커버되어 별도 옵션 필드 불필요,
      정확한 시그니처는 M11에서 확정)
- [ ] `initValue`(진입 애니메이션) 필요성 재검토 — 필요해지면 hasBeenSet
      억제 동작과의 상충부터 풀 것(`research/tween-plan.md` 참고)

## 특정 마일스톤에 안 묶이고 병행 가능

- [ ] 용어 정리 스윕 — `State`/`DI`/`Slot` 등(`PerInstanceState`는 `Relate`로
      대체·해소됨) — `.claude/question.md` 1번, 최종 이름 확정되는 대로
      아무 시점에나
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
