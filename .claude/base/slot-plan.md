# Slot — 뮤터블 자식 배열, 엄격한 단일 마운트 소유권 (base로 승격됨)

**상태**: base — 설계 방향(소유권 귀속, 재마운트 시 throw, retract=폐기)과
소스 트리 상 패키지 경계까지 확정되어 `research/`에서 승격됨(`base/
architecture.md`의 "구현 착수: 소스 트리 구조 확정" 절 참고). 원본:
`.claude/initreq/raw-userinput.md` "slot을 구현하도록 하기로 했음" 절. Fusion의
`Children` SpecialKey와 Vide의 mount 무가드 비교는 `reference/comparison-fusion-vide.md`
참고 — 결론: **두 라이브러리 어디에도 이런 엄격한 단일 마운트 가드가 없음,
quad의 진짜 개선점.** **[2026-08-09 세 번째 세션]** CRUD 의미론
(`pre-implementation-audit.md` 1-7/1-8) 완전 확정, `research/
additional-primitives-plan.md`가 다루던 키 기반 동적 컬렉션 재조정도
`Slot:List(...)` 메소드로 이 문서에 승격·통합 완료 — 아래 참고.

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
(`process(inst,k,self)`)은 `Dispatch.setLength(inst,i,self.Length)` 호출과
같은 자리에서 `self._listed`면 `activateList(self,inst)`도 트리거해야 함 —
`:List`의 `data:Observer(fn)` 구독을 Slot 마운트 시점까지 lazy하게 미루는
것도 이 mount 훅의 책임(아래 "`Slot:List(...)`"의 "구독 시점" 절 참고).

**추가로 필요해진 핸들러**: Slot과는 별개로, `k`가 number이고 `v`가 이미
만들어진 Instance인 경우(중첩 인스턴스를 자식으로 직접 넣는 경우, 예:
`Frame { Frame {} }`)를 위한 핸들러도 필요 — `quad-roblox/src/Handlers/
InstanceChild.luau`. Slot은 "뮤터블 배열"을 다루고 이 핸들러는 "정적으로
하나 박아넣는" 더 단순한 경우라 별개로 둠.

## 개념

뮤터블 자식 배열. `Slot<T>()`(빈 인스턴스, 인자 없는 바닥 생성자 — 다른
독립 프리미티브의 `Type(args)` 관습과 동일하되, 무인자라 `T`를 추론할
수 없어 tbox 명시적 제네릭 적용 `Slot<<Instance>>()`로 지정)로 만들고,
`Add`/`Remove`/`Extract`/`Clear`/`Move`/`Swap` CRUD로 조작하면 실제
바인드된 children이 그에 맞춰 갱신됨 — 정확한 시그니처는 아래 "CRUD API
확정" 절 참고(`get`/`set`은 드롭).

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
- **핸들러 계층 값(Ref/PreRef/Observer/Effect/Modifier) 금지, 즉시
  `error`** — `Modifier` 필드가 이 값들을 담으면 즉시 `error`로 확정했던
  것(`modifier-plan.md` 7번)과 같은 판별 메커니즘(`isRef`/`isPreRef`/
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
  Ref를 넘기면 됨(`slot:Add(Frame { Ref = myRef })`).
- **`T`의 실제 의미**: 위 배제 덕에 "이 Slot이 실제로 담을 수 있는 최종
  마운트 가능한 값의 타입" 그 자체로 단순해짐 — quad-roblox엔 사실상
  `T = Instance` 하나뿐(컴포넌트 호출 결과도 결국 Instance)이라
  `D.InstSlot = Slot<<Instance>>`가 사실상 "그" Slot 타입. `Slot<T>()`가
  기본값(`T` 생략 시) 없이 항상 명시를 요구하는지, `quad-base`에선
  `any`로 기본값을 두는지는 tbox 제네릭 적용 문법 확정 시 같이 정할 것
  (이 문서 "자식으로 넘기는 클래스 스토어" 절의 기존 미결과 같은 갈래).

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
  하나). **트리거 시점은 `Dispatch.process(inst,k,self)`가 이 Slot
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
  마다 전역 weak-set 멤버십으로 추적 — 특정 Slot 인스턴스에 안 묶임
  ("한 인스턴스가 어디에도 중복 마운트 안 됨"이 라이브러리 전역 불변식이라서).
  `Add`가 이 weak-set을 확인(이미 참이면 error)/설정, `Remove`/`Extract`
  둘 다 여기서 제거(둘의 차이는 파괴 여부일 뿐, "마운트 해제"라는 점은 같음).

## 여럿 존재 가능, 부모가 실제 데이터 테이블만 다루면 됨

Slot은 하나의 instance 안에 여럿 존재할 수 있다. 전부 하나의 children으로
들어가지만, 실제 렌더된 instance에서 `GetChildren()`을 직접 하지 않고도 부모가
생성한 "실제 slot 데이터 테이블"만 다루면 되게 해서 **추상화 수준을 낮은 직접
바인딩에서 한 단계 떼어냄**(간접화를 통한 추상화).

## 마운트된 Slot의 재마운트는 즉시 throw (확정)

**사용자 확인 완료**: 이미 사용된(마운트된) slot을 재마운트하려 하면 **즉시
`error()`로 중단** — warn+no-op 아님. 개발 중 바로 잡아낼 수 있게 강하게
실패하는 쪽 선택. 마운트되는 순간 slot의 실제 대상은 고정된다 — 따라서
**글로벌 스코프에서 slot을 쓰는 건 그다지 좋지 않을 수 있음**(재사용/재마운트가
막히므로).

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
bind-system-plan.md`의 "Length/Offset — 여러 Slot이 형제로 섞일 때 순서
보장" 절 참고. **DOM류 물리 순서 백엔드에도 같은 base 메커니즘이 그대로
재사용됨**(offset이 바뀌어도 이미 마운트된 원소를 물리적으로 옮길 필요
없음 — `insertBefore`가 뒤 형제를 자연히 밀어주므로, backend Handler의
"offset 변경 시 할 일"만 no-op으로 달라짐) — `architecture.md`의 "다른
렌더 백엔드에서도 재사용 가능해야 한다"는 전제와도 부딪히지 않음.

## Slot과 Store 바인드의 관계 (`retract` 순서)

Slot이 store 바인드로 들어오는 경우, pluggable 처리기에 `retract`(구 cleanup,
`base/lifecycle-pattern.md` 참고) 핸들러가 필요함 — 한번 넘어간 slot 요소가
나중에 `retract`되면 삭제되는지, 아니면 "부모의 소유이니 부모가 처리"해야
하는지 검토 필요. **기울어진 결론(잠정안, 이후 정정됨)**: 부모가 정리 정도만
미리 수행하고 다시 `process`하면 되므로, 부모에게 위임(자식 slot 요소 자체가
스스로 정리를 실행하는 게 아니라).

> **정정(2026-08-04 검증 라운드)**: 위 "부모 위임" 잠정안은 이후 **폐기**
> 쪽으로 정정됨 — 아래 "확정" 절과 `.claude/question.md`("Slot의 `retract`
> 동작이 '부모 위임' 잠정안에서 '폐기(옮기지 않음)'로 확정") 참고. 이 문단은
> 검토 과정의 히스토리로만 남겨둠, 현재 유효한 동작 아님.

이건 `base/bind-system-plan.md`의 "Store 바인드는 재실행 래핑" 확정
모델과 맞물림 — slot이 store 값으로 오면, store 바인드 핸들러가 이전 slot
상태를 `retract`하고 새 slot 상태로 다시 `process`하는 사이클을 돈다는 뜻.
Slot 핸들러 자신이 감시 중인 값(배열/스토어)이 바뀔 때 child를 갱신하는
추적(구독)도 `base/bind-system-plan.md`가 말하는 "process 함수가 다른 값
변경을 추적해도 됨" 범위에 속하고, `retract` 시점엔 그 추적만 풀면 됨 —
Destroy 시점엔 `retract`가 호출되지 않는다는 원칙(`base/lifecycle-pattern.md`)도
동일하게 적용.

**확정(2026-08-04 검증 라운드): retract되는 slot은 옮겨지지 않고 그냥 폐기된다.**
Slot은 바인딩되는 순간 그 안의 요소를 전부 own해버리는 데이터형 — 새 slot
상태로 교체될 때 이전 slot의 내용을 다른 곳으로 옮기는 경로는 없음, 그냥
버림. React의 portal(`<></>`)류로 나중에 옮길 수 있게 하는 것도 검토됐으나
**이번 마일스톤에서는 오버엔지니어링으로 판단, 하지 않음** — 필요성이 명확해지면
그때 별도로 다시 논의.

> **범위 명확화(2026-08-09 세 번째 세션)**: 위 "폐기, 옮기지 않음"은
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
    값(Ref/PreRef/Observer/Effect/Modifier)이면 에러 — 위 "요소 타입 제약" 절.
    `index`가 범위 밖(1..현재 개수+1, 즉 끝에 추가하는 위치까지 포함)이면
    에러 — **clamp 안 함**(2026-08-10 세션 확정): index가 조용히 다른
    자리로 보정되면 "의도한 위치가 아닌데 그대로 성공한" 조용한 버그가
    생기고, 이미 다른 CRUD 전부가 fail-fast인 것과도 불일치함.
  - `Remove`/`Extract`/`Move`: `index`(들)가 범위 밖(1..현재 개수)이면
    에러.
  - `Extract(index, newElement)`: `newElement`도 `Add`와 동일한 검증
    (이미 마운트/타입 제약) 적용.
  - `Swap`: `indexA`/`indexB` 중 하나라도 범위 밖이면 에러 — 단
    `Swap(i, i)`(같은 인덱스)는 위치가 안 바뀌므로 에러 없이 no-op.
- **`Move`/`Swap`은 반환값 없음(void)** — 내부 재배치만 수행, 멤버십
  weak-set을 안 건드림(요소가 Slot을 떠난 적이 없으므로) — 그래서 `Add`/
  `Remove`/`Extract`보다 저렴함.
- **공개 CRUD 중 실제로 mutate하는 것(`Add`/`Remove`/`Extract`/
  `ExtractAll`/`Clear`/`Move`/`Swap`)은 "가드 확인 + `raw*` 위임"의 얇은
  wrapper** — `self._listed`(`:List`가 설치돼 있으면 수동 CRUD 금지)만
  확인하고 실제 로직은 `rawAdd`/`rawRemove`/`rawExtract`/`rawClear`/
  `rawMove`/`rawSwap`에 있음 — 이 `raw*` 함수들이 `:List`의 reconcile이
  가드 없이 직접 호출하는 바로 그 함수(아래 "`Slot:List`" 절의 "구현"
  참고). 공개 메소드에 로직이 따로 있는 게 아니라 전부 이 한 세트를
  공유. **`Get`/`IndexOf`는 순수 읽기라 이 가드 대상 아님** — `:List`가
  설치돼 있어도 자유롭게 호출 가능.
- **재진입성**(Observer/store-bind 재실행 콜백 안에서 `Add`/`Clear`를
  다시 호출) — 별도 가드 불필요. CRUD는 평범한 동기 테이블 뮤테이션 +
  Dispatch 호출일 뿐이라 "일반적 무한루프는 방어 안 함, provider 버그로
  간주"라는 기존 원칙이 그대로 적용됨.
- **`Slot()` 생성자**: 인자 없는 빈 생성자로 확정 — 초기 children을
  가변인자로 받는 옵션도 검토했으나, "명시적으로 `Add`해야 들어간다"
  쪽이 이 프로젝트의 "매직 없이 명시적" 기조와 더 맞음.

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
diff해서 변경분만 생성/갱신/파괴한다. **독립 타입이 아니라 `Slot`의
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

**이름 정정 — `renderFn` → `updateFn` (같은 세션 후속).** 아래 서술하는
호출 계약이 "새 key가 나타났을 때 1회 렌더"에서 "매 사이클 재호출되어
갱신 여부를 스스로 판단"으로 바뀌면서, "render"보다 "update"가 실제
역할을 더 정확히 반영한다고 판단해 이름도 같이 바꿈.

- `data: {[K]:V} | State<{[K]:V}> | Source<{[K]:V}>` — plain이면 최초
  1회 배치만 하고 이후 추적 안 함(다시는 안 바뀌므로), State/Source면
  아래 메커니즘이 계속 동작. 기존 leaf 프로퍼티의 "리터럴 또는 State
  둘 다 받는" 폴리모픽 컨벤션 재사용.
- `keyFn(item, index) -> key`(선택, 생략 시 `index`를 그대로 key로 사용) —
  아이템 값과 인덱스 둘 다 받음.
- **`updateFn<UD = any>(item, index, userdata: UD?, prev: T?): (T | nil, UD?)`
  — 매 reconcile 사이클마다 모든 key에 대해 호출됨.** `:List`는 더 이상
  item을 위해 `Source`를 대신 만들어주지 않음(아래 "왜 `Source`를
  `:List`가 안 만드는가" 참고) — `item`/`index`는 매번 그 사이클의 raw
  현재값 그대로 넘어감, 반응형으로 쓸지는 `updateFn`이 알아서 결정.
  - **`userdata: UD?`** — 이 key에 대해 지난 호출에서 `updateFn` 자신이
    반환해둔 두 번째 값을 그대로 돌려받음(첫 호출은 `nil`). 완전히
    opaque — `:List`는 안을 전혀 안 들여다봄. `updateFn`이 원하는 걸
    아무거나 담아도 됨(item의 `Source`, 여러 파생 State, 로컬 UI
    상태 등).
  - **`prev: T?`** — 이 key에 대해 지금 실제로 마운트돼 있는
    element(없으면 `nil`, 첫 호출을 포함해 언제든 가능).
  - **반환값 두 개는 서로 완전히 독립** — `:List`가 `result`와 `userdata`
    사이에 어떤 커플링도 안 둠(예: `result`가 `nil`이라고 `userdata`를
    자동으로 지우지 않음), 그대로 기록만 함. **[정정, 같은 세션 후속]**
    처음엔 "`result`가 `nil`이면 `userdata`도 같이 버림"이었으나, 이러면
    "인스턴스는 파괴하되 다시 나타날 때 재사용하려고 캐시는 남겨두고
    싶다" 같은 정당한 패턴 자체가 원천 봉쇄됨 — 그럴 이유가 없어 커플링을
    없앰. 흔한 경우(둘 다 리셋)는 그냥 `return nil` 하나로 충분(Lua가
    안 받은 반환 슬롯을 알아서 `nil`로 채움), 캐시를 남기고 싶으면
    명시적으로 `return nil, ud`.
  - `updateFn`은 매번 다음 중 하나를 반환:
    - **`prev`를 그대로 반환** — "지금 마운트된 걸 계속 쓴다"는 뜻.
      관용구: `if prev and (필터 통과) then ...update ud...; return prev,
      ud end`. 실제 마운트/파괴가 없는 **저렴한 경로**.
    - **새 값(또는 다른 값)을 반환** — 첫 렌더(이 key 최초 등장) 또는
      의도적 교체. `prev`가 있었다면 그건 파괴되고 새 값이 그 자리를
      대신함.
    - **첫 번째 값으로 `nil`을 반환** — "지금 이 key는 렌더 안 함"(filter
      탈락 등). `prev`가 있었다면 실제로 파괴됨(단순 `Visible = false`
      아님 — 아래 참고). `None`을 반환해도 동일 취급(둘 다 허용, 편의상
      `nil` 권장 — 반환값이 raw Slot 요소로 직접 들어가는 게 아니라
      `:List`의 reconcile이 해석만 하므로 "요소 타입 제약"의 raw
      `nil`/`None` 금지와 안 부딪힘).
  - `userdata = userdata or {}`류 lazy-init 관용구가 `UD`가 완전히 자유
    제네릭인 상태에서도 Luau 타입 시스템이 매끄럽게 좁혀주는지는 **실측
    필요**(M0/M6 착수 시 확인 항목, 지금 단정 안 함).

### 왜 매 사이클 호출로 바뀌었는가 — filter/toggle 문제

사용자가 제기한 문제: item이 State 변경으로 "더 이상 렌더되면 안 되는"
상태가 될 수 있는데(예: 검색 필터에서 탈락), 기존 "1회만 호출" 모델엔
이걸 표현할 방법이 없었음. 실무에서 흔한 회피책은 실제로 제거하지 않고
`Visible = false`만 토글하는 것 — 하지만 이건 **lazy하지 않음**: 필터링된
항목도 여전히 완전히 살아있는 Instance라 애니메이션/이벤트 연결/재계산이
계속 돎. 리스트가 200개+가 되면 "보이는 건 20개인데 200개가 전부 계속
돌아가는" 문제가 실제 비용으로 드러남.

**해법**: `updateFn`을 매 사이클 호출하되, `prev`를 줘서 "바꿀 게 없으면
그대로 돌려주기만 하면 되는" 저렴한 경로를 만들고, filter 탈락은 `nil`
반환으로 **진짜 파괴**되게 함 — Visible 토글이 아니라 실제 Remove.
200개 중 20개만 통과하는 필터면 20개만 실제로 살아있고 나머지 180개는
정말로 존재하지 않음(애니메이션도 안 돎).

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
lifecycle-pattern.md` "quad는 라이프사이클 중간에 있지 않다")과 정확히
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
자신이 마운트되는 순간(`Dispatch/Slot.luau`의 `process(inst,k,self)`)에
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

-- Dispatch/Slot.luau의 process(inst,k,self)가 마운트 시점에 1회 호출
-- (self._mounted=true/self._mountedInst=inst를 세팅하는 바로 그 자리)
function activateList(self, inst)
    local keyFn, updateFn = self._keyFn, self._updateFn
    local mounted, userdata, keyIndex = {}, {}, {}

    local function reconcile(items)
        local newKeyIndex, seen = {}, {}
        for i, item in ipairs(items) do
            local key = keyFn(item, i)
            newKeyIndex[key] = i
            seen[key] = true

            local prev = mounted[key]
            local result, ud = updateFn(item, i, userdata[key], prev)
            if result == None then result = nil end   -- 편의: None도 nil과 동일 취급

            if result ~= prev then
                if prev ~= nil then rawRemove(self, prev) end    -- 파괴
                if result ~= nil then rawAdd(self, result, i) end -- 새로 배치
                mounted[key] = result
            elseif prev ~= nil and keyIndex[key] ~= i then
                rawMove(self, prev, i)                 -- 그대로 쓰되 위치만 이동
            end

            userdata[key] = ud    -- result와 무관, 그대로 기록
        end
        for key in pairs(keyIndex) do   -- 직전 사이클에 존재했던 전체 key
            if not seen[key] then
                local prev = mounted[key]
                if prev ~= nil then rawRemove(self, prev) end
                mounted[key], userdata[key] = nil, nil
            end
        end
        keyIndex = newKeyIndex
    end

    local data = self._listData
    if isState(data) then
        local observer = data:Observer(function() reconcile(data:Get()) end)
        -- Observer 등록 자체의 "등록 즉시 1회 실행"은 canExecute/Subscribed
        -- 게이팅과 무관하게 여기서 이미 무조건 일어남(아래 "구독 시점" 절) —
        -- bindLifetime은 그 다음에 걸어 *이후* 재실행만 inst 생명주기에 귀속
        bindLifetime(inst, observer)
    else
        reconcile(data)
    end
end
```

- **`data:Observer(fn)`**: 새 구독 프리미티브 아님 — 2026-08-07 여섯 번째
  세션에 이미 "등록 즉시 1회 실행" 확정된 그 메소드를 그대로 씀.
  `reconcile`은 매번 **현재 전체 스냅샷을 받아 O(n) 단일 패스로 diff**
  — 트리 전체를 비교하는 비싼 diff가 아니라 `seen` 셋 하나로 "새 key
  목록에 없는 건 지운다"만 판정하는 React/Vue/Solid류의 표준 key 기반
  방식, `data`가 참조를 유지한 채 뮤테이션+`Emit()`되는 경로도 지원해야
  하는 이상 최소 한 번은 훑어야 하는 게 불가피함.
- **`updateFn`을 매번 부르는 게 비싼 게 아닌 이유** — 흔한 경로(`prev`
  그대로 반환)는 함수 호출 하나뿐, 실제 Instance 생성/파괴가 있는 건
  key가 새로 나타나거나/사라지거나/filter로 구조가 바뀌는 경우뿐.
  200개 중 값만 갱신되는 사이클엔 200번의 값싼 함수 호출이 있을 뿐,
  200번의 재구성이 있는 게 아님.
- **`mounted`/`userdata`를 정리하는 루프가 `mounted`가 아니라 이전
  사이클의 `keyIndex`를 순회하는 이유** — `userdata`가 이제 `result ==
  nil`이어도 살아남을 수 있어서(위 "반환값 두 개는 서로 독립"), 어떤
  key가 `mounted[key] == nil`인 채로(필터 탈락 상태) `data`에서 완전히
  사라지면 `pairs(mounted)`로는 그 key가 아예 안 잡혀서 `userdata`가
  못 치워지고 샘 — 직전 사이클에 실제로 존재했던 **전체** key 집합
  (`keyIndex`, 매 사이클 모든 key에 대해 채워짐)을 순회해야 이 케이스를
  놓치지 않음.
- **`mounted`/`userdata`/`keyIndex`**: `activateList`(마운트 시점 1회
  실행)의 로컬 변수(클로저 업밸류) — 별도 전역 weak table(`Relate` 등)
  불필요, `inst`/`self`가 살아있는 동안만 존재하면 되고 죽으면 클로저도
  같이 GC됨(아래 "구독 시점" 절).
- **`reconcile`이 직접 호출하는 건 `rawAdd`/`rawRemove`/`rawMove`뿐** —
  `rawExtract`/`rawSwap`/`rawClear`도 (위 "모든 공개 CRUD는 가드+위임"
  구조상) 당연히 존재하지만, `:List`의 reconcile 알고리즘 자체가 그
  셋을 쓸 일이 없을 뿐(제거는 항상 파괴 확정이라 `Extract` 아닌 `Remove`
  경로, 리오더는 항상 절대 위치 이동이라 `Swap` 아닌 `Move` 경로,
  `Clear`는 reconcile 단위가 아니라 Slot 전체 단위 연산이라 무관).
- **리오더는 `Move`(의 가드 없는 버전)** — Parent를 안 건드리는 진짜
  저비용 경로. 최소-이동 알고리즘(LIS 기반 등) 자체는 구현 시점 최적화로
  미룸, 여기선 계약(파괴 없이 위치만 바뀜)만 확정.

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
마운트되는 순간(`Dispatch/Slot.luau`의 `process(inst,k,self)` — 위
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
"등록 즉시 1회 실행" 계약) — 이 시점엔 아직 `bindLifetime`이 `Subscribed`를
세팅 전이라 `canExecute`를 물으면 거짓이겠지만, 애초에 최초 실행은
`canExecute`로 게이팅되는 대상이 아니라서 상관없음. `bindLifetime`은 그
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
새 코드가 필요 없음, `base/lifecycle-pattern.md`의 "정리는 기본적으로
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

- 재마운트 에러 처리(throw), retract 시 폐기(옮기지 않음) 둘 다 확정. 남은 건
  실제 구현 단계에서 이 "폐기" 동작이 실사용에서 불편하지 않은지 재검증하는
  정도 — 설계 방향 자체는 더 이상 열려있지 않음.
- "클래스가 슬롯을 받는 방법"(Named Slot 없음)도 확정됨(위 "클래스가 슬롯을
  받는 방법" 절 참고).
- **[해소됨, 2026-08-09 세 번째 세션]** `add`/`remove`/`clear` CRUD 의미론,
  `isMounted` 이중 추적 분리, 키 기반 동적 컬렉션 재조정(`Slot:List`) —
  위 "CRUD API 확정"/"`isMounted` 이중 추적 분리"/"`Slot:List`" 절 참고.
- **[해소됨, 2026-08-09 여섯 번째 세션]** 여러 Slot이 형제로 섞일 때
  순서 보장 — 위 "여러 Slot이 섞일 때 순서 보장" 절 참고, 메커니즘은
  `base/bind-system-plan.md`의 "Length/Offset" 절이 최신 소스.

## Slot.Length — `:List`뿐 아니라 항상 노출됨 (2026-08-09 여섯 번째 세션)

Slot은 CRUD/`:List` 여부와 무관하게 `.Length: State<number>`를 항상
노출 — 지금 실제로 마운트된 요소 개수(사용자가 직접 CRUD로 넣든 `:List`
reconcile이 넣든 동일). 두 용도를 겸함: (1) 사용자가 "n개 검색됨" 같은
UI에 직접 관측, (2) `Dispatch.setLength(inst, i, slot.Length)`가 형제
순서 보장(위 "여러 Slot이 섞일 때 순서 보장" 참고)에 내부적으로 읽는 바로
그 값 — 별도 두 State가 아니라 하나. `:List`의 filter 탈락이 실제
`Remove`(Visible 토글 아님)로 확정돼 있어서 `Length`는 자동으로 "실제
마운트된 것"만 반영 — 수동 Visible 토글을 쓰면 `Length`가 그걸 못 잡는
게 맞고, 그건 사용자가 별도 State로 계산해야 하는 몫.

## 백로그 — `Slot():Single(state, updateFn?)` (2026-08-09 여섯 번째 세션, 미착수)

`:List`의 key-map(`mounted`/`userdata`/`keyIndex`) 없이 "0개 아니면 1개"만
다루는 더 가벼운 편의 메소드 제안(예: `state<Frame?>`를 조건부로 마운트하는
관용구를 더 명시적으로 표현) — `.Length`는 그냥 0/1이고 나머지(offset 소비,
LayoutOrder 바인딩)는 일반 Slot과 완전히 같은 프로토콜. 아직 상세 설계
안 함, `.claude/question.md`에 백로그로만 반영.
