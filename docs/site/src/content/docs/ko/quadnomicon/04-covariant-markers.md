# [Quadnomicon Vol. 4] 불변성 우회: 공변 마커로 New Solver를 길들이다

> **작성 목적**: 프레임워크 아키텍트 및 타입 시스템 엔지니어를 위한 기술 해설서
> **관련 소스**: `quad-types/src/init.luau`, `quad-roblox/src/D/init.luau`(생성 파일), `scripts/gen-d.py`

> [!CAUTION]
> 이 권은 공개 타입 표면의 변성 설계와 솔버 한도를 다룹니다. 애플리케이션을 만들려고 quad를 배우는 중이라면 [Getting Started](/quad/ko/getting-started/01-core-mental-model/)부터 보십시오.

---

## 1. Luau New Solver의 벽: 불변성(Invariance)과 유니언 폭발

Roblox의 차세대 타입 체커(Solver V2)는 사운드니스를 크게 끌어올렸지만, 제네릭 컨테이너를 다루는 UI 프레임워크에는 장벽을 하나 세웠습니다.

### `State<T>`는 왜 불변(Invariant)인가

타입 $A$가 $B$의 서브타입($A <: B$)일 때:

- 값을 읽기만 하는 자리는 **공변(Covariant)** — $Output<A> <: Output<B>$.
- 값을 쓰기만 하는 자리는 **반공변(Contravariant)** — $Input<B> <: Input<A>$.
- 읽기와 쓰기를 모두 하는 자리는 **불변(Invariant)**.

Quad의 전체형 `State<T>`는 `Get(): T`와 (`Source`에서는) `Set(T)`을 함께 갖습니다. T가 양쪽 위치에 나타나므로 솔버는 이걸 **불변**으로 봅니다.

### 그래서 생긴 일: 유니언 폭발

`State<number>`가 `State<number | UDim>` 자리에 **들어가지 못합니다.** 그래서 생성 D 슬롯의 유니언은 가능한 조합을 멤버마다 손으로 나열해야 했습니다:

```luau
-- 마커 이전: 멤버별 팔을 전부 나열해야 했던 모양
type PropValue<T> =
    T
    | TweenData<T>
    | State<T>
    | State<Tween<T>>
    | State<T | Tween<T>>
    | None
```

31개 GUI 클래스를 코드 생성하자 그 나열이 솔버 예산을 잠식했고, 진단은 크래시가 아니라 **`Code is too complex to typecheck`**로 나왔습니다. 원인이 서로 다른 세 번의 사건에서 한도 플래그를 올려야 했습니다:

| 플래그 | 올린 계기 | 값 |
|---|---|---|
| `LuauTarjanChildLimit` | 생성 `export type D`/`DMapper`(31클래스 Param 인스턴스화), 뒤이어 클래스별 `<Class>Modifier` + `DModifier` | 기본 10000 → 40000 → 160000 |
| `LuauSubtypingIterationLimit` | 생성 `<Class>OnChange` 유니언 대 멤버 많은 콜백 타입(Color3/string) | 100000으로 핀 |
| `LuauTypeInferIterationLimit` | 상위 클래스 Modifier 타입(`As<Class>` 메소드 수십 개)의 캐스트 자리와 `Apply` 인자 자리 | 기본 20000 → 1000000으로 핀 |
| `LuauSolverConstraintLimit` | 숏핸드 키 넷을 GuiObject 계열 10클래스에 얹자 `export type D`가 다시 too complex | 1000000으로 핀 |

그리고 전체 타입 검사에 **4.96초**가 걸렸습니다.

---

## 2. 돌파구: "입력 자리"와 "출력 자리"의 분리

핵심 질문은 이것이었습니다.

> 프롭스나 Slot 요소처럼 **값을 입력받는 자리**에서, 렌더러가 그 State의 `:Compute()`나 `:With()`를 직접 호출할 일이 있는가?

없습니다. 입력 자리가 필요로 하는 건 둘뿐입니다:

1. 런타임에 이게 quad의 반응형 노드임을 알아볼 표식.
2. 타입 레벨에서 이 노드가 어떤 $T$를 방출하는지에 대한 **공변 정보**.

메소드는 그 둘 중 어느 것도 아닙니다 — 오히려 T를 양쪽 위치에 등장시켜 불변성을 만들고, 유니언에 앉으면 검사 예산까지 먹습니다.

---

## 3. 공변 마커 (`StateMarker<T>`)

그래서 입력 자리 전용 타입을 `quad-types`에 신설했습니다:

```luau
export type StateMarker<T> = { read __quadState: true, read __quadStateValue: T }

export type SlotMarker<T> = { read __quadSlot: true, read __quadSlotValue: T }
```

### 왜 작동하는가

1. **`read` 키워드**: 필드가 읽기 전용이면 T는 읽기 위치에만 나타나므로 솔버가 **T에 공변**으로 평가합니다. 그래서 `StateMarker<number>`가 `StateMarker<number | UDim>`의 서브타입으로 인정됩니다. 같은 필드를 읽기·쓰기로 두면 즉시 불변이 됩니다 — 대조군 스파이크가 그렇게 에러를 냅니다.

2. **폭 서브타이핑(Width Subtyping)**: 유저가 실제로 넘기는 값은 메소드가 다 붙은 전체형 `State<T>`입니다. 그 모양에 마커 필드가 들어 있으므로 캐스트 없이 마커 자리에 그대로 들어갑니다. **입력 자리가 마커만 요구해도 전체형 값을 받습니다.**

3. **검사력은 유지됩니다**: `StateMarker<number>` 자리에 `State<string>`은 여전히 거부되고, 제네릭 소비자 `take<T>(m: StateMarker<T>): T`는 T를 복원합니다.

4. **런타임 비용**: `__quadState`는 메타테이블에 실제로 한 줄 심겨 있고(`Impl.__quadState = true`) `__index`로 상속되므로 인스턴스당 비용이 없습니다. `__quadStateValue`는 **순수 팬텀**입니다 — 런타임 값에 존재하지 않습니다(T 값을 들고 있을 수 없으므로).

> **주의 — 런타임 판정은 이 필드가 아닙니다.** `q.isState(v)` 같은 판정은 Brand 레지스트리가 합니다. 마커 필드는 타입 좁힘과 진단을 돕는 조언층이고, 읽는 코드가 있어서는 안 됩니다.

---

## 4. 성과: 슬롯 유니언이 네 팔로 통일되다

```luau
-- 생성된 D/init.luau의 실제 한 줄
type PV2 = number | TweenData<number> | StateMarker<number | Tween<number>> | None -- number
```

State 계열의 여러 팔이 **공변 마커 한 팔**로 접히면서, 슬롯 유니언은 `T | StateMarker<T> | None` 세 팔이 기본 모양이 됐습니다. TweenService가 보간할 수 있는 타입의 슬롯만 `TweenData<T>` 팔이 하나 더 붙어 `T | TweenData<T> | StateMarker<T | Tween<T>> | None`이 됩니다(생성 파일 기준 74개 슬롯 중 10개). 가장 심했던 슬롯(`number | UDim`을 받는 `UICorner` 자리)은 **11팔에서 다섯 팔**(`number | UDim | TweenData<…> | StateMarker<…> | None`)로 줄었습니다.

| 지표 | 마커 도입 전 | 마커 도입 후 |
|---|---|---|
| 슬롯 유니언 모양 | 멤버별 조합을 손으로 나열(최대 11팔) | `T \| StateMarker<T> \| None` (+ 보간 가능 타입만 `TweenData<T>` 팔) |
| 타입 검사 시간 | 4.96초 | 3.41초 |
| `LuauSolverConstraintLimit` | 1,000,000으로 핀 | **플래그 제거**(없이도 클린) |

나머지 세 한도 플래그(`LuauTarjanChildLimit` / `LuauSubtypingIterationLimit` / `LuauTypeInferIterationLimit`)는 **그대로 핀되어 있습니다** — 마커가 해결한 건 슬롯 유니언의 팔 수이지 생성 D 전체의 규모가 아니기 때문입니다.

### 남아 있는 한계

- **꺼낸 값의 타입은 상한입니다.** 중첩 Slot을 `Get`/`Extract`로 꺼내면 선언된 `Slot<T>`로 보입니다 — `Slot<Frame>`을 `Slot<Instance>` 자리에 넣었다 꺼내면 `Slot<Instance>`가 되고, 그 핸들로 다른 클래스를 `Add`하는 게 타입상 통과합니다(런타임은 요소 클래스를 가리지 않습니다). 실제 요소 타입을 아는 쪽이 캐스트로 지킵니다.
- **생성자 추론은 별개 문제입니다.** `q.Slot()`만 쓰면 `Slot<unknown>`으로 추론됩니다 — 마커와 무관한 생성자 `T` 추론 이슈라, 명시 타입 인자 `q.Slot<<Instance>>()`로 줍니다.

---

## 5. 아키텍처 교훈

1. **메소드가 있는 인터페이스를 함수 인자 유니언에 직접 올리지 말 것.** 메소드는 T를 양쪽 위치에 등장시켜 불변성을 만들고, 유니언 서브타이핑을 마비시킵니다.
2. **입력에는 가벼운 읽기 전용 마커를, 출력·`self`에는 전체형을 쓸 것.** 값을 돌려주는 자리에서는 메소드가 실제로 필요합니다.
3. **팬텀 필드는 변성을 고르는 도구다.** 런타임에 값을 둘 수 있고 싸면 두고, 못 두면 팬텀으로 둡니다 — 단 팬텀은 조언층이므로 판정 로직이 절대 그걸 읽어서는 안 됩니다.
