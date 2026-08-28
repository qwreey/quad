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

### ⭐ 물리 조작은 주입 op다 — `native*` 계층 (2026-08-21 구현 전 QA 5라운드, 같은 날 확장)

**사용자 지적**: *"element.Parent = self._mountedInst 부분은 실제 엔진이
구현하게 되는 crud 셋을 사용하게 되어야할것이다. slot 의 해당 동작은 base
이므로 parent 를 모른다."* 맞다 — 위 경계 문단이 "실제 트리 조작은 백엔드"라고
이미 말해뒀는데 의사코드는 계속 `element.Parent = ...` / `element:Destroy()`로
Roblox 어휘를 직접 쓰고 있었다. 이 문서의 의사코드를 전부 주입 op 호출로 바꿨다.

**층위 정의(사용자)**: **`raw*`는 그 Slot 스코프 안의 연산**(평탄화 전,
`_elements` 인덱스)이고, **`native*`는 확정된 offset/length로 표현되는 물리 트리
연산**(평탄화 후, 절대 좌표)이다.

```lua
nativeInsert (target, offset, elements)                          -- 삽입(자신이 밀어냄)
nativeExtract(target, offset, elements, newElements?)            -- 빼되 **살림** (+그 자리에 교체 삽입)
nativeRemove (target, offset, elements, newElements?)            -- 빼면서 **파괴** (+그 자리에 교체 삽입)
nativeMove   (target, fromOffset, elements, toOffset)            -- 범위 이동(사이가 밀림)
nativeSwap   (target, offsetA, elementsA, offsetB, elementsB)    -- 두 구간 맞교환(사이 고정)
nativeDispose(element)                                           -- 트리 **밖** 값 파괴
isInst       (value): boolean                                    -- [2026-08-24 신설] 이 값이 이 백엔드의
                                                                 -- 마운트 가능한 요소(`T`)인가
```

**⭐ [2026-08-24 신설] `isInst`는 다른 `native*`와 성격이 다르다 — 조작이 아니라
판정이고, 미주입이 에러다.** 요소 타입 검증을 블랙리스트에서 화이트리스트로
뒤집으면서 생겼다(아래 "요소 타입 제약" 절, 6라운드 손 트레이싱 `H-40`).
base는 여전히 `T`가 뭔지 모른다 — **아는 건 백엔드고 base는 주입된 술어만
부른다.** quad-roblox의 구현은 `typeof(value) == "Instance"` 한 줄이다.

- **`offset`은 전부 0-based 절대 offset**(`Dispatch.getOffsetAt`이 주는 그 값).
  Roblox 백엔드는 이 인자를 그냥 무시한다 — `LayoutOrder`가 물리 순서와
  분리돼 있으므로.
- **⭐ 빠지는 요소는 반드시 `elements` 배열로 넘긴다** — `(target, offset, count)`만으로
  대상을 찾을 수 있는 건 DOM뿐이다(`childNodes[offset]`). **Roblox는 자식이 순서
  없는 집합**이고 quad의 offset은 순전히 논리값이라, 백엔드가 offset으로 인스턴스를
  역으로 못 찾는다. `count`는 `#elements`로 따라온다.
- **`Replace`는 별도 op이 아니다** — `newElements`가 있는 `nativeRemove`(파괴 교체)
  또는 `nativeExtract`(비파괴 교체)다. `Splice`도 이 둘로 표현된다. 제거와 삽입을
  한 호출로 합치는 이유는 **리플로우 2회와 그 사이 인덱스가 어긋난 창**을 없애기
  위함(사용자: *"안 그러면 splice 가 무거워짐"*).
- **파괴/비파괴를 불리언이 아니라 이름으로 가른 이유**: 공개 CRUD의
  `Remove` ↔ `Extract` 어휘를 그대로 물려받고, **백엔드의 융합**을 열어주기
  위해서다 — Roblox에서 `Parent = nil` 후 `Destroy()`는 그냥 `Destroy()`보다
  비싸므로(사용자 지적), `nativeRemove`가 그 자리에서 바로 파괴할 수 있어야 한다.
- **`nativeSwap`이 따로 있는 이유**: `Move`는 사이 요소를 전부 밀지만 `Swap`은
  **가운데를 고정한 채 양끝만 교환**이라 다른 연산이다. `Move` 2회로 흉내내면
  리플로우 2회 + 중간 인덱스 재계산이 필요하다.
- **`nativeInsert`를 흡수하지 않은 이유**: `nativeExtract(target, offset, {}, elements)`로
  표현은 되지만, **최빈 경로**(리스트 최초 채우기·단건 `Add`)가 "0개를 빼는 extract"라는
  모양이 되고 `DocumentFragment`류 일괄 삽입 최적화도 그 안에 숨는다.
- **기본 구현(조합 폴백) — 미주입이 에러가 아니다.** `addTag`/`setAttribute`가
  "미주입이면 명확한 에러"인 것과 갈린다: 이쪽은 조합으로 항상 정의되기 때문이다.
  `nativeRemove` = `nativeExtract` + `nativeDispose` 반복, `nativeMove` =
  `nativeExtract` + `nativeInsert`, `nativeSwap` = `nativeMove` 2회. 백엔드는
  **이득 있는 것만 덮어쓴다.**
  - **⚠️ [2026-08-24 보강, 6라운드 손 트레이싱 `H-34`] 단 Roblox 백엔드는
    `nativeMove`/`nativeSwap`을 반드시 덮어써야 한다 — 여기선 조합 폴백이
    "느린 정답"이 아니라 관측 가능한 동작 차이를 만든다.** `Move`/`Swap`이
    공개 CRUD에 추가된 근거 자체가 *"`Extract`+`Add`는 실제 Parent 조작이
    두 번(detach+reattach) 일어남"*을 피하려는 것이었는데(아래 "원시 최소화
    원칙 정정" 절), 조합 폴백은 정확히 그 두 번을 되돌려 `AncestryChanged`
    재발화·깜빡임·재바인딩 비용을 다시 만든다. **offset을 무시하는 백엔드에서
    순서 이동은 애초에 물리 조작이 아니므로 no-op으로 덮어쓰면 된다.**
    quad 자신의 배관은 `Destroying` 하나만 보므로 안 깨진다 — 영향은
    사용자 코드/렌더 쪽이다.
  - `isInst`는 이 조합 폴백의 예외다(위 문단) — 판정이라 조합으로 만들 수
    없고, 미주입이면 명확한 에러여야 한다.
- **⚠️ 전제 — 한 Slot의 물리 자식은 부모 안에서 연속 구간을 차지한다.** 범위 op이
  성립하는 근거가 전부 이것이다(offset이 누적합이고 중첩 Slot도 같은
  `physicalTarget`을 공유하므로 구조적으로 참). quad 밖에서 그 부모에 자식을 끼워
  넣는 게 UB인 진짜 이유이기도 하다(`base/dispatch-core-plan.md`의 Length/Offset 절 끝, "동적 자식 추가/제거의
  유일한 정당 경로" 문단).
- **⚠️ 이름은 여전히 가칭** — 주입 op 목록에 정식 등재할 때 확정할 것
  (`base/dispatch-core-plan.md`의 "base가 소유하는 핸들러와 주입되는 엔진 op" 절).

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
- **⭐ [전면 정정, 2026-08-24 6라운드 손 트레이싱 `H-40`] 판정은 블랙리스트가
  아니라 화이트리스트다 — `isSlot` → `isState` → `isInst`.** 아래 "핸들러 계층
  값 … 금지" 항목은 **열거된 것만** 막는 블랙리스트였고, 그래서 목록에 없는
  값 타입이 전부 샜다. 실제로 `Tween`이 그대로 통과해 `_elements`에 들어가고
  (물리적으로는 아무것도 안 붙는데 `Length`만 유령 +1), 나중 파괴 경로의
  `nativeDispose(t)`가 `Destroy` 메소드 없는 테이블에서 죽는다. 확정된 판정
  순서는:
  1. `isSlot(v)` → 중첩 Slot으로 구조적 처리(아래 "Slot-in-Slot 중첩" 절).
  2. `isState(v)` → 래퍼 Slot(`:Single`)으로 풀어 재귀(아래 "반응형 raw 요소" 절).
     **그 안쪽 값이 다시 이 판정을 받는다** — State가 나중에 이상한 값으로
     바뀌어도 같은 자리에서 걸린다.
  3. 그 외 → **`isInst(v)`가 거짓이면 즉시 `error`.**
  **관문은 `wrapElement` 하나로 둔다** — 공개 CRUD와 `:List`의 `settle`이 둘 다
  여길 지나므로 검증 지점이 갈리지 않는다.
  **base는 여전히 `T`를 모른다** — `isInst`는 백엔드가 주입하는 술어이고 base는
  그걸 부르기만 한다(위 `native*` 절). 그래서 화이트리스트인데도 "base는 `T`가
  뭔지 모른다"는 이 문서의 일관된 입장과 안 부딪힌다.
  **왜 Brand로 안 하나**(사용자 판정, 2026-08-24): *"이제 brand 는 각각 따로
  생성되어서 있는지 없는지 보는건 결국 전부 봐야한다는 의미"* — `Brand`가
  2026-08-21 재작성으로 인스턴스 브랜드가 된 뒤로 "아무 quad 브랜드나 붙었나"를
  물으려면 모든 브랜드를 순회해야 한다.
  아래 두 항목(핸들러 계층 값 금지, `nil`/`None` 금지)은 **여전히 유효하지만
  이제 이 화이트리스트의 따름정리**다 — 그 값들은 셋 중 어디에도 해당하지 않으므로
  3번에서 걸린다. 다만 **에러 메시지는 계속 구분해서 낸다**(핸들러 계층 값이
  왜 안 되는지는 아래 근거가 있고, 그걸 "`isInst`가 아님"으로 뭉뚱그리면
  진단이 나빠진다).
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
실제로는 부모/자식 부기까지 했지만 다중 마운트 방지는 없었음), v2는 **Slot의
마운트 경로 자체**(`attachSlot` 분해분 — 별도 `Mount` 함수가 아니다; **[2026-08-28]**
이미 있는 트리를 quad가 소유하는 `Claim`은 `research/existing-mount-plan.md`에서
논의 중이고 그것도 이 단일 마운트 불변식을 그대로 진다)가 이 강제를 담당.

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
  - **⭐ [2026-08-24 좁힘, 6라운드 손 트레이싱 `H-2`] `_mounted`/`_mountedInst`는
    이제 "물리 인스턴스가 있는가"만 뜻한다.** `attachSlot`이 5라운드 `F-3`으로
    `materializeSlotTree`(부기 확정) + `mountSlotTree`(물리 대입)로 쪼개진 뒤,
    이 둘은 **뒤쪽에서만** 세팅된다. 그래서 상태가 셋이다:
    **미실체화 / 실체화(부기는 있고 물리는 없음) / 마운트**.
  - **`slot._physicalTarget` 신설** — `materializeSlotTree` 머리에서 저장한다.
    `Dispatch.setLength`의 앵커(그리고 length가 State일 때 `bk.observers`의
    앵커)가 **실체화 시점에 이미 필요**한데 `_mountedInst`는 그때 아직 `nil`이기
    때문이다. `raw*`는 앵커가 필요하면 `_physicalTarget`을, `native*`를 부를지
    말지는 `_mounted`를 본다(아래 `rawAdd`/`rawRemove` 계열).
  - 언마운트는 `_mounted`/`_mountedInst`를 지우고 `_physicalTarget`도 같이
    지운다(재마운트 시 새 target으로 다시 채워진다 — 옛 값을 들고 있으면 죽은
    inst를 강하게 붙잡는다, 아래 `unmountSlotTree`).
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

-- nested(`rawAdd`) 전용 — 엄격, 이미 누가 갖고 있으면 같은 owner여도 error.
-- [2026-08-21 감사] 예외 하나: **detach 재마운트**. `rawDetach`가 소유권을
-- 일부러 유지하므로(`slot._detached`가 계속 들고 있음), 다음 사이클에
-- `prev`를 그대로 돌려주는 문서 권장 패턴이 여기서 무조건 죽고 있었다.
-- top-level `claimOwnerAt`이 이미 "같은 (inst,k) 자리의 재발행은 통과"라는
-- 같은 모양의 예외를 갖고 있어 대칭이 맞는다.
local function claimOwner(element, ownerKey, fromDetached)
    local cur = elementOwner:GetWeak(element, OWNER)
    if cur ~= nil then
        -- 내가 계속 들고 있던 요소를 내가 다시 넣는 경우만 통과.
        -- `fromDetached` 없이 같은 owner라는 것만으로 통과시키면
        -- `Slot{a, a}`가 다시 조용히 새어나간다(2026-08-13 감사가 막은 것).
        if not (fromDetached and cur == ownerKey) then
            error("이 요소는 이미 마운트돼 있음 — 다중 마운트 금지")
        end
        return   -- 이미 내 것이므로 SetWeak도 불필요
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

**⭐ [2026-08-27 신설, 9라운드 Q2] 파괴된 Slot은 재사용 불가 — `slot._destroyed`.**
지금까지 파괴 쪽 계약이 어디에도 없었다. `destroySlotTree`는 **`_elements`를
안 비운다**(요소만 `nativeDispose`) — 파괴된 Slot은 죽은 Instance를 든 좀비이고,
`_mounted`를 `false`로 되돌려놓으므로 *"마운트된 Slot의 재마운트는 즉시 throw"*
가드에도 안 걸려 재마운트하면 죽은 Instance를 다시 `Parent` 대입한다.

- `destroySlotTree` 꼬리에서 `slot._destroyed = true`. **"파괴됨"은 이 플래그
  하나만 말한다** — 핸들(`_baseObserver`/`_listObserver`/`_listActivated`)을
  `nil`로 지워 그 뜻을 겸하게 하지 않는다(사용자: *"두 일을 겸하는걸 만들다가
  사고가 난 적 많아"* — `invalidAfter`가 그랬다). 핸들은 `unbindLifetime`만.
- **`attachSlot`/`materializeSlotTree` 진입과 공개 CRUD(`:Add` 등) 진입에서
  `if self._destroyed then error(..., 2) end`** — 사용자 입력 검증이므로
  `level 2`, 메시지는 영어(`base/architecture.md`의 error 계약). CRUD까지 막는
  이유: `_elements`가 안 비워지므로 죽은 Slot에 `Add`하면 **조용히** 좀비 배열이
  자란다.
- **`Owned = false`인 Slot은 `_destroyed`가 서지 않는다** — `destroySlotTree`가 그
  분기에서 `unmountSlotTree`로 빠져 꼬리(플래그 세팅)에 안 닿는다. 그 Slot은
  요소를 만든 적이 없으니 좀비가 없고 재사용도 그대로 가능하다 — **사용자
  확정**(*"owned = false 은 state<Frame> -> slot(single) 형태가 구현되는 것이라
  맞아"*). "파괴 대신 언마운트만"이라는 그 분기의 뜻 그대로.
- **이중 `dispose`는 얼리리턴 no-op** — teardown 경로가 겹치는 건 실재하고
  GC-native 기조와 맞는다. 플래그 세팅도 얼리리턴도 `destroySlotTree` 쪽이라
  다형 진입점 `dispose(value)`는 공짜로 물려받는다. 이름은 `_disposed`가
  아니다 — 사용자: *"`dispose` 는 형질이 다른 엔진 요소를 포함할 수 있는 것에
  대한 공동 소멸자인 네이밍. 자신이 삭제되고 그 여부는 `destroy` 가 맞아보이고,
  `dispose` 는 슈거로써 `destroy` 와 별도의 맥락에서 해석해야해."*

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
error가 맞음**.

**⚠️ [정정, 2026-08-21] 이제 그 경로가 정확히 하나 생겼다 — `Detach`
재마운트.** `rawDetach`는 일부러 `releaseOwner`를 안 부르므로(소유권 유지가
`Detach`의 핵심), `settle`의 재마운트 분기는 `rawUnmount`를 거치지 않고
곧바로 `rawAdd`를 부른다 — 위 문단이 "없다"고 단정한 바로 그 모양이다.
그래서 `claimOwner`에 **`fromDetached` 플래그가 참일 때만** 통과하는 좁은
예외를 뒀다(위 그 함수의 정의). **플래그 없이 "같은 owner면 통과"로
완화하면 안 된다** — 이 절이 애초에 막으려던 `Slot { a, a }`가 다시
새어나간다. 나머지 논증(top-level은 `claimOwnerAt`으로 구분)은 그대로
유효하다. 경위는 `qa-request/pre-implementation-qa-round4-followup.md`의
`I-1`.

반대로 top-level은 store 재발행마다 같은 Slot으로
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
-- rawAdd(self, element, index, fromDetached?) 안, "이미 마운트" 에러 체크 자리
claimOwner(element, self, fromDetached)  -- self = 담는 Slot. 이미 누가(같은 self
                                          -- 포함) 소유 중이면 error — 단 detach
                                          -- 재마운트만 예외(위 그 함수)

-- rawRemove(self, index)/rawExtract 안, 요소를 내보내는 자리
releaseOwner(element, self)

-- [삭제됨, 2026-08-20 `C-4`] destroySlotTree에는 명시적 releaseOwner가 없다 —
-- 2026-08-13 감사가 넣었던 걸 되돌렸다(자식이 어차피 죽으므로 불필요).
-- 아래 "소유권 반납은 GC에 맡기면 안 됨" 절의 재정정이 소스.
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
(**[정정, 2026-08-21]** "재클레임이 정당한 경우가 하나도 없다"는 전제는
`Detach` 재마운트 하나가 예외로 생겼다 — 바로 위 ⚠️ 문단이 소스.
`claimOwner`가 반환값 없이 error만 낸다는 이 항목의 결론 자체는 그대로다.)

**[2026-08-13 감사] 소유권 반납은 GC에 맡기면 안 됨** — `rawUnmount`/
`rawExtract`처럼 **요소를 살려서 내보내는** 경로에 한해 그렇다(**[표현 정밀화,
2026-08-21]** 여기 `rawRemove`를 같이 적었었는데 그건 파괴 경로다 —
`rawRemove`의 `releaseOwner`는 아래 재정정 기준으로 보면 불필요하지만 요소가
어차피 죽으므로 무해해서 그대로 둔다). `elementOwner`는
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

**⭐ [2026-08-27, 9라운드 Q2] 아래 표의 mutate 연산 전부**(`Add`~`Swap` — 조회
`Get`/`IndexOf` 제외)**가 진입 첫 줄에 `if self._destroyed then error(..., 2) end`를
둔다.** 의사코드가 있는 건 `:Add`/`:List`뿐이라 거기만 적혀 있지만, 규칙은 표
전체다 — `_elements`가 파괴 뒤에도 안 비워지므로 어느 하나라도 빠지면 죽은
Slot의 좀비 배열이 조용히 자란다(아래 "파괴된 Slot은 재사용 불가" 절).

| 연산 | 시그니처 | 복잡도 | 의미 |
|---|---|---|---|
| `Add` | `Slot:Add(element, index?): number` | O(n) | 삽입(뒤 요소 밀림), `index` 생략 시 끝에 추가 — **실제로 삽입된 인덱스를 반환** |
| `Remove` | `Slot:Remove(index)` | O(n) | 제거 **+ 파괴**(retract/Destroy) — `Extract(index):Destroy()`와 동치, 흔한 경로라 별도 이름으로 유지 |
| `Replace` | `Slot:Replace(index, newElement)` | **O(1)** | 그 자리 요소를 교체하고 **이전 것을 파괴** — `Extract(index, newElement)`의 파괴 짝(`Remove` ↔ `Extract` 관계와 동형). **[2026-08-21 5라운드 `B-5` 신설]** |
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
- **⭐ `Replace` 신설(2026-08-21 구현 전 QA 5라운드 `B-5`)** — `Extract(index,
  newElement)`가 이미 "그 자리 교체 + 이전 것 반환"을 O(1)로 해주는데, **흔한
  경우는 이전 것을 그냥 버리는 것**이다. 그때 `Extract`로 받아서 직접
  `dispose`하게 하면 `Remove`가 있는데도 `Extract(index):Destroy()`를 쓰게
  하는 것과 같은 불편이라, 파괴 짝을 이름 하나로 준다.
  **사용자 판정**: *"차라리, replace 를 제공하는게 나아보임. 해당 요소 자리에
  교체분을 넣고, 이전건 파기해주는 것. extract 가 뽑아내는것과 다르게 이건
  제거해준다."*
  - **진짜 동기는 `:List`의 reconcile 쪽이다** — 교체를 "제거 후 삽입"으로
    하면 `spliceArraysDown`(뒤 요소 당김) + `spliceArraysUp`(다시 밀어냄)이
    쌍으로 돌아 **O(n) 시프트가 두 번, `recompute`도 두 번** 난다. 자리 수가
    안 변하는 교체엔 둘 다 불필요하다(사용자: *"list 에서도 교체 작업이 제거
    다음 붙여넣기일텐데, 밀고 당기는게 많아짐"*). 그래서 `settle`의 교체
    분기가 `releaseElement` + `rawAdd`가 아니라 **`rawReplace` 하나**를
    쓴다(아래 의사코드).
  - **`Extract`와의 관계**: `Remove` ↔ `Extract`가 "파괴 / 비파괴"로 갈리는
    것과 정확히 같은 축이다. 새 능력이 아니라 이름 하나.
  - **[2026-08-21 감사] `rawReplace`의 `destroyOld`가 갈리는 지점**: 공개
    `Replace`는 **항상 `true`**(사용자가 명시적으로 "이건 지워라"라고 부른
    것이므로), `:List`의 `settle`만 `self._owned ~= false`를 넘긴다(남의
    요소면 언마운트만). `_listed` Slot은 공개 CRUD가 막혀 있어 두 경로가
    한 Slot에서 섞이지 않는다.
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
  모른 채(자기 `mounted`/`prevKeys`가 비어있는 상태로 시작) 새 요소를
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
      -- ⭐⭐ [2026-08-27, 9라운드 `H-125`/Q2] **`Offset`과 `_baseObserver`도 여기서
      -- 난다 — `Length`와 같은 자리.** 마운트 시점에 만들면 첫 마운트(생성 →
      -- "등록 즉시 1회"가 우연히 캐시를 0으로)와 재마운트(`bindLifetime`만 →
      -- 바인드는 발화가 아니라 안 함)가 갈려 재마운트 캐시가 낡았다. 이제 그
      -- 분기가 없다. 둘 다 **bind/unbind로만 관리하고 제거/생성하지 않는다**
      -- (사용자: *"단순히 bind/unbind 로 관리해야지 그것 자체를 제거/생성
      -- 하는건 안 맞아보임"*). `SL-75`/`D-60`의 "마운트 전엔 `0`"이 이걸로
      -- 코드에서도 성립한다. 콜백 본문은 아래 `materializeSlotTree` 절의
      -- `makeBaseObserver`가 소스(머리에 미실체화 가드 — 이 "등록 즉시 1회"가
      -- `bk`를 eager 생성하지 않도록).
      -- **[2026-08-27, Q3] 옛 `_elemIndex`는 여기 없다** — 그 맵은
      -- `bk.indexOfElement`로 Dispatch 부기에 산다(`indexOfRaw`가 조회).
      local self = setmetatable({
          _elements = {},
          Length = Source(0),
          Offset = Source(0),
          ...
      }, Slot_mt)
      self._baseObserver = makeBaseObserver(self)   -- 등록 즉시 1회는 가드가 삼킨다
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
(2026-08-11 세션 명시화).** `key`는 그냥 `mounted`/`userdata`/`prevKeys`
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
`userdata`/`prevKeys`의 같은 슬롯을 다투게 돼 한쪽 item이 사라지거나
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
  모든 key에 대해 호출됨.**
  - **⭐⭐ [2026-08-25 정정, 7라운드 `H-95`] 이 반환 타입 그대로면 strict에서
    정상 용례가 전부 막힌다.** Luau는 콜백이 **선언된 것보다 적게
    반환**하면 에러다(`Expected 'El?, number?', but got 'El?'`) — 이 문서가
    드는 예시들이 `return frame` 한 값만 돌려주는데 그게 통과하지 않는다.
    **확정 형태는 함수 타입의 유니온**이다:
    ```lua
    type UpdateFn<T, UD> = Fn2<T, UD> | Fn1<T> | Fn0
    -- Fn2: (...) -> (T?, UD?)   Fn1: (...) -> T?   Fn0: (...) -> ()
    ```
    `luau-analyze` 실측에서 네 모양(2개/1개/`nil`/없음)이 전부 통과하고
    **엉뚱한 타입을 돌려주면 여전히 잡힌다**(음성 대조군 확인).
    *"항상 명시적으로 반환하라"*를 계약으로 두는 안은 기각 — 인체공학이
    나쁘고 `--!nocheck` 코드에선 조용히 지나간다. 단일 옵셔널 반환인
    `Effect`의 `fn`은 가변 반환 팩(`-> ...(() -> ())`)이 더 맞는다
    (`base/effect-plan.md`). `:List`는 더 이상 item을 위해 `Source`를
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
            -- ⭐ [2026-08-26 교정, 8라운드 `H-121`] 한때 여기가
            --   `:With(offset):Compute(function(i, o) ... o:Get() ...)`였는데
            --   **확정 콜백 계약과 어긋난다** — `:With`로 모은 값은 포지셔널로
            --   안 넘어오고(`source-state-plan.md`: *"with한 값을 포지셔널 인자로
            --   받지 않고 클로저로 직접 읽는다"*), 2번째 자리에 실제로 오는 건
            --   `previous`다(첫 사이클엔 `nil` → `o:Get()`이 즉사, 이후엔 직전
            --   결과 숫자 → `number:Get()`으로 또 죽는다).
            LayoutOrder = layoutOrder:With(offset):Compute(function(i) return i:Get() + offset:Get() end),
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
차지할** 물리 위치"로 정확히 계산돼서 넘어오므로(아래 "구현" 절의
`reconcile` 참고, 직전까지의 생존분만으로 계산 가능해 이 item
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
`data`의 순서를 바꾸면 "지금 인덱스 ~= 이번 자리" 감지 → `Move`가 그대로
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
UB.**

**⚠️ [예시 추가, 2026-08-21] quad가 만든 Instance도 "GC만으로 정리되는 값"이
아니다.** 지금까지 이 절은 `:Subscribe()`한 Observer만 예로 들어서 **Instance는
안전해 보였는데, 정반대다** — quad는 자기가 만든 Instance마다 gcconn을 걸고 그
클로저가 `inst`를 캡처하므로("참조를 놓는 것만으로는 회수되지 않고 반드시
`Destroy`로 회수된다", `base/lifecycle-pattern.md`의 "(0)" 절) **`ud`에 담아둔
Instance는 아무도 안 들고 있어도 영원히 남는다.**

- 요소를 잠깐 떼어뒀다 되쓰고 싶으면 **`ud`에 직접 담지 말고 `Detach`를
  반환**할 것 — 그러면 `slot._detached`가 관리하고 owner가 죽을 때 같이
  정리된다(위 "Detach된 요소는 `slot._detached`가 보유한다" 절). `Detach`가
  생긴 뒤로는 `ud`에 Instance를 담을 이유 자체가 없다.
- 그래도 담겠다면 **정리 책임은 전적으로 사용자**다 — `:List`는 `ud` 안을
  들여다보지 않는다. `:List`가 어떤 teardown 경로도 보장 안 하므로, `userdata` 안의
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
function Slot:List(data, updateFn, keyFn, opts)
    if self._destroyed then error("Slot: destroyed Slot cannot be reused", 2) end   -- [2026-08-27 Q2]
    assert(not self._listed, "Slot already has :List installed")
    -- [2026-08-24 6라운드 손 트레이싱 `H-37`] **역방향 가드** — 산문(위 "CRUD API
    -- 확정" 절)이 확정해둔 대칭 가드가 의사코드에 안 옮겨져 있었다. 이게 없으면
    -- `Slot():Add(x); slot:List(...)`가 조용히 통과해, reconcile이 `x`의 존재를
    -- 모른 채(빈 `mounted`/`prevKeys`로) 시작한다.
    assert(not self._crudUsed, "Slot: cannot install :List after manual CRUD was used")
    self._listed = true
    self._listData = data
    self._updateFn = updateFn
    self._keyFn = keyFn or function(_, index) return index end
    -- [2026-08-21 감사] `Owned`를 실제로 심는 유일한 자리 — 이 줄이 없으면
    -- `settle`/`destroySlotTree`/`releaseElement`가 읽는 `self._owned`가
    -- 영원히 nil(=owned)이라 `Owned = false` 확정이 코드에 도달하지 못한다.
    -- 기본이 true이므로 **false일 때만** 필드를 세운다(nil = owned).
    if opts and opts.Owned == false then self._owned = false end

    -- [2026-08-24 `H-2`] 판정 기준을 `_mounted`가 아니라 **`_physicalTarget`**으로
    -- 넓힌다 — 실체화만 된 상태(부기는 서 있고 물리는 아직)에서 `:List`가
    -- 설치되는 경우도 지금 활성화해야 `materializeSlotTree`의 자식 루프 분기와
    -- 어긋나지 않는다. 물리 op은 `rawAdd`가 `_mounted`로 알아서 가른다.
    if self._physicalTarget then
        -- 초기 population도 `materializeSlotTree`와 같은 이유로 게이팅한다 —
        -- 안 그러면 아이템마다 `recompute`가 돌아 O(n²)(그 절의 `blocker:On()` 문단).
        -- [2026-08-27, `H-136` 후속] `reconcile`이 이제 자기 게이트를 쥐므로(`ownsGate`)
        -- **이 `if` 블록 전체가 잉여**다 — `On()`/`OffWithoutEmit()`뿐 아니라 아래
        -- `recomputeBlocker` 확인 + `recompute` 호출까지 `reconcile` 꼬리가 똑같이
        -- 한다. 안쪽에선 `ownsGate = false`로 걸러져 동작은 같다.
        -- `materializeSlotTree`와 모양을 맞추려 두지만, 구현 시 블록째 지우고
        -- `activateList(self, self._physicalTarget)` 한 줄만 남겨도 무방하다.
        local blocker = getBlocker(self)
        blocker:On()
        activateList(self, self._physicalTarget)
        blocker:OffWithoutEmit()
        local bk = getBookkeeping(self)
        -- ⭐ [2026-08-26 추가, `/code-review high`] 배치 Blocker는 방금 껐지만
        -- `bk.recomputeBlocker`는 따로 봐야 한다 — 사용자 코드가 바깥
        -- `recompute`의 `offset:Set(abs)` 안에서 이 Slot을 재진입 마운트하면
        -- (`H-119`가 세운 바로 그 전제) 중첩 `recompute`가 완주하고 그 꼬리의
        -- `bk.offsetSetUpTo = bk.N` + `recomputeBlocker:OffWithoutEmit()`이
        -- **바깥 루프의 되감기 신호를 지운다.**
        if not bk.recomputeBlocker:IsOn() then recompute(self, bk) end
    end
    return self
end

-- Dispatch/Slot.luau의 process(inst,k,self,index)가 마운트 시점에 1회 호출
-- (self._mounted=true/self._mountedInst=inst, self.Offset 세팅과 같은 자리)
-- [리네이밍, 2026-08-21] 2번째 인자는 `inst`였으나 `physicalTarget`으로 통일 —
-- 옆 함수들(materializeSlotTree/mountSlotTree/attachSlot)이 쓰는 이름과 같은
-- 개념이고, 실제로 항상 물리 Instance다(bindLifetime의 첫 인자로 들어감).
-- Slot일 수는 없다 — 그 Slot은 이미 1번째 인자 `self`다.
function activateList(self, physicalTarget)
    -- [2026-08-21 감사] **멱등 가드 — 두 번째 호출은 즉시 반환.**
    -- `Detach`로 뗐다 돌아온 자식 Slot이 `:List`를 갖고 있으면
    -- `materializeSlotTree`가 `slot._listed`를 보고 여기를 다시 부른다.
    -- 가드가 없으면 `data:Observer(fn)` 구독이 하나 더 생기고
    -- `mounted`/`userdata`/`prevKeys` 클로저 상태가 **통째로 새로 만들어져**
    -- 옛 상태를 잃은 채 reconcile이 두 벌 돈다(기존 요소를 전부 새 것으로
    -- 오인해 다시 그림). `_crudUsed`/`_listed`와 같은 결의 플래그.
    if self._listActivated then
        -- 재마운트(포탈 포함) — 클로저 상태(mounted/userdata/prevKeys)는
        -- 그대로 두고 **GC 앵커만 새 target으로 옮긴다.** 이걸 안 하면
        -- 자원이 옛 physicalTarget에 매달린 채로 남아, 그게 죽는 순간
        -- 살아있는 이 Slot의 `:List`가 조용히 반응을 멈추고(`_listObserver`)
        -- 살아있는 detached 요소가 파괴된다(`_detachCleanup`).
        -- [2026-08-21 /code-review high] `_listObserver`는 `data`가 reactive
        -- (State/Source)일 때만 세팅된다(아래 `isState(data)` 분기) — plain
        -- table `data`(문서가 지원하는 형태)면 영원히 `nil`이라, 가드 없이
        -- 부르면 `bindLifetime(physicalTarget, nil)`이 `gchold[nil] = true`로
        -- 죽는다(`base/lifecycle-pattern.md`의 `bindLifetime` 계약).
        -- 언마운트 쪽(`unmountSlotTree`)은 이미 `if slot._listObserver then`로
        -- 방어돼 있었는데 이 재마운트 분기만 빠져 있었다.
        if self._listObserver then bindLifetime(physicalTarget, self._listObserver) end
        bindLifetime(physicalTarget, self._detachCleanup)
        return
    end
    self._listActivated = true

    local keyFn, updateFn = self._keyFn, self._updateFn
    local offset = self.Offset
    -- **⭐ [2026-08-24 6라운드 손 트레이싱 `H-1`] `keyIndex`가 인덱스 맵에서
    -- 단순 키 집합으로 내려앉았다** — 이름도 `prevKeys`로 바꾼다.
    -- 옛 설계는 `keyIndex[key]`를 `_elements` 인덱스로 쓰고 `raw*`에 그대로
    -- 넘겼는데, 그 값은 **사이클 도중엔 stale**이다(`rawAdd`/`rawRemove`가
    -- 배열을 시프트하는데 교체는 사이클 끝에 한 번뿐). 이제 인덱스는
    -- `indexOfRaw(self, element)`(= `bk.indexOfElement` 조회 — **[2026-08-27 Q3]**
    -- 옛 `slot._elemIndex`는 Dispatch 부기로 갔다)로 그때그때 구하고,
    -- 여기 남는 건 **"직전 사이클에 존재했던 키"**라는 집합 용도뿐이다.
    local mounted, userdata, prevKeys = {}, {}, {}

    -- [2026-08-21] 한 키의 처분을 실제로 수행하는 공통 로직 — 정상 사이클과
    -- 소멸 루프가 같은 걸 쓴다(분기가 두 군데로 갈리면 반드시 어긋남).
    -- [2026-08-24 `H-2`] 4번째 인자는 **`_elements` 슬롯 위치**(`slotPos`)다 —
    -- 옛 이름 `pos`는 리프 카운터와 배열 인덱스를 한 변수에 겹쳐 쓰고 있었다
    -- (아래 `reconcile` 참고).
    local function settle(key, result, detach, slotPos)
        local wasMounted  = mounted[key]
        -- [2026-08-21 5라운드 `DE-7`] `_detached`는 **lazy** — 없을 수 있다.
        -- 읽기는 항상 nil 체크, 쓰기는 `getDetached(self)`(getOrCreate)로.
        local detached    = self._detached
        local wasDetached = detached and detached[key]
        local prev = wasMounted or wasDetached

        if detach then
            -- "이 자리를 비우되 죽이지 마라."
            -- **prev가 아예 없어도(마운트도 detach도 아님) nop** — 사용자가 "지금
            -- prev가 있는지"를 추적할 의무가 없다. 이미 detach 상태여도 nop.
            if wasMounted ~= nil then
                local idx = indexOfRaw(self, wasMounted)   -- [`H-1`] 지금 이 순간의 실제 인덱스
                if self._owned == false then
                    -- [2026-08-21 5라운드 `DE-13`] **내 것이 아니면 붙잡지 않는다** —
                    -- 언마운트 + 소유권 반납으로 끝내고 `_detached`에 넣지 않는다.
                    -- 다음 사이클의 `prev`는 `nil`이 된다(아래 "`Owned = false`에서
                    -- `Detach`" 절).
                    rawUnmount(self, idx)
                    mounted[key] = nil
                else
                    rawDetach(self, idx)           -- 언마운트하되 **소유권은 유지**
                    getDetached(self)[key], mounted[key] = wasMounted, nil
                end
            end
        elseif result == nil then
            -- "지워라". Owned=false면 파괴 대신 언마운트만(아래 "Owned" 절).
            if prev ~= nil then
                -- [`H-1`] detach 중이던 요소는 `_elements` 밖이라 인덱스가 없다(nil)
                local idx = if wasDetached ~= nil then nil else indexOfRaw(self, wasMounted)
                releaseElement(self, idx, prev, wasDetached ~= nil)
            end
            mounted[key] = nil
            if detached then detached[key] = nil end
        elseif result == unwrapElement(prev) then
            -- [2026-08-21 5라운드 `C-3`] 비교 대상은 **사용자가 받은 값**이다 —
            -- `prev`는 물리 요소(State를 반환했으면 래퍼 Slot)라 그대로 비교하면
            -- 같은 State를 다시 반환해도 "다른 값"으로 오인한다.
            if wasDetached ~= nil then
                detached[key] = nil                -- **재마운트** — detach된 걸 되살림
                -- 4번째 인자 = fromDetached. 소유권을 놓은 적이 없으므로
                -- `claimOwner`가 재클레임을 허용해야 한다(위 그 함수 주석).
                rawAdd(self, prev, slotPos, true)  -- 물리 요소(=래퍼)를 그대로 되돌림
                mounted[key] = prev
            else
                local idx = indexOfRaw(self, wasMounted)   -- [`H-1`]
                if idx ~= slotPos then
                    rawMove(self, idx, slotPos)    -- 그대로 쓰되 위치만 이동
                end
            end
        else
            -- 교체.
            -- [2026-08-21 5라운드 `B-5`] 마운트 중이던 자리는 **`rawReplace`** —
            -- "제거 후 삽입"으로 하면 `spliceArraysDown` + `spliceArraysUp`이 쌍으로
            -- 돌아 O(n) 시프트와 `recompute`가 두 번씩 난다. 자리 수가 안 바뀌는
            -- 교체엔 둘 다 불필요.
            local element = wrapElement(result)    -- State면 래퍼 Slot, 아니면 그대로
            if wasDetached ~= nil then
                -- detach 중이던 건 이미 `_elements` 밖이라 "자리 교체"가 성립 안 함
                releaseElement(self, nil, prev, true)   -- index 없음(트리 밖)
                detached[key] = nil
                rawAdd(self, element, slotPos)
            elseif wasMounted ~= nil then
                -- [`H-1`, 2026-08-24 `/code-review high` 지적으로 보강]
                -- `rawReplace`는 **자리를 유지한 채 내용만** 바꾼다. 그래서 같은
                -- 사이클에 순서까지 바뀌었으면(값 교체 + 리오더가 겹치는 경우)
                -- 교체 후 자리를 맞춰줘야 한다 — 안 그러면 그 요소만 옛 배열
                -- 자리에 남아, 이웃들의 `rawAdd`/`rawMove`가 `updateFn`에 알려준
                -- 순서와 다른 배열을 상대로 계산하게 된다.
                local idx = indexOfRaw(self, wasMounted)
                rawReplace(self, idx, element, self._owned ~= false)
                if idx ~= slotPos then rawMove(self, idx, slotPos) end
            else
                rawAdd(self, element, slotPos)
            end
            mounted[key] = element                 -- **물리 요소**를 기억한다(래퍼일 수 있음)
        end
    end

    -- **⭐ [2026-08-24 6라운드 손 트레이싱 `H-2`/`H-31`/`H-38`로 재작성]**
    -- 셋을 같이 고쳤다:
    --   (`H-2`) **두 좌표계를 분리했다.** 옛 `pos` 하나가 *리프 개수*(중첩 Slot은
    --     `.Length`만큼 전진)이면서 동시에 *`_elements` 배열 인덱스*로 쓰였다.
    --     이제 배열 자리는 `slotPos`(생존 아이템마다 +1)이고, `updateFn`에 넘기는
    --     물리 위치는 **`Dispatch.getOffsetAt`에서 구한다**(아래 참고).
    --   (`H-31`) **중복 키 검사를 선행 패스로 뺐다.** 옛 코드는 메인 루프 안에서
    --     item마다 검사해서, N번째에서 중복이 발견될 때 1..N-1의 `settle`이 이미
    --     물리/부기를 커밋한 뒤였다. 중복 키는 사용자 데이터에서 가장 흔한 실수라
    --     도달 빈도가 다른 패닉 경로와 다르다. `keyFn`을 한 번 더 도는 O(n)이
    --     붙지만 `:List`가 이미 O(n)이라 상수배다.
    --   (`H-38`) **키 집합을 증분 갱신한다.** 마지막 일괄 교체를 없앴다 —
    --     `updateFn`이 중간에 던지면 앞선 `settle`은 커밋됐는데 집합만 옛것으로
    --     남아, 그 사이클에 새로 생긴 키를 다음 사이클 소멸 루프가 못 물어
    --     영구 고아가 된다. 계약: **reconcile은 원자적이지 않지만 중단된
    --     지점까지는 정합하다.**
    local function reconcile(items)
        -- 선행 패스 1 — 키 수집 + 중복 검사. 여기선 아무것도 mutate하지 않는다.
        local keys, seen = table.create(#items), {}
        for i, item in ipairs(items) do
            local key = keyFn(item, i)   -- keyFn은 raw i를 받음(:List 파라미터 설명 참고)
            if seen[key] then
                error("Slot:List — duplicate key: " .. tostring(key))
            end
            seen[key] = true
            keys[i] = key
        end

        -- ⭐ [2026-08-27 확정, 9라운드 `H-136`] **한 사이클은 한 배치다** — 재실행
        -- (`data:Set(…)` → 이 함수)도 최초 population과 똑같이 Blocker로 감싼다.
        -- 안 그러면 raw op마다 `recompute`가 완주해 O(n²) + 부모 캐스케이드가
        -- 아이템 수만큼 나고, `dispatch-core-plan.md`의 *"한 사이클 … 한 번만"*이
        -- 거짓이 된다. `raw*`의 명시 호출은 이미 `getBlocker(self):IsOn()`을
        -- 보므로(`H-119`) 추가 배선은 없다.
        -- **Blocker는 네스팅이 안 된다**(불리언, `base/blocker-plan.md`) — 최초
        -- population은 `Slot:List`/`materializeSlotTree`가 이미 켜둔 **바깥 배치
        -- 안에서** 여기 오므로, 이미 켜져 있으면 손대지 않고 바깥이 끄게 둔다.
        -- `updateFn`이 도중에 던지면 켜진 채 남는 것은 `materializeSlotTree`가
        -- 이미 감수하는 것과 같은 부류(`pcall` 안 씀 — error 계약).
        local blocker = getBlocker(self)
        local ownsGate = not blocker:IsOn()
        if ownsGate then blocker:On() end

        local slotPos = 0   -- `_elements` 자리 카운터 — 생존 아이템마다 정확히 +1

        for i, item in ipairs(items) do
            local key = keys[i]

            -- [2026-08-21] prev는 "이 키의 요소" — 마운트돼 있든 detach돼 있든.
            -- 그래서 detach된 걸 그대로 반환하면 재마운트가 된다(settle 참고).
            -- [2026-08-21 5라운드 `C-3`] `updateFn`에는 **래핑 전 값**을 준다
            -- (물리 요소가 래퍼 Slot이어도 사용자는 자기가 준 State를 다시 본다).
            local prev = unwrapElement(mounted[key] or (self._detached and self._detached[key]))
            local candidateSlot = slotPos + 1   -- "이 item이 살아남으면 차지할" 배열 자리
            -- [2026-08-24 `H-2`] `updateFn`의 `index`는 **물리 위치**다 — 부기에서
            -- 그때그때 뽑는다. 실체화가 순차로 일어나므로 이 시점엔 1..candidateSlot-1의
            -- 길이가 이미 전부 확정돼 있다(`rawAdd`가 마운트 전에도 부기를 하도록
            -- 바뀐 것이 이걸 성립시킨다). 옛 코드는 `result.Length:Get()`을 직접
            -- 더했는데, **새로 만들어진 중첩 Slot의 `.Length`는 그 시점 항상 0**이라
            -- 아무것도 반영하지 못했다.
            -- `offset`은 이 Slot의 base **Source**(위 `local offset = self.Offset`)라
            -- 숫자를 쓰려면 `:Get()`. 1-based 상대 위치로 준다(옛 `candidateIndex`와 같은 기준).
            local physIndex = Dispatch.getOffsetAt(self, candidateSlot) - offset:Get() + 1
            local result, ud = updateFn(item, physIndex, offset, prev, userdata[key])
            if result == None then result = nil end   -- 편의: None도 nil과 동일 취급
            -- [2026-08-18, 이름 2026-08-19 확정] Detach는 "이 자리를 비우되 죽이지는 말라"는 지시.
            -- 아래 "Detach" 절 — 자리 계산 관점에선 nil과 똑같이 취급된다.
            local detach = (result == Detach)
            if detach then result = nil end

            if result ~= nil then
                slotPos = candidateSlot   -- 배열 자리는 요소 하나당 하나(중첩 Slot도 한 칸)
            end

            -- [`H-38`, 2026-08-24 `/code-review high` 지적으로 순서 정정]
            -- **`settle` *앞*에서 기록한다.** 뒤에 두면 `settle`이 물리/부기를
            -- 이미 커밋한 뒤 던질 때(`rawAdd` 안의 `claimOwner` 거부 등) 그 키가
            -- 집합에 안 들어가, 다음 사이클 소멸 루프가 못 물어 영구 고아가
            -- 된다 — `H-38`이 고치려던 바로 그 모양이다. 선행 패스가 `seen`을
            -- 미리 채우는 것과 같은 이유.
            prevKeys[key] = true
            settle(key, result, detach, slotPos)
            userdata[key] = ud       -- result와 무관, 그대로 기록
        end

        -- [재설계, 2026-08-21] 소멸 루프 — 조용히 파괴하지 않고 **처분을 묻는다**.
        -- 아래 "`KeyGone`" 절이 소스.
        -- [`H-38`] 스냅샷을 뜬 뒤 돈다 — 루프 안의 `settle`이 `prevKeys`를
        -- 건드리므로(아래 `prevKeys[key] = nil`) 순회 중 원본을 바꾸면 안 된다.
        for key in pairs(table.clone(prevKeys)) do   -- 직전 사이클에 존재했던 전체 key
            if not seen[key] then
                local prev = unwrapElement(mounted[key] or (self._detached and self._detached[key]))
                local result, ud = updateFn(KeyGone, 0, offset, prev, userdata[key])
                if result == None then result = nil end
                local detach = (result == Detach)
                if detach then result = nil end
                -- [2026-08-21 5라운드 `DE-9`] prev든 **새 값이든** 전부 error.
                -- KeyGone을 받은 자리는 "데이터가 다시 나타날 때를 위한 캐싱"
                -- (= Detach) 아니면 파괴뿐이고, **새 마운트/생성은 거부**한다.
                if result ~= nil then
                    error("Slot:List — KeyGone에는 nil/None(파괴) 또는 Detach(홀드)만 반환할 수 있음 "
                        .. "(자리가 없어진 키에 새 요소를 마운트할 수 없고, prev 유지도 모순)")
                end
                settle(key, result, detach, 0)   -- slotPos는 의미 없음(자리를 안 차지함)
                userdata[key] = ud               -- 유저가 nil을 반환해야 지워짐
                prevKeys[key] = nil              -- [`H-38`] 이 키는 이제 없다 —
                                                 -- **다음 사이클엔 다시 안 묻는다**
            end
        end

        -- ⭐ [2026-08-27, `H-136`] 배치 닫기 — `Slot:List`의 `_physicalTarget` 분기와
        -- 같은 꼬리. `recomputeBlocker`는 따로 본다(사용자 코드가 바깥 `recompute`
        -- 안에서 이 사이클을 일으킨 재진입이면 바깥 루프가 되감아 따라잡는다).
        if ownsGate then
            blocker:OffWithoutEmit()
            local bk = getBookkeeping(self)
            if not bk.recomputeBlocker:IsOn() then recompute(self, bk) end
        end
    end

    -- [이관, 2026-08-21] `_detached` 정리용 Effect는 원래 `mountSlotTree`가
    -- 모든 Slot마다 설치했으나 **여기로 옮겼다**(사용자 판단). `_detached`를
    -- 채우는 유일한 지점이 아래 `settle`의 `rawDetach`이므로, `:List`가 없는
    -- Slot의 `_detached`는 정의상 영원히 빈 테이블이다 — 중첩 트리 크기만큼
    -- no-op Effect와 `bindLifetime` 엔트리를 심고 있었다. 이제
    -- `_listObserver`와 **완전히 같은 취급**을 받는다(생성은 여기 1회,
    -- 언마운트 시 앵커만 해제하고 핸들 보존, 재마운트 시 위 가드가 재앵커,
    -- 파괴 시 해제+`nil`) — "`activateList`가 소유하고 물리 target에
    -- 앵커되는 자원"이라는 한 범주.
    -- Effect가 유일한 도구인 이유: `bindLifetime`은 "실행해도 되는가"만
    -- 게이팅할 뿐 죽는 순간의 콜백을 안 준다(`base/effect-plan.md`).
    self._detachCleanup = Effect(function()
        return function()
            if not self._detached then return end   -- [2026-08-21] lazy — 한 번도 detach 안 했으면 끝
            for key, element in pairs(self._detached) do
                -- releaseOwner를 **먼저, 두 분기 공통으로**. 빠뜨리면
                -- `_owned == false` 요소가 죽은 Slot을 owner로 달고 남아,
                -- 사용자가 그 값을 다른 Slot에 넣을 때 GC 타이밍에 따라
                -- "이미 마운트돼 있음" error가 난다 — 위 "소유권 반납은
                -- GC에 맡기면 안 됨" 절이 경계하는 실패 모드.
                releaseOwner(element, self)
                -- [2026-08-21 5라운드 `DE-13`] `_owned == false` 분기가 여기 있었으나
                -- 제거했다 — unowned Slot은 `_detached`를 **애초에 채우지 않으므로**
                -- (위 `settle`의 detach 분기) 여기 오는 건 전부 내 것이다.
                if isSlot(element) then destroySlotTree(element) else nativeDispose(element) end
                self._detached[key] = nil
            end
        end
    end)
    bindLifetime(physicalTarget, self._detachCleanup)

    local data = self._listData
    if isState(data) then
        local observer = data:Observer(function() reconcile(data:Get()) end)
        self._listObserver = observer   -- [2026-08-21] 재마운트 시 앵커를 옮기려면 보관 필요
        -- Observer 등록 자체의 "등록 즉시 1회 실행"은 canExecute
        -- 게이팅과 무관하게 여기서 이미 무조건 일어남(아래 "구독 시점" 절) —
        -- bindLifetime은 그 다음에 걸어 *이후* 재실행만 inst 생명주기에 귀속
        bindLifetime(physicalTarget, observer)
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
마운트된 개수**만 세는 별도 카운터라 이 문제가 없음 — `rawMove`/`rawAdd`도
전부 이 카운터 기준으로 통일(**[2026-08-24 `H-2`] 그 카운터는 이제 `slotPos`이고
리프 개수와 분리됐다**, 위 `reconcile`). filter 탈락 없이 순서대로 통과하는
흔한 경우엔 `pos == i`라 체감상 달라지는 게 없음.

**[같은 세션 후속] `updateFn`에 넘기는 `index`가 "살아남으면 차지할 위치"인
이유 — `idx`를 `:List`가 State로 관리하던 안을 기각하며 나온 재설계.**
그 값은 **"이 item이 이번 사이클에 살아남으면 차지할 위치"** — 직전까지
처리된 item들의 생존분만으로 계산되므로 이 item 자신이 살아남을지와 무관하게
`updateFn` 호출 **전에** 이미 정확히 알 수 있음.
(**[2026-08-24 `H-2`] 계산 방식만 바뀌었다** — 옛 `candidateIndex = pos + 1`은
리프 카운터와 배열 인덱스를 겹쳐 써서 틀렸고, 지금은 배열 자리를 `slotPos`로
따로 세고 넘기는 값은 `Dispatch.getOffsetAt`에서 뽑는다. **"살아남으면 차지할
위치를 미리 준다"는 이 성질 자체는 그대로다.**)
그래서 `result ~= nil`일 때만 `slotPos`를 커밋—
살아남지 못하면(`nil` 반환) 그 값은 그냥 버려지고 다음 생존자가 같은
값을 받음. 이 덕에 `updateFn`은 항상 **정확한 최종값**을 받아서, 위
"왜 `LayoutOrder`를 Slot이 대신 안 해주는가" 절의 `Source(index)` 예시처럼
새 원소를 처음부터 올바른 값으로 만들 수 있음(임시값→나중에 정정하는
이중 write가 생기지 않음) — 그 값 자체가 다음 자리를 미리 계산해두는
것뿐이라 look-ahead(아직 안 본 뒤쪽 item을 미리 훑는 것)가 전혀 필요 없는,
여전히 단일 forward pass(**[2026-08-24 `H-31`] 다만 중복 키 검사만은
선행 패스로 분리됐다** — `keyFn`만 도는 패스라 `updateFn` 호출은 여전히
한 번뿐이다).

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
  사이클의 키 집합(`prevKeys`)을 순회하는 이유** — `userdata`가 이제 `result ==
  nil`이어도 살아남을 수 있어서(위 "반환값 두 개는 서로 독립"), 어떤
  key가 `mounted[key] == nil`인 채로(필터 탈락 상태) `data`에서 완전히
  사라지면 `pairs(mounted)`로는 그 key가 아예 안 잡혀서 `userdata`가
  못 치워지고 샘 — 직전 사이클에 실제로 존재했던 **전체** key 집합
  (`prevKeys`, 매 사이클 모든 key에 대해 채워짐)을 순회해야 이 케이스를
  놓치지 않음. `userdata` 안에 사용자가 직접 넣어둔 `Source`(예: 위
  `LayoutOrder` 예시의 `layoutOrder`)도 이 정리 대상에 자연히 포함됨 —
  `:List` 자신은 그 안을 안 들여다보지만, `userdata[key] = nil`이 되는
  순간 참조가 끊겨 GC됨.
- **`mounted`/`userdata`/`prevKeys`**: `activateList`(마운트 시점 1회
  실행)의 로컬 변수(클로저 업밸류) — 별도 전역 weak table(`Relate` 등)
  불필요, `inst`/`self`가 살아있는 동안만 존재하면 되고 죽으면 클로저도
  같이 GC됨(아래 "구독 시점" 절).
- **`reconcile`이 직접 호출하는 건 `rawAdd`/`rawMove`와, 처분 헬퍼
  `releaseElement`(→ `rawRemove` 또는 `rawUnmount`)/`rawDetach`**
  (**[2026-08-21]** `Detach` 확정으로 `rawDetach`가, `Owned` 확정으로
  `releaseElement`가 추가됨 — 처분 분기가 한 군데(`settle`)로 모였다) (**[재정정, 2026-08-18 구현 전 QA]** 2026-08-13 여섯 번째
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
| 새 값(`result ~= nil`, `prev`와 다름) | **파괴**(`Owned = false`면 언마운트만) | `updateFn`이 만든 걸 `updateFn`이 자기 손으로 못 지운다(reconcile 중이라 `dispose`가 거부됨) — 지울 방법이 없으므로 reconcile이 대신 지운다. **[재정정, 2026-08-21]** 옛 서술의 "언마운트만"은 `state<Frame>` 케이스를 이 표에 섞은 것이었고, 그건 이제 `Owned = false`가 담당(아래 "`Owned` 옵션" 절) |
| `nil` / `None` | **파괴**(`Owned = false`면 언마운트만) | `updateFn`이 명시적으로 "이 자리를 지워라"라고 말한 것 |
| `Detach` | **언마운트만 + `slot._detached`가 계속 보유** | 아래. 이미 detach 상태면 **nop** |
| `prev`를 그대로 반환 | 마운트 중이면 위치만 이동, **detach 중이면 재마운트** | 아래 |
| 키가 데이터에서 사라짐 | **`updateFn`에게 `KeyGone`으로 처분을 묻는다** | **[재설계, 2026-08-21]** 아래 "`KeyGone`" 절 |

**`Detach` — `Instance.new`/`Destroy` 비용을 아끼는 재사용 경로.**
`filter` 용도처럼 "지금은 안 보이지만 곧 다시 필요할" 요소를 매번
파괴/재생성하는 건 비싸다. 그래서 `updateFn`이 **`Detach`를 반환**하면 그
자리는 파괴 없이 `Parent = nil`로만 내려오고 Slot에서 빠진다:

```lua
-- filter에서 걸러진 아이템 — 죽이지 말고 들고 있다가 나중에 되쓴다
return Detach
```

**[정정, 2026-08-21] 여기에 userdata를 딸려 보낼 필요는 없다.** 옛 서술은
`return Detach, { old = prev }`처럼 사용자가 직접 붙잡는 모양이었으나, 보존
주체가 `slot._detached`로 바뀌면서 다음 사이클에 그 요소가 **`prev`로 그대로
전달**된다 — 그냥 `return prev`하면 재마운트된다. 바로 아래 절.

#### ⭐ Detach된 요소는 `slot._detached`가 보유한다 — `userdata`가 아님 (2026-08-21 확정)

**[전면 정정]** 옛 서술은 *"보존 주체는 `userdata`"* 였다 — `updateFn`이
`return Detach, { old = prev }`처럼 자기 `ud`에 담아 붙잡고, 다음 사이클에
그걸 꺼내 반환하면 재마운트된다는 모양. **이건 최종 처분이 불가능해서
폐기**한다(사용자 확정: *"Detach 요소는 slot 안에 보관하는게 내 생각이였어서
… ud 에 넣는거로는 최종 처분이 불가하다에 동의함"*).

**왜 `userdata`로는 안 되나 — 세 가지**:

1. **`:List`가 안을 못 들여다본다.** `userdata`는 계약상 완전히 opaque다
   (아래 "`userdata`의 생명주기 제약" 절) — 파괴할 시점이 와도 **뭘 죽여야
   하는지 알 방법이 없다.**
2. **소유권이 붕 뜬다.** detach된 요소는 여전히 이 Slot이 관리 중이어야
   남이 못 가져간다(`elementOwner`). `ud`에만 있으면 Slot 쪽엔 아무 기록이
   없다.
3. **파괴 walk가 안 닿는다.** `destroySlotTree`는 `_elements`를 훑는데
   detach된 요소는 거기서 이미 빠졌다 — `ud` 안은 walk 대상이 아니다.

**그리고 이건 "GC가 언젠가 치우겠지"로 넘어갈 수 없다.** quad는 자기가 만든
Instance마다 gcconn을 걸고 **그 클로저가 `inst`를 캡처**하므로("참조를 놓는
것만으로는 회수되지 않고 반드시 `Destroy`로 회수된다",
`base/lifecycle-pattern.md`의 "(0)" 절), `Parent = nil`인 detach 노드는
**아무도 안 들고 있어도 자기 시그널 커넥션이 자기를 살려 영원히 남는다.**
GC 폴백이 아예 없으므로 명시적 정리 경로가 **필수**다.

**확정된 형태**:

- **`slot._detached: {[key]: T}?` — Slot 필드, 단 lazy(`nil` 허용).** 클로저
  업밸류가 아니라 필드여야 `destroySlotTree`/`dispose`의 walk가 닿는다.
  (`mounted`/`userdata`/`prevKeys`가 `activateList`의 업밸류로 남는 것과 다른
  이유 — **마운트된 요소는 `_elements`를 통해 walk가 이미 닿기 때문**이다.)
  - **⭐ [2026-08-21 5라운드 `DE-7`] 모든 Slot이 이 테이블을 미리 갖지
    않는다** — `_detached`를 채우는 건 `:List`의 `settle`뿐인데 Slot 대부분은
    `:List`도, detach도 없다. **사용자 판정**: *"테이블 생성 비용을 모든
    slot 이 가져야하나는 의문 … if 확인으로 nil 이면 스킵이 훨씬 싸게
    먹히지 않는가? … 최적화에 드는 비용이 거의 없는데, 안 할 이유가 보이진
    않음."* 그래서 **읽기는 항상 `if slot._detached then`, 쓰기는
    `getDetached(slot)`(getOrCreate 유틸)**로 통일한다 — `Relate`의
    `StrongMap`/`WeakMap`이 첫 `Set`에서야 만들어지는 것과 같은 관례
    (`base/relate-plan.md`의 "실제 구조" 절).
- **⭐ [2026-08-21 5라운드] `Detach`의 nop 조건은 둘이다** — (a) 이미
  detach 중, (b) **`prev`가 아예 없음**(그 키에 마운트된 것도 detach된 것도
  없음). 후자도 조용히 무시하므로 **`updateFn`이 "지금 prev가 있는지"를
  추적할 의무가 없다**(사용자 질문에 대한 확정) — `if not shouldShow(item)
  then return Detach end`처럼 조건만 보고 반환해도 안전하다.
- **⭐ [2026-08-21 5라운드 `DE-13`] `Owned = false`에서 `Detach`는
  `_detached`에 안 들어간다.** unowned 요소는 애초에 남의 것이라 "잠깐
  빼두고 내가 계속 들고 있는다"가 성립하지 않는다 — 그래서 `rawDetach`가
  아니라 **`rawUnmount`(언마운트 + 소유권 반납)**로 처리하고, 다음 사이클의
  `prev`는 `nil`이 된다. **사용자 판정**: *"애초에 unowned 의 state 로 받은것은
  더이상 가지고 있지 않는다. detach 에 들어가있지도 않는다. 외부로 반출된
  것이라 다시 들고와서 자기 자신에 붙이지 않음."* 부수 결과 — unowned
  `:List`에서는 `Detach`와 `nil`이 **같은 동작**이 되고(둘 다 언마운트+반납),
  `_detached`가 영원히 `nil`이라 `_detachCleanup`도 할 일이 없다.
- **소유권은 유지된다** — `Detach`는 `rawUnmount`(소유권 반납)가 아니라
  `rawDetach`(**소유권 유지**)를 쓴다. 아래 "raw 3형제" 참고.
- **`prev`로 그대로 돌려준다** — reconcile이 `mounted[key] or self._detached[key]`를
  `prev`로 넘기므로, **`updateFn`이 `ud`로 붙잡을 필요가 없다.** 그대로
  반환하면 재마운트된다.
- **이미 detach인데 또 `Detach`를 반환하면 nop**(사용자 확정) — 상태가
  그대로 유지될 뿐 아무 일도 안 일어난다. 매 사이클 filter에 걸리는 흔한
  경로라 여기서 뭔가를 반복하면 안 된다.
- **`ud`에 담는 것 자체는 여전히 자유** — 다만 **보존을 위해 담을 필요가
  없어졌고**, 담더라도 그건 사용자 몫이라 `:List`가 정리해주지 않는다
  (아래 "`userdata`의 생명주기 제약" 절).
- **⚠️ [2026-08-21 5라운드 `DE-11`] 문서화 시 반드시 같이 적을 것 — 홀드된
  요소는 owner가 죽을 때까지 쌓인다.** `Detach`는 **삽입/삭제가 빈번한
  경우를 위한 재사용 최적화일 뿐 그 이상을 돕지 않는다**(사용자 확정).
  키가 다시 안 나타나면 `_detachCleanup`이 도는 시점(owner 사망)까지
  `_detached`에 남으므로, churn이 큰 리스트에서 이걸 무한정 쓰면 메모리가
  는다 — 잘라내는 정책(LRU/최대 개수)은 **만들지 않는다**.

```lua
-- filter에서 걸러진 아이템 — 그냥 Detach만 반환하면 된다
if not shouldShow(item) then
    return Detach, ud       -- slot._detached가 붙잡아둠, ud로 홀드할 필요 없음
end
-- 다시 보여야 하면 prev를 그대로 반환 → 재마운트
if prev then return prev, ud end
```

#### `KeyGone` — 키가 데이터에서 사라질 때 처분을 묻는다 (2026-08-21 신설)

**옛 갭**: 소멸 루프가 `mounted[key]`/`userdata[key]`를 조용히 지웠는데,
`Detach`로 홀드 중이던 요소는 `mounted[key]`가 이미 `nil`이라 파괴 대상이
아니었다 — **파괴되지도, `updateFn`에게 되돌려지지도 않고 참조만 끊겼다**
(그리고 위 gcconn 때문에 GC도 안 됐다). 사용자 판정으로 **`updateFn`에게
한 번 더 물어보는 것**으로 해소:

```lua
updateFn(item: T | KeyGone, index, offset, prev, ud)
```

- **`KeyGone`은 `Detach`/`None`과 같은 급의 sentinel**이고, 공개 표면 위치도
  같다(패키지 최상위 export, 정의는 Slot 관련 파일 옆 — 아래 `Detach`의
  "공개 표면 위치 확정" 항목과 동일한 근거).
- **`updateFn`은 `if item == KeyGone then ... end`로 분기**해 처분을 고른다 —
  반환값 의미는 정상 사이클과 **완전히 같다**(`nil`=파괴, `Detach`=계속 홀드,
  새 값=교체). 그래서 reconcile의 처분 로직(`settle`)이 한 벌로 공유된다.
- **⭐ [정정, 2026-08-21 5라운드 `DE-9`] `nil`/`None`/`Detach` 외의 반환은
  전부 `error`** — `prev`를 그대로 반환하는 것뿐 아니라 **새 요소를 반환하는
  것도** 거부한다. **사용자 판정**: *"KeyGone 을 받은 요소는 오직 데이터의
  파괴 또는 detach 를 통해 다시 나오는 경우를 위한 캐싱 이외의 새로운
  마운트나 생성을 거부한다."* 자리가 없어진 키에 새 요소를 마운트하면
  넣을 위치 자체가 없다(옛 의사코드는 `pos = 0`으로 `rawAdd`를 불러 범위 밖
  인덱스로 터졌을 것). 그래서 소멸 루프의 `settle` 호출은 **항상 `result ==
  nil`**이고, 교체 분기에 도달하는 경로가 없다. (다른 CRUD 에러 조건들과 같은
  fail-fast 톤.)
- **`index`는 `0`** — 사라진 키는 자리를 안 차지한다. `offset`/`sum`이 이미
  0-based 개수라 "아무 자리도 없음"이 `0`으로 자연스럽고, `index: number`라는
  시그니처도 안 바뀐다(`nil`을 넣으면 타입이 바뀜). `offset`은 Slot의 것을
  그대로 넘긴다(항상 유효).
- **한 번만 묻는다 — 새 규칙이 필요 없다.** 소멸 루프는 **직전 사이클의
  `prevKeys`**(= 그때 데이터에 있던 키)만 순회하는데, 사라진 키는 소멸
  루프가 그 자리에서 지우므로 **다음 사이클엔 대상이 아니다.** 홀드된
  것은 `_detached`/`userdata`에 조용히 남아 있다가 (a) 키가 데이터에 다시
  나타나면 `prev`로 부활하고, (b) owner가 죽으면 `activateList`가 설치한
  `_detachCleanup` Effect가 정리한다(**[이관, 2026-08-21]** 원래
  `mountSlotTree`에 있었으나, `_detached`를 채우는 건 `:List`뿐이라
  `:List` 없는 Slot마다 no-op Effect를 심고 있었다).
- **`userdata`도 유저가 정한다** — `updateFn`이 `nil`을 반환해야 지워진다.
  키가 이미 사라졌으므로 다시 물어볼 기회가 없다는 뜻이지만, **owner가 죽으면
  전부 같이 사라지므로 영구 누수는 아니다**(사용자 확정: *"대신에 slot 의
  소유주가 죽으면 같이 죽는다. ud 도 모두 정리된다"*).
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
| `updateFn`이 `Detach` 반환 | `_detached`가 보유(소유권 유지) | **언마운트 + 소유권 반납**(`_detached`에 안 들어감, 다음 `prev`는 `nil`) — **[2026-08-21 5라운드 `DE-13`]** |
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

**[2026-08-21 짝 항목도 닫힘]** `Detach`로 홀드된 요소의 보관 위치
(`slot._detached` 필드)와 최종 처분(owner 죽을 때 `Effect`), `KeyGone`
센티널까지 같은 라운드에 확정됐다 — 아래 "Detach 요소는 `slot._detached`가
보유한다"/"`KeyGone`" 절이 소스. `destroySlotTree`가 `_owned == false`면
파괴 대신 언마운트로 빠지는 것도 그 확정의 일부.

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
지점)에 `activateList(self, physicalTarget)`가 수행(**[리네이밍,
2026-08-21]** 2번째 인자 이름은 `inst`였으나 owner 키가 Slot일 수도 있는
문맥과 헷갈리지 않도록 `physicalTarget`으로 통일 — 아래 실제 정의가 소스).
`Dispatch.setLength(inst,i, self.Length)`를 부르는 것과 같은 자리에서 같이
트리거되면 됨.

**`:List()`가 실체화 이후에 불리는 경우 — 그 자리에서 즉시 활성화 (확정)**:
마운트는 1회성 이벤트라, `:List()`가 늦게 호출되면 그 이벤트를 기다리는
방식으론 영영 활성화가 안 됨 — `:List()`가 그 자리에서 바로
`activateList`를 호출한다. CRUD와의 상호배타 가드(`self._listed`)와
같은 자리에서 자연스럽게 처리됨 — 호출 순서에 대한 새 제약을 추가하지 않음.
**⚠️ [판정 기준 정정, 2026-08-24 6라운드 `H-2`] 그 판정은 `self._mounted`가
아니라 `self._physicalTarget`이다** — 여기 원래 *"`self._mounted`를 확인해서
이미 참이면 … `activateList(self, self._mountedInst)`"*라고 적혀 있었는데,
`_mounted`는 이제 **물리 인스턴스 유무**만 뜻하므로 그 기준은 "실체화만 된
상태"(부기는 서 있고 물리는 아직)를 놓친다. 실제 확정 의사코드는 위
`Slot:List` 블록이 소스이고, 거기서 초기 population을 Blocker로 감싸는
것까지 같이 한다.

**canExecute와 "등록 즉시 1회 실행"의 관계 — 초기 실행은 게이팅과 무관하게
무조건 일어남(사용자 확인)**: `data:Observer(fn)`가 등록되는 순간
(`bindLifetime` 호출 *이전*) `fn`이 이미 한 번 동기 실행됨(Observer 자체의
"등록 즉시 1회 실행" 계약) — 이 시점엔 아직 `bindLifetime`을 안 걸어
`observer`에게 gcconn 참조가 없으므로 `canExecute`를 물으면 거짓이겠지만,
애초에 최초 실행은 `canExecute`로 게이팅되는 대상이 아니라서 상관없음
(**[정정, 2026-08-14 다섯 번째 세션]** 원래 "`bindLifetime`이 `Subscribed`를
세팅 전이라"고 적혀 있었으나 `bindLifetime`은 그 필드를 안 건드림 —
`.Subscribed`는 구독 경로 전용,
`archive/canexecute-inst-arg-reversed.md`.
**[2026-08-26 표기 정정, 8라운드 `H-111`]** 그때 "전역 `:Subscribe()` 전용"
이라 적었으나 **구독 경로(강/약) 공용**이 맞다 — `:WeakSubscribe()`도
세운다. `bindLifetime`이 안 건드린다는 요지는 그대로 유효). `bindLifetime`은 그
직후에 걸려서 **이후의** 재실행(`data`가 다시 바뀔 때)만 게이팅 —
`Dispatch.setLength`의 `bindLifetime(inst,observer)` 다음 줄에 있는
"등록 즉시 1회와 겹쳐도 무해"라는 주석과 정확히 같은 구조.

**Destroy 이후 — "재실행 막기"와 "관측 자체를 관두기"가 새 메커니즘 없이
한 번에 해결됨**: `inst`가 Destroy되면 `bindLifetime`의 `gcconn`(Roblox가
Destroy 시 자동으로 끊는 Connection)이 죽어 `canExecute`가 거짓이 되고
future 재실행이 no-op됨(위 "`state:Observer(fn)`" 절 원칙 재사용) — 그리고
"이전 state를 계속 관측하는 것도 관둬야 한다"는 요구도, `gchold`가
`Relate(inst)`(weak-keyed) 아래 있어서 `inst`가 죽으면 그 안에 강참조로
붙잡혀 있던 Observer/클로저(`mounted`/`userdata`/`prevKeys`를 포함해)가
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
조용히 어긋남 — 별도 방어 로직 없음, 문서 경고로만 남김. **[2026-08-28 10라운드
`H-148`]** 루트(`PlayerGui` 등 quad 밖 부모)는 사용자가 `.Parent =`로 붙이는 게
아니라 **quad가 `Claim`으로 소유**하는 쪽으로 방향이 확정됐다
(`research/existing-mount-plan.md`, M5 이후) — 그래서 이 금지에 예외가 없어진다.
(2026-08-27에 하루 있었던 "루트는 밖에서" 예외는 폐기.)

## `Slot:Single(state, updateFn?, opts?)` — 확정 (2026-08-11 세션, `:List` 위의 순수 sugar)

기존 "백로그, 미착수"에서 실제 설계까지 완료됨 — 새 reconcile 로직
없이 **`:List`를 정확히 0/1개짜리 배열로 감싸는 sugar**:

```lua
-- [정정, 2026-08-24 6라운드 손 트레이싱 `H-22`] **`KeyGone`을 흡수해야 한다.**
-- 소멸 루프는 `updateFn(KeyGone, ...)`을 부른 뒤 `nil`/`None`/`Detach`가 아닌
-- 반환을 전부 error로 막는데(5라운드 `DE-9`), 옛 identity는 받은 `KeyGone`을
-- 그대로 돌려주므로 **그 error에 100% 걸렸다.** 영향 범위가 `Slot:Add(state)`
-- sugar 전부 / `:Single(state)`의 updateFn 생략 전부 / 내부 `wrapElement` 전부라
-- 사실상 반응형 raw 요소 기능 전체가 첫 nil-전이에서 죽었다(같은 문서가
-- *"`State<T?>`(nilable)도 특별 취급 없이 그냥 됨"*을 보장하고 있어 문서 내부
-- 모순이기도 했다). 흡수 후 기본 동작은 "키가 사라지면 파괴"이고, 이는
-- `Owned` 표와도 맞는다(`Owned = false`면 `releaseElement`가 언마운트만 한다).
-- **사용자가 직접 쓰는 identity성 `updateFn`에도 같은 처리가 필요하다** —
-- `:List` 파라미터 설명에 명시할 것.
local function identityUpdateFn(item)
    if item == KeyGone then return nil end
    return item
end

function Slot:Single(state, updateFn, opts)
    updateFn = updateFn or identityUpdateFn   -- [2026-08-11 일곱 번째 세션] 기본값 추가

    local data = if isState(state)
        then state:Compute(function(v) return (if v:Get() == nil then {} else { v:Get() }) end)
        else (if state == nil then {} else { state })

    return self:List(data, function(item, index, offset, prev, ud)
        return updateFn(item, offset, prev, ud)   -- index는 항상 상수라 안 넘김
    end, function() return true end, opts)   -- 고정 key, opts는 그대로 전달
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
- `mounted`/`userdata`/`prevKeys` 전부 `:List`가 이미 갖고 있는 걸
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

> **✅ [해소, 2026-08-21] `attachSlot`의 책임 분해 — 분해로 확정, 아래
> 반영 완료.** 이 함수 하나가 책임을 일곱 개(부모 등록 offset/length,
> `:List` 실체화, 마운트 상태 전이, 배치 게이팅, 자식 배치, 재귀) 지고
> 있다는 사용자 지적에서 시작했고 — *"attachSlot 의 기능이 너무 다양해진게
> 문제같음"* — 진단은 **"부모에게 알리는 길이의 최종값은 flush가 끝나야
> 정해진다"와 "부기가 물리 조작보다 먼저"가 단일 함수로는 동시에 만족되지
> 않는다**는 것이었다(`setLength` 슬롯이 하나뿐이라 원리적으로 불가능).
> **결론: `materializeSlotTree`(부기) + `mountSlotTree`(물리)로 분해하고
> `attachSlot`은 그 둘을 부르는 두 줄짜리 래퍼로 남긴다** — 이름/시그니처/
> 호출부 전부 불변. 근거 기록은 `reference/slot-attach-decomposition.md`.

**✅ [해결, 2026-08-18 구현 전 QA 2라운드 후속]** 아래가 재사용하는
`Dispatch.setLength`/`setOffsetSource`/`recompute`가 배치 등록 중 크래시할
수 있던 문제(`RC-1`)는 해결됨 — `base/dispatch-core-plan.md`의
"배치 등록을 안전하게 만드는 Blocker 게이팅" 절이 소스. 이 문서에선 그
해법이 **`materializeSlotTree`의 등록 루프**에 어떻게 적용되는지만
다룬다(아래 코드의 `blocker` 관련 줄) — **[2026-08-21]** 분해 전엔 이 게이팅이
`attachSlot` 본체에 있었고, 물리 마운트 쪽(`mountSlotTree`)은 Blocker가
필요 없다.

`base/dispatch-core-plan.md`의 "Length/Offset" 절이 이미 확정해둔 두 함수는
owner 키(`inst`)가 물리 Instance일 필요가 없음(`Relate`가 아무 테이블이나
weak 키로 받음) — **Slot 자신을 owner 키로 재사용하면 최상위 마운트와
중첩 마운트가 완전히 같은 함수 호출**이 됩니다.

**[재정정, 2026-08-18 구현 전 QA 2라운드 후속] 호출 순서가 뒤집혀 있었음
— `setLength`가 먼저, `setOffsetSource`가 나중이던 것을 바로잡음.**
`base/dispatch-core-plan.md`의 "`NilHandler`" 절이 이미 확정해둔 **"호출
순서는 `setOffsetSource` → `setLength`"** 일반 규칙(해제 시점 계약에서
나왔지만 등록 시점에도 그대로 적용)과 이 의사코드(**[2026-08-21]** 분해
후엔 `materializeSlotTree`)가 계속 어긋나 있었던 것 — RC-1을 고치며 `setOffsetSource`가 즉시 계산을 하게
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
-- quad-base, Slot.luau
-- [전면 재작성, 2026-08-21 구현 전 QA 4라운드 확정] 옛 단일 `attachSlot`을
-- **비공개 재귀 둘 + 얇은 공개 진입점**으로 분해. 공개 표면(이름/시그니처/
-- 호출부 셋)은 하나도 안 바뀐다 — 쪼갠 건 함수가 아니라 **재귀**다.
-- 근거와 대안 비교는 `reference/slot-attach-decomposition.md`.

-- (1) 부기만 만든다. 물리 마운트(`Parent` 대입)를 단 한 줄도 안 한다.
-- ⭐⭐ [2026-08-27, 9라운드 `H-125`/Q2] `_baseObserver`의 콜백 — **Slot 생성자가
-- 만든다**(위 `Slot(initial)`). 이 함수는 생성자가 부르는 팩토리일 뿐이고, 여기
-- 두는 이유는 본문이 `bk`·`recompute`를 알아야 해서다.
local function makeBaseObserver(slot)
    return slot.Offset:Observer(function()
        -- ⭐ 미실체화면 할 일이 없다 — 생성자의 "등록 즉시 1회"를 여기서 삼킨다.
        --   이 가드가 없으면 그 1회가 **모든 Slot**에 대해 `getBookkeeping`을
        --   불러 `bk` + `recomputeBlocker`를 eager 생성한다(한 번도 마운트 안 되는
        --   Slot까지). 의미도 맞다 — 미실체화 Slot의 베이스 변경엔 할 일이 없다.
        if slot._physicalTarget == nil then return end
        -- ⭐ [2026-08-26, 8라운드 `H-119`/`H-3`] 두 줄이 빠져 있었다:
        --   (1) 배치 Blocker만 보고 `recomputeBlocker`를 안 봐서 재진입 차단이
        --       우회됐고, (2) `H-3`의 3번("베이스가 바뀐 경우라
        --       두 필드 `0`")이 의사코드에 없었다.
        local bk = getBookkeeping(slot)
        -- [2026-08-26] 무효화는 **두 필드를 다** 내린다(캐시도 낡고 Set도
        --   다시 해야 한다) — `dispatch-core-plan.md`의 "두 필드" 절.
        bk.offsetCacheValidUpTo, bk.offsetSetUpTo = 0, 0   -- 베이스가 바뀜 → 1번부터 전부
        if getBlocker(slot):IsOn() or bk.recomputeBlocker:IsOn() then return end
        recompute(slot, bk)
    end)
end

local function materializeSlotTree(slot, physicalTarget, ownerKey, position)
    -- [2026-08-27, 9라운드 Q2] 파괴된 Slot은 마운트 불가(위 "파괴된 Slot은 재사용
    -- 불가" 절). `attachSlot`이 이 함수를 거치므로 여기 한 번이면 된다.
    if slot._destroyed then error("Slot: destroyed Slot cannot be mounted", 2) end
    -- [2026-08-24 6라운드 `H-2`] **앵커를 먼저 저장한다.** `setLength`의 4번째
    -- 인자(그리고 length가 State일 때 `bk.observers`의 앵커)가 실체화 시점부터
    -- 필요한데 `_mountedInst`는 `mountSlotTree`에서야 채워진다. `raw*`가 이
    -- 필드를 본다(위 "`isMounted` 이중 추적 분리" 절의 3상태).
    slot._physicalTarget = physicalTarget

    -- ⭐⭐ [2026-08-27 순서 재배치, 9라운드 `H-125`/Q2] **게이트와 관측자 바인드가
    -- `setOffsetSource`(= 베이스가 바뀌는 emit) *위*로 왔다.** 옛 순서는
    -- `setOffsetSource` → `blocker:On()` → (`_baseObserver`가 있으면 bind /
    -- 없으면 생성)이었는데, 재마운트에선 그 관측자가 `unmountSlotTree`가
    -- unbind해둔 상태라 emit이 `canExecute`에 걸러져 **두 필드가 0으로 안
    -- 내려가고**, 꼬리 `recompute`가 옛 베이스의 `offsetCache[1]`을 그대로 썼다
    -- (첫 마운트는 "등록 즉시 1회"가 *우연히* 0으로 만들어 안 보였다 — 그
    -- 비대칭이 버그의 집). 이제 `Offset`/`_baseObserver`는 생성자에서 나므로
    -- 여기엔 생성 분기가 없고, 바인드는 **발화가 아니므로** 순서가 곧 계약이다.
    -- Blocker가 감싸는 게 **등록뿐**이라 "배치 등록 게이팅"이라는 정의와 범위가
    -- 정확히 일치함(옛 코드는 물리 마운트까지 같이 감쌌음).
    local blocker = getBlocker(slot)   -- Relate(slot) 기반, lazy 생성 — 이 Slot 전용
    blocker:On()
    -- [2026-08-21 5라운드 G절] **깊은 전파** — 앞 형제의 길이가 변해 내 베이스가
    -- 밀리면 내 자식들의 offset도 다시 계산돼야 한다. `_listObserver`/
    -- `_detachCleanup`과 **같은 취급**: 재마운트 땐 앵커만 새 target으로(앵커가
    -- 물리 target인 근거는 위 `C-4`). **바인드가 `blocker:On()` *뒤*인 게
    -- 중요하다** — 아래 emit이 깨운 콜백이 게이트 없이 `recompute(slot)`를
    -- 완주하면, 그 시점 `bk`는 언마운트 전 옛 부기(`Relate(slot)` 위에
    -- 살아남는다)라 옛 `N`·옛 자식 목록으로 돈다. 이 Blocker는 이 Slot의 것이고
    -- `setOffsetSource`는 **부모 owner의** blocker를 보므로 간섭이 없다.
    bindLifetime(physicalTarget, slot._baseObserver)
    -- offset — activateList가 updateFn에 이 값을 넘겨야 하므로(C1). 여기서
    -- `slot.Offset`이 새 베이스로 `Set`되고, 위 관측자가 두 필드를 0으로 내린 뒤
    -- 게이트에 걸려 돌아온다. **이미 있는 Source를 등록만 한다** — 매번
    -- `Source(0)`을 새로 만들면 언마운트가 `slot.Offset`을 일부러 보존해둔
    -- 이유(이미 렌더된 요소들이 그 Source를 **구독한 채 함께 딸려 나간다**,
    -- `SL-75`/`DC-6`)가 무너진다. identity 유지가 포탈의 전제.
    Dispatch.setOffsetSource(ownerKey, position, slot.Offset)
    -- [2026-08-21 5라운드 G절] `recompute(slot, ...)`은 `0`이 아니라 **이
    -- `slot.Offset`**에서 시작한다 — 그래야 자식 offset이 절대값이 된다(안 그러면
    -- depth ≥ 2에서 부모 베이스만큼 어긋남). 베이스를 부기에 따로 복사해두지
    -- 않는다(같은 값이 두 곳에 생김) — `base/dispatch-core-plan.md`의 `recompute`.
    -- `_mounted`는 여전히 false — reconcile의 rawAdd가 **물리 op을 건너뛰는**
    -- 경로를 타야 함(RC-3/RC-4). 이제 이 조건이 **함수 경계로 강제**된다:
    -- `_mounted`를 켜는 코드가 이 함수엔 아예 없음.
    -- **⭐ [2026-08-24 정정, `H-2`] 옛 서술은 그 경로를 "`_elements`에만 넣고
    -- 끝"이라고 적었는데 그건 이제 틀리다** — `rawAdd`는 마운트 전에도 부기를
    -- 전부 한다(`native*`만 건너뛴다). 그래야 population 도중
    -- `Dispatch.getOffsetAt`이 성립하고, `updateFn`에 넘기는 `index`를 거기서
    -- 구할 수 있다(아래 "`:List`의 `index`도 nested-Slot 결과의" 절).

    -- **⭐ [2026-08-24 순서 변경, `H-2`] `activateList`가 이제 Blocker *안*에서
    -- 돈다.** 5라운드 `AS-5`가 이걸 밖에 둬도 된다고 한 근거는 *"그 안에선
    -- 게이팅할 recompute 자체가 안 일어난다"*였는데, 위 정정으로 일어나게
    -- 됐다 — 밖에 두면 population 중 아이템마다 `recompute`가 돌아 O(n²)다.
    -- (`getOffsetAt`은 `lengthList`를 직접 읽으므로 게이트 안에서도 정확하다 —
    -- Blocker가 막는 건 `recompute`지 부기 등록이 아니다.)
    -- **⭐ [2026-08-24 분기, `H-2`. 같은 날 `/code-review high` 지적으로 조건 정정]**
    -- `activateList`가 **최초 population을 실제로 수행할 때만** 이 루프를
    -- 건너뛴다 — 그때는 그 안의 `rawAdd`가 이미 자리마다 등록을 마쳤으므로
    -- 여기서 또 돌면 같은 자리를 두 번 등록한다.
    -- **⚠️ 조건이 `slot._listed` 하나면 포탈 재마운트가 깨진다**: 재마운트에선
    -- `activateList`가 `_listActivated` 멱등 가드에 걸려 **앵커만 새 target으로
    -- 옮기고 즉시 리턴**하므로(위 그 함수), 루프까지 건너뛰면 보존된
    -- `_elements` 안의 중첩 Slot들이 **다시 실체화되지 않는다** —
    -- `_physicalTarget`이 `nil`인 채 `_mounted`만 켜지고, `_baseObserver`가
    -- **죽은 옛 target**에 매달린 채 남는다(그 가드 자신이 경고하는 실패 모드).
    if slot._listed and not slot._listActivated then
        activateList(slot, physicalTarget)   -- 최초 population — rawAdd가 자리마다 등록
    else
        if slot._listed then
            activateList(slot, physicalTarget)   -- 재마운트: 앵커만 새 target으로
        end
        for i, element in ipairs(slot._elements) do
            if isSlot(element) then
                -- 재귀 — 자식이 자기 끝에서 setLength(slot, i, 자기Length)까지 하고 옴
                materializeSlotTree(element, physicalTarget, slot, i)
            else
                -- 평범한 요소: 자기 자리의 offset은 아무도 안 읽으므로 None,
                -- length는 상수 1. 순서는 늘 offsetSource → setLength(C4).
                Dispatch.setOffsetSource(slot, i, None)
                Dispatch.setLength(slot, i, 1, physicalTarget, element)   -- 4번째 = 생명주기 앵커(5라운드 `C-4`), 5번째 = 요소(9라운드 Q3)
            end
        end
    end
    -- [2026-08-21 감사] 위 재귀가 **예외를 던지면 이 줄에 도달하지 못해
    -- Blocker가 켜진 채 남는다** — 그 Slot의 `recompute`가 이후 영원히
    -- 게이팅돼 `Length`가 영구 stale해진다. `pcall`로 감싸지 않는 것이
    -- **사용자 판단(2026-08-21)**: 마운트 도중 예외는 quad가 복구를 보장하지
    -- 않는 상태이고(에러 경계는 `base/fallback-plan.md`의 `Fallback`/
    -- `Traceback`이 담당), 아직 실제로 밟은 적 없는 경로다 —
    -- `conventions.md`의 "드문 오용이나 가상의 미래 요구까지" 절이 세운
    -- 원칙 그대로. 실제로 물리면 그때 넣는다.
    -- 참고: 이건 이번 분해가 만든 창이 아니라 옛 단일 `attachSlot`에도
    -- 있었을 구조적 갭이다(옛 코드도 같은 구간에 정리 코드가 없었음).
    blocker:OffWithoutEmit()
    local bk = getBookkeeping(slot)
    -- ⭐ [2026-08-26 추가, `/code-review high`] 위와 같은 이유로
    --   `recomputeBlocker`도 본다(`H-119`가 "명시 호출부 **전부**"라고 했는데
    --   이 자리와 `:List` 활성화 꼬리 둘이 빠져 있었다).
    if not bk.recomputeBlocker:IsOn() then
        recompute(slot, bk)              -- 여기서 slot.Length가 최종값으로 확정
    end

    -- 자기 길이를 부모에게. 이제 **처음부터 최종값**이고(C6), 동시에
    -- 어떤 Parent 대입보다도 먼저다(C7) — 단일 함수로는 둘을 동시에
    -- 만족시킬 수 없었던 지점. 5번째 = 이 Slot 자신(9라운드 Q3 — 길이가 State라
    -- 지속 등록이 생기는 자리, 클로저가 `bk.indexOfElement[slot]`을 조회한다).
    Dispatch.setLength(ownerKey, position, slot.Length, physicalTarget, slot)
end

-- (2) 물리만 붙인다. 부기를 단 한 줄도 안 건드린다 → Blocker 불필요.
-- **⚠️ [2026-08-21 감사] 전제: 반드시 `materializeSlotTree` 이후에만 부를 것.**
-- 아래 `acc`가 `slot.Offset:Get()`에서 시작하는데, 그 값이 최종값이 되는 건
-- materialize의 마지막 `recompute`가 끝난 뒤다. 순서를 뒤집거나 materialize를
-- 건너뛰고 부르면 물리 삽입 위치가 조용히 어긋난다(공개 `attachSlot`이 둘을
-- 붙여 부르는 것이 이 계약의 전부 — `reference/slot-attach-decomposition.md`의
-- "prepare만 하고 mount 안 한 중간 상태" 항목이 아직 열려 있는 이유이기도 하다).
local function mountSlotTree(slot, physicalTarget)
    slot._mounted = true
    slot._mountedInst = physicalTarget
    -- [2026-08-21 5라운드 G절] 물리 삽입 위치(절대 offset, 0-based)를 같이 넘긴다.
    -- 러닝 누적이라 O(n) — 자리마다 getOffsetAt을 부르면 O(n²)가 된다.
    local acc = slot.Offset:Get()
    -- [이관, 2026-08-21] `_detachCleanup` Effect 설치가 여기 있었으나
    -- `activateList`로 옮겼다 — `_detached`를 채우는 건 `:List`의 `settle`뿐이라
    -- List 없는 Slot마다 no-op Effect를 심고 있었다(위 그 함수의 주석이 소스).
    -- 그래서 이 함수는 이제 **정말로 물리 대입만** 한다.
    for i, element in ipairs(slot._elements) do
        if isSlot(element) then
            mountSlotTree(element, physicalTarget)    -- 자식은 자기 Offset에서 다시 시작
            acc += element.Length:Get()
        else
            nativeInsert(physicalTarget, acc, { element })   -- 주입 op(위 "native*" 절)
            acc += 1
        end
    end
end

-- (3) 공개 진입점 — 이름/시그니처/호출부 전부 옛것 그대로. 몸통만 두 줄.
local function attachSlot(slot, physicalTarget, ownerKey, position, mount)
    materializeSlotTree(slot, physicalTarget, ownerKey, position)
    -- [2026-08-24 `H-2`] **부모가 아직 마운트 전이면 실체화까지만 한다.**
    -- `rawAdd`가 마운트 전에도 부기를 하게 되면서(위 그 함수) 자식 Slot에도
    -- "부기는 하되 물리는 안 함"이 필요해졌다. `mount`가 생략되면 true
    -- (기존 호출부 전부가 마운트까지 원하는 경로라 기본값이 옛 동작이다) —
    -- `rawAdd`/`rawReplace`만 `self._mounted`를 그대로 넘긴다.
    if mount ~= false then
        mountSlotTree(slot, physicalTarget)
    end
end
```

**왜 쪼갰나 — 이득 넷**(상세와 기각된 대안은
`reference/slot-attach-decomposition.md`):

1. **C6와 C7이 처음으로 동시에 만족된다.** 옛 코드는 `setLength`의 자리가
   하나뿐이라 "최종값으로 등록"(C6)과 "부기가 물리보다 먼저"(C7) 중 하나를
   포기해야 했다 — C7을 지키고 `Length = 0`으로 등록한 뒤 자기 교정하는
   쪽이었다. 분해하면 둘 다 성립하고, **배치 밖 재마운트의 부모 `recompute`가
   2회 → 1회**로 준다(아래 "해소" 참고).
2. **순서 제약이 줄 순서가 아니라 함수 경계로 강제된다.** `RC-1`/`RC-3`/`RC-4`가
   전부 "한 함수 안에서 줄 순서를 잘못 잡아" 난 버그였는데, `_mounted`를 켜는
   코드가 `materializeSlotTree`엔 아예 없으므로 그 실수 클래스가 구조적으로
   사라진다. **사용자 확정 근거**: *"이게 하나의 큰 복잡한 복합 함수라 여러
   session 간의 실수가 발생하던 부분이고 … 지금 의사코드를 건들이는 비용이,
   추후 실수가 누적되는 비용보다 싸다고 생각함."*
3. **`_mounted`의 의미가 정직해진다** — 옛 코드에선 "`activateList`는 지났고
   flush는 아직"이라는 중간 시점이었는데, 이제 문자 그대로 "mount 단계를
   지났는가"다.
4. **Blocker의 범위가 정의와 일치하고, 백엔드에 seam이 생긴다** —
   `mountSlotTree`가 부기를 안 건드리는 순수 walk라, 일괄 삽입이 유리한
   백엔드(웹 `DocumentFragment` 등)가 **이 함수 하나만** 갈아끼울 수 있다.

**⚠️ 바뀌는 관측 가능한 동작 하나 — 물리 마운트가 "부기 완료 후 일괄"이 된다.**
`Parent` 대입 **순서 자체는 동일**(둘 다 깊이 우선 같은 순서)하지만, 옛
코드는 부기와 물리가 인터리브됐고 지금은 부기가 전부 끝난 뒤 물리가 몰린다.
`Parent` 대입은 `ChildAdded`/`DescendantAdded`를 **동기 발화**시키므로 사용자
핸들러가 이 차이를 관측할 수 있는데, **분해 쪽이 더 정확하다** — 첫
`ChildAdded`가 뜰 때 서브트리 전체의 `Length`/`Offset`이 이미 최종값이다(옛
코드는 `inner.Length == 0`인 미완성 스냅샷을 보여줬다). `slot.Length`
구독자도 `0` → 최종 두 번이 아니라 최종값으로 한 번 발화한다.

**✅ [해소, 2026-08-21] 옛 "좁은 엣지 케이스"는 이 분해로 사라졌다.**
여기 있던 ⚠️ 항목(배치 밖 단독 재마운트 시 부모 `recompute`가 아직 안 굳은
`slot.Length`로 한 번 헛도는 것)은 `setLength`가 `materializeSlotTree` 끝으로
가면서 **처음부터 최종값**이 되어 발생 경로가 없어졌다. 트레이싱 원문은
`qa-request/pre-implementation-qa-round3.md`의 "확인만 하고 새 결함 없음" 절.

**최상위 마운트(`Dispatch/Slot.luau`)는 이제 이 함수 호출 한 줄:**
```lua
-- process(inst, k, slotValue, index)
attachSlot(slotValue, inst, inst, k)   -- ownerKey = 물리 inst 자신
```

**이미 마운트된 outer에 nested Slot을 나중에 `Add`하는 경우(런타임에
카테고리 추가):**
```lua
-- rawAdd 안, element가 Slot일 때
-- **[2026-08-24 정정, `H-2`]** 옛 서술은 *"self가 아직 마운트 전이면
-- `_elements`에만 들어가고 나중에 처리"*였는데, 그러면 최초 population 중
-- `getOffsetAt`이 성립하지 않는다. 이제 **부기는 항상 하고 물리만 가른다.**
attachSlot(element, self._physicalTarget, self, index, self._mounted)
--                                                     ^^^ mount 여부
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
    -- **⭐ [2026-08-24 정정, 6라운드 손 트레이싱 `H-6`] 두 가지를 고쳤다.**
    -- (1) `physicalTarget`이 **어디에도 안 묶여 있었다** — 인자는 `slot` 하나뿐인데
    --     아래 루프가 그 이름을 참조했다. 로컬로 먼저 뽑아 쓴다(같은 함수가
    --     아래에서 `slot._mountedInst = nil`로 지우므로 읽는 순서도 지켜야 한다).
    -- (2) **역순 순회로 바꿨다** — 앞에서부터 빼면 뒤가 물리적으로 당겨져
    --     두 번째부터는 `getOffsetAt`이 주는 부기 offset과 실제 물리 위치가
    --     어긋난다. Roblox 백엔드는 `elements` 배열로 받으니 무해하지만
    --     offset을 신뢰하는 백엔드(DOM `childNodes[offset]` 최적화 등)에선
    --     틀린 자리를 짚는다. 뒤에서부터 빼면 앞쪽 offset이 안 밀려 매번 정확하다.
    local physicalTarget = slot._mountedInst
    for i = #slot._elements, 1, -1 do
        local element = slot._elements[i]
        if isSlot(element) then
            unmountSlotTree(element)   -- 재귀 — 중첩 Slot도 똑같이 비파괴
        elseif physicalTarget then     -- [`H-12`] 실체화만 된 상태면 뗄 물리가 없다
            nativeExtract(physicalTarget, Dispatch.getOffsetAt(slot, i), { element })   -- 파괴 아님(주입 op)
        end
        -- releaseOwner를 **안 부름** — 자식들은 여전히 이 slot의 소유. 이게
        -- destroySlotTree와의 핵심 차이(파괴는 소유권까지 반납, 언마운트는 유지).
    end
    -- [2026-08-26, `/code-review high` 6차] `if bk then` 가드를 뺐다 —
    --   `getBookkeeping`은 lazy 생성이라 절대 nil이 아니다
    --   (`base/dispatch-core-plan.md`). 같은 파일 안에서 어떤 자리는 가드하고
    --   어떤 자리는 안 하던 불일치를 없앤다.
    local bk = getBookkeeping(slot)
    for i, observer in pairs(bk.observers) do
        unbindLifetime(observer)       -- 물리 target에 걸린 배관만 해제
    end
    -- [2026-08-21] `activateList`가 소유하는 두 자원의 **앵커만** 푼다.
    -- 안 풀면 옛 physicalTarget이 죽을 때, 지금은 다른 곳에 살아있는 이
    -- Slot의 `:List`가 조용히 멈추고(`_listObserver`) `_detached`가
    -- 파괴된다(`_detachCleanup`) — 포탈 경로에서 실제로 터진다.
    -- **핸들과 `_listActivated`는 보존한다**(언마운트는 파괴가 아니다) —
    -- 구독과 그 클로저 상태(`mounted`/`userdata`/`prevKeys`)는 재마운트
    -- 후에도 이어져야 하고, 새 target에 다시 걸어주는 건 `activateList`의
    -- 멱등 가드다. 파괴 쪽(`destroySlotTree`)만 핸들까지 `nil`로 지운다.
    if slot._listObserver then unbindLifetime(slot._listObserver) end
    if slot._detachCleanup then unbindLifetime(slot._detachCleanup) end
    unbindLifetime(slot._baseObserver)   -- [2026-08-21 G절; 2026-08-27 Q2] 생성자에서 나므로 항상 있다 — 가드 없음
    -- `slot._detached`는 **안 건드린다** — 언마운트는 파괴가 아니고,
    -- 재마운트되면 그대로 이어져야 한다(`_elements`를 보존하는 것과 같은 이유).
    slot._mounted, slot._mountedInst = false, nil
    slot._physicalTarget = nil   -- [2026-08-24 `H-2`] 앵커도 같이 — 안 지우면 죽은
                                 -- inst를 계속 강하게 붙잡는다(재실체화가 새로 채운다)
    -- [정정, 2026-08-20 `SL-75`] slot.Offset은 건드리지 않는다 — nil로 되돌리면
    -- 그 Source를 이미 구독 중인 다운스트림이 영구히 끊긴다(포탈이 깨짐).
    -- stale한 채 남겨두고, 재마운트 시 setOffsetSource의 즉시 계산이 덮어쓴다.
    -- slot 자신의 unbindLifetime / releaseOwner / owner쪽 setLength·setOffsetSource는
    -- 호출부 몫 — destroySlotTree와 동일한 층위 분리.
end

local function destroySlotTree(slot)
    -- [2026-08-27, 9라운드 Q2] 이중 파괴는 no-op — teardown 경로가 겹치는 건
    -- 실재한다(`dispose`가 이 함수를 부르므로 이중 `dispose`도 여기서 흡수).
    if slot._destroyed then return end
    -- [2026-08-21] Owned=false면 이 Slot은 요소를 만든 적이 없다 — 파괴 대신
    -- 언마운트만(위 "`Owned` 옵션" 절). `Slot:Add(state)` sugar가 그 경우.
    if slot._owned == false then
        unmountSlotTree(slot)
        return
    end
    for i, element in ipairs(slot._elements) do
        -- [재정정, 2026-08-20 구현 전 QA 4라운드 `C-4`] 여기서 releaseOwner를
        -- 명시적으로 부르지 **않는다** — 2026-08-13 감사가 넣었던 것을 되돌림.
        -- 근거는 아래 "소유권 반납은 GC에 맡기면 안 됨" 절의 재정정 참고.
        if isSlot(element) then
            destroySlotTree(element)   -- 재귀는 "파괴"에만, choreography 없음
        else
            nativeDispose(element)
        end
    end
    -- [2026-08-21] Detach로 홀드 중인 요소도 같이 파괴 — 이것들은 `_elements`에
    -- 없으므로(rawDetach가 뺐음) 위 루프가 못 닿는다. **`dispose`가 재귀적으로
    -- 잘 죽이는가**의 답이 정확히 이 줄이다(아래 "`dispose`" 절).
    if slot._detached then                 -- [2026-08-21 5라운드 `DE-7`] lazy — 없으면 통째로 스킵
        for key, element in pairs(slot._detached) do
            if isSlot(element) then destroySlotTree(element) else nativeDispose(element) end
            slot._detached[key] = nil
        end
    end
    if slot._detachCleanup then
        unbindLifetime(slot._detachCleanup)   -- 이미 손으로 비웠으니 Effect는 할 일 없음
        slot._detachCleanup = nil
    end

    -- [2026-08-21 감사] `:List` 구독도 푼다 — **파괴이므로 `unmountSlotTree`와
    -- 달리 핸들과 `_listActivated`까지 지운다.** 안 풀면 `gchold[physicalTarget]`이
    -- observer를(그리고 그 클로저가 붙잡은 `mounted`/`userdata`/`prevKeys`와
    -- 파괴된 slot 자신을) 계속 강하게 붙잡는다 — 중첩 Slot은 아무리 깊어도
    -- `physicalTarget`이 트리 최상위 inst 하나라(`materializeSlotTree`가 같은
    -- 값을 재귀에 그대로 넘김) **자식 Slot만 죽고 그 inst는 살아있는 게 흔한
    -- 경우**다. 그러면 `data`가 emit될 때마다 이미 죽은 자식들에 대해
    -- reconcile이 계속 돈다.
    -- ⭐⭐ [2026-08-27 정정, 9라운드 Q2] **핸들은 unbind만 하고 지우지 않는다.**
    -- 여기 한때 `slot._listObserver, slot._listActivated = nil, nil`과
    -- `slot._baseObserver = nil`이 있었다 — 근거(*"안 풀면 `gchold[physicalTarget]`이
    -- observer를 계속 강하게 붙잡는다"*)는 실은 `unbindLifetime`이 하는 일이고,
    -- `nil` 대입은 slot → observer 참조 하나를 놓는 것뿐인데 slot 자신이
    -- 쓰레기라 공짜다. 대신 그 `nil`이 **"파괴됨"이라는 두 번째 뜻**을 세 필드에
    -- 겸하게 했고(`_listObserver == nil`은 원래 "`data`가 plain table", 
    -- `_listActivated == nil`은 "최초 population 전"이라는 자기 뜻이 있다) —
    -- `invalidAfter`가 두 뜻을 겸하다 사고 난 것과 같은 모양이라 그만둔다.
    -- 파괴됨은 아래 `_destroyed` 하나만 말한다.
    if slot._listObserver then unbindLifetime(slot._listObserver) end
    unbindLifetime(slot._baseObserver)         -- 생성자에서 났으므로 항상 있다(Q2)
    local bk = getBookkeeping(slot)    -- 이 slot이 자기 자식들 위해 등록해둔 observer들
    for i, observer in pairs(bk.observers) do   -- [2026-08-26] 가드 제거(위와 같은 이유)
        unbindLifetime(observer)
    end
    -- [정정, 2026-08-13 감사] 마운트 상태도 되돌림 — 안 그러면 파괴된 Slot이
    -- `_mounted == true`로 남아 "마운트된 Slot의 재마운트는 즉시 throw"(위 절)에
    -- 영원히 걸리고, `_mountedInst`가 죽은 inst를 계속 강하게 붙잡음.
    slot._mounted, slot._mountedInst = false, nil
    slot._physicalTarget = nil   -- [2026-08-24 `H-2`] 같은 이유로 앵커도
    -- ⭐ [2026-08-27, 9라운드 Q2] 파괴됨은 이 플래그 하나가 말한다 — 마운트·공개
    -- CRUD·`:List` 진입이 이걸 보고 error한다(위 "파괴된 Slot은 재사용 불가" 절).
    -- `_mounted = false`만으로는 재마운트 throw 가드에 안 걸리는 게 문제였다.
    slot._destroyed = true
    -- [2026-08-12 열여섯 번째 세션, 스코프 정정] slot 자신의 unbindLifetime은
    -- 여기서 안 부름 — attachSlot이 최상위에서만 bindLifetime하므로 짝도
    -- 최상위 파괴 지점(SlotHandler.process가 반환하는 클로저, 위)에서만 한 번.
    -- destroySlotTree는 재귀 전체에서 항상 이 위치까지만(자식 Observer 정리) 담당.
end

-- [명확화, 2026-08-13 감사에서 index/element 불일치 발견해 보강] 아래
-- **✅ [해소, 2026-08-21 5라운드 — index 기준으로 통일 확정]** 오래 열려 있던
-- "raw*가 index 기준과 element 기준으로 섞여 있다"는 캐비엇은 **전부 index로
-- 통일**하는 것으로 닫혔다(**사용자 확정**: *"index 로 전부 처리되면 될듯.
-- 애초에 안에서 다시 element -> index 를 찾아야하던걸로 앎"*).
--   * `rawRemove`/`rawUnmount`/`rawDetach`/`rawMove`/`rawSwap`/`rawExtract`/
--     `rawSplice`/`rawReplace` — **전부 index를 받는다.**
--   * 예외는 `rawAdd(self, element, index, fromDetached?)` 하나 — 새로 넣는
--     대상이라 element가 인자인 게 당연하다(그 element는 **이미 래핑된 물리
--     요소**여야 한다, 아래 "래핑은 raw 바깥에서" 항목).
--   * **⭐ [전면 정정, 2026-08-24 6라운드 손 트레이싱 `H-1`]** 여기 원래
--     *"element만 손에 쥔 호출부(`:List`의 `settle`)가 index를 구해야 하는데,
--     그 값은 이미 `keyIndex`가 들고 있다"*라고 적혀 있었다. **그게 틀렸다** —
--     `keyIndex`는 사이클 **끝**에 한 번 교체되는데 사이클 도중의
--     `rawAdd`/`rawRemove`가 배열을 시프트하므로, 그 뒤에 처리되는 키들의
--     `keyIndex` 값은 전부 어긋나 있다(`[a,b]`→`[x,a,b]`가 조용히 `a,b,x`가
--     되고, 전체 삭제는 해시 순회 순서에 따라 `nil` 인덱싱까지 간다).
--   * **확정된 해법 — 역방향 인덱스 맵을 raw 층이 직접 든다.**
--     **⭐ [2026-08-27 이동, 9라운드 Q3] 그 맵은 이제 `bk.indexOfElement`
--     (Dispatch 부기)다** — 여기 한때 `slot._elemIndex`였는데, 7라운드 `H-102`가
--     같은 뜻의 맵을 Dispatch 층에 따로 만들어(그것도 사용자가 정한 적 없는
--     `token`으로) **같은 맵이 두 층에** 살게 됐고, 그게 사고의 원인이었다
--     (사용자: *"elem->index 를 누가 관리하느냐가 어디서 관리하느냐가 명확하지
--     않아서 자꾸 사고가 나는듯"*). 소유는 `bk` 하나, owner가 Slot이든 `inst`든
--     규칙 하나. raw 층은 `getBookkeeping(self).indexOfElement`를 **읽고
--     갱신**한다 — 아래 항목들의 "맵"은 전부 이것.
--     (`물리 요소 → _elements 인덱스`)를 `_elements`와
--     같은 수명으로 두고, **자리를 밀거나 당기는 모든 연산**
--     (`spliceArraysUp`/`spliceArraysDown`/`rawMove`/`rawSwap`/`rawReplace`/
--     `rawAdd`)이 같이 갱신한다. detach된 요소는 `_elements` 밖이므로
--     맵에서도 빠진다(`rawDetach`가 지운다).
--     - **`raw*`의 index 시그니처는 그대로다**(위 목록 유지) — 바뀌는 건
--       "호출부가 index를 어디서 구하는가"뿐이다.
--     - **`indexOfRaw(self, element)`가 이 맵 조회가 되고, 폴백이 아니라
--       기본 경로로 승격된다.** `settle`은 `keyIndex[key]` 대신
--       `indexOfRaw(self, prev)`를 쓴다.
--     - **층 분리는 오히려 더 깨끗해진다** — 맵이 `raw*`가 이미 만지는 부기
--       (`bk`)에 살아서 `raw*`가 `:List`의 클로저 상태(`mounted`/`prevKeys`)를 볼
--       필요가 없다(**[2026-08-27]** 원문은 *"`_elements`와 같은 층에"*였다 —
--       맵이 `bk`로 가도 이 논거는 그대로다). **사용자 판단**(2026-08-24): *"raw* 가 층위를 알아야할
--       이유를 모르겠는 상태. 그냥 k->realElem 을 list 에선 저장하고 …
--       realElem->index 해시맵을 만들어주고, index 밀고 당기는 동작에서 이걸
--       같이 업데이트해주는 편이 나아보이기도. quad-base 의 현 모양에서 더
--       확장 될 땐, index 를 알아야하게 되는 경우가 많아질것이라, 선제
--       처리로 해결하는게 맞아보이는데"*.
--     - **비용**: 시프트는 이미 O(n) memmove라 맵 갱신이 점근 비용을 안
--       올리고, 조회만 O(n)→O(1)이 된다.
--     - **키 유일성은 이미 보장돼 있다** — `claimOwner`/`claimOwnerAt`이 같은
--       요소의 이중 배치를 error로 막으므로(위 "요소 소유권" 절) `물리 요소 →
--       index`는 함수로 잘 정의된다.
--     - **부수 효과**: `:List`의 `keyIndex`가 인덱스 맵일 이유가 없어져
--       **단순 키 집합**으로 내려앉는다(소멸 루프의 "직전 사이클에 존재했던
--       키" 용도만 남음) — 아래 `reconcile` 참고.
--     - 앞으로 `Move`/`Swap`/`Extract`/`Splice`와 공개 `Slot:IndexOf`가 전부
--       이 맵을 쓴다(그것들이 element→index를 필요로 하는 게 이 결정의
--       근거 중 하나였다).
-- [신설, 2026-08-13 여섯 번째 세션] rawRemove의 비파괴 짝 — `:List`의
-- reconcile과 `Extract` 계열이 씀. rawRemove와 **딱 하나만 다름: 안 죽인다.**
function rawUnmount(self, index)
    local element = self._elements[index]
    local bk = getBookkeeping(self)
    if bk.observers[index] then
        unbindLifetime(bk.observers[index])
    end
    releaseOwner(element, self)   -- 소유권은 반납(이제 다른 곳에 넣을 수 있음)
    -- [2026-08-24 6라운드 `H-12`] **부기는 항상, 물리 op만 `_mounted`로 가른다** —
    -- `rawAdd`와 같은 규칙(위 "`isMounted` 이중 추적 분리" 절의 3상태).
    -- `unmountSlotTree`는 자기 안에서 `_mounted`를 보므로 여기선 안 가른다.
    if isSlot(element) then unmountSlotTree(element)
    elseif self._mounted then
        nativeExtract(self._mountedInst, Dispatch.getOffsetAt(self, index), { element })
    end

    spliceArraysDown(self, index)   -- _elements/lengthList/sourceList/observers/bk.indexOfElement/bk.N — 아래 참고
    -- ⭐ [2026-08-26, 8라운드 `H-119`] 명시 호출도 재진입 게이트를 먼저 본다.
    --   건너뛴 몫은 위 spliceArraysDown이 당겨둔 `bk.offsetSetUpTo`로
    --   바깥 `recompute`의 되감기가 복구한다(`dispatch-core-plan.md`).
    if not (getBlocker(self):IsOn() or bk.recomputeBlocker:IsOn()) then
        recompute(self, bk)         -- 자리가 없어지는 경로엔 setLength가 없으므로 여기서 명시 호출
    end
end

-- [신설, 2026-08-21] rawUnmount의 "소유권 유지" 짝 — `Detach`가 쓴다.
-- rawUnmount와 **딱 하나만 다름: releaseOwner를 안 부른다.**
-- detach된 요소는 여전히 이 Slot이 들고 있으므로(slot._detached) 소유권을
-- 놓으면 남이 가져갈 수 있게 되어 "다중 마운트 금지" 불변식이 깨진다.
function rawDetach(self, index)
    local element = self._elements[index]
    local bk = getBookkeeping(self)
    if bk.observers[index] then
        unbindLifetime(bk.observers[index])
    end
    -- releaseOwner를 **안 부름** — 이게 rawUnmount와의 유일한 차이
    if isSlot(element) then unmountSlotTree(element)
    elseif self._mounted then      -- [2026-08-24 `H-12`] 물리 op만 가름
        nativeExtract(self._mountedInst, Dispatch.getOffsetAt(self, index), { element })
    end

    spliceArraysDown(self, index)  -- `bk.indexOfElement`에서도 이 요소·자리가
                                   -- 빠진다(트리 밖이 됨) — 아래 splice 요구 목록
    -- ⭐ [2026-08-26, 8라운드 `H-119`] 명시 호출도 재진입 게이트를 먼저 본다.
    --   건너뛴 몫은 위 spliceArraysDown이 당겨둔 `bk.offsetSetUpTo`로
    --   바깥 `recompute`의 되감기가 복구한다(`dispatch-core-plan.md`).
    if not (getBlocker(self):IsOn() or bk.recomputeBlocker:IsOn()) then
        recompute(self, bk)         -- [`H-119`] 게이트 통과 시에만
    end
end

-- [신설, 2026-08-21] 밀려나거나 지워지는 요소의 처분 — `Owned`가 정한다
-- (위 "`Owned` 옵션" 절). detach 중이던 요소는 이미 `_elements`에 없으므로
-- spliceArraysDown/recompute가 필요 없어 경로가 갈린다.
-- [시그니처 정리, 2026-08-21] index 우선 — detach 중이던 요소만 index가 없다
-- (트리 밖이라 자리 자체가 없음), 그 경우 `index = nil`로 부른다.
function releaseElement(self, index, element, wasDetached)
    if wasDetached then
        if self._owned ~= false then
            if isSlot(element) then destroySlotTree(element) else nativeDispose(element) end
        end
        return   -- 이미 물리 트리 밖 + 부기 밖이라 더 할 일 없음
    end
    if self._owned ~= false then rawRemove(self, index)   -- 파괴
    else rawUnmount(self, index) end                      -- 언마운트만(사용자 것)
end

-- **⭐ [신설, 2026-08-24 6라운드 손 트레이싱 `H-29`] `collectLeaves(slot)` —
-- 중첩 Slot이 차지하는 물리 리프를 순서대로 평탄화해 모으는 헬퍼.**
-- `native*` 계층이 *"빠지는 요소는 반드시 `elements` 배열로 넘긴다"*를 계약으로
-- 못박았는데(위 그 절), `_elements[index]`가 Slot이면 넘길 배열이 없다.
-- `rawRemove`/`rawUnmount`는 Slot 요소를 `destroySlotTree`/`unmountSlotTree`로
-- 빠져나가 이 문제를 피했지만 `Move`/`Swap`/`Extract`/`Splice`엔 그 우회가 없다.
-- **사용자 확정(2026-08-24): 헬퍼를 새로 둔다**(대안이던 "중첩 Slot은
-- unmount+attach 경로로" 는 `Move`/`Swap`을 따로 둔 이유를 되돌린다 — `H-34`).
function collectLeaves(slot, out)
    out = out or {}
    for _, element in ipairs(slot._elements) do
        if isSlot(element) then collectLeaves(element, out)
        else table.insert(out, element) end
    end
    return out
end

-- **⭐ [2026-08-24 `H-29`] 아직 의사코드가 없는 `raw*` — 작성 시 지킬 것.**
-- `rawMove`/`rawSwap`/`rawExtract`/`rawSplice`/`rawClear`는 이름만 있었다
-- (`rawMove`는 `reconcile`이 **직접 부르는** 함수인데도). 새 결정이 필요한 건
-- 위 `collectLeaves` 하나였고, 나머지는 아래 규약대로 쓰면 된다:
--   1. **함께 치환되는 것** — `_elements`, `bk.indexOfElement`(`H-1`,
--      **[2026-08-27 Q3]** 옛 `slot._elemIndex` — `reindexFrom`이 갱신),
--      `bk.lengthList`, `bk.sourceList`, `bk.observers`. 넷 다 **position
--      인덱스**이고 `sourceList[i]`는 그 중첩 Slot 자신의 `slot.Offset`이라
--      position이 아니라 **요소에 귀속**된다 → 전부 같은 순열로 움직인다.
--      (**[2026-08-27]** 옛 `bk.tokens`/`bk.indexOfToken`은 폐기 — 이동 구간을
--      규약 4가 `setLength`로 다시 태우므로 요소 키 맵은 거기서 다시 쓰인다.)
--   2. **`bk.N`은 안 변한다** — 자리 수가 그대로이므로(`spliceArraysUp`/`Down`과
--      갈리는 지점).
--      ⚠️ [2026-08-26 범위 정정, 5·6차 `/code-review high`] **`rawSplice`·
--        `rawClear`·`rawExtract`의 제거 형태는 예외다** — 자리 수를 바꾼다.
--        (`rawExtract`는 조건부다: `newElement`를 **지정하면 교체**라 자리 수가
--         그대로지만, **생략하면 제거**라 뒤가 당겨지며 준다 — 위 CRUD 표의
--         `Extract` 행. 6차 리뷰가 5차의 예외 목록에서 이걸 빠뜨린 걸 잡았다.) 이 규약을 그대로
--        적용해 `rawClear`를 짜면 `_elements`는 비는데 `bk.N`이 옛 개수로
--        남아, 다음 `recompute`가 `i <= bk.N`으로 끝을 넘어가 `sourceList[i]`가
--        `nil` → **부기가 멀쩡한데 "부기가 깨졌음" error로 죽는다.** 그것들은
--        `spliceArraysUp`/`Down`과 같은 취급(자리 수 갱신 + 무효화)을 받아야
--        한다. 아래 3·4번은 다섯 함수 전부에 적용된다.
--   3. **캐시는 당긴다** — 바뀐 최소 위치의 **하나 앞**으로
--      `bk.offsetCacheValidUpTo`와 `bk.offsetSetUpTo`를 **둘 다** `math.min`
--      (`H-3`; 두 필드 분리는 [2026-08-26] `dispatch-core-plan.md`의
--      "두 필드" 절). ⭐ [2026-08-26 정정, `/code-review high`] 여기 한때
--      "바뀐 최소 위치로"라고만 적혀 있었는데, 그건 `H-113`이 거짓임을 증명한
--      바로 그 공식이다 — `rawSwap(i, j)`가 `recompute`의 커서 `i`에서 일어나면
--      `math.min(i, i) = i`라 되감기 조건 `offsetSetUpTo < i`가 거짓이고, 그
--      자리로 옮겨온 **다른 요소의 offset Source가 이번 패스에서 `Set`을 못
--      받는다**(우리가 Set한 건 옮겨나간 옛 요소의 Source다). 루프 꼬리의
--      `bk.offsetSetUpTo = bk.N`이 "Set을 다 마쳤다"로 마감하므로 다음 계기까지 그
--      요소만 옆으로 어긋난 채 남는다. `spliceArrays*`와 같은 처방
--      (`math.min(…, minPos - 1)`(두 필드 다))을 쓴다.
--   4. **`recompute`는 `setLength`에 일임**(`H-19`) — 순서만 바뀌어 길이 합이
--      그대로여도 offset은 전부 바뀌므로, 자리 이동 후 해당 위치들의
--      `setLength`를 다시 태워 게이트를 통과시킨다.
--   5. **물리 op에 넘길 `elements`는 `collectLeaves`로 만든다**(중첩 Slot 요소).
--   6. **물리 op은 `_mounted`로 가른다**(`H-12`) — 부기는 항상.
-- 참고: 이 문서에 남아 있던 *"`raw*` 내부 호출 규약은 공개 API와 다를 수
-- 있음(구현 세부, M6에서 확정)"*은 5라운드의 index 통일로 이미 닫힌
-- **stale**이라 근거로 인용하지 말 것.

-- **raw 3형제 — 갈리는 축이 둘(파괴하는가 / 소유권을 놓는가)**:
--   rawRemove : 소유권 반납 + **파괴**
--   rawUnmount: 소유권 반납 + 파괴 안 함   ← 요소를 살려서 내보내는 경로
--   rawDetach : **소유권 유지** + 파괴 안 함 ← 내가 계속 들고 있는 경로
-- 셋 다 **자리를 없애는** 연산이라 spliceArraysDown이 따라붙는다. 자리를
-- 유지한 채 내용만 바꾸는 rawReplace(아래)는 그래서 별개 축이다.

-- [신설, 2026-08-21 5라운드 `C-1`] rawAdd — 이 문서에서 가장 많이 참조되는데
-- 정의가 없어서 `_mounted` 분기가 다른 함수 주석에만 흩어져 있었다. 새 결정은
-- 없고 기존 서술을 모은 것(사용자 확인, 5라운드).
-- **⭐ [전면 재작성, 2026-08-24 6라운드 손 트레이싱 `H-2`/`H-5`/`H-12`/`H-19`]**
-- 옛 버전은 `if not self._mounted then return index end`로 **부기까지 통째로**
-- 건너뛰었다. 그러면 `:List`의 최초 population 동안 `bk.lengthList`가 비어 있어
-- `Dispatch.getOffsetAt(self, 2)`가 `nil`을 읽는다 — `updateFn`에 넘길 `index`를
-- offset에서 구하려면 그 자리에서 이미 부기가 서 있어야 한다.
-- **이제 `_mounted`는 물리 인스턴스 유무만 가른다**(위 "`isMounted` 이중 추적
-- 분리" 절의 3상태): **부기는 실체화 시점부터 항상 하고, `native*`만 가린다.**
-- **⚠️ [2026-08-24 재정정, `/code-review high` 지적] 위 재작성이 가드를 하나
-- 통째로 지웠었다.** 상태는 **셋**인데(미실체화/실체화/마운트) `_mounted` 경계만
-- 코드에 남기고 **첫 경계를 안 뒀다** — 그러면 `Slot { frameA }` 생성자가
-- (그 자체가 `:Add`를 부른다, 위 그 절) `materializeSlotTree`보다 훨씬 먼저
-- 부기를 시도한다. (**[2026-08-27 근거 정정, 9라운드 Q2]** 여기 한때 *"`getOffsetAt`
-- → `ownerKey.Offset:Get()`에서 `slot.Offset`이 아직 nil이라 즉시 죽는다"*가
-- 근거였는데, `Offset`이 생성자에서 나면서 **그 근거는 거짓**이 됐다 — 남는
-- 근거는 아래 하나다.) 중첩이면 치명적이다: `attachSlot(element, nil, …)` →
-- `bindLifetime(nil, …)`은 이 문서가 스스로 치명적이라 적어둔 그것이다.
-- **`_physicalTarget`이 곧 "실체화됐는가"의 판정이다.**
function rawAdd(self, element, index, fromDetached)
    claimOwner(element, self, fromDetached)   -- 이미 누가 갖고 있으면 error(detach 재마운트만 예외)
    index = index or (#self._elements + 1)
    table.insert(self._elements, index, element)
    reindexFrom(self, index)                  -- `bk.indexOfElement` 갱신 — **상태와 무관하게 항상**
                                              -- ([2026-08-27 Q3] 그래서 미실체화 Slot도 `:Add`만 하면
                                              --  `bk`가 생긴다 — `getBookkeeping`은 lazy라 안전)

    if self._physicalTarget == nil then
        -- **아직 실체화 전: 부기의 앵커도 베이스 offset도 없다.** `_elements`
        -- (와 그 역방향 맵)에만 넣고 끝낸다 — 나중에 `materializeSlotTree`가
        -- 통째로 처리한다. 여기서 부기를 시도하면 위 배너의 크래시가 난다.
        return index
    end

    local bk = getBookkeeping(self)
    spliceArraysUp(self, index)               -- 부기 배열들을 한 칸 밀고
                                              -- bk.N 증가 + `lengthList[index]` 자리표시자(`H-5`)

    if isSlot(element) then
        -- 자식이 자기 부기+물리를 다 한다. 아직 마운트 전이면 **실체화까지만** —
        -- `attachSlot`이 `materializeSlotTree`/`mountSlotTree`로 갈린다(아래 그 절).
        attachSlot(element, self._physicalTarget, self, index, self._mounted)
    else
        -- [순서 재정렬, 2026-08-21] **자기 자리를 정하는 것 먼저 / 뒤를 미는 것 나중.**
        -- 옛 "부기 전부 먼저"는 base가 물리적으로 자리를 비워둘 수 있다는 전제였는데
        -- 그런 수단이 없다 — 미는 주체는 `nativeInsert` 자신이다(아래 `dispatch-core-plan.md`
        -- "물리와 부기의 순서" 절).
        Dispatch.setOffsetSource(self, index, None)   -- 내 자리 offset은 1..index-1의 합이라
                                                      -- 내 삽입으로 안 변한다 → 먼저 해도 안전
        if self._mounted then                         -- [`H-12`] 물리 op만 가른다
            nativeInsert(self._mountedInst, Dispatch.getOffsetAt(self, index), { element })
        end
        Dispatch.setLength(self, index, 1, self._physicalTarget, element)   -- **뒤를 미는 것**은 그 다음 (5번째 = 요소, 9라운드 Q3)
        -- [`H-19`] 명시 `recompute(self, bk)`를 **삭제했다** — `setLength`가 상수
        -- 길이에도 마지막에 `gatedRecompute()`를 부르므로 두 번 돌고 있었고,
        -- "recompute를 누가 부르는가"의 소스가 두 곳이면 `H-3`의 캐시 무효화를
        -- 어디 둘지가 애매해진다. **자리의 길이가 바뀌면 `setLength`가 책임진다.**
    end
    return index
end

-- [신설, 2026-08-21 5라운드 `B-5`] rawReplace — 자리를 유지한 채 내용만 교체.
-- `destroyOld`는 호출부가 정한다(공개 `Replace`는 항상 true, `:List`는 `_owned`).
-- [2026-08-21, **정정 2026-08-24 `H-1`**] `indexOfRaw(self, element)` —
-- **`getBookkeeping(self).indexOfElement[element]` 한 번 조회**(**[2026-08-27 Q3]**
-- 옛 `self._elemIndex`). 공개 `Slot:IndexOf`와 다른 점은
-- 그대로다: 그쪽은 사용자가 넘긴 **언래핑된 값**으로 찾아주는 API고(위
-- "래핑/언래핑" 절), 이쪽은 물리 요소를 그대로 찾는다.
-- **옛 서술("O(n) 선형 탐색하는 예외 경로용 폴백, reconcile은 `keyIndex`가
-- 인덱스를 들고 있어 이걸 안 부른다")은 폐기됐다** — `keyIndex`는 사이클
-- 도중 stale이라 그 용도로 쓸 수 없었고(`H-1`), 이제 이게 **기본 경로**다.
-- `settle`이 `keyIndex[key]` 대신 이걸 부른다.
function rawReplace(self, index, newElement, destroyOld)
    local oldElement = self._elements[index]
    claimOwner(newElement, self)              -- 새 요소 먼저 클레임(실패하면 아무것도 안 바뀜)
    releaseOwner(oldElement, self)
    self._elements[index] = newElement         -- **시프트 없음** — 자리 수가 안 변한다
    -- [2026-08-24 `H-1`] 역방향 맵도 같이 — 자리 수는 안 변해도 **주인이 바뀐다**
    -- ([2026-08-27 Q3] 맵은 `bk.indexOfElement`. 아래 `setLength(…, newElement)`가
    --  새 주인을 등록하지만, 미실체화 분기는 `setLength`를 안 부르므로 여기서 직접)
    local bk0 = getBookkeeping(self)
    bk0.indexOfElement[oldElement] = nil
    bk0.indexOfElement[newElement] = index

    if not self._mounted then
        if destroyOld then                     -- 물리 트리 밖이라 native* 교체가 필요 없다
            if isSlot(oldElement) then destroySlotTree(oldElement) else nativeDispose(oldElement) end
        end
        -- [2026-08-24 `H-12`, 같은 날 `/code-review high`로 가드 보강]
        -- 부기는 **실체화된 뒤라야** 한다 — `rawAdd`와 같은 이유(앵커/베이스가
        -- 아직 없으면 `setLength`가 `getOffsetAt`에서 죽는다).
        if self._physicalTarget ~= nil then
            if isSlot(newElement) then attachSlot(newElement, self._physicalTarget, self, index, false)
            else
                Dispatch.setOffsetSource(self, index, None)
                Dispatch.setLength(self, index, 1, self._physicalTarget, newElement)   -- [Q3] 5번째 = 요소
            end
        end
        return
    end

    local bk = getBookkeeping(self)
    local offset = Dispatch.getOffsetAt(self, index)

    -- [2026-08-21] **원자적 교체** — 빼기와 넣기를 한 호출로 합친다(리플로우 1회,
    -- 그 사이 인덱스가 어긋난 창이 없음). 파괴 여부는 op **이름**이 가른다.
    if isSlot(oldElement) or isSlot(newElement) then
        -- 어느 한쪽이 Slot이면 구간 길이가 1이 아니라 각자의 경로로 간다
        if isSlot(oldElement) then
            if destroyOld then destroySlotTree(oldElement) else unmountSlotTree(oldElement) end
        else
            local op = if destroyOld then nativeRemove else nativeExtract
            op(self._mountedInst, offset, { oldElement })
        end
        if isSlot(newElement) then
            attachSlot(newElement, self._physicalTarget, self, index, self._mounted)
            return
        end
        Dispatch.setOffsetSource(self, index, None)
        nativeInsert(self._mountedInst, offset, { newElement })
    else
        local op = if destroyOld then nativeRemove else nativeExtract
        op(self._mountedInst, offset, { oldElement }, { newElement })   -- 한 번에
    end
    Dispatch.setLength(self, index, 1, self._physicalTarget, newElement)   -- [Q3] 5번째 = 요소
    -- [`H-19`] 명시 `recompute(self, bk)` 삭제 — `setLength`에 일임(위 `rawAdd` 참고)
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
    -- [2026-08-21] 파괴 경로는 **한 번에** — 빼기와 파괴를 백엔드가 융합할 수 있다
    -- (Roblox는 Parent=nil 없이 그 자리에서 Destroy가 더 싸다).
    if isSlot(element) then destroySlotTree(element)
    elseif self._mounted then       -- [2026-08-24 `H-12`] 물리 op만 가른다
        nativeRemove(self._mountedInst, Dispatch.getOffsetAt(self, index), { element })
    else
        -- **⚠️ [2026-08-24 재정정, `/code-review high` 지적] `else`가 비어 있었다.**
        -- `nativeRemove`가 곧 **파괴**였는데(위 주석: "빼기와 파괴를 백엔드가
        -- 융합") `_mounted`로 가리기만 하니, 마운트 전 창에서 요소가
        -- `_elements`에서 빠지고 **아무도 안 죽인다**. quad Instance는 gcconn
        -- 때문에 `Destroy` 말고는 회수 경로가 없으므로(`base/fallback-plan.md`의
        -- ⚠️ 절) 지연 GC가 아니라 **영구 누수**다. `rawReplace`의 마운트 전
        -- 분기가 이미 `nativeDispose`로 올바르게 처리하고 있었다.
        nativeDispose(element)      -- 트리 밖이라 offset이 필요 없다
    end

    spliceArraysDown(self, index)   -- _elements/lengthList/sourceList/observers/bk.indexOfElement/bk.N — 아래 참고
    -- ⭐ [2026-08-26, 8라운드 `H-119`] 명시 호출도 재진입 게이트를 먼저 본다.
    --   건너뛴 몫은 위 spliceArraysDown이 당겨둔 `bk.offsetSetUpTo`로
    --   바깥 `recompute`의 되감기가 복구한다(`dispatch-core-plan.md`).
    if not (getBlocker(self):IsOn() or bk.recomputeBlocker:IsOn()) then
        recompute(self, bk)         -- outer 자기 자신 레벨에서 딱 1회만
    end
end
```

**⭐ [2026-08-24 6라운드 손 트레이싱 `H-1`/`H-5`/`H-3`] `spliceArraysUp`/
`spliceArraysDown`이 해야 하는 일 — 아래 목록이 소스다**(**[2026-08-27, 9라운드
`H-132`]** 한때 "셋 늘었다"고 세어뒀는데 그 뒤 항목이 늘고 줄어 개수가 어긋났다 —
세지 않는다).

- **`bk.indexOfElement`는 별도 헬퍼 `reindexFrom(self, from)`이 맡는다**(`H-1`,
  **[2026-08-24 분리, 2026-08-27 맵 이동]**). 이 맵은 `_elements`의 역방향이라
  **실체화 여부와 무관하게 항상** 정확해야 한다. `reindexFrom`은 `from`부터
  끝까지 `bk.indexOfElement[self._elements[i]] = i`를 다시 쓰고, 제거 경로에선
  빠지는 요소를 맵에서 **뺀 뒤** 부른다. `_elements`를 시프트하는 자리는
  **전부** 이걸 부른다(`rawAdd`의 미실체화 얼리리턴 포함).
  `spliceArraysUp`/`Down`은 자기 몫으로 이걸 같이 부르되, 하는 일은 아래 부기
  항목들이다. (**[2026-08-27 Q3]** 분리의 옛 근거 *"`spliceArrays*`는 `bk`를
  만지므로 실체화된 뒤에만 부를 수 있다"*는 맵이 `bk`로 가며 **소멸**했다 —
  `getBookkeeping`은 lazy라 언제 불러도 된다. 분리는 "맵은 시프트마다, 부기
  배열은 실체화 뒤"라는 **호출 시점 차이** 때문에 그대로 둔다. 따름정리:
  미실체화 Slot도 `:Add`만 하면 `bk`가 생긴다.)
- **`spliceArraysUp`은 `lengthList[index]`에 자리표시자(`0`)를 채운다**(`H-5`).
  옛 순서는 `spliceArraysUp`이 `bk.N`을 먼저 올리고 `lengthList[index]`는
  `setLength`가 마지막에 채워서, **그 사이에 `nativeInsert`가 끼어 있었다.**
  Roblox의 `Parent` 대입은 `ChildAdded`/`DescendantAdded`를 **동기 발화**시키므로
  그 핸들러가 같은 owner에 손대면 `recompute`가 `lengthList[index] == nil`을
  읽어 `sum += nil`로 터진다(`sourceList[index]`는 `None`으로 채워져 있어
  그쪽 error 가드엔 안 걸린다). **동기 재진입이라 "체인 도중 yield 금지"
  불변식으로는 안 덮인다.** `sourceList`가 `None`으로 채워지는 것과 대칭을
  맞춰 창 자체를 없앤다.
- **⭐⭐ [2026-08-27 신설, 9라운드 `H-126`/Q3] 비워지는 자리는 세 배열 전부
  처리한다.** `spliceArraysUp`은 `index` 자리에 `lengthList = 0` / `sourceList =
  None` / **`observers = nil`**, `spliceArraysDown`은 당긴 뒤 꼬리(`N`) 세 자리를
  `nil`로. 자리표시자 두 줄만 적혀 있고 `observers`는 말이 없어서, `t[i+1] =
  t[i]` 복사 루프로 짜면 `observers[index]`에 옛 값이 남아 `index`와 `index+1`이
  **같은 Observer**를 가리켰다 — 이어지는 `setLength(self, index, …)`가
  `oldObserver`로 그걸 `unbindLifetime`해 **밀려난 요소의 길이 관측자를
  죽인다**(그 요소가 커져도 뒤 형제가 영영 안 밀린다 — 9라운드 실측
  `vacate=false`). `Down`의 꼬리 잔여는 `bk.N` 밖이라 당장은 안 보이지만 다음
  `Up`이 그 자리를 범위 안으로 밀어 올리면 자리표시자 대신 유령 값이 들어온다.
- **캐시를 앞으로 당긴다**(`H-3`) —
  **두 필드 다** `math.min(…, index - 1)`:
  `bk.offsetCacheValidUpTo`(캐시 유효 상한)와 `bk.offsetSetUpTo`(offset
  `Source`에 `:Set`을 마친 지점). **[2026-08-26]** 옛 단일 필드
  `invalidAfter`가 두 뜻을 겸하던 게 되감기 신호가 조용히 지워지는 원인이라
  갈라졌다 — `base/dispatch-core-plan.md`의 "두 필드" 절이 소스.
  `base/dispatch-core-plan.md`의 무효화 표가 규정한 규칙 중 하나이고
  (**[2026-08-26]** "세 규칙"이라 세어뒀는데 `/code-review high`가 그 표에
  `rawMove`/`rawSwap`류 행이 빠진 걸 잡아 넷이 됐다 — 개수는 그 표가 소스),
  지금까지 산문으로만 있고 코드 경로가 없었다.
  **⭐⭐ [2026-08-26 재정정, 8라운드 `H-113`] `-1`이 다시 필요하다.**
  여기 한때 `index - 1`이었다가 2026-08-25에 *"되감기 재개 지점이
  `invalidAfter + 1`에서 그 필드 자신으로 고쳐지며 그 `-1`이
  불필요해졌다"*는 이유로 `index`가 됐는데, **그 논증이 `index == i`(= 지금
  `recompute`가 처리 중인 커서 자리)에서 거짓이다** — 루프가 매 반복
  `bk.offsetSetUpTo = i`를 쓰므로 `math.min(i, i) = i`가 되어 **"아무 일도
  없던 것"과 값이 같아지고**, 되감기 조건 `offsetSetUpTo < i`가 거짓이라
  재방문이 없다. 그러면 splice로 그 자리에 밀려 들어온 요소의 offset이
  이번 패스에서 `Set`을 못 받고 조용히 낡는다. `-1`로 두면 `i-1`부터
  되감아 `i`를 재방문하고(그 자리 offset 쓰기는 `~=` 가드로 no-op),
  **재개 지점은 `offsetSetUpTo` 그대로**라 2026-08-25의 그 변경 자체는
  유지된다 — 둘은 독립이다. 근거 전량은 `base/dispatch-core-plan.md`의
  "되감기 신호는 `bk.invalidAfter` 하나로 통일한다" 절(**[2026-08-26]** 그 절
  제목의 확정은 같은 날 역전됐다 — 두 필드로 갈라졌다).
  - **⭐ 이게 `recompute` 되감기의 신호이기도 하다** — recompute 도중
    splice가 나면 그 값이 낮아지고, 진행 중인 루프가 그 지점 다음부터
    되감는다(`base/dispatch-core-plan.md`의 `recompute` 절). 그래서
    `{a,a,a, b,b, c,c}`에서 앞의 `a,a`가 사라졌는데 커서가 이미 `c`에
    있어도 복구된다.
- **⛔ [2026-08-27 폐기, 9라운드 Q3/`H-141`] 여기 한때 *"`bk.tokens`와
  `bk.indexOfToken`도 같이 밀어야 한다"*(7라운드 `H-102`, 2026-08-25)는 항목이
  있었다.** `setLength`의 `gatedRecompute`가 인덱스 대신 캡처할 신원으로
  `token = {}`을 두고, splice가 (1) `bk.tokens`를 같이 당기고 (2) 밀린 자리
  전부의 `bk.indexOfToken[token]`을 갱신·사라진 항목을 지우라는 요구였다.
  **토큰은 사용자가 정한 적 없는 신원**이고(`/code-review`가 "`len`은 자리마다
  유일하지 않다"를 잡으며 요소 키로 되돌아가는 대신 발명), 같은 뜻의 맵을 두
  층에 두는 원인이었다. 이제 클로저는 **요소를 캡처**하고 `bk.indexOfElement`를
  조회하므로(위 첫 항목) 이 요구는 통째로 사라진다 — `H-102`의 결론(*"클로저에
  박힌 인덱스가 낡는다 → 캡처 말고 조회"*)은 그대로이고, 조회 대상만 원래
  사용자 지시(요소 → 인덱스)로 돌아왔다.

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
  `lengthList[i]`가 아직 없으므로, `Dispatch.drive`/`materializeSlotTree`의
  배치 등록도, Slot의 런타임 단건
  `rawAdd`도 이 하나의 규칙으로 통일), `spliceArraysDown`이 위치 하나를
  물리적으로 지울 때(`rawRemove`/`rawUnmount`) 그만큼 줄어든다. **`Dispatch.drive`의
  `inst`에서는 이 규칙이 사실상 눈에 안 띈다** — 최상위 배열 리터럴은
  구조적으로 늘거나 줄지 않으므로(전체 재-dispatch만 있음) `bk.N`이
  등록이 끝난 뒤로는 그냥 고정값처럼 보일 뿐, 별도 케이스가 아니라 같은
  규칙의 특수한 안정 상태다.
- **왜 이게 `RC-1`의 크래시를 다시 불러오지 않는가**: `Dispatch.drive`/
  `materializeSlotTree`의 배치 등록 중엔 `recompute`가 각 owner의 Blocker
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
-- [정정, 2026-08-21 5라운드 `C-3`] 래핑을 공개 `Add` 안에 인라인으로 두지 않고
-- **공용 헬퍼 하나**로 뺀다 — `Replace`/`Extract(index, new)`/`Splice`/`:List`의
-- reconcile까지 전부 같은 래핑이 필요하기 때문(아래 절).
-- **⭐ [전면 정정, 2026-08-24 6라운드 손 트레이싱 `H-40`]** 옛 의사코드는 이
-- 한 줄이 전부였고, **같은 문서가 확정해둔 가드를 하나도 하지 않았다.**
-- 산문이 이미 정확한 알고리즘을 서술해뒀으므로 옮기기만 한 것이다.
function Slot:Add(element, index)
    -- (0) [2026-08-27, 9라운드 Q2] 파괴된 Slot — 모든 공개 CRUD·`:List`·마운트
    --     진입점이 같은 가드를 둔다(위 "파괴된 Slot은 재사용 불가" 절).
    if self._destroyed then error("Slot: destroyed Slot cannot be reused", 2) end
    -- (1) `:List`가 설치돼 있으면 수동 CRUD 금지 (위 "CRUD API 확정" 절)
    assert(not self._listed, "Slot: :List가 설치된 Slot엔 수동 CRUD를 쓸 수 없음")
    -- (2) index 범위 검증 — **clamp 안 함**, 범위 밖이면 error
    if index ~= nil and (index < 1 or index > #self._elements + 1) then
        error("Slot:Add — index가 범위 밖(1.." .. (#self._elements + 1) .. "): " .. tostring(index))
    end
    -- (3) 요소 타입 검증은 `wrapElement`가 한다(위 그 함수 — `isSlot`/`isState`/`isInst`)
    local wrapped = wrapElement(element)
    -- (4) 역방향 가드용 플래그 — 이게 없으면 `Slot():Add(x); slot:List(...)`가
    --     조용히 통과한다(`H-37`이 지적한 대칭의 반대쪽)
    self._crudUsed = true
    return rawAdd(self, wrapped, index)
end
```

**⭐ [2026-08-24 `H-30`/`H-31`] 여러 요소를 받는 CRUD는 검증을 선행 패스로
분리한다.** `Splice`의 확정 문장 *"검증은 실제 mutate 전에 전부 먼저 통과해야
함(일부만 적용된 채 중간에 에러나는 반쪽 상태 방지)"*을 지키는 코드 경로가
없었다 — "이미 마운트됨" 판정을 실제로 하는 곳은 `rawAdd` 안의 `claimOwner`
하나뿐이고 그건 **요소를 삽입하기 직전에 요소마다** 돈다. 그래서
`slot:Splice(1, 0, a, b, c)`에서 `c`만 남의 소유면 `a`/`b`는 이미 들어간
**반쪽 상태**가 된다. 확정:

- `Splice`/`Replace`/`Extract(index, new)`는 `raw*`를 부르기 **전에**
  `newElements` 전량에 대해 (a) `wrapElement`(타입 검증 포함)와
  (b) `elementOwner` 조회(이미 누가 갖고 있으면 error)를 **먼저 다 돌린다.**
- 통과한 래핑 결과를 그대로 `raw*`에 넘긴다(두 번 래핑하지 않는다).
- 같은 처방이 `:List`의 중복 키 검사에도 적용됐다(`reconcile`의 선행 패스,
  위 그 의사코드).

### ⭐ 래핑/언래핑은 Slot 전체에 걸린 연산이다 (2026-08-21 구현 전 QA 5라운드 `C-3`)

**사용자 지적**: *"replace, extract 등에서도 래핑해야하므로 래핑이 하나의
함수로 나와야한다. 그리고, 또, IndexOf 와 Get 등은 래핑 전 객체를 주어야할텐데
… 입력을 isState 인지 확인하고 래핑하거나 안 하거나 하는 래퍼와 반대로 get 등을
위해 언랩하는 도구가 필요하다."* 그대로 확정한다.

```lua
-- Slot 내부 비공개 헬퍼 둘. 이 둘만이 래핑을 아는 자리다.
local function wrapElement(v)
    -- [2026-08-24 6라운드 손 트레이싱 `H-40`] **요소 타입 검증의 단일 관문**이
    -- 여기다. 공개 CRUD와 `:List`의 `settle`이 둘 다 이 함수를 지나므로,
    -- State가 나중에 이상한 값으로 바뀌는 경우도 같은 자리에서 걸린다.
    -- 판정은 화이트리스트다(위 "요소 타입 제약" 절): `isSlot` → `isState` →
    -- `isInst`. 셋 중 어디에도 안 걸리면 error.
    if isSlot(v) then return v end
    if not isState(v) then
        -- 진단을 위해 핸들러 계층 값은 따로 잡는다(왜 안 되는지 근거가 다르다)
        if isRef(v) or isPreRef(v) or isPostRef(v) or isObserver(v) or isEffect(v) or isModifier(v) then
            error("Slot: 핸들러 계층 값(Ref/PreRef/PostRef/Observer/Effect/Modifier)은 요소가 될 수 없음")
        end
        if v == nil or v == None then
            error("Slot: nil/None은 요소가 될 수 없음 — 실제로 마운트 가능한 값만")
        end
        if not isInst(v) then     -- 백엔드 주입 술어(위 `native*` 절)
            error("Slot: 이 백엔드가 마운트할 수 없는 값")
        end
        return v
    end
    local sub = Slot()
    sub:Single(v, nil, { Owned = false })   -- updateFn은 identity 기본값.
                               -- **`Owned = false`를 여기서 실제로 넘긴다** — 안쪽
                               -- 요소는 사용자 것이라 래퍼가 죽어도 파괴하면 안 됨.
    sub._wrapped = v           -- ← 역참조. 언래핑이 O(1)이 되는 근거
    return sub
end

local function unwrapElement(el)
    if el == nil then return nil end
    -- [정정, 2026-08-24 6라운드 손 트레이싱 `H-21`] **`isSlot` 가드가 필수다.**
    -- 옛 코드는 `el._wrapped or el` 한 줄이었는데, `el`은 **물리 요소**이고
    -- quad-roblox에서 그건 사실상 Roblox `Instance`다 — **없는 멤버를 인덱싱하면
    -- `nil`이 아니라 에러**(`_wrapped is not a valid member of Frame`)라
    -- `:List`가 raw Instance를 다루는 **모든 두 번째 사이클**이 여기서 죽었다.
    -- base 일반성 관점에서도 틀렸다: `T`가 number/boolean인 백엔드면 Luau에서도
    -- `attempt to index number`다. 래퍼는 **항상 Slot**이고 `isSlot`은 `Brand`의
    -- weak-key 조회라(`base/brand-plan.md`) Instance/userdata/원시값 전부에 안전하다.
    if isSlot(el) then return el._wrapped or el end
    return el
end
```

- **⭐ [확정, 2026-08-21] 래핑은 `raw*` **바깥**에서 한다 — `raw*`는 언제나
  이미 래핑된 물리 요소만 다룬다.** 래핑 지점은 정확히 둘: 공개 표면
  (`Slot:Add`/`Replace`/`Extract(index, new)`/`Splice`)과 `:List`의 `settle`.
  (**사용자 확인**: *"raw들은 모두 래핑된거 그대로 넣고 빼도록 할까?"* — 그렇다.)
  - **왜 `rawAdd` 안이 아닌가**: `raw*`가 래핑까지 하면 "이 함수가 받은 게
    사용자 값인가 물리 요소인가"가 호출부마다 달라져, 지금 막 index로 통일한
    인자 규약이 다시 흐려진다. 래핑을 바깥에 두면 `raw*`의 세계는 **물리
    요소 하나로 균일**하다.
  - 그래서 `mounted[key]`도, `_elements`도, `_detached`도 전부 **물리 요소**를
    담는다. 언래핑은 **사용자에게 나갈 때만** 일어난다.
- **`_elements`에는 항상 물리 요소(래퍼일 수 있음)가 들어간다** — 부기/물리
  조작(`rawAdd`/`rawReplace`/`rawMove`/`rawRemove`/`attachSlot`)은 전부 이쪽을
  본다.
- **사용자에게 나가는 값은 전부 `unwrapElement`를 거친다** — `Get`/`IndexOf`/
  `Extract`/`ExtractAll`/`Splice`의 반환값, 그리고 `:List`의 `updateFn`이 받는
  `prev`. 사용자는 자기가 넣은 State를 그대로 돌려받지, quad가 만든 래퍼 Slot을
  보지 않는다.
- **`IndexOf(element)`는 언래핑 기준으로 비교**한다 — 사용자가 넣은 State를
  그대로 넘겨도 그 자리를 찾아준다(비교가 O(n)인 건 원래 계약 그대로).
- **⭐ 이 한 쌍이 있으면 "반환값 맵"과 "물리 요소 맵"을 따로 둘 필요가 없다.**
  `:List`의 `mounted[key]`는 **물리 요소 하나만** 들고, 사용자 관점의 값이
  필요할 때(=`prev` 전달, 멱등 비교) `unwrapElement`를 부르면 된다 — 사용자가
  예상한 그대로다(*"이 래핑 언래핑이 구현되면 자연스럽게 wrappers[key] |
  mounted[key] 분리가 필요하지 않아질 수도 있긴하다"*).
- **래퍼 Slot의 소유 관계**: 래퍼는 quad가 만든 것이라 **부모가 파괴할 수 있고**,
  래퍼 안의 요소는 사용자 것이라 `Owned = false`로 설치된다 — `destroySlotTree(래퍼)`가
  `_owned == false`를 보고 안쪽은 언마운트만 하고 빠진다. 두 층이 정확히 이
  구분으로 갈린다.
- **`Extract`가 돌려주는 것도 언래핑된 값**이고, 그 시점에 래퍼는 할 일이
  없어져 그냥 버려진다(언마운트로 자기 구독이 풀리므로 GC-native).

**`:Single`의 `updateFn`을 선택 인자로 완화 — 기본값은 identity.** 이
sugar가 성립하려면 `:Single(state)`(updateFn 생략)이 유효해야 함 —
`Slot:Single(state, updateFn?, opts?)`, 생략 시 `function(item) return item end`
(**[2026-08-26 표기 정정, 8라운드 `H-123`]** 3번째 `opts`(= `Owned`)는 `H-22`
확정 의사코드가 받아 `:List`로 그대로 전달한다 — 이 줄과 절 제목이 2-인자로
남아 있었다).

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

**⭐ [2026-08-21 5라운드 신설] 단, 아직 트리에 붙어 있는 동안 조상이 죽으면
그 요소도 같이 죽는다 — `Owned = false`여도 마찬가지다.** 사용자 질문에서
나온 확인 사항:

```lua
Frame {
    Slot {
        State(Frame),   -- unowned: quad는 이 Frame을 절대 파괴하지 않는다
    },
}
```

여기서 바깥 `Frame`이 `Destroy`되면 **엔진이 서브트리를 재귀적으로 파괴**하므로
안쪽 `State(Frame)`의 값도 같이 죽는다. **이건 의도된 동작이고 quad가 개입할
자리가 아니다**(사용자: *"엔진 자체가 recursive 호출로 전부 죽이는게
일반적이기에 우리가 빼줄 수 있는 요소도 아니고, 같이 죽는게 의도 동작"*).

- **`Owned = false`가 약속하는 건 "quad가 안 죽인다"뿐**이지 "무슨 일이 있어도
  살아남는다"가 아니다. 언마운트(`Parent = nil`)가 조상 파괴보다 **먼저**
  일어난 요소만 살아남는다.
- **그래서 `state<Frame>`에서 값을 빼내 재사용하려면 조상이 살아있는 동안
  꺼내야 한다** — 조상이 이미 죽은 뒤에 `state:Get()`으로 얻은 값은 **이미
  죽은 Instance**다. 그 값에 다시 마운트를 시도하면 `bindLifetime`/`canExecute`
  게이트에 걸린다(바로 아래 "부수 효과" 문단이 서술하는 그 경로).
- 같은 이유로 `_detached`가 들고 있던 요소도 조상이 죽으면 같이 죽는다 —
  detach는 `Parent = nil`이므로 **조상 트리에서 이미 빠져 있어** 이 경우엔
  해당 없음(그쪽 정리는 `_detachCleanup`이 담당).

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
  **[확인 완료, 2026-08-21] Slot-in-Slot에서도 재귀가 성립한다** — 파괴 walk는
  `destroySlotTree`이고 그게 `_elements`를 훑다 `isSlot(element)`면 재귀하며,
  **`_detached`(Detach로 홀드 중인 것)까지 같은 함수가 훑는다**(위 코드).
  `_owned == false`면 파괴 대신 언마운트로 빠지는 것도 그 안에 있다. 즉
  `dispose(slot)` 한 번으로 서브트리 전체 + 홀드분 전체가 정리된다 —
  **남는 예외는 `userdata` 안에 사용자가 직접 넣어둔 것뿐**이고, 그건
  위 "`userdata`의 생명주기 제약" 절대로 사용자 책임이다.
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
-- **⭐ [정정, 2026-08-24 6라운드 손 트레이싱 `H-28`/`H-43`]** 옛 의사코드는
-- 소유권 가드를 **`isSlot` 분기 안에만** 뒀다. 그런데 위 산문은 대상 구분 없이
-- *"아직 어느 트리에 의해 살아있길 요구되고 있으면 파괴를 거부하고 즉시
-- `error`"*라 선언하고, 그 근거인 `elementOwner`는 Slot이든 plain 마운트 가능
-- 값이든 **전부** 커버한다. 그래서 **가장 흔한 대상인 "Slot에 마운트된
-- Instance"가 `else`로 새어 그대로 파괴**됐다 —
-- `local f = Frame{}; slot:Add(f); dispose(f)`가 `f:Destroy()`까지 가고
-- `slot._elements`엔 죽은 Instance가, `elementOwner`엔 클레임이 남아
-- `dispose`가 막으려던 바로 그 UB가 일어난다. **가드를 분기 밖으로 올린다.**
function dispose(value)
    -- (1) 소유권 가드 — 값 종류와 무관하다(`elementOwner` 조회는 타입을 안 봄)
    -- ⚠️ [2026-08-25 정정, `/code-review high`] `GetStrong(value)`(1-인자)는
    --   **항상 `nil`이라 가드가 죽은 코드였다** — `elementOwner`는 위에서
    --   3-인자 `SetWeak(element, OWNER, ...)`로만 쓰이고 강한 맵엔 아무것도
    --   안 들어간다(`Relate`는 항상 3-인자 `SetWeak`/2-인자 `GetWeak`, 409행).
    --   `H-71`로 dedup 기록까지 `SetWeak`이 되며 강/약 짝맞춤이 더 중요해졌다.
    if elementOwner:GetWeak(value, OWNER) ~= nil then
        error("dispose: 이 값은 아직 트리가 살아있길 요구 중임 — 먼저 Remove/Extract 할 것")
    end
    -- (2) [`H-43`] Slot도 Instance도 아닌 값이 백엔드로 그냥 흘러가지 않게
    if isSlot(value) then
        destroySlotTree(value)   -- 재귀 파괴
    elseif isInst(value) then
        nativeDispose(value)     -- 아래 주입 op
    else
        error("dispose: 이 백엔드가 파괴할 수 없는 값")
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

**base/backend 분리 — `nativeDispose`는 주입 op**(`base/dispatch-core-plan.md`
"base가 소유하는 핸들러와 주입되는 엔진 op" 절과 같은 패턴, `addTag`/
`removeTag`/`setAttribute`가 선례): `dispose`가 `isSlot`이 아닌 값을
받으면 base가 시그니처만 소유하는 `nativeDispose(inst: any): ()`로 위임 —
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
- **`state:Apply`는 손대지 않는다** — 시그니처 영향이 없으므로 M2 착수 전
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
2. **`:List`의 `reconcile`** — **[재정정, 2026-08-18 구현 전 QA;
   2026-08-21 `Owned` 도입으로 다시 정정]** 이 항목은 원래 "비파괴가 되는
   건 **값 교체와 `Detach`뿐**"이라고 적혀 있었는데, **값 교체 쪽은
   틀렸다**. 지금 확정은 **`Detach`만 비파괴**이고, 값 교체·`nil`/`None`·
   키 소멸은 전부 **`Owned` 플래그가 결정**한다(기본 `true` = 파괴,
   `false` = 언마운트만). 상세와 이유는 위 "`nil` 리턴은 파괴가 기본" 절의
   표가 소스 — 그 표와 이 항목이 어긋나면 표가 맞다.
   2026-08-13에 이 항목이 "교체/소멸 시 전부 비파괴"로 적혔던 것은
   `:List`에는 안 맞는 일반화였음.

**여전히 파괴인 것**: 명시적 CRUD `Slot:Remove(index)`/`Slot:Clear()`
(CRUD 표가 "제거 **+ 파괴**"로 이미 정의), `dispose`, 그리고 위 2번의
`:List` 경로 전부(`Owned = true`일 때 — 값 교체 포함). 즉 일반 규칙은
**"자동 경로는 언마운트, 명시적으로 지우라고 한 것만 파괴"**이되,
**`:List`가 소유하는 요소는 그 규칙의 예외로 파괴가 기본이다** —
`updateFn`이 만든 걸 `updateFn`이 자기 손으로 못 지우기 때문(reconcile
중엔 `dispose`가 거부됨). `updateFn`이 지우지 않길 원하면 `Detach`로 그
의도를 명시하고, **애초에 `:List`의 것이 아닌 요소**(`state<Frame>` 등)는
설치 시점에 `Owned = false`로 선언한다.

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
1만 건너뛰어 물리적으로 겹치는 LayoutOrder 범위가 나옴 — **의도 자체는 확정.**

**⭐ [전면 정정, 2026-08-24 6라운드 손 트레이싱 `H-2`] 그 의도를 구현하던
방식이 두 군데 틀려서 다시 썼다.** 옛 의사코드는
`pos = candidateIndex - 1 + (if isSlot(result) then result.Length:Get() else 1)`
였는데:

1. **같은 변수를 `_elements` 배열 인덱스로도 썼다.** `pos`는 물리 리프 개수
   기준인데 `_elements`는 **중첩 Slot 하나당 한 칸**이다 — 두 좌표계가 한
   변수에 겹쳐 있었고, 그 값이 그대로 `rawAdd`/`rawMove`의 index 인자로
   갔다. 첫 아이템이 중첩 Slot이면 `pos = 1 - 1 + 0 = 0`이 되어
   `table.insert(self._elements, 0, S)`가 된다 — **Luau에선 에러도 안 난다**
   (실측: `table.insert(t, 0, x)`는 `t[0] = x`, `#t` 불변). 그러면
   `ipairs`로 도는 모든 walk(실체화·마운트·파괴·언마운트)가 그 요소에
   **영원히 안 닿고**, 그 서브트리는 gcconn 때문에 GC도 안 되어 조용히
   영구 누수가 된다.
2. **`.Length`를 읽는 시점이 틀렸다.** `updateFn`이 반환하는 중첩 Slot은
   정의상 아직 어디에도 마운트 안 된 것이고(이미 마운트됐으면 `rawAdd`의
   `claimOwner`가 error), `Length`를 갱신하는 주체는 `recompute`뿐이며
   그건 실체화 시점에야 돈다 — 즉 **그 시점 `.Length`는 항상 `0`**이라
   `isSlot(result)` 분기는 언제나 `+ 0`이었다. 애초에 아무것도 반영하지
   못했다.

**확정된 해법**(사용자: *"offsetAt 으로 구함 → 기본적으로 activation 자체는
순차로 일어나므로 length 자체는 확정되는게 맞을것임 … 부모 슬롯의 offset 은
먼저 setOffsetSource 되므로 처리가 됨"*):

- **배열 자리와 물리 위치를 분리한다.** 배열 자리는 `slotPos`(생존 아이템마다
  정확히 +1), `updateFn`에 넘기는 `index`는 **`Dispatch.getOffsetAt`에서
  뽑는다**(위 "구현" 절의 `reconcile`).
- **그게 성립하려면 실체화가 순차여야 하고, 그래서 `rawAdd`가 마운트 전에도
  부기를 하도록 같이 바꿨다** — 옛 `rawAdd`는 `_mounted`가 거짓이면 부기까지
  통째로 건너뛰어서, 최초 population 동안 `bk.lengthList`가 비어 있었다.
  이제 `_mounted`는 물리 인스턴스 유무만 가리고 `native*`만 가린다(위
  "`isMounted` 이중 추적 분리" 절의 3상태).
- 그 결과 **첫 사이클과 이후 사이클의 `index`가 같아진다** — 옛 방식은
  같은 데이터인데도 첫 프레임만 다른 값을 줬다(LayoutOrder 계산이 첫
  프레임에 틀렸다).

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
