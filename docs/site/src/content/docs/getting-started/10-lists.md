---
title: "10. 목록 만들기 — Slot:List"
description: "데이터 배열 하나를 원천으로 두고, Slot:List가 항목마다 컴포넌트를 만들고 살아남은 항목은 재사용하게 합니다"
---
> **대상 독자**: [09. 컴포넌트로 쪼개기](/getting-started/09-components/)를 끝낸 개발자
> **목표**: 카운터를 데이터 개수만큼 그리고, 데이터가 바뀌면 필요한 것만 만들고 지우기

09장에서는 카운터 둘을 손으로 적었습니다. 개수가 데이터에 따라 달라진다면
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
const D = q.D
const Counter = require("./Counter")

return function(props)
    const list = q.Slot()

    list:List(props.Rows, function(item, index, offset, prev, ud)
        if item == q.KeyGone then
            return nil, ud                    -- 이번 데이터에서 사라진 키 → 파괴
        end
        if prev then
            return prev, ud                   -- 이미 있는 키 → 그대로 둔다(재사용)
        end
        return Counter { Label = item.Label, Start = item.Start }, ud   -- 새 키 → 만든다
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

<details>
<summary><strong>08장의 <code>q.Slot { … }</code>과 뭐가 다른가요?</strong></summary>

`Slot`은 **두 모드 중 하나**로만 삽니다 — 손으로 원소를 넣고 빼는 **수동 CRUD** 모드(08장)와, 데이터에 맞춰 quad가 맞춰 주는 **`:List`/`:Single`** 모드입니다. 둘은 상호 배타이고, 섞으려 하면 그 자리에서 에러가 납니다.

- `:Add`를 한 번이라도 쓴 Slot, 또는 `q.Slot { ... }`처럼 초기 원소를 주고 만든 Slot(**심지어 빈 `q.Slot {}`**)에는 `:List`를 걸 수 없습니다.
- 반대로 `:List`를 건 뒤의 수동 CRUD도 막힙니다.

그래서 목록용 Slot은 위 코드처럼 **인자 없이** `q.Slot()`으로 만듭니다.

원소가 최대 하나면 `:Single`이 있습니다 — `updateFn`에서 `index`가 빠지는 것 말고는 `:List`와 규칙이 같습니다. "현재 화면 하나만 띄우기" 같은 전환이 그 자리입니다.

</details>

진입점에서는 그냥 부릅니다.

```luau
-- (Main.client.luau 계속)
const CounterBoard = require("@game/ReplicatedStorage/Client/UI/CounterBoard")

const board = CounterBoard { Rows = rows }
board.Parent = screen
```

**실행하면** 카운터 둘이 나란히 뜹니다 — 09장과 화면은 같지만, 이제 개수를 정하는 것은 코드가 아니라 `rows`입니다.

---

## 3. 데이터를 바꾸면 필요한 것만 바뀝니다

항목을 추가하는 버튼을 하나 답니다. 하는 일은 **`rows`에 새 배열을 넣는 것뿐**입니다.

```luau
-- … Main.client.luau의 화면 어딘가에 이어집니다
D.TextButton {
    Text = "+ 카운터",
    Activated = function()
        const nextRows = table.clone(rows:Get())
        table.insert(nextRows, { Id = `c{#nextRows}`, Label = "새 카운터", Start = 0 })
        rows:Set(nextRows)
    end,
},
```

**실행하면** 카운터가 하나 더 생깁니다. 여기서 중요한 것은 **안 생긴 것**입니다.

- 이미 있던 `a`·`b`는 **다시 만들어지지 않습니다.** `updateFn`이 `prev`를 그대로 돌려준 갈래가 "그 자리에 계속 두라"는 뜻이고, 그 인스턴스는 신원까지 그대로입니다(누르던 카운트도 그대로 남습니다).
- 새 키 `c`만 `Counter { ... }`가 한 번 불립니다.
- 반대로 데이터에서 어떤 키가 빠지면 그 키에 `q.KeyGone`으로 `updateFn`이 한 번 더 불리고, 위 코드처럼 `nil`을 돌려주면 그 인스턴스가 **파괴됩니다.**

<details>
<summary><strong>빠진 항목을 파괴하지 않고 잠깐 숨겨 두려면요?</strong></summary>

`q.Detach`를 돌려주면 됩니다. 그 원소를 트리에서 떼되 **파괴하지 않고 들고 있다가**, 같은 키가 다시 나타났을 때 `prev`를 돌려주면 만들지 않고 그대로 다시 붙습니다. 탭 전환처럼 숨겼다 되살리는 자리의 도구입니다.

```luau
-- … (CounterBoard.luau) updateFn의 첫 갈래
if item == q.KeyGone then
    return q.Detach, ud    -- 파괴 대신 보관
end
```

원소를 **밖에서** 관리하고 싶다면 `opts.Owned = false`가 있습니다 — `list:List(data, updateFn, keyFn, { Owned = false })`처럼 주면 이 Slot이 원소를 파괴하지 않고 목록에서 빠질 때 언마운트만 합니다.

</details>

### `updateFn`이 돌려줄 수 있는 것 넷

호출은 `updateFn(item, index, offset, prev, userdata)`이고 — 이번 항목, 이 Slot 안에서의 물리 위치, 이 Slot의 `Offset` Source, 이 키가 지난번에 만든 원소, 이 키의 자유 값 순서입니다(자리마다의 정확한 뜻은 [레퍼런스: `slot:List`](/reference/core/07-slot/#slotlistdata-updatefn-keyfn-opts)) — 돌려주는 것은 `(결과, userdata)` 둘입니다. 결과 자리에 무엇을 놓느냐가 그 항목의 운명을 정합니다.

| 무엇을 돌려주나 | 무슨 일이 일어나나 |
|---|---|
| **`prev` 그대로** | 그 자리에 계속 둡니다 — 마운트도 파괴도 없는 **가장 싼 경로** |
| **새 값** | `prev`가 있었다면 파괴되고 새 값이 그 자리를 대신합니다 |
| **`nil` 또는 `q.None`** | `prev`가 있었다면 파괴됩니다 |
| **`q.Detach`** | 파괴하지 않고 트리 밖에 붙들어 둡니다. 그 키가 다시 오면 같은 원소가 그대로 재마운트됩니다 |

**순서는 quad가 정하지 않습니다.** `Slot`은 `LayoutOrder`라는 이름을 알지 못합니다 — `index`와 `offset`을 넘겨줄 뿐, 그것을 `LayoutOrder`에 쓸지 `Position`에 쓸지는 `updateFn`을 쓰는 쪽의 몫입니다([08장](/getting-started/08-slot/) 5절이 그 계산이고, 위 예제는 배치를 `UIListLayout`에 맡겼습니다).

---

## 4. 이미 있는 항목의 값이 바뀔 때

`prev`를 돌려주는 갈래는 **인스턴스를 다시 만들지 않습니다.** 그래서 라벨 텍스트처럼 항목마다 바뀌는 값은 다른 길로 넣어야 합니다 — `userdata`에 `Source`를 넣어 두고 **그 `Source`만 `:Set`** 하는 것이 정본 관용구입니다.

항목이 라벨 한 줄인 더 작은 목록으로 보겠습니다 — 위 `CounterBoard`와 겹치지 않게 데이터도 따로 둡니다.

```luau
-- 항목마다 바뀌는 값을 userdata의 Source로 들고 있는 목록
const logRows = q.Source({
    { Id = "a", Label = "왼쪽" },
    { Id = "b", Label = "오른쪽" },
})

const list = q.Slot()

list:List(logRows, function(item, index, offset, prev, ud)
    if item == q.KeyGone then
        return nil, ud
    end
    if prev then
        ud:Set(item.Label)            -- ← 인스턴스는 그대로, 값만 갈아 끼운다
        return prev, ud
    end
    const label = q.Source(item.Label)
    return D.TextLabel { Text = label }, label   -- ← 두 번째 반환이 다음 ud
end, function(item)
    return item.Id
end)

const box = D.Frame { BackgroundTransparency = 1, list }
```

**실행하면** `a` 항목의 라벨만 바꿔 넣었을 때 그 줄의 글씨는 새것으로 바뀌는데, 인스턴스는 처음 만든 그것 그대로입니다(`c`만 새로 만들어집니다).

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

두 번째 반환값이 곧 **그 키의 다음 `userdata`**라, 새로 만드는 갈래에서 `Source`를 돌려주면 그 다음 사이클부터 `ud` 자리로 돌아옵니다.


---

## 더 알고 싶다면

- [레퍼런스: `Slot`](/reference/core/07-slot/) — `:List`/`:Single`의 전체 계약, 에러 문구, `Detach`·`KeyGone`·`Owned`
- [03. `Slot:List`로 긴 목록 다루기](/how-to/03-virtualized-infinite-scroll/) — 수백~수만 개짜리 목록의 윈도잉과 `Blocker`
