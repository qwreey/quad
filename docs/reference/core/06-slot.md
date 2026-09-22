---
title: Slot
description: 가변 자식 배열 프리미티브 — CRUD 열하나, :List/:Single 재조정, Detach/KeyGone, dispose
---

# Slot\<T\>

`Slot<T>`은 **가변 자식 배열**입니다. 부모의 숫자 키 자리에 한 번 놓이면, 그 뒤로 Slot에 가한 CRUD가 그대로 물리 자식에 반영됩니다 — 부모를 다시 만들지도, 렌더 함수를 다시 돌리지도 않습니다.

Slot은 **두 모드 중 하나**로만 삽니다. 손으로 원소를 넣고 빼는 **수동 CRUD** 모드와, 데이터 배열에 맞춰 quad가 재조정하는 **`:List`/`:Single`** 모드입니다. 둘은 상호 배타이고, 섞으려 하면 그 자리에서 에러가 납니다.

이 페이지의 심볼: [`q.Slot`](#qslottinitial) · [`slot.Length`](#slotlength) · [`slot.Offset`](#slotoffset) · [`slot:Add`](#slotaddelement-index) · [`slot:Remove`](#slotremoveindex) · [`slot:Replace`](#slotreplaceindex-newelement) · [`slot:Extract`](#slotextractindex-newelement) · [`slot:ExtractAll`](#slotextractall) · [`slot:Splice`](#slotspliceindex-removecount-newelements) · [`slot:Clear`](#slotclear) · [`slot:Move`](#slotmoveoldindex-newindex) · [`slot:Swap`](#slotswapindexa-indexb) · [`slot:Get`](#slotgetindex) · [`slot:IndexOf`](#slotindexofelement) · [`slot:List`](#slotlistdata-updatefn-keyfn-opts) · [`slot:Single`](#slotsinglestate-updatefn-opts) · [`q.Detach`](#qdetach) · [`q.KeyGone`](#qkeygone) · [`q.dispose`](#qdisposevalue)

이 페이지의 모든 예제는 아래 프롤로그를 전제합니다.

```luau
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("@game/ReplicatedStorage/Client/UI/Quad")
local QuadTypes = require("@game/ReplicatedStorage/roblox_packages/quad_types") -- 설정 모듈이 다시 내보내지 않는 타입(`QuadTypes.SlotItem<T>`·`QuadTypes.KeyGone`)
local D = q.Declaration
```

## 원소 대수 — 넣는 자리와 꺼내는 자리의 타입이 다르다

```luau
-- 입력 자리(생성자 initial, Add/Replace/Extract의 새 원소, Splice, IndexOf)
type SlotElement<T> = T | StateMarker<T> | SlotMarker<T>
-- 출력 자리(Get/Extract/ExtractAll/Splice의 반환, updateFn의 ctx.Prev)
type SlotItem<T> = T | State<T> | Slot<T>
```

같은 값의 두 역할이라 별칭이 둘입니다. 입력 자리는 **마커 타입**이라 `T`에 공변입니다 — `Slot<Instance>`의 원소 자리에 `State<Frame>`이나 `Slot<Frame>`이 그대로 들어갑니다. 출력은 언래핑된 원래 값이라 전체형입니다.

원소로 놓을 수 있는 것은 셋입니다.

| 넣은 것 | 되는 일 |
|---|---|
| 백엔드가 마운트할 수 있는 값(Roblox면 `Instance`) | 그대로 물리 자식 하나 |
| `State<T>` / `Source<T>` | 내부적으로 `:Single`을 건 래퍼 Slot으로 감싸집니다. 값이 바뀌면 그 자리만 통째로 교체됩니다 |
| 다른 `Slot<T>` | 중첩 — 바깥 Slot의 한 자리를 안쪽 Slot의 물리 원소 전부가 차지합니다 |

그 밖은 전부 거부됩니다.

- `Slot: handler-layer values (Ref/PreRef/PostRef/Observer/Effect/Modifier) cannot be elements`
- `Slot: nil/None cannot be an element — only actually mountable values`
- `Slot: this backend cannot mount this value`
- `Slot: this element is not claimed by quad — build it with the Declaration or take it over with Claim first (an Instance made by another quad module instance also counts as not claimed here, and so does a destroyed one — a destroyed Instance cannot be reused)` — quad 밖에서 만든 인스턴스(`Instance.new`, 다른 라이브러리가 만든 트리)는 quad가 소유하고 있지 않아 죽음을 추적할 수 없으므로 원소로 받지 않습니다. 다른 quad 인스턴스가 `Declaration`으로 만든 것도 이쪽 기록에는 없어 같은 거부입니다(꼬리 구절이 그 경우를 가리킵니다 — 인스턴스 간 값 섞기는 정의되지 않은 동작). 먼저 [`Claim`](../roblox/04-claim-mapper.md)으로 넘겨받거나 `Declaration`으로 만드세요. Slot이 대신 claim해 주지는 않습니다 — 소유는 언제나 사용자가 명시적으로 시작합니다.
- `Quad0169 Slot: destroyed Slot cannot be an element`

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
<!-- strict 실측 2026-09-11: consumer/P19.luau — q.Slot():Get(1)을 number에 대입하면 'Slot<unknown>'이 유니언에 보인다 --> strict 모드에서는 `q.Slot<<Instance>>()`처럼 **명시적으로 인스턴스화**하세요.
- `initial`을 주면 — **빈 `Slot{}`이라도** — 그 Slot은 수동 CRUD Slot으로 고정됩니다. 나중에 `:List`를 걸 수 없습니다.
- `initial`은 **평범한 배열**이어야 합니다. 값 하나를 괄호 없이 넘기거나(`Slot(frame)`) 정수가 아닌 키를 섞으면 에러입니다.
  - `Quad0176 Slot: initial elements must be a plain { element, ... } array (got {typeof(initial)} — a bare element or quad value needs the braces)`
  - `Quad0177 Slot: initial elements must be an array — key "{tostring(k)}" is not an array position`
- 배열 안의 중복(같은 원소 두 번 — `Quad0171 Slot: the same element appears twice`), 이 Slot이 이미 들고 있는 원소를 되넣는 것(`Quad0170 Slot:Splice: this element is already in this Slot — reorder with Move/Swap instead of adding it again` — `Replace(i, slot:Get(i))`도 같습니다), 이미 다른 곳에 마운트된 원소는 원소를 하나도 넣기 전에 한 번에 검사됩니다. `State`에 담긴 원소는 그 **현재값**으로 같은 검사(마운트 가능·소유·파괴된 Slot 아님)를 미리 받습니다 — 실패한 호출은 아무것도 바꾸지 않습니다.
- 배열 중간의 nil 구멍은 정의되지 않은 동작입니다 — `ipairs`가 거기서 멈추고 뒤는 무시됩니다.

**예제**

```luau
local list = q.Slot<<Instance>>()      -- 빈 Slot(아직 수동/재조정 모드 미정)
local fixed = q.Slot<<Instance>>({     -- 초기 원소 둘, 수동 CRUD Slot으로 고정
    D.TextLabel { Text = "A" },
    D.TextLabel { Text = "B" },
})

local panel = D.Frame { list, fixed }  -- 숫자 키에 놓으면 그 자리가 Slot의 자식 구간이 된다
```

**관련** — [Slot 접두합 트리](../../quadnomicon/02-slot-prefix-sum-tree.md), [DOMless Slot](../../quadnomicon/09-fragment-breakthrough-and-domless-slot.md)

## `slot.Length`

**시그니처**

```luau
read Length: State<number>
```

**동작** — 이 Slot이 차지하는 **물리 원소의 총 개수**를 싣는 반응형 `State<number>`입니다 — **읽기 전용**이라 `:Set`이 없습니다(값을 채우는 것은 quad의 부기뿐입니다). 중첩 Slot은 자기 물리 잎의 수만큼 기여하므로, 원소 배열의 길이(`#`)와 항상 같지는 않습니다.

**마운트 전에는 0입니다.** 채워지는 것은 부기(bookkeeping) 재계산이고, 그건 Slot이 실제로 어딘가에 놓인 뒤에 돕니다. 그래서 `:Add` 직후에 `Length:Get()`을 읽으면 아직 0일 수 있습니다.

`State`이므로 `:Compute`/`:Observer`로 그대로 구독할 수 있습니다.

**예제**

```luau
local slot = q.Slot<<Instance>>()
local empty = slot.Length:Compute(function(self)
    return self:Get() == 0
end)
local view = D.Frame { slot, D.TextLabel { Text = "비었음", Visible = empty } }
```

**관련** — [State](./03-state.md), [Slot 접두합 트리](../../quadnomicon/02-slot-prefix-sum-tree.md)

## `slot.Offset`

**시그니처**

```luau
read Offset: State<number>
```

:::caution
`Offset`을 구독한 콜백(`:Observer`·`Effect`·`Compute`)은 **던지면 안 됩니다.** 이 값은 부모의 자리 부기가 다시 계산되는 창 안에서 `:Set`되므로, 거기서 던지면 그 부모의 부기가 영구히 멈춥니다(`Length`는 그 창 밖에서 발행되므로 구독 콜백이 던져도 다음 변경에서 회복됩니다) — 이후 에러는 나지 않지만 형제 Slot의 자식이 옛 오프셋에 앉습니다. 던질 수 있는 일은 콜백 밖에서 끝내세요(`updateFn`과 같은 계약).
:::

**동작** — 마운트 대상 안에서 이 Slot의 첫 원소 **앞에 놓인 숫자 키 자리들의 길이 합**(0부터 센 절대 위치 — 앞에 아무것도 없으면 0, 첫 원소는 `Offset + 1`번째; 문자 키 숏핸드가 만든 관리 자식(`UICorner = 8`의 `UICorner`)은 물리 자식이지만 여기 세지 않습니다 — Roblox에서 자식의 물리 순서는 계약이 아닙니다)를 싣는 읽기 전용 `State<number>`입니다. 형제가 앞에서 길이를 바꾸면 이 값이 따라 움직입니다. `Length`와 짝을 이루어 접두합을 만들고, `:List`/`:Single`의 `updateFn`이 `ctx.Offset`으로 받는 것도 이 State입니다.

Roblox 백엔드는 자식 순서를 물리 속성으로 갖지 않으므로 이 값은 부기용입니다 — 순서가 물리인 백엔드(DOM 등)와 계약을 공유하려고 존재합니다.

**관련** — [Slot 접두합 트리](../../quadnomicon/02-slot-prefix-sum-tree.md)

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
- 이미 다른 곳에 마운트된 값은 거부됩니다. 문구 뒤에 붙는 꼬리 안내는 아래 "죽은 Slot과 마운트 규칙" 절의 것과 같습니다.

  ```
  Quad0172 Slot:Add: this element is already mounted — multiple mounts are not allowed (if its owner was destroyed outside quad — `inst:Destroy()` — the value went with it and cannot be reused after its parent is destroyed; extract it before destroying, as with an Instance)
  ```

- Slot을 자기 자신이나 자기 조상에 넣으면 순환이라 거부됩니다 — `Quad0173 Slot:Add: cannot add a Slot to itself or to one of its own descendants (that would be a cycle)`. **인스턴스를 매개로 한 순환은 거부되지 않습니다(정의되지 않은 동작)** — 이 Slot이 붙어 있는 인스턴스나 그 조상을 원소로 넣는 것(`slot:Add(host)`). quad-base는 인스턴스의 조상 사슬을 모르고, 정적 자식 자리의 같은 검사(`InstanceChild: cannot place an Instance inside itself …`)는 백엔드 핸들러가 하는 것입니다. Roblox에서는 엔진이 부모 대입에서 던지는데 그때는 Slot 부기가 이미 끝난 뒤라 그 원소가 자리에 끼인 채 남습니다. 회복은 **`slot:Extract(그 자리)`** 로 자리를 비운 뒤 그 인스턴스를 원래 부모에 다시 붙이는 것입니다 — `Extract`는 그 인스턴스의 `Parent`를 `nil`로 만들고, `Remove`는 그 인스턴스(자기 자신이거나 조상!)를 **파괴**하니 쓰지 마세요. `Splice`로 넣은 경우는 배치 창 안에서 던진 것이라 그 Slot의 `Length`가 더는 갱신되지 않습니다(위 `:Clear` 캐비엇과 같은 동결) — 그 Slot은 버리세요.
- quad가 소유하지 않은(claim되지 않은) 인스턴스는 거부됩니다 — 위 "원소 대수" 절의 `Slot: this element is not claimed by quad …`. 생성자 `initial`·`:Replace`·`:Splice`·`:List`/`:Single`의 새 원소도 같은 검사를 지납니다.
- 마운트된 Slot의 단일 변경(`Add`·`Remove`·`Replace`·`Move`·`Swap`·`Extract`)은 현재 길이에 비례하는 부기 비용을 냅니다 — `Move`/`Swap`은 Roblox에서 물리 이동이 없을 뿐 자리 계산은 전량 돕니다. 여러 개를 한 번에 넣거나 뺄 때는 [`:Splice`](#slotspliceindex-removecount-newelements)를 쓰세요(한 호출에 여럿이 배치이고, 한 개씩 반복 호출은 배치가 아닙니다). `:List`의 한 사이클도 바뀐 항목 수와 무관하게 전체 항목 수에 비례합니다.

**예제**

```luau
local slot = q.Slot<<Instance>>()
slot:Add(D.TextLabel { Text = "끝에" })
slot:Add(D.TextLabel { Text = "앞에" }, 1)
local root = D.Frame { slot }
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
local slot = q.Slot<<Instance>>({ D.Frame {}, D.Frame {} })
local taken = slot:Extract(1)          -- 살아 있는 채로 빠져나온다
local other = q.Slot<<Instance>>()
other:Add(taken)                       -- 다른 Slot으로 이사
```

**관련** — [비파괴 포털과 소유권](../../quadnomicon/05-non-destructive-portal-and-ownership.md)

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
local slot = q.Slot<<Instance>>({ D.Frame {}, D.Frame {}, D.Frame {} })
local removed = slot:Splice(2, 1, D.Frame {}, D.Frame {}) -- 2번을 빼고 그 자리에 둘을 넣는다
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

## `slot:List(data, updateFn, keyFn?, opts?)`

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
| `data` | `{ Item }` 또는 그걸 담은 State | 재조정의 원본. State면 값이 바뀔 때마다 다시 돕니다 |
| `updateFn` | 함수 | 항목 하나를 어떻게 만들/유지/버릴지 결정합니다(아래 계약) |
| `keyFn` | `((item, index) -> any)?` | 항목의 신원. 기본값은 **인덱스**입니다 |
| `opts` | `{ read OwnsElements: boolean? }?` | `OwnsElements = false`면 이 Slot이 원소를 파괴하지 않습니다 |

**반환** — `self`(체이닝용).

**`updateFn` 계약**

호출 시그니처는 `updateFn(ctx) -> (result, userdata)`입니다. `ctx`는 필드 다섯을 담은 테이블 하나이고, **호출마다 새로 만들어집니다** — `updateFn` 안에서 만든 클로저(`:Compute` 콜백, 이벤트 콜백)가 `ctx`를 붙잡아 나중에 읽어도 다음 호출의 값으로 바뀌지 않습니다.

| 필드 | 뜻 |
|---|---|
| `ctx.Item` | 이번 사이클의 데이터 항목. 지난 사이클에 있었는데 이번엔 사라진 키에는 `q.KeyGone`이 옵니다 |
| `ctx.Index` | 이 Slot 안에서의 물리 위치(`Offset` 기준 1부터). 중첩 Slot이 섞여 있으면 데이터 배열의 인덱스와 다릅니다. `KeyGone` 호출에서는 `0`입니다 |
| `ctx.Offset` | 이 Slot의 `Offset` State 자체 — 값이 아니라 핸들입니다 |
| `ctx.Prev` | 이 키가 지난번에 만든 원소(언래핑됨). 처음이면 `nil` |
| `ctx.UserData` | 지난 호출이 두 번째로 반환한 값. 키마다 따로 보관됩니다 |

반환값은 `(result, userdata)` 둘입니다. `result`의 뜻은 넷입니다.

| 반환 | 뜻 |
|---|---|
| 새 원소 | 그 자리에 놓습니다. `ctx.Prev`가 있었으면 교체(소유 Slot이면 옛 원소 파괴) |
| `ctx.Prev` 그대로 | 그대로 유지 — 다시 만들지 않습니다. 위치만 필요하면 옮깁니다 |
| `nil` 또는 `q.None` | 이 키를 버립니다(소유 Slot이면 파괴) |
| `q.Detach` | 트리에서 떼되 **파괴하지 않고** 보관합니다. 다음에 `ctx.Prev`를 반환하면 그대로 다시 붙습니다 |

두 번째 반환값은 이 키의 다음 `ctx.UserData`가 됩니다.

`updateFn`은 항목 하나를 원소로 바꾸는 함수입니다 — 자기가 만드는 자식 Slot을 채우는 것은 되지만, **이 Slot의 조상을 CRUD하면 안 됩니다.** 첫 `updateFn`은 이 Slot이 트리에 붙는 순간(부모와 함께 마운트될 때, 또는 이미 마운트된 부모에 `Add`/`Splice`/`Replace`로 들어갈 때) 그 부모들의 마운트 작업 안에서 불리므로 그 자리에서 던집니다(아래 문구). 조상을 바꿔야 하면 마운트 뒤 Observer에서 하세요.

```
Quad0167 Slot: cannot mutate a Slot while it is being mounted — a :List/:Single updateFn (or an Observer that fires during the mount) must not CRUD an ancestor Slot; do it after the mount, from an Observer
```

**동작**

- `:List`는 **설치**입니다. 한 Slot에 한 번만 걸 수 있고, 수동 CRUD를 이미 쓴 Slot(빈 `Slot{}` 포함)에는 걸 수 없습니다.
  - `Quad0148 Slot: already has :List/:Single installed`
  - `Quad0149 Slot: cannot install :List/:Single on a manual Slot (one that used CRUD or was built as Slot{ ... }, even empty)`
  - 반대로 `:List`를 건 뒤의 수동 CRUD는 `Quad0166 Slot: manual CRUD is not allowed after :List/:Single`.
- 재조정은 마운트 시점과 이후 `data`가 바뀔 때마다 돕니다. 한 사이클은 **하나의 배치**로 묶여 재계산이 한 번만 일어납니다.
- 사이클 순서는 (1) 데이터 순서대로 키를 계산해 중복/누락을 먼저 검사, (2) 항목마다 `updateFn`, (3) 지난 사이클에 있었지만 이번엔 없는 키에 `q.KeyGone`으로 `updateFn`을 한 번 더 — 입니다.
- `KeyGone` 호출에서는 `nil`/`q.None`(파괴)과 `q.Detach`(보관)만 반환할 수 있습니다. 새 원소를 반환하면 `Quad0147 Slot:List: KeyGone accepts only nil/None (destroy) or Detach (hold)`.
- 인자 검증 에러: `Quad0150 Slot:List: updateFn must be a function (got {typeof(updateFn)})`, `Quad0151 Slot:List: data must be a plain array or a State of one (got {typeof(data)})`, `Quad0152 Slot:List: keyFn must be a function (got {typeof(keyFn)})`.
- 재조정 중 에러: `Quad0142 Slot:List: data must be a plain array (got {typeof(items)}) — a data State must hold one too`, `Quad0144 Slot:List: keyFn returned nil for item #{i}`(NaN도 같은 모양으로 `returned NaN`), `Quad0145 Slot:List: duplicate key {tostring(key)}`. 인자 검증에 `Quad0153 Slot:List: opts must be a table (got {typeof(opts)})`(`:Single`도 같음)이 더해집니다.
- `updateFn`이 이 Slot의 `data` State를 다시 `:Set` 하는 **재진입**은 정의되지 않은 동작입니다.
- `KeyGone` 호출끼리의 순서는 정해져 있지 않습니다 — 사라진 키가 데이터에 있던 순서로 온다고 기대하지 마세요.
- `updateFn`이 도중에 던지면(이미 다른 곳에 마운트된 원소나 claim되지 않은 Instance를 반환해 quad가 대신 던지는 경우 포함) 그 사이클의 배치가 닫히지 않아 **그 Slot의 `Length`가 더 이상 발행되지 않습니다** — 재조정 자체는 계속 돌아 항목이 붙고 떨어지지만, 같은 부모 안의 형제 Slot이 옛 오프셋에 자식을 넣게 되고 에러는 나지 않습니다. 사용자 코드의 예외를 감싸 복구하지 않는 계약이라 [`slot:Clear`](#slotclear)와 같이 정의되지 않은 동작으로 둡니다 — 던질 수 있는 일은 `updateFn` 밖에서 끝내세요.

**`OwnsElements = false`**

**State에 담은 원소는 파괴되지 않습니다.** `slot:Add(q.Source(frame))`처럼 `State`로 넣은 원소는 그 State가 주인이라, `Remove`·`Replace`·`Clear`·`:List`의 키 소멸·`q.dispose(slot)` 어느 경로로 버려도 인스턴스는 살아남고 자리에서만 내려옵니다(`Parent = nil`, 소유권 해제 — 다른 Slot에 다시 넣을 수 있습니다). 화면을 철거할 때 그 인스턴스까지 없애려면 그 State를 `q.dispose`하거나 값을 `q.None`으로 바꾸고 인스턴스를 직접 `q.dispose`하세요. `State<Slot>`(리스트 안 포털)도 같습니다.

기본은 소유(`OwnsElements = true`)입니다 — 이 Slot이 버리는 원소는 파괴됩니다. `OwnsElements = false`를 주면 버릴 때 소유권만 풀고 살려둡니다. 그 Slot 자체를 버릴 때도 같습니다 — `q.dispose(slot)`하거나 소유하는 부모 Slot이 이 Slot을 `Remove`/`Clear`로 파괴하면, 이 Slot은 쥐고 있던 원소 전부의 소유권을 놓고 **빈 채로** 살아남습니다(파괴되지 않고 다시 쓸 수 있으며, 다음 마운트에서 data로부터 처음부터 다시 조정합니다). 원소는 살아남아 다른 Slot에 다시 넣거나 `q.dispose`할 수 있습니다. 반면 부모에서 `Extract`로 빼는 것은 파괴가 아니라서 이 Slot은 원소를 **쥔 채** 떨어져 나오고, 그대로 다른 Slot에 넣으면 원소째 옮겨갑니다. 원소를 밖에서 관리하는 가상화 목록이나 포털이 이 옵션의 자리입니다. 단, Slot이 **마운트된 채로 그 부모 Instance가 파괴되면** 엔진이 자손을 지우므로 원소도 같이 죽습니다 — 화면을 철거할 때 살려야 할 원소는 먼저 `:Extract`하거나 data에서 키를 빼세요. 그래도 원소는 quad 소유(`Declaration`으로 만들었거나 `Claim`으로 넘겨받은 것)여야 합니다 — 이 옵션은 파괴 여부만 바꾸고, 위 "원소 대수"의 미claim 거부는 그대로 적용됩니다.

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
    return D.TextLabel { Text = (ctx.Item :: Row).Title }
end, function(item: Row)
    return item.Id            -- 신원은 Id
end)

local view = D.Frame { slot }
rows:Set({ { Id = "b", Title = "둘째" }, { Id = "a", Title = "첫째" } }) -- a는 재사용, b는 새로 생성
```

`userdata`를 쓴다면 `ctx` 타입의 `UserData` 필드와 반환 팩의 두 번째 자리에 그 타입을 적습니다 — `UserData: RowUD?` / `: (any, RowUD?)`.

**관련** — [가상화 무한 스크롤](../../how-to/03-virtualized-infinite-scroll.md), [DOMless Slot](../../quadnomicon/09-fragment-breakthrough-and-domless-slot.md)

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

타입 인자는 `:List`와 같은 `<Item, UD>`입니다 — `state`가 담는 것은 **데이터**(`Item`)이고, 원소 타입 `T`와 묶이지 않습니다. `Source<string?>`로 `Slot<Instance>`를 `updateFn`으로 매핑해 모는 모양이 그대로 타입 검사를 통과합니다. `updateFn`을 생략하는 항등 사용에서는 `Item`이 곧 원소라 `T`로 두시면 됩니다(다른 것을 넘기면 타입이 아니라 런타임 가드 `Slot: this backend cannot mount this value`가 잡습니다).

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
- `state`가 State면 값이 바뀔 때마다 그 자리가 통째로 교체됩니다.
- 인자 검증 에러: `Quad0154 Slot:Single: updateFn must be a function (got {typeof(updateFn)})`.

`Slot`에 State를 원소로 넣는 `slot:Add(someState)`는 내부적으로 `OwnsElements = false`인 래퍼 Slot에 `:Single`을 건 것과 같습니다. 래퍼가 `OwnsElements = false`이므로 값이 바뀔 때 **옛 원소는 파괴되지 않습니다** — 더 쓸 일이 없으면 직접 `q.dispose` 하세요.

**예제**

```luau
local current = q.Source<<Instance?>>(nil)
local slot = q.Slot<<Instance>>():Single(current)
local host = D.Frame { slot }

current:Set(D.TextLabel { Text = "화면 A" })  -- 붙는다
current:Set(D.TextLabel { Text = "화면 B" })  -- A는 파괴되고 B로 교체
current:Set(nil)                              -- 비워진다
```

**관련** — [비파괴 포털과 소유권](../../quadnomicon/05-non-destructive-portal-and-ownership.md)

## `q.Detach`

**시그니처**

```luau
Detach: Detach -- { read __quadDetach: true }
```

이 페이지는 Slot 재조정 안에서의 쓰임을 다룹니다 — 센티널 자체의 정의는 [생명주기와 센티널](./10-lifetime-sentinels.md)에도 있습니다.

**동작** — `:List`/`:Single`의 `updateFn`이 반환하는 센티널입니다. "이 원소를 트리에서 떼되 파괴하지는 말고 들고 있어라"라는 뜻입니다. 다음 사이클에 같은 키가 다시 나타났을 때 `ctx.Prev`를 반환하면 **만들지 않고 그대로 다시 붙습니다**.

보관은 `OwnsElements`가 켜진 Slot에서만 일어납니다 — 보관 중인 원소는 Slot이 소유하고, Slot이 파괴될 때 같이 파괴됩니다. `OwnsElements = false`인 Slot에서 `Detach`는 보관이 아니라 **완전한 해제**입니다: 원소는 파괴되지 않고 소유만 풀린 채 사용자 손에 남고, 같은 키가 다시 나타나도 `ctx.Prev`는 `nil`이라 새로 만들어집니다. 판정은 신원 비교(`result == q.Detach`)입니다.
<!-- mock 실측 2026-09-11: gs.owned.luau — OwnsElements=true는 같은 인스턴스가 prev로 돌아옴(made 2), OwnsElements=false는 prev nil·새로 만듦(made 3), 둘 다 옛 원소 파괴 안 됨 -->

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
    return D.Frame {}
end, function(item: Row) return item.Id end)
```

**관련** — [가상화 무한 스크롤](../../how-to/03-virtualized-infinite-scroll.md)

## `q.KeyGone`

**시그니처**

```luau
KeyGone: KeyGone -- { read __quadKeyGone: true }
```

센티널 자체의 정의는 [생명주기와 센티널](./10-lifetime-sentinels.md)에도 있습니다.

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

생명주기 관점의 서술은 [생명주기와 센티널](./10-lifetime-sentinels.md)에도 있습니다.

**동작** — quad가 관리하는 값을 지우는 **유일한 안전 경로**입니다. Slot을 주면 그 트리를 통째로 무너뜨리고(중첩 Slot 재귀, 원소 파괴), 백엔드 값을 주면 백엔드의 파괴 op로 넘깁니다.

**마운트 중인 값에는 쓸 수 없습니다.** 먼저 꺼내야 합니다.

- `Quad0178 dispose: value must not be nil`
- `Quad0179 dispose: this value is still held by a Slot or a mounted position — Remove/Extract it from a manual Slot, drop its key from a :List Slot's data, destroy the owner Slot (a detached element goes with its owner), or take it off its numeric-key seat first (Set(nil) the State holding it; a shorthand-managed child goes with its key)`
- `Quad0180 dispose: this backend cannot dispose this value`
- `dispose: this value was made by another quad module instance …` — 다른 quad 인스턴스가 만든 `Slot`/`State`(`q.New()`를 따로 부른 코드나 `quad_base` 사본이 둘인 프로젝트).

**소유는 검사하지 않습니다.** `dispose`의 계약은 "이 값을 지워도 quad의 부기가 깨지지 않는가"이지 "우리가 만든 값인가"가 아닙니다 — 그래서 `Instance.new`나 `:Clone()`으로 만들어 어느 자리에도 놓지 않은 Instance도 지웁니다. 다른 quad 인스턴스가 자기 자리에 앉힌 Instance는 이쪽 부기에 없어 거부되지 않으니, 인스턴스끼리 값을 섞지 마세요([`q` 모듈](./01-quad-module.md)의 교차 인스턴스 규칙 — 정의되지 않은 동작).

⚠️ 마운트 대상 인스턴스를 quad 밖에서(`inst:Destroy()`) 파괴하면 그 값은 영구히 죽습니다. 위 넷 가운데 `dispose: this value is still held by …` 하나에만 그 사정을 알리는 안내가 뒤에 붙습니다.

```
(if its owner was destroyed outside quad — `inst:Destroy()` — the value went with it and cannot be reused after its parent is destroyed; extract it before destroying, as with an Instance)
```

**예제**

```luau
local slot = q.Slot<<Instance>>({ D.Frame {} })
local taken = slot:Extract(1)  -- 먼저 소유에서 꺼내고
q.dispose(taken)               -- 그다음에 지운다

local temp = q.Slot<<Instance>>({ D.Frame {}, D.Frame {} })
q.dispose(temp)                -- 마운트된 적 없는 Slot은 트리째 파괴된다
```

**관련** — [인스턴스 신원과 GC 철학](../../quadnomicon/07-instance-identity-and-gc-philosophy.md), [디버깅과 문제 해결](../../how-to/09-debugging-and-troubleshooting.md)

## 죽은 Slot과 마운트 규칙

- 하나의 원소는 **동시에 한 자리에만** 마운트될 수 있습니다. 첫째 문구는 Slot이 원소를 자기 것으로 가져갈 때, 둘째 문구는 그 원소를 인스턴스의 자리(숫자 키의 Slot·정적 자식)에 마운트할 때 이미 임자가 있는 경우입니다. 이 규칙의 레지스트리는 하나라 Slot 원소·정적 자식(`D.Frame { c }`)·숏핸드가 만든 관리 자식(`UICorner = 8`의 `_quad_round`)이 서로 섞이지 않습니다 — 정적 자식을 `slot:Add`하거나 Slot 원소를 정적 자리에 놓으면 같은 문구로 거부됩니다.
- `D.<Class> { … }`가 중간에 던지면(nil 구멍, 잘못된 키) 그 전에 놓인 자식들은 반쯤 지어진 Instance에 앉은 채 남습니다 — 같은 자식으로 다시 시도하면 위의 "already mounted elsewhere"가 납니다. 그 Instance는 호출자에게 돌아오지 않지만 자식의 `Parent`로 닿으므로, 같은 자식을 다시 쓰려면 먼저 `q.dispose(child.Parent)`로 정리하세요(자식들도 같이 파괴됩니다 — 보통은 자식도 새로 만드는 편이 간단합니다).

  ```
  Quad0156 Slot: this element is already mounted — multiple mounts are not allowed (if its owner was destroyed outside quad — `inst:Destroy()` — the value went with it and cannot be reused after its parent is destroyed; extract it before destroying, as with an Instance)
  Quad0160 Bookkeeping.claimOwnerAt: this element is already mounted elsewhere — multiple mounts are not allowed (if its owner was destroyed outside quad — `inst:Destroy()` — the value went with it and cannot be reused after its parent is destroyed; extract it before destroying, as with an Instance)
  ```

- 파괴된 Slot은 되살아나지 않습니다 — `Quad0165 Slot: destroyed Slot cannot be reused`, 원소로 넣으려 하면 `Quad0169 Slot: destroyed Slot cannot be an element`, 마운트하려 하면 `Quad0164 Slot: destroyed Slot cannot be mounted`.
- 마운트 대상이 **quad 밖에서** 파괴된 Slot은 그 사실을 모릅니다(정의되지 않은 동작) — `Add`/`Replace`/`Splice`는 계속 성공하고 새 원소는 죽은 인스턴스에 붙습니다. 알아채는 자리는 `q.dispose`(`… cannot be reused after its parent is destroyed`)와 뽑아낸 원소의 재사용(`… a destroyed Instance cannot be reused`)뿐입니다. 화면을 quad 밖에서 지웠다면 그 Slot도 버리세요.
- Slot을 자기 자신이나 자기 조상에 넣는 순환은 넣는 시점에 거부됩니다. 인스턴스를 매개로 한 순환(이 Slot의 마운트 대상이나 그 조상을 원소로)은 거부되지 않고 정의되지 않은 동작입니다 — 위 `Slot:Add` 절.
