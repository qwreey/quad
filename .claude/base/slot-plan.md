# Slot — 뮤터블 자식 배열, 엄격한 단일 마운트 소유권 (base로 승격됨)

> **✅ [2026-08-13 열네 번째 세션] 하강 diff 재디스패치 반영 완료.**
> 이전 ⚠️ 배너가 예고하던 교체가 끝났음 — 래핑 핸들러의 `retractFrom`
> 선행 호출이 폐기되고 `Dispatch.process`가 핸들러를 먼저 비교하며,
> `SlotHandler`가 반환하는 클로저가 받는 값의 **타입이 계약으로 보장**됨
> (같은 핸들러로 재프로세스될 때만 값이 넘어오므로 항상 `Slot`이거나
> `nil`). 상세는 `base/dispatch-core-plan.md` "Dispatch 체인" 절, 옛
> 모델 원문은 `archive/dispatch-hintvalue-model-reversed.md`.

**상태**: base — 설계 방향(소유권 귀속, 재마운트 시 throw, **[2026-08-13
여섯 번째 세션 역전] retract=언마운트** — 옛 "retract=폐기"는 뒤집혔음,
아래 "`State<Slot>` 교체는 파괴가 아니라 언마운트" 절이 정본)과
소스 트리 상 패키지 경계까지 확정되어 `research/`에서 승격됨(`base/
architecture.md`의 "구현 착수: 소스 트리 구조 확정" 절 참고). 원본:
`.claude/initreq/raw-userinput.md` "slot을 구현하도록 하기로 했음" 절. Fusion의
`Children` SpecialKey와 Vide의 mount 무가드 비교는 `reference/comparison-fusion-vide.md`
참고 — 결론: **두 라이브러리 어디에도 이런 엄격한 단일 마운트 가드가 없음,
quad의 진짜 개선점.** **[2026-08-09 세 번째 세션]** CRUD 의미론
(`pre-implementation-audit.md` 1-7/1-8) 완전 확정, `research/
additional-primitives-plan.md`가 다루던 키 기반 동적 컬렉션 재조정도
`Slot:List(...)` 메소드로 이 문서에 승격·통합 완료 — 아래 참고.
**[2026-08-12 열다섯 번째 세션]** `Splice(index, removeCount,
...newElements)` CRUD 신설 — 구간 제거+삽입을 shift/recompute 1회로
묶는 순수 최적화, 아래 "CRUD API 확정" 절 참고.

## base/roblox 패키지 경계 (2026-08-04, 5차 라운드 확정)

Slot의 add/remove/clear 재조정 로직(추상 자식 참조 기준 — "이 자리에 뭐가
있어야 하는가"를 결정하는 순수 로직)은 `quad-base/src/Dispatch/Slot.luau`가
소유. 실제 트리 조작(Instance `Parent` 설정/`Destroy`)은 `quad-roblox/src/
Handlers/Slot.luau`가 그 위에서 적용/해제만 담당 — 다른 모든 인터페이스/구현
분리와 동일한 패턴(`base/architecture.md`의 소스 트리 참고). Slot 자체는
당연히 Instance들을 담게 될 것으로 취급.

**[2026-08-09 세 번째 세션 보강]** 이 경계가 담당하는 훅은 mount(`Add`)/
unmount(`Remove`) 둘이 아니라 **reposition(`Move`/`Swap`)까지 셋** —
아래 "CRUD API 확정" 절 참고. reposition은 **Parent를 건드리지 않는다는
계약만 base가 강제**하고, quad-roblox가 이걸 `SetSiblingIndex`로 구현할지
(`LayoutOrder` 기반 정렬이라) 사실상 no-op으로 둘지는 구현 선택.

**[2026-08-09 일곱 번째 세션 보강]** `Dispatch/Slot.luau`의 mount 훅
(`process(inst,k,self,index)`)은 `Dispatch.setLength(inst,i,self.Length)` 호출과
같은 자리에서 `self._listed`면 `activateList(self,inst)`도 트리거해야 함 —
`:List`의 `data:Observer(fn)` 구독을 Slot 마운트 시점까지 lazy하게 미루는
것도 이 mount 훅의 책임(아래 "`Slot:List(...)`"의 "구독 시점" 절 참고).
**[2026-08-11 세션, superseded] 이 mount 훅은 이제 `attachSlot(slotValue,
inst, inst, k)` 한 줄로 축약됨** — `Dispatch.setLength`/`activateList`
호출은 `attachSlot` 내부로 옮겨감(로직은 그대로, 재귀 가능하도록만
일반화됨), 상세는 아래 "Slot-in-Slot 중첩" 절 참고.

**추가로 필요해진 핸들러**: Slot과는 별개로, `k`가 number이고 `v`가 이미
만들어진 Instance인 경우(중첩 인스턴스를 자식으로 직접 넣는 경우, 예:
`Frame { Frame {} }`)를 위한 핸들러도 필요 — `quad-roblox/src/Handlers/
InstanceChild.luau`. Slot은 "뮤터블 배열"을 다루고 이 핸들러는 "정적으로
하나 박아넣는" 더 단순한 경우라 별개로 둠.

## 개념

뮤터블 자식 배열. `Slot<T>(initial?)`(다른 독립 프리미티브의 `Type(args)`
관습과 동일 — `initial` 생략 시 빈 인스턴스, `T`를 추론할 수 없어 tbox
명시적 제네릭 적용 `Slot<<Instance>>()`로 지정. `initial`을 주면
`:Add`를 반복 호출하는 sugar일 뿐, 상세는 아래 "CRUD API 확정" 절의
생성자 항목 참고)로 만들고, `Add`/`Remove`/`Extract`/`Clear`/`Move`/
`Swap` CRUD로 조작하면 실제 바인드된 children이 그에 맞춰 갱신됨 —
정확한 시그니처는 아래 "CRUD API 확정" 절 참고(`get`/`set`은 드롭).

### 요소 타입 제약 (2026-08-09 세 번째 세션)

- **`nil`/`None` 둘 다 금지 — Slot의 raw 요소는 오직 실제 마운트 가능한
  `T` 값만.** [정정, 같은 세션 후속] 처음엔 "배열 파트는 `nil` 대신
  `None`" 원칙을 그대로 가져와 `None`을 Slot 요소로 허용했었는데,
  `:List`의 필터링 요구사항을 구체화하며 재검토한 결과 불필요했음이
  드러남 — `updateFn`이 "이번엔 렌더 안 함"을 표현하는 건 아래 `:List`
  절에서 **`updateFn`의 반환값을 해석하는 `:List` 자신의 내부 로직**으로
  처리되고, 그 경우 `rawAdd` 자체가 아예 호출되지 않음(즉 `None`이 실제로
  Slot 배열에 들어갈 일이 없음) — 그래서 raw `Add`가 굳이 `None`을
  허용해야 할 이유가 없어짐. `element == nil`뿐 아니라 `element == None`도
  `Add`(및 내부 `raw*`)에서 즉시 `error` — "Slot 안엔 실제로 마운트
  가능한 값만 들어간다"는 단일 규칙으로 단순화.
- **핸들러 계층 값(Ref/PreRef/PostRef/Observer/Effect/Modifier) 금지, 즉시
  `error`** — `Modifier` 필드가 이 값들을 담으면 즉시 `error`로 확정했던
  것(`modifier-plan.md` 7번)과 같은 판별 메커니즘(`isRef`/`isPreRef`/`isPostRef`/
  `isObserver`/`isEffect`/`isModifier` Brand predicate)을 그대로 재사용.
  근거: `Dispatch/Leaf.luau`가 처리하는 "children 배열에 `Ref`/`Observer`/
  `PreRef`가 직접 놓이는" 케이스는 **그 컴포넌트가 지금 만들고 있는
  Instance 자기 자신을 가리키는 self-ref 캡처**(`Frame { PreRef():Callback(fn) }`가
  그 Frame 자신을 잡는 것)라 `inst`가 "지금 생성 중인 바로 그 하나의
  Instance"로 고정돼 있어야 의미가 성립하는데, **Slot은 특정 컴포넌트
  호출 하나에 묶여있지 않고 이미 존재하는 부모에 나중에 독립적으로
  붙는 동적 리스트라 이 전제 자체가 없음** — Slot 안의 Ref가 "무엇"을
  가리켜야 하는지 정의가 안 됨. 대체 경로도 이미 있어 능력 손실 없음 —
  특정 child에 ref가 필요하면 그 child를 만드는 컴포넌트 호출 자체에
  Ref를 넘기면 됨(`slot:Add(MyComponent { Ref = myRef })` — **여기서
  `MyComponent`는 `Ref`라는 named 파라미터를 받는 사용자 컴포넌트 함수다.**
  **[예시 이름 정정, 2026-08-20 구현 전 QA 4라운드 `SL-4`]** 예전엔 이 자리를
  `Frame {...}`으로 적었는데, `Frame`은 코퍼스 전반에서 **인스턴스 리터럴**을
  가리키는 이름이라 "리터럴의 named 키에 Ref를 놓아도 된다"로 읽히는
  정반대 오해를 부른다 — 실제로 인스턴스 리터럴에 `Ref = ...`를 named 키로
  놓으면 leaf 바인딩이 **아니고** `HANDLER_PRIORITY_FALLBACK` 가드가 잡아
  에러를 낸다(leaf 바인딩은 배열 숫자 키 전용, `base/ref-plan.md`).
  컴포넌트 함수임이 이름에서 바로 드러나도록 예시 이름을 바꿈).
- **`T`의 실제 의미**: 위 배제 덕에 "이 Slot이 실제로 담을 수 있는 최종
  마운트 가능한 값의 타입" 그 자체로 단순해짐 — quad-roblox엔 사실상
  `T = Instance` 하나뿐(컴포넌트 호출 결과도 결국 Instance)이라
  `D.InstSlot = Slot<<Instance>>`가 사실상 "그"
  Slot 타입. `Slot<T>()`가
  기본값(`T` 생략 시) 없이 항상 명시를 요구하는지, `quad-base`에선
  `any`로 기본값을 두는지는 tbox 제네릭 적용 문법 확정 시 같이 정할 것
  (이 문서 "자식으로 넘기는 클래스 스토어" 절의 기존 미결과 같은 갈래).
  **[2026-08-11 세션] `Slot<T>` 자신도 이제 예외적으로 허용 — 실제로는
  `T = Instance | Slot<Instance>`(자기 참조 제네릭).** 컴포넌트 결합
  시 "결과가 Instance든 Slot(멀티루트)이든 구분 없이 다른 Slot에
  넣을 수 있어야 한다"는 요구 때문 — 상세 근거/메커니즘은 아래
  "Slot-in-Slot 중첩" 절 참고. 자기 참조 제네릭이 Luau에서 실제로
  타입체크되는지는 다른 재귀 타입 케이스들과 같은 급으로 실측 필요
  (`.claude/luau-test/`, M0/M6 착수 시 확인).
  **[2026-08-11 일곱 번째 세션, 같은 세션 정정] raw 요소가 `State<T>`/
  `Source<T>`로 감싸져 있는 것도 허용 — `Slot:Add`가 받는 실제 타입은
  `T | State<T> | Source<T>`.** **구현은 새 메커니즘이 아니라 순수
  `:Single` sugar** — `isState(element)`면 그 자리에 내부적으로
  `Slot():Single(element)`(nested Slot)를 대신 삽입할 뿐이라, 언랩된
  값이 `nil`이어도(`State<T?>`) 전혀 문제없음(raw 직접 전달 요소에만
  여전히 non-nil 요구 적용, 핸들러 계층 값 금지는 그대로 상속) — 상세는
  맨 아래 "반응형 raw 요소" 절 참고, 최초 검토했던 "position-keyed
  StoreBind 구독" 안은 기각.

## 핵심 제약: 소유권 귀속과 단일 마운트

Slot에 들어간 요소는 **ownership이 귀속**되며 다른 곳에 마운트할 수 없게 된다.
`isMounted`를 관리해서, **한 인스턴스에 대한 다중 마운팅이 라이브러리 차원에서
절대 일어나지 않도록 강제**하는 게 v1 대비 핵심 디자인 변화. v1의 `mount()`는
별다른 강제를 안 했지만(`reference/quad-v1-architecture.md`의 mount.lua 분석 참고 —
실제로는 부모/자식 부기까지 했지만 다중 마운트 방지는 없었음), v2는 mount
함수 자체가 이 강제를 담당.

Fusion의 `Children` SpecialKey는 이걸 "특정 SpecialKey 하나의 내부 부기"로만
구현했고(재사용 가능한 1급 프리미티브가 아님), Vide는 아예 이 개념이 없어서
같은 target에 두 번 `mount()`하면 조용히 두 개의 독립 루트가 생김 — 둘 다
반면교사.

### `isMounted` 이중 추적 분리 (1-8 해소, 2026-08-09 세 번째 세션)

"한 인스턴스가 다중 마운팅 절대 안 됨"이라는 위 원칙과 아래 "재마운트 시
즉시 throw"가 원래 하나의 `isMounted`로 뭉뚱그려 서술돼 있었는데, 실제로는
서로 다른 두 대상을 추적해야 함 — 명시적으로 분리:

- **Slot 컨테이너 자신**: `self._mounted: boolean`(Slot 인스턴스 필드
  하나). **트리거 시점은 `Dispatch.process(inst,k,self,index)`가 이 Slot
  객체에 대해 실제로 호출된 순간**(핸들러 매치 시점) — Instance
  `Parent` 대입 완료를 기다리지 않음. 다른 모든 "마운트됨" 판정(PreRef
  소진, Ref 콜백 fire 등)이 전부 dispatch-process 시점 기준이라 여기만
  post-effect 기준으로 가면 일관성이 깨짐. 컴포넌트가 Slot을 prop으로
  받아 저장만 하고 실제 트리에 안 놓는 경로는 `process`가 애초에 안
  불려서 이 정의로도 오탐 없음. **[2026-08-09 일곱 번째 세션 보강]**
  같은 자리에서 `self._mountedInst = inst`도 같이 저장 — `:List()`가
  마운트 이후에 호출되는 경우 이 값으로 즉시 활성화(아래 "`Slot:List(...)`"의
  "구독 시점" 절 참고).
- **개별 element**: Slot 안에 담기는 각 element(Instance/컴포넌트 결과 등)
  마다 전역 멤버십으로 추적 — 특정 Slot 인스턴스에 안 묶임("한 인스턴스가
  어디에도 중복 마운트 안 됨"이 라이브러리 전역 불변식이라서). **[구체화,
  2026-08-12 열여섯 번째 세션]** 이 전역 멤버십의 실제 구현은 아래
  "요소 소유권 — `elementOwner`" 절의 `claimOwner`/`releaseOwner` —
  `Add`가 `claimOwner`(이미 다른 owner면 error)/`Remove`·`Extract`가
  `releaseOwner`. top-level Dispatch 마운트(`SlotHandler`)도 **같은**
  레지스트리를 써서 두 경로가 서로의 소유권을 볼 수 있음(전에는 별도
  레지스트리라 안 보였던 gap, 해당 절 참고).

## 여럿 존재 가능, 부모가 실제 데이터 테이블만 다루면 됨

Slot은 하나의 instance 안에 여럿 존재할 수 있다. 전부 하나의 children으로
들어가지만, 실제 렌더된 instance에서 `GetChildren()`을 직접 하지 않고도 부모가
생성한 "실제 slot 데이터 테이블"만 다루면 되게 해서 **추상화 수준을 낮은 직접
바인딩에서 한 단계 떼어냄**(간접화를 통한 추상화).

## 마운트된 Slot의 재마운트는 즉시 throw (확정)

**사용자 확인 완료**: 이미 사용된(마운트된) slot을 **다른 위치로** 재마운트하려
하면 **즉시 `error()`로 중단** — warn+no-op 아님. 개발 중 바로 잡아낼 수 있게
강하게 실패하는 쪽 선택. 마운트되는 순간 slot의 실제 대상은 고정된다 — 따라서
**글로벌 스코프에서 slot을 쓰는 건 그다지 좋지 않을 수 있음**(재사용/재마운트가
막히므로).

> **[명확화, 2026-08-12 열두 번째 세션 메커니즘과 대조]** 위 throw는 **다른**
> `inst`로 마운트하려 할 때만 해당 — **같은** `inst`로 재-emit되는 경우(store
> 재발행 등으로 `process`가 같은 slot을 다시 받는 경우)는 예외적으로 no-op이지
> throw가 아니다. 상세 메커니즘은 아래 "Slot과 Store 바인드의 관계" 절의
> `SlotHandler.process`(`owner == inst` 분기) 참고.

## 클래스가 슬롯을 받는 방법

"네이밍된 슬롯"이 필요한가에 대한 사용자 자문: 그냥 슬롯 바인드 테이블을
값으로 넘기면 되는 것 아닌가 — 결국 array처럼 구현된 Store라고 생각하는 게
편하다는 방향. **기울어진 결론**: 별도 "Named Slot" 개념 없이, store나
파라미터로 넘기고 그게 그냥 ref처럼 바인드되는 모양.

**확정(2026-08-04, 로드맵 인수인계 라운드)**: 위 방향 그대로 확정 — 별도
"Named Slot" 개념 없음, 슬롯 바인드 테이블을 store나 파라미터로 그냥 넘기면
ref처럼 바인드됨 — **사용자 확정**("A. 맞음. 리프노드에선 그렇게 마운트됨").
단, 이 확정은 "리프 레벨에서 슬롯 하나가 마운트되는 방식"에 한정 — 여러
Slot이 형제로 섞이는 경우의 순서 보장 문제는 별도로 열려있음, 바로 아래
참고.

### 여러 Slot이 섞일 때 순서 보장 — 해소됨 (2026-08-09 여섯 번째 세션)

`Frame { Slot1, 일반자식, Slot2 }`처럼 Slot과 Slot 사이에 다른 요소가 끼거나
Slot이 여럿 형제로 존재할 때, 최종 자식 순서가 저작 순서(위쪽 Slot의 요소가
항상 아래쪽 Slot의 요소보다 앞)를 안정적으로 지키는지가 2026-08-04부터 열려
있었던 질문 — **메커니즘 확정으로 해소됨**: `Dispatch.setLength`/
`Dispatch.setOffsetSource` + 형제별 개수 누적합(`offset`)을 리액티브
프로퍼티(Roblox `LayoutOrder`)에 바인딩하는 방식 — 상세는 `base/
dispatch-core-plan.md`의 "Length/Offset — 여러 Slot이 형제로 섞일 때 순서
보장" 절 참고. **DOM류 물리 순서 백엔드에도 같은 base 메커니즘이 그대로
재사용됨**(offset이 바뀌어도 이미 마운트된 원소를 물리적으로 옮길 필요
없음 — `insertBefore`가 뒤 형제를 자연히 밀어주므로, backend Handler의
"offset 변경 시 할 일"만 no-op으로 달라짐) — `architecture.md`의 "패키지 경계"가
세운 "다른 렌더 백엔드에서도 재사용 가능해야 한다"는 전제와도 부딪히지 않음.

## Slot과 Store 바인드의 관계 (`retract` 순서)

Slot이 store 바인드로 들어오는 경우, pluggable 처리기에 `retract`(구 cleanup,
`base/lifecycle-pattern.md` 참고) 핸들러가 필요함 — 한번 넘어간 slot 요소가
나중에 `retract`되면 삭제되는지, 아니면 "부모의 소유이니 부모가 처리"해야
하는지 검토 필요. **기울어진 결론(잠정안, 이후 정정됨)**: 부모가 정리 정도만
미리 수행하고 다시 `process`하면 되므로, 부모에게 위임(자식 slot 요소 자체가
스스로 정리를 실행하는 게 아니라).

> **정정(2026-08-04 검증 라운드)**: 위 "부모 위임" 잠정안은 당시 **폐기**
> 쪽으로 정정됐었음. **[재역전, 2026-08-13 여섯 번째 세션] 그 "폐기"마저
> 다시 뒤집혀 지금 정본은 `retract`=언마운트**(파괴 아님) — 이 문서 맨 위
> 상태 배너, `archive/question-resolved.md` 맨 끝 확정 요약 표의
> `base/slot-plan.md` 행, 그리고 아래 "`State<Slot>` 교체는 파괴가 아니라
> 언마운트" 절 참고(역전된 "폐기" 원문·역전 근거는
> `archive/slot-discard-no-portal-reversed.md`). 이 문단은 검토 과정의
> 히스토리로만 남겨둠, 두 잠정안 모두 현재 유효한 동작 아님.

**[전면 정정, 2026-08-12 열한 번째 세션, 2026-08-13 다섯 번째/열네 번째
세션에 서술 갱신] 위 "핸들러 타입이 안 바뀌면 retract 없이 process가 diff
담당"이라는 전제 자체가 틀렸음** — store 재발행마다(핸들러가 그대로여도)
**항상** 이전 `process`가 반환한 클로저가 먼저 불림. **[갱신, 열네 번째
세션] 부르는 주체는 `Dispatch.process` 자신**(같은 핸들러면 그 자리
클로저에 새 값을 넘기고 곧바로 `process`를 다시 부름 —
`base/dispatch-core-plan.md` "Dispatch 체인" 절 (A) 분기). 그래서
`State<Slot>`이 `slotA→slotB`로 바뀔 때 **`slotA`를 처리했던 클로저가
`nextValue=slotB`로 먼저 불려 `slotA`를 언마운트하고, 그 다음
`process(inst,k,slotB,index)`가 `slotB`를 마운트**하는 두 단계로 자연히
갈림 — 클로저가 "이전 것 정리", `process`가 "새 것 마운트" 전담:

**[정정, 2026-08-12 열두 번째 세션] "같은 값인가"를 위치별 relate로
간접 비교하는 대신, Slot 자신이 지금 어느 `inst`에 바인딩됐는지를 직접
추적** — 이게 이미 확정된 "한 element가 어디에도 중복 마운트 안 됨"
전역 불변식(위 "요소 타입 제약" 절)을 Slot 컨테이너 자신에도 그대로
적용하는 것이라 더 정확함(위치 비교로는 "이 Slot이 동시에 다른 위치에도
마운트돼 있는가"를 못 잡음).

**[GC 주의, 2026-08-12 열세 번째 세션 — 아래 문단은 이 결정에 이르게 된
역사적 근거이고, 거기 나오는 `kSlotMap`/`slotOwner`는 지금은 둘 다
존재하지 않음: `kSlotMap`은 2026-08-13 다섯 번째 세션에 Handler 계약이
클로저 반환으로 바뀌며 삭제, `slotOwner`는 2026-08-12 열여섯 번째 세션에
`elementOwner`로 일반화. 결론(= 전부 weak, 실제 앵커는 `bindLifetime`
하나)만 아래 코드에 그대로 살아있음]** `kSlotMap`/`slotOwner` 둘 다
Slot을 `SetStrong`으로 저장하면 안 됨 — `kSlotMap[inst][k]=slot`(강)과
`slotOwner[slot]=inst`(강)가 동시에 있으면 **서로 다른 두 `Relate`가
맞물려 서로를 살려주는 순환**이 생김(`inst`가 살아있어야 `slotOwner`가
`slot`을 붙잡고, `slot`이 살아있어야 `kSlotMap`이 `inst`를 붙잡는 식 —
둘 다 서로에게만 기대면 어느 쪽 reachability도 외부에서 못 끊음). 이건
`bindLifetime`이 이미 쓰는 "한 `Relate` 안에서 값이 자기 키를 다시
참조하는" 패턴(`Dispatch.setLength`의 `observer`가 클로저로 `inst`를
캡처하는 것, `Ref.Value=inst` 등)과는 **다른, 더 위험한 모양**이다 —
단일 테이블 자기참조는 그 테이블의 키(`inst`)가 이 테이블 *바깥에서부터*
독립적으로 reachable한지만 판별하면 끝나지만, 두 개의 별도 weak 테이블이
서로의 키를 상대방 값으로 제공하는 상호 순환은 그 판별 자체가 서로에게
의존해버려 일반적인 weak-table GC로 한 번에 안 풀림(Lua 5.2+ ephemeron이
풀려고 만들어진 바로 그 사례). **[확인, 2026-08-12 열네 번째 세션]
Luau는 ephemeron 테이블이 없음 — 복잡성 때문에 도입 안 함, 공식 문서로
확인됨(출처: https://luau.org/compatibility/ "Lua 5.2" 섹션, "Ephemeron
tables" 항목).** 즉 이 회피는 "혹시 몰라서"가 아니라 **Luau에서 실제로
이 순환이 안 풀린다는 게 공식 소스로 확정된 필수 조치** — 설계로 아예
피함. **해법: 실제 GC 앵커는 `bindLifetime`/`unbindLifetime`(이미 결정돼 있었는데
`attachSlot`/`destroySlotTree`에 적용이 안 돼 있던 부분, 이번에 추가) 
하나로만 두고, `kSlotMap`/`slotOwner`는 전부 `SetWeak`(순수 조회용,
아무것도 안 붙잡음)로 낮춤**:

**[일반화, 2026-08-12 열여섯 번째 세션] `slotOwner`는 top-level Dispatch
마운트만 보고 있어서, Slot-in-Slot으로 nested `Add`되는 경로(아래 "요소
소유권 — `elementOwner`" 절)와 서로 다른 레지스트리라 어느 한쪽이 이미
소유 중인 걸 다른 쪽이 못 보고 이중 마운트를 허용하는 gap이 있었음
(사용자 발견) — `slotOwner`를 element(범용, Slot이든 plain Instance든)
전체를 커버하는 `elementOwner`로 승격해 top-level Dispatch 경로와
nested CRUD 경로가 **같은** 레지스트리를 쓰도록 통합:

```lua
local elementOwner = Relate()  -- element(Slot이든 plain 마운트 가능 값이든) 전체 공용
                                -- {[element] = ownerKey}  -- ownerKey: inst | Slot, 전부 weak
local OWNER = "__owner"        -- sentinel key(Relate는 항상 3-인자 SetWeak/2-인자 GetWeak 이후
                                -- 값이라 outer key 하나당 값 하나만 저장하고 싶어도 key가 필요함 —
                                -- lifecycle-pattern.md의 GCCONN/GCHOLD와 같은 패턴, base/relate-plan.md 참고)
local OWNER_POS = "__ownerPos"  -- [2026-08-13 감사 신설] owner 안에서의 위치(top-level만 씀, 아래 참고)

-- nested(`rawAdd`) 전용 — 엄격, 이미 누가 갖고 있으면 같은 owner여도 error
local function claimOwner(element, ownerKey)
    if elementOwner:GetWeak(element, OWNER) ~= nil then
        error("이 요소는 이미 마운트돼 있음 — 다중 마운트 금지")
    end
    elementOwner:SetWeak(element, OWNER, ownerKey)
end

-- top-level(`SlotHandler`) 전용 — "같은 (inst,k) 자리의 spurious 재발행"만
-- false, 그 외 중복은 전부 error. 반환값 = 실제로 새로 클레임했는가.
local function claimOwnerAt(element, inst, k)
    local current = elementOwner:GetWeak(element, OWNER)
    if current == inst and elementOwner:GetWeak(element, OWNER_POS) == k then
        return false  -- 정확히 이 자리가 이미 들고 있음 — 재확인만, no-op
    end
    if current ~= nil then
        error("이 요소는 이미 다른 곳에 마운트돼 있음 — 다중 마운트 금지")
    end
    elementOwner:SetWeak(element, OWNER, inst)
    elementOwner:SetWeak(element, OWNER_POS, k)
    return true
end

local function releaseOwner(element, ownerKey)
    -- [정정, 2026-08-13 세션] 불일치를 조용히 무시하지 않음 — claim이 항상
    -- 먼저 성공해야만 이 element를 이 ownerKey가 들고 있을 수 있으므로, 여기서
    -- 불일치가 관측되는 것 자체가 호출측(rawRemove/rawExtract/SlotHandler.process가 반환한 클로저)의
    -- 소유권 bookkeeping이 어딘가 깨졌다는 뜻 — Dispatch의 "매치 실패는 조용한
    -- 무시 없이 즉시 error" 원칙과 같은 결로 즉시 error.
    local current = elementOwner:GetWeak(element, OWNER)
    if current ~= ownerKey then
        error("releaseOwner: 이 element는 이 ownerKey가 소유하고 있지 않음 — 호출측 소유권 추적이 깨졌음")
    end
    elementOwner:SetWeak(element, OWNER, nil)
    elementOwner:SetWeak(element, OWNER_POS, nil)
end

function SlotHandler.process(inst, k, slotValue, index)
    if claimOwnerAt(slotValue, inst, k) then
        -- [정정, 2026-08-13 세션] bindLifetime을 attachSlot 밖, 여기(top-level Handler)로
        -- 이동 — 반환하는 클로저 쪽 unbindLifetime과 같은 층위(Handler)로 대칭. 중첩
        -- Slot은 여전히 anchor 불필요(자신을 담는 outer의 `_elements`(plain strong
        -- array)로 이미 transitively 살아있음 — elementOwner는 전부 weak라 별도 anchor
        -- 아님) — 그 구분은 이제 "attachSlot을 top-level에서 부르는 이 자리에서만
        -- bindLifetime한다"는 호출부 자체의 위치로 표현됨, attachSlot 내부 분기가 아님.
        bindLifetime(inst, slotValue)
        attachSlot(slotValue, inst, inst, k)
    end
    -- 여기 도달했다는 건 "이 (inst,k) 자리가 slotValue를 소유 중"이 보장된 것 —
    -- 방금 새로 클레임했든, 직전 사이클의 클레임이 spurious 재발행을 거쳐 그대로
    -- 살아있든 둘 중 하나(다른 소유자였다면 claimOwnerAt이 이미 error). 어느 쪽이든
    -- "이 자리가 결국 다른 값으로 바뀔 때 할 일"은 slotValue/inst가 같아서 동일하므로
    -- 클로저도 하나로 통일 — 여기서 no-op 클로저를 반환하면 안 됨: 체인은
    -- 클로저를 early-return시키든 말든 항상 *소비*하므로(retractFrom도, 재프로세스도),
    -- spurious 사이클에서 no-op을 심어두면 그 다음 진짜 교체 때 이전 서브트리를
    -- 정리할 주체가 사라짐.
    return function(nextValue)
        -- nextValue는 nil이거나 같은 핸들러가 곧 처리할 Slot — 타입 보장됨
        if slotValue == nextValue then return end  -- 같은 Slot 재발행 → no-op
        -- [정정, 2026-08-13 감사 후속] 파괴가 아니라 **언마운트** —
        -- 아래 "`State<Slot>` 교체는 파괴가 아니라 언마운트" 절이 확정한
        -- 결정이 적용돼야 하는 자리가 바로 여기(최상위 dispatch 경로).
        -- 예전엔 destroySlotTree를 불러 그 결정과 정면으로 모순됐음.
        unmountSlotTree(slotValue)
        -- 이 위치가 더 이상 기여하지 않음을 owner에게 알림 — **순서 고정**
        -- (setLength가 끝에서 gatedRecompute를 경유해 recompute를 돌리므로
        -- offsetSource를 먼저 비워야 죽는 중인 Source에 헛된 :Set()이 안 감,
        -- 아래 ⚠️ 절 참고)
        Dispatch.setOffsetSource(inst, k, None)
        Dispatch.setLength(inst, k, 0)
        unbindLifetime(slotValue)  -- top-level 자신의 GC 앵커 해제 — SlotHandler.process의 bindLifetime과 짝
        releaseOwner(slotValue, inst)    -- 이제 이 Slot은 아무에게도 안 묶임(다른 곳에 다시 넣을 수 있음)
    end
end
```

**언마운트된 Slot은 그대로 재사용 가능** — `_elements`와 그 안의 소유권이
전부 보존되므로(아래 `unmountSlotTree` 참고), `slot`을 들고 있던 코드가
다른 곳에 다시 넣으면 `attachSlot`이 새 물리 부모로 다시 flush함. 아무도
안 들고 있으면 그냥 GC. 지금 확실히 죽이려면 `dispose`(아래 절).

**[전면 정정, 2026-08-13 감사] `claimOwner`를 nested/top-level 두 함수로
쪼개고, top-level은 `(inst, k)`까지 본다.** 원래는 하나의 `claimOwner`가
"같은 ownerKey면 `false` 반환(no-op)"을 양쪽에 공유했는데, 그 분기가
**두 개의 서로 다른 상황을 구분 못 해서** 양쪽 경로에 각각 버그를
만들고 있었음:

- **top-level**: `Frame { slot, slot }`(같은 Slot을 같은 inst의 두 위치에)에서
  `k=2`가 `current == inst`라 조용히 `false`를 받아 attach를 건너뛰는데,
  **그러고도 파괴적인 클로저를 반환**했음 — 나중에 철거될 때
  `destroySlotTree`가 두 번 돌고 `unbindLifetime` 짝이 어긋나며
  `releaseOwner`가 (이미 해제된 상태라) error로 터짐. 구 설계는
  `kSlotMap`에 안 적힌 자리는 `retract`가 자연히 no-op이라 우연히 막혀
  있었는데, `kSlotMap` 제거가 이 방어를 같이 걷어낸 회귀였음. 이제
  `claimOwnerAt`이 `k=2`에서 곧바로 error를 내므로 그 상태 자체가 안
  만들어짐 — **클로저를 두 갈래로 쪼개는 방식으로는 못 고침**: 체인은
  클로저가 early-return하든 말든 항상 소비하므로, spurious
  사이클에서 no-op 클로저를 심으면 다음 진짜 교체 때 이전 서브트리를
  정리할 주체가 사라져 오히려 더 큰 누수가 됨(감사 중 실제로 그 방향을
  먼저 써봤다가 되돌림).
- **nested**: `rawAdd`는 애초에 `claimOwner`의 반환값을 안 봄(아래 "요소
  소유권" 절 호출부) — 그래서 `local a = Slot{}; Slot { a, a }`가 조용히
  통과해 `_elements = {a, a}`가 되고, `attachSlot`이 같은 Slot에 대해 두 번
  불려 부모 `lengthList`에 같은 Slot이 두 번 계산되고 `slot.Offset`도
  두 번째 호출이 덮어써 첫 번째 `Source`가 고아가 됨.

**해법의 근거 — nested엔 "재클레임"이라는 개념이 애초에 없다.** `:List`의
`reconcile`은 요소를 바꿀 때 항상 `rawUnmount(prev)`(→`releaseOwner`) 다음에
`rawAdd(result)`(→`claimOwner`) 순서로 부르고(아래 "구현" 절 의사코드 —
**[정정, 2026-08-13 여섯 번째 세션]** 예전엔 `rawRemove`(파괴)였으나
언마운트 전환으로 바뀜, `rawUnmount`도 `releaseOwner`를 똑같이 부르므로
이 소유권 논증 자체는 그대로 성립),
`rawMove`/`rawSwap`은 클레임을 아예 안 건드림 — 즉 nested에서 "이미 내가
갖고 있는 걸 다시 클레임"하는 정당한 경로가 하나도 없으므로 **무조건
error가 맞음**. 반대로 top-level은 store 재발행마다 같은 Slot으로
`process`가 다시 불리는 게 정상 경로라 그 케이스만 구분해줘야 하고,
그러려면 owner 하나로는 부족해서 위치(`k`)까지 봐야 함.

**위치를 키에 넣어도 안전한 이유(사용자 확인)** — 여기서 쓰는 `k`는
"바깥 컨테이너 안에서의 인덱스"고, 이건 nested Slot의 `Length`가 변해도
바뀌지 않음. 실제 물리 배치의 변동은 전부 `offset`이 흡수하도록 설계돼
있음(`base/dispatch-core-plan.md` "Length/Offset" 절의 `recompute`가 그
증거 — `lengthList`/`sourceList`는 위치별 배열이고 순서 계산만
누적합으로 함). top-level의 `k`는 특히 props 배열 리터럴의 위치라
저작 시점에 고정. **nested는 `Move`/`Swap`/`Splice`/`Remove`가
`_elements` 인덱스를 실제로 밀고 당기지만, 위 결론대로 nested는
위치를 아예 안 쓰므로(엄격 `claimOwner`) 무관** — 그래서
`OWNER_POS`는 top-level 전용이고 `rawAdd` 경로는 건드릴 필요가 없음.

`attachSlot` 자체가 quad-roblox 소속이라 `inst`를 아는 건 자연스러움 —
`elementOwner`가 굳이 `inst`의 정체를 몰라도(예: 다른 백엔드에서 중간
표현 테이블이어도) 무관하게 동작함, 그냥 "지금 이 자리를 차지한 값이
누구냐"만 구분하면 됨.

### 요소 소유권 — `elementOwner`, nested `Add`/top-level Dispatch 공용 (2026-08-12 열여섯 번째 세션)

**문제(사용자 발견)**: 위 `elementOwner`가 승격되기 전엔 top-level
Dispatch 마운트(`SlotHandler.process`)만 `slotOwner`를 봤고, `Add`가
확인한다는 "개별 element 전역 weak-set"(구 "isMounted 이중 추적 분리"
절)은 완전히 별개 레지스트리로 서술만 있고 코드가 없었음 — 그래서
`slot1`을 top-level store-bind하면 `slotOwner`만 찍히고, 그 다음
`otherSlot:Add(slot1)`을 하면 `Add`가 보는 레지스트리엔 아무것도 없어
그대로 통과 → 같은 `slot1`이 두 군데 물리적으로 마운트되는데 에러가
안 남(반대 순서도 동일하게 뚫림) — "핵심 제약: 소유권 귀속과 단일
마운트" 절의 라이브러리 전역 불변식이 실제로는 안 지켜지던 gap.

**해법**: 위에서 승격한 `elementOwner`/`claimOwner`/`releaseOwner`를
Slot뿐 아니라 **모든 마운트 가능 element(plain Instance 포함)**의
소유권 판정에 공용으로 씀 — top-level(`SlotHandler.process`와 그 반환
클로저)과 nested(`rawAdd`/`rawRemove`/`rawExtract`)가 정확히 같은 함수, 같은
`Relate`를 호출하므로 어느 경로로 먼저 클레임하든 다른 경로가 반드시
봄:

```lua
-- rawAdd(self, element, index) 안, "이미 마운트" 에러 체크 자리
claimOwner(element, self)  -- self = 담는 Slot. 이미 누가(같은 self 포함) 소유 중이면 여기서 error

-- rawRemove(self, index)/rawExtract 안, 요소를 내보내는 자리
releaseOwner(element, self)

-- destroySlotTree(slot) 안, 자식들을 파괴하기 직전(아래 "파괴" 절)
releaseOwner(element, slot)
```

**[2026-08-13 감사] `claimOwner`는 반환값이 없음 — 성공 아니면 error다.**
예전 버전은 "이미 같은 owner면 `false` 반환"이었고 `rawAdd` 호출부는 그
반환값을 아예 안 봐서, `local a = Slot{}; Slot { a, a }`가 조용히 통과했음
(위 "Slot과 Store 바인드의 관계" 절의 전면 정정 참고). nested 경로엔
재클레임이 정당한 경우가 하나도 없으므로(reconcile은 항상 `rawUnmount`→
`rawAdd` 순서 — **[정정, 2026-08-13 여섯 번째 세션]** 옛 `rawRemove`(파괴)에서
바뀌었으나 둘 다 `releaseOwner`를 부르므로 논증 동일, `rawMove`/`rawSwap`은
클레임 미접촉) 무조건 error가 맞음 —
top-level만 `claimOwnerAt`으로 spurious 재발행을 구분함.

**[2026-08-13 감사] 소유권 반납은 GC에 맡기면 안 됨** — `rawRemove`/
`rawExtract`처럼 **요소를 살려서 내보내는** 경로에 한해 그렇다. `elementOwner`는
값도 `SetWeak`이라 "아무에게도 참조되지 않게 되면 소유권 기록도 저절로
사라진다"가 원리적으로는 맞지만, **그게 언제인지가 GC 타이밍에 달려 있어서**
그 전에 같은 element를 다른 곳에 넣으려 하면 "이미 마운트돼 있음" error가
비결정적으로 터짐. top-level Slot 자신의 반납은 `SlotHandler.process`가
반환한 클로저가 담당(층위 분리는 `unbindLifetime`과 동일한 원칙).

**[재정정, 2026-08-20 구현 전 QA 4라운드 `C-4`] 단, `destroySlotTree`는 이
규칙의 대상이 아니다 — 명시적 `releaseOwner`를 도로 뺀다.** 2026-08-13
감사가 같은 근거로 `destroySlotTree`에도 넣었었는데, 사용자 판정으로
되돌림: *"Destroy 된 요소는 다른곳에 원래 마운트 못하는게 보통 엔진
정상이고, 또, 릴리즈 안 되어 다른곳에 마운트 막혀도 상관 없고, 그게 정상
동작일 수 있어보임."*

- **막히는 게 정상이다** — 파괴된 요소를 다른 곳에 다시 넣으려는 코드는 그
  자체로 버그다. "비결정적으로 실패"의 반대는 "성공"이 아니라 **"항상
  실패"**이고, 그게 더 나은 동작이다. 명시적 반납은 오히려 그 버그를
  통과시켜 죽은 Instance를 엉뚱한 데서 터지게 만든다.
- **`rawRemove`/`rawExtract`와 갈리는 이유**: 그쪽은 요소를 **살려서**
  호출자에게 돌려주는 경로라 "이제 다른 곳에 넣어도 된다"가 정상 시나리오다.
  `destroySlotTree`는 그 반대 — 요소가 죽는다.
- **남는 성질**: 반납을 안 하므로 GC 전엔 error, GC 후엔 통과라 **여전히
  비결정적**이다. 그래도 두 결과 모두 "버그 있는 코드"에 대한 것이라
  실사용 위험이 없고, 결정적으로 만들려면 "파괴됨" 마킹이라는 새 부기가
  필요해 `conventions.md`의 "드문 오용이나 가상의 미래 요구까지 방어/
  최적화하려고 구조를 복잡하게 만들지 않는다" 원칙에 어긋난다. 파괴된 값의
  재사용이 UB라는 건 `Ref`("Destroy와는 무관")에서 이미 확립된 관례이기도
  하다.

`ownerKey`가 `inst`(top-level)든 `Slot`(nested)든 `elementOwner`는
타입을 신경 안 써서 하나의 레지스트리로 충분 — `outerSlot`이 값으로
들어가도 `elementOwner` 자체는 아무것도 강하게 안 붙잡고(전부
`SetWeak`), 실제 강한 참조는 `outerSlot._elements`(plain array, `Relate`
아님)가 이미 쥐고 있으므로 `relate-plan.md`가 경고하는 "두 Relate
상호 강참조" 패턴과 다른 모양 — GC 문제 없음.

- **같은 바인딩이면 완전히 무시하는 게 이 자리에선 효율 문제가 아니라
  정합성 문제** — 이 no-op 가드가 없으면 **[정정, 2026-08-13 4차 감사]
  재귀 재emit이 있을 때마다 마운트된 서브트리 전체가 언마운트됐다 다시
  마운트됨**(작성 당시엔 아직 destroy 모델이었음, 아래 "`State<Slot>` 교체는
  파괴가 아니라 언마운트" 절의 언마운트 전환 참고 — 물리 트리 이탈+재마운트라 여전히 자식들이 들고 있던 스크롤
  위치/포커스/애니메이션 상태는 유실됨, 파괴가 아니라는 것만 정정) —
  Tag의 `Contains` 힌트가 막으려던 "깜빡임" 문제보다 훨씬 파급이 큰 버전.
  `store.key:Set(sameSlotAgain)`처럼 사용자가 실수로 같은 객체를 다시
  emit하거나, 상위 `:Compute`가 재계산됐는데 결과가 우연히 같은 Slot
  레퍼런스인 경우 등이 실제로 이 경로를 탈 수 있음. `retract`가 `old ~= v`
  체크로 이걸 막고, `process`도 `old == slotValue` 체크로 대칭적으로 막음
  — 둘 다 스킵돼야 완전한 no-op.
- Slot 핸들러 자신이 감시 중인 값(배열/스토어)이 바뀔 때 child를 갱신하는
  추적(구독)도 `base/dispatch-core-plan.md`가 말하는 "process 함수가 다른 값
  변경을 추적해도 됨" 범위에 속하고, `retract` 시점엔 그 추적만 풀면 됨 —
  Destroy 시점엔 `retract`가 호출되지 않는다는 원칙(`base/lifecycle-pattern.md`)도
  동일하게 적용.

> **🔄 [역전됨, 2026-08-13 여섯 번째 세션 — 원문은 archive로 이동]**
> 여기 있던 **"retract/재바인드되는 slot은 그냥 폐기된다"+"portal은
> 오버엔지니어링이라 안 함"** 확정은 뒤집혔습니다 — 지금은 `State<Slot>`
> 교체가 **파괴가 아니라 언마운트**이고, **portal은 별도 기능이 아니라 그
> 결정의 자연스러운 귀결**입니다. 정본은 이 문서 아래쪽
> "`State<Slot>` 교체는 파괴가 아니라 언마운트" 절(+ `unmountSlotTree`).
> 원문·역전 근거·파급 범위는 `archive/slot-discard-no-portal-reversed.md`.

> **범위 명확화(2026-08-09 세 번째 세션, 이 조항은 지금도 유효)**: 위
> (지금은 역전된) "폐기, 옮기지 않음"은
> **프레임워크가 store-bind 재실행으로 Slot 값 전체를 통째로 갈아치울
> 때**(retract)만의 얘기 — **사용자가 직접 `Slot:Extract(element)`를
> 부르는 CRUD 경로는 이것과 다른 시나리오**다. Extract로 뺀 element는
> 파괴되지 않고 호출부가 소유권을 되찾으며, **임의의 다른 Slot으로
> 자유롭게 다시 `Add`할 수 있다**(아래 "CRUD API 확정" 절) — retract가
> "옮기지 않는다"고 확정한 건 프레임워크가 알아서 옮겨주는 자동 portal을
> 안 만든다는 뜻이지, 사용자가 명시적으로 두 번 호출(`Extract` 후
> `Add`)해서 옮기는 것 자체를 막는 게 아니다.

## CRUD API 확정 (2026-08-09 세 번째 세션, 1-7 해소)

**[정정, 2026-08-09 열한 번째 세션] 식별 기준을 element 레퍼런스에서
인덱스 기준으로 전환.** 원래 "인덱스는 add/remove 반복 시 곧 stale
해진다"는 이유로 레퍼런스 기준을 택했으나, 실사용에서는 반대 문제가 더
흔함(사용자 지적) — `slot:Add(Frame{...})`처럼 호출부가 리턴값을 변수에
안 담고 바로 흘려보내는 경우가 많아서, 나중에 그 element를 다시 골라
Remove/Extract/Move하려 해도 참조를 안 들고 있는 경우가 잦음. `Add`만
새로 넣는 대상이라 자연히 element를 직접 받고, 나머지 CRUD는 전부
**인덱스 기준**으로 재확정 — 레퍼런스만 갖고 있으면 `IndexOf`로 먼저
인덱스를 구하면 됨(아래):

| 연산 | 시그니처 | 복잡도 | 의미 |
|---|---|---|---|
| `Add` | `Slot:Add(element, index?): number` | O(n) | 삽입(뒤 요소 밀림), `index` 생략 시 끝에 추가 — **실제로 삽입된 인덱스를 반환** |
| `Remove` | `Slot:Remove(index)` | O(n) | 제거 **+ 파괴**(retract/Destroy) — `Extract(index):Destroy()`와 동치, 흔한 경로라 별도 이름으로 유지 |
| `Extract` | `Slot:Extract(index, newElement?)` | O(n) 또는 O(1) | `newElement` 생략 — 제거만(파괴 안 함), 뒤 요소가 당겨져 빈 자리를 메움(O(n)). `newElement` 지정 — 그 자리를 즉시 교체(뒤 요소 안 건드림, O(1)), 이전 element를 반환 |
| `ExtractAll` | `Slot:ExtractAll(): {T}` | O(n) | 전체 추출(파괴 안 함) — `Clear`의 비파괴 버전, 추출된 element 배열(순서 보존)을 반환 |
| `Splice` | `Slot:Splice(index, removeCount, ...newElements): {T}` | O(n) | 한 위치에서 `removeCount`개를 비파괴 추출(반환)하고 그 자리에 `newElements`를 삽입 — shift+recompute 1회로 통합 |
| `Clear` | `Slot:Clear()` | O(n) | 전체 `Remove`(전부 파괴) — 빈 Slot에 호출해도 no-op |
| `Move` | `Slot:Move(oldIndex, newIndex)` | **O(n)** | 제자리 재배치 — 옛/새 위치 사이 요소들이 밀림/당겨짐(배열 splice와 동일 의미), **Parent 안 건드림** |
| `Swap` | `Slot:Swap(indexA, indexB)` | **O(1)** | 두 인덱스의 요소를 맞교환, 나머지 안 건드림, **Parent 안 건드림** |
| `Get` | `Slot:Get(index): T?` | O(1) | 그 인덱스의 element 조회(범위 밖이면 `nil`) |
| `IndexOf` | `Slot:IndexOf(element): number?` | O(n) | element의 현재 인덱스 역조회(멤버 아니면 `nil`) — 레퍼런스만 있고 인덱스가 없을 때 다른 CRUD와 연결하는 다리 |

- **`Add`가 삽입된 인덱스를 반환하는 이유(2026-08-10 세션 확정)** —
  `index`를 생략(끝에 추가)하면 호출부가 실제 위치를 모르는데, 그걸
  알아내는 유일한 방법이 `IndexOf(element)`(O(n))뿐이었음 — `Add`는
  그 값을 삽입 과정에서 이미 계산하므로 반환은 공짜. `index`를 명시적으로
  넘긴 호출에서는 반환값이 그냥 echo라 다소 중복이지만, "항상 최종
  인덱스를 반환"으로 시그니처를 통일해 분기 없이 단순하게 둠. `Move`/
  `Swap`이 void인 것과 모순 아님 — 그 둘은 호출부가 이미 위치를 알고
  부르는 연산이라 새로 알려줄 정보가 없어서 void인 것이고, `Add`는
  반대로 새 정보(계산된 위치)가 생기는 경우라 "반환값은 실제로 새로
  알게 되는 정보만"이라는 같은 원칙의 연장.
- **`Extract(index, newElement?)`가 존재하는 이유** — 인덱스 기준 모델에서
  "요소 하나를 다른 걸로 교체"하려면 `Extract(index)`(O(n) 시프트) 후
  `Add(newElement, index)`(O(n) 시프트 재발생)를 따로 불러야 해서 이중으로
  무거움. `newElement`를 같이 넘기면 그 자리 값을 시프트 없이 바로
  갈아끼우기만 하면 되므로 훨씬 쌈 — 별도 `Set`이라는 이름 대신 `Extract`의
  확장으로 둔 이유는 반환값이 "이전 element"라는 의미가 `Extract`와
  정확히 같아서(교체도 "그 자리 걸 빼내고 새 걸 넣는" 것의 원자적 버전일
  뿐). `newElement`에도 `Add`와 같은 검증(이미 마운트/타입 제약)이
  똑같이 적용됨.
- **`Splice` 신설(2026-08-12 열다섯 번째 세션)** — 한 구간을 제거하고
  동시에 새 요소들을 그 자리에 넣는 흔한 배치 갱신(`:List` 없이 수동
  CRUD로 큰 구간을 통째로 교체하는 경우)을 `Extract`/`Add`를 요소 수만큼
  반복 호출하면, 그때마다 개별 `raw*` 호출이 각자 shift+`recompute`를
  돌려 O(n) 비용이 반복 횟수만큼 곱으로 커짐 — `Splice`는 이걸 시프트
  1회 + `recompute` 1회로 묶는 순수 최적화(새 능력 추가 아님, `Extract`
  반복+`Add` 반복으로도 결과는 항상 재현 가능). **비파괴**(`Extract`처럼
  제거분을 파괴하지 않고 반환) — 실제 물리적 detach/reattach(Roblox
  `Parent` 조작, `AncestryChanged` 발화 등)를 언제 어떻게 할지는 base가
  정하지 않고 quad-roblox 등 백엔드 Handler 엔드포인트가 처리(기존
  "base는 추상 재조정 로직, backend는 실제 트리 조작"이라는 패키지
  경계 원칙 그대로 재적용, 새 분리 아님). 제거된 구간이 뒤 요소를 당기고
  삽입된 구간이 다시 밀어내는 게 순수하게 겹치면 상쇄되는 부분이 있어
  `Extract 반복 + Add 반복`보다 실제 이동 계산량도 더 적음.
  **`newElements`는 `Tag:Added`와 달리 의도적으로 vararg 유지, `T | {T}`로
  안 바꿈(같은 세션 후속 논의).** `Tag:Added`가 `string | {string}`로 간
  이유(조건절로 조립한 여러 동적 테이블을 한 호출로 합칠 수 없는 vararg의
  구조적 한계, 위 `tag-plan.md` 참고)가 여기도 적용되는지 검토했으나
  기각 — (1) 실사용 패턴이 다름: 한 번에 갈아끼우는 요소 개수는 호출부가
  이미 아는 소수인 경우가 대부분이고, 정말 개수를 모르는 동적 삽입이면
  `Slot:Add`가 이미 받는 `State<T>`/nested `Slot` 요소로 흡수 가능
  (Slot-in-Slot, 위 "반응형 raw 요소"/"Slot-in-Slot 중첩" 절) — `Splice`
  자체가 동적 배치를 떠받칠 이유가 없음. (2) **`T | {T}`가 여기선 오히려
  틀림 — 이유는 "`Slot`의 `T`가 우연히 테이블(`Instance | Slot<Instance>`)
  이라서"가 아니라, `Slot<T>`가 base 레벨에선 `T`가 뭔지 전혀 모르는
  제네릭이기 때문(다른 백엔드면 테이블일 수도, userdata일 수도, 그 밖에
  뭐든 될 수 있음)** — `Tag`는 `T=string`으로 항상 고정·확정돼 있어
  `type(v) == "table"` 분기가 "배열이냐 아니냐"를 안전하게 구분하지만,
  `Splice(idx, len, {item1, item2})`의 `{}`가 "그 자체로 하나의 `T`
  값(마침 테이블로 표현된)"인지 "펼쳐야 할 `{T}` 배열"인지는 `T`가 뭔지
  base가 애초에 모르므로 원천적으로 판별 불가능(quad-roblox에서 `T`에
  `Slot`이 섞여있는 건 이 문제를 드러내는 한 사례일 뿐, 근본 원인이
  아님). 억지로 하려면 결국 항상 명시적으로 감싸거나 풀어야 해서 vararg
  대비 얻는 게 없음. 이미 `{T}` 배열을 들고 있는 호출부는
  `Splice(i, n, table.unpack(list))`로 충분(리스트가 하나뿐이라
  tail-position 제약에도 안 걸림).
- **`Get`/`IndexOf` 신설, 원래 "YAGNI"로 뺐던 것을 재추가.** 처음엔
  "`:List`가 자기 key→element 맵을 따로 들고 있어 Slot 내부 상태 조회가
  불필요"하다고 판단해 드롭했으나, 위 인덱스 기준 전환과 맞물려 다시
  필요해짐 — element 레퍼런스만 갖고 있는 호출부가 인덱스 기반 CRUD를
  쓰려면 `IndexOf`가 유일한 다리. `Get`은 대칭성/일반적인 컬렉션 API
  완결성을 위해 같이 열어둠(필수까진 아니지만 비용이 거의 없어 열어둠).
- **`raw*` 내부 호출 규약은 공개 API와 다를 수 있음(구현 세부, M6에서
  확정)** — `:List`의 reconcile은 이미 자기 `key→element` 맵을 들고
  있어서 `rawRemove`/`rawMove` 등을 element 기준으로 계속 부를 수도
  있음. 공개 CRUD가 인덱스를 받아 내부적으로 element를 찾아 `raw*`에
  넘기는 얇은 변환 계층이 될지, `raw*` 자체를 인덱스 기준으로 통일할지는
  base 설계가 못박을 필요 없는 구현 디테일.
- **에러 조건 — 전부 즉시 `error()`, no-op 없음**(기존 "재마운트 시 throw"와
  같은 fail-fast 톤):
  - `Add`: element가 이미 어딘가(같은 Slot이든 다른 Slot이든) 마운트돼
    있으면 에러 — "라이브러리 차원에서 다중 마운팅 절대 금지" 원칙을
    CRUD 경로에도 동일 적용. `element`가 `nil`/`None`이거나 핸들러 계층
    값(Ref/PreRef/PostRef/Observer/Effect/Modifier)이면 에러 — 위 "요소 타입 제약" 절.
    `index`가 범위 밖(1..현재 개수+1, 즉 끝에 추가하는 위치까지 포함)이면
    에러 — **clamp 안 함**(2026-08-10 세션 확정): index가 조용히 다른
    자리로 보정되면 "의도한 위치가 아닌데 그대로 성공한" 조용한 버그가
    생기고, 이미 다른 CRUD 전부가 fail-fast인 것과도 불일치함.
  - `Remove`/`Extract`/`Move`: `index`(들)가 범위 밖(1..현재 개수)이면
    에러.
  - `Extract(index, newElement)`: `newElement`도 `Add`와 동일한 검증
    (이미 마운트/타입 제약) 적용.
  - `Splice(index, removeCount, ...newElements)`: `index`는 `Add`와 같은
    범위(1..현재 개수+1), `removeCount`는 `index`부터 실제 남은 개수를
    못 넘으면 에러(음수도 에러) — clamp 안 함, 나머지 CRUD와 같은
    fail-fast 톤. `newElements` 각각에 `Add`와 동일한 검증(이미 마운트/
    타입 제약) 적용, 검증은 실제 mutate 전에 전부 먼저 통과해야 함
    (일부만 적용된 채 중간에 에러나는 반쪽 상태 방지).
  - `Swap`: `indexA`/`indexB` 중 하나라도 범위 밖이면 에러 — 단
    `Swap(i, i)`(같은 인덱스)는 위치가 안 바뀌므로 에러 없이 no-op.
- **`Move`/`Swap`은 반환값 없음(void)** — 내부 재배치만 수행, 멤버십
  weak-set을 안 건드림(요소가 Slot을 떠난 적이 없으므로) — 그래서 `Add`/
  `Remove`/`Extract`보다 저렴함.
- **공개 CRUD 중 실제로 mutate하는 것(`Add`/`Remove`/`Extract`/
  `ExtractAll`/`Splice`/`Clear`/`Move`/`Swap`)은 "가드 확인 + `raw*` 위임"의
  얇은 wrapper** — `self._listed`(`:List`가 설치돼 있으면 수동 CRUD 금지)만
  확인하고 실제 로직은 `rawAdd`/`rawRemove`/`rawExtract`/`rawSplice`/
  `rawClear`/`rawMove`/`rawSwap`에 있음 — 이 `raw*` 함수들이 `:List`의 reconcile이
  가드 없이 직접 호출하는 바로 그 함수(아래 "`Slot:List`" 절의 "구현"
  참고). 공개 메소드에 로직이 따로 있는 게 아니라 전부 이 한 세트를
  공유. **`Get`/`IndexOf`는 순수 읽기라 이 가드 대상 아님** — `:List`가
  설치돼 있어도 자유롭게 호출 가능.
  **[2026-08-11 세션] 역방향 가드 신설 — `_crudUsed` ↔ `_listed` 대칭.**
  `:List`의 가드는 원래 "`:List`가 이미 설치돼 있으면 수동 CRUD
  금지"만 있었고, 반대로 "수동 CRUD를 이미 썼으면 나중에 `:List`
  설치 금지"는 없었음 — 이 상태로는 `Slot():Add(x); ...; slot:List(...)`
  같은 코드가 조용히 통과해서, `:List`의 reconcile이 `x`의 존재를 전혀
  모른 채(자기 `mounted`/`keyIndex`가 비어있는 상태로 시작) 새 요소를
  추가하려다 `x`와 충돌(Length 이중 계산, index 꼬임 등)하는 gap이
  있었음. 모든 mutate CRUD(`Slot(initial)`이 호출하는 `:Add` 포함)가
  `self._crudUsed = true`를 세팅하고, `:List`/`:Single`(내부적으로
  `:List` 호출)이 설치 시 `assert(not self._crudUsed, ...)`를 추가로
  확인 — 한 Slot은 평생 "수동 CRUD" 아니면 "`:List`/`:Single`" 둘 중
  하나로만 고정됨.
- **재진입성**(Observer/store-bind 재실행 콜백 안에서 `Add`/`Clear`를
  다시 호출) — 별도 가드 불필요. CRUD는 평범한 동기 테이블 뮤테이션 +
  Dispatch 호출일 뿐이라 "일반적 무한루프는 방어 안 함, provider 버그로
  간주"라는 기존 원칙이 그대로 적용됨. `recompute` 자체의 재진입(같은
  Slot의 length를 자기 계산 도중 다시 건드리는 것)도 같은 톤으로 UB —
  `base/dispatch-core-plan.md`의 "Length/Offset" 절, `Source⊇State`
  단방향 원칙과 같은 카테고리로 명명됨(2026-08-11 세션).
- **`Slot(initial?: {T})` 생성자 — [정정, 2026-08-11 세션] "인자 없는
  빈 생성자로 확정"을 뒤집고 초기 배열을 받는 옵션 생성자를 다시 엶.**
  단, 새 마운트 로직이 아니라 **순수하게 `:Add`를 반복 호출하는
  sugar**로만 존재 — "명시적으로 Add해야 들어간다"는 원래 취지(매직
  없이 명시적)가 실제로는 안 깨짐, `Slot{a,b,c}`가 정확히
  `Slot():Add(a):Add(b):Add(c)`와 같은 일을 하는 표기일 뿐이라서:
  ```lua
  function Slot(initial)
      local self = setmetatable({...}, Slot_mt)
      if initial ~= nil then
          self._crudUsed = true   -- 빈 테이블이어도 즉시 잠금(아래 참고)
          for _, v in ipairs(initial) do   -- ipairs가 첫 nil에서 멈춤
              self:Add(v)                  -- → "중간 nil은 UB, 그 뒤 무시"가 공짜로 성립
          end
      end
      return self
  end
  ```
  **`initial ~= nil`이면(빈 테이블 `{}`이어도) 즉시 `_crudUsed = true`** —
  `Slot({})`은 상태상 `Slot():Add(x):Remove(1)`과 동일(결과는 비어있지만
  "수동 CRUD를 썼다"는 의도는 이미 커밋됨)이라, 인자를 아예 안 준
  `Slot()`(진짜 `nil`)만 나중에 `:List`/`:Single`을 설치할 수 있는 상태로
  남음 — 아래 "CRUD ↔ List/Single 상호 배타" 절 참고.

### 원시 최소화 원칙 정정 — `Move`/`Swap` 공개 API로 추가 (같은 세션 후속)

`:List`의 리오더 메커니즘을 구체화하던 중, 처음엔 `Extract`+`Add(index)`
조합으로 충분하다고 봐서 "원시 연산 최소화" 원칙에 따라 별도 `Move`/`Swap`을
안 만들기로 했었는데 — 실제로는 두 가지 공백이 드러나 **뒤집음**:

1. **`Extract`+`Add`는 리오더치고 너무 무겁다.** `Extract`의 계약이 "제거,
   파괴 안 함, 소유권 회수"라 백엔드가 곧이곧대로 구현하면 실제 Parent
   조작이 두 번(detach+reattach) 일어남 — Roblox에서 `AncestryChanged`
   발화, 잠재적 깜빡임, 불필요한 재바인딩 비용까지 딸려올 수 있음.
   순서만 바뀌는, 매 `:List` 재계산마다 흔히 일어나는 케이스치고 과함.
2. **`:List` 없이 수동으로 Slot을 구성하는 사용자에겐 리오더 수단이
   아예 없었다** — `Extract`+`Add`도 결국 위 1번 비용을 그대로 지므로
   대체제가 못 됨.

둘 다 원시 최소화보다 우선하는 실사용 공백이라 판단, `Move`(O(n), 배열
splice 의미)와 `Swap`(O(1), 순수 페어 교환)을 공개 CRUD에 추가 — 시간복잡도
차이를 문서화해서 사용자가 상황에 맞게 고를 근거를 줌. `:List`의 reconcile
자체는 키 기반 diff가 "이 키는 이제 절대 위치 i다"를 산출하지 "A랑 B를
맞바꿔라"를 산출하지 않으므로 내부적으로는 계속 `Move`(의 가드 없는 버전)만
사용 — `Swap`은 순수하게 수동 Slot 사용자를 위한 편의 API.

## `Slot:List(data, updateFn, keyFn?)` — 키 기반 동적 컬렉션 재조정 (2026-08-09 세 번째 세션, `research/additional-primitives-plan.md`에서 승격·통합)

Fusion `ForPairs`/`ForKeys`/`ForValues`, Vide `indexes()`/`values()`, React
`key` prop에 대응하는 프리미티브 — 데이터 배열을 정체성(key) 기준으로
diff해서 변경분만 생성/갱신/언마운트한다(**[정정, 2026-08-13 4차 감사]**
원래 "파괴"였으나 언마운트 전환 반영). **독립 타입이 아니라 `Slot`의
콜론 메소드**로 확정(아래 "왜 자유 함수/새 타입이 아닌가" 참고) — 자기
자신을 변경하고 자신을 반환, `Ref():Callback(fn)`류의 기존 체이닝 패턴과
동일:

```
Slot():List(data, updateFn, keyFn?) -> Slot  -- self
```

**파라미터 순서 정정, `keyFn` 선택 인자화 (같은 세션 후속).** 원래
`(data, keyFn, updateFn)`이었는데, 실사용 대부분(사용자 추정 80%)이
"item 자체의 정체성 추적 없이 그냥 순번을 key로 써도 충분한" 단순 목록
(재정렬·중간 삽입/삭제로 인한 identity 보존이 필요 없는 경우)이라
`keyFn`을 매번 명시하게 하는 게 불필요한 보일러플레이트였음 — `updateFn`을
필수 인자 자리(두 번째)로, `keyFn`을 선택 인자(세 번째, 생략 시 인덱스를
그대로 key로 사용하는 `function(item, index) return index end`)로 재배치.
**tradeoff는 명시적으로 문서화 필요**: 인덱스를 key로 쓰면 중간 삽입/삭제
시 그 뒤 모든 항목이 "다른 item인데 같은 key"로 오인돼 캐스케이드 갱신이
일어남(파괴/재생성은 없음, 단지 identity 보존이 없을 뿐) — 흔한 업계
관행(React `key` 생략 시 index 기본값, Vue `v-for` key 없이 쓰는 경우)과
같은 트레이드오프라 새로 설명할 개념은 아님, 재정렬/중간 삽입이 실제로
일어나는 목록엔 진짜 `keyFn`을 넘기라고 안내하는 정도로 충분.

**`key`의 타입 제약 — 없음, 사이클 간 안정성+유일성만 있으면 됨
(2026-08-11 세션 명시화).** `key`는 그냥 `mounted`/`userdata`/`keyIndex`
맵의 Lua 테이블 키로 쓰일 뿐이라 string/number/테이블 레퍼런스 등 뭐든
가능 — 유일한 조건은 (1) 같은 논리적 item이면 사이클이 바뀌어도 항상
같은 key(안정성), (2) 서로 다른 item이면 항상 다른 key(유일성). `keyFn`이
`item`을 그대로 받으므로, `item`에 이미 안정적인 식별자 필드(흔히 문자열
id)가 있으면 그걸 그대로 쓰면 됨 — 캐스케이드 갱신을 피하려고 새로
뭔가 만들 필요 없음:

```lua
slot:List(data, updateFn, function(item) return item.id end)
```

재정렬/중간 삽입이 실제로 일어나는 목록엔 이 패턴을 기본 권장 관용구로
문서화(콘텐츠 사이트 착수 시 반영 — `research/documentation-content-map.md`).

**같은 사이클 안에서 `keyFn`이 중복 key를 반환하면 즉시 `error`
(2026-08-11 세션)** — `reconcile`이 어차피 `seen[key]`를 채우고 있으므로
그 직전에 `if seen[key] then error(...) end` 확인 하나만 추가하면 거의
공짜(아래 "구현" 절 코드 참고). 조용히 넘어가면 두 item이 `mounted`/
`userdata`/`keyIndex`의 같은 슬롯을 다투게 돼 한쪽 item이 사라지거나
뒤섞이는 조용한 버그가 되므로, 다른 Slot CRUD 에러 조건들과 같은
fail-fast 톤으로 그 자리에서 막음 — `keyFn` 작성자(주로 위 `item.id`
관용구를 안 쓰고 실수로 안 유일한 필드를 쓴 경우)에게 즉시 신호를 줌.

**이름 정정 — `renderFn` → `updateFn` (같은 세션 후속).** 아래 서술하는
호출 계약이 "새 key가 나타났을 때 1회 렌더"에서 "매 사이클 재호출되어
갱신 여부를 스스로 판단"으로 바뀌면서, "render"보다 "update"가 실제
역할을 더 정확히 반영한다고 판단해 이름도 같이 바꿈.

> **용어 주의 — 세 가지 "위치/식별" 값을 혼동하지 말 것(2026-08-11 세션
> 명시화)**: 아래 서술에 비슷한 이름의 값 세 개가 나오는데 전부 다름.
> 1. **`keyFn(item, index)`의 `index`** — 원본 `data` 배열에서의 raw
>    위치(`ipairs(items)`의 루프 인덱스 그대로), filter와 무관하게 항상
>    원본 배열 기준.
> 2. **`key`** — `keyFn`이 계산해 돌려주는 정체성 값. `mounted`/`userdata`
>    맵의 실제 키이자 `:List`가 diff를 판단하는 기준 — item이 재정렬돼도
>    같은 `key`면 같은 개체로 취급.
> 3. **`updateFn(item, index, ...)`의 `index`** — `key`/위 1번과 전혀
>    무관한 **압축된 마운트 위치**(filter로 마운트 안 된 item만큼
>    당겨짐) — 순서/레이아웃(`LayoutOrder` 등) 계산 전용, **식별 목적으로
>    쓰면 안 됨**(그건 `key`의 역할). 상세는 아래 `updateFn` 파라미터
>    설명 참고.

- `data: {[K]:V} | State<{[K]:V}> | Source<{[K]:V}>` — plain이면 최초
  1회 배치만 하고 이후 추적 안 함(다시는 안 바뀌므로), State/Source면
  아래 메커니즘이 계속 동작. 기존 leaf 프로퍼티의 "리터럴 또는 State
  둘 다 받는" 폴리모픽 컨벤션 재사용.
- `keyFn(item, index) -> key`(선택, 생략 시 `index`를 그대로 key로 사용) —
  아이템 값과 인덱스 둘 다 받음. **이 `index`는 원본 `data` 배열 위치** —
  아래 `updateFn`의 `index`(압축된 마운트 위치)와 이름만 같고 값은 다름,
  위 "용어 주의" 참고.
- **`updateFn<UD = any>(item, index: number, offset: Source<number>,
  prev: T?, userdata: UD?): (T | nil, UD?)` — 매 reconcile 사이클마다
  모든 key에 대해 호출됨.** `:List`는 더 이상 item을 위해 `Source`를
  대신 만들어주지 않음(아래 "왜 `Source`를 `:List`가 안 만드는가" 참고,
  2026-08-11 세션에 `index`도 같은 원칙으로 편입) — `item`/`index`는
  매번 그 사이클의 raw 현재값 그대로 넘어감, 반응형으로 쓸지는
  `updateFn`이 알아서 결정. **파라미터 순서는 반환값 순서(`T`류 먼저,
  `UD`류 나중)와 맞춤(2026-08-11 세션 정정)** — 원래 `userdata`가
  `prev`보다 앞이었는데, 반환은 `(result, ud)`라 파라미터도 `prev,
  userdata` 순서여야 "값이 안 바뀌면 그대로 반환"이 `return prev, ud`로
  자연스럽게 읽힘.
  - **`index: number`** — 이 key가 **지금 마운트되면(이 사이클에서
    `nil`을 반환하지만 않으면) 실제로 마운트된 요소들 사이에서** 몇
    번째를 차지하게 되는지(1-base), **raw number**(State 아님) — **`keyFn(item,
    index)`가 받는 raw `index`(원본 `data` 배열에서의 위치)와는 다른
    값**이니 혼동 주의. filter로 앞쪽 item이 마운트 안 되면 그만큼
    압축(compact)됨(예: 5개 중 2번째/4번째만 통과하면 그 둘의 `index`는
    1, 2). **`:List`는 이 값을 State로 감싸주지 않음** — `item`을 raw로
    넘기는 것과 완전히 같은 원칙(아래 "왜 `Source`를 `:List`가 안
    만드는가" 참고)이 `index`에도 그대로 적용된 것뿐: `updateFn`이
    `LayoutOrder` 같은 걸 반응형으로 유지하고 싶으면 **자기 `userdata`
    안에 직접 `Source`를 만들어 관리**해야 함, 원치 않으면(웹 백엔드처럼
    무시해도 되는 경우 등) 그냥 버려도 그만 — 아래 "왜 `LayoutOrder`를
    Slot이 대신 안 해주는가" 절의 예시 참고.
  - **`offset: Source<number>`** — 이 `Slot` 자신의 `Slot.Offset`을 그대로
    전달(모든 key가 같은 값을 공유) — 형제로 섞인 다른 Slot/정적 자식이
    기여한 개수의 누적합(`base/dispatch-core-plan.md`의 "Length/Offset" 절
    참고). `index`와 마찬가지로 실제 프로퍼티에 어떻게 반영할지는
    전적으로 `updateFn` 몫 — `Slot`/Handler가 자동으로 해주지 않음
    (2026-08-11 세션 확정, 아래 참고).
  - **`prev: T?`** — 이 key에 대해 지금 실제로 마운트돼 있는
    element(없으면 `nil`, 첫 호출을 포함해 언제든 가능).
  - **`userdata: UD?`** — 이 key에 대해 지난 호출에서 `updateFn` 자신이
    반환해둔 두 번째 값을 그대로 돌려받음(첫 호출은 `nil`). 완전히
    opaque — `:List`는 안을 전혀 안 들여다봄. `updateFn`이 원하는 걸
    아무거나 담아도 됨(item의 `Source`, 여러 파생 State, 로컬 UI
    상태 등).
  - **반환값 두 개는 서로 완전히 독립** — `:List`가 `result`와 `userdata`
    사이에 어떤 커플링도 안 둠(예: `result`가 `nil`이라고 `userdata`를
    자동으로 지우지 않음), 그대로 기록만 함. **[정정, 같은 세션 후속]**
    처음엔 "`result`가 `nil`이면 `userdata`도 같이 버림"이었으나, 이러면
    "인스턴스는 파괴하되 다시 나타날 때 재사용하려고 캐시는 남겨두고
    싶다" 같은 정당한 패턴 자체가 원천 봉쇄됨 — 그럴 이유가 없어 커플링을
    없앰. 흔한 경우(둘 다 리셋)는 그냥 `return nil` 하나로 충분(Lua가
    안 받은 반환 슬롯을 알아서 `nil`로 채움), 캐시를 남기고 싶으면
    명시적으로 `return nil, ud`.
  - **`updateFn`은 매번 다음 세 갈래 중 하나를 명시적으로 골라야 함**
    (아래 "왜 `LayoutOrder`를 Slot이 대신 안 해주는가" 절의 예시 코드가
    이 세 갈래를 그대로 구현) — 어느 갈래인지 `updateFn` 자신만 정확히
    알기 때문에, 이 판단을 `updateFn` 밖(`:List` 내부)으로 빼면 낭비가
    생김(재사용 예정인 Source에 미리 `:Set`해뒀다가 결국 다시 그리게
    되는 식):
    - **버림** — 첫 번째 값으로 `nil`(또는 `None`, 동일 취급)을 반환.
      "지금 이 key는 렌더 안 함"(filter 탈락 등) — `prev`가 있었다면
      **[정정, 2026-08-13 3차 감사, 그러나 2026-08-18 구현 전 QA로 재역전
      — "`nil` 리턴은 파괴가 기본" 절 참고] 파괴됨**(단순 `Visible =
      false`도 아니고, 언마운트도 아님 — `rawRemove`. `Detach`를 명시
      반환해야 대신 언마운트+재사용됨). 편의상
      `nil` 권장(반환값이 raw Slot 요소로 직접 들어가는 게 아니라
      `:List`의 reconcile이 해석만 하므로 "요소 타입 제약"의 raw
      `nil`/`None` 금지와 안 부딪힘).
    - **다시 그림** — `prev`와 다른(보통 새로) 만든 값을 반환. 첫 렌더
      (이 key 최초 등장) 또는 의도적 전체 교체 — `prev`가 있었다면 그건
      **[정정, 2026-08-13 3차 감사] 파괴가 아니라 언마운트되고** 새 값이
      그 자리를 대신함. 이 갈래에서 반응형 값(예:
      `LayoutOrder`용 `Source`)이 필요하면 **항상 새로 만들어서** 처음부터
      올바른 값으로 시작해야 함, 이전 `userdata`에 뭐가 남아있었든
      재사용/`Set`하면 안 됨(아무도 안 구독하는 상태라 무의미한 연산).
    - **`prev`를 그대로 반환(source만 갱신)** — "지금 마운트된 걸
      계속 쓴다"는 뜻, 실제 마운트/파괴가 없는 **저렴한 경로**. 관용구:
      `if prev and (필터 통과) then ...update ud 안의 Source에 :Set()...;
      return prev, ud end` — 이 갈래에서만 기존 Source를 재사용하며
      값이 실제로 다를 때만 `:Set()`.
  - `userdata = userdata or {}`류 lazy-init 관용구가 `UD`가 완전히 자유
    제네릭인 상태에서도 Luau 타입 시스템이 매끄럽게 좁혀주는지는 **실측
    필요**(M0/M6 착수 시 확인 항목, 지금 단정 안 함).

### 왜 `LayoutOrder`를 Slot이 대신 안 해주는가 (2026-08-11 세션)

처음엔 `Slot`을 마운트하는 Handler가 `index`+`offset`을 조합해 각 원소의
`LayoutOrder`를 자동으로 바인딩해주는 안을 검토했으나 **기각** — 사용자가
직접 두 가지 문제를 지적:

1. **매직이 됨.** 컴포넌트가 자기 프로퍼티로 `LayoutOrder`를 이미 지정해서
   Slot에 넣어도(`Frame { LayoutOrder = 5 }`), Slot이 마운트 시점에 그걸
   조용히 덮어쓰게 됨 — "매직 없이 명시적"이라는 프로젝트 전역 기조와
   정면으로 부딪힘.
2. **애초에 `updateFn`이 동적 요소를 전부 다루는 게 원래 설계 의도였음.**
   `userdata`도 그 일부 — Slot/Handler가 원소 프로퍼티의 일부(`LayoutOrder`)만
   따로 떼어 자기가 관리하면 이 원칙이 깨짐.

**결론**: Slot은 `index`(압축된 위치)와 `offset`(형제 누적합, `Source`)만
`updateFn`에 값으로 전달하고, 그 둘을 실제로 어디에 어떻게 쓸지는 전부
`updateFn` 작성자 몫 — 로블록스에선 `LayoutOrder`에, 웹이면 필요할 때만
CSS `order`에(불필요하면 그냥 무시, `insertBefore`가 알아서 물리 순서를
처리하므로), 조합 방식(`+`가 아니라 다른 함수)도 전적으로 자유. Slot
쪽엔 `LayoutOrder`라는 이름 자체가 전혀 등장 안 함, 완전히 엔진/프로퍼티
이름 무관.

수동 CRUD로 Slot을 쓰는 사용자도 마찬가지 — `:List` 없이 직접
`slot:Add(element, index)`를 부른다면, 원한다면 `slot.Offset`을 직접
읽어 자기 `index`(CRUD 호출 시점에 스스로 아는 값)와 조합해서 프로퍼티를
구성하면 됨, 안 하면 그냥 `LayoutOrder`가 갱신 안 될 뿐(에러 아님).

**`index`가 State가 아니라 raw number인 이유, `:Set` 타이밍은 전부
`updateFn`의 몫(같은 세션 후속)** — 처음엔 `:List`가 `index`도
`indexState: Source<number>`로 감싸 관리해주는 안을 검토했으나, 사용자가
"결국 이것도 `item`처럼 raw number로 넘기고, `:Set`을 언제 할지는
`userdata`를 활용해 `updateFn` 스스로 정하는 게 맞다"고 정리 — 채택.
근거: (1) `item`에 이미 적용된 "`:List`가 반응형을 강제하지 않는다"
원칙(바로 아래 절)이 `index`에도 그대로 적용돼야 일관적임. (2) `:List`가
`indexState`를 대신 관리하면, 값이 실제로 바뀌었는지 비교하는 가드
(`Get() ~= newIndex`, `recompute`가 이미 쓰는 패턴)를 넣더라도 **새로
생기는 원소는 항상 `Source(0)`으로 시작했다가 다시 `:Set(index)`으로
고쳐 써야 해서 프로퍼티가 두 번 써짐** — `updateFn`이 `userdata`로 직접
관리하면 새 원소는 처음부터 `Source(index)`로 **올바른 값으로 생성**돼서
이 낭비 자체가 없음.

```lua
function updateFn(item, index, offset, prev, ud)
    if not shouldShow(item) then
        return nil, ud   -- 버림 — Set 자체를 안 부름
    end

    if not prev then
        -- 다시 그림(새 원소) — 이전 Source 재사용/Set 없이 처음부터 올바른 값으로 생성
        local layoutOrder = Source(index)
        return Frame {
            LayoutOrder = layoutOrder:With(offset):Compute(function(i, o) return i:Get() + o:Get() end),
            ...
        }, { layoutOrder = layoutOrder }
    end

    -- source 업데이트만 전파 — 기존 원소/Source 재사용, 실제로 바뀔 때만 Set
    local layoutOrder = ud.layoutOrder
    if layoutOrder:Get() ~= index then
        layoutOrder:Set(index)
    end
    return prev, ud
end
```

**세 갈래를 명시적으로 나누는 이유(사용자 정정)** — `updateFn`이 실행되기
전까지는 이번 사이클에 이 item이 "버려질지/다시 그려질지/source만
갱신될지" 아무도 모름, 그래서 `idx:Set()`을 미리 해둘 수가 없음(해봐야
어느 쪽으로 결론 날지 몰라 낭비가 될 수 있음) — 반대로 `updateFn`
자신은 이 세 갈래를 정확히 알고 있으므로, 자기 안에서 직접 나누면
낭비가 없음. 특히 **"다시 그림" 갈래에서 이전 `ud.layoutOrder`를
재사용하며 `:Set()`하는 건 무의미한 연산**이 됨 — 어차피 새 Frame을
만드는 순간 새로운 `:With`/`:Compute` 구독이 맺어지므로, 그 전에 아직
아무도 안 보는 이전 Source에 `:Set()`을 해봐야 아무 캐스케이드도 안
일어나는 헛수고(구독자가 없어 관측 비용은 저렴하지만 그래도 불필요한
분기) — 대신 그냥 새 `Source(index)`를 바로 만들면 됨, 이전 Source가
어디 남아있든 상관없음(아무도 참조 안 하면 그냥 GC됨).

`index`가 `updateFn` 호출 시점에 이미 "**이 item이 이번 사이클에 살아남으면
차지할** 압축 위치"로 정확히 계산돼서 넘어오므로(아래 "구현" 절의
`candidateIndex` 참고, 직전까지의 생존자 수만으로 계산 가능해 이 item
자신의 생존 여부와 무관), `updateFn`이 값을 늦게 알아서 임시값→정정
과정을 거칠 필요가 없음 — `nil` 반환(필터 탈락)이면 이 `index` 값은
그냥 버려지고 다음 생존자가 같은 값을 받음.

### 왜 매 사이클 호출로 바뀌었는가 — filter/toggle 문제

사용자가 제기한 문제: item이 State 변경으로 "더 이상 렌더되면 안 되는"
상태가 될 수 있는데(예: 검색 필터에서 탈락), 기존 "1회만 호출" 모델엔
이걸 표현할 방법이 없었음. 실무에서 흔한 회피책은 실제로 제거하지 않고
`Visible = false`만 토글하는 것 — 하지만 이건 **lazy하지 않음**: 필터링된
항목도 여전히 완전히 살아있는 Instance라 애니메이션/이벤트 연결/재계산이
계속 돎. 리스트가 200개+가 되면 "보이는 건 20개인데 200개가 전부 계속
돌아가는" 문제가 실제 비용으로 드러남.

**[캐비엇, 2026-08-13 여섯 번째 세션] 아래 근거는 "제거 = 진짜 파괴"를
전제로 쓰였는데 그 전제가 언마운트 재설계로 바뀌었음** — 다만 **결론은
그대로 유효**함: 언마운트도 물리 트리에서 떼어내므로 `Visible=false` 토글과
달리 렌더/레이아웃 비용이 사라지고, 아무도 안 들고 있으면 GC되어 이벤트
연결·재계산도 결국 정리됨. 즉 "lazy하지 않음" 문제는 파괴가 아니라
**언마운트만으로도 해소**되고, 오히려 사용자가 그 요소를 들고 있다가 다시
쓸 수 있게 되는 이득이 붙음.

**해법**: `updateFn`을 매 사이클 호출하되, `prev`를 줘서 "바꿀 게 없으면
그대로 돌려주기만 하면 되는" 저렴한 경로를 만들고, filter 탈락은 `nil`
반환으로 **[정정, 2026-08-13 3차 감사, 그러나 2026-08-18 구현 전 QA로
재역전 — 아래 참고] 언마운트**되게 함(위 캐비엇대로 파괴 아님) — Visible
토글이 아니라 실제 물리 트리 이탈. 200개 중 20개만 통과하는 필터면
20개만 실제로 마운트돼 있고 나머지 180개는 물리적으로 존재하지 않음
(애니메이션도 안 돎, 다만 아무도 안 들고 있지 않은 한 GC되기 전까지
`nil` 아닌 언마운트된 채로 재사용 가능하게 남아있을 수 있음 — 위 캐비엇
참고).

**⚠️ [재정정, 2026-08-18 구현 전 QA, `/code-review high`로 이 절의 stale
서술 발견] 바로 위 두 문단은 "filter 탈락 = 언마운트(비파괴)"를 결론으로
쓰고 있는데, 그 결론은 이후 재역전됐다.** 지금 유효한 규칙은 "`nil`
리턴은 파괴가 기본 — `Detach`로만 비파괴" 절(SL-3 해소,
`question.md`/`archive/question-resolved.md` 참고) — filter 탈락으로
`updateFn`이 그냥 `nil`을 반환하면 이제 **파괴**(`rawRemove`)가 기본이고,
"Instance.new/Destroy 비용을 아끼고 싶다"는 이 절의 동기를 살리려면
`nil` 대신 명시적으로 `Detach`를 반환해야 언마운트+재사용이 된다. 이
절의 **동기**(matched-item 애니메이션/이벤트가 계속 돌면 안 된다는 문제
자체)는 여전히 유효하지만, "그래서 nil이 곧 언마운트"라는 결론 문장은
`Detach`(당시 가칭 `PopOnly`) 신설로 대체됐다 — 이 절을 읽고 filter를
구현할 땐 반드시 위 "`nil` 리턴은 파괴가 기본" 절도 같이 볼 것.

**"이전 상태를 다음 호출에 어떻게 넘기냐" 문제는 `userdata`가 그 채널** —
item이 plain table이라 매번 `Source`를 새로 안 만들고 재사용하려면 그
`Source`를 어딘가 저장해야 하는데, `:List`가 그걸 대신 안 만들어주는
대신(아래 참고) `userdata`라는 전용 채널로 `updateFn`이 직접 관리하게
함 — filter 탈락 후 재등장해도(Instance는 파괴됐다 새로 만들어져도)
`userdata`를 살려뒀다면 그대로 이어짐(위 "반환값 두 개는 서로 독립" 참고).

**sort는 이 재설계와 무관, 기존 메커니즘으로 이미 커버됨** — 호출부가
`data`의 순서를 바꾸면 `keyIndex[key] ~= i` 감지 → `Move`가 그대로
처리, 새 메커니즘 필요 없음(사용자가 filter와 같이 물었던 것 중 sort는
원래도 문제가 없었음).

### 왜 `Source`를 `:List`가 안 만드는가 — item/index를 raw로 넘기는 이유

이전 초안은 `:List`가 `itemState`/`indexState`(내부 `Source`)를 강제로
만들어 `updateFn`에 넘겨줬는데, 재검토 결과 이건 **`:List`가 굳이 강요할
필요 없는 결정**이었음 — 반응형 바인딩이 필요 없는 단순한 행(예: 매번
그냥 새로 계산해도 싼 텍스트 하나)까지 전부 `Source` 생성 비용을 억지로
지게 됨. `userdata`로 이 권한을 완전히 `updateFn` 쪽에 넘기면, 원하는
item만 자기 `Source`를 만들어 `userdata`에 담고, 나머지는 매번 raw
`item`에서 그냥 다시 계산해도 됨 — 어느 쪽이 나은지는 케이스 by 케이스라
`:List`가 미리 정할 이유가 없음.

**부수 효과 — 이전 "item 값은 무조건 재전파, index는 실제 변경시만"
비대칭 백로그가 사라짐.** `:List`가 더 이상 `Source`를 안 만드므로 그
문제 자체가 `:List` 소관이 아니게 됨 — item/index를 반응형으로 감쌀지,
매번 무조건 `:Set()`할지 조건부로 할지는 전부 `updateFn` 작성자의 선택.

### `userdata`의 생명주기 제약 — GC-native만 허용, 명시적 cleanup이 필요한
값은 UB (같은 세션 후속)

**검토했다가 기각한 대안**: `item`을 `T?`(nilable)로 바꿔서, key가 최종
제거될 때 `updateFn(nil, index, userdata, prev)`를 한 번 더 불러 "정리할
기회"를 주는 안 — `if not item then <userdata 안의 구독 해제 등> return
end` 관용구로 `userdata` 안에 담긴 리소스(예: `Observer:Subscribe()`한
구독)를 정리할 수 있게 하자는 아이디어. **기각 — 사용자가 스스로 반례를
찾음**: 이 훅은 `data`에서 key가 빠져 `reconcile`이 다시 도는 정상
경로에서만 발화함 — 하지만 **Slot을 담고 있는 부모 Instance 자체가
`Destroy`되는 경로**(가장 흔한 소멸 경로)는 `reconcile`을 다시 안 돌기
때문에 이 훅이 전혀 안 불림. 절반만 동작하는 정리 메커니즘은 없는 것보다
나쁨 — 사용자가 "정리가 보장된다"고 오해하고 `Subscribe`류를 `userdata`에
넣었다가 Destroy 경로에서 조용히 새는 게 실제로 훨씬 위험한 결과.
`retract`가 Destroy 시엔 절대 안 불린다는 기존 원칙(`base/
lifecycle-pattern.md` "quad는 자신이 만든 Instance의 라이프사이클")과 정확히
같은 이유로, `:List`에 새 반쪽짜리 예외를 만들 이유가 없음.

**대신 명시적 제약으로 문서화**: **`userdata`에는 반환된 element(또는
Slot 자신)보다 명시적으로 오래 살아야 하는 값을 담으면 안 됨 — GC만으로
자연히 정리되는 값만 담을 것(plain 값, `Source`/`State` 등), `:Subscribe()`한
`Observer`/`Effect`류처럼 명시적 `:Unsubscribe()`가 필요한 값을 담는 건
UB.** `:List`가 어떤 teardown 경로도 보장 안 하므로, `userdata` 안의
무언가가 GC 하나만으로 안 죽는다면 그건 곧 leak. 이건 quad 전역
GC-native 원칙(`lifecycle-pattern.md`)을 `:List`라는 구체적 지점에 그대로
적용한 것뿐 — 새 원칙 아님.

### 구현

**구독 시점은 `:List()` 호출이 아니라 Slot 마운트 시점 — lazy `bindLifetime`
(2026-08-09 일곱 번째 세션, 아래 "구독 시점" 절 참고).** `:List()`는 설정만
저장하고 반환, 실제 `data:Observer(fn)` 구독과 최초 `reconcile`은 Slot
자신이 마운트되는 순간(`Dispatch/Slot.luau`의 `process(inst,k,self,index)`)에
`activateList`가 수행 — `Dispatch.setLength`가 이미 쓰고 있는 것과 같은
패턴(마운트 시점까지 미뤘다가 그 자리에서 `bindLifetime`).

```lua
function Slot:List(data, updateFn, keyFn)
    assert(not self._listed, "Slot already has :List installed")
    self._listed = true
    self._listData = data
    self._updateFn = updateFn
    self._keyFn = keyFn or function(_, index) return index end

    if self._mounted then
        activateList(self, self._mountedInst)  -- 이미 마운트돼 있으면 즉시 활성화
    end
    return self
end

-- Dispatch/Slot.luau의 process(inst,k,self,index)가 마운트 시점에 1회 호출
-- (self._mounted=true/self._mountedInst=inst, self.Offset 세팅과 같은 자리)
function activateList(self, inst)
    local keyFn, updateFn = self._keyFn, self._updateFn
    local offset = self.Offset
    local mounted, userdata, keyIndex = {}, {}, {}

    local function reconcile(items)
        local newKeyIndex, seen = {}, {}
        local pos = 0   -- 압축된(실제 마운트된) 위치 카운터, raw 루프 인덱스 i와 다름

        for i, item in ipairs(items) do
            local key = keyFn(item, i)   -- keyFn은 raw i를 받음(:List 파라미터 설명 참고)
            if seen[key] then
                error("Slot:List — duplicate key: " .. tostring(key))
            end
            seen[key] = true

            local prev = mounted[key]
            local candidateIndex = pos + 1   -- "이 item이 살아남으면 차지할" 압축 위치(생존 여부와 무관하게 계산 가능)
            local result, ud = updateFn(item, candidateIndex, offset, prev, userdata[key])
            if result == None then result = nil end   -- 편의: None도 nil과 동일 취급
            -- [2026-08-18, 이름 2026-08-19 확정] Detach는 "이 자리를 비우되 죽이지는 말라"는 지시.
            -- 아래 "Detach" 절 — 자리 계산 관점에선 nil과 똑같이 취급된다.
            local detach = (result == Detach)
            if detach then result = nil end

            if result ~= nil then
                -- [2026-08-11 일곱 번째 세션] result가 nested Slot이면 그
                -- .Length만큼 건너뛴다 — 다음 형제의 index가 이 아이템이
                -- 실제로 차지하는 물리적 개수를 반영해야 함(아래 "index도
                -- nested-Slot 결과의 Length만큼 건너뛰어야 함" 절 참고)
                pos = candidateIndex - 1 + (if isSlot(result) then result.Length:Get() else 1)
            end

            if result ~= prev then
                -- [재정정, 2026-08-18 구현 전 QA] 세 경로가 갈린다 — 아래
                -- "`nil` 리턴은 파괴가 기본" 절이 소스:
                --   (a) 교체(result ~= nil): 밀려난 prev는 **언마운트만**
                --       — state<Frame> 교체와 동형, 지우라고 한 적이 없음.
                --   (b) Detach: **언마운트만**, 재사용은 ud가 홀드.
                --   (c) 그냥 nil/None: **파괴**(rawRemove) — "지워라"라는 지시.
                if prev ~= nil then
                    if result ~= nil or detach then rawUnmount(self, prev)
                    else rawRemove(self, prev) end
                end
                if result ~= nil then rawAdd(self, result, pos) end -- 새로 배치, 압축 위치 기준
                mounted[key] = result
            elseif prev ~= nil and keyIndex[key] ~= pos then
                rawMove(self, prev, pos)               -- 그대로 쓰되 위치만 이동
            end

            userdata[key] = ud    -- result와 무관, 그대로 기록
                                  -- (Detach 재사용은 여기 담긴 { old = ... }가 담당)
            newKeyIndex[key] = pos
        end
        for key in pairs(keyIndex) do   -- 직전 사이클에 존재했던 전체 key
            if not seen[key] then
                local prev = mounted[key]
                if prev ~= nil then rawRemove(self, prev) end -- [재정정, 2026-08-18] 파괴
                mounted[key], userdata[key] = nil, nil
            end
        end
        keyIndex = newKeyIndex
    end

    local data = self._listData
    if isState(data) then
        local observer = data:Observer(function() reconcile(data:Get()) end)
        -- Observer 등록 자체의 "등록 즉시 1회 실행"은 canExecute
        -- 게이팅과 무관하게 여기서 이미 무조건 일어남(아래 "구독 시점" 절) —
        -- bindLifetime은 그 다음에 걸어 *이후* 재실행만 inst 생명주기에 귀속
        bindLifetime(inst, observer)
    else
        reconcile(data)
    end
end
```

**[정정, 2026-08-11 세션] `pos`(압축 위치)와 raw 루프 인덱스 `i`를
분리한 이유 — 이전 의사코드의 실제 버그.** 원래 `rawAdd(self, result, i)`처럼
raw `i`를 그대로 위치 인자로 썼는데, 앞쪽 item이 filter로 마운트 안 되면
실제 Slot 안 마운트된 개수는 `i`보다 항상 적어짐 — 그 상태로 `rawAdd`를
`i` 위치에 부르면 `Add`의 "범위 밖 index는 clamp 없이 error"(위 "CRUD API
확정" 절)에 걸려 그냥 터짐. `pos`는 이번 사이클에서 **지금까지 실제로
마운트된 개수**만 세는 별도 카운터라 이 문제가 없음 — `keyIndex`/`rawMove`/
`rawAdd`도 전부 이 `pos` 기준으로 통일. filter 탈락 없이 순서대로 통과하는
흔한 경우엔 `pos == i`라 체감상 달라지는 게 없음.

**[같은 세션 후속] `updateFn`에 넘기는 `index`가 `candidateIndex`(=`pos + 1`)인
이유 — `idx`를 `:List`가 State로 관리하던 안을 기각하며 나온 재설계.**
`candidateIndex`는 **"이 item이 이번 사이클에 살아남으면 차지할 압축
위치"** — 직전까지 처리된 item들의 생존 개수(`pos`)만으로 계산되므로
이 item 자신이 살아남을지와 무관하게 `updateFn` 호출 **전에** 이미 정확히
알 수 있음. 그래서 `result ~= nil`일 때만 `pos = candidateIndex`로 커밋—
살아남지 못하면(`nil` 반환) 그 값은 그냥 버려지고 다음 생존자가 같은
값을 받음. 이 덕에 `updateFn`은 항상 **정확한 최종값**을 받아서, 위
"왜 `LayoutOrder`를 Slot이 대신 안 해주는가" 절의 `Source(index)` 예시처럼
새 원소를 처음부터 올바른 값으로 만들 수 있음(임시값→나중에 정정하는
이중 write가 생기지 않음) — `candidateIndex` 자체가 다음 값을 미리
계산해두는 것뿐이라 look-ahead(아직 안 본 뒤쪽 item을 미리 훑는 것)가
전혀 필요 없는, 여전히 단일 forward pass.

- **`data:Observer(fn)`**: 새 구독 프리미티브 아님 — 2026-08-07 여섯 번째
  세션에 이미 "등록 즉시 1회 실행" 확정된 그 메소드를 그대로 씀.
  `reconcile`은 매번 **현재 전체 스냅샷을 받아 O(n) 단일 패스로 diff**
  — 트리 전체를 비교하는 비싼 diff가 아니라 `seen` 셋 하나로 "새 key
  목록에 없는 건 지운다"만 판정하는 React/Vue/Solid류의 표준 key 기반
  방식, `data`가 참조를 유지한 채 뮤테이션+`Emit()`되는 경로도 지원해야
  하는 이상 최소 한 번은 훑어야 하는 게 불가피함.
- **`updateFn`을 매번 부르는 게 비싼 게 아닌 이유** — 흔한 경로(`prev`
  그대로 반환)는 함수 호출 하나뿐, 실제 Instance 생성/**[정정,
  2026-08-13 4차 감사] 언마운트**(파괴 아님 — 위 "구현" 절 `rawUnmount`
  참고)가 있는 건 key가 새로 나타나거나/사라지거나/filter로 구조가
  바뀌는 경우뿐.
  200개 중 값만 갱신되는 사이클엔 200번의 값싼 함수 호출이 있을 뿐,
  200번의 재구성이 있는 게 아님.
- **`mounted`/`userdata`를 정리하는 루프가 `mounted`가 아니라 이전
  사이클의 `keyIndex`를 순회하는 이유** — `userdata`가 이제 `result ==
  nil`이어도 살아남을 수 있어서(위 "반환값 두 개는 서로 독립"), 어떤
  key가 `mounted[key] == nil`인 채로(필터 탈락 상태) `data`에서 완전히
  사라지면 `pairs(mounted)`로는 그 key가 아예 안 잡혀서 `userdata`가
  못 치워지고 샘 — 직전 사이클에 실제로 존재했던 **전체** key 집합
  (`keyIndex`, 매 사이클 모든 key에 대해 채워짐)을 순회해야 이 케이스를
  놓치지 않음. `userdata` 안에 사용자가 직접 넣어둔 `Source`(예: 위
  `LayoutOrder` 예시의 `layoutOrder`)도 이 정리 대상에 자연히 포함됨 —
  `:List` 자신은 그 안을 안 들여다보지만, `userdata[key] = nil`이 되는
  순간 참조가 끊겨 GC됨.
- **`mounted`/`userdata`/`keyIndex`**: `activateList`(마운트 시점 1회
  실행)의 로컬 변수(클로저 업밸류) — 별도 전역 weak table(`Relate` 등)
  불필요, `inst`/`self`가 살아있는 동안만 존재하면 되고 죽으면 클로저도
  같이 GC됨(아래 "구독 시점" 절).
- **`reconcile`이 직접 호출하는 건 `rawAdd`/`rawUnmount`/`rawRemove`/
  `rawMove`** (**[재정정, 2026-08-18 구현 전 QA]** 2026-08-13 여섯 번째
  세션에 "reconcile의 제거는 전부 비파괴 언마운트"로 바꿨던 것을
  **부분적으로 되돌림** — `nil` 리턴/키 소멸은 다시 **파괴**가 기본이고,
  값 교체와 `Detach`만 비파괴. 아래 "`nil` 리턴은 파괴가 기본" 절이
  소스) — `rawExtract`/`rawSwap`/`rawClear`도 (위 "모든 공개 CRUD는
  가드+위임" 구조상) 당연히 존재하지만, `:List`의 reconcile 알고리즘
  자체가 그 셋을 직접 호출할 일이 없을 뿐. `rawUnmount`는 `rawRemove`의
  비파괴 짝으로서 `Extract` 계열과 공유하는 저수준 프리미티브 — 위 코드
  블록의 "rawRemove의 비파괴 짝 — `:List`의 reconcile과 `Extract`
  계열이 씀" 주석 참고. reconcile이 공개 `Slot:Extract` 대신
  `rawUnmount`를 직접 부르는 진짜 이유는 파괴 여부가 아니라, reconcile이
  이미 자기 `mounted` 맵으로 element를 추적 중이라 `Extract`의 "제거한
  element를 호출자에게 반환" 계약이 불필요하고, 공개 CRUD의 가드/에러
  체크도 reconcile 내부 상태 일관성상 중복이기 때문. 리오더는 항상
  절대 위치 이동이라 `Swap` 아닌 `Move` 경로, `Clear`는 reconcile 단위가
  아니라 Slot 전체 단위 연산이라 무관 — 이 둘의 근거는 여전히 유효.
- **리오더는 `Move`(의 가드 없는 버전)** — Parent를 안 건드리는 진짜
  저비용 경로. 최소-이동 알고리즘(LIS 기반 등) 자체는 구현 시점 최적화로
  미룸, 여기선 계약(파괴 없이 위치만 바뀜)만 확정.

### `nil` 리턴은 파괴가 기본 — `Detach`로만 비파괴 (2026-08-18 구현 전 QA, 확정 뒤집기; 이름 2026-08-19 확정)

**[재정정]** 2026-08-13 여섯 번째 세션은 "자동 경로는 언마운트, 명시적으로
지우라고 한 것만 파괴"라는 일반 규칙을 세우면서 `:List`의 reconcile까지
전부 비파괴로 바꿨는데, **`:List`에는 그 일반화가 안 맞는다**는 게 사용자
판정: *"List reconcile 에서 nil 리턴으로 지워지길 요구하는 경우는 비파괴일지,
파괴일지 생각해보아야할 것이 많은듯. 기본적으로 파괴가 맞기는 한데…"*

**세 경로로 갈린다**(위 `reconcile` 의사코드):

| updateFn의 반환 | 이전 요소(`prev`) 처리 | 왜 |
|---|---|---|
| 새 값(`result ~= nil`) | **언마운트만** | 밀려난 것뿐이지 "지워라"가 아님. `state<Frame>` 교체와 동형이고, `Slot { State<Slot> }` sugar(`:Single`)가 이 경로를 타므로 아래 "`State<Slot>` 교체" 절의 확정도 그대로 유지됨 |
| `nil` / `None` | **파괴**(`rawRemove`) | `updateFn`이 명시적으로 "이 자리를 지워라"라고 말한 것 |
| `Detach` | **언마운트만** + 재사용 대기 | 아래 |
| 키가 데이터에서 사라짐 | **파괴**(`rawRemove`) | `nil` 리턴과 같은 의미(그 아이템은 이제 없음) |

**`Detach` — `Instance.new`/`Destroy` 비용을 아끼는 재사용 경로.**
`filter` 용도처럼 "지금은 안 보이지만 곧 다시 필요할" 요소를 매번
파괴/재생성하는 건 비싸다. 그래서 `updateFn`이 **`Detach`와 함께 userdata를
반환**하면 그 자리는 파괴 없이 `Parent = nil`로만 내려오고 Slot에서 빠진다:

```lua
-- filter에서 걸러진 아이템 — 죽이지 말고 들고 있다가 나중에 되쓴다
return Detach, { old = prev, source = ... }
```

- **보존 주체는 `userdata`** — reconcile은 `mounted[key]`에서만 뺄 뿐
  `userdata[key]`는 그대로 기록하므로(위 의사코드), 반환한 테이블 안의
  `old`가 그 요소를 강하게 붙잡아 GC를 막는다. 다음 사이클에 `updateFn`이
  같은 `userdata`를 다섯 번째 인자로 다시 받으므로, 거기서 `old`를 꺼내
  그대로 반환하면 **재마운트**된다(`rawAdd` 경로).
- **userdata는 그 키가 데이터에 남아 있는 한, 명시적으로 `nil`을 반환하기
  전까지 안 지워진다** — 즉 "언제 진짜로 버릴지"를 `updateFn`이 결정한다.
- **⚠️ 단, 키가 데이터에서 아예 사라지면 얘기가 다르다(2026-08-18 감사에서
  발견한 갭).** 그 경우 reconcile의 소멸 루프가 `mounted[key]`/`userdata[key]`를
  **둘 다** 지우는데, `Detach`로 홀드 중이던 요소는 `mounted[key]`가 이미
  `nil`이라 `rawRemove`(파괴) 대상이 아니다 — 결과적으로 그 요소는
  **파괴되지도, `updateFn`에게 되돌려지지도 않고 참조만 끊겨 GC 대상이
  된다**(Parent는 이미 `nil`). 이건 같은 절의 표가 "키가 사라지면 파괴"라고
  못박은 것과도, 위 "버릴 시점은 `updateFn`이 정한다"와도 어긋난다.
  **세 선택지 중 하나를 M8 착수 전에 정할 것**(`question.md` 3번):
  (a) 소멸 루프가 `userdata[key].old`도 확인해 `rawRemove`로 파괴,
  (b) 지금처럼 참조만 끊고 GC에 맡김(단 표와 서술을 그 사실에 맞게 고침),
  (c) `updateFn`을 마지막으로 한 번 더 불러 처분을 묻는다.
  **지금 문서는 (a)를 기본으로 가정하지 않는다** — 결정 전이므로 구현 금지.
- **이름 확정 — `Detach`(2026-08-19).** 처음엔 가칭 `PopOnly`로 도입됐고
  사용자가 *"PopOnly 확정. 다만 이름은 변경될 수 있음. 이름에 대해서는 더
  생각해보아야함"*이라고 남겨 `question.md` 용어 정리 항목에 올라가
  있었음 — 이후 세션에서 후보들을 검토하다 `Detach`로 확정. 근거는 둘:
  (1) 이미 있는 `Extract`(바로 아래 불릿, 호출자가 직접 부르는 명령형
  추출)와 동사가 겹치면 헷갈리는데, `Detach`는 "화면(부모 계층)에서만
  떼어낼 뿐 관리 주체는 여전히 reconcile"이라는 의미라 `Extract`의
  "소유권을 통째로 호출자에게 넘긴다"는 것과 자연스럽게 구분됨. (2)
  `nil`(파괴)과의 대비도 더 직접적으로 드러남. 메커니즘(반환 규약 +
  userdata 홀드 + 재마운트)은 그대로 — 원문은
  `session/2026-08-19-02-detach-naming-and-placement.md`.
- **공개 표면 위치 확정 — 패키지 최상위 export(2026-08-19).** `Slot`은
  함수(팩토리)라 `Slot.Detach`처럼 붙이려면 callable-table+메타테이블이
  새로 필요한데, sentinel 상수 하나 때문에 그 구조를 들이는 건 과함
  (`conventions.md`의 "드문 오용이나 가상의 미래 요구까지 방어/최적화하려고
  구조를 복잡하게 만들지 않는다" 원칙). 대신 `None`과 같은 선례를 따른다 —
  `None`도 여러 곳(Slot 요소, Attribute, offsetSource)에서 쓰이는
  sentinel이지만 공개 표면은 패키지 최상위(`quad-base/src/init.luau`
  재노출)이고 실제 정의는 관련 로직 옆(`Dispatch/None.luau`)에 있다.
  `Detach`도 같은 패턴 — **정의는 Slot 관련 파일(`Slot.luau` 또는
  `Dispatch/Slot.luau`) 옆에 두고, `init.luau`에서 최상위로 재노출**한다.
  지금은 `:List` reconcile 한 곳에서만 쓰이지만 `None`도 처음엔 그렇게
  시작해 이후 재사용됐으므로 최상위에 두는 게 자연스럽다. 정확한 파일
  배치는 M6 구현 시점에 확정.
### ⭐ 소유권은 설치 시점에 정해진다 — `Owned` 옵션 (2026-08-21 구현 전 QA 4라운드 확정)

위 표("`nil` → 파괴")는 **`:List`가 그 요소를 만든 경우**를 전제한다. 그런데
`Slot:Add(state)` 라 sugar(`:Single` + 기본 identity `updateFn`, 아래 "반응형
raw 요소" 절)로 들어온 요소는 **사용자가 `state`에 담아 넘긴 것**이라 Slot이
죽이면 안 된다 — `state<Frame>` 교체가 이전 값을 파괴하지 않는다는 확정
의미론(아래 "`State<Slot>` 교체는 파괴가 아니라 언마운트" 절)과 정면으로
부딪히기 때문. 두 답을 다 만족시키는 축이 **"누가 그 요소를 만들었는가"**이고,
그건 사이클마다 달라지는 게 아니라 **설치 시점에 고정되는 속성**이다
(**사용자 확정, 2026-08-21**: *"unowned 로 나오는 경우가 state<Frame> 등을
주는 경우이므로 설치 시점이다에 동의함"*).

```lua
Slot:List(data, updateFn, keyFn?, opts?)     -- opts.Owned: boolean? (기본 true)
Slot:Single(state, updateFn?, opts?)
```

| | `Owned = true`(기본) | `Owned = false` |
|---|---|---|
| 누가 요소를 만드나 | `updateFn`(= `:List` 소유) | 사용자(`state`에 담아 넘김) |
| `updateFn`이 새 값 반환 | 밀려난 `prev` **파괴** | **언마운트만** |
| `updateFn`이 `nil`/`None` 반환 | **파괴** | **언마운트만** |
| 키가 데이터에서 사라짐 | **파괴** | **언마운트만** |
| owner가 죽음(`destroySlotTree`/`dispose`) | **파괴**(재귀) | **언마운트만** |
| `Slot:Add(state)` sugar | — | **이걸로 설치됨** |

- **`Detach`와는 직교하는 축이다** — `Detach`는 "지금은 안 쓰지만 **내 것**"
  (사이클마다 달라지는 판단), `Owned = false`는 "**애초에 내 것이 아님**"
  (설치 시점에 고정). 그래서 반환값 계열에 "unowned replace" 센티널을 하나 더
  만들지 않는다 — 만들면 두 의미가 한 이름에 섞인다(사용자 지적: *"의미론이
  분화한다"*).
- **`destroySlotTree`/`dispose`도 이 플래그를 봐야 한다** — `Owned = false`인
  Slot을 파괴할 땐 자기 요소를 죽이지 않고 언마운트만 한다. 그래서 플래그는
  클로저 업밸류가 아니라 **Slot 필드**(`slot._owned`)여야 파괴 walk가 읽을 수
  있다.
- **수동 CRUD와 안 부딪힌다** — 이 플래그는 `:List`/`:Single` 설치 시에만
  생기고, 그 Slot은 `_listed`라 수동 CRUD가 이미 막혀 있다(위 "`_crudUsed` ↔
  `_listed` 대칭").
- **혼합은 표현 못 함** — 한 리스트 안에 "내가 만든 것"과 "사용자 것"이 섞이는
  경우는 이 플래그로 못 가른다. 실사용 사례가 안 보여 지금은 안 다루고,
  필요해지면 `Detach` + 수동 관리로 우회할 수 있다.
- **⚠️ 이름은 `Owned`로 잠정** — `elementOwner`/`claimOwner`/`releaseOwner`와
  같은 뿌리라 골랐다. 다른 가칭들과 함께 용어 정리 대기열(`question.md` 1번).

**⚠️ 아직 안 닫힌 짝 항목** — `Detach`로 홀드된 요소를 **어디에 보관하고
언제 파괴하는지**(`slot._detached` 필드 + owner 죽을 때 `Effect`로 정리)와
`KeyGone` 센티널은 별개로 확인 대기 중이다.
`qa-request/pre-implementation-qa-round4-followup.md`의 `F-3` 절이 소스 —
**그게 닫히기 전엔 이 절의 "파괴" 칸을 구현하지 말 것**(무엇을 파괴 대상으로
훑을지가 거기서 정해짐).

- **`Slot`의 다른 비파괴 API와의 관계**: `Extract`/`ExtractAll`/`Splice`가
  이미 비파괴 추출을 제공하지만(위 "CRUD API 확정" 절) 그건 **호출자가
  직접 부르는 명령형 경로**다. `Detach`는 같은 일을 **reconcile 안에서
  선언적으로** 하기 위한 것이라 서로 대체 관계가 아니다.

### 구독 시점 — `:List()` 호출이 아니라 Slot 마운트 시점, lazy `bindLifetime`
(2026-08-09 일곱 번째 세션)

**문제**: 원래 초안은 `data:Observer(fn)`를 `:List()` 호출 그 자리에서 만들었음
— 근데 `:List()`는 `Slot():List(data, updateFn)`처럼 Slot이 아직 어디에도
마운트되기 전에 불리는 게 흔한 사용법이라, 그 시점엔 `inst`를 몰라서
`bindLifetime`을 걸 수 없었음(사용자가 직접 지적) — 마운트 대상이 나중에
`Destroy`돼도 이 구독을 멈출 방법이 없는 gap이었음.

**해법 — `Dispatch.setLength`가 이미 쓰고 있는 패턴 그대로 재사용**: 새
메커니즘 발명 아님. `:List()`는 `data`/`updateFn`/`keyFn`만 저장하고 반환,
실제 `data:Observer(fn)` 구독 + 최초 `reconcile`은 Slot 컨테이너 자신이
마운트되는 순간(`Dispatch/Slot.luau`의 `process(inst,k,self,index)` — 위
"`isMounted` 이중 추적 분리" 절이 이미 `self._mounted`를 세팅하는 바로 그
지점)에 `activateList(self, inst)`가 수행. `Dispatch.setLength(inst,i,
self.Length)`를 부르는 것과 같은 자리에서 같이 트리거되면 됨.

**`:List()`가 마운트 이후에 불리는 경우 — `self._mounted`면 즉시 활성화
(확정)**: 마운트는 1회성 이벤트라, `:List()`가 마운트보다 늦게 호출되면
그 이벤트를 기다리는 방식으론 영영 활성화가 안 됨 — `:List()`가
`self._mounted`를 확인해서 이미 참이면 그 자리에서 바로
`activateList(self, self._mountedInst)`를 호출(마운트 시점에 `inst`를
`self._mountedInst`로 같이 저장해둠). CRUD와의 상호배타 가드(`self._listed`)와
같은 자리에서 자연스럽게 처리됨 — 호출 순서에 대한 새 제약을 추가하지 않음.

**canExecute와 "등록 즉시 1회 실행"의 관계 — 초기 실행은 게이팅과 무관하게
무조건 일어남(사용자 확인)**: `data:Observer(fn)`가 등록되는 순간
(`bindLifetime` 호출 *이전*) `fn`이 이미 한 번 동기 실행됨(Observer 자체의
"등록 즉시 1회 실행" 계약) — 이 시점엔 아직 `bindLifetime`을 안 걸어
`observer`에게 gcconn 참조가 없으므로 `canExecute`를 물으면 거짓이겠지만,
애초에 최초 실행은 `canExecute`로 게이팅되는 대상이 아니라서 상관없음
(**[정정, 2026-08-14 다섯 번째 세션]** 원래 "`bindLifetime`이 `Subscribed`를
세팅 전이라"고 적혀 있었으나 `bindLifetime`은 그 필드를 안 건드림 —
`.Subscribed`는 전역 `:Subscribe()` 전용,
`archive/canexecute-inst-arg-reversed.md`). `bindLifetime`은 그
직후에 걸려서 **이후의** 재실행(`data`가 다시 바뀔 때)만 게이팅 —
`Dispatch.setLength`의 `bindLifetime(inst,observer)` 다음 줄에 있는
"등록 즉시 1회와 겹쳐도 무해"라는 주석과 정확히 같은 구조.

**Destroy 이후 — "재실행 막기"와 "관측 자체를 관두기"가 새 메커니즘 없이
한 번에 해결됨**: `inst`가 Destroy되면 `bindLifetime`의 `gcconn`(Roblox가
Destroy 시 자동으로 끊는 Connection)이 죽어 `canExecute`가 거짓이 되고
future 재실행이 no-op됨(위 "`state:Observer(fn)`" 절 원칙 재사용) — 그리고
"이전 state를 계속 관측하는 것도 관둬야 한다"는 요구도, `gchold`가
`Relate(inst)`(weak-keyed) 아래 있어서 `inst`가 죽으면 그 안에 강참조로
붙잡혀 있던 Observer/클로저(`mounted`/`userdata`/`keyIndex`를 포함해)가
전부 같이 GC 대상이 되는 것으로 공짜로 해결 — 명시적으로 구독을 끊는
새 코드가 필요 없음, `base/lifecycle-pattern.md`의 "정리(`retract`)는 기본적으로
GC에 위임" 원칙 그대로.

**부수 관찰(설계 아님, 메모만)**: `bindLifetime`이 `Relate(inst)` 기반이라,
"이 `inst`에 지금 어떤 Slot/Observer가 붙어있는가"를 나중에 weak하게
역조회하는 것도 같은 저장소로 가능해 보임(quad-debug의 "무엇이 무엇에
연결됐는가" 그래프와 맞닿을 수 있음) — 지금 설계할 필요는 없음, 필요성이
확인되면 그때.

### 왜 자유 함수/새 타입이 아닌가

처음엔 `List(data, updateFn, keyFn?) -> Slot` 같은 자유 함수(또는 `Slot`을
구조적으로 만족하는 새 타입 `List`)로 검토했으나 둘 다 기각:

- **자유 함수 기각**: `Source(default)`/`Ref(default)`/`Store({defaults})`가
  지켜온 "`Type(args)` 팩토리 이름 = 반환 타입"이라는 컨벤션이 깨짐 —
  `List(...)`이 `Slot`을 반환하면 이름과 실제 타입이 안 맞음.
- **새 서브타입(`List extends Slot`, Source⊇State 같은 구조적 서브타이핑)
  기각**: Source가 State의 서브타입이어야 했던 이유는 Source가 State보다
  진짜로 더 많은 공개 메소드(`:Set`/`:Emit`)를 갖기 때문 — 반면 이
  프리미티브는 Slot이 이미 가진 것(`Add`/`Remove`/`Extract`/`Clear`/
  `Move`/`Swap`) 위에 새 공개 메소드를 얹지 않음. 그냥 "자동으로 채워지고
  관리되는 Slot"일 뿐이라 별도 타입일 이유가 없음.
- **결론: `Slot`의 콜론 메소드.** "원천에 종속된 파생 데이터는 자유 함수
  생성자가 없고 메소드로만 얻어진다"(State/Observer)는 기존 분류 원칙과
  같은 모양 — 다만 여기 원천은 Source가 아니라 이미 만들어진 Slot 자신.
  Fusion의 `ForPairs`/`ForKeys`/`ForValues` 3분할도 이 재구성으로 통합
  방향이 자연스러워짐(단일 `:List`가 이미 Slot 메소드 이름공간 안에
  있으니 여러 진입점을 나열할 이유가 약해짐) — **통합 확정**.
- 이름 후보로 검토됐던 `Render`/`Draw`도 이 재구성으로 더 이상 "타입
  이름"이 아니라 "메소드 이름" 문제가 됐지만, `List`가 여전히 가장
  낫다고 판단(`Render`는 quad의 "렌더 주기 없음" 원칙과 메소드 이름으로
  써도 충돌 소지가 남고, `Draw`는 즉시모드 GUI 뉘앙스) — **`List`로 확정**.

## 자식으로 넘기는 클래스 스토어

자식에게 내려주는 클래스 스토어는 부모 쪽에서 미리 만들어서 내려보내는 게
편할 것 같다는 방향 — `store<<ChildClass.Props>>` 형태로 구성된 스토어를 만들면
됨(타입 표기는 러프한 스케치, 실제 문법은 tbox의 명시적 제네릭 적용 패턴
`f<<T>>(...)` — `.claude/initreq/tbox/CLAUDE.md:40-41` — 참고해서 확정할 것).

## 열린 질문 (`.claude/question.md`에도 취합)

- 재마운트 에러 처리(throw)는 확정. **[역전됨, 2026-08-13 여섯 번째 세션]
  "retract 시 폐기(옮기지 않음)"는 뒤집혔음** — 지금은 `State<Slot>` 교체가
  **언마운트**이고 이전 Slot은 파괴되지 않음(파괴는 명시적 `Remove`/`Clear`/
  `dispose`만). "실사용에서 불편하지 않은지 재검증"이라던 남은 항목도 그
  재설계로 해소됨 — 최신 설계는 아래 "`State<Slot>` 교체는 파괴가 아니라
  언마운트" 절이 정본.
- "클래스가 슬롯을 받는 방법"(Named Slot 없음)도 확정됨(위 "클래스가 슬롯을
  받는 방법" 절 참고).
- **[해소됨, 2026-08-09 세 번째 세션]** `add`/`remove`/`clear` CRUD 의미론,
  `isMounted` 이중 추적 분리, 키 기반 동적 컬렉션 재조정(`Slot:List`) —
  위 "CRUD API 확정"/"`isMounted` 이중 추적 분리"/"`Slot:List`" 절 참고.
- **[해소됨, 2026-08-09 여섯 번째 세션]** 여러 Slot이 형제로 섞일 때
  순서 보장 — 위 "여러 Slot이 섞일 때 순서 보장" 절 참고, 메커니즘은
  `base/dispatch-core-plan.md`의 "Length/Offset" 절이 최신 소스.

## Slot.Length — `:List`뿐 아니라 항상 노출됨 (2026-08-09 여섯 번째 세션)

Slot은 CRUD/`:List` 여부와 무관하게 `.Length: State<number>`를 항상
노출 — 지금 실제로 마운트된 요소 개수(사용자가 직접 CRUD로 넣든 `:List`
reconcile이 넣든 동일). **[2026-08-11 세션] Slot-in-Slot 중첩 허용
이후로는 정확히 "요소별 기여도의 합"** — plain 요소는 1, nested Slot
요소는 그 Slot 자신의 `.Length`(재귀) — 상세는 "Slot-in-Slot 중첩" 절
참고. plain 요소만 쓰는 흔한 경우엔 항상 합==개수라 체감 차이 없음.
두 용도를 겸함: (1) 사용자가 "n개 검색됨" 같은
UI에 직접 관측, (2) `Dispatch.setLength(inst, i, slot.Length)`가 형제
순서 보장(위 "여러 Slot이 섞일 때 순서 보장" 참고)에 내부적으로 읽는 바로
그 값 — 별도 두 State가 아니라 하나. `:List`의 filter 탈락이 실제
`Remove`(Visible 토글 아님)로 확정돼 있어서 `Length`는 자동으로 "실제
마운트된 것"만 반영 — 수동 Visible 토글을 쓰면 `Length`가 그걸 못 잡는
게 맞고, 그건 사용자가 별도 State로 계산해야 하는 몫.

**동적 자식은 반드시 `Slot` 또는 `state<Frame>`류 store-bind를 통해서만
추가/제거 — 그 외 경로는 UB(2026-08-10 세션, `base/dispatch-core-plan.md`의
"Length/Offset" 절 반영).** 둘 다 `Dispatch.setLength`/`setOffsetSource`를
정확히 호출하는 유일한 정당 경로라, 이걸 우회해서(예: 외부 코드가 Slot이
마운트해둔 부모 Instance에 직접 `.Parent = parentInst`로 자식을 끼워
넣는 것) 자식을 추가/제거하면 `Length`/형제 순서 계산이 그 변화를 몰라
조용히 어긋남 — 별도 방어 로직 없음, 문서 경고로만 남김.

## `Slot:Single(state, updateFn?)` — 확정 (2026-08-11 세션, `:List` 위의 순수 sugar)

기존 "백로그, 미착수"에서 실제 설계까지 완료됨 — 새 reconcile 로직
없이 **`:List`를 정확히 0/1개짜리 배열로 감싸는 sugar**:

```lua
local function identityUpdateFn(item) return item end

function Slot:Single(state, updateFn)
    updateFn = updateFn or identityUpdateFn   -- [2026-08-11 일곱 번째 세션] 기본값 추가

    local data = if isState(state)
        then state:Compute(function(v) return (if v:Get() == nil then {} else { v:Get() }) end)
        else (if state == nil then {} else { state })

    return self:List(data, function(item, index, offset, prev, ud)
        return updateFn(item, offset, prev, ud)   -- index는 항상 상수라 안 넘김
    end, function() return true end)   -- 고정 key
end
```

**`updateFn` 기본값(identity) — [2026-08-11 일곱 번째 세션] 추가.** 반응형
raw 요소(`Slot:Add(state)`, 아래 "반응형 raw 요소" 절)가 `Slot():Single(state)`의
sugar로 재정의되면서, `updateFn` 생략이 유효해야 그 sugar가 성립함 —
생략 시 `prev`/`userdata`/`offset`을 전혀 안 쓰고 매번 `item`을 그대로
반환(= 정체성이 바뀔 때마다 항상 다시 그리는 coarse swap).

- **`index`를 안 주는 이유**: Single은 형제가 자기 하나뿐이라 `index`가
  항상 상수(1 또는 존재 안 함)라 의미가 없음 — 나머지(`offset`/`prev`/
  `userdata`, 세 갈래 반환 규칙)는 `:List`와 100% 동일 규칙 재사용.
- **key를 고정값(`true`)으로 두는 게 핵심** — `state`가 A값에서 B값으로
  바뀌어도 같은 key라 `prev`가 유지되고, `updateFn`이 "새로 그릴지/
  그대로 쓸지"를 스스로 판단 가능(값 자체를 key로 쓰면 매번 다른 item
  취급돼서 파괴+재생성이 강제됨 — 원하는 동작이 아님).
- **원래 동기(`State<Frame?>`가 offset을 못 받는 문제)를 이걸로 완전히
  해결** — `updateFn`이 `offset`을 직접 받으므로, "offset을 얻으려고
  컴포넌트가 Slot을 리턴하는" 우회가 애초에 필요 없어짐. Slot-in-Slot
  중첩(아래 절)의 정당화 근거는 이것과 별개 — 컴포넌트 결합 시 결과
  타입이 뭐든(Instance/Slot) 균일하게 다룰 수 있어야 한다는 요구.
- `mounted`/`userdata`/`keyIndex` 전부 `:List`가 이미 갖고 있는 걸
  그대로 재사용, 코드 중복 없음. `:List`와 마찬가지로 `self._crudUsed`
  체크 대상(내부적으로 `:List`를 호출하므로 자동 적용).

## Slot-in-Slot 중첩 — 확정 (2026-08-11 세션)

**동기 — Slot을 원시 최소 요구가 아니라 컴포넌트 결합의 균일성 문제로
접근.** 카테고리 헤더+아이템 그룹(`outer:Add(header); outer:Add(itemsSlot)`)이
구체적 동기로 제기됐지만, 더 근본적인 이유는 **컴포넌트 결합** — `local
result = SomeComponent(props)`가 `Instance`를 리턴하든 `Slot`(멀티루트
워크어라운드, `base/component-composition-plan.md`)을 리턴하든, 호출부가
`outerSlot:Add(result)`를 분기 없이 그냥 부를 수 있어야 함. 지금까지
"요소 타입 제약"이 `Slot`을 암묵적으로 배제하고 있어서(`T = Instance`
단순화), 정확히 이 컴포지션 케이스가 막혀 있었음.

### 요소 타입 — `Slot` 허용

위 "요소 타입 제약" 절 갱신대로 `isMountable`이 `isSlot(v)`을 더 이상
배제하지 않음 — 나머지(Ref/PreRef/PostRef/Observer/Effect/Modifier 금지,
nil/None 금지)는 그대로.

### 재귀 메커니즘 — 새 프리미티브 없이 `Dispatch.setLength`/`setOffsetSource`를 Slot 자신 키로 재사용

> **🔭 [2026-08-21] `attachSlot`의 책임 분해가 확장 논의 대기 중** — 아래
> 의사코드가 지금 정본이고 그대로 유효하지만, 이 함수 하나가 지고 있는 책임이
> 일곱 개(부모 등록 offset/length, `:List` 실체화, 마운트 상태 전이, 배치
> 게이팅, 자식 배치, 재귀)라는 사용자 지적이 있었다 — *"attachSlot 의 기능이
> 너무 다양해진게 문제같음"*. 특히 **"부모에게 알리는 길이의 최종값은 flush가
> 끝나야 정해진다"와 "부기가 물리 조작보다 먼저"가 단일 함수로는 동시에
> 만족되지 않는다.** 책임 목록·순서 제약의 출처·분해 후보는
> `research/slot-attach-decomposition.md`에 정리해뒀다. **M2/M3를 막지는
> 않지만 M6(`:List`) 구현 전엔 결론이 나 있어야 한다.**

**✅ [해결, 2026-08-18 구현 전 QA 2라운드 후속]** 아래가 재사용하는
`Dispatch.setLength`/`setOffsetSource`/`recompute`가 배치 등록 중 크래시할
수 있던 문제(`RC-1`)는 해결됨 — `base/dispatch-core-plan.md`의
"배치 등록을 안전하게 만드는 Blocker 게이팅" 절이 소스. 이 문서에선 그
해법이 `attachSlot`의 flush 루프에 어떻게 적용되는지만 다룬다(아래
코드의 `blocker` 관련 줄).

`base/dispatch-core-plan.md`의 "Length/Offset" 절이 이미 확정해둔 두 함수는
owner 키(`inst`)가 물리 Instance일 필요가 없음(`Relate`가 아무 테이블이나
weak 키로 받음) — **Slot 자신을 owner 키로 재사용하면 최상위 마운트와
중첩 마운트가 완전히 같은 함수 호출**이 됩니다.

**[재정정, 2026-08-18 구현 전 QA 2라운드 후속] 호출 순서가 뒤집혀 있었음
— `setLength`가 먼저, `setOffsetSource`가 나중이던 것을 바로잡음.**
`base/dispatch-core-plan.md`의 "`NilHandler`" 절이 이미 확정해둔 **"호출
순서는 `setOffsetSource` → `setLength`"** 일반 규칙(해제 시점 계약에서
나왔지만 등록 시점에도 그대로 적용)과 이 `attachSlot` 의사코드가 계속
어긋나 있었던 것 — RC-1을 고치며 `setOffsetSource`가 즉시 계산을 하게
되면서 이 불일치가 드러남. 사용자 확정: *"length 를 알게되는 시점은 각
요소가 생성된 이후인데, 그럼 setOffset 이 먼저 안 되어있으면 offset
전파가 한번 더 일어나게됨"* — Slot의 진짜 `.Length`는 `activateList`가
자기 `:List`를 최초 reconcile한 **뒤에야** 확정되므로, `setLength`를 그
전에 부르면 등록 직후 값이 또 바뀌어 전파가 한 번 낭비된다. 올바른 순서는
**`setOffsetSource`(즉시 계산) → (Slot이면) 실체화 → `setLength`(그제서야
확정된 값으로 등록) → 물리 마운트**.

**[재정정, 2026-08-18 구현 전 QA 3라운드] "확정된 값으로 등록"은 값
자체가 아니라 이 순서를 지키는 한 자연히 따라오는 결과를 가리킨 표현이지,
`setLength` 호출 시점에 `slot.Length`의 **값**이 반드시 최종값이어야
한다는 뜻은 아니다.** 실체화(`activateList`)와 물리 마운트(flush 루프)의
순서를 더 트레이싱하며 `RC-3`/`RC-4`(둘 다 `activateList` 도중 아직
`self._mounted`가 안 세팅된 상태를 요구한다는 게 드러남 — 아래 코드의
"`_mounted`는 여기서 아직 세팅하지 않는다" 주석 참고)를 고치는 과정에서,
`slot.Length`가 실제로 최종값으로 안정되는 시점은 `activateList` 직후가
아니라 **flush 루프가 끝난 뒤의 마지막 `recompute`**로 한 단계 더
밀렸다 — `Dispatch.setLength(ownerKey, position, slot.Length)`가 넘기는
건 **State 객체 자신**이라, 등록 시점에 값이 아직 안 굳어 있어도
무해하다(부모는 객체를 구독해뒀다가 나중에 값이 바뀌면 정상 반응).
`setOffsetSource → setLength` 순서 자체(왜 `setOffsetSource`가 먼저여야
하는지)는 안 바뀜 — 상세 트레이싱은
`qa-request/pre-implementation-qa-round3.md`의 `RC-3`/`RC-4` 절.

```lua
-- quad-base, Slot.luau — 재귀적 "attach" 하나로 최상위/중첩 마운트 통합
local function attachSlot(slot, physicalTarget, ownerKey, position)
    -- [정정, 2026-08-13 세션] bindLifetime 호출은 여기 없음 — top-level 전용
    -- 앵커링은 SlotHandler.process(아래)로 이동. attachSlot 자신은 이제
    -- top-level/nested 어느 깊이에서 불려도 완전히 동일하게 동작하는 순수 구조적
    -- mount 로직만 담당(레이어 구분은 오직 이 함수를 부르는 쪽의 책임) — retract
    -- 쪽(destroySlotTree)이 이미 이 원칙대로였는데(자기 자신의 unbindLifetime은
    -- 안 하고 process가 반환하는 retract 클로저에서만 짝을 맞춤) process 쪽만 attachSlot 내부에
    -- ownerKey==physicalTarget 분기로 anchor 로직이 새어들어와 있던 비대칭이었음.

    local offsetSource = Source(0)
    Dispatch.setOffsetSource(ownerKey, position, offsetSource)   -- 먼저 — 앞선 형제 합으로 즉시 계산
    slot.Offset = offsetSource

    -- [재정정, 2026-08-18 구현 전 QA 3라운드, `RC-3`/`RC-4` 해결 —
    -- 사용자 설계] `_mounted`는 여기서 아직 세팅하지 않는다 — 그래야
    -- 아래 `activateList`가 실행되는 동안 `self._mounted`가 계속
    -- `false`라, `:List`의 reconcile이 부르는 `rawAdd`가 "아직 마운트
    -- 전"(= `_elements`에만 넣고 끝) 경로를 타서 이 시점엔 물리
    -- 마운트도 Dispatch 등록도 전혀 안 일어난다. 옛 코드는 `_mounted`를
    -- 맨 위에서 세팅해뒀었는데, 그러면 reconcile의 `rawAdd`가 매 항목마다
    -- 즉시 물리 마운트 + `Dispatch.setLength`를 태워(아래 flush 루프가
    -- 곧 다시 처리할 바로 그 자리를) 두 가지 문제를 냈다 — (a) 아직
    -- Blocker가 없어(그건 flush 루프 직전에야 생김) 매 항목마다 게이팅
    -- 없이 `recompute`가 돎(`RC-3`), (b) nested Slot 항목은 이 시점에
    -- 이미 `attachSlot`이 한 번 불렸는데, 아래 flush 루프가 같은 요소를
    -- 다시 순회하며 `attachSlot`을 **또** 불러 이중 실행됨(`RC-4`).
    -- `_mounted`를 `activateList` 뒤로 미루면 이 함수 안에서 실제
    -- 마운트가 일어나는 자리는 아래 flush 루프 단 하나로 통일된다 —
    -- `:List`든 수동 CRUD든 구분할 필요가 없어짐. 상세 트레이싱은
    -- `qa-request/pre-implementation-qa-round3.md`의 `RC-3`/`RC-4` 절.
    if slot._listed then
        activateList(slot, physicalTarget)   -- reconcile이 채우는 건 `_elements`뿐 — 물리 마운트는 안 함(위 참고)
    end

    slot._mounted = true
    slot._mountedInst = physicalTarget

    -- **[정정, 2026-08-18 3라운드]** `slot.Length`는 이 시점에 아직
    -- "확정된 값"이 아니다 — 최종 값은 아래 flush 루프 끝의 `recompute`가
    -- 매긴다. 여기서 넘기는 건 값이 아니라 **State 객체 자신**이라 무해함:
    -- 부모는 이 객체를 구독해뒀다가, 그 값이 나중에(flush 끝나고) 바뀌면
    -- 정상적으로 다시 반응한다(부모 배치가 아직 안 끝났으면 부모 자신의
    -- Blocker가 그 반응을 알아서 미룸 — 아래 "확인만 하고 새 결함 없음"
    -- 절 참고). 옛 주석("확정된 값으로 등록")은 옛 순서(`_mounted`가
    -- `activateList`보다 먼저라 그 안에서 이미 최종화되던 것) 기준이었고
    -- 이제는 안 맞아 정정.
    Dispatch.setLength(ownerKey, position, slot.Length)

    -- attach 전에 이미 들어와있던 요소들(수동 CRUD로 마운트 전 `:Add()`된
    -- 것) **및** 방금 `activateList`가 `_elements`에만 채워둔 `:List`
    -- 결과물 — 이제 이 flush 루프가 어느 경로로 왔든 상관없이 유일한
    -- 물리 마운트 지점이다. `slot._elements`의 개수(N)가 이미 정해진 채
    -- position을 하나씩 등록하는 배치라 `Dispatch.drive`와 같은 크래시
    -- 위험이 있음(`RC-1`) — 이 Slot 자신의 owner 키로 별도 Blocker를 새로
    -- 만들어(부모 Blocker와 절대 공유하지 않음 — base/blocker-plan.md의
    -- "재진입" 절) 같은 On→등록→OffWithoutEmit→recompute 패턴을 적용.
    local blocker = getBlocker(slot)   -- Relate(slot) 기반, lazy 생성 — 이 Slot 전용
    blocker:On()
    for i, element in ipairs(slot._elements) do
        if isSlot(element) then
            attachSlot(element, physicalTarget, slot, i)   -- 재귀, ownerKey가 이제 slot 자신
        else
            -- 평범한 Instance 요소도 같은 순서: 자기 자리의 offset은 아무도
            -- 안 읽으므로 None(참여만, 소비 없음), length는 상수 1.
            Dispatch.setOffsetSource(slot, i, None)
            Dispatch.setLength(slot, i, 1)
            element.Parent = physicalTarget   -- quad-roblox 글루가 실제 수행
        end
    end
    blocker:OffWithoutEmit()
    local bk = getBookkeeping(slot)
    if bk then recompute(slot, bk) end   -- 여기서 slot.Length가 비로소 진짜 값으로 확정됨
end
```

**⚠️ [신설, 2026-08-18 3라운드 감사 후속] 좁은 엣지 케이스 — 배치 밖에서
이 Slot이 단독으로 (재)마운트되면, 부모의 `recompute`가 아직 안 굳은
`slot.Length`로 한 번 헛돌 수 있다.** `Dispatch.setLength(ownerKey,
position, slot.Length)`(위 코드)는 `slot.Length`가 `State`라 등록 즉시
1회 실행을 동기로 태우는데, 이 `attachSlot` 호출이 `Dispatch.drive`의
배치나 부모 Slot의 flush 루프 **안**이면 부모 Blocker가 아직 켜져 있어
안전하게 스킵되지만, **배치 밖**(예: `state<Slot>` 값이 steady state에서
반응형으로 교체될 때, 부모 owner의 Blocker는 이미 꺼진 채)이면 부모의
`gatedRecompute`가 즉시 실행돼 아직 flush가 안 끝난 `slot.Length`로 한
번 계산한다 — flush가 끝나고 `slot.Length:Set(최종값)`이 다시 발화하면
정확한 값으로 자기 교정된다. 크래시도 영구적으로 틀린 값도 아니고
최악의 경우 한 프레임짜리 낭비 재계산 — 손대지 않기로 함, 다만 이
자리를 다시 만질 때 놓치지 않도록 기록. 트레이싱 원문은
`qa-request/pre-implementation-qa-round3.md`의 "확인만 하고 새 결함
없음" 절.

**최상위 마운트(`Dispatch/Slot.luau`)는 이제 이 함수 호출 한 줄:**
```lua
-- process(inst, k, slotValue, index)
attachSlot(slotValue, inst, inst, k)   -- ownerKey = 물리 inst 자신
```

**이미 마운트된 outer에 nested Slot을 나중에 `Add`하는 경우(런타임에
카테고리 추가):**
```lua
-- rawAdd 안, element가 Slot이고 self가 이미 마운트돼 있을 때
if isSlot(element) and self._mounted then
    attachSlot(element, self._mountedInst, self, index)
end
-- self가 아직 마운트 전이면 _elements에만 들어가고, self가 나중에
-- attachSlot될 때 위 flush 루프가 처리
```

**이 런타임 단건 경로는 Blocker 게이팅이 필요 없다(사용자 확인,
2026-08-18)** — *"그건 이미 마운트가 된 이후라서 별 상관 없음... 새로운
개체가 뒤에 붙는 현상에서는 위 요소들로 하여금 위치를 구하면 돼, 뒷
요소를 밀어내는게 아니라서, setLength 가 emit 되지 않는것에 영향 안
받고 수행 가능함"* — 이 시점엔 `self`의 Blocker가 이미 flush 배치를
끝내고 `OffWithoutEmit()`으로 꺼져 있고, 새로 등록되는 position보다
앞선 모든 position은 이미 안정적으로 채워져 있어 `nil` 자리가 생길
여지 자체가 없다.

`recompute`가 owner가 Slot이면 그 `.Length`에도 합계를 반영하도록
확장됐으므로(`base/dispatch-core-plan.md` 참고) — `Slot.Length`는 더
이상 raw 개수가 아니라 **"요소별 기여도의 합"**(plain=1, nested
Slot=그 `.Length`)이 됨. plain 요소만 있는 흔한 경우엔 항상 합==개수라
체감 차이 없음.

### 파괴 — 재귀적 `Clear()` 금지, flat teardown

**재귀적으로 `Clear()`(요소별 `Remove` 반복)를 하면 죽는 서브트리
내부에서 불필요한 shift+recompute가 요소 수만큼 반복되어 비용이 커짐 —
대신 순수 파괴 walk만 하고, outer 쪽 recompute는 자기 위치 하나에
대해서만 한 번 돎:**

```lua
-- [신설, 2026-08-13 감사 후속] 비파괴 언마운트 — `State<Slot>` 교체/`Extract`
-- 계열이 쓰는 경로. `destroySlotTree`와 **딱 하나만 다름: 실제로 안 죽인다.**
-- 물리 트리에서만 떼어내고 `_elements`/자식 소유권은 통째로 보존하므로,
-- 같은 Slot을 나중에 다른 곳에 다시 마운트할 수 있음(= 포탈).
local function unmountSlotTree(slot)
    for i, element in ipairs(slot._elements) do
        if isSlot(element) then
            unmountSlotTree(element)   -- 재귀 — 중첩 Slot도 똑같이 비파괴
        else
            element.Parent = nil       -- Destroy 아님(quad-roblox 글루가 수행)
        end
        -- releaseOwner를 **안 부름** — 자식들은 여전히 이 slot의 소유. 이게
        -- destroySlotTree와의 핵심 차이(파괴는 소유권까지 반납, 언마운트는 유지).
    end
    local bk = getBookkeeping(slot)
    if bk then
        for i, observer in pairs(bk.observers) do
            unbindLifetime(observer)   -- 물리 target에 걸린 배관만 해제
        end
    end
    slot._mounted, slot._mountedInst = false, nil
    -- [정정, 2026-08-20 `SL-75`] slot.Offset은 건드리지 않는다 — nil로 되돌리면
    -- 그 Source를 이미 구독 중인 다운스트림이 영구히 끊긴다(포탈이 깨짐).
    -- stale한 채 남겨두고, 재마운트 시 setOffsetSource의 즉시 계산이 덮어쓴다.
    -- slot 자신의 unbindLifetime / releaseOwner / owner쪽 setLength·setOffsetSource는
    -- 호출부 몫 — destroySlotTree와 동일한 층위 분리.
end

local function destroySlotTree(slot)
    for i, element in ipairs(slot._elements) do
        -- [재정정, 2026-08-20 구현 전 QA 4라운드 `C-4`] 여기서 releaseOwner를
        -- 명시적으로 부르지 **않는다** — 2026-08-13 감사가 넣었던 것을 되돌림.
        -- 근거는 아래 "소유권 반납은 GC에 맡기면 안 됨" 절의 재정정 참고.
        if isSlot(element) then
            destroySlotTree(element)   -- 재귀는 "파괴"에만, choreography 없음
        else
            element:Destroy()
        end
    end
    local bk = getBookkeeping(slot)    -- 이 slot이 자기 자식들 위해 등록해둔 observer들
    if bk then
        for i, observer in pairs(bk.observers) do
            unbindLifetime(observer)
        end
    end
    -- [정정, 2026-08-13 감사] 마운트 상태도 되돌림 — 안 그러면 파괴된 Slot이
    -- `_mounted == true`로 남아 "마운트된 Slot의 재마운트는 즉시 throw"(위 절)에
    -- 영원히 걸리고, `_mountedInst`가 죽은 inst를 계속 강하게 붙잡음.
    slot._mounted, slot._mountedInst = false, nil
    -- [2026-08-12 열여섯 번째 세션, 스코프 정정] slot 자신의 unbindLifetime은
    -- 여기서 안 부름 — attachSlot이 최상위에서만 bindLifetime하므로 짝도
    -- 최상위 파괴 지점(SlotHandler.process가 반환하는 클로저, 위)에서만 한 번.
    -- destroySlotTree는 재귀 전체에서 항상 이 위치까지만(자식 Observer 정리) 담당.
end

-- [명확화, 2026-08-13 감사에서 index/element 불일치 발견해 보강] 아래
-- 시그니처는 index 기준 예시 — 위 "raw* 내부 호출 규약" 절이 이미
-- 못박았듯 reconcile(위 "여러 Slot이 섞일 때" 절 근처)은 element 기준으로
-- rawRemove(self, prev)를 부름. **같은 불일치가 rawUnmount에도 그대로
-- 있음** — 아래 reconcile 예시의 rawUnmount(self, prev) 호출도 prev가
-- element(mounted[key])이지 index가 아님. 둘 중 하나로 통일할지 얇은
-- 변환 계층을 둘지는 아직 M6 구현 세부로 열려 있음 — 이 블록/아래
-- reconcile 블록 둘 다 그 결정 전 illustrative 예시.
-- [신설, 2026-08-13 여섯 번째 세션] rawRemove의 비파괴 짝 — `:List`의
-- reconcile과 `Extract` 계열이 씀. rawRemove와 **딱 하나만 다름: 안 죽인다.**
function rawUnmount(self, index)
    local element = self._elements[index]
    local bk = getBookkeeping(self)
    if bk.observers[index] then
        unbindLifetime(bk.observers[index])
    end
    releaseOwner(element, self)   -- 소유권은 반납(이제 다른 곳에 넣을 수 있음)
    if isSlot(element) then unmountSlotTree(element) else element.Parent = nil end

    spliceArraysDown(self, index)   -- _elements/lengthList/sourceList/observers/bk.N — 아래 참고
    recompute(self, bk)
end

function rawRemove(self, index)
    local element = self._elements[index]
    local bk = getBookkeeping(self)
    if bk.observers[index] then
        unbindLifetime(bk.observers[index])  -- outer가 이 위치 위해 등록해둔 observer
    end
    releaseOwner(element, self)   -- [정정, 2026-08-13 감사] 원래 이 줄이 의사코드에서
                                  -- 빠져 있었음(산문 쪽 "요소 소유권" 절은 rawRemove/
                                  -- rawExtract가 releaseOwner를 부른다고 이미 명시하고
                                  -- 있었는데 코드만 불일치) — 엄격 releaseOwner가
                                  -- 들어온 뒤로는 이 누락이 실동작 차이를 만듦
    if isSlot(element) then destroySlotTree(element) else element:Destroy() end

    spliceArraysDown(self, index)   -- _elements/lengthList/sourceList/observers/bk.N — 아래 참고
    recompute(self, bk)             -- outer 자기 자신 레벨에서 딱 1회만
end
```

**[신설, 2026-08-18 구현 전 QA 3라운드] `spliceArraysDown`이 밀어야 하는
배열 목록(아래)에 빠진 게 있었고, `bk.N`도 같이 줄여야 한다는 것 자체가
이 코퍼스 어디에도 명시된 적이 없었음.**

- **`bk.observers`도 같이 당겨야 함** — 위 코드가 이미 `bk.observers[index]`를
  읽어 `unbindLifetime`하지만(제거되는 그 위치의 것), `spliceArraysDown`
  자신이 이동시켜야 하는 배열 목록에 지금까지 `observers`가 빠져 있었다
  (`_elements`/`lengthList`/`sourceList` 셋만 언급됨). `bk.observers[i]`는
  `Dispatch.setLength`가 그 자리 length가 `State`일 때만 채우는(위
  "`setLength` 구현" 절) position-indexed 배열이라, 나머지 셋과 똑같이
  뒤 position들이 한 칸씩 당겨질 때 같이 안 당기면 이후 그 position의
  observer가 엉뚱한 것(옛 이웃의 observer)을 가리키게 된다.
- **`bk.N`도 여기서 하나 줄여야 함** — `recompute`(`base/dispatch-core-plan.md`
  "Length/Offset" 절)가 `for i = 1, bk.N do`로 순회하는 그 상한. **`bk.N`의
  정의 자체가 이 코퍼스 어디에도 없던 갭**이었다(`qa-request/
  pre-implementation-qa-round3.md`의 "`bk.N`의 수명주기" 절 — **사용자
  확정(2026-08-18)**: *"bk.N = 그때그때 실제 개수(새 최대 위치가 등록될
  때마다 증가, spliceArraysDown이 압축할 때 감소)로 두 owner 타입에
  동일하게 적용"*). 즉 `bk.N`은 `Dispatch.setLength`가 이전에 본 적
  없는 더 큰 position을 등록할 때마다 그 값으로 늘어나고(`setOffsetSource`는
  건드리지 않음 — 항상 `setLength`보다 먼저 불려서 그 시점엔
  `lengthList[i]`가 아직 없으므로, `Dispatch.drive`/`attachSlot`의 flush
  배치도, Slot의 런타임 단건
  `rawAdd`도 이 하나의 규칙으로 통일), `spliceArraysDown`이 위치 하나를
  물리적으로 지울 때(`rawRemove`/`rawUnmount`) 그만큼 줄어든다. **`Dispatch.drive`의
  `inst`에서는 이 규칙이 사실상 눈에 안 띈다** — 최상위 배열 리터럴은
  구조적으로 늘거나 줄지 않으므로(전체 재-dispatch만 있음) `bk.N`이
  등록이 끝난 뒤로는 그냥 고정값처럼 보일 뿐, 별도 케이스가 아니라 같은
  규칙의 특수한 안정 상태다.
- **왜 이게 `RC-1`의 크래시를 다시 불러오지 않는가**: `Dispatch.drive`/
  `attachSlot`의 배치 등록 중엔 `recompute`가 각 owner의 Blocker
  게이팅으로 아예 안 도는데(`blocker:IsOn()`만 확인, `bk.N`은 안 봄) —
  그래서 배치 도중 `bk.N`이 최종값보다 작은 채로 계속 늘어나는 중이어도
  안전하다. `RC-1`의 원래 크래시는 **`bk.N`이 배치가 시작되기도 전에
  이미 최종 크기로 고정돼 있었던 것**의 부산물이었다는 게 이번에 다시
  확인됨 — 지금은 그 전제 자체가 없다. 그 대신 Blocker 게이팅이 여전히
  필요한 이유는 크래시 방지가 아니라 **비용**(등록마다 `recompute`가
  한 번씩 도는 O(N²) 대신 배치 끝에 O(1)번만) — `RC-1` 해결 논의에서
  사용자가 직접 지적한 "이러면 첫 실행에서 계속 recompute 비용이 쌓임"
  문제 그대로.

**왜 `unbindLifetime`이 꼭 필요한지**: `bindLifetime`은 물리 target
인스턴스 생명주기에 걸려있는데, 죽는 건 "이 nested Slot 하나"고 물리
target(공유 부모)은 계속 살아있으니 GC가 자동으로 안 치워줌 — 명시적으로
안 풀면 카테고리가 자주 추가/삭제되는 UI에서 조용히 새는 옵저버가
쌓임. 반대로 물리 target 자체가 죽는 경우(최상위 Destroy)는 지금처럼
GC가 전부 한 번에 정리하니 손 안 대도 됨 — 이 구분은 새 원칙이 아니라
"GC 정리는 물리 target 생명주기 단위"라는 기존 원칙이 nested Slot에서
처음으로 그 경계 바깥의 케이스(target은 살아있는데 논리 서브트리만
죽는 경우)를 만나서 드러난 것뿐.

- **Length 변경은 정확히 offset 변경으로만 전파됨, 별도 채널 없음** —
  수정된 `recompute`(`base/dispatch-core-plan.md` 참고)를 보면 `:Set()`이
  호출되는 대상은 (a) 뒤 형제들의 offset, (b) owner가 Slot이면 그
  `.Length` 딱 둘뿐. Length 값 자체는 읽히기만 함(`:Get()`/Observer
  트리거) — (b)로 올라간 `.Length`도 한 단계 위에서는 그냥 또 다른
  `lengthList` 항목이라 같은 패턴이 재귀될 뿐, 새 전파 채널이 아님.

### "위치 이전 기억"은 base 책임 아님 — backend가 필요하면 `Relate`로

Slot-in-Slot 자체는 순수 숫자(Length/Offset) 계산만 재귀적으로 하고,
"나 이전에 물리적으로 어디에 있었지" 같은 backend 종속적 위치 정보는
전혀 안 다룸 — 필요한 backend(예: DOM `insertBefore` 기반)가 자기
`Relate`로 알아서 저장해야 할 몫. web 백엔드는 `insertBefore`/
`removeChild`가 물리적으로 밀고/당겨주므로, "지금 이 위치의 물리적
이전 형제가 누구인지"만 삽입 시점에 알면 되고 이미 배치된 형제들의
프로퍼티를 재작성할 필요가 없음 — 기존 "DOM류 물리 순서 백엔드에도
같은 base 메커니즘이 그대로 재사용됨"(2026-08-09 여섯 번째 세션) 확정과
정합적, 중첩이 생겨도 이 결론은 안 바뀜.

**기각된 대안 — DOM 백엔드가 nested Slot을 실제 `<div>` 중첩으로
매핑하는 안.** 검토했으나 기각 — React `<></>`(Fragment)가 존재하는
이유와 정확히 같은 이유로 Slot도 **의도적으로 wrapper 없는** 그룹핑
도구라, 논리적 중첩을 물리 `<div>` 중첩으로 매핑하면 이 wrapper-less
원칙 자체가 깨짐(flexbox/grid 등에서 직계 형제를 기대하는 CSS가
깨질 수 있음). 어느 backend든 nested Slot의 리프는 항상 flat하게
같은 물리 부모의 자식이어야 함 — 그래서 위 숫자 기반 메커니즘이
Roblox뿐 아니라 web에도 그대로 필요.

### 0-based 개수 vs 1-based Lua 인덱스

`offset`/`sum`은 0-based 개수(카디널 수)고, `_elements`/`updateFn`의
`index`는 1-based Lua 배열 관례 — `index + offset` 공식이 이 둘을
의도적으로 섞는 것. 상세는 `base/dispatch-core-plan.md`의 "`offset`/`sum`은
0-based 개수" 절 참고.

## 반응형 raw 요소 — `State<T>`/`Source<T>`도 Slot 요소로 허용 (2026-08-11 일곱 번째 세션)

**동기 — 사용자 제기**: Slot이 지금까지 `State<Frame>`/`State<Slot>`처럼
State/Source로 감싼 값을 raw 요소로 못 받았는데, 이미 확정된 메커니즘만
합성하면 새로 만들 것 없이 구현 가능하다는 지적.

**확정**: `Slot:Add`(및 `Slot(initial)` 생성자 sugar)가 받는 `element`의
타입은 `T | State<T> | Source<T>`(`T = Instance | Slot<Instance>`, 위
"Slot-in-Slot 중첩"의 자기 참조 제네릭과 합성) — 임의 깊이로 조합 가능.

### [정정, 같은 세션 후속] 최초안(별도 position-keyed StoreBind 구독) 기각 — 순수 `:Single` sugar로 대체

최초에는 "`rawAdd`가 그 위치에 대해 `Dispatch/StoreBind.luau`류 재-dispatch
구독을 걸고, Length 기여도도 `state:Compute(...)`로 파생시켜 `setLength`에
넘기는" 별도 메커니즘을 검토했으나 **사용자가 실제 문제를 지적해 기각**:

1. **`State<T?>`(nilable)를 지원하려면 "가끔 없음"을 표현해야 하는데,
   `_elements` 배열에 직접 `None`을 넣는 것 말고 방법이 없어져서 배열 파트
   `None`을 다시 끌어들이게 됨.**
2. **그러면 `Length` 계산도 이 케이스를 따로 알아야 함** — "요소별
   기여도의 합"이라는 기존 공식이 예외를 갖게 됨.
3. **`Move`/`Swap`이 인덱스를 재배치할 때마다 그 위치에 물린 구독도 같이
   옮겨야 하는 인덱스-구독 동기화 부담이 새로 생김** — 이건 정확히
   `:List`가 element가 아니라 `key` 기준으로 설계된 이유(위 "CRUD API
   확정" 절)와 정면으로 부딪히는 회귀.

**올바른 구현 — 새 메커니즘 전혀 없이 순수 sugar**: `element`가
`isState(element)`(State/Source 둘 다 포함하는 기존 집합 판별,
2026-08-06 후속 세션 확정)면, 그 자리에 **내부적으로 새로 만든 `Slot():
Single(element)`을 대신 삽입** — raw 반응형 요소는 전부 Slot-in-Slot
중첩(위 절) 위에 얹힌 `:Single`의 얇은 sugar일 뿐이다:

```lua
function Slot:Add(element, index)
    if isState(element) then
        local sub = Slot()
        sub:Single(element)   -- updateFn 생략 시 identity 기본값(아래 참고)
        element = sub
    end
    return rawAdd(self, element, index)
end
```

**`:Single`의 `updateFn`을 선택 인자로 완화 — 기본값은 identity.** 이
sugar가 성립하려면 `:Single(state)`(updateFn 생략)이 유효해야 함 —
`Slot:Single(state, updateFn?)`, 생략 시 `function(item) return item end`.

**이게 최초안의 세 문제를 전부 없애는 이유**:
- **`_elements`엔 `None`이 절대 안 들어감** — 바깥 Slot 입장에서 이
  위치의 값은 항상 `sub`(안정적인 Slot 레퍼런스)고, "지금 진짜 뭔가
  마운트돼 있는가"는 `sub` 내부(`:Single`이 감싼 `:List`의 0/1개 데이터)로
  완전히 옮겨감 — `sub`가 비어있는 것과 `_elements[index] == None`은
  전혀 다른 것(전자는 이미 "빈 Slot"이라는 정상 상태, Slot-in-Slot
  자체가 처음부터 이 경우를 지원).
- **Length 계산도 새로 손댈 것 없음** — `Slot.Length`가 이미 "요소별
  기여도의 합"(nested Slot=`.Length`)으로 정의돼 있어서, 비어있는
  `sub`가 자동으로 0을 기여함(Slot-in-Slot 중첩 절의 기존 recompute
  그대로).
- **Add/Remove/Move/Swap도 전부 기존 계약 그대로** — `_elements[index]`가
  항상 안정적인 `sub` 레퍼런스라, `Remove(index)`는 기존
  `destroySlotTree`로 `sub` 전체를 정리하면 끝, `Move`/`Swap`도 `sub`
  레퍼런스 하나를 옮기는 것뿐이라 인덱스-구독 동기화 문제 자체가 없음
  (`:List`의 reconcile은 `key` 기준으로 독립 동작, `sub`가 바깥에서
  어느 인덱스에 있든 상관 안 함).
- **`State<T?>`(nilable)도 특별 취급 없이 그냥 됨** — `:Single`이 이미
  `if v:Get() == nil then {} else {v:Get()}`로 nil을 "빈 리스트"로 흡수하므로, raw 직접
  전달 요소(`Add(element)`, State로 안 감싼 경우)에만 여전히 non-nil이
  요구되고, `State`/`Source`로 감싼 값은 내부적으로 nilable이어도 아무
  문제 없음 — 위 "요소 타입 제약" 절의 nil/None 금지는 **State/Source로
  감싸지 않은 raw 값에만 적용되는 규칙으로 범위가 좁혀짐**.

**"coarse swap"은 `updateFn = identity`가 만드는 결과일 뿐, 별도
메커니즘의 산물이 아님** — 기본 `updateFn`(`function(item) return item
end`)이 `prev`/`userdata`를 완전히 무시하므로 매 사이클 `result ~= prev`가
거의 항상 성립해 실질적으로 항상 다시 그리지만, 이건 `:List`/`:Single`의
reconcile이 원래 갖고 있는 세 갈래(버림/다시 그림/source만 갱신) 중
"다시 그림"만 계속 타는 특수 케이스일 뿐 — 코드 레벨의 별도 경로가
아니다. patch-reuse가 필요하면 사용자가 직접 `Slot():Single(state,
myUpdateFn)`을 불러 `myUpdateFn` 안에서 `prev`/`userdata`를 활용하면 됨.

**`:Single`/`:List`와의 관계 — 대체가 아니라 굵기(granularity)가 다름**:
- **raw `State<T>` 요소(`Add(state)`)**: `updateFn` 기본값(identity)의
  `:Single` — coarse swap, `prev` 재사용 없음.
- **`Slot():Single(state, updateFn)`**: `updateFn`을 직접 지정해
  `prev`/`userdata`로 patch-reuse + `offset` 접근까지 원할 때 — **`:Single`이
  애초에 생긴 이유가 정확히 이 offset 접근**(`updateFn`이 LayoutOrder류를
  계산하려면 offset이 필요한데, raw 요소 sugar의 기본 identity
  `updateFn`은 이걸 안 씀).
- 둘은 같은 메커니즘 위의 다른 `updateFn`일 뿐이라 언제든 서로
  전환 가능(raw로 시작했다가 patch-reuse가 필요해지면 그냥 `updateFn`을
  명시하는 `:Single` 호출로 바꾸면 됨).

**조합 예시(사용자 제시)**:
```lua
return Slot {
    State<Frame> --[[ 리스트 헤더 — 항상 존재, 정체성만 가끔 바뀜 ]],
    Slot():List(items, updateFn) --[[ 아이템 그룹 — 개수/순서가 동적 ]],
}
```
헤더처럼 LayoutOrder(offset) 참여가 필요 없는 raw 요소는 그냥
`State<Frame>`으로 두고, 아이템처럼 개수가 변하며 형제 순서 보장이 필요한
그룹은 `Slot():List(...)`로 감싸는 식으로 **한 Slot 안에서 자유롭게 섞어
쓸 수 있음** — Slot-in-Slot 중첩(위 절)과 이 반응형 raw 요소가 서로
독립적으로 조합됨을 보여주는 예.

### `State<Slot>` 재설정 시 소유권이 안전한가 — 확인됨 (2026-08-13 감사, 사용자 질문)

**질문**: `Slot { state<Slot> }`에서 그 state가 다른 Slot으로 재설정되면
소유권/마운트 상태가 정확히 갈리는가. 그리고 이걸 "래퍼가 불변이라
괜찮다"로 설명할 게 아니라 **Slot-in-Slot 자체가 일반적으로 안전해야**
하는 것 아닌가(사용자 판단: 후자가 맞음).

**결론: 후자가 맞고, 실제로 성립함.** 위 sugar 때문에 구조는 항상
`outer._elements[i] = sub`(래퍼 Slot, 이 위치에 **영구 고정**) →
`sub:Single(state)` → 그 `:List`의 `reconcile`이 안쪽만 교체 — 이고,
`reconcile`은 `result ~= prev`일 때 **`rawUnmount(self, prev)` 다음에
`rawAdd(self, result, pos)`** 순서로 부름(위 "구현" 절 — **[정정,
2026-08-13 여섯 번째 세션]** 옛 `rawRemove`(파괴)에서 비파괴
`rawUnmount`로 바뀜, 다만 `rawUnmount`도 `releaseOwner`를 부르므로
아래 소유권 표는 그대로 성립). 즉 소유권이
**반납 → 재클레임** 순서로 정확히 갈림:

| 시점 | `elementOwner[innerA]` | `elementOwner[innerB]` |
|---|---|---|
| 최초 reconcile | `sub` | — |
| state가 B로 재설정, `rawUnmount(sub, innerA)` | `nil`(releaseOwner) | — |
| 이어서 `rawAdd(sub, innerB, pos)` | `nil` | `sub`(claimOwner) |

바깥(`outer`) 입장에선 `_elements[i]`가 계속 `sub`라 아무 일도 안
일어나고, 소유권 판정도 `sub` 아래 한 레벨에서만 갈림 — **래퍼가
불변이라는 사실에 기대는 게 아니라, nested CRUD의 release→claim 규율
자체가 안전성을 만듦.** 그래서 `Slot { Slot { Slot } }`처럼 손으로
중첩한 경우에도 정확히 같은 규칙 하나로 동작함(래퍼 sugar는 그저 그
일반 메커니즘의 사용자일 뿐).

**단 이 결론은 위 "요소 소유권" 절의 2026-08-13 감사 수정 **둘**을 전제함** —
(1) nested `claimOwner`가 엄격(같은 owner 재클레임도 error)이라
`Slot { a, a }`가 실제로 막히고, (2) `rawRemove`/`rawUnmount`가
`releaseOwner`를 실제로 부름(의사코드에서 빠져 있었음). 둘 중 하나라도
빠지면 이 표의 중간 단계가 어긋남.
**[정정, 2026-08-20 `C-4`]** 원래 여기 셋째로 "(3) `destroySlotTree`가 자식
소유권을 명시적으로 반납"이 있었으나 그 수정 자체가 되돌려졌다(같은 절의
재정정 참고) — **이 표와는 무관**하다. 이 표가 다루는 건 `reconcile`의
`rawUnmount`→`rawAdd` 왕복이고 파괴 경로가 아니기 때문.

### [전면 정정, 2026-08-13 여섯 번째 세션 후속, 사용자 결정] `State<Slot>` 교체는 **파괴가 아니라 언마운트** — `state<Frame>`와 완전히 동일

이 정정 **전에** 쓰인 두 절("`State<Slot?>`가 `nil`이 됐다 돌아오는 경우",
"포탈")은 당시 설계(reconcile이 `rawRemove`=파괴를 씀)를 정확히 서술한
것이지만, 그 설계 자체가 이 정정으로 **뒤집힘** — 두 절의 원문은
`archive/slot-discard-no-portal-reversed.md`로 옮겼고(아래쪽에 요약
포인터만 남김), 현재 유효한 규칙은 이 절이다.

**결정(사용자)**: `State<Slot>`이 다른 값으로 교체될 때 이전 Slot은
**파괴되지 않고 언마운트만 된다.** 근거:

1. **`state<Frame>`가 이미 그렇게 동작함** — `store.child:Set(otherFrame)`을
   해도 이전 `Frame`을 quad가 `Destroy()`해주지 않음, 그냥 트리에서
   내려올 뿐. `State<Slot>`만 다르게(파괴로) 동작할 이유가 없음. **"이전
   값을 지울지는 그 값을 만든 쪽이 정한다"**는 이미 `Ref`("Destroy와 무관")/
   `Attribute`("명시적 `None`으로만 지움")에서 확정된 quad 전역 철학과도
   같은 결.
2. **비파괴 추출은 이미 지원되는 개념** — `Extract`/`ExtractAll`/`Splice`가
   전부 비파괴로 확정돼 있음(위 "CRUD API 확정" 절). "제거 = 파괴"만
   reconcile이 임의로 골랐던 것이라, 그 선택을 되돌리는 것뿐 새 능력이
   아님.
3. **뽑아냈으면 더 이상 leaf의 소유가 아님** — 소유권이 반납된
   (`releaseOwner`) 상태이므로, 그 Slot을 계속 쓸지 버릴지는 그걸 들고
   있는 코드의 몫.

**그러면 안 지운 Slot은 언제 죽는가 — "들고 있다 죽으면 같이 소멸"**
(GC-native, 이 프로젝트의 기본 원칙 그대로): 아무도 참조를 안 들고 있으면
그냥 GC됨. 명시적으로 지금 죽이고 싶으면 `dispose`(아래).

**부수 효과 — 이미 파괴된 대상에 재마운트하려는 시도가 자연히 막힘.**
Slot이 마운트될 때 **자기 하위 요소들까지 `bindLifetime`으로 물리 target에
묶고, 실제 동작 전에 `canExecute`를 확인**하도록 하면(`base/lifecycle-pattern.md`),
"nested로 마운트해둔 뒤 물리 Instance를 Destroy하고, 그 다음 Slot을 뽑아
다른 데 쓰려는" 경로가 별도 방어 로직 없이 걸러짐 — 이미 있는
`bindLifetime`/`canExecute` 게이트를 한 층 더 촘촘히 적용하는 것뿐,
새 메커니즘이 아님.

**`Set`으로 덮어쓰기 *전에* 이전 값을 직접 `Destroy()`하는 건 UB.**
`state<Frame>`에서 `frame:Destroy()`를 먼저 하고 `Set(other)`을 부르는
것과 정확히 같은 문제 — quad는 그 값이 이미 죽었다는 걸 모른 채 언마운트
경로를 탐. 순서는 항상 **`Set`(언마운트) → 그 다음 정리**.

#### `dispose(value)` — quad가 관리 중인 값을 안전하게 지우는 유일한 경로 (신설, 사용자 제안, **2026-08-14 열 번째 세션에 시그니처/범위 확정 — `question.md` 0-B 해소**)

위 UB를 "조심하세요"로만 두지 않기 위해, **base 레벨 탑레벨 유틸
`dispose(value: Slot | Instance): ()`** 를 제공:

- 의미(**[정정, 사용자 확정]** 최초안은 "마운트돼 있으면 먼저 떼어낸 뒤
  파괴"였으나 더 단순하게 확정): **대상이 아직 어느 트리에 의해 살아있길
  요구되고 있으면 파괴를 거부하고 즉시 `error`.** 떼어내주지 않음 —
  떼어내는 건 `Set`(언마운트)의 몫이고, `dispose`는 그 뒤에 부르는 것.
  아무도 요구하지 않는 상태면 실제로 파괴(Slot이면 하위까지 재귀).
- **왜 거부가 맞는가(사용자)**: "실제로 클리어 하거나 Destroy 해도
  로블록스엔 에러 안 나는데, quad에선 데이터 구조가 깨지는 일이니까요."
  엔진은 조용히 넘어가지만 quad의 `_elements`/`lengthList`/`sourceList`/
  `elementOwner`는 그 순간 어긋남 — 그래서 **quad가 관리 중인 값을
  안전하게 지우는 유일한 경로가 `dispose`**이고, 그 경로가 "지금 지우면
  안 되는 상태"를 잡아주는 게 존재 이유. 위 "`Set` 전에 직접 `Destroy()`
  하는 건 UB" 항목이 `dispose`를 쓰면 UB가 아니라 **명확한 에러**가 됨.
- **이게 성립하는 이유 — "이 값이 지금 어디 마운트돼 있는가"를 이미
  알고 있음.** `a = Frame{}; Frame{a}; Frame{a}`를 error로 잡기로 이미
  확정했고(위 "핵심 제약: 소유권 귀속과 단일 마운트"), 그 판정을 위해
  `elementOwner`가 element → owner를 들고 있음 — `dispose`는 그 정보를
  거꾸로 읽으면 되므로 **새 부기가 필요 없음**. 사용자 지적: "이미 두
  곳에 넣는 게 에러나도록 하기로 했으니, 어디 마운트되었냐가 따져지고,
  그래서 이미 가능한 일".

**범위 — `Slot` + 엔진 객체(Instance)만, `Observer`/`Effect`는 명시적으로
제외**(2026-08-14 열 번째 세션, 사용자 확정):

```lua
function dispose(value)
    if isSlot(value) then
        -- 위 elementOwner 기반 판정 재사용 — 요구 중이면 error, 아니면 재귀 파괴
        ...
    else
        disposeInst(value)  -- 아래 주입 op
    end
end
```

- **왜 `Observer`/`Effect`는 dispose 대상이 아닌가**: 이 둘은 children
  배열 leaf 위치에 놓이면 `Dispatch/Leaf.luau`가 매치해 내부적으로
  `bindLifetime(inst, value)`를 호출하고(`base/source-state-plan.md`
  "이중 바인딩 금지" 절), 생존은 그 GC 앵커(gcconn)만으로 판정됨 —
  Slot처럼 "죽는 순간 `elementOwner`/`lengthList`/`sourceList`가
  어긋나는" 트리 부기 자체가 없음. 즉 dispose가 막으려는 문제(부기
  붕괴)가 Observer/Effect에는 원천적으로 발생하지 않음 — 아무도 안 들고
  있으면 그냥 GC. **[정정, 2026-08-20 구현 전 QA 4라운드 `SL-72`] 조기에 끊는
  사용자 경로는 `unbindLifetime`이 아니다** — 옛 서술은 "조기에 끊고 싶으면
  `unbindLifetime`으로 충분"이라 적어 이걸 사용자 API처럼 안내했는데, 사용자
  판정: *"우린 조기에 끊는걸 명시적으로 unbindLifetime 로 지원하지 않음. 그건
  유저에게 드러나는 표면이 아니고, State<Observer?> 를 사용하는게 적절."*
  `bindLifetime`/`unbindLifetime`은 **Handler 작성자용 내부 배관**이고
  (`base/lifecycle-pattern.md`), 사용자가 leaf에 붙은 Observer/Effect를 끄고
  싶으면 그 자리를 `State<Observer?>`로 두고 `nil`을 emit하면 된다 — 그러면
  기존 하강 diff가 알아서 이전 것을 retract한다(새 경로 불필요). 어느 쪽이든
  `dispose`가 다룰 이유가 없다는 결론은 그대로.
  **주의 — Modifier 필드/`Slot:Add`·`:List` 원소 금지 규칙("핸들러 계층 값이
  들어오면 즉시 error")과 헷갈리지 말 것.** 그건 Modifier 필드나 Slot의
  CRUD 원소 자리에 관한 별개 규칙이고, children 배열의 leaf 위치(정적
  `Frame{observer}`류)나 그 leaf가 `State<Observer>`/`State<Effect>`로
  반응형으로 바뀌는 경우는 전혀 다른 컨텍스트 — 후자는 이미 확정된 일반
  원칙("모든 `(inst,k)`는 `T`든 `State<T>`든 `StoreBind`가 균일하게 재귀
  처리")의 자연스러운 귀결이라 별도 설계 없이 그냥 됨.
- **`unbindLifetime`과의 역할 분담**: `dispose`는 **트리 소유권 부기가
  있는 대상**(Slot/Instance)이 아직 요구되는데 강제로 죽이려는 시도를
  막는 것이고, `unbindLifetime`은 Observer/Effect류의 GC 앵커를 조기
  해제하는 것 — 축이 달라 서로 대체 불가.

**base/backend 분리 — `disposeInst`는 주입 op**(`base/dispatch-core-plan.md`
"base가 소유하는 핸들러와 주입되는 엔진 op" 절과 같은 패턴, `addTag`/
`removeTag`/`setAttribute`가 선례): `dispose`가 `isSlot`이 아닌 값을
받으면 base가 시그니처만 소유하는 `disposeInst(inst: any): ()`로 위임 —
quad-roblox는 `inst:Destroy()`로 구현. 웹 등 다른 백엔드는 자기 방식으로
매핑.

**네이밍**: `free()`는 GC-native 언어 맥락과 안 맞아 기각, `Destroy`는
엔진 자체 `:Destroy()` 메소드와 동명이라 사용자가 "그냥 `:Destroy()`
부르는 거 아님?"으로 착각할 위험이 있어 기각 — `dispose` 유지.

**[백로그 후보, 2026-08-18 구현 전 QA] `SetAndDispose` 류 편의 콤비네이터.**
위 "`Set`(언마운트) → 그 다음 정리" 순서 요구 때문에 호출부가 매번
**`Get()`으로 이전 값을 미리 잡아두고 → `Set(new)` → 잡아둔 옛 값을
`dispose`** 하는 3단계를 손으로 써야 해서 편의성이 떨어진다는 사용자 지적:
*"source:apply(SetAndDispose( new )) 같은걸 구현해줄까는 생각해보았음(단
여기서의 apply 는 source 를 넘겨주는 함수가 되어야함.). Get해놓고 Set 이후
나중에 지우는게 편의성이 떨어지기 때문. 아니면 그냥 source 자체에 :콜론
메서드로 가능하게 하는걸 넣어줄까 생각은 하고 있음."* 후보 둘:

1. `source:Apply(SetAndDispose(new))` — 콤비네이터. **단 여기서의 `Apply`는
   `State`가 아니라 `Source`를 넘겨주는 함수여야 함**(사용자 명시) — 지금
   확정된 `state:Apply(factory)`는 `factory(self)`에 `State`를 넘기므로,
   `Source` 전용 변형이 필요한지 같이 정해야 한다.
2. `Source`에 콜론 메서드로 직접 얹기(`source:SetAndDispose(new)`).

**[해소, 2026-08-20 구현 전 QA 4라운드 `SL-74`] 2번(`Source`의 콜론 메서드)으로
확정 — `state:Apply` 시그니처엔 영향 없음.** 사용자 판정: *"타입 문제 때문에
Apply 를 오버라이딩 해서 source 타입을 함수에 건내주는건 못함. 그럼 source ->
state 가 안전히 성립 못해서, Apply 라는 이름을 그대로 쓰지는 못함. 따라서 영향이
안 가고, 그냥 SetAndDispose() 로만 Set() 와 세트로 주는게 나아보이고, 그걸로
확정지어야할것 같다는 생각임."*

- **1번(`source:Apply(SetAndDispose(new))`)이 기각된 이유는 타입이다** —
  `state:Apply(factory)`는 `factory`에 `State<T>`를 넘기는 것으로 이미 확정돼
  있는데(`base/source-state-plan.md`), `Source` 전용으로 오버라이딩하면 같은
  이름이 리시버 타입에 따라 다른 걸 넘기게 된다. `Source<T>`가 `State<T>`를
  **단방향으로만** 만족하므로 그 반대 방향(넘겨받은 게 `Source`임을 보장)은
  안전하게 성립하지 않는다 — 이름을 그대로 재사용할 수가 없음.
- **확정 형태**: `source:SetAndDispose(value)` — `:Set(value)`와 **한 세트로
  묶인 `Source` 전용 콜론 메서드**. `Set`(언마운트) → 옛 값 `dispose` 순서를
  안에서 수행하므로 호출부가 `Get()`으로 옛 값을 미리 잡아둘 필요가 없다.
- **`state:Apply`는 손대지 않는다** — 시그니처 영향이 없으므로 M3 착수 전
  결론이 필요하던 항목에서 빠진다(`question.md`/`.claude/todos.md`에서 제거).

#### 구현상 바뀌어야 하는 것

**[반영 완료, 2026-08-13 감사 후속]** 비파괴 경로를 `unmountSlotTree`로
신설하고(아래 "파괴" 절), 이걸 쓰는 자리를 둘로 못박음:

1. **`SlotHandler.process`가 반환하는 클로저**(최상위 dispatch 경로) —
   **이 결정이 적용돼야 하는 바로 그 자리인데 처음엔 빠뜨려서
   `destroySlotTree`를 계속 부르고 있었음**(다른 에이전트 리뷰가 지적,
   그대로 뒀으면 언마운트 결정 자체가 무의미해질 뻔함). 지금은 위 절의
   코드가 `unmountSlotTree` + `setOffsetSource(None)`/`setLength(0)` +
   `unbindLifetime` + `releaseOwner`를 부름.
2. **`:List`의 `reconcile`** — **[재정정, 2026-08-18 구현 전 QA]** 여기서
   비파괴가 되는 건 **값 교체와 `Detach`뿐**이다. `updateFn`이 `nil`/`None`을
   반환하거나 키가 데이터에서 사라진 경우는 **다시 파괴가 기본**(사용자
   판정) — 상세와 이유는 위 "`nil` 리턴은 파괴가 기본" 절이 소스.
   2026-08-13에 이 항목이 "교체/소멸 시 전부 비파괴"로 적혔던 것은
   `:List`에는 안 맞는 일반화였음.

**여전히 파괴인 것**: 명시적 CRUD `Slot:Remove(index)`/`Slot:Clear()`
(CRUD 표가 "제거 **+ 파괴**"로 이미 정의), `dispose`, 그리고 위 2번의
`:List` 소멸 경로. 즉 일반 규칙은 **"자동 경로는 언마운트, 명시적으로
지우라고 한 것만 파괴"**이되, **`:List`에서 `nil`을 반환하는 것 자체가
"지우라고 한 것"으로 센다** — `Ref`/`Attribute`의 "지울 거면 명시적으로"
철학과 같은 결이고, `updateFn`이 지우지 않길 원하면 `Detach`로 그 의도를
명시한다.

`unmountSlotTree`는 `destroySlotTree`가 하는 일 중 **실제 파괴와 자식
소유권 반납만 빼고 나머지는 그대로 함**(자식 observer `unbindLifetime`,
`_mounted`/`_mountedInst` 복원 — **[정정, 2026-08-20 `SL-75`] `slot.Offset`은
안 건드림**). 옛 owner에 등록해둔
`Dispatch.setLength`/`setOffsetSource` 해제는 호출부 몫(아래).

**[정정, 사용자 지적] "해제 짝"이라는 새 API는 필요 없음** — 옛 owner에
대해 그냥 **`Dispatch.setOffsetSource(ownerKey, position, None)` +
`Dispatch.setLength(ownerKey, position, 0)`을 다시 부르면 끝**.
이건 이미 확정된 관용구 그대로임(`base/dispatch-core-plan.md`의 "해제(그
자리가 더 이상 기여하지 않게 될 때)는 `setOffsetSource(...,None)`").
즉 **해제 = 0/`None`으로 재등록**이고 별도 unregister 함수가 없어도 됨 —
앞서 "이게 실제 작업량"이라고 적었던 판단은 과했음.

**⚠️ 순서가 중요함 — `setOffsetSource`를 먼저, `setLength`를 나중에
(2026-08-13 여섯 번째 세션, 사용자 지적).** 마운트할 때와 달리 **해제할
때는 이 순서를 반드시 지켜야 함**:

- `Dispatch.setLength`는 끝에서 `gatedRecompute`를 경유해(배치 게이팅
  중이 아니면) `recompute`를 돌리고, `recompute`는 `sourceList`를
  순회하며 각 자리의 `offset:Set(sum)`을 호출함(`base/dispatch-core-plan.md`
  "Length/Offset" 절 — 해제는 배치 도중이 아니라 steady state에서 흔히
  일어나므로 이 경로에서는 `gatedRecompute`가 거의 항상 즉시 `recompute`로
  이어짐).
- 그래서 **`setLength(0)`을 먼저 부르면**, 그 안의 `recompute`가 도는
  시점에 해제 중인 자리의 `sourceList[i]`엔 **아직 옛 Slot의 offset
  `Source`가 그대로 남아 있음** → 지금 막 떼어내는 서브트리의 Source에
  `:Set()`이 날아가고, 그 Source를 구독하던 (이제 곧 없어질) 자식들의
  `LayoutOrder` 계산이 헛되이 캐스케이드됨. 사용자 표현대로 "**invalid한
  offset source 자체가 있다는 것부터 위험**".
- `setOffsetSource(None)`을 먼저 부르면 그 자리는 `recompute`의
  `offset ~= None` 가드에 걸려 곧바로 제외되므로, 뒤이은 `setLength(0)`의
  `recompute`가 그 Source를 아예 안 건드림.
- **자기 자신의 offset은 어차피 안 바뀜**(자기 length가 줄어든다는 건
  자기 앞 형제들의 누적합은 그대로라는 뜻) — 그래서 이 순서 문제는
  "내 offset이 틀리게 계산된다"가 아니라 **"죽는 중인 Source에 쓰기가
  날아간다"** 쪽임. 사용자도 "물론 별 상관 없어요"라고 했듯 실제 값
  오류로 이어지진 않지만, 방어적으로 순서를 고정.

**추가 방어 조치**:
- **⚠️ [전면 정정, 2026-08-20 구현 전 QA 4라운드 `SL-75`/`D-60`] 해제 시
  `slot.Offset`을 `nil`로 되돌리면 안 된다 — stale한 채로 그냥 둔다.**
  옛 서술은 "해제 시 `slot.Offset = nil`도 같이"였는데, 그러면 **포탈(언마운트
  후 다른 곳에 재마운트)이 깨진다** — 사용자 판정: *"nil 로 만들면 안 되는게,
  포탈로 옮기는게 안 됨. 이미 offset 을 들고 가 바운딩 했다면 큰 문제가 생김.
  그냥 stale하게 있는게 맞고, 나중에 offset이 멀쩡히 다시 설정되는게 옳음.
  언마운트 시 offset stale 은 단순히 맞는 행동이고, 처음 생성 시 0 인것과 유사
  동작임."*
  - **누가 이미 그 `Source`를 구독하고 있을 수 있다** — `updateFn`이
    `layoutOrder:With(offset):Compute(...)`처럼 `offset`을 파생 그래프에 엮어둔
    상태에서 필드를 `nil`로 갈아치우면, 그 구독은 옛 Source를 계속 보는데
    Slot은 새 Source를 만들어 등록하게 되어 둘이 영영 갈라진다. 재마운트가
    "값이 다시 정상으로 채워지는" 일이 아니라 "연결이 끊긴 채 조용히 멈추는"
    일이 되어버림.
  - **stale한 값 자체는 위험하지 않다** — 언마운트 상태의 `Offset`은 그냥
    "마지막으로 알던 위치"이고, 재마운트되면 `setOffsetSource`의 즉시 계산이
    올바른 값으로 덮어쓴다. 이건 **처음 생성 시 `0`인 것과 같은 성격의
    잠정값**이지 오염이 아니다.
  - **따라서 `Slot.Offset`은 "마운트 전엔 `nil`"이 아니다** — 아래
    "`Slot.Offset`도 `Slot.Length`와 마찬가지로 공개 필드" 관련 서술과
    `unmountSlotTree` 의사코드도 이 정정에 맞춰 갱신됨(같은 라운드).
- **⚠️ [전면 정정, 2026-08-20 구현 전 QA 4라운드 `C-6`] `recompute`가
  `sourceList[i] == nil`을 관대하게 skip하지 않는다 — 즉시 `error`다.**
  옛 서술은 "해제/재마운트가 얽히는 전이 구간에서 `nil`이 관측돼도 크래시
  대신 skip"이었는데, 사용자 의문(*"애초에 해제에서 nil이 관측 될 일이
  없다고 생각하는데"*)을 받아 다시 추적한 결과 **지금 설계에서 도달
  경로를 찾지 못했다**:
  - `bk.N`이 "그때그때 실제 개수"로 확정돼(2026-08-18) `lengthList`/
    `sourceList`가 아직 안 채워진 위치를 `recompute`가 읽을 일 자체가 없음.
  - 배치 등록 중엔 Blocker 게이팅으로 `recompute`가 아예 안 돎.
  - 해제는 `setOffsetSource(None)` → `setLength(0)`이라 `None`이지 `nil`이
    아님.
  - `spliceArraysDown`은 배열을 **압축**하므로 중간에 구멍을 안 남김.

  그러면 `nil`이 관측된다는 건 **부기가 깨졌다는 신호**이고, 관대한 skip은
  "위치 하나가 조용히 순서 계산에서 빠지는" 추적 어려운 오작동이 된다 —
  `Dispatch`의 "매치 실패는 조용한 무시 없이 즉시 error"/`releaseOwner`
  불일치 error와 같은 톤으로 **즉시 error**가 맞다(사용자 동의).
  등록 쪽이 `None`을 쓸 의무는 그대로.

**`state<state<Frame>>`류로 offset이 밀리고 당겨지는 문제는 "그냥 확인된
것"으로 수용**(사용자 판단) — `state<state<Tag>>`와 같은 범주로,
평탄화 도구(`research/operator-sugar-plan.md`)가 처리할 요소이고 실사용
케이스가 드묾. Dispatch/Slot에 별도 배관을 넣지 않음.

### [역전됨 — 원문은 archive로 이동] `State<Slot?>` 왕복 / 포탈 검토 두 절

위 "언마운트" 정정 **이전에** 쓰인 두 절(`State<Slot?>`가 `nil`이 됐다
돌아오면 Slot이 파괴된다는 분석, 그리고 포탈이 가능한지 검토하며 숙제 셋을
열어둔 절)은 결론이 전부 뒤집혀 이 문서에서 뺐다 — **원문·역전 근거·숙제
셋의 결말은 `archive/slot-discard-no-portal-reversed.md` 3~4절.**

지금 유효한 답만 옮겨두면:

- **`nil`↔`slotA` 왕복은 정상 동작한다** — 언마운트 전환으로 "두 번째
  등장부터 깨진 서브트리" 문제 자체가 사라짐. 단 **`Set`으로 덮어쓰기
  *전에* 이전 값을 직접 `Destroy()`하는 건 UB**(`state<Frame>`에서 먼저
  `frame:Destroy()`하고 `Set`하는 것과 같은 문제) — 순서는 항상
  `Set`(언마운트) → 그 다음 정리.
- **포탈은 기본 동작이다** — opt-in 표식도, 새 API도 없음. 옛 owner의
  등록 해제는 `setOffsetSource(ownerKey, position, None)` **다음에**
  `setLength(ownerKey, position, 0)`(순서 중요 — 위 ⚠️ 절).

### `:List`의 `index`도 nested-Slot 결과의 `.Length`만큼 건너뛰어야 함 (같은 세션 후속, 사용자 발견)

Slot-in-Slot으로 `T = Instance | Slot<Instance>`가 허용되면서, `:List`의
`updateFn`이 `result`로 nested Slot(멀티루트 컴포넌트 결과 등)을 반환할
수도 있음 — 이때 그 아이템은 물리적으로 1개가 아니라 `result.Length`개의
실제 요소를 차지함. 원래 `candidateIndex = pos + 1`(고정 +1)로만 커밋했다면,
`updateFn`이 `index`를 LayoutOrder 계산에 쓰는데 어떤 아이템이 nested
Slot(Length=3)을 반환할 때 다음 아이템의 `index`가 3만큼 안 건너뛰고
1만 건너뛰어 물리적으로 겹치는 LayoutOrder 범위가 나옴 — **의도된 동작으로
확정, 위 "구현" 절의 `reconcile` 의사코드에 이미 반영됨**(`pos = candidateIndex
- 1 + (if isSlot(result) then result.Length:Get() else 1)`).

**남는 캐비엇 — `index`는 여전히 raw 스냅샷이라, nested Slot의 Length가
outer `:List`의 reconcile 없이 나중에 바뀌면 그 이후 형제들의 `index`는
갱신 안 됨.** 이건 새로 생기는 문제가 아니라 이미 확정된 "`index`가
State가 아니라 raw number"라는 설계(위 "왜 `LayoutOrder`를 Slot이 대신
안 해주는가" 절) 원칙의 당연한 연장 — `index`는 outer `:List`가 가장
최근에 reconcile됐을 때의 스냅샷일 뿐, 실시간 정확성이 필요하면
`updateFn`이 직접 `result.Length`를 구독해서 스스로 처리해야 함(이미
"`index`/`offset`을 실제 프로퍼티에 어떻게 반영할지는 전적으로
`updateFn` 몫"이라는 기존 원칙과 정합). 실사용에서 이 케이스(리스트
아이템이 각자 멀티루트를 반환하며 그 개수가 outer 리스트 reconcile
없이 동적으로 바뀜)는 드물 것으로 예상 — 실제로 문제가 되면 그때
`updateFn`이 자체적으로 방어하는 패턴을 문서화.
