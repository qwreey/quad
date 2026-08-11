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
  **[2026-08-11 세션] `Slot<T>` 자신도 이제 예외적으로 허용 — 실제로는
  `T = Instance | Slot<Instance>`(자기 참조 제네릭).** 컴포넌트 결합
  시 "결과가 Instance든 Slot(멀티루트)이든 구분 없이 다른 Slot에
  넣을 수 있어야 한다"는 요구 때문 — 상세 근거/메커니즘은 아래
  "Slot-in-Slot 중첩" 절 참고. 자기 참조 제네릭이 Luau에서 실제로
  타입체크되는지는 다른 재귀 타입 케이스들과 같은 급으로 실측 필요
  (`.claude/luau-test/`, M0/M6 착수 시 확인).

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
  `base/bind-system-plan.md`의 "Length/Offset" 절, `Source⊇State`
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
    기여한 개수의 누적합(`base/bind-system-plan.md`의 "Length/Offset" 절
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
      실제로 파괴됨(단순 `Visible = false` 아님 — 아래 참고). 편의상
      `nil` 권장(반환값이 raw Slot 요소로 직접 들어가는 게 아니라
      `:List`의 reconcile이 해석만 하므로 "요소 타입 제약"의 raw
      `nil`/`None` 금지와 안 부딪힘).
    - **다시 그림** — `prev`와 다른(보통 새로) 만든 값을 반환. 첫 렌더
      (이 key 최초 등장) 또는 의도적 전체 교체 — `prev`가 있었다면 그건
      파괴되고 새 값이 그 자리를 대신함. 이 갈래에서 반응형 값(예:
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
            LayoutOrder = layoutOrder:With(offset):Compute(function(i, o) return i + o end),
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

            if result ~= nil then
                pos = candidateIndex   -- 실제로 살아남았을 때만 커밋
            end

            if result ~= prev then
                if prev ~= nil then rawRemove(self, prev) end       -- 파괴
                if result ~= nil then rawAdd(self, result, pos) end -- 새로 배치, 압축 위치 기준
                mounted[key] = result
            elseif prev ~= nil and keyIndex[key] ~= pos then
                rawMove(self, prev, pos)               -- 그대로 쓰되 위치만 이동
            end

            userdata[key] = ud    -- result와 무관, 그대로 기록
            newKeyIndex[key] = pos
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
  놓치지 않음. `userdata` 안에 사용자가 직접 넣어둔 `Source`(예: 위
  `LayoutOrder` 예시의 `layoutOrder`)도 이 정리 대상에 자연히 포함됨 —
  `:List` 자신은 그 안을 안 들여다보지만, `userdata[key] = nil`이 되는
  순간 참조가 끊겨 GC됨.
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
추가/제거 — 그 외 경로는 UB(2026-08-10 세션, `base/bind-system-plan.md`의
"Length/Offset" 절 반영).** 둘 다 `Dispatch.setLength`/`setOffsetSource`를
정확히 호출하는 유일한 정당 경로라, 이걸 우회해서(예: 외부 코드가 Slot이
마운트해둔 부모 Instance에 직접 `.Parent = parentInst`로 자식을 끼워
넣는 것) 자식을 추가/제거하면 `Length`/형제 순서 계산이 그 변화를 몰라
조용히 어긋남 — 별도 방어 로직 없음, 문서 경고로만 남김.

## `Slot:Single(state, updateFn)` — 확정 (2026-08-11 세션, `:List` 위의 순수 sugar)

기존 "백로그, 미착수"에서 실제 설계까지 완료됨 — 새 reconcile 로직
없이 **`:List`를 정확히 0/1개짜리 배열로 감싸는 sugar**:

```lua
function Slot:Single(state, updateFn)
    local data = isState(state)
        and state:Compute(function(v) return v == nil and {} or { v } end)
        or (state == nil and {} or { state })

    return self:List(data, function(item, index, offset, prev, ud)
        return updateFn(item, offset, prev, ud)   -- index는 항상 상수라 안 넘김
    end, function() return true end)   -- 고정 key
end
```

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
배제하지 않음 — 나머지(Ref/PreRef/Observer/Effect/Modifier 금지,
nil/None 금지)는 그대로.

### 재귀 메커니즘 — 새 프리미티브 없이 `Dispatch.setLength`/`setOffsetSource`를 Slot 자신 키로 재사용

`base/bind-system-plan.md`의 "Length/Offset" 절이 이미 확정해둔 두 함수는
owner 키(`inst`)가 물리 Instance일 필요가 없음(`Relate`가 아무 테이블이나
weak 키로 받음) — **Slot 자신을 owner 키로 재사용하면 최상위 마운트와
중첩 마운트가 완전히 같은 함수 호출**이 됩니다.

```lua
-- quad-base, Slot.luau — 재귀적 "attach" 하나로 최상위/중첩 마운트 통합
local function attachSlot(slot, physicalTarget, ownerKey, position)
    slot._mounted = true
    slot._mountedInst = physicalTarget

    Dispatch.setLength(ownerKey, position, slot.Length)   -- slot.Length는 State<number>, 기존 로직 그대로
    local offsetSource = Source(0)
    Dispatch.setOffsetSource(ownerKey, position, offsetSource)
    slot.Offset = offsetSource

    if slot._listed then
        activateList(slot, physicalTarget)   -- 기존 :List lazy activation, 안 바뀜
    end

    -- attach 전에 이미 들어와있던 요소들 flush(이미 채워둔 Slot을 나중에
    -- 마운트하는 흔한 패턴이 원래도 전제하고 있던 것 — 새 개념 아님)
    for i, element in ipairs(slot._elements) do
        if isSlot(element) then
            attachSlot(element, physicalTarget, slot, i)   -- 재귀, ownerKey가 이제 slot 자신
        else
            element.Parent = physicalTarget   -- quad-roblox 글루가 실제 수행
        end
    end
end
```

**최상위 마운트(`Dispatch/Slot.luau`)는 이제 이 함수 호출 한 줄:**
```lua
-- process(inst, k, slotValue)
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

`recompute`가 owner가 Slot이면 그 `.Length`에도 합계를 반영하도록
확장됐으므로(`base/bind-system-plan.md` 참고) — `Slot.Length`는 더
이상 raw 개수가 아니라 **"요소별 기여도의 합"**(plain=1, nested
Slot=그 `.Length`)이 됨. plain 요소만 있는 흔한 경우엔 항상 합==개수라
체감 차이 없음.

### 파괴 — 재귀적 `Clear()` 금지, flat teardown

**재귀적으로 `Clear()`(요소별 `Remove` 반복)를 하면 죽는 서브트리
내부에서 불필요한 shift+recompute가 요소 수만큼 반복되어 비용이 커짐 —
대신 순수 파괴 walk만 하고, outer 쪽 recompute는 자기 위치 하나에
대해서만 한 번 돎:**

```lua
local function destroySlotTree(slot)
    for i, element in ipairs(slot._elements) do
        if isSlot(element) then
            destroySlotTree(element)   -- 재귀는 "파괴"에만, choreography 없음
        else
            element:Destroy()
        end
    end
    local bk = getBookkeeping(slot)    -- 이 slot이 자기 자식들 위해 등록해둔 observer들
    if bk then
        for i, observer in pairs(bk.observers) do
            unbindLifetime(slot._mountedInst, observer)
        end
    end
end

function rawRemove(self, index)
    local element = self._elements[index]
    local bk = getBookkeeping(self)
    if bk.observers[index] then
        unbindLifetime(self._mountedInst, bk.observers[index])  -- outer가 이 위치 위해 등록해둔 observer
    end
    if isSlot(element) then destroySlotTree(element) else element:Destroy() end

    spliceArraysDown(self, index)   -- _elements/lengthList/sourceList 전부 한 칸씩 당김
    recompute(self, bk)             -- outer 자기 자신 레벨에서 딱 1회만
end
```

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
  수정된 `recompute`(`base/bind-system-plan.md` 참고)를 보면 `:Set()`이
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
의도적으로 섞는 것. 상세는 `base/bind-system-plan.md`의 "0-based
개수" 절 참고.
