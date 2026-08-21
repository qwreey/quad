# ROADMAP.md

quad-v2 구현 단계 실행 계획. 설계 근거/아키텍처 자체는 여기 안 옮겨적음 —
`.claude/base/`가 소스, 여긴 **순서와 진행 상황**만. 마일스톤 시작할 때
체크박스를 세분화해서 늘려도 되고, 끝나면 체크만 하면 됨 — 살아있는 문서.

**2026-08-04 세션에 준비만 해둔 상태로 신설, 이후 여러 세션에 걸쳐 설계가
확정될 때마다 각 마일스톤 체크박스가 계속 갱신돼왔음.**

> **✅ [2026-08-19 기준] M0 스파이크 4개 전부 통과, M1 스캐폴딩도 대부분
> 완료(quad-base/quad-roblox 폴더+pesde.toml, 루트 default.project.json/
> .luaurc, mock 테스트 하네스, `New()`/`RunInit`/`AddPlugin` 골격 — 아래
> M0/M1 체크박스 참고). 다음은 M2(디스패치 엔진) 착수.** M1 착수 도중
> wally→pesde 전환이 확정돼(`base/project-setup-plan.md`) M1 체크박스의
> `wally.toml` 표기도 `pesde.toml`로 정정. 부수로 M3가 의존하는
> `quad-types`/`type-version-check` 두 워크스페이스 멤버도 이 과정에서
> 먼저 신설됨(`base/quad-types-plan.md`).

> **✅ [2026-08-13 열네 번째 세션] M0 착수를 막던 결정이 전부 해소됐음.**
> `0-Y`(13차 세션), `0-Z`(Attribute 이름 소유권)/`0-A`(재디스패치 하강
> diff, 둘 다 14차 세션) 확정·반영 완료 — `.claude/question.md`의 최우선
> 칸이 비었습니다.
>
> **다만 M0 착수 전에 반드시 읽을 구현 규약 두 개**:
> `.claude/base/typing-limits.md`(0-Y의 산물 — 파생 State마다 결과 타입을
> 명시 주석으로 바인딩)와 `.claude/base/dispatch-core-plan.md`(0-A/0-Z의
> 산물 — 하강 diff 재디스패치, 3-인자 `retractFrom`, Handler 작성
> 체크리스트 8개, `HANDLER_PRIORITY_FALLBACK`, 주입되는 엔진 op).
> (특히 "파생 State를 만드는 자리마다 결과 타입을 명시 주석으로 바인딩"과
> 7번 체크리스트).

## M0 — 스켈레톤 + 기술검증 (스파이크, "진짜" 마일스톤 아님)

최종 소스 트리를 그대로 만들기 전에, 지금까지 **추론만으로 확정하고 실제
Luau 코드로 부딪혀본 적 없는 세 가지**를 던지는 코드로 검증하는 단계 —
`.claude/base/` 감사에서 나온 결론(2026-08-04). 여기서 뭔가 어긋나면
`architecture.md`/`bind-system-plan.md` 등을 이 시점에 고치는 게 정상 —
실패가 아니라 이 단계의 목적.

- [x] Store/State push-invalidate → pull-recompute propagation을 실제로
      짜보기(다이아몬드 의존성 케이스 포함 — **[2026-08-14 정정]** 확인할
      것은 "이미 invalid면 전파 중단되는지"가 **아니라** 그 반대:
      **emit은 자기 invalid 상태와 무관하게 항상 전파되고**, 중복 재계산은
      `:Get()` 시점 캐시로만 막히는지. 특히 `:Get()`을 안 부르는
      `Observer`가 매 변경마다 계속 울리는지 — 옛 모델에선 두 번째부터
      침묵했음(`archive/invalidate-dedup-propagation-reversed.md`).
      스파이크 `05-store-state-diamond-propagation.luau`는 **[2026-08-19
      재작성 완료, `done/`]** 현행 모델("emit은 항상 전파 + `:Get()`
      시점 캐시로만 dedup")로 재검증 통과)
- [x] Source가 State를 구조적으로 만족하는 제네릭 타입(`:Compute<U>(self:
      Source<T>, ...) -> State<U>`류, self 타이핑 + State 참조 혼합)이
      Luau 솔버에서 안전하게 추론되는지 확인(2026-08-06 세 번째 세션,
      `base/source-state-plan.md` "Source가 State를 만족함" 절 — `State<T>`가
      `Source`를 참조하지 않는 단방향 의존으로 두면 위험한 상호 재귀는
      피할 수 있어 보이나 실제 검증 전엔 확정 아님. **[통과]**
      `luau-test/done/08-type-source-satisfies-state.luau` — 핵심 케이스
      통과, 잔여 자기재귀 케이스는 Luau 한계로 별도 확정
      (`base/typing-limits.md`), 설계 영향 없음)
- [x] `process`(+반환 retractor 클로저) 재귀 재-process 디스패치를 실제로
      짜보기(store-bind 핸들러 하나 + `isHandlable` 우선순위 스캔 포함 —
      `luau-test/done/03-recursive-store-bind-dispatch.luau` 통과)
- [x] props 순회의 "배열 파트 먼저, 해시 파트 나중" 두 패스 계약이 실제
      Luau 테이블에서 관찰한 대로 동작하는지 확인, `PreRef` pre-pass +
      일반 `Ref`의 위치 기반 순서까지 최소 스파이크로 검증
      (2026-08-07 세 번째 세션, `base/ref-plan.md` "`phase` 옵션
      폐기 → 위치로 표현, `PreRef` 신설" 절) — **PreRef pre-pass의 소진은
      `nil`이 아니라 실재하는 센티널로(2026-08-07 열 번째 세션 정정, 사용자가
      Luau REPL로 반례 제시 — 키가 듬성듬성해지면 순회가 index 순서를
      전혀 안 지킴), 이 경로는 nil-hole 위험이 아예 없도록 설계됐으므로
      "구멍 있는 테이블 순회" 자체를 검증할 필요는 없어짐(같은 절 "왜
      `nil`이 아니라 `None`인가" 참고). **[정정, 2026-08-14 두 번째 세션]
      소진 값은 이제 `None`이 아니라 전용 센티널 `ProcessedPreRef`** —
      정상 두 패스가 그 자리를 `ProcessedPreRefHandler`로 매치해
      `Dispatch.setLength(0)`/`setOffsetSource(None)`을 등록하도록 재설계됨
      (`base/ref-plan.md` "PreRef" 절, `base/dispatch-core-plan.md`
      "Length/Offset" 절) — 아래 `PreRef` pre-pass/동적 경로 가드
      체크리스트 항목도 이 값으로 스파이크할 것.
- [x] `props.Modifier`/`props.Ref` named-parameter로 받는 컴포넌트 하나 작성,
      `export type Params = {...}`로 타입 체크되는지 확인
      (`component-composition-plan.md` 최종 결론 1번) — **`props.Modifier or
      None`/`props.Ref or None` 관용구(2026-08-07 열 번째 세션 확정,
      `component-composition-plan.md` "필수 관용구" 절)로 nil-hole을 막는
      케이스를 반드시 포함할 것 — caller가 Modifier/Ref를 안 넘겨도
      `or None`이 항상 non-nil을 보장하므로 `{nil, ref, child}`류 리터럴
      구멍 자체가 안 생김(`research/pre-implementation-audit.md` 1-5).
      M0에서 검증할 것은 "어떻게 막을지"가 아니라 이 관용구가 실제로
      타입 체크/런타임 양쪽에서 문제없이 동작하는지** —
      `luau-test/done/06-component-boundary-nil-hole-props.luau` 통과
- [x] 위 과정에서 소스 트리/메커니즘 문서에 고칠 부분이 생기면 그 자리에서
      `.claude/base/` 갱신 — 실제로 여러 차례 발생, 그때마다 반영됨(각
      스파이크 항목의 "정정"/"재작성" 표시가 그 기록)

**통과 기준**: 위 항목들이 Luau에서 자연스럽게 짜이는 게 확인되면 M1
진행 — **[2026-08-19] 전부 통과, M1 진행 중**(개수는 `luau-test/STATUS.md`가
소스, 여기서 세지 않음).

## M1 — 실제 스캐폴딩

- [x] `quad-base/`, `quad-roblox/` 폴더 + 각 `pesde.toml`(**[2026-08-19
      정정]** 이 체크박스는 원래 `wally.toml`이라 적혀 있었으나 같은 날
      wally→pesde 전환이 확정돼 `pesde.toml`로 정정 —
      `base/project-setup-plan.md` 참고. `quad-roblox/src`는 아직 빈
      폴더 — 실제 소스는 M5)
- [x] 루트 `default.project.json`, `.luaurc`(`architecture.md` "구현 착수:
      소스 트리 구조 확정" 절 그대로)
- [x] quad-base용 최소 mock 테스트 하네스(Vide `test/mock.luau` 선례, 순수
      `luau` CLI, `architecture.md` "테스트 전략" 절 참고) —
      `quad-base/test/mock.luau` + `smoke.*.luau`, 전부 PASS
- [x] 최상위 `New()`/`InitXxx(module)` 팩토리 체이닝 골격 — 각 서브시스템
      Init이 `module`을 파라미터로 받아 뮤테이션, `Relate` 기반 인스턴스별
      멱등 가드(`base/module-lifecycle-plan.md`의 "New()의 내부 구성" 절
      그대로, 2026-08-19 확정) — `quad-base/src/init.luau`의 `New()`/
      `RunInit`/`AddPlugin`으로 구현·smoke 테스트 검증 완료
- [x] 이 시점부터 `.claude/qa-request/`/`.claude/archive/` 폴더 실사용
      시작(**[2026-08-19 확인]** 두 폴더 모두 M1 이전인 설계 단계부터
      이미 쓰이고 있었고 — QA 라운드/역전 결정 기록 — M1 착수 이후에도
      계속 같은 방식으로 쓰이는 중이라 "실사용 시작"이라는 조건은 사실상
      항상 충족돼 있었음)

## M2 — 디스패치 엔진

> **✅ [2026-08-13 열네 번째 세션] 재디스패치 모델 교체 완료 — 아래
> 체크리스트는 새 모델("하강 diff") 기준으로 갱신됐습니다.** 래핑 핸들러의
> 선행 `retractFrom`은 폐기됐고, `Dispatch.process`가 슬롯의 `handler`를
> 먼저 비교해 (같으면 그 자리 클로저에 새 값을 넘기고 자기 `process`
> 재호출, 다르면 그 자리부터 전량 철거) 처리합니다. 정본은
> `.claude/base/dispatch-core-plan.md`(같은 세션에 `bind-system-plan.md`에서
> 분리 신설), 뒤집힌 옛 모델은
> `.claude/archive/dispatch-hintvalue-model-reversed.md`.


- [ ] `Dispatch/init.luau` — `Dispatch.getHandler(inst,k,v): Handler?`(순수
      스캔, `isHandlable`+`priority`) / `Dispatch.process(inst,k,v,index)`
      (오케스트레이터: getHandler → **그 인덱스의 기존 핸들러와 비교** →
      같으면 그 자리 클로저에 새 값을 넘기고 같은 핸들러의 `.process`로
      자리 교체, 다르면 `retractFrom` 후 새로 설치. 반환값이 `nil`이면
      즉시 error) / **3-인자** `Dispatch.retractFrom(inst,k,index)`
      (아래 항목) / `Dispatch.addHandler(handler)`(레지스트리 등록,
      quad-roblox가 팩토리 뮤테이션 시점에 호출) / `Dispatch.drive(inst,
      flattened)`(배열→해시 두 패스 순회하며 각 `(k,v)`에
      `Dispatch.process(inst,k,v,1)` 호출 — `dispatch-core-plan.md`의 `None`
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
      `isRef(v) and not isPreRef(v) and not isPostRef(v)`로 명시적으로
      좁혀야 함(**[2026-08-14 아홉 번째 세션]** `PostRef` 확정으로 제외
      항 하나 추가, `isPostRef`도 `isRef` 아래 형제로 신설). `isModifier`는
      여전히 단순 항등, 상위 개념 없음. **[정정, 2026-08-11 아홉 번째
      세션]** `isAttribute` 하나였던 게 `isAttributeKey`(단일 키 특수 키
      predicate, 해시파트 `k`를 판별)와 `isAttribute`(그룹 값 predicate,
      array-part `v`를 판별, `isTag`와 같은 결)로 분리됨 — 그룹
      `Attribute(...)` 프리미티브 신설로 같은 이름이 서로 다른 두
      대상(키 vs 값)을 가리키게 돼서 갈라짐, `base/attribute-plan.md`
      참고) 전부의 기반. `isNone`만 예외로 레지스트리 없이 `x == None`
      항등 비교 — `brand-plan.md`의 `Brand` 절, 2026-08-07 여덟
      번째 세션 신설)
- [ ] `Relate.luau`(전체가 quad-base, 순수 Lua — `base/relate-plan.md`) —
      `Relate()` 비싱글톤 생성자, `:SetWeak`/`:GetWeak`/`:SetStrong`/`:GetStrong`.
      `inst`(첫 인자)는 항상 weak, `StrongMap`/`WeakMap` 서브테이블은 lazy
      생성(첫 `Set` 호출 시에만), `WeakMap`은 공유 메타테이블(`{__mode="v"}`)
      재사용 — 구 `base.perInstanceState(inst)`/`PerInstanceState.luau`를
      대체(2026-08-08 세션 신설).
- [ ] `LifetimeHandle.luau` **인터페이스만**(`bindLifetime(inst,value)`/
      `unbindLifetime(value)`/`canBound(value)`/`canExecute(value)` 탑레벨
      함수 타입 계약, 실 구현 없음 — quad-roblox 실 구현은 M8) — 원래
      M8에만 있었으나 M4(StoreBind의 `Connected` 확인)/M6(Slot의
      `canExecute`)이 이미 이 인터페이스를 전제로 서술돼 있어 로드맵
      순서가 역전돼 있었음(`pre-implementation-audit.md` 우선순위1-9,
      `question.md` 2번 — 2026-08-07 네 번째 세션에 반영).
      **[정정, 2026-08-14 다섯 번째 세션] `unbindLifetime`/`canExecute`는
      `inst`를 안 받는다** — 옛 2-인자 시그니처(`(inst, value)`)는 오염이었음.
      `bindLifetime`이 바인딩 시점에 `inst`의 gcconn 참조를 `value` 쪽
      `Relate`로 복사해두므로 "지금 실행돼도 되는가"를 `value` 하나로 물을 수
      있고, `canExecute`의 실제 호출부(State 전파 루프)엔 `inst`가 없어서
      2-인자로는 호출 자체가 불가능했음. 판정은 (a) 복사된 gcconn의
      `.Connected` 또는 (b) Observer/Effect의 `.Subscribed` 둘 중 하나 —
      **`.Subscribed`는 전역 `:Subscribe()` 전용 필드라
      `bindLifetime`/`unbindLifetime`이 읽지도 쓰지도 않음**. 역전 원문은
      `archive/canexecute-inst-arg-reversed.md`.
      **`unbindLifetime(value)` 추가(2026-08-09 여섯 번째 세션)** —
      `inst` 전체 죽기 전에 특정 값 하나만
      조기 해제(`Dispatch.setLength`가 State 재등록 시 이전 Observer를
      정리하는 데 씀), gchold 내부 구조를 호출부가 몰라도 되게 캡슐화.
      `bindLifetime`/`unbindLifetime`/`canBound`/`canExecute` 넷 다
      네임스페이스 없이 탑레벨 함수로 export(`Dispatch.xxx`류 시스템
      네임싱과 구분, `isState`/`isObserver`와 같은 1급 프리미티브 취급) —
      `base/lifecycle-pattern.md`의 "`bindLifetime`/`canBound`/
      `canExecute`/`unbindLifetime` — 확정" 절 참고. **이중 바인딩 금지
      게이트는 `canBound`**(`canExecute`는 emit 전파 게이팅 전용 —
      **[2026-08-14 열한 번째 세션] `canBound`가 별도 진입점으로 재도입되어
      다시 갈라짐, 판정 로직은 공유하는 비공개 헬퍼 하나 — M3 체크박스
      참고**), children 배열 leaf 부착이 실제로는 `bindLifetime` 호출이라
      이 게이트를 그대로 탐
- [ ] `Dispatch.setLength(inst,i,len:number|State<number>)`/
      `Dispatch.setOffsetSource(inst,i,offset:Source<number>|None)` —
      array part 형제 순서 보장(Length/Offset 누적합→`LayoutOrder` 리액티브
      바인딩), array part 모든 number 인덱스에 대해 둘 다 호출 필수(생략
      UB, Handler 구현체 작성자만의 계약) — `recompute`는 leaf-lifetime
      경로(`bindLifetime`/`unbindLifetime`)로 등록, `:Subscribe()` 아님
      (2026-08-09 여섯 번째 세션, `base/dispatch-core-plan.md` "Length/Offset"
      절 — `base/slot-plan.md` "여러 Slot이 섞일 때 순서 보장" 해소).
      **[2026-08-18 구현 전 QA 2라운드 후속] `bk.N≥2`인 자리가 처음
      채워지는 동안 크래시하던 경로(`RC-1`)는 owner별 `Blocker` 게이팅으로
      해결됨** — `setLength`/`setOffsetSource`가 배치 등록 중엔
      `recompute`를 미루고 배치가 끝나면 명시적으로 한 번만 돎, 상세는
      `base/dispatch-core-plan.md`의 "배치 등록을 안전하게 만드는 Blocker
      게이팅" 절. **[정정, 2026-08-18 구현 전 QA 3라운드] 그 크래시 자체는
      `bk.N`의 정의(그때그때 실제 개수로 확정, 같은 문서 "저장 위치" 절)가
      바뀌며 사라졌음** — 지금 이 두 함수 구현이 여전히 `Blocker`
      (`getBlocker`/`:On()`/`:IsOn()`/`:OffWithoutEmit()`)를 호출하는 이유는
      크래시 방지가 아니라 배치 등록 비용(O(N²)→O(N)) 절감. **다만
      호출하는 건 여전히 사실이라 — `Blocker.luau`는 아래 M3 체크박스에
      있는데 이 항목은 M2 소속이라, 로드맵 순서대로면 M2가 아직 없는
      `Blocker`를 참조하게 됨.** M2 착수 전 `Blocker`의 최소 표면
      (`On`/`Off`/`IsOn`/`OffWithoutEmit`)을 M3보다 먼저(또는 M2와 병행)
      만들 필요가 있는지 사용자 판단 필요 —
      `qa-request/pre-implementation-qa-round3.md`의 "ROADMAP.md 마일스톤
      정합성" 절.
- [ ] 핸들러 계약 검증: `process`가 retractor 클로저를 **반환하지 않는**
      핸들러를 등록하면 리뷰/린트에서 걸러내기(정리할 게 없어도 항상
      `function() end`를 반환 — `Dispatch.retractFrom`이 nil 체크 없이
      호출, `base/dispatch-core-plan.md` "핸들러 계약" 절, 2026-08-08 세션
      / **2026-08-13 다섯 번째 세션에 별도 `retract` 필드가 `process`
      반환값으로 합쳐지며 대상만 바뀜**)
- [ ] 우선순위 동률/매치 실패 처리(2026-08-12 열일곱 번째 세션 확정,
      `base/dispatch-core-plan.md` "우선순위 동률/매치 실패 처리" 절) —
      `HANDLER_PRIORITY_HIGH`/`_NORMAL`/`_LOW`/**`_FALLBACK`**(base 제공
      핸들러의 기본 밴드 — 백엔드가 평범한 우선순위로 자기 핸들러를
      등록하면 언제나 이김, 2026-08-13 열네 번째 세션 신설) 등 목적별 상수,
      매치 실패(`isHandlable`을 만족하는 핸들러 없음)는 `Brand`+`typeof(v)`
      출력 후 즉시 error(provider 초기화 확인 안내 포함 — provider
      미주입 상태도 이 경로로 자동 커버, `pre-implementation-audit.md`
      1-3/1-4), 핸들러 등록/정렬 시점 동률 감지 print 경고 +
      `Dispatch.listHandlers()` 디버그 유틸. **[2026-08-18]** 동률 경고는
      무조건 찍지 않고 **모듈 표면의 `Quad.debug`(boolean, 기본 `false`)가
      참일 때만** — `Quad.debug` 자체가 이번에 신설된 새 공개 표면이다
      (`base/module-lifecycle-plan.md`의 "모듈 표면의 디버그 플래그" 절)
- [ ] `Dispatch/Leaf.luau` — `(i:number, v=Ref/Observer/PreRef/PostRef)` children-array
      leaf 매칭 Handler, `StoreBind.luau`와 같은 층위(범용/엔진무관) —
      quad-base 소속으로 확정(2026-08-08 두 번째 세션, `base/
      dispatch-core-plan.md` "Dispatch는 프리미티브가 아니다" 절)
- [ ] `chains`(Relate 기반, `{[inst(weak)]={[k]={[index]={handler, retractor}}}}`
      — **재귀 깊이 인덱스 → (담당 핸들러, 그가 반환한 retractor 클로저)**) +
      **3-인자** `Dispatch.retractFrom(inst,k,index)` — 재귀 재-dispatch
      (StoreBind/NoneHandler)의 정리를 다단 체인까지 정확히 전파(2026-08-08
      신설 → 2026-08-13 다섯 번째 세션 인덱스화 → **같은 날 열네 번째 세션
      하강 diff로 전면 교체**, `base/dispatch-core-plan.md` "Dispatch 체인"
      절, `pre-implementation-audit.md` 1-2번 "이전 핸들러 추적" 항목 해소).
      **구현 시 반드시 지킬 것**:
      - **재디스패치는 하강 diff** — 래핑 핸들러는 선행 `retractFrom`을
        부르지 않고 그냥 `Dispatch.process(inst,k,realv,index+1)`. 비교는
        `Dispatch.process` 안에서: 슬롯의 `handler`가 같으면 그 자리
        클로저에 새 값을 넘긴 뒤 같은 핸들러의 `process`로 자리 교체,
        다르면 `retractFrom(inst,k,index)` 후 새로 설치
      - `chains:SetStrong(inst,k,list)`는 `handler.process` 호출 **전에** —
        뒤에 두면 재귀 위임이 자기 테이블을 만들었다가 바깥이 덮어써
        하위 retractor가 통째로 유실됨(2026-08-13 감사에서 잡힌 버그)
      - 새 자리를 여는 (B) 분기에선 `handler.process` 호출 전에 no-op
        점유 마커를 박아 `list`를 구멍 없는 시퀀스로 유지(hole 있는
        테이블의 `#`는 Lua가 보장 안 함)
      - `process`가 `nil`을 반환하면 (A)/(B) 양쪽에서 즉시 error
      - 다른 키로 위임할 땐 항상 `index=1`, 같은 키 재귀는 `index+1`;
        `Dispatch.drive`의 진입도 항상 `1`
      - **소유권 충돌 감지는 Dispatch의 일이 아님**(옛 점유 error 폐지) —
        필요한 도메인이 직접(Attribute 이름 claim, M10)
- [ ] mock 대상 테스트

## M3 — Store/State/Source

- [ ] `Source.luau`/`State.luau`/`Store.luau`
- [ ] **[2026-08-18 신설]** `store:GetDynamic<<T>>(name): Source<T>` — 런타임에
      이름이 정해지는 동적 키의 정식 창구(옛 `store "key"` 문자열 커링은
      기각). **⚠️ 콜론 메소드로 두면 `__index`가 고정 메소드 테이블을 먼저
      확인해야 하고 `GetDynamic`이 예약 키가 됨** — 탑레벨 함수로 둘지
      아직 미결(`base/store-plan.md`의 "타입 추론 문제" 절, `question.md` 3번)
- [ ] **State 전파 루프 — 구독자는 weak, 발화마다 `canExecute` 게이팅**
      (2026-08-14 다섯 번째 세션 확정, `base/lifecycle-pattern.md`의 "실제
      호출부 — State 전파(`emit`)가 `canExecute`로 게이팅한다" 절) —
      State는 구독자(Observer의 emit 클로저)를 **weak로만** 담고, 살려두는
      책임은 `gchold`(leaf) 또는 전역 `Subscribed` 테이블(전역)에 있음
      (어디에도 안 묶인 Observer는 GC되어 목록에서 자연히 빠짐). 발화 시
      각 구독자에 대해 `canExecute(observer)`가 거짓이면 **그 구독자만
      조용히 건너뜀**(no-op) — 이게 `canExecute`의 유일한 실제 호출부이고,
      `inst`를 인자로 받을 수 없는 이유(State는 자기가 어느 Instance에
      걸렸는지 모름). `state:Observer(fn)`의 "등록 즉시 1회 실행"은
      `bindLifetime` 이전에 동기적으로 일어나므로 이 게이팅과 무관
- [x] `store.key` dot-access 타입 추론 확인 — Luau `type function`
      (`WrapStore`/`ProcessStoreType`)으로 `Store<T>`가 `T`의 각 필드를
      `Source`로 감싼 레코드 타입을 합성 가능함을 확인(2026-08-12 열일곱
      번째 세션, `base/typing-limits.md` §5) — **[2026-08-15 실측 완료]**
      `luau-test/done/16-type-store-key-typefunction.luau` 통과(원인은
      설계 문제가 아니라 `types.newfunction` API 버전 드리프트였음)
- [ ] `:Compute(fn, ...)` — trailing args로 추가 의존성 직접 받는 sugar
      (2026-08-11 세션, `base/source-state-plan.md` "`:Compute(fn, ...)`"
      절) — `:With(...):Compute(fn)` 체인과 달리 노드 1개(Compute 노드
      자신에 구독만 추가)로 끝나야 함, 새 노드 생성 없이 구현되는지 M0/M3
      스파이크에서 확인. `Effect`/`Observer`는 대칭 sugar 없이 `:With` 명시
      유지(의도적 비대칭, 같은 절 참고)
- [ ] trailing deps를 `fn`에 lazy positional 인자로도 노출(`fn(self,
      previous?, dep1, ..., depN)` — 순서는 Luau 값 레벨 `...`가 파라미터
      리스트 맨 끝이어야 하는 것과 같은 이유로 `previous?`가 deps 팩
      **앞**에 와야 함, 2026-08-11 후속 세션 제안 → 같은 날 세 번째
      세션에 순서 정정, `base/source-state-plan.md` "trailing deps를 fn에
      lazy positional 인자로도 노출" 절) — 방향/순서는 확정,
      `luau-test`의 `15-type-compute-trailing-deps-typepack.luau`로
      이형 다중 deps를 제네릭 타입 팩으로 표현 가능한지만 실측 필요(안
      되면 동종 타입 dep 1개로 한정)
- [ ] `Blocker.luau`(`base/blocker-plan.md` 참고 — 여러 Source를
      한꺼번에 바꿔도 파생값 재계산/재대입이 한 번만 되게 하는 primitive,
      State와 밀접히 연관돼 있어 같은 마일스톤에서 개발)
- [ ] `state:Apply(factory)`(`base/source-state-plan.md` "`state:Apply(factory)`"
      절, 2026-08-07 일곱 번째 세션) — `factory(self)`를 체이닝 문법으로
      부르는 순수 설탕, `factory: (State<T>) -> U): U`로 열린 타입. Source도
      기존 `:With`/`:Compute` 델리게이션에 얹혀 자동 포함
- [ ] `state:Observer(fn)` — children 배열 leaf 참가자, **등록 즉시 1회
      실행 확정**(`base/source-state-plan.md`의 Observer 절), `isObserver`
      판별자, canExecute 게이팅, `:Subscribe()`/`:Unsubscribe()`. **동적
      경로 가드**(`{priority = HANDLER_PRIORITY_FALLBACK, isHandlable = v
      is Observer, process = error(...)}`, `k` 타입 안 가림, 2026-08-14
      열한 번째 세션 — `PreRef`와 같은 패턴)도 같이 등록
- [ ] `Effect(fn, state?)`(`base/effect-plan.md`) — `state` 생략 시 설치
      1회+leaf 사망 시 확정 정리, `state` 지정 시 내부적으로
      `state:Observer(...)`를 조합해 재실행+cleanup 체이닝(React
      `useEffect` 동형). Observer 구현 이후에 착수(의존 관계).
      `EffectHandle:Subscribe()`/`:Unsubscribe()`도 추가(leaf 없이 쓰는
      모듈/스크립트 레벨 Effect) — `:Unsubscribe()`는 Observer와 달리
      마지막 cleanup을 1회 트리거해야 함(2026-08-07 일곱 번째 세션).
      **동적 경로 가드**도 Observer와 같은 패턴으로 등록(`base/effect-plan.md`
      "동적 경로 가드" 절, 2026-08-14 열한 번째 세션)
- [ ] Observer/Effect 이중 바인딩 금지 — `canBound(value)` 게이트로
      `:Subscribe()`(전역)와 `bindLifetime`(inst-scoped, leaf 부착도
      내부적으로 이걸 호출)이 동시에 걸리면 즉시 `error`(`base/source-state-plan.md` "이중 바인딩 금지" 절, 2026-08-07 일곱 번째
      세션 신설, 2026-08-09 여섯 번째 세션에서 "leaf 부착=bindLifetime
      호출"로 정정 — 진짜 독립 경로는 둘뿐).
      **[2026-08-14 다섯 번째 세션에 별도 predicate `canBound(handle)`을
      폐기하고 `canExecute` 하나로 합쳤다가, 같은 날 열한 번째 세션에
      다시 갈라짐]** — "지금 묶어도 되는가"(bound 문맥)와 "지금
      발화해도 되는가"(execute 문맥)는 호출부의 질문이 다르고
      **[2026-08-18 구현 전 QA 정정] 판정값도 같은 게 아니라 서로의
      부정**이라(`canBound(v) == not canExecute(v)`, 게이트는 항상
      `if not canBound(v) then error(...)`), `Ref` 이중 배치
      방지(`question.md` 0-W)를 계기로 `canBound`가
      별도 진입점으로 재도입됨 — 판정 로직(비공개 `isBoundAlive` 헬퍼)은
      공유해 코드 중복은 없음. **이 절이 쓰는 게이트는 이제 `canBound`**
      (emit 전파 게이팅 전용 `canExecute`가 아님). `.Subscribed` 필드가
      leaf 경로와 무관하다는 것, leaf 생존 판정을 `bindLifetime`이 `value`
      쪽 `Relate`에 복사해둔 gcconn으로 하는 것은 안 바뀜 — `base/
      lifecycle-pattern.md`의 "`canBound` vs `canExecute`" 절, 역전 경위는
      `archive/canexecute-inst-arg-reversed.md`. 부수 효과로 **바인딩이
      죽은 뒤(`Destroy`/`unbindLifetime`)의 재사용은 게이트를 통과**
      (살아있는 바인딩만 막는 게 의도, 안 바뀜)
- [ ] mock 대상 테스트

## M4 — 첫 end-to-end 반응형 업데이트

> **✅ [2026-08-13 열네 번째 세션] 재디스패치 모델 교체 완료** — 아래
> 항목은 `base/dispatch-core-plan.md`의 하강 diff 기준으로 읽을 것.


- [ ] `Dispatch/StoreBind.luau`(재귀 재실행 로직, 엔진 무관 — **선행
      `retractFrom` 없이** `Dispatch.process(inst,k,realv,index+1)` 한 줄
      (2026-08-13 열네 번째 세션 하강 diff), 반환 클로저는 자기 Observer
      구독만 해제. `base/dispatch-core-plan.md` "Dispatch 체인" 절)
- [ ] mock 대상으로 "store 값 바꾸면 `process`가 다시 호출된다" +
      "이전 값이 다른 타입이면 이전 `process`가 반환했던 retractor 클로저가
      정확히 불린다" 확인 + **`State<State<T>>`(값이 또 State/Source)가
      인덱스 N/N+1로 안 겹치고 정상 동작하는지**(2026-08-13 다섯 번째
      세션에 UB→정상 지원으로 재정정) + **최초 마운트 직후 첫 재발행에서
      인덱스 2의 retractor가 실제로 불리는지**(위 M2의 `SetStrong` 순서
      버그가 정확히 여기서 증상으로 나타남)

## M5 — quad-roblox 최소 프로바이더

> **⚠️ 구현 관례**: `quad-roblox`의 공개 타입은 지금부터 단일 파일
> (`src/init.luau` 또는 `types.luau`)에 몰아둘 것 — 나중에 필요해지면
> 백로그 `quad-roblox-types`(가칭, `quad-types`와 같은 패턴)로 쉽게
> 분리할 수 있게 하기 위함. `base/quad-types-plan.md`의 "남은 것" 절이
> 소스.

- [ ] `RobloxFactory.luau`(BaseModule 뮤테이션, 재호출 가드) — 진입점
      `QuadRoblox(Quad): QuadRoblox`가 `QuadTypes.CheckedQuad<T, Pattern>`으로
      주입받은 quad-base 버전을 확인(`base/quad-types-plan.md` 참고)
- [ ] `D/init.luau`(제네릭 생성자 `New` + 생성기가 찍는 정적 별칭 필드 — **[2026-08-18]** 범위는 "GUI에 쓰이는 모든 인스턴스", 이벤트 필드의 콜백 타입까지 생성, `base/bind-system-plan.md`의 "인스턴스 생성 / 이벤트 네이밍 인체공학" 절)
- [ ] `Handlers/Property.luau`, `Handlers/InstanceChild.luau`
- [ ] **Instance 생성 시점의 gcconn/gchold 셋업**(2026-08-14 다섯 번째 세션
      확정, 옛 "`bindLifetime` 첫 호출에서 lazy 생성"에서 전환 — `base/
      lifecycle-pattern.md`의 "(0) gcconn/gchold는 Instance 생성 시점에
      만든다" 절) — quad가 만든 모든 Instance에 대해 **핸들러/바인딩 유무와
      무관하게 생성 직후 무조건** `GetPropertyChangedSignal("ClassName")`
      연결(절대 발화 안 함)로 gcconn을 만들고 `gchold[1]=gcconn`,
      `InstData:SetWeak(inst,"gchold"/"gcconn",...)`. **클로저가 `gchold`와
      `inst`를 둘 다 캡처해야 함** — Instance userdata 포인터 동일성을
      고정하는 게 목적이고, 그래야 `inst`를 키로 쓰는 모든 `Relate`
      (`elementOwner`/`nameClaims`/Tag 참조카운트 등)가 성립함. 대가는
      "quad가 만든 Instance는 참조를 놓는 것만으로 회수되지 않고 반드시
      `Destroy`가 필요" — 바인딩이 하나라도 걸리면 어차피 같은 순환이
      생기므로 실질적 신규 제약은 아님
- [ ] 실제 Roblox에서 첫 `Frame{...}` 렌더 확인 — **Studio 작업이라
      `HUMAN_TODO.md` 1번(계정 분리) 먼저 되어야 진행 가능, `SAFETY.md` 준수**

## M6 — Slot

> **✅ [2026-08-13 열네 번째 세션] 재디스패치 모델 교체 완료** — 아래
> "`SlotHandler.process`는 claim 실패 시에도 파괴적 클로저를 반환해야 함"
> 항목은 새 모델에서도 그대로 유효함(체인은 클로저를 early-return
> 여부와 무관하게 항상 소비 — `base/dispatch-core-plan.md`의
> "Handler 작성 체크리스트" 1번). 클로저가 받는 값이 항상 `Slot`이거나
> `nil`임이 계약으로 보장된다는 점만 새로 추가됨.

- [ ] **[2026-08-13 여섯 번째 세션 — 이 세션의 Slot 결정 전부, 구현 전 필독]**
      - **`State<Slot>` 교체 = 파괴가 아니라 언마운트**(`state<Frame>`와 동일).
        비파괴 경로 `unmountSlotTree`를 `destroySlotTree`와 별도로 구현 —
        차이는 딱 둘: 실제 `Destroy()`를 안 하고, 자식 `releaseOwner`도 안 함
        (자식은 계속 그 slot 소유라 통째로 재마운트 가능 = 포탈).
        **쓰는 자리**: `SlotHandler.process`가 반환하는 클로저, 그리고
        `:List`의 `reconcile` 중 **`Owned = false` 설치와 `Detach` 경로**
        (**[재정정, 2026-08-21]** 값 교체는 `Owned = true`면 파괴가 맞다 —
        `updateFn`이 만든 걸 자기 손으로 못 지우기 때문. `state<Frame>`
        의미론은 `Owned = false`가 담당).
        **여전히 파괴인 것**: 명시적 `Remove`/`Clear`/`dispose`, 그리고
        **[재정정, 2026-08-18 구현 전 QA] `:List`에서 `updateFn`이
        `nil`/`None`을 반환하거나 키가 데이터에서 사라진 경로**(2026-08-13의
        "reconcile은 전부 비파괴" 일반화가 `:List`엔 안 맞았음 —
        `base/slot-plan.md`의 "`nil` 리턴은 파괴가 기본" 절이 소스).
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
- [ ] **`dispose(value: Slot | Instance)`** — 대상이 아직 어느 트리에 의해
      살아있길 요구되면 **파괴를 거부하고 즉시 error**(떼어내주지 않음 —
      떼는 건 `Set`=언마운트의 몫). 엔진은 `Destroy`/`Clear`에 에러를 안
      내지만 quad 자료구조가 깨지므로, quad가 관리 중인 값을 안전하게
      지우는 유일한 경로. 마운트 위치는 `elementOwner`가 이미 알고 있어
      새 부기 불필요. `isSlot(value)`면 그 경로, 아니면 백엔드가 주입하는
      `disposeInst(inst): ()`(`addTag`/`removeTag`/`setAttribute`와 같은
      "base 소유+op 주입" 패턴, quad-roblox는 `inst:Destroy()`)로 위임.
      **`Observer`/`Effect`는 범위 밖**(GC-native `bindLifetime`/
      `unbindLifetime`만으로 충분, 트리 부기 없음) — 2026-08-14 열 번째
      세션에 `question.md` 0-B 해소, 정본은 `base/slot-plan.md`
      "`dispose(value)`" 절

- [x] **"여러 Slot이 형제로 섞일 때 순서 보장" 해소**(2026-08-09 여섯 번째
      세션) — `Dispatch.setLength`/`setOffsetSource` 메커니즘, `base/
      dispatch-core-plan.md` "Length/Offset" 절. `Slot.Length: State<number>`도
      이때 확정(CRUD/`:List` 여부 무관 항상 노출, 순서 계산과 "n개 검색됨"
      UI 둘 다 겸함) — 구현 시 이 두 API를 `:List`/CRUD의 `raw*`가 호출.
      **`recompute` 트리거 모델의 크래시(`RC-1`)는 Blocker 게이팅으로
      해결됨**, 위 M2 항목 참고.
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
      error(`Modifier` 필드와 같은 판별 메커니즘 재사용) — `D.InstSlot =
      Slot<<Instance>>`(**[2026-08-18]** `D` 네임스페이스 이름 확정 —
      옛 `question.md` 1번 용어정리 항목은 해소되어
      `archive/question-resolved.md`로 이전됨)가 quad-roblox의 사실상 유일한
      Slot 타입.
- [ ] `Slot:List(data, updateFn, keyFn?)` — 키 기반 동적 컬렉션 재조정,
      `keyFn(item, index) -> key` 생략 시 원본 `data` 배열 위치(raw index)를
      그대로 key로 사용(중간 삽입/삭제 시 identity 보존 안 됨, 캐스케이드
      갱신 — 흔한 업계 관행과 같은 트레이드오프).
      `updateFn<UD=any>(item, index: number, offset: Source<number>, prev: T?,
      userdata: UD?): (T|nil, UD?)`가 **매 reconcile 사이클마다 호출**
      (filter/toggle 지원 — 첫 반환값 `nil` 시 실제 파괴, `Visible` 토글
      아님, 200+ 항목에서 lazy하지 않은 문제 회피), `prev` 그대로 반환하면
      저비용 재사용 경로.
      **[2026-08-18 신설, 이름 2026-08-19 확정, 2026-08-21 보존 주체 정정]
      `Detach` 반환 경로** — `updateFn`이 `Detach`를 반환하면 그 자리는
      **파괴하지 않고 `Parent = nil`로만 내려와** Slot에서 빠진다.
      **보존 주체는 `userdata`가 아니라 `slot._detached` 필드**(Slot 필드여야
      `destroySlotTree` walk가 닿고 소유권도 유지됨 — `ud`로는 최종 처분이
      불가능). reconcile이 `prev`로 그대로 돌려주므로 `ud`에 담을 필요 없이
      **그대로 반환하면 재마운트**되고, 이미 detach 상태에서 또 `Detach`면
      **nop**. 언마운트는 소유권을 유지하는 `rawDetach`를 씀(`rawUnmount`
      아님). `Instance.new`/`Destroy` 비용을 아끼는 filter용 경로. 공개
      표면은 `None`과 같이 패키지 최상위 export(`base/slot-plan.md`의
      "Detach된 요소는 `slot._detached`가 보유한다" 절).
      **[2026-08-21 해소] "키가 사라졌을 때 홀드 중이던 요소의 처분"은
      `KeyGone` 센티널로 확정** — `updateFn(KeyGone, 0, offset, prev, ud)`로
      한 번 더 물어 처분을 받고, owner가 죽으면 `mountSlotTree`가 건
      `Effect`가 `_detached`를 전부 정리한다(같은 문서의 "`KeyGone`" 절).
      **`Owned` 옵션 신설** — `:List`/`:Single`의 설치 시점 플래그(기본
      `true`), `false`면 어떤 경로로도 파괴하지 않고 언마운트만(사용자가
      `state`에 담아 넘긴 요소용, `Slot:Add(state)` sugar가 이걸로 설치). 파라미터 순서는 반환값 순서(`prev`류 먼저,
      `userdata`류 나중)와 맞춤(2026-08-11 세션 정정, 원래 `userdata`가
      `prev`보다 앞이었음).
      **`updateFn`의 `index`는 `keyFn`의 raw `index`(원본 `data` 배열
      위치)와 다른 값** — "이번 사이클에 살아남으면 차지할 압축된 마운트
      위치"(`candidateIndex`, filter로 압축됨), `key`와도 무관(순서/레이아웃
      전용, 식별 목적 아님) — 문서화 시 셋(원본 raw index/`key`/`updateFn`의
      `index`)을 혼동하지 않게 주의. **`offset`은 `Slot.Offset`을 그대로
      전달**(형제 Slot/정적 자식 누적합, `base/dispatch-core-plan.md`의
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
      2026-08-11 세션 추가 확정, `base/slot-plan.md` "`Slot:List(data, updateFn, keyFn?)`" 절)
      구현.
      **`data:Observer(fn)` 구독은 `:List()` 호출 시점이 아니라 Slot
      마운트 시점까지 lazy — `Dispatch.setLength`와 같은 패턴으로
      `bindLifetime(inst,observer)`(마운트 이후 `:List()`가 불리면
      `self._mounted` 확인 후 즉시 활성화)** (2026-08-09 일곱 번째 세션,
      `base/slot-plan.md` "`Slot:List(data, updateFn, keyFn?)`"의 "구독 시점" 절)
      **`Slot.Offset: Source<number>`도 `Slot.Length`처럼 공개 필드로
      노출 — Slot 마운트 시점에 `Dispatch.setOffsetSource`가 등록하는
      바로 그 Source를 `self.Offset`으로도 저장**(2026-08-11 세션,
      `base/dispatch-core-plan.md`의 "Slot.Length와 Slot.Offset은 별개" 절)
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
      **`recompute` 트리거 모델의 크래시(`RC-1`)는 Blocker 게이팅으로
      해결됨 — 위 M2 항목 참고(`base/slot-plan.md` "재귀 메커니즘" 절).**
      **[재설계, 2026-08-21] `attachSlot`은 비공개 재귀 둘로 분해됨** —
      `materializeSlotTree`(부기만, Blocker가 감싸는 건 이제 여기뿐) +
      `mountSlotTree`(물리 `Parent` 대입만, Blocker 불필요), 그리고 그 둘을
      순서대로 부르는 **두 줄짜리 공개 `attachSlot`**(이름/시그니처/호출부
      전부 그대로). 이걸로 "부모에게 알리는 길이가 최종값"과 "부기가 물리보다
      먼저"가 처음으로 **동시에** 만족되고, 배치 밖 재마운트의 부모
      `recompute`가 2회→1회로 준다. 순서 제약이 줄 순서가 아니라 **함수
      경계로 강제**되므로 `RC-1`/`RC-3`/`RC-4` 같은 "줄 순서를 잘못 잡아서"
      나던 버그 클래스가 구조적으로 사라짐. 근거 기록은
      `research/slot-attach-decomposition.md`.
      **관측 가능한 변화 하나**: `Parent` 대입 순서는 그대로지만 물리 마운트가
      "부기 완료 후 일괄"이 되어, `ChildAdded` 핸들러가 볼 때 서브트리 전체의
      `Length`/`Offset`이 이미 최종값이다(옛 코드는 미완성 스냅샷을 보여줬음).
- [x] **`Slot(initial?: {T})` 생성자로 확장** — "인자 없는 빈 생성자로
      확정"을 뒤집음, `:Add` 반복 호출 sugar일 뿐(새 마운트 로직 없음).
      `initial ~= nil`이면(빈 테이블도) 즉시 `_crudUsed = true` — 상태상
      `Add→Remove`와 동일하므로. **`_crudUsed` ↔ `_listed` 상호 배타
      가드 신설** — 기존엔 `:List` 설치 후 수동 CRUD만 막았지 반대(수동
      CRUD 후 `:List` 설치)는 안 막아서 `:List`의 reconcile이 기존
      요소를 모른 채 충돌하는 gap이 있었음(2026-08-11 세션, `base/
      slot-plan.md` "CRUD API 확정" 절).
- [x] **`recompute` off-by-one 버그 수정**(2026-08-11 세션, `base/
      dispatch-core-plan.md` "Length/Offset" 절) — `sum` 누적과
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
      `modifier-plan.md` 9번, `brand-plan.md`의 `Brand` 절, M2의
      `Brand.luau`에 이미 구현돼 있어야 함)
- [ ] 인라인 키/setter로 modifier 필드를 명시적으로 지우는 `None` 센티널
      (이름 확정, `modifier-plan.md` 2-1번, `Peek` 반환 타입에 `None` 추가) +
      이를 `nil`로 재디스패치하는 base 내장 `NoneHandler`
      (`dispatch-core-plan.md`의 `None` 센티널 절, M2 dispatch 엔진의
      "이전 매치 핸들러 추적" 항목과 함께 구현 — `StoreBind` 핸들러와
      동일한 재귀 재디스패치 패턴이라 새 메커니즘 아님) — `None` 센티널
      자체는 확정 완료. **[2026-08-13 열네 번째 세션 갱신]** `NoneHandler`가
      쓰는 재-dispatch 배관에서 **선행 `retractFrom` 호출은 폐기됨** —
      그냥 `Dispatch.process(inst,k,nil,index+1)` 한 줄
      (`base/dispatch-core-plan.md`).
      **[2026-08-18 구현 전 QA 재설계]** `Dispatch.drive`의 `None` 스킵
      분기는 **없앤다**(반응형 값이 내놓는 `None`은 어차피 `process`에
      도착하므로) — `NoneHandler`는 배열/해시 구분 없이 **재귀만** 하고,
      실제 정리는 아래 `NilHandler`가 맡는다
- [ ] **[2026-08-18 신설]** `NilHandler` — `isHandlable`이
      `type(k) == "number" and v == nil`일 때만 매치하는 말단 핸들러.
      `Dispatch.setLength(inst,k,0)` + `Dispatch.setOffsetSource(inst,k,None)`
      등록이 이 핸들러의 일이고 재귀는 안 함(`State<Slot|nil>`도 정상
      동작해야 한다는 사용자 요구, `base/dispatch-core-plan.md`의
      "`NilHandler`" 절)
- [ ] 프로퍼티류 필드 타입에 `T' = T | Tween<T>` 치환 반영(타입 생성
      스크립트가 `Position: UDim2` 자리를 `UDim2 | Tween<UDim2>`로 만들면
      끝, Modifier 런타임/`__index` 자체엔 변경 없음 — `modifier-plan.md`
      10번, 2026-08-10 세션, `base/tween-plan.md`)

## M8 — Ref

- [ ] `Ref.luau`(`.Value` 읽기 전용 필드 + `:Set(value)`/`:Callback(fn)`/
      `:Wait(thread?)`, 전부 self 반환) + `PreRef.luau`/`PostRef.luau`(별도 파일, Ref
      런타임 재사용 + children 배열 전용, Modifier/Store 타입 차단,
      위치 무관 호이스팅 pre-pass — `base/ref-plan.md` "`phase`
      옵션 폐기 → 위치로 표현, `PreRef` 신설" 절 + "API 모양" 절)
- [ ] `(v=Ref)` 매치 핸들러 — children 배열의 숫자 슬롯에 놓인
      `Ref(default)` 인스턴스를 인식해 바인드(별도 `CreatedRef` 래퍼
      없음 — 이름 자체가 폐기됨, 아래 참고)
- [ ] **이중 배치 방지**(`question.md` 0-W, 2026-08-14 열한 번째 세션
      해소) — `RefLeafHandler.process`가 실제 바인딩 분기에서
      `bindLifetime(inst, v)`를, 실제 언바인딩 분기에서 `unbindLifetime(v)`를
      호출. 새 `Relate` 불필요 — `bindLifetime`이 이미 내장한 `canBound`
      이중 바인딩 가드를 재사용하는 것뿐(같은 `Ref`가 이미 다른 자리에
      살아있으면 그 자리에서 즉시 error) — `base/ref-plan.md` "이중 배치
      방지" 절
- [ ] `PreRef`/`PostRef` pre-pass — 새 `Dispatch.*` 함수 없이
      `Dispatch.drive(inst, flattened)` 자신이 두 패스(배열→해시) 루프
      전에 배열 파트를 **한 번** 훑어, `PreRef`는 그 자리에서 fire하고
      `PostRef`는 로컬 `postRefList`에 push만 함(Dispatch.process/getHandler
      우회하는 raw 루프, `flatten` 함수에는 얹지 않음 — 재바인드 시 flatten
      재호출 가능성과 충돌하므로 기각). **복수 `PreRef`/`PostRef`의 계열 안
      상대 순서는 배열 index 순서 그대로 보장**(별도 규칙 없음 — 배열 파트
      index 순서 계약의 귀결. 2026-08-14 아홉 번째 세션에 잠깐 미보장으로
      뒤집었다가 같은 세션에 철회 —
      `archive/preref-order-unguaranteed-withdrawn.md`, `FastQuery(...) ->
      PreRef`류 조합이 반례). fire/수집된 슬롯은 그 자리에서 소진(**[정정, 2026-08-14 두
      번째 세션] `None`이 아니라 전용 센티널 `ProcessedPreRef`/
      `ProcessedPostRef` 처리** — 아래 `Processed*Handler` 항목이 그 자리를
      정상 두 패스로 마저 처리)
      — `base/ref-plan.md` "PreRef" 절 / "`PostRef`" 절
- [ ] **[2026-08-14 아홉 번째 세션 신설]** `PostRef.luau` + 두 패스 뒤
      `postRefList` 소비 루프 — `PreRef.luau`와 같은 방식(`Ref` 런타임
      재사용 + 브랜드 태그만 다름, children 배열 리터럴 전용, Modifier/Store
      타입 차단, `_fired` 1회용 가드). `Dispatch.drive`가 해시 파트까지
      끝낸 뒤 `postRefList`를 순회하며 각 `PostRef`를 fire — 배열 재순회가
      아니라 실제 개수만큼의 짧은 루프. **보장 범위 주의**: 자기 서브트리
      완성은 보장하되 **이 인스턴스가 부모에 붙는 것보다는 먼저**임
      — `base/ref-plan.md` "`PostRef`" 절
- [ ] `PostRef` 동적 경로 가드 Handler — `PreRef`의 것과 완전한 거울상
      (`{priority = HANDLER_PRIORITY_FALLBACK, isHandlable = v is PostRef,
      process = error(...)}`), 같은 절 참고
- [ ] `PreRef` 동적 경로 가드 Handler — `{priority =
      HANDLER_PRIORITY_FALLBACK, isHandlable = v is PreRef, process =
      error(...)}` 형태로 정상 우선순위 레지스트리에 등록(`k` 타입 안
      가림), `NoneHandler`와 같은 "한 값 종류 전담" 패턴. 리터럴 배열
      경로는 pre-pass가 이미 소진시키므로 이 Handler가 매치되면 곧 타입
      차단을 우회한 버그라는 뜻 — 같은 절 참고. **[2026-08-14 열한 번째
      세션]** 우선순위가 하드 블록이 아니라 `FALLBACK`인 이유(나중에 named
      자리 바인드가 확정되면 평범한 우선순위 Handler로 덮어쓸 수 있게 —
      `Tag`/`Attribute`와 같은 이유)와 `Observer`/`EffectHandle`에도 같은
      패턴의 가드가 추가됨은 `base/source-state-plan.md`/`base/effect-plan.md`의
      "동적 경로 가드" 절 참고
- [ ] **[2026-08-14 두 번째 세션 신설]** `ProcessedPreRefHandler` +
      **[아홉 번째 세션] `ProcessedPostRefHandler`**(완전한 거울상, 코드
      한 글자 차이) — `{isHandlable = v == Processed*Ref, process =
      setLength(0)+setOffsetSource(None)+no-op retract}` 형태로 정상
      우선순위 레지스트리에 등록, `NoneHandler`와 같은 "한 값 종류 전담"
      패턴. pre-pass가 소진시킨 자리가 Length/Offset에 "0 기여"를 등록할
      책임을 지는 자리 — `base/ref-plan.md` "PreRef" 절 / "`PostRef`" 절,
      `base/dispatch-core-plan.md` "Length/Offset" 절
- [ ] Ref 콜백/대기자 실행 루프(`type(v)=="thread"`면
      `coroutine.resume(v, self)`+`nil`로 소진(2026-08-09 열한 번째
      세션 최종 정정 — 순서 안 중요 + 슬롯 재사용 위해 `None`이 아닌
      `nil`, `table.insert` 대신 빈 슬롯 선형 탐색 등록), 함수면
      `v(value)` 호출+유지 — 같은 배열 하나로 통합). `:Wait(thread?)`는
      `thread`가 `nil`이면
      `coroutine.running()` 캡처+yield, 있으면 등록만 하고 즉시 `self`
      반환(남의 thread를 여기서 대신 정지시킬 수 없어서)
- [ ] `LifetimeHandle` quad-roblox 실제 구현 — `bindLifetime`/
      `unbindLifetime`/`canBound`/`canExecute` 본체(인터페이스 자체는
      M2로 이동됨, `Relate` 자체는 quad-base라 quad-roblox 쪽 재구현
      없음).
      **[2026-08-14 다섯 번째 세션 정정] gcconn/gchold를 여기서 lazy 생성하지
      않는다** — 생성은 M5의 Instance 생성 경로가 이미 끝내둔 것이고, 이
      함수들은 `InstData`에서 찾아 쓰기만 함. `bindLifetime`은
      `gchold[value]=true`(강참조로 생존 보장)와 `BindData:SetWeak(value,
      "gchold"/"gcconn", ...)`(값이 자기 생존 판정 근거를 직접 들고 있게)
      둘만 하고, `unbindLifetime(value)`은 그 셋을 되돌림. **[2026-08-14
      열한 번째 세션] `canBound(value)`/`canExecute(value)`는 비공개
      헬퍼 `isBoundAlive(value)` 하나(복사된 gcconn의 `.Connected` 또는
      `.Subscribed`를 봄)를 공유하는 얇은 진입점 둘로 분리** — `bindLifetime`/
      `Observer:Subscribe()`의 이중 바인딩 가드는 `canBound`, State emit
      전파 루프만 `canExecute`.
      **저장은 전부 `SetWeak`**(`SetStrong` 아님 — gchold/gcconn은 아래 M5
      클로저↔`gchold[1]` 상호 참조로 이미 안전하게 살아있고, "다른 곳에서
      안전하게 유지되는 것은 항상 weak로 잡는다"가 일반 규칙).
      `base/lifecycle-pattern.md`의 "`bindLifetime` / `canBound` /
      `canExecute` / `unbindLifetime`" 절

## M9 — 컴포넌트 합성 레이어

- [ ] 플레인 함수 컴포넌트 관례 문서화/예제
- [ ] `props.Modifier`/`props.Ref` 전달 관례를 정식 컴포넌트로 검증(M0
      스파이크를 정식화)

## M10 — Event / OnChange / Attribute / Tag

> **✅ [2026-08-13 열네 번째 세션] 0-Z(Attribute 이름 소유권)/0-A(하강
> diff) 확정 완료** — 이 마일스톤의 Tag/Attribute 항목은 **quad-base로
> 재배치**됐고(엔진 op `addTag`/`removeTag`/`setAttribute`만 주입),
> 이름 소유권은 그룹 전용 키 + `AttributeKeyHandler`의 이름 claim이
> 판정함. 정본은 `base/attribute-plan.md`/`base/tag-plan.md`.
>
> **[2026-08-14 열두 번째 세션 정정]** `TagHandler`/`AttributeKeyHandler`/
> `AttributeGroupHandler`는 참조 카운트/이름 claim **알고리즘 구현**일
> 뿐 — `HANDLER_PRIORITY_FALLBACK`에 실제로 등록되는 건 이를 감싸는
> 별도 파일 `TagFallbackHandler`/`AttributeKeyFallbackHandler`/
> `AttributeGroupFallbackHandler`이고, **[재역전, 2026-08-18 구현 전 QA]
> 등록 주체는 백엔드 팩토리가 아니라 quad-base 자신**(백엔드 미로드
> 상태에서도 안내 에러 경로가 돌아야 하기 때문 —
> `base/dispatch-core-plan.md`의 해당 절). 아래 체크리스트의
> `Handler` 파일 항목은 전부 이 구분을 반영하도록 갱신됨 — 뒤집힌
> 옛 모델은
> `archive/tag-attribute-load-time-registration-reversed.md`.


- [ ] `Handlers/Event.luau`(`ReflectionService` 기반 자동 판별)
- [ ] `Handlers/OnChange.luau`(`OnChange(name)` 특수 키 팩토리+Handler,
      `GetPropertyChangedSignal` 바인딩 — 제네릭 없이 콜백 타입은 인라인
      명시, 이름별 weak 캐시로 `OnChange(a) == OnChange(a)` 동등성 보장
      (`AttributeKey`와 동일 기법), `base/onchange-plan.md`, 2026-08-10
      세션 확정·2026-08-11 아홉 번째 세션 후속(캐시))
- [ ] **[2026-08-13 열네 번째 세션 재배치] `quad-roblox/EngineOps.luau` —
      주입되는 엔진 op 3개**: `addTag(inst,{string})`/`removeTag(inst,{string})`
      (`CollectionService`), `setAttribute(inst,name,v)`(`v==nil`이면 삭제).
      `RobloxFactory`가 `BaseModule`에 주입(`bindLifetime`/`canExecute`와
      같은 패턴) — 아래 base 핸들러들이 이걸 호출함
      (`base/dispatch-core-plan.md` "base가 소유하는 핸들러와 주입되는
      엔진 op" 절)
- [ ] `quad-base/AttributeKey.luau`(단일 키 `AttributeKey<<T>>(name)` +
      이름별 weak 캐시로 동등성 보장 + 스칼라 편의 패밀리
      `String`/`Number`/`BooleanAttribute` — 엔진 고유 타입 패밀리
      (`Color3Attribute`류)만 quad-roblox의 `D`(Declarative) 층에서 각자 추가.
      타입 파라미터화 이름만 착수 전 확인, `base/attribute-plan.md`)
- [ ] `quad-base/Dispatch/AttributeKey.luau`(`AttributeKeyHandler` —
      `setAttribute(inst,name,v)`를 `v`가 뭐든 무조건 호출 + **이름
      claim**(`nameClaims` Relate, 다른 키 객체가 같은 이름에 들어오면
      즉시 error, 반환 클로저는 자기 claim만 반납하고 엔진 부작용 없음).
      알고리즘 구현일 뿐 스스로 등록되진 않음(아래
      `AttributeKeyFallbackHandler` 항목 참고). `question.md` 0-Z 결정 —
      `base/attribute-plan.md` "이름 소유권" 절)
- [ ] **[2026-08-14 열두 번째 세션 신설]** `quad-base/Dispatch/
      AttributeKeyFallback.luau`(`AttributeKeyFallbackHandler` — 위
      `AttributeKeyHandler`를 그대로 감싸 `HANDLER_PRIORITY_FALLBACK`으로
      등록되는 별도 이름의 엔티티. **[재역전, 2026-08-18] 등록 주체는
      `RobloxFactory`가 아니라 quad-base 자신** —
      `base/dispatch-core-plan.md` "base가 소유하는 핸들러와 주입되는
      엔진 op" 절)
- [ ] `Attribute.luau`(quad-base — 그룹 값 타입+API: `Attribute(store1,
      store2, ...)`/`Merged`/**`Overridden`**/`:NameMap`, `Tag`와 동형
      array-part 값 객체, `base/attribute-plan.md`. **[2026-08-18]**
      `Merged`는 이름이 겹치면 error, `Overridden`은 뒤가 이김 — 둘 다 제공)
- [ ] `quad-base/Dispatch/Attribute.luau`(`AttributeGroupHandler` — 이름마다
      **그룹 전용 키**(비공개 `GetKey`, 그룹 값 객체별·이름별 메모이즈)로
      `Dispatch.process(inst,key,source,1)`만 부르고, 반환 클로저가 자기가
      등록한 키 전부에 `Dispatch.retractFrom(inst,key,1)`.
      **`process` 안에서 `retractFrom`을 먼저 부르면 안 됨**(철거는 전적으로
      클로저 몫). 실제 `setAttribute`/store-bind 구독/이름 claim은 전부 단일
      키 경로 재사용 — `base/attribute-plan.md` "메커니즘" 절. 알고리즘
      구현일 뿐 스스로 등록되진 않음, 아래 `AttributeGroupFallbackHandler`
      항목 참고)
- [ ] **[2026-08-14 열두 번째 세션 신설]** `quad-base/Dispatch/
      AttributeGroupFallback.luau`(`AttributeGroupFallbackHandler` — 위
      `AttributeGroupHandler`를 그대로 감싸 `HANDLER_PRIORITY_FALLBACK`으로
      등록되는 별도 이름의 엔티티, 등록 주체는 `AttributeKeyFallbackHandler`와
      동일하게 **quad-base 자신** — [재역전, 2026-08-18])
- [ ] `Tag.luau`(quad-base — 값 타입+immutable clone 체이닝: `Tag(...)`/
      `:Added`/`:Removed`/`:Contains`/`:Apply`/`Merged`/`:Names`,
      `base/tag-plan.md` — 2026-08-08 세 번째 세션 array-part 값 객체로
      재설계, 구 해시 파트 모델은 `archive/tag-hash-key-model-reversed.md`)
- [ ] `quad-base/Dispatch/Tag.luau`(`TagHandler` — `isHandlable`은 `isTag(v)`.
      **`addTag`는 온전히 `process`, `removeTag`는 온전히 반환 클로저** —
      이름별 홀더 집합(`tagNameMap`, 위치 `k` 기준 참조 카운트)이 비었을
      때만 실제 `removeTag`, 그마저도 클로저가 받은 새 값이 그 이름을
      `Contains`하면 skip해 깜빡임 방지. 제거할 이름은 모아서 **한 번에**
      `removeTag(inst, names)`. `process` 쪽 별도 diff 없음, `kTagMap`도
      불필요(클로저가 `v`를 직접 캡처) — 2026-08-12 열한 번째 /
      2026-08-13 네·다섯·열네 번째 세션, `base/tag-plan.md`. 알고리즘
      구현일 뿐 스스로 등록되진 않음, 아래 `TagFallbackHandler` 항목 참고)
- [ ] **[2026-08-14 열두 번째 세션 신설]** `quad-base/Dispatch/
      TagFallback.luau`(`TagFallbackHandler` — 위 `TagHandler`를 그대로
      감싸 `HANDLER_PRIORITY_FALLBACK`으로 등록되는 별도 이름의 엔티티,
      등록 주체는 `AttributeKeyFallbackHandler`와 동일하게 **quad-base
      자신** — [재역전, 2026-08-18])
- [ ] **[2026-08-14 세션에 누락 발견, 신규]** `quad-roblox/Handlers/
      InstanceShorthand.luau` — UI 편의 숏핸드 `UICorner`/`UIPadding`
      (+`UIPaddingOffset`)/`UIScale`(`base/ui-shorthand-plan.md`). 이
      마일스톤 전후로 구현하기로 그 문서가 이미 지정해뒀는데 체크리스트에
      항목 자체가 없었음. 구현 포인트: (a) 재사용 대상은 quad가 만든 고정
      이름(`_quad_corner`류) 자식으로 한정, (b) `v == nil`이면 그 자식 제거,
      (c) **자식 프로퍼티는 직접 대입하지 말고 `Dispatch.process(child,
      prop, wrapped, 1)`로 위임** — 이걸로 Tween이 공짜로 따라옴(해석은
      `PropertyHandler` 하나에만 남음), (d) 스칼라→프로퍼티 타입 `wrap`은
      `Tween<T>`의 `.Value`에만 적용되도록 들어올릴 것, (e) `UIPadding`은
      자식 프로퍼티 4개에 각각 위임, (f) 자식을 없앨 때 `retractFrom(child,
      prop, 1)`도 같이. M11(Tween) 이후에 하면 (c)~(d)를 바로 검증 가능

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

- [ ] 용어 정리 스윕 — `State`/`Slot` 등(`PerInstanceState`는 `Relate`로
      대체·해소됨, `DI`→`D`는 2026-08-18 확정·반영 완료) — `.claude/question.md` 1번, 최종 이름 확정되는 대로
      아무 시점에나
- [ ] 각 마일스톤 완료 시 `.claude/qa-request/`/`.claude/archive/`에 기록,
      필요하면 `.claude/session-summary.md` "세션 히스토리"도 갱신(전체 원문은
      `.claude/session/`에, `.claude/session-summary.md`엔 2~4줄 요약+링크만
      — 2026-08-11 재구조화 세션 참고)

## 백로그 (스코프 밖 — 필요성이 실제로 드러나면 그때 설계)

- [ ] 범용 렌더 디버깅 도구로서의 quad-mock(Tween mock 등 동적 동작 포함,
      M1의 quad-base 테스트용 mock과는 별개)
- [ ] `quad-debug`/`quad-debug-roblox-plugin` — 실물 Instance→코드 위치
      역추적 Studio 플러그인(`research/debug-tooling-plan.md`). 위
      quad-mock과 목적이 다름(오프라인 검증 vs 실시간 라이브 관찰) —
      단 trace 이벤트 스키마를 공유할 여지는 있음, 그 문서 참고. M2/M3/M5
      구현 시 훅 확장 지점만 고려해두면 이 항목 자체는 지금 착수 불필요.
- [ ] v1 마이그레이션 가이드(`objectListClass.__newIndex` 오타 기능 재현
      테스트는 2026-08-13 세 번째 세션에 불필요로 해소됨 —
      `archive/question-resolved.md` 참고, v2엔 대응 개념 자체가 없음)
- [ ] Slot 형제 순서 보장(다중 백엔드 관점) — Roblox만이면 급하지 않음
- [ ] **[2026-08-14 신설, 2026-08-19 설계 전부 해소 후 `base/`로 승격]**
      시간 기반 전파 게이트 `Debounce`/`Throttle`(`base/debounce-throttle-plan.md`)
      — 제어 핸들 설계까지 닫히면서 quad-base에 새 코어 메커니즘을
      추가하지 않는 **순수 슈가**로 확인됨(`Blocker`의 gated state + `Ref` +
      아래 주입 op 2개 위에 전부 얹힘, 그 문서 13절). **M3에서 `Blocker`를
      구현할 때 게이티드 노드를 공용 `Gate`로 빼두는 것만은 그 시점에 할
      것**(둘이 같은 노드를 공유하므로 따로 하면 같은 설계를 두 번 함).
      프리미티브 자체는 그 위에 나중에 얹으면 되고 M0/M3를 막지 않음.
      주입 op 2개(`setTimeout(func, delay) -> Timeout` / `clearTimeout`,
      Roblox는 `task.delay`/`task.cancel`로 배선 — **인자 순서가 반대라
      주의**)가 `bindLifetime`/`canExecute`와 같은 base 범용 유틸 그룹에
      추가될 예정이라는 것만 M1 설계 시 인지. `os.clock()`은 Luau 표준
      라이브러리라 주입 대상 아님(단 절대 시각이 아니라 diff 전용)
- [ ] **[2026-08-14 아홉 번째 세션 신설]** 생명주기 훅 슈가
      `OnCreated`/`OnRendered`/`OnDestroyed`(`base/lifecycle-hooks-plan.md`)
      — 각각 `PreRef():Callback(fn)`/`PostRef():Callback(fn)`/
      `Effect(function() return fn end)`를 반환하는 순수 팩토리 함수
      3개라, 착수 시점에 그 문서의 코드 스케치를 그대로 옮기면 끝(새 타입/
      Dispatch 개념 없음, 패키지는 quad-base 확정). **설계는 확정됐지만
      구현은 형제 백로그(`quad-mock`/`quad-debug`/`Operator`/`Fallback`)와
      동급으로 맨 뒤** — 없어도 프리미티브를 직접 쓰면 되므로 기능 격차
      없음. 단 이들이 얹히는 `PostRef` 자신은 슈가가 아니라 디스패치
      코어의 일부라 **M8에서 `PreRef`와 같이 구현됨**(위 M8 참고).
