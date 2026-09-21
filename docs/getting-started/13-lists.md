---
title: "13. 목록 만들기 — Slot:List"
description: "데이터 배열 하나를 원천으로 두고, Slot:List가 항목마다 컴포넌트를 만들고 살아남은 항목은 재사용하게 합니다"
---
# [시작하기] 13. 목록 만들기 — `Slot:List`

> **대상 독자**: [12. 함수로 묶기](./12-functions.md)를 끝낸 개발자
> **목표**: 카운터를 데이터 개수만큼 그리고, 데이터가 바뀌면 필요한 것만 만들고 지우기

11장에서는 카운터 둘을 손으로 적었습니다. 개수가 데이터에 따라 달라진다면
손으로 적을 수 없습니다. `Slot`에 **`:List`를 걸면** quad가 데이터에 맞춰
자식들을 맞춰 줍니다.

권장하는 흐름은 하나입니다. **데이터 원천은 위에서 만들고, 그것을 받은
컴포넌트가 안에서 목록을 굴리고, 항목 하나하나는 다시 컴포넌트로 만든다.**

---

## 1. 데이터 원천

진입점에서 항목 배열을 담은 `Source`를 하나 만듭니다. **항목마다 변하지 않는 신원(`Id`)이 하나 있어야 합니다.**

```luau
-- (Main.client.luau 계속)
const rows = q.Source({
    { Id = "a", Label = "왼쪽", Start = 0 },
    { Id = "b", Label = "오른쪽", Start = 10 },
})
```

---

## 2. 목록을 굴리는 컴포넌트

`src/client/UI/CounterBoard.luau`를 만듭니다. 이 컴포넌트가 하는 일은 셋입니다 — 빈 `Slot`을 하나 만들고, 거기 `:List`를 걸고, 그 `Slot`을 자기 숫자 키 자리에 놓는 것.

```luau
-- 새 파일: ReplicatedStorage/Client/UI/CounterBoard
const q = require("./Quad")
const D = q.Declaration
const Counter = require("./Counter")

return function(props)
    const list = q.Slot()

    list:List(props.Rows, function(ctx)
        if ctx.Item == q.KeyGone then
            return nil, ctx.UserData          -- 이번 데이터에서 사라진 키 → 파괴
        end
        if ctx.Prev then
            return ctx.Prev, ctx.UserData     -- 이미 있는 키 → 그대로 둔다(재사용)
        end
        return Counter { Label = ctx.Item.Label, Start = ctx.Item.Start }, ctx.UserData   -- 새 키 → 만든다
    end, function(item)
        return item.Id                        -- 신원은 Id
    end)

    return D.Frame {
        Size = UDim2.fromOffset(640, 140),
        BackgroundTransparency = 1,

        D.UIListLayout { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12) },

        list,
    }
end
```

`updateFn`은 테이블 하나(`ctx`)를 받습니다. 필드는 이번 항목(`ctx.Item`), 위치(`ctx.Index`·`ctx.Offset`), 이 키가 지난번에 만든 원소(`ctx.Prev`), 이 키에 붙여 둘 자유 값(`ctx.UserData`)입니다. 돌려주는 것은 `(원소, userdata)` 둘이고, 자세한 뜻은 아래 3절의 표에서 봅니다.

<details>
<summary><strong>10장의 <code>q.Slot { … }</code>과 뭐가 다른가요?</strong></summary>

`Slot`은 **두 모드 중 하나**로만 삽니다 — 손으로 원소를 넣고 빼는 **수동 CRUD** 모드(10장)와, 데이터에 맞춰 quad가 맞춰 주는 **`:List`/`:Single`** 모드입니다. 둘은 상호 배타이고, 섞으려 하면 그 자리에서 에러가 납니다.

- `:Add`를 한 번이라도 쓴 Slot, 또는 `q.Slot { ... }`처럼 초기 원소를 주고 만든 Slot(**심지어 빈 `q.Slot {}`**)에는 `:List`를 걸 수 없습니다.
- 반대로 `:List`를 건 뒤의 수동 CRUD도 막힙니다.

그래서 목록용 Slot은 위 코드처럼 **인자 없이** `q.Slot()`으로 만듭니다.

원소가 **최대 하나**뿐인 자리를 위한 짝도 있습니다 — `:Single`이고, 아래 5절에서 다룹니다.

</details>

진입점에서는 그냥 부릅니다.

**11장에서 만든 `row`와 `row.Parent = screen` 줄, 그리고 `Counter`를 require하던 줄은 지웁니다** — 카운터 둘을 손으로 적던 자리를 이 보드가 대신합니다(`Counter`는 이제 보드가 require합니다). 11장의 `Children`과 12장의 `Watch`도 `row`와 함께 사라지지만, `Counter.luau`의 `props.Children or q.None`·`props.Watch` 두 자리는 그대로 둬도 됩니다 — 넘어오지 않으면 `q.None`이 자리를 지킵니다.

```luau
-- (Main.client.luau 계속)
const CounterBoard = require("@game/ReplicatedStorage/Client/UI/CounterBoard")

const board = CounterBoard { Rows = rows }
board.Parent = screen
```

**실행하면** 카운터 둘이 나란히 뜹니다 — 11장과 화면은 같지만, 이제 개수를 정하는 것은 코드가 아니라 `rows`입니다.

---

## 지금까지의 코드

`row`가 나가고 `CounterBoard`가 그 자리를 대신한 시점입니다.

**`Main.client.luau`**

```luau
-- (Main.client.luau — 01장부터 지금까지 전체 모습. Players·game.Loaded:Wait()·q·D·playerGui·screen은 01장 그대로입니다)
const Players = game:GetService("Players")

if not game:IsLoaded() then game.Loaded:Wait() end

const q = require("@game/ReplicatedStorage/Client/UI/Quad")
const D = q.Declaration

const playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

const screen = D.ScreenGui { ResetOnSpawn = false } -- 리스폰 때 엔진이 이 화면을 지우지 않게

const rows = q.Source({
    { Id = "a", Label = "왼쪽", Start = 0 },
    { Id = "b", Label = "오른쪽", Start = 10 },
})

const CounterBoard = require("@game/ReplicatedStorage/Client/UI/CounterBoard")

const board = CounterBoard { Rows = rows }
board.Parent = screen

screen.Parent = playerGui
```

**`CounterBoard.luau`**

```luau
-- (CounterBoard.luau — 방금 만든 전체 모습)
const q = require("./Quad")
const D = q.Declaration
const Counter = require("./Counter")

return function(props)
    const list = q.Slot()

    list:List(props.Rows, function(ctx)
        if ctx.Item == q.KeyGone then
            return nil, ctx.UserData          -- 이번 데이터에서 사라진 키 → 파괴
        end
        if ctx.Prev then
            return ctx.Prev, ctx.UserData     -- 이미 있는 키 → 그대로 둔다(재사용)
        end
        return Counter { Label = ctx.Item.Label, Start = ctx.Item.Start }, ctx.UserData   -- 새 키 → 만든다
    end, function(item)
        return item.Id                        -- 신원은 Id
    end)

    return D.Frame {
        Size = UDim2.fromOffset(640, 140),
        BackgroundTransparency = 1,

        D.UIListLayout { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12) },

        list,
    }
end
```

`Counter.luau`는 [12장](./12-functions.md)에서 끝난 모습(`highlightColor` 파이프, `props.Children or q.None`, `props.Watch` 갈래) 그대로라 여기서는 바뀐 게 없어 다시 싣지 않습니다 — `CounterBoard`의 `updateFn`은 그중 `Label`·`Start`만 씁니다.

---

## 3. 데이터를 바꾸면 필요한 것만 바뀝니다

항목을 추가하는 버튼을 하나 답니다. 하는 일은 **`props.Rows`에 새 배열을 넣는 것뿐**입니다 — 보드가 받은 그 `Source`를 그대로 씁니다.

```luau
-- … (CounterBoard.luau) 돌려주는 D.Frame의 list 뒤에 원소 하나 더
        D.TextButton {
            Size = UDim2.fromOffset(120, 40),
            Text = "+ 카운터",
            Activated = function()
                const nextRows = table.clone(props.Rows:Get())
                table.insert(nextRows, { Id = `c{#nextRows}`, Label = "새 카운터", Start = 0 })
                props.Rows:Set(nextRows)
            end,
        },
```

여기서 id를 배열 길이로 만든 것은 예제라서입니다. 항목을 지우기 시작하면 같은 id가 다시 만들어져 `Slot:List: duplicate key c2`로 그 자리에서 막히니, 실제 코드에서는 절대 줄지 않는 카운터나 서버가 준 id를 쓰세요.
<!-- mock 실측 2026-09-11: gs.polish3.luau "13 dup key" — 같은 키 둘이면 `Slot:List: duplicate key a` -->
<!-- mock 실측 2026-09-11: gs.board.luau — 보드 안 버튼이 props.Rows:Set → 자식 3(카운터 둘+버튼)에서 4로 -->

**실행하면** 카운터가 하나 더 생깁니다. 여기서 중요한 것은 **안 생긴 것**입니다.

- 이미 있던 `a`·`b`는 **다시 만들어지지 않습니다.** `updateFn`이 `ctx.Prev`를 그대로 돌려준 갈래가 "그 자리에 계속 두라"는 뜻이고, 그 인스턴스는 신원까지 그대로입니다(누르던 카운트도 그대로 남습니다).
- 새로 생긴 키 하나에만 `Counter { ... }`가 한 번 불립니다.
- 반대로 데이터에서 어떤 키가 빠지면 그 키에 `q.KeyGone`으로 `updateFn`이 한 번 더 불리고, 위 코드처럼 `nil`을 돌려주면 그 인스턴스가 **파괴됩니다.**

<details>
<summary><strong>빠진 항목을 파괴하지 않고 잠깐 숨겨 두려면요?</strong></summary>

`q.Detach`를 돌려주면 됩니다. 그 원소를 트리에서 떼되 **파괴하지 않고 들고 있다가**, 같은 키가 다시 나타났을 때 `ctx.Prev`를 돌려주면 만들지 않고 그대로 다시 붙습니다. 탭 전환처럼 숨겼다 되살리는 자리의 도구입니다.

```luau
-- … (CounterBoard.luau) updateFn의 첫 갈래
if ctx.Item == q.KeyGone then
    return q.Detach, ctx.UserData    -- 파괴 대신 보관
end
```

원소를 **밖에서** 관리하고 싶다면 `opts.OwnsElements = false`가 있습니다 — `list:List(data, updateFn, keyFn, { OwnsElements = false })`처럼 주면 이 Slot이 원소를 파괴하지 않고 목록에서 빠질 때 언마운트만 합니다.

</details>

### `updateFn`이 돌려줄 수 있는 것 넷

호출은 `updateFn(ctx)`입니다. `ctx`의 필드는 `Item`(이번 항목), `Index`(이 Slot 안에서의 물리 위치), `Offset`(이 Slot의 `Offset` State), `Prev`(이 키가 지난번에 만든 원소), `UserData`(이 키의 자유 값)입니다(각각의 정확한 뜻은 [레퍼런스: `slot:List`](../reference/core/06-slot.md#slotlistdata-updatefn-keyfn-opts)). 돌려주는 것은 `(결과, userdata)` 둘이고, 결과 자리에 무엇을 놓느냐가 그 항목의 운명을 정합니다.

| 무엇을 돌려주나 | 무슨 일이 일어나나 |
|---|---|
| **`ctx.Prev` 그대로** | 그 자리에 계속 둡니다 — 마운트도 파괴도 없는 **가장 싼 경로** |
| **새 값** | `ctx.Prev`가 있었다면 파괴되고 새 값이 그 자리를 대신합니다 |
| **`nil` 또는 `q.None`** | `ctx.Prev`가 있었다면 파괴됩니다 |
| **`q.Detach`** | 파괴하지 않고 트리 밖에 붙들어 둡니다. 그 키가 다시 오면 같은 원소가 그대로 재마운트됩니다 |

**순서는 quad가 정하지 않습니다.** `Slot`은 `LayoutOrder`라는 이름을 알지 못합니다 — `ctx.Index`와 `ctx.Offset`을 넘겨줄 뿐, 그것을 `LayoutOrder`에 쓸지 `Position`에 쓸지는 `updateFn`을 쓰는 쪽의 몫입니다([10장](./10-slot.md) 5절이 그 계산이고, 위 예제는 항목을 뒤에 붙이기만 해서 배치를 `UIListLayout`에 맡겼습니다 — 데이터 중간에 항목이 끼어들 수 있다면 `ctx.Index`/`ctx.Offset`으로 `LayoutOrder`를 채우세요).

---

## 4. 이미 있는 항목의 값이 바뀔 때

`ctx.Prev`를 돌려주는 갈래는 **인스턴스를 다시 만들지 않습니다.** 그래서 라벨 텍스트처럼 항목마다 바뀌는 값은 다른 길로 넣어야 합니다 — `userdata`에 `Source`를 넣어 두고 **그 `Source`만 `:Set`** 하는 것이 정본 관용구입니다.

항목이 라벨 한 줄인 더 작은 목록으로 보겠습니다 — 위 `CounterBoard`와 겹치지 않게 데이터도 따로 둡니다.

```luau
-- 새 예시: 별도 스크립트 — 항목마다 바뀌는 값을 userdata의 Source로 들고 있는 목록
const logRows = q.Source({
    { Id = "a", Label = "왼쪽" },
    { Id = "b", Label = "오른쪽" },
})

const list = q.Slot()

list:List(logRows, function(ctx)
    if ctx.Item == q.KeyGone then
        return nil, ctx.UserData
    end
    if ctx.Prev then
        ctx.UserData:Set(ctx.Item.Label)   -- ← 인스턴스는 그대로, 값만 갈아 끼운다
        return ctx.Prev, ctx.UserData
    end
    const label = q.Source(ctx.Item.Label)
    return D.TextLabel { Text = label }, label   -- ← 두 번째 반환이 다음 ctx.UserData
end, function(item)
    return item.Id
end)

const box = D.Frame { BackgroundTransparency = 1, list }
```

`a` 항목의 라벨만 바꿔 넣고, 새 키 `c`를 하나 더합니다.

```luau
-- … 위쪽 코드에 이어집니다
const first = box:GetChildren()[1]

logRows:Set({
    { Id = "a", Label = "왼쪽(수정)" },
    { Id = "b", Label = "오른쪽" },
    { Id = "c", Label = "새로" },
})

print(#box:GetChildren())              --> 3              (c만 새로 만들어졌다)
print(box:GetChildren()[1].Text)       --> "왼쪽(수정)"
print(box:GetChildren()[1] == first)   --> true           (같은 인스턴스다)
```

**실행하면** `a`의 글씨만 새것으로 바뀌고, 그 라벨 인스턴스는 처음 만든 그대로입니다. 새로 만들어지는 것은 새 키 `c` 하나뿐입니다.

두 번째 반환값이 곧 **그 키의 다음 `userdata`**라, 새로 만드는 갈래에서 `Source`를 돌려주면 그 다음 사이클부터 `ctx.UserData`로 돌아옵니다.


---

## 5. 원소가 최대 하나라면 — `:Single`

[10장 6절](./10-slot.md)에서 자식 하나를 갈아 끼울 때는 `Slot`도 `:List`도 없이 **`State`를 자리에 놓기만** 했습니다. 대부분은 그걸로 충분합니다. 그런데 그 방법에는 한 가지가 없습니다 — **`Offset`을 받을 수 없습니다.** 그 자리는 `Offset` 발행 채널을 두지 않기 때문입니다.

앞 Slot이 자라면 내 자리도 밀리는데 **그 순번 자체가 필요할 때**(`LayoutOrder`가 대표적입니다) `:Single`을 직접 겁니다.

```luau
-- 새 예시: 별도 스크립트
const cur = q.Source<<string?>>(nil)

const single = q.Slot<<Instance>>():Single(cur, function(ctx)
    if ctx.Item == q.KeyGone then
        return nil                        -- 값이 nil이 되면 그 원소를 파괴한다
    end
    return D.TextLabel {
        Text = ctx.Item,
        LayoutOrder = ctx.Offset:Compute(function(o) return o:Get() + 1 end),
    }
end)

const top = q.Slot { D.TextLabel { Text = "T1" }, D.TextLabel { Text = "T2" } }

const panel = D.Frame {
    D.TextLabel { Text = "머리" },   -- 고정 자식 하나
    top,                             -- 앞 구간(지금은 둘)
    single,
}

cur:Set("지금 화면")
print(single:Get(1).LayoutOrder)   --> 4      (머리 하나 + top 둘 = Offset 3; :Get(index)는 그 자리의 원소를 읽습니다)

top:Add(D.TextLabel { Text = "T3" })
print(single:Get(1).LayoutOrder)   --> 5      (앞이 자라 밀렸다)

top:Remove(1)
print(single:Get(1).LayoutOrder)   --> 4      (앞이 줄어 당겨졌다)
```

**실행하면** 내 원소는 그대로인 채 `LayoutOrder`만 앞 구간을 따라 움직입니다. `Offset`이 `State`라서 `:Compute`로 이어 붙이면 그 뒤로는 quad가 알아서 갱신합니다.
<!-- mock 실측 2026-09-11: gs.gs6probe.luau S1~S4 — LayoutOrder 4 → 5 → 4, cur:Set(nil)이면 자식 수가 4에서 3으로 -->

<details>
<summary><strong>자리에 놓은 <code>State</code>와 뭐가 다른가요?</strong></summary>

`updateFn`을 아예 생략하면 값을 그대로 원소로 씁니다(`q.Slot():Single(cur)`). [10장 6절](./10-slot.md)에서 `State`를 자리에 놓은 것과 **겉보기 결과는 같지만 안쪽은 다릅니다** — 자리에 놓은 `State`는 `:Single`이 아니라 자식 인스턴스 처리기가 맡습니다([19장](./19-handlers.md)). 소유권 차이도 그래서 생깁니다: 자리에 놓은 `State`는 갈아 끼운 옛 원소를 내려놓기만 하지만, 직접 건 `:Single`은 **파괴합니다**(옛 원소를 살려 두고 싶으면 `{ OwnsElements = false }`를 세 번째 인자로 주면 됩니다).
<!-- mock 실측 2026-09-11: gs.gs6probe.luau S5 — 직접 건 :Single에서 교체된 옛 원소는 파괴됨(isDestroyed true) -->

</details>

`updateFn`은 `:List`의 것과 **같은 규칙**입니다 — 같은 모양의 `ctx`를 받고(`ctx.Index`도 옵니다), 돌려줄 수 있는 것도 위 표 그대로(`ctx.Prev` 재사용 / 새 값 / `nil`·`q.None` / `q.Detach`)입니다. 그래서 같은 `updateFn`을 `:List`와 `:Single`에 나눠 쓸 수도 있습니다. 값이 `nil`이 되면 `ctx.Item`으로 `q.KeyGone`이 옵니다.

---

## 이해 점검

```quiz
# 목록용 Slot을 만드는 법

`:List`를 걸 Slot은 왜 인자 없이 `q.Slot()`으로 만드나요?

- [x] `Slot`은 수동 CRUD와 `:List`/`:Single` 중 한 모드로만 살고, 두 모드는 섞을 수 없기 때문입니다
- [ ] 초기 원소를 주고 만들어도 되고, `:List`를 걸면 그 원소 뒤로 데이터가 이어 붙습니다
- [ ] `:List`를 건 뒤에도 `:Add`로 항목을 더 넣을 수 있어 초기 원소는 아무 때나 채우면 됩니다

두 모드를 섞으려 하면 그 자리에서 에러가 납니다 — 초기 원소를 준 Slot에 `:List`를 거는 것도, `:List`를 건 뒤에 수동 CRUD를 부르는 것도 막힙니다.
```

```quiz
# `updateFn`이 돌려주는 것

`updateFn`의 결과 자리에 놓는 값의 뜻으로 옳은 것은 무엇인가요?

- [ ] `nil`을 돌려주면 그 원소가 트리에서 떼어져 보관됐다가 같은 키가 다시 오면 붙습니다
- [x] `ctx.Prev`를 그대로 돌려주면 마운트도 파괴도 없이 그 자리에 계속 둡니다
- [ ] 새 값을 돌려주면 `ctx.Prev`도 그대로 남아 그 자리에 둘이 함께 놓입니다

`nil`이나 `q.None`은 `ctx.Prev`가 있었다면 파괴하고, 파괴하지 않고 붙들어 두는 쪽은 `q.Detach`입니다. 새 값을 돌려주면 `ctx.Prev`는 파괴되고 새 값이 그 자리를 대신합니다.
```

```quiz
# 이미 있는 항목의 값이 바뀔 때

`ctx.Prev`를 돌려주는 재활용 갈래에서 라벨 텍스트처럼 항목마다 바뀌는 값은 어떻게 넣나요?

- [ ] `ctx.Item`이 바뀌면 quad가 그 인스턴스의 프로퍼티를 알아서 갱신해 줍니다
- [ ] 값이 바뀐 항목은 새 값을 돌려줘 인스턴스를 다시 만드는 것이 정본입니다
- [x] `userdata`에 `Source`를 넣어 두고 그 `Source`만 `:Set` 합니다

`ctx.Prev`를 돌려주는 갈래는 인스턴스를 다시 만들지 않으므로 바뀌는 값은 다른 길로 넣어야 합니다. 새로 만드는 갈래에서 `Source`를 만들어 프로퍼티에 꽂고 두 번째 반환값(`userdata`)으로 돌려주면, 다음 사이클의 `ctx.UserData`로 그 `Source`가 돌아와 `:Set`만 하면 됩니다.
```

---

## 더 알고 싶다면

- [레퍼런스: `Slot`](../reference/core/06-slot.md) — `:List`/`:Single`의 전체 계약, 에러 문구, `Detach`·`KeyGone`·`OwnsElements`
- [03. `Slot:List`로 긴 목록 다루기](../how-to/03-virtualized-infinite-scroll.md) — 수백~수만 개짜리 목록의 윈도잉과 `Throttle`
