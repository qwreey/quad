---
title: Slot
description: 가변 자식 배열 프리미티브 — CRUD 열셋, :List/:Single 재조정, Detach/KeyGone, dispose
---

# Slot\<T\>

`Slot<T>`은 **가변 자식 배열**입니다. 부모의 숫자 키 자리에 한 번 놓이면, 그 뒤로 Slot에 가한 CRUD가 그대로 물리 자식에 반영됩니다 — 부모를 다시 만들지도, 렌더 함수를 다시 돌리지도 않습니다.

Slot은 **두 모드 중 하나**로만 삽니다. 손으로 원소를 넣고 빼는 **수동 CRUD** 모드와, 데이터 배열에 맞춰 quad가 재조정하는 **`:List`/`:Single`** 모드입니다. 둘은 상호 배타이고, 섞으려 하면 그 자리에서 에러가 납니다.

이 페이지의 심볼: [`q.Slot`](#qslottinitial) · [`slot.Length`](#slotlength) · [`slot.Offset`](#slotoffset) · [`slot:Add`](#slotaddelement-index) · [`slot:Remove`](#slotremoveindex) · [`slot:Replace`](#slotreplaceindex-newelement) · [`slot:Extract`](#slotextractindex-newelement) · [`slot:ExtractAll`](#slotextractall) · [`slot:Splice`](#slotspliceindex-removecount-newelements) · [`slot:Clear`](#slotclear) · [`slot:Move`](#slotmoveoldindex-newindex) · [`slot:Swap`](#slotswapindexa-indexb) · [`slot:Get`](#slotgetindex) · [`slot:IndexOf`](#slotindexofelement) · [`slot:List`](#slotlistdata-updatefn-keyfn-opts) · [`slot:Single`](#slotsinglestate-updatefn-opts) · [`q.Detach`](#qdetach) · [`q.KeyGone`](#qkeygone) · [`q.dispose`](#qdisposevalue)

이 페이지의 모든 예제는 아래 프롤로그를 전제합니다.

```luau
-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 참고)
local Quad = require(<quad-base 모듈 경로>)
local QuadRoblox = require(<quad-roblox 모듈 경로>).QuadRoblox
local QuadTypes = require(<quad-types 모듈 경로>) -- 타입 주석용(`QuadTypes.SlotItem<T>` 등)
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
local D = q.D
```

## 원소 대수 — 넣는 자리와 꺼내는 자리의 타입이 다르다

```luau
-- 입력 자리(생성자 initial, Add/Replace/Extract의 새 원소, Splice, IndexOf)
type SlotElement<T> = T | StateMarker<T> | SlotMarker<T>
-- 출력 자리(Get/Extract/ExtractAll/Splice의 반환, updateFn의 prev)
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
- `Slot: destroyed Slot cannot be an element`

## `q.Slot<<T>>(initial?)`

**시그니처**

```luau
Slot: <T>(initial: { SlotElement<T> }?) -> Slot<T>
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `initial` | `{ SlotElement<T> }?` | 초기 원소 배열. `:Add`를 순서대로 부른 것과 같습니다 |

**반환** — 새 `Slot<T>`. 아직 어디에도 마운트되지 않은 상태입니다.

**동작**

- 타입 인자를 안 주면 `q.Slot()`은 `Slot<unknown>`으로 추론됩니다. strict 모드에서는 `q.Slot<<Instance>>()`처럼 **명시적으로 인스턴스화**하세요.
- `initial`을 주면 — **빈 `Slot{}`이라도** — 그 Slot은 수동 CRUD Slot으로 고정됩니다. 나중에 `:List`를 걸 수 없습니다.
- `initial`은 **평범한 배열**이어야 합니다. 값 하나를 괄호 없이 넘기거나(`Slot(frame)`) 정수가 아닌 키를 섞으면 에러입니다.
  - `Slot: initial elements must be a plain { element, ... } array (got {typeof(initial)} — a bare element or quad value needs the braces)`
  - `Slot: initial elements must be an array — key "{tostring(k)}" is not an array position`
- 배열 안의 중복(같은 원소 두 번)과 이미 다른 곳에 마운트된 원소는 원소를 하나도 넣기 전에 한 번에 검사됩니다.
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
Length: Source<number>
```

**동작** — 이 Slot이 차지하는 **물리 원소의 총 개수**를 싣는 반응형 `Source<number>`입니다. 중첩 Slot은 자기 물리 잎의 수만큼 기여하므로, 원소 배열의 길이(`#`)와 항상 같지는 않습니다.

**마운트 전에는 0입니다.** 채워지는 것은 부기(bookkeeping) 재계산이고, 그건 Slot이 실제로 어딘가에 놓인 뒤에 돕니다. 그래서 `:Add` 직후에 `Length:Get()`을 읽으면 아직 0일 수 있습니다.

`Source`이므로 `:Compute`/`:Observer`로 그대로 구독할 수 있습니다.

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
Offset: Source<number>
```

**동작** — 마운트 대상 안에서 이 Slot의 첫 원소가 시작하는 **절대 물리 위치**를 싣는 `Source<number>`입니다. 형제가 앞에서 길이를 바꾸면 이 값이 따라 움직입니다. `Length`와 짝을 이루어 접두합을 만들고, `:List`의 `updateFn`이 네 번째 자리에서 받는 것도 이 Source입니다.

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
- 삽입 위치는 `n+1`(맨 뒤 다음)까지 허용됩니다. 그 밖은 에러입니다 — `Slot:Add: index out of range (got {index}, limit {limit})`, 정수가 아니면 `Slot:Add: index must be a positive integer (got {tostring(index)})`.
- 이미 다른 곳에 마운트된 값은 거부됩니다. 문구 뒤에 붙는 꼬리 안내는 아래 "죽은 Slot과 마운트 규칙" 절의 것과 같습니다.

  ```
  Slot:Add: this element is already mounted — multiple mounts are not allowed (if its owner was destroyed outside quad — `inst:Destroy()` — the value went with it and cannot be reused after its parent is destroyed; extract it before destroying, as with an Instance)
  ```

- Slot을 자기 자신이나 자기 조상에 넣으면 순환이라 거부됩니다 — `Slot:Add: cannot add a Slot to itself or to one of its own descendants (that would be a cycle)`.
- 단일 `Add`는 현재 길이에 비례하는 비용을 냅니다. 여러 개를 한 번에 넣을 때는 [`:Splice`](#slotspliceindex-removecount-newelements)를 쓰세요.

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

**동작** — 그 자리의 원소를 떼고 **파괴합니다**. 살려서 꺼내려면 [`:Extract`](#slotextractindex-newelement)를 쓰세요. 범위는 1..n이고 클램프는 없습니다.

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

**동작** — 구간 제거와 삽입을 **한 번의 재계산**으로 처리합니다. 여러 원소를 한꺼번에 넣는 정본 경로입니다. `removeCount`가 남은 개수를 넘으면 `Slot:Splice: removeCount out of range`.

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

## `slot:Swap(indexA, indexB)`

**시그니처**

```luau
Swap: (self: Slot<T>, indexA: number, indexB: number) -> ()
```

**동작** — 두 자리를 맞바꿉니다. 같은 인덱스를 두 번 주면 아무 일도 하지 않습니다.

## `slot:Get(index)`

**시그니처**

```luau
Get: (self: Slot<T>, index: number) -> SlotItem<T>?
```

**반환** — 그 자리의 원소(언래핑됨). 범위 밖이면 `nil`.

**동작** — 읽기 전용이라 수동/재조정 모드를 고정하지 않습니다. 다만 인덱스가 숫자가 아니면 "빈 Slot"처럼 조용히 `nil`을 주지 않고 던집니다 — `Slot:Get: index must be a number (got {typeof(index)})`.

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
    updateFn: (item: Item | KeyGone, index: number, offset: Source<number>, prev: SlotItem<T>?, userdata: UD?) -> (any, UD?),
    keyFn: ((item: Item, index: number) -> any)?,
    opts: SlotListOpts?
) -> Slot<T>

type SlotListOpts = { Owned: boolean? }
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `data` | `{ Item }` 또는 그걸 담은 State | 재조정의 원본. State면 값이 바뀔 때마다 다시 돕니다 |
| `updateFn` | 함수 | 항목 하나를 어떻게 만들/유지/버릴지 결정합니다(아래 계약) |
| `keyFn` | `((item, index) -> any)?` | 항목의 신원. 기본값은 **인덱스**입니다 |
| `opts` | `{ Owned: boolean? }?` | `Owned = false`면 이 Slot이 원소를 파괴하지 않습니다 |

**반환** — `self`(체이닝용).

**`updateFn` 계약**

호출 시그니처는 `updateFn(item, index, offset, prev, userdata) -> (result, userdata)`입니다.

| 자리 | 뜻 |
|---|---|
| `item` | 이번 사이클의 데이터 항목. 지난 사이클에 있었는데 이번엔 사라진 키에는 `q.KeyGone`이 옵니다 |
| `index` | 이 Slot 안에서의 물리 위치(`Offset` 기준 1부터). 중첩 Slot이 섞여 있으면 데이터 배열의 인덱스와 다릅니다 |
| `offset` | 이 Slot의 `Offset` Source 자체 — 값이 아니라 핸들입니다 |
| `prev` | 이 키가 지난번에 만든 원소(언래핑됨). 처음이면 `nil` |
| `userdata` | 지난 호출이 두 번째로 반환한 값. 키마다 따로 보관됩니다 |

반환값 `result`의 뜻은 넷입니다.

| 반환 | 뜻 |
|---|---|
| 새 원소 | 그 자리에 놓습니다. `prev`가 있었으면 교체(소유 Slot이면 옛 원소 파괴) |
| `prev` 그대로 | 그대로 유지 — 다시 만들지 않습니다. 위치만 필요하면 옮깁니다 |
| `nil` 또는 `q.None` | 이 키를 버립니다(소유 Slot이면 파괴) |
| `q.Detach` | 트리에서 떼되 **파괴하지 않고** 보관합니다. 다음에 `prev`를 반환하면 그대로 다시 붙습니다 |

두 번째 반환값은 이 키의 다음 `userdata`가 됩니다.

**동작**

- `:List`는 **설치**입니다. 한 Slot에 한 번만 걸 수 있고, 수동 CRUD를 이미 쓴 Slot(빈 `Slot{}` 포함)에는 걸 수 없습니다.
  - `Slot: already has :List/:Single installed`
  - `Slot: cannot install :List/:Single on a manual Slot (one that used CRUD or was built as Slot{ ... }, even empty)`
  - 반대로 `:List`를 건 뒤의 수동 CRUD는 `Slot: manual CRUD is not allowed after :List/:Single`.
- 재조정은 마운트 시점과 이후 `data`가 바뀔 때마다 돕니다. 한 사이클은 **하나의 배치**로 묶여 재계산이 한 번만 일어납니다.
- 사이클 순서는 (1) 데이터 순서대로 키를 계산해 중복/누락을 먼저 검사, (2) 항목마다 `updateFn`, (3) 지난 사이클에 있었지만 이번엔 없는 키에 `q.KeyGone`으로 `updateFn`을 한 번 더 — 입니다.
- `KeyGone` 호출에서는 `nil`/`q.None`(파괴)과 `q.Detach`(보관)만 반환할 수 있습니다. 새 원소를 반환하면 `Slot:List: KeyGone accepts only nil/None (destroy) or Detach (hold)`.
- 인자 검증 에러: `Slot:List: updateFn must be a function (got {typeof(updateFn)})`, `Slot:List: data must be a plain array or a State of one (got {typeof(data)})`, `Slot:List: keyFn must be a function (got {typeof(keyFn)})`.
- 재조정 중 에러: `Slot:List: data must be a plain array (got {typeof(items)}) — a data State must hold one too`, `Slot:List: keyFn returned nil for item #{i}`, `Slot:List: duplicate key {tostring(key)}`.
- `updateFn`이 이 Slot의 `data` State를 다시 `:Set` 하는 **재진입**은 정의되지 않은 동작입니다.

**`Owned = false`**

기본은 소유(`Owned = true`)입니다 — 이 Slot이 버리는 원소는 파괴됩니다. `Owned = false`를 주면 버릴 때 소유권만 풀고 살려둡니다. 그 Slot이 통째로 파괴돼도 원소는 살아남아 다른 Slot에 다시 넣을 수 있습니다. 원소를 밖에서 관리하는 가상화 목록이나 포털이 이 옵션의 자리입니다.

**예제**

`--!strict`에서는 `updateFn`의 **파라미터 전부와 반환 팩**에 주석을 달아야 합니다 — 반환이 갈래마다 다른 타입이라, 주석이 없으면 첫 `return`에서 반환 타입이 굳어 나머지 갈래가 거부됩니다.

```luau
type Row = { Id: string, Title: string }

local rows = q.Source<<{ Row }>>({ { Id = "a", Title = "첫째" } })
local slot = q.Slot<<Instance>>()

slot:List(rows, function(
    item: Row | QuadTypes.KeyGone,
    index: number,
    offset: QuadTypes.Source<number>,
    prev: QuadTypes.SlotItem<Instance>?,
    ud: nil
): (any, nil)
    if item == q.KeyGone then
        return nil            -- 사라진 키: 파괴
    end
    if prev then
        return prev           -- 이미 있는 키: 그대로 둔다
    end
    return D.TextLabel { Text = (item :: Row).Title }
end, function(item: Row)
    return item.Id            -- 신원은 Id
end)

local view = D.Frame { slot }
rows:Set({ { Id = "b", Title = "둘째" }, { Id = "a", Title = "첫째" } }) -- a는 재사용, b는 새로 생성
```

`userdata`를 쓴다면 `ud`와 반환 팩의 두 번째 자리에 그 타입을 적습니다 — `ud: RowUD?` / `: (any, RowUD?)`.

**관련** — [가상화 무한 스크롤](../../how-to/03-virtualized-infinite-scroll.md), [DOMless Slot](../../quadnomicon/09-fragment-breakthrough-and-domless-slot.md)

## `slot:Single(state, updateFn?, opts?)`

**시그니처**

```luau
Single: <Item, UD>(
    self: Slot<T>,
    state: Item? | StateMarker<Item?>,
    updateFn: ((item: Item | KeyGone, offset: Source<number>, prev: SlotItem<T>?, userdata: UD?) -> (any, UD?))?,
    opts: SlotListOpts?
) -> Slot<T>
```

타입 인자는 `:List`와 같은 `<Item, UD>`입니다 — `state`가 담는 것은 **데이터**(`Item`)이고, 원소 타입 `T`와 묶이지 않습니다. `Source<string?>`로 `Slot<Instance>`를 `updateFn`으로 매핑해 모는 모양이 그대로 타입 검사를 통과합니다. `updateFn`을 생략하는 항등 사용에서는 `Item`이 곧 원소라 `T`로 두시면 됩니다(다른 것을 넘기면 타입이 아니라 런타임 가드 `Slot: this backend cannot mount this value`가 잡습니다).

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `state` | `Item?` 또는 그걸 담은 State | 이 Slot이 실을 **한 개**의 데이터 — `updateFn`이 원소로 바꿉니다 |
| `updateFn` | 함수? | 생략하면 항등 — 값을 그대로 원소로 씁니다(그때 `Item`은 원소 타입) |
| `opts` | `{ Owned: boolean? }?` | `:List`와 같습니다 |

**반환** — `self`.

**동작**

- 원소가 최대 하나인 `:List`입니다. 설치 규칙·모드 배타성·`Owned` 의미는 전부 `:List`와 같습니다.
- `updateFn`의 인자에서 `index`가 빠집니다 — `(item, offset, prev, userdata)`.
- `state`의 값이 `nil`이거나 `q.None`이면 원소가 없는 상태입니다. `updateFn`에는 그때 `q.KeyGone`이 옵니다.
- `state`가 State면 값이 바뀔 때마다 그 자리가 통째로 교체됩니다.
- 인자 검증 에러: `Slot:Single: updateFn must be a function (got {typeof(updateFn)})`.

`Slot`에 State를 원소로 넣는 `slot:Add(someState)`는 내부적으로 `Owned = false`인 래퍼 Slot에 `:Single`을 건 것과 같습니다.

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

**동작** — `:List`/`:Single`의 `updateFn`이 반환하는 센티널입니다. "이 원소를 트리에서 떼되 파괴하지는 말고 들고 있어라"라는 뜻입니다. 다음 사이클에 같은 키가 다시 나타났을 때 `prev`를 반환하면 **만들지 않고 그대로 다시 붙습니다**.

보관 중인 detach 원소는 Slot이 소유합니다 — Slot이 파괴될 때 같이 파괴됩니다(`Owned = false`면 살아남습니다). 판정은 신원 비교(`result == q.Detach`)입니다.

**예제**

```luau
type Row = { Id: string }

local visible = q.Source(true)
local rows = q.Source<<{ Row }>>({ { Id = "a" } })
local slot = q.Slot<<Instance>>()

slot:List(rows, function(
    item: Row | QuadTypes.KeyGone,
    _index: number,
    _offset: QuadTypes.Source<number>,
    prev: QuadTypes.SlotItem<Instance>?,
    _ud: nil
): (any, nil)
    if item == q.KeyGone then return q.Detach end
    if not visible:Get() then return q.Detach end -- 숨김: 떼되 살려둔다
    if prev then return prev end                  -- 복귀: 그대로 다시 붙는다
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

**동작** — 재조정 사이클의 마지막에, **지난 사이클에는 있었지만 이번 데이터에는 없는 키**마다 `updateFn`의 `item` 자리에 오는 센티널입니다. 그 키가 만든 원소를 어떻게 할지 정하라는 물음입니다.

이 호출에서 허용되는 반환은 `nil`/`q.None`(버림)과 `q.Detach`(보관) 둘뿐입니다. `updateFn`의 첫 줄에서 신원 비교로 갈라내는 것이 관용구입니다.

```luau
if item == q.KeyGone then
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

- `dispose: value must not be nil`
- `dispose: this value is still held by a Slot or a mounted position — Remove/Extract it from a manual Slot, drop its key from a :List Slot's data, or destroy the owner Slot (a detached element goes with its owner)`
- `dispose: this backend cannot dispose this value`

⚠️ 마운트 대상 인스턴스를 quad 밖에서(`inst:Destroy()`) 파괴하면 그 값은 영구히 죽습니다. 위 셋 가운데 `dispose: this value is still held by …` 하나에만 그 사정을 알리는 안내가 뒤에 붙습니다.

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

- 하나의 원소는 **동시에 한 자리에만** 마운트될 수 있습니다. 첫째 문구는 Slot이 원소를 자기 것으로 가져갈 때, 둘째 문구는 그 원소를 인스턴스의 자리에 마운트할 때 이미 임자가 있는 경우입니다.

  ```
  Slot: this element is already mounted — multiple mounts are not allowed (if its owner was destroyed outside quad — `inst:Destroy()` — the value went with it and cannot be reused after its parent is destroyed; extract it before destroying, as with an Instance)
  Slot: this element is already mounted elsewhere — multiple mounts are not allowed (if its owner was destroyed outside quad — `inst:Destroy()` — the value went with it and cannot be reused after its parent is destroyed; extract it before destroying, as with an Instance)
  ```

- 파괴된 Slot은 되살아나지 않습니다 — `Slot: destroyed Slot cannot be reused`, 원소로 넣으려 하면 `Slot: destroyed Slot cannot be an element`, 마운트하려 하면 `Slot: destroyed Slot cannot be mounted`.
- Slot을 자기 자신이나 자기 조상에 넣는 순환은 넣는 시점에 거부됩니다.
