---
title: Slot
description: 가변 자식 배열 프리미티브 — CRUD 열하나, :List/:Single 재조정, Detach/KeyGone, dispose
---

`Slot<T>`은 **가변 자식 배열**입니다. 부모의 숫자 키 자리에 한 번 놓이면, 그 뒤로 Slot에 가한 CRUD가 그대로 물리 자식에 반영됩니다 — 부모를 다시 만들지도, 렌더 함수를 다시 돌리지도 않습니다.

Slot은 **두 모드 중 하나**로만 삽니다. 손으로 원소를 넣고 빼는 **수동 CRUD** 모드와, 데이터 배열에 맞춰 quad가 재조정하는 **`:List`/`:Single`** 모드입니다(처음 꽂힐 때 한 번 짓는 **`:Lazy`**도 이 쪽 — 수동 CRUD가 잠깁니다). 둘은 상호 배타이고, 섞으려 하면 그 자리에서 에러가 납니다.

이 페이지의 심볼: [`q.Slot`](#qslottinitial) · [`slot.Length`](#slotlength) · [`slot.Offset`](#slotoffset) · [`slot:Add`](#slotaddelement-index) · [`slot:Remove`](#slotremoveindex) · [`slot:Replace`](#slotreplaceindex-newelement) · [`slot:Extract`](#slotextractindex-newelement) · [`slot:ExtractAll`](#slotextractall) · [`slot:Splice`](#slotspliceindex-removecount-newelements) · [`slot:Clear`](#slotclear) · [`slot:Move`](#slotmoveoldindex-newindex) · [`slot:Swap`](#slotswapindexa-indexb) · [`slot:Get`](#slotgetindex) · [`slot:IndexOf`](#slotindexofelement) · [`slot:WhenIdle`](#slotwhenidlefn) · [`slot:List`](#slotlistdata-updatefn-keyfn-opts) · [`slot:Single`](#slotsinglestate-updatefn-opts) · [`slot:Lazy`](#slotlazyfn) · [`q.Detach`](#qdetach) · [`q.KeyGone`](#qkeygone) · [`q.dispose`](#qdisposevalue)

이 페이지의 모든 예제는 아래 프롤로그를 전제합니다.

```luau
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("@game/ReplicatedStorage/Client/UI/Quad")
local QuadTypes = require("@game/ReplicatedStorage/roblox_packages/quad_types") -- 설정 모듈이 다시 내보내지 않는 타입(`QuadTypes.SlotItem<T>`·`QuadTypes.KeyGone`)
```

## 원소 대수 — 넣는 자리와 꺼내는 자리의 타입이 다르다

```luau
-- 입력 자리(생성자 initial, Add/Replace/Extract의 새 원소, Splice, IndexOf)
type SlotElement<T> = T | StateMarker<(T | None)?> | SlotMarker<T> -- State가 nil/None을 내놓으면 그 원소를 내린다
-- 출력 자리(Get/Extract/ExtractAll/Splice의 반환, updateFn의 ctx.Prev)
type SlotItem<T> = T | State<T> | Slot<T>
```

같은 값의 두 역할이라 별칭이 둘입니다. 입력 자리는 **마커 타입**이라 `T`에 공변입니다 — `Slot<Instance>`의 원소 자리에 `State<Frame>`이나 `Slot<Frame>`이 그대로 들어갑니다. 출력은 언래핑된 원래 값이라 전체형입니다.

옵셔널(`?`) 자리에 놓인 `Slot<T>` 자체(위 원소 자리가 아니라 `Slot<Instance>?`처럼 `Slot`을 담는 변수·필드 타입)는 [2026-09-26 기준] 신 솔버가 `T`를 검사하지 않는다는 별개의 한계가 있습니다.

원소로 놓을 수 있는 것은 셋입니다.

| 넣은 것 | 되는 일 |
|---|---|
| 백엔드가 마운트할 수 있는 값(Roblox면 `Instance`) | 그대로 물리 자식 하나 |
| `State<T>` / `Source<T>` | 내부적으로 `:Single`을 건 래퍼 Slot으로 감싸집니다. 값이 바뀌면 그 자리만 통째로 교체됩니다 |
| 다른 `Slot<T>` | 중첩 — 바깥 Slot의 한 자리를 안쪽 Slot의 물리 원소 전부가 차지합니다 |

그 밖은 전부 거부됩니다.

- `Quad0238 Slot: handler-layer values (Ref/PreRef/PostRef/Observer/Effect/Modifier) cannot be elements`
- `Quad0239 Slot: nil/None cannot be an element - only actually mountable values`
- `Quad0240 Slot: this backend cannot mount this value`
- `Quad0241 Slot: this element is not claimed by quad - build it with q.Elem or take it over with Claim first (an Instance made by another quad module instance also counts as not claimed here, and so does a destroyed one - a destroyed Instance cannot be reused)` — quad 밖에서 만든 인스턴스(`Instance.new`, 다른 라이브러리가 만든 트리)는 quad가 소유하고 있지 않아 죽음을 추적할 수 없으므로 원소로 받지 않습니다. 다른 quad 인스턴스가 `q.Elem`으로 만든 것도 이쪽 기록에는 없어 같은 거부입니다(꼬리 구절이 그 경우를 가리킵니다 — 인스턴스 간 값 섞기는 정의되지 않은 동작). 먼저 [`Claim`](/reference/roblox/04-claim-mapper/)으로 넘겨받거나 `q.Elem`으로 만드세요. Slot이 대신 claim해 주지는 않습니다 — 소유는 언제나 사용자가 명시적으로 시작합니다.
- `Quad0242 Slot: destroyed Slot cannot be an element` — 원소가 파괴된 Slot일 때(`State`가 쥔 값이 파괴된 Slot이면 그 래퍼가 값을 정착시킬 때 같은 문구).

## `q.Slot<<T>>(initial?)`

**시그니처**

```luau
Slot: <T>(initial: { read [number]: SlotElement<T> }?) -> Slot<T>
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `initial` | `{ SlotElement<T> }?` | 초기 원소 배열. `:Add`를 순서대로 부른 것과 같습니다 |

**반환** — 새 `Slot<T>`. 아직 어디에도 마운트되지 않은 상태입니다.

**동작**

- 타입 인자를 안 주면 `q.Slot()`은 `Slot<unknown>`으로 추론됩니다.
strict 모드에서는 `q.Slot<<Instance>>()`처럼 **명시적으로 인스턴스화**하세요.
- `initial`을 주면 — **빈 `Slot{}`이라도** — 그 Slot은 수동 CRUD Slot으로 고정됩니다. 나중에 `:List`를 걸 수 없습니다.
- `initial`은 **평범한 배열**이어야 합니다. 값 하나를 괄호 없이 넘기거나(`Slot(frame)`) 정수가 아닌 키를 섞으면 에러입니다.
  - `Quad0176 Slot: initial elements must be a plain { element, ... } array (got {typeof(initial)} - a bare element or quad value needs the braces)`
  - `Quad0177 Slot: initial elements must be an array - key "{tostring(k)}" is not an array position`
- 원소의 **종류**(마운트 가능한 값인지·quad 소유인지·파괴된 Slot이 아닌지)는 원소를 하나도 넣기 전에 한 번에 검사됩니다 — 이 검사에 걸린 호출은 아무것도 바꾸지 않습니다.
- 같은 원소를 두 번 넣는 것(배열 안의 중복, 이미 이 Slot에 있는 원소를 다시 넣기)과 이미 다른 곳에 마운트된 원소는 그 원소를 자리에 넣는 순간 걸립니다 — `Quad0170 Slot: this element is already in this Slot (a second mount) - reorder with Move/Swap instead of adding it again`(`slot:Add(a); slot:Add(a)`·`Slot { a, a }`·`Replace(i, slot:Get(i))`), `Quad0172 Slot: this element is already mounted - multiple mounts are not allowed …`. 여러 원소를 받는 호출(생성자·`Splice`)이 중간 원소에서 이렇게 던지면 앞 원소는 이미 들어가 있습니다(관측 — 계약 아님). 생성자 `q.Slot({ a, a })`가 둘째 원소에서 던지는 경우 두 점이 더 있습니다(역시 관측 — 계약 아님). 던진 Slot은 손에 돌아오지 않으므로 앞 원소를 되풀 길이 없고, 그 원소를 다시 쓸 수 있게 되는 시점은 GC에 달려 있습니다(그 전에는 다시 넣으면 `Quad0172`, `q.dispose`는 `Quad0179`). [`q.debug`](/reference/core/01-quad-module/#qdebug)가 켜져 있으면 한 호출 안의 중복은 넣기 전에 `Quad0171 Slot: the same element appears twice`로 거부합니다(받은 값 그대로 비교합니다 — `State`의 값은 읽지 않습니다). `Splice`가 같은 호출에서 빼는 원소를 다시 넣는 것은 정상입니다(빼는 쪽이 먼저 풀립니다).
- **`State`에 담긴 원소는 넣을 때 그 값을 읽지 않습니다** — `:List`·`:Single`의 항목과 같이, 래퍼가 그 값을 정착시킬 때(마운트 때, 그 뒤엔 값이 바뀔 때) 위와 같은 검사를 받습니다. 그래서 마운트 전 Slot에 같은 Instance를 쥔 `State` 둘을 넣으면 넣는 줄은 통과하고 마운트 줄에서 `Quad0156`이 납니다(마운트된 Slot이면 그 래퍼가 곧바로 정착하므로 넣는 호출 안에서 납니다). 던진 뒤 그 Slot의 상태는 관측 — 계약 아님입니다(지금은 자식이 빠진 채 남고 그 사슬의 다음 CRUD가 `Quad0167`로 막힙니다).
- 배열 중간의 nil 구멍은 정의되지 않은 동작입니다 — `ipairs`가 거기서 멈추고 뒤는 무시됩니다. [`q.debug`](/reference/core/01-quad-module/#qdebug)를 켜 두면 그 자리에서 멈춥니다 — `Quad0270 Slot: initial elements have a nil hole at index {n} …`(3.3.0부터).

**예제**

```luau
local list = q.Slot<<Instance>>()      -- 빈 Slot(아직 수동/재조정 모드 미정)
local fixed = q.Slot<<Instance>>({     -- 초기 원소 둘, 수동 CRUD Slot으로 고정
    q.Elem "TextLabel" { Text = "A" },
    q.Elem "TextLabel" { Text = "B" },
})

local panel = q.Elem "Frame" { list, fixed }  -- 숫자 키에 놓으면 그 자리가 Slot의 자식 구간이 된다
```

**관련** — [Slot 접두합 트리](/quadnomicon/02-slot-prefix-sum-tree/), [DOMless Slot](/quadnomicon/09-fragment-breakthrough-and-domless-slot/)

## `slot.Length`

**시그니처**

```luau
read Length: State<number>
```

**동작** — 이 Slot이 차지하는 **물리 원소의 총 개수**를 싣는 반응형 `State<number>`입니다 — **읽기 전용**이라 `:Set`이 없습니다(값을 채우는 것은 quad의 부기뿐입니다). 중첩 Slot은 자기 물리 잎의 수만큼 기여하므로, 원소 배열의 길이(`#`)와 항상 같지는 않습니다.

**마운트 전에는 0입니다.** 채워지는 것은 부기(bookkeeping) 재계산이고, 그건 Slot이 실제로 어딘가에 놓인 뒤에 돕니다. 그래서 `:Add` 직후에 `Length:Get()`을 읽으면 아직 0일 수 있습니다. 같은 이유로 **마운트에서 내려온 뒤**(`State<Slot>` 자리에서 다른 Slot으로 갈아 끼워졌거나 `Extract`된 Slot)에는 마지막 마운트 값에 **멈춰** 있고, 그 사이의 `Add`/`Remove`/`Replace`는 다시 마운트될 때 반영됩니다([2026-09-27 mock 관측] — 원소 셋인데 `Length` 2).

`State`이므로 `:Compute`/`:Observer`로 그대로 구독할 수 있습니다.

**예제**

```luau
local slot = q.Slot<<Instance>>()
local empty: q.State<boolean> = slot.Length:Compute(function(self)
    return self:Get() == 0
end)
local view = q.Elem "Frame" { slot, q.Elem "TextLabel" { Text = "비었음", Visible = empty } }
```

**관련** — [State](/reference/core/03-state/), [Slot 접두합 트리](/quadnomicon/02-slot-prefix-sum-tree/)

## `slot.Offset`

**시그니처**

```luau
read Offset: State<number>
```

:::caution
`Offset`을 구독한 콜백(`:Observer`·`Effect`·`Compute`)은 **던지면 안 됩니다.** 이 값은 부모의 자리 부기가 다시 계산되는 창 안에서 `:Set`되므로, 거기서 던지면 그 부모의 부기가 영구히 멈춥니다(`Length`는 그 창 밖에서 발행되므로 이 동결은 없습니다 — 구독 콜백이 던진 뒤 다음 변경에서 다시 맞는 것은 관측일 뿐 계약이 아닙니다) — 이후 에러는 나지 않지만 형제 Slot의 자식이 옛 오프셋에 앉습니다. 던질 수 있는 일은 콜백 밖에서 끝내세요(`updateFn`과 같은 계약).
:::

**동작** — 마운트 대상 안에서 이 Slot의 첫 원소 **앞에 놓인 숫자 키 자리들의 길이 합**(0부터 센 절대 위치 — 앞에 아무것도 없으면 0, 첫 원소는 `Offset + 1`번째; 문자 키 숏핸드가 만든 관리 자식(`UICorner = 8`의 `UICorner`)은 물리 자식이지만 여기 세지 않습니다 — Roblox에서 자식의 물리 순서는 계약이 아닙니다)를 싣는 읽기 전용 `State<number>`입니다. 형제가 앞에서 길이를 바꾸면 이 값이 따라 움직입니다. 앞 형제가 **`State<Slot>` 자리의 교체**로 바뀌면(옛 Slot 철거 → 새 Slot 처리) 이 값은 두 번 통지됩니다 — 한 번은 자리가 비는 순간(0 쪽으로), 한 번은 새 Slot이 앉은 뒤 최종값으로; 같은 길이여도 그렇습니다(수동 `Replace`는 한 번도 안 통지 — [2026-09-27 mock 실측]). `Length`와 짝을 이루어 접두합을 만들고, `:List`/`:Single`의 `updateFn`이 `ctx.Offset`으로 받는 것도 이 State입니다.

**`Offset`/`Length`를 보는 콜백이 Slot을 CRUD해 그 값이 다시 바뀌는 고리**는 수렴할 때 정의된 경로입니다 — 부모의 자리 계산이 바뀐 자리부터 다시 돌아(되감기) 맞춥니다(예: 옆 Slot의 길이에 따라 헤딩·그리드 칸을 넣고 빼기). **수렴하지 않는 고리는 정의되지 않은 동작입니다** — 값마다 넣고 빼기를 뒤집는 콜백처럼 끝나지 않는 고리에 기대지 마세요. 끝나는 모양은 고리에 따라 다를 뿐 둘 다 같은 정의되지 않은 동작입니다: `Offset`을 보는 고리는 되감기라, 무한히 돌지 않도록 한 번의 자리 계산이 **1만 번 넘게 되감으면 늘 켜진 한도가 `Quad0267`로 멈추고** 그 계산을 시작한 줄(CRUD나 `:Set`)에서 던집니다([`q.debug`](/reference/core/01-quad-module/#qdebug)와 무관 — [`Effect`의 지연 재실행 한도](/reference/core/05-observer-effect/#qeffectfn-deps)와 같은 수). `Length`를 보는 고리(자기 Slot의 `Length`를 보는 콜백, 또는 두 Slot이 서로의 `Length`로 상대를 뒤집는 고리)는 되감기가 아니라 자리 계산 안에서 자리 계산이 거듭 중첩되므로 스택 오버플로로 끝납니다. 관측(계약 아님): `Quad0267`이 던진 자리는 위 caution의 창 안이라 그 부모의 부기는 멈춘 채 남습니다.

**`Offset` 콜백이 그 `Offset`을 계산하고 있는 조상 Slot을 떼었다 다시 붙이는 것은 정의되지 않습니다.** 예를 들어 `S { P { I } }`에서 `I.Offset`을 보는 콜백은 `P`의 자리 계산이 도는 도중에 불리므로, 그 콜백이 `P`를 `S`에서 `Extract`한 뒤 다시 `Add`(또는 같은 일을 `Splice`로)하는 것이 여기 해당합니다. 일반형은 "자리 계산이 도는 중인 Slot을 그 계산이 부른 콜백 안에서 다시 붙이는 것"이고, `Length` 콜백도 그 계산 사슬 안에서 불렸다면 같습니다. 같은 콜백 안의 다른 CRUD — 보는 Slot 안의 CRUD, 보는 Slot을 같은 부모 안에서 떼었다 다시 붙이기, 형제 Slot의 CRUD, 조상을 떼기만 하는 것 — 는 위 정의된 고리입니다. 관측(계약 아님): 지금은 다시 붙이는 줄에서 `Quad0109`가 나고 그 뒤 위쪽 Slot의 CRUD가 `Quad0167`로 막힙니다.

Roblox 백엔드는 자식 순서를 물리 속성으로 갖지 않으므로 이 값은 부기용입니다 — 순서가 물리인 백엔드(DOM 등)와 계약을 공유하려고 존재합니다.

**관련** — [Slot 접두합 트리](/quadnomicon/02-slot-prefix-sum-tree/)

## `slot:Add(element, index?)`

**시그니처**

```luau
Add: (self: Slot<T>, element: SlotElement<T>, index: number?) -> number
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `element` | `SlotElement<T>` | 넣을 원소 |
| `index` | `number?` | 삽입 위치(1..n+1). 생략하면 맨 뒤 |

**반환** — 실제로 들어간 인덱스.

**동작**

- 수동 CRUD 진입점이라 이 Slot이 수동 모드로 고정됩니다.
- 삽입 위치는 `n+1`(맨 뒤 다음)까지 허용됩니다. 그 밖은 에러입니다 — `Quad0236 Slot:Add: index out of range (got {index}, limit {limit})`, 정수가 아니면 `Quad0168 Slot:Add: index must be a positive integer (got {tostring(index)})`.
- 이미 다른 곳에 마운트된 값은 거부됩니다(이미 이 Slot에 있는 값이면 `Quad0170` — 순서는 `Move`/`Swap`). 문구 뒤에 붙는 꼬리 안내는 아래 "죽은 Slot과 마운트 규칙" 절의 것과 같습니다.

  ```
  Quad0172 Slot: this element is already mounted - multiple mounts are not allowed (if its owner was destroyed outside quad - `inst:Destroy()` - the value went with it and cannot be reused after its parent is destroyed; extract it before destroying, as with an Instance)
  ```

- Slot을 자기 자신이나 자기 조상에 넣으면 순환이라 거부됩니다 — `Quad0173 Slot:Add: cannot add a Slot to itself or to one of its own descendants (that would be a cycle)`. **[3.3.0부터] 이 검사는 [`q.debug`](/reference/core/01-quad-module/#qdebug)가 켜져 있을 때만 돕니다** — 원소 관계를 따라 올라가는 검사라 넣는 Slot마다 깊이만큼 비용이 듭니다. 꺼 두면 넣는 줄은 통과하고 그 순환은 정의되지 않은 동작입니다 — 관측(계약 아님): 그 순환 트리의 다음 CRUD나 해체가 스택 오버플로나 내부 불변식 에러로 죽고(어느 쪽인지는 연산마다 다릅니다), 그 뒤의 부기 무결은 약속하지 않습니다. **인스턴스를 매개로 한 순환은 거부되지 않습니다(정의되지 않은 동작)** — 이 Slot이 붙어 있는 인스턴스나 그 조상을 원소로 넣는 것(`slot:Add(host)`). quad-base는 인스턴스의 조상 사슬을 모르고, 정적 자식 자리의 같은 검사(`Dispatch: cannot place an Instance inside itself …`)는 백엔드 핸들러가 하는 것입니다. Roblox에서는 엔진이 부모 대입에서 던지는데 그때는 Slot 부기가 이미 끝난 뒤라 그 원소가 자리에 끼인 채 남습니다. **[3.3.0부터]** 엔진 호출 안에서 던진 것이라 그 Slot은 이후의 CRUD를 `Quad0167`로 거부합니다(관측 — 계약 아님; 전에는 `slot:Extract(그 자리)`로 자리를 비울 수 있었습니다) — 그 Slot은 버리세요. `Splice`로 넣은 경우는 배치 창 안에서 던진 것이라 그 Slot의 `Length`도 더는 갱신되지 않습니다(위 `:Clear` 캐비엇과 같은 동결).
- **`State`를 거친 순환도 거부되지 않습니다(정의되지 않은 동작)** — 직접 넣는 순환(위 `Quad0173`, `q.debug`일 때)만 넣는 시점에 거부하고, 다른 것을 거친 순환은 위 인스턴스 매개 순환과 같이 정의되지 않습니다. 두 모양이 있습니다. (1) `State` 값을 거친 Slot 순환 — `st`를 넣어 둔 Slot이나 그 조상 Slot을 `st:Set(...)`으로 `st`의 값에 넣거나, 아직 마운트되지 않은 `outer`에 `st`를 넣고 `st:Set(inner)` 뒤 `inner:Add(outer)`처럼 엮는 것. (2) 값이 `nil`인 같은 `State`를 두 자리에 넣는 것 — 값이 있었다면 마운트 때 `Quad0156`으로 드러났을 경우입니다. 둘 다 마운트나 다음 `:Set` 때 `Quad0156`/`Quad0173`으로 드러나고, 그때 걸린 Slot은 이후 CRUD가 `Quad0167`로 막히는 채 남을 수 있습니다. 넣는 시점에 이것까지 잡으려면 원소마다 아래 방향 탐색이 필요해 평범한 `Add`가 크게 느려지므로 막지 않습니다. 예외 하나 — **값 사슬이 자기에게 돌아오는 `State`**(`st:Set(st)`, `a`가 `b`를, `b`가 `a`를 담는 것)는 [`q.debug`](/reference/core/01-quad-module/#qdebug)가 켜져 있으면 원소 경로에서도 `Quad0070 State: the value chain is circular …`로 거부합니다 — Slot이 그 값을 읽는 때, 곧 마운트될 때(이미 마운트된 Slot이면 넣는 줄 — `Add` 등)나 그 `:Set` 줄에서 던지고(**[3.3.0부터]** 마운트 전 Slot에 넣는 줄에선 값을 읽지 않으므로 debug에서도 던지지 않습니다), 그 Slot은 이전 원소를 보인 채 다음 `:Set`에서 회복합니다(관측 — 계약 아님). debug를 꺼 두면 이 검사도 하지 않습니다 — 그런 순환은 스택 오버플로로 끝나는 정의되지 않은 동작입니다.
- quad가 소유하지 않은(claim되지 않은) 인스턴스는 거부됩니다 — 위 "원소 대수" 절의 `Quad0241 Slot: this element is not claimed by quad …`. 생성자 `initial`·`:Replace`·`:Splice`·`:List`/`:Single`의 새 원소도 같은 검사를 지납니다.
- 마운트된 Slot의 단일 변경(`Add`·`Remove`·`Replace`·`Move`·`Swap`·`Extract`)은 현재 길이에 비례하는 부기 비용을 냅니다 — `Move`/`Swap`은 Roblox에서 물리 이동이 없을 뿐 자리 계산은 전량 돕니다. 여러 개를 한 번에 넣거나 뺄 때는 [`:Splice`](#slotspliceindex-removecount-newelements)를 쓰세요(한 호출에 여럿이 배치이고, 한 개씩 반복 호출은 배치가 아닙니다 — 다만 `:Splice`의 배치는 **recompute와 물리 op**가 한 번이라는 뜻이고, 인덱스 부기는 넣는 원소마다 뒤쪽을 한 번씩 밀어 k개를 앞에 넣으면 k·(남은 길이)만큼 듭니다 — N=4000 앞에 100개 25ms 안팎, mock CLI). `:List`의 한 사이클도 바뀐 항목 수와 무관하게 전체 항목 수에 비례합니다.

**예제**

```luau
local slot = q.Slot<<Instance>>()
slot:Add(q.Elem "TextLabel" { Text = "끝에" })
slot:Add(q.Elem "TextLabel" { Text = "앞에" }, 1)
local root = q.Elem "Frame" { slot }
```

## `slot:Remove(index)`

**시그니처**

```luau
Remove: (self: Slot<T>, index: number) -> ()
```

**동작** — 그 자리의 원소를 떼고 **파괴합니다**(`State`에 담아 넣은 원소는 예외 — 아래 "State에 담은 원소" 참고). 살려서 꺼내려면 [`:Extract`](#slotextractindex-newelement)를 쓰세요. 범위는 1..n이고 클램프는 없습니다.

## `slot:Replace(index, newElement)`

**시그니처**

```luau
Replace: (self: Slot<T>, index: number, newElement: SlotElement<T>) -> ()
```

**동작** — 같은 자리를 새 원소로 바꾸고 **옛 원소를 파괴합니다**. 옛 원소를 살려 받고 싶으면 `Extract(index, newElement)`가 그 쌍입니다.

## `slot:Extract(index, newElement?)`

**시그니처**

```luau
Extract: (self: Slot<T>, index: number, newElement: SlotElement<T>?) -> SlotItem<T>
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `index` | `number` | 꺼낼 자리(1..n) |
| `newElement` | `SlotElement<T>?` | 주면 그 자리를 이 원소로 채웁니다. 생략하면 자리 자체가 사라집니다 |

**반환** — 꺼낸 원소. **언래핑된 원래 값**입니다(State를 넣었으면 그 State가 나옵니다).

**동작** — 파괴하지 않는 제거입니다. 꺼낸 값은 소유권이 풀려 다른 Slot에 다시 넣거나 `q.dispose`로 직접 지울 수 있습니다.

**예제**

```luau
local slot = q.Slot<<Instance>>({ q.Elem "Frame" {}, q.Elem "Frame" {} })
local taken = slot:Extract(1)          -- 살아 있는 채로 빠져나온다
local other = q.Slot<<Instance>>()
other:Add(taken)                       -- 다른 Slot으로 이사
```

**관련** — [비파괴 포털과 소유권](/quadnomicon/05-non-destructive-portal-and-ownership/)

## `slot:ExtractAll()`

**시그니처**

```luau
ExtractAll: (self: Slot<T>) -> { SlotItem<T> }
```

**반환** — 원소 전부를 순서대로 담은 배열(언래핑된 원래 값).

**동작** — 전부를 **살린 채로** 비웁니다. 재계산은 한 번만 돕니다 — 원소마다 `:Extract`를 부르는 것보다 훨씬 쌉니다.

## `slot:Splice(index, removeCount, ...newElements)`

**시그니처**

```luau
Splice: (self: Slot<T>, index: number, removeCount: number, ...SlotElement<T>) -> { SlotItem<T> }
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `index` | `number` | 시작 위치(1..n+1) |
| `removeCount` | `number` | 살려서 꺼낼 개수. 실제로 있는 만큼만 허용 — 클램프 없음 |
| `...newElements` | `SlotElement<T>` | 그 자리에 끼워 넣을 원소들 |

**반환** — 꺼낸 원소들의 배열(살아 있음, 언래핑됨).

**동작** — 구간 제거와 삽입을 **한 번의 재계산**으로 처리합니다. 여러 원소를 한꺼번에 넣는 정본 경로입니다. `removeCount`가 남은 개수를 넘으면 `Quad0174 Slot:Splice: removeCount out of range`.

**예제**

```luau
local slot = q.Slot<<Instance>>({ q.Elem "Frame" {}, q.Elem "Frame" {}, q.Elem "Frame" {} })
local removed = slot:Splice(2, 1, q.Elem "Frame" {}, q.Elem "Frame" {}) -- 2번을 빼고 그 자리에 둘을 넣는다
-- removed[1] 은 살아 있는 채로 손에 들어온다
```

## `slot:Clear()`

**시그니처**

```luau
Clear: (self: Slot<T>) -> ()
```

**동작** — 원소 전부를 **파괴하며** 비웁니다(`ExtractAll`의 파괴판). 재계산은 한 번뿐입니다.

⚠️ 이 창(window) 안에서 사용자 정리 코드가 던지면 그 Slot의 배치가 그대로 얼어붙습니다 — 던지는 정리 콜백은 쓰지 마세요.

## `slot:Move(oldIndex, newIndex)`

**시그니처**

```luau
Move: (self: Slot<T>, oldIndex: number, newIndex: number) -> ()
```

**동작** — 위치만 바꿉니다. 소유권 변화도, 파괴도 없습니다. 두 인덱스 모두 1..n이어야 합니다.

Roblox 백엔드에서는 이것으로 **화면에 보이는 순서가 바뀌지 않습니다.** 자식의 물리 순서가 의미를 갖지 않아 재정렬 op(`nativeMove`)가 의도된 no-op이고, 바뀌는 것은 quad의 부기뿐입니다 — 이 Slot 안의 인덱스, `slot:Get`/`slot:IndexOf`, 이후 삽입 위치, 그리고 그 구간에 걸린 중첩 `Slot`의 `Offset`이 새 순서를 따릅니다. 보이는 순서는 `LayoutOrder`(또는 직접 계산한 `Position`)가 정하니 그쪽을 같이 바꿔야 합니다.

## `slot:Swap(indexA, indexB)`

**시그니처**

```luau
Swap: (self: Slot<T>, indexA: number, indexB: number) -> ()
```

**동작** — 두 자리를 맞바꿉니다. 같은 인덱스를 두 번 주면 아무 일도 하지 않습니다.

`:Move`와 마찬가지로 Roblox 백엔드에서는 화면 순서가 바뀌지 않습니다 — `nativeSwap`도 의도된 no-op이라 부기상의 순서만 맞바뀌고, 보이는 순서는 `LayoutOrder`가 정합니다.

## `slot:Get(index)`

**시그니처**

```luau
Get: (self: Slot<T>, index: number) -> SlotItem<T>?
```

**반환** — 그 자리의 원소(언래핑됨). 범위 밖이면 `nil`.

**동작** — 읽기 전용이라 수동/재조정 모드를 고정하지 않습니다. 다만 인덱스가 숫자가 아니면 "빈 Slot"처럼 조용히 `nil`을 주지 않고 던집니다 — `Quad0175 Slot:Get: index must be a number (got {typeof(index)})`.

## `slot:IndexOf(element)`

**시그니처**

```luau
IndexOf: (self: Slot<T>, element: SlotElement<T>) -> number?
```

**반환** — 그 원소가 있는 인덱스, 없으면 `nil`.

**동작** — 원시 원소는 역맵으로 바로 찾고, State로 감싼 원소는 언래핑 비교로 찾습니다. `Extract`에 넘길 인덱스를 구할 때 씁니다.

## `slot:WhenIdle(fn)`

**시그니처**

```luau
WhenIdle: (self: Slot<T>, fn: (slot: Slot<T>) -> ()) -> ()
```

**인자** — `fn`: 이 Slot을 인자로 받는 함수. **반환** — 없음.

**동작** — 이 Slot이 **연산 한가운데가 아니면 `fn(slot)`을 바로 실행하고**(반환 전에), 연산 한가운데면 **그 연산이 끝난 직후에** 실행합니다. "연산 한가운데"는 [`Quad0167`](/reference/errors/03-slot/#quad0167)이 CRUD를 거부하는 바로 그 구간입니다 — 이 Slot(또는 그 안의 Slot)이 마운트되는 중, 이 Slot이나 **그 안의 Slot**에서 원소를 붙이거나 떼는 엔진 호출이 도는 중, 파괴되는 중. 그래서 자식 Slot의 연산 도중 조상 Slot에 건 요청은 자식의 연산이 끝난 직후(자식의 `Length`가 갱신된 뒤)에 실행됩니다. 그 구간 안에서 불린 콜백(`q.OnDestroyed`, `q.OnChange "Frame" "Parent" (…)`, 마운트 중에 발화한 `Observer`)이 이 Slot을 고쳐야 할 때 쓰는 문입니다.

```luau
-- 팝업 하나가 닫힐 때 딸린 팝업도 같은 Slot에서 뺀다
q.OnDestroyed(function()
    overlaySlot:WhenIdle(function(slot)
        local index = slot:IndexOf(childPopup)   -- index는 실행되는 시점에 구한다
        if index then
            slot:Remove(index)
        end
    end)
end)
```

- **신호 설정과 무관하게 같은 코드입니다.** Deferred에서는 콜백이 이미 연산 뒤에 불리므로 `fn`이 바로 돌고, Immediate와 테스트 mock에서는 연산이 끝난 직후에 돕니다. 엔진의 스케줄러(`task.defer`)를 쓰지 않으므로 다음 재개 지점까지 밀리지 않습니다 — 바깥 연산(`slot:Remove(…)` 등)이 반환할 때는 `fn`이 이미 실행된 뒤입니다.
- **index를 미리 구해 두지 마세요.** quad는 거부된 CRUD를 대신 미뤄 주지 않습니다 — 부른 시점의 index는 연산이 끝나면 틀려 있을 수 있기 때문입니다. `fn` 안에서 `slot:IndexOf(element)`로 다시 구하세요.
- **요청은 한 순서로 실행됩니다** — 먼저 건 것이 먼저. `fn`이 다시 `WhenIdle`을 부르면 그때는 Slot이 한가하므로 바로 실행됩니다.
- **파괴된 Slot은 한가한 것으로 칩니다.** 파괴되는 도중에 건 요청은 파괴가 끝난 뒤 실행되고, 이미 파괴된 Slot에 건 요청은 바로 실행됩니다 — `fn` 안에서 그 Slot을 CRUD하면 평소의 파괴된 Slot 에러(`Quad0165`)가 납니다.
- **`:List`/`:Single` Slot에도 쓸 수 있습니다.** 그 Slot은 CRUD를 받지 않으므로 `fn`이 할 일은 데이터 `State`를 바꾸는 것입니다(재조정이 끝난 직후에 실행됩니다).
- **`fn`이 던지면** 그 예외는 그 요청을 실행한 연산의 호출자에게 전파됩니다(바깥 연산 자체는 이미 끝난 뒤이고, 남은 요청은 다음 연산이 끝날 때 실행됩니다). 연산이 도중에 던져 `Quad0167`로 막힌 Slot에 걸려 있던 요청은 그 Slot이 파괴될 때까지 실행되지 않습니다 — quad는 예외를 감싸지 않습니다.
- `fn`이 함수가 아니면 `Quad0268 Slot:WhenIdle: fn must be a function (got {typeof(fn)})`.

## `slot:List(data, updateFn, keyFn?, opts?)`

`opts`의 모르는 키(옛 `Owned` 등)는 조용히 무시됩니다(`:Single`도 같음). `q.debug = true`면 모르는 옵션 키(오타·옛 이름)를 한 줄로 알려 줍니다 — 정본은 [`q.debug`](/reference/core/01-quad-module/#qdebug).

**시그니처**

```luau
List: <Item, UD>(
    self: Slot<T>,
    data: { Item } | StateMarker<{ Item }>,
    updateFn: (ctx: { Item: Item | KeyGone, Index: number, Offset: State<number>, Prev: SlotItem<T>?, UserData: UD? }) -> (any, UD?),
    keyFn: ((item: Item, index: number) -> any)?,
    opts: SlotListOpts?
) -> Slot<T>

type SlotListOpts = { read OwnsElements: boolean? }
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `data` | `{ Item }` 또는 그걸 담은 State | 재조정의 원본. State면 값이 바뀔 때마다 다시 돕니다. 항목 자체가 `q.KeyGone`이면 `Quad0260`입니다 — `KeyGone`은 `updateFn`이 받는 표시지 데이터 값이 아닙니다 |
| `updateFn` | 함수 | 항목 하나를 어떻게 만들/유지/버릴지 결정합니다(아래 계약) |
| `keyFn` | `((item, index) -> any)?` | 항목의 신원. 기본값은 **인덱스**입니다. 같은 항목에는 사이클마다 **같은 키**를 돌려줘야 합니다(아래 "동작") |
| `opts` | `{ read OwnsElements: boolean? }?` | `OwnsElements = false`면 이 Slot이 원소를 파괴하지 않습니다. 불리언이 아닌 값(`"false"`, `0`)은 `Quad0259`로 거부합니다 |

**반환** — `self`(체이닝용).

**`updateFn` 계약**

호출 시그니처는 `updateFn(ctx) -> (result, userdata)`입니다. `ctx`는 필드 다섯을 담은 테이블 하나이고, **호출마다 새로 만들어집니다** — `updateFn` 안에서 만든 클로저(`:Compute` 콜백, 이벤트 콜백)가 `ctx`를 붙잡아 나중에 읽어도 다음 호출의 값으로 바뀌지 않습니다.

| 필드 | 뜻 |
|---|---|
| `ctx.Item` | 이번 사이클의 데이터 항목. 지난 사이클에 있었는데 이번엔 사라진 키에는 `q.KeyGone`이 옵니다 |
| `ctx.Index` | 이 Slot 안에서의 물리 위치(`Offset` 기준 1부터). 중첩 Slot이 섞여 있으면 데이터 배열의 인덱스와 다릅니다. `KeyGone` 호출에서는 `0`입니다 |
| `ctx.Offset` | 이 Slot의 `Offset` State 자체 — 값이 아니라 핸들입니다. 여기에 `:Observer`를 만들었다면 원소의 숫자 키 자리에 묶거나 `:Subscribe()` 해야 계속 발화합니다 — 만들기만 하면 처음 한 번 돌고 그 뒤로는 불리지 않습니다([2026-09-27 mock 실측]; Observer 일반 규칙 — [핸들은 두 가지로 살아난다](/reference/core/05-observer-effect/#핸들은-두-가지로-살아난다)) |
| `ctx.Prev` | 이 키가 지난번에 만든 원소(언래핑됨). 처음이면 `nil` |
| `ctx.UserData` | 지난 호출이 두 번째로 반환한 값. 키마다 따로 보관됩니다 |

반환값은 `(result, userdata)` 둘입니다. `result`의 뜻은 넷입니다.

| 반환 | 뜻 |
|---|---|
| 새 원소 | 그 자리에 놓습니다. `ctx.Prev`가 있었으면 교체(소유 Slot이면 옛 원소 파괴) |
| `ctx.Prev` 그대로 | 그대로 유지 — 다시 만들지 않습니다. 위치만 필요하면 옮깁니다 |
| `nil` 또는 `q.None` | 이 키를 버립니다(소유 Slot이면 파괴) |
| `q.Detach` | 트리에서 떼되 **파괴하지 않고** 보관합니다. 다음에 `ctx.Prev`를 반환하면 그대로 다시 붙습니다(`OwnsElements = false`면 보관이 아니라 해제 — 아래 옵션 절) |

두 번째 반환값은 이 키의 다음 `ctx.UserData`가 됩니다. `KeyGone` 호출에서 돌려준 두 번째 값도 그대로 이 키에 남습니다 — 같은 키가 나중에 다시 나타나면 `Prev = nil`·`UserData = <그 값>`으로 오고, 다시 오지 않는 키라면 그 값은 이 `:List`가 사는 동안 계속 붙잡혀 있습니다([2026-09-27 mock 실측]). 버리는 키에서는 두 번째 값을 돌려주지 마세요.

`updateFn`은 항목 하나를 원소로 바꾸는 함수입니다 — 자기가 만드는 자식 Slot을 채우는 것은 되지만, **이 Slot의 조상을 CRUD하면 안 됩니다.** 첫 `updateFn`은 이 Slot이 트리에 붙는 순간(부모와 함께 마운트될 때, 또는 이미 마운트된 부모에 `Add`/`Splice`/`Replace`로 들어갈 때) 그 부모들의 마운트 작업 안에서 불리므로 그 자리에서 던집니다(아래 문구) — 바로 위 부모만이 아니라 맨 위까지의 조상 Slot 전부가 막힙니다. 조상을 바꿔야 하면 **마운트가 끝난 뒤, `updateFn` 밖에서** 하세요. 마운트 중에 동기로 발화하는 `Observer`(그 안에서 만든 `Observer`의 첫 발화, 마운트가 바꾼 `Length`/`Offset`을 보는 `Observer` 등)도 같은 창 안이라 같은 에러입니다 — 그 안에서 시작해야 하는 일이면 [`slot:WhenIdle(fn)`](#slotwhenidlefn)에 넘기세요(그 Slot의 연산이 끝난 직후에 실행됩니다). 이 창 안에서 무엇이든 던지면(위 에러 포함) **그 Slot부터 맨 위 조상 Slot까지** 이후의 CRUD가 모두 `Quad0167`로 거부됩니다 — 사용자 코드의 예외를 복구하지 않는 계약이라, 그 트리는 호스트 Instance를 `q.dispose`하고 다시 만드세요. **원소를 붙이거나 떼는 엔진 호출 안에서 동기로 불리는 신호 콜백**도 같은 규칙입니다([3.3.0부터]) — Roblox에서 `SignalBehavior`가 Immediate이면 원소의 `Parent` 변경 신호(`q.OnChange "Frame" "Parent" (fn)`)가 `Add`/`Remove`/`Replace`/`Splice`나 마운트의 엔진 호출 안에서 불리는데, 그 콜백이 **그 연산이 진행 중인 Slot이나 그 조상 Slot**을 CRUD하면 같은 `Quad0167`입니다(그 연산은 끝까지 마쳐지고, 막힌 것은 콜백의 CRUD뿐; 조상까지인 것은 자식의 `Length`가 엔진 호출 뒤에 갱신되어 그 사이 조상의 자리 계산이 낡은 값을 쓰기 때문). 전에는 조용히 부기가 어긋났습니다(`Length`가 틀리거나 다른 원소가 빠짐). Deferred(새 경험의 기본)에서는 콜백이 연산 뒤에 불리므로 해당 없습니다 — 두 설정(과 테스트 mock)에서 같은 코드가 되게 하려면 그 CRUD를 [`slot:WhenIdle(fn)`](#slotwhenidlefn)에 넘기세요. 같은 부모 아래의 형제 Slot·무관한 Slot의 CRUD와, 언마운트 도중의 콜백(이미 떼어진 Slot을 봅니다)은 막지 않습니다. 또 **한 Slot의 `Length`가 자기 앞 자리의 길이에 다시 영향을 주는 고리**(길이 `State`의 Compute가 뒤 Slot의 `Length`/`Offset`을 읽는 모양)는 자기 상류를 되먹이는 고리라 정의되지 않은 동작이고, 방어하지 않습니다 — 관측(계약 아님): 지금은 수렴하면 고정점에 닿지만, 발산하면 번호 없는 스택 오버플로로 끝나고 그 Slot은 이후 CRUD에 `Quad0167`을 냅니다([2026-09-27 mock 실측]; 무한 루프 방어를 두지 않는 것은 설계 결정).

```
Quad0167 Slot: cannot mutate a Slot while it is being mounted or while one of its elements is being inserted/removed (it, or a Slot inside it, is mid-operation) - a :List/:Single updateFn, an Observer that fires during that mount, or a backend signal callback that runs synchronously inside the insert/remove (an element's parent changed) must not CRUD this Slot or an ancestor Slot; run it through slot:WhenIdle(fn) - fn runs as soon as the operation has finished (or an earlier operation on this Slot or a Slot inside it threw mid-way - then this Slot stays unusable: dispose its host Instance)
```

**동작**

- `:List`는 **설치**입니다. 한 Slot에 한 번만 걸 수 있고, 수동 CRUD를 이미 쓴 Slot(빈 `Slot{}` 포함)에는 걸 수 없습니다.
- 데이터 배열 중간의 `nil` 구멍은 **정의되지 않은 동작**입니다 — `initial`과 같은 이유로 `ipairs`가 거기서 멈추고, 구멍 뒤에 아직 있는 항목의 원소까지 `KeyGone` 경로로 **파괴**됩니다(`{"a","b","c"}` → `{"a", nil, "c"}`를 `:Set`하면 Length 1, `"c"`의 원소 파괴 — [2026-09-27 mock 관측 — 계약 아님]). 항목을 빼려면 `table.remove`로 배열을 다시 채우세요. [`q.debug`](/reference/core/01-quad-module/#qdebug)를 켜 두면 재조정이 아무것도 파괴하기 전에 멈춥니다 — `Quad0269 Slot:List: data has a nil hole at index {n} …`(3.3.0부터; 평소 경로에서는 검사하지 않습니다 — 재조정마다 배열을 한 번 더 훑어야 해서).
  - `Quad0148 Slot: already has :List/:Single/:Lazy installed`
  - `Quad0149 Slot: cannot install :List/:Single/:Lazy on a manual Slot (one that used CRUD or was built as Slot{ ... }, even empty)`
  - 반대로 `:List`를 건 뒤의 수동 CRUD는 `Quad0166 Slot: manual CRUD is not allowed after :List/:Single/:Lazy`.
- 재조정은 마운트 시점과 이후 `data`가 바뀔 때마다 돕니다. 한 사이클은 **하나의 배치**로 묶여 재계산이 한 번만 일어납니다.
- 사이클마다 먼저 데이터 순서대로 키를 계산해 중복/누락을 검사하고(여기서 걸리면 아무 `updateFn`도 불리지 않습니다), 그 뒤 데이터의 항목마다 `updateFn`을, 지난 사이클에 있었지만 이번엔 없는 키마다 `q.KeyGone`으로 `updateFn`을 한 번씩 부릅니다. **이 호출들이 어떤 순서로 오는지는 정해져 있지 않습니다** — 항목끼리, 사라진 키끼리, 항목과 사라진 키 사이 모두(**[3.3.0부터]** 3.2.0까지는 "항목 먼저, 사라진 키 나중"을 적어 두었습니다). `updateFn`은 자기 키의 항목만 보고 원소를 돌려주세요 — 다른 키의 `updateFn`이 먼저 불렸는지에 기대는 코드(바깥 상태를 호출 순서대로 쌓기 등)는 정의되지 않습니다. 전부 한 배치 안이라 화면에는 사이클이 끝난 모습만 나옵니다.
- `KeyGone` 호출에서는 `nil`/`q.None`(파괴)과 `q.Detach`(보관)만 반환할 수 있습니다. 새 원소를 반환하면 `Quad0147 Slot:List: KeyGone accepts only nil/None (destroy) or Detach (hold)`.
- 인자 검증 에러: `Quad0150 Slot:List: updateFn must be a function (got {typeof(updateFn)})`, `Quad0151 Slot:List: data must be a plain array or a State of one (got {typeof(data)})`, `Quad0152 Slot:List: keyFn must be a function (got {typeof(keyFn)})`.
- 키 비교는 Luau 테이블 키 규칙 그대로입니다 — `0`과 `-0`은 같은 키이고, `1`과 `"1"`은 다른 키입니다.
- `keyFn`은 **안정적**이어야 합니다. 같은 항목에 사이클마다 다른 키를 돌려주면(매번 새 테이블, 난수 등) 에러는 나지 않지만 매 사이클 모든 원소가 새로 만들어지고 옛 원소는 전부 `KeyGone`으로 버려집니다([2026-09-27 mock 실측]).
- **원소를 다른 키로 옮기는 경로는 없습니다** — 키가 곧 신원이라, 키가 바뀐 항목은 새 원소를 만들어야 합니다. 같은 사이클 안에서 다른 키(사라진 키 포함)의 원소나 그 원소를 모는 `State`를 돌려주는 것은 위 호출 순서에 따라 결과가 갈리므로 **정의되지 않은 동작**입니다. 관측(계약 아님, [2026-10-15 mock]): 지금은 사라진 키를 먼저 처리하므로, 사라진 키의 `KeyGone`이 `nil`을 돌려줘 그 원소가 파괴된 뒤라면 그 원소를 감싸던 `State`는 새 키에서 다시 쓸 수 있고, `OwnsElements = true`의 `q.Detach`로 보관 중인 원소는 여전히 이 Slot 것이라 `Quad0156`입니다(문구는 "already mounted"지만 보관 중인 원소도 여기 걸립니다); 두 키가 다 남은 채 원소를 맞바꾸면 먼저 불린 쪽이 아직 다른 키의 것을 돌려주게 되어 `Quad0156`입니다. `OwnsElements = false`에서는 `Detach`가 보관이 아니라 해제라, 떼어 둔 원소를 다른 키가 반환하면 옮겨집니다.
- `keyFn`이 이후 사이클에서 던진 뒤의 상태도 계약이 아닙니다 — 관측으로는 게이트를 켜기 전이라 아무것도 바뀌지 않고 다음 `data:Set`에서 회복됐습니다([2026-09-27 mock 실측] — 첫 사이클이면 아래 `updateFn` 항목과 같습니다).
- 재조정 중 에러: `Quad0142 Slot:List: data must be a plain array (got {typeof(items)}) - a data State must hold one too`, `Quad0143 Slot:List: data must be a plain array - key "{k}" is not an array position`(배열 부분이 비어 있는데 다른 키가 있을 때 — 아이디 맵·JSON 오브젝트; **[3.3.0부터]** 배열에 덧붙은 키까지 보는 전수 검사는 [`q.debug`](/reference/core/01-quad-module/#qdebug)일 때만이고, 꺼져 있으면 덧붙은 키는 무시됩니다), `Quad0144 Slot:List: keyFn returned nil for item #{i}`(NaN도 같은 모양으로 `returned NaN`), `Quad0145 Slot:List: duplicate key {tostring(key)}`. 인자 검증에 `Quad0153 Slot:List: opts must be a table (got {typeof(opts)})`(`:Single`도 같음)이 더해집니다.
- `updateFn`이 이 Slot의 `data` State를 다시 `:Set` 하는 **재진입**은 정의되지 않은 동작입니다 — 첫 재조정이든 그 뒤든 같습니다. `updateFn`은 항목 하나로 원소(컴포넌트)를 만드는 자리이고, 자기가 만든 것 밖의 State를 바꾸는 곳이 아닙니다. `updateFn`이 만든 원소의 `OnChange`가 Immediate 시그널에서 초기값으로 동기 발화해 `data`를 `:Set`하는 경우도 마찬가지로 정의되지 않습니다 — 지금은 첫 재조정 안에서라면 `Observer` 첫 발화 규칙([05-observer-effect](/reference/core/05-observer-effect/))의 귀결로 그 재조정이 끝난 뒤 새 데이터로 한 번 더 재조정되는 것이 관측되지만([2026-09-30 mock 실측]), 보장하는 동작은 아닙니다.
- `updateFn`이 도중에 던진 뒤의 상태는 정의되지 않은 동작입니다(이미 다른 곳에 마운트된 원소나 claim되지 않은 Instance를 반환해 quad가 대신 던지는 경우 포함). 아래는 관측이지 계약이 아닙니다 — 그 사이클의 배치가 닫히지 않아 **그 Slot의 `Length`가 더 이상 발행되지 않습니다** — **이후 사이클**이라면 재조정 자체는 계속 돌아 항목이 붙고 떨어지지만(**첫 사이클**, 즉 첫 재조정(`:List`를 부르는 그 호출 안, 또는 `q.Elem "Frame"{ q.Slot():List(...) }`처럼 마운트 때 처음 도는 경우)에서 던지면 데이터 구독이 살아나기 전에 던진 것이라 그 뒤의 `data:Set`이 전부 조용히 무시됩니다 — 위 재조정 중 에러 `Quad0142`~`0146`도 첫 사이클이면 같습니다 — [2026-09-27 mock 관측 — 계약 아님]; `:List`를 다시 걸 수도 없으니 그 Slot은 버리세요), 같은 부모 안의 형제 Slot이 옛 오프셋에 자식을 넣게 되고 에러는 나지 않습니다. 사용자 코드의 예외를 감싸 복구하지 않는 계약이라 [`slot:Clear`](#slotclear)와 같이 정의되지 않은 동작으로 둡니다 — 던질 수 있는 일은 `updateFn` 밖에서 끝내세요. 이 항목에는 두 경우가 더 포함됩니다 — `updateFn`이 마운트할 수 없는 값을 담은 `State`(`q.Source({})` 등)를 돌려주면 그 `State`를 감싼 자리가 먼저 들어간 뒤 `Quad0240`으로 던져, 그 자리가 이후 `KeyGone`으로도 빠지지 않고 남습니다(원시 값을 바로 돌려줬다면 넣기 전에 던집니다). 그리고 첫 사이클의 quad 자체 검사(`Quad0142`~`0146`)가 던진 뒤 그 Slot이 데이터 변경에 반응하지 않는 것도 같은 정의되지 않은 동작입니다.

**`OwnsElements = false`**

**State에 담은 원소는 파괴되지 않습니다.** `slot:Add(q.Source(frame))`처럼 `State`로 넣은 원소는 그 State가 주인이라, `Remove`·`Replace`·`Clear`·`:List`의 키 소멸·`q.dispose(slot)` 어느 경로로 버려도 인스턴스는 살아남고 자리에서만 내려옵니다(`Parent = nil`, 소유권 해제 — 다른 Slot에 다시 넣을 수 있습니다). 화면을 철거할 때 그 인스턴스까지 없애려면 그 State를 `q.dispose`하거나 값을 `q.None`으로 바꾸고 인스턴스를 직접 `q.dispose`하세요. `State<Slot>`(리스트 안 포털)도 같습니다.

기본은 소유(`OwnsElements = true`)입니다 — 이 Slot이 버리는 원소는 파괴됩니다. `OwnsElements = false`를 주면 버릴 때 소유권만 풀고 살려둡니다. 그 Slot 자체를 버릴 때도 같습니다 — `q.dispose(slot)`하거나 소유하는 부모 Slot이 이 Slot을 `Remove`/`Clear`로 파괴하면, 이 Slot은 쥐고 있던 원소 전부의 소유권을 놓고 **빈 채로** 살아남습니다(파괴되지 않고 다시 쓸 수 있으며, 다음 마운트에서 data로부터 처음부터 다시 조정합니다). 원소는 살아남아 다른 Slot에 다시 넣거나 `q.dispose`할 수 있습니다. 반면 부모에서 `Extract`로 빼는 것은 파괴가 아니라서 이 Slot은 원소를 **쥔 채** 떨어져 나오고, 그대로 다른 Slot에 넣으면 원소째 옮겨갑니다. 원소를 밖에서 관리하는 가상화 목록이나 포털이 이 옵션의 자리입니다. 단, Slot이 **마운트된 채로 그 부모 Instance가 파괴되면** 엔진이 자손을 지우므로 원소도 같이 죽습니다 — 화면을 철거할 때 살려야 할 원소는 먼저 `:Extract`하거나 data에서 키를 빼세요. 그래도 원소는 quad 소유(`q.Elem`으로 만들었거나 `Claim`으로 넘겨받은 것)여야 합니다 — 이 옵션은 파괴 여부만 바꾸고, 위 "원소 대수"의 미claim 거부는 그대로 적용됩니다.

**예제**

`--!strict`에서는 `updateFn`의 **`ctx` 파라미터와 반환 팩**에 주석을 달아야 합니다 — 반환이 갈래마다 다른 타입이라, 주석이 없으면 첫 `return`에서 반환 타입이 굳어 나머지 갈래가 거부됩니다. `ctx` 타입이 길면 파일 안에 별칭을 하나 두면 됩니다.

```luau
type Row = { Id: string, Title: string }
type RowCtx = {
    Item: Row | QuadTypes.KeyGone,
    Index: number,
    Offset: QuadTypes.State<number>,
    Prev: QuadTypes.SlotItem<Instance>?,
    UserData: nil,
}

local rows = q.Source<<{ Row }>>({ { Id = "a", Title = "첫째" } })
local slot = q.Slot<<Instance>>()

slot:List(rows, function(ctx: RowCtx): (any, nil)
    if ctx.Item == q.KeyGone then
        return nil            -- 사라진 키: 파괴
    end
    if ctx.Prev then
        return ctx.Prev       -- 이미 있는 키: 그대로 둔다
    end
    return q.Elem "TextLabel" { Text = (ctx.Item :: Row).Title }
end, function(item: Row)
    return item.Id            -- 신원은 Id
end)

local view = q.Elem "Frame" { slot }
rows:Set({ { Id = "b", Title = "둘째" }, { Id = "a", Title = "첫째" } }) -- a는 재사용, b는 새로 생성
```

`userdata`를 쓴다면 `ctx` 타입의 `UserData` 필드와 반환 팩의 두 번째 자리에 그 타입을 적습니다 — `UserData: RowUD?` / `: (any, RowUD?)`.

**관련** — [가상화 무한 스크롤](/how-to/03-long-lists-and-windowing/), [DOMless Slot](/quadnomicon/09-fragment-breakthrough-and-domless-slot/)

## `slot:Single(state, updateFn?, opts?)`

**시그니처**

```luau
Single: <Item, UD>(
    self: Slot<T>,
    state: Item? | StateMarker<Item?>,
    updateFn: ((ctx: { Item: Item | KeyGone, Index: number, Offset: State<number>, Prev: SlotItem<T>?, UserData: UD? }) -> (any, UD?))?,
    opts: SlotListOpts?
) -> Slot<T>
```

타입 인자는 `:List`와 같은 `<Item, UD>`입니다 — `state`가 담는 것은 **데이터**(`Item`)이고, 원소 타입 `T`와 묶이지 않습니다. `Source<string?>`로 `Slot<Instance>`를 `updateFn`으로 매핑해 모는 모양은 **strict에서 타입 인자를 명시해야** 통과합니다 — `slot:Single<<string, nil>>(cur, function(ctx) … end)`처럼; 무주석 람다는 `ctx`가 `unknown`으로 굳고, `ctx: q.SingleCtx<string, nil>`처럼 정확히 주석해도 `Item`의 인스턴스를 추론하지 못합니다(`Item?` 팔이 넘긴 `State`를 `Item`의 하한으로 잡는 신 솔버 한계 — [2026-09-27 실측]; `KeyGone` 갈래에서 `return nil`을 먼저 하는 관용구는 반환 타입이 `nil`로 굳어 `:List`·`:Single<<…>>` 둘 다 반환 팩 주석(`): (TextLabel?, nil)`)까지 필요하고, `Text = ctx.Item`은 `ctx.Item :: string` 캐스트가 있어야 통과합니다; 반환이 한 갈래인 람다는 `:List`는 같은 무주석 람다로 통과합니다). `updateFn`을 생략하는 항등 사용에서는 `Item`이 곧 원소라 `T`로 두시면 됩니다(다른 것을 넘기면 타입이 아니라 런타임 가드 `Quad0240 Slot: this backend cannot mount this value`가 잡습니다).

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `state` | `Item?` 또는 그걸 담은 State | 이 Slot이 실을 **한 개**의 데이터 — `updateFn`이 원소로 바꿉니다 |
| `updateFn` | 함수? | 생략하면 항등 — 값을 그대로 원소로 씁니다(그때 `Item`은 원소 타입) |
| `opts` | `{ read OwnsElements: boolean? }?` | `:List`와 같습니다 |

**반환** — `self`.

**동작**

- 원소가 최대 하나인 `:List`입니다. 설치 규칙·모드 배타성·`OwnsElements` 의미는 전부 `:List`와 같습니다.
- `updateFn`은 `:List`와 **같은 모양의 `ctx`** 하나를 받습니다(`ctx.Index`도 들어옵니다). 그래서 같은 `updateFn`을 `:List`와 `:Single`에 나눠 쓸 수 있습니다.
- `state`의 값이 `nil`이거나 `q.None`이면 원소가 없는 상태입니다. 값이 있다가 `nil`/`q.None`이 되면 `updateFn`에 `ctx.Item`으로 `q.KeyGone`이 옵니다 — 처음부터 비어 있으면 `updateFn`은 불리지 않습니다.
- `state`가 State면 값이 바뀔 때마다 `updateFn`이 다시 돌고, 그 자리는 `updateFn`이 돌려주는 대로 갑니다 — `ctx.Prev`를 돌려주면 원소가 유지되고(키가 상수라 `Prev`가 늘 옵니다), 새 원소를 돌려주면 통째로 교체됩니다.
- 인자 검증 에러: `Quad0154 Slot:Single: updateFn must be a function (got {typeof(updateFn)})`.

`Slot`에 State를 원소로 넣는 `slot:Add(someState)`는 내부적으로 `OwnsElements = false`인 래퍼 Slot에 `:Single`을 건 것과 같습니다. 래퍼가 `OwnsElements = false`이므로 값이 바뀔 때 **옛 원소는 파괴되지 않습니다** — 더 쓸 일이 없으면 직접 `q.dispose` 하세요.

두 가지를 알아 두세요. **(1) 옛 원소가 풀리는 시점은 마운트 중일 때입니다** — 이 Slot이 언마운트된 상태(마운트된 적은 있으나 지금은 떼인)에서 `:Set`하면 조정이 돌지 않아 옛 원소는 다시 마운트될 때까지 래퍼에 묶인 채 남습니다(그 사이 다른 Slot에 넣으면 `Quad0172`, `q.dispose`는 `Quad0179`). `OwnsElements = false`인 `:Single`도 같습니다. **(2) 이미 다른 자리가 쥔 원소로 `:Set`하면 정의되지 않은 동작입니다** — `Set` 줄에서 `Quad0156`이 나고 그 래퍼는 배치 게이트가 켜진 채 남아 뒤의 `Set`이 겉으론 되는 듯해도 `Length`가 조용히 어긋납니다(`:List`의 `updateFn` 절과 같은 UB — 던진 자리의 Slot은 버리세요).

**예제**

```luau
local current = q.Source<<Instance?>>(nil)
local slot = q.Slot<<Instance>>():Single(current)
local host = q.Elem "Frame" { slot }

current:Set(q.Elem "TextLabel" { Text = "화면 A" })  -- 붙는다
current:Set(q.Elem "TextLabel" { Text = "화면 B" })  -- A는 파괴되고 B로 교체
current:Set(nil)                              -- 비워진다
```

**관련** — [비파괴 포털과 소유권](/quadnomicon/05-non-destructive-portal-and-ownership/)

## `slot:Lazy(fn)`

**시그니처**

```luau
Lazy: (self: Slot<T>, fn: () -> (SlotElement<T> | None)?) -> Slot<T>
```

빈 Slot에 **한 번만 짓는 함수**를 겁니다. `fn`은 거는 순간이 아니라 이 Slot이 **처음 꽂혀 마운트될 때 한 번** 불리고, 돌려준 값 하나가 이 Slot의 내용이 됩니다 — 원소 하나, `State`(반응형 원소), 여러 원소를 담은 `Slot`, 또는 `nil`·`q.None`(빈 내용). 돌려준 값은 [`slot:Add`](#slotaddelement-index)로 넣은 것과 같이 다룹니다. 이름의 "게으름"은 [시작하기 19장](/getting-started/19-laziness/)의 그것과 같은 뜻입니다 — 필요한 순간(꽂히는 순간)까지 미룰 뿐, 엔진 스케줄러(`task.defer`)와는 무관하게 마운트 순회 안에서 그 자리에서 짓습니다. **[3.3.0부터]**

**언제 쓰나** — Luau는 인자를 먼저 평가하므로 `Window({ Children = q.Slot{ Button{…} } })`에서 버튼은 창보다 **먼저** 지어집니다. 창이 자기 본문에서 무언가(예: [`q.Context`](/reference/sugar/01-context/) 가방에 넣는 값)를 채운 **뒤에** 내용을 짓고 싶을 때 내용을 `q.Slot():Lazy(fn)`으로 넘기세요. 받는 컴포넌트는 이것을 모릅니다 — 평범한 `Slot`으로 받아 자기 자리에 꽂을 뿐이고, 꽂히는 순간(그 부모가 자기 자리를 처리할 때) `fn`이 돕니다.

```luau
local ctx = q.Context()
local Handle = q.Context.Provider("WindowHandle")

local function Window(props: { Context: q.Context, Children: q.Slot<Instance> })
    props.Context:Set(Handle, makeHandle())           -- 본문에서 먼저 채운다
    return q.Elem "Frame" { props.Children }                 -- 여기서 꽂힐 때 내용이 지어진다
end

Window({
    Context = ctx,
    Children = q.Slot():Lazy(function()
        return CloseButton({ Handle = ctx:Get(Handle) }) -- 창이 채운 값을 본다
    end),
})
```

**동작**

- **한 번만 짓습니다.** 뗐다가 같은 곳이나 다른 곳에 다시 꽂아도 `fn`은 다시 불리지 않고, 처음 지은 것이 그대로 다시 붙습니다(수동 Slot을 옮길 때와 같습니다). 다시 지어야 하면 새 Slot을 만드세요. 지은 것을 미리 꺼내는 길은 없습니다 — 꽂히기 전에는 아무것도 지어져 있지 않습니다.
- 다시 돌지 않습니다 — `fn` 안에서 `State`를 읽어도 그 값이 바뀔 때 다시 짓지 않습니다. 바뀌는 내용이 필요하면 `State`를 돌려주거나(그 값이 원소가 됩니다) [`slot:Single`](#slotsinglestate-updatefn-opts)을 쓰세요.
- 이미 마운트된 빈 Slot에 걸면 그 자리에서 바로 짓습니다.
- 같은 부모 아래의 [`PreRef`](/reference/core/07-ref/)는 배열에서 앞뒤 어디에 있든 먼저 불립니다(PreRef가 먼저 소진됩니다). 그 뒤 `fn`은 부모가 이 Slot의 자리에 왔을 때 불립니다.
- `fn`은 `:List`/`:Single`의 첫 `updateFn`과 같은 자리(마운트 작업 안)에서 불립니다. 그래서 같은 규칙을 따릅니다 — 자기가 돌려줄 원소와 그 안의 Slot은 지어도 되지만, 이 Slot의 조상 Slot을 CRUD하면 `Quad0167`입니다(그 자리에서 고쳐야 하면 [`slot:WhenIdle`](#slotwhenidlefn)).
- 설치 규칙과 잠금은 `:List`/`:Single`과 같습니다. 한 Slot에 한 번만 걸 수 있고(`Quad0148`), 수동 CRUD를 쓴 Slot에는 걸 수 없으며(`Quad0149`), 건 뒤의 수동 CRUD는 `Quad0166`입니다.
- 지은 원소는 이 Slot이 소유합니다 — Slot이 파괴되면 같이 파괴됩니다.
- 인자·반환 에러: `Quad0271 Slot:Lazy: fn must be a function (got {typeof(fn)})`, `Quad0272 Slot:Lazy: fn must return one value (got {n}) - put several elements in a Slot and return that (what fn returned is not cleaned up; the Slot stays empty)`(여럿을 돌려주려면 `q.Slot{ … }`에 담아 하나로). `Quad0272` 뒤 `fn`이 만든 원소는 치워지지 않고 남습니다 — quad는 사용자 실수로 깨진 자리를 대신 정리하지 않습니다.
- `fn`이 던지면 그 에러가 마운트한 쪽으로 그대로 나갑니다(감싸지 않습니다). 그 뒤의 상태는 `:List`의 `updateFn`이 던진 경우와 같이 정의되지 않습니다 — 다음 마운트에서 `fn`을 다시 부르지도 않습니다.

## `q.Detach`

**시그니처**

```luau
Detach: Detach -- { read __quadDetach: true }
```

이 페이지는 Slot 재조정 안에서의 쓰임을 다룹니다 — 센티널 자체의 정의는 [생명주기와 센티널](/reference/core/10-lifetime-sentinels/)에도 있습니다.

**동작** — `:List`/`:Single`의 `updateFn`이 반환하는 센티널입니다. "이 원소를 트리에서 떼되 파괴하지는 말고 들고 있어라"라는 뜻입니다. 다음 사이클에 같은 키가 다시 나타났을 때 `ctx.Prev`를 반환하면 **만들지 않고 그대로 다시 붙습니다**.

보관은 `OwnsElements`가 켜진 Slot에서만 일어납니다 — 보관 중인 원소는 Slot이 소유하고, Slot이 파괴될 때, 그리고 **Slot이 지금 마운트된 호스트 인스턴스가 `Destroy`/`q.dispose`로 죽을 때**도 같이 파괴됩니다(보관분의 수명이 호스트에 묶이고, 언마운트 때 풀려 다시 마운트되면 새 호스트에 묶입니다 — 그 원소의 Effect cleanup은 `dying = true`; [2026-09-27 mock 관측]). `OwnsElements = false`인 Slot에서 `Detach`는 보관이 아니라 **완전한 해제**입니다: 원소는 파괴되지 않고 소유만 풀린 채 사용자 손에 남고, 같은 키가 다시 나타나도 `ctx.Prev`는 `nil`이라 새로 만들어집니다. 판정은 신원 비교(`result == q.Detach`)입니다.

**예제**

```luau
type Row = { Id: string }
type RowCtx = {
    Item: Row | QuadTypes.KeyGone,
    Index: number,
    Offset: QuadTypes.State<number>,
    Prev: QuadTypes.SlotItem<Instance>?,
    UserData: nil,
}

local visible = q.Source(true)
local rows = q.Source<<{ Row }>>({ { Id = "a" } })
local slot = q.Slot<<Instance>>()

slot:List(rows, function(ctx: RowCtx): (any, nil)
    if ctx.Item == q.KeyGone then return q.Detach end
    if not visible:Get() then return q.Detach end -- 숨김: 떼되 살려둔다
    if ctx.Prev then return ctx.Prev end          -- 복귀: 그대로 다시 붙는다
    return q.Elem "Frame" {}
end, function(item: Row) return item.Id end)
```

**관련** — [가상화 무한 스크롤](/how-to/03-long-lists-and-windowing/)

## `q.KeyGone`

**시그니처**

```luau
KeyGone: KeyGone -- { read __quadKeyGone: true }
```

센티널 자체의 정의는 [생명주기와 센티널](/reference/core/10-lifetime-sentinels/)에도 있습니다.

**동작** — 재조정 사이클의 마지막에, **지난 사이클에는 있었지만 이번 데이터에는 없는 키**마다 `updateFn`의 `ctx.Item`으로 오는 센티널입니다(그 호출의 `ctx.Index`는 `0`). 그 키가 만든 원소를 어떻게 할지 정하라는 물음입니다.

이 호출에서 허용되는 반환은 `nil`/`q.None`(버림)과 `q.Detach`(보관) 둘뿐입니다. `updateFn`의 첫 줄에서 신원 비교로 갈라내는 것이 관용구입니다.

```luau
if ctx.Item == q.KeyGone then
    return nil -- 이 키의 원소를 파괴한다
end
```

## `q.dispose(value)`

**시그니처**

```luau
dispose: (value: any) -> ()
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `value` | `any` | 파괴할 Slot 또는 백엔드 값(Roblox면 `Instance`) |

**반환** — 없음.

생명주기 관점의 서술은 [생명주기와 센티널](/reference/core/10-lifetime-sentinels/)에도 있습니다.

**동작** — quad가 관리하는 값을 지우는 **유일한 안전 경로**입니다. Slot을 주면 그 트리를 통째로 무너뜨리고(중첩 Slot 재귀, 원소 파괴), 백엔드 값을 주면 백엔드의 파괴 op로 넘깁니다.

**마운트 중인 값에는 쓸 수 없습니다.** 먼저 꺼내야 합니다. 값을 쥔 것이 숫자 키 자리의 `Source`라면 [`source:SetAndDispose(v)`](/reference/core/02-source/#sourcesetanddisposev)가 꺼내기(`:Set`)와 파괴를 이 순서로 한 번에 합니다.

- `Quad0178 dispose: value must not be nil`
- `Quad0179 dispose: this value is still held by a Slot or a mounted position - Remove/Extract it from a manual Slot, drop its key from a :List Slot's data, destroy the owner Slot (a detached element goes with its owner), or take it off its numeric-key seat first (Set(nil) the State holding it; a shorthand-managed child goes with its key)`
- `Quad0180 dispose: this backend cannot dispose this value`
- `Quad0106 dispose: this value was made by another quad module instance …` — 다른 quad 인스턴스가 만든 `Slot`/`State`(`q.NewModule()`를 따로 부른 코드 — `quad_base` 사본이 둘인 프로젝트는 브랜드가 갈려 이 에러 대신 `Quad0180`/`Quad0240`류가 납니다).

**소유는 검사하지 않습니다.** `dispose`의 계약은 "이 값을 지워도 quad의 부기가 깨지지 않는가"이지 "우리가 만든 값인가"가 아닙니다 — 그래서 `Instance.new`나 `:Clone()`으로 만들어 어느 자리에도 놓지 않은 Instance도 지웁니다. 다른 quad 인스턴스가 자기 자리에 앉힌 Instance는 이쪽 부기에 없어 거부되지 않으니, 인스턴스끼리 값을 섞지 마세요([`q` 모듈](/reference/core/01-quad-module/)의 교차 인스턴스 규칙 — 정의되지 않은 동작).

⚠️ 마운트 대상 인스턴스를 quad 밖에서(`inst:Destroy()`) 파괴하면 그 값은 영구히 죽습니다. 위 넷 가운데 `Quad0179 dispose: this value is still held by …` 하나에만 그 사정을 알리는 안내가 뒤에 붙습니다.

```
(if its owner was destroyed outside quad - `inst:Destroy()` - the value went with it and cannot be reused after its parent is destroyed; extract it before destroying, as with an Instance)
```

**예제**

```luau
local slot = q.Slot<<Instance>>({ q.Elem "Frame" {} })
local taken = slot:Extract(1)  -- 먼저 소유에서 꺼내고
q.dispose(taken)               -- 그다음에 지운다

local temp = q.Slot<<Instance>>({ q.Elem "Frame" {}, q.Elem "Frame" {} })
q.dispose(temp)                -- 마운트된 적 없는 Slot은 트리째 파괴된다
```

**관련** — [인스턴스 신원과 GC 철학](/quadnomicon/07-instance-identity-and-gc-philosophy/), [디버깅과 문제 해결](/how-to/10-debugging-and-troubleshooting/)

## 죽은 Slot과 마운트 규칙

- 하나의 원소는 **동시에 한 자리에만** 마운트될 수 있습니다. 첫째 문구는 `:List`/`:Single`(그리고 `State` 원소의 래퍼) Slot이 원소를 자기 것으로 가져갈 때(수동 CRUD는 `Quad0172`, 이미 이 Slot에 있으면 `Quad0170` — 위 `slot:Add` 절), 둘째 문구는 그 원소를 인스턴스의 자리(숫자 키의 Slot·정적 자식)에 마운트할 때 이미 임자가 있는 경우입니다. 이 규칙의 레지스트리는 하나라 Slot 원소·정적 자식(`q.Elem "Frame" { c }`)·숏핸드가 만든 관리 자식(`UICorner = 8`의 `_quad_round`)이 서로 섞이지 않습니다 — 정적 자식을 `slot:Add`하거나 Slot 원소를 정적 자리에 놓으면 같은 문구로 거부됩니다.
- `q.Elem "<Class>" { … }`가 중간에 던지면(nil 구멍, 잘못된 키) 그 전에 놓인 자식들은 반쯤 지어진 Instance에 앉은 채 남습니다 — 같은 자식으로 다시 시도하면 위의 "already mounted elsewhere"가 납니다. 그 Instance는 호출자에게 돌아오지 않지만 자식의 `Parent`로 닿으므로, 같은 자식을 다시 쓰려면 먼저 `q.dispose(child.Parent)`로 정리하세요(자식들도 같이 파괴됩니다 — 보통은 자식도 새로 만드는 편이 간단합니다).

  ```
  Quad0156 Slot: this element is already mounted - multiple mounts are not allowed (a State or :List element is settled when its Slot mounts or the value changes, so two elements that became the same Instance - two States holding one value, an updateFn returning the same Instance twice - collide here, not at Add) (if its owner was destroyed outside quad - `inst:Destroy()` - the value went with it and cannot be reused after its parent is destroyed; extract it before destroying, as with an Instance)
  Quad0160 Bookkeeping.claimOwnerAt: this element is already mounted elsewhere - one value takes one seat, so the same element cannot sit in two parent tables, twice in one table, or in two Slots (if its owner was destroyed outside quad - `inst:Destroy()` - the value went with it and cannot be reused after its parent is destroyed; extract it before destroying, as with an Instance)
  ```

- 파괴된 Slot은 되살아나지 않습니다 — `Quad0165 Slot: destroyed Slot cannot be reused`, 원소로 넣으려 하면 `Quad0242 Slot: destroyed Slot cannot be an element`, 마운트하려 하면 `Quad0140 Slot: destroyed Slot cannot be mounted`(같은 문구의 `Quad0164`는 안쪽 검사라 공개 경로에서는 `Quad0140`이 먼저 납니다).
- **죽어 가는 호스트의 `Slot`을 그 호스트의 cleanup이나 `q.OnDestroyed` 안에서 CRUD하는 것은 정의되지 않은 동작입니다** — 그 Slot을 든 호스트 인스턴스가 죽어 가는 중(`q.dispose(host)`든 quad 밖의 파괴든)의 이야기이고, 서브트리 안 인스턴스들의 파괴 순서는 정해 두지 않았기 때문입니다([Observer·Effect](/reference/core/05-observer-effect/)). 이미 **파괴된 Slot**을 다루는 규칙은 이것과 별개입니다 — `slot:WhenIdle(fn)`은 파괴된 Slot을 한가한 것으로 치고 `fn`을 그냥 실행하며, `fn` 안의 CRUD는 평소의 파괴된 Slot 에러(`Quad0165`)를 냅니다.
- 마운트 대상이 파괴된 Slot은 그 사실을 모릅니다(정의되지 않은 동작 — 예외는 `q.Detach`로 보관 중인 원소로, 이것만은 호스트와 함께 파괴됩니다) — 부모를 `inst:Destroy()`로 지웠든 `q.dispose(부모)`로 지웠든 같습니다(`q.dispose`는 Instance에 대해 백엔드의 파괴 op만 부릅니다) — `Add`/`Replace`/`Splice`는 계속 성공하고 새 원소는 죽은 인스턴스에 붙으며, `:List` 모드는 데이터가 바뀌어도 조용히 재조정을 멈춥니다(`updateFn`이 더는 불리지 않음 — [2026-09-27 mock 관측 — 계약 아님]). 알아채는 자리는 `q.dispose`(`… cannot be reused after its parent is destroyed`)와 뽑아낸 원소의 재사용(`… a destroyed Instance cannot be reused`)뿐입니다. 화면을 quad 밖에서 지웠다면 그 Slot도 버리세요.
- Slot을 자기 자신이나 자기 조상에 넣는 순환은 [`q.debug`](/reference/core/01-quad-module/#qdebug)가 켜져 있으면 넣는 시점에 거부됩니다(꺼져 있으면 다음 CRUD에서 죽습니다). 인스턴스를 매개로 한 순환(이 Slot의 마운트 대상이나 그 조상을 원소로)은 거부되지 않고 정의되지 않은 동작입니다 — 위 `Slot:Add` 절.
