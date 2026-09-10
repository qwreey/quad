---
title: "08. 자식이 들어갈 자리 — Slot"
description: "카드 안에 Slot으로 한 구간을 잡아 두고 클릭 기록을 넣고 빼며, Offset과 Length가 어떻게 따라 움직이는지 봅니다"
---
# [시작하기] 08. 자식이 들어갈 자리 — `Slot`

> **대상 독자**: [07. Modifier](./07-modifier.md)를 끝낸 개발자
> **목표**: 만들어 놓은 카드의 자식을 나중에 넣고 빼기

지금까지 자식은 **만들 때 한 번** 적어 넣었습니다. 그런데 카운터를 누를 때마다
"클릭 기록"을 한 줄씩 쌓으려면, 화면을 만든 **뒤에** 자식을 더할 수 있어야 합니다.
`Slot`은 배열 부분의 한 자리를 "여기는 나중에 바뀔 구간"으로 잡아 두는 값입니다.

---

## 지금까지의 코드

```luau
-- (Main.client.luau 계속 — 카드를 화면 가운데 놓는 AnchorPoint/Position은 생략합니다.
--  기록이 쌓일 자리를 만들려고 카드 높이만 160 → 320으로 키웠고, 버튼은 라벨 바로 아래로 올렸습니다)
const count = q.Source(0)
const countText = count:Compute(function(c) return `카운트: {c:Get()}` end)

const card = D.Frame {
    Size = UDim2.fromOffset(240, 320),
    BackgroundColor3 = Color3.fromRGB(35, 35, 42),
    ClipsDescendants = true,      -- 기록이 카드 밖으로 삐져나가지 않게
    UICorner = 12,

    D.TextLabel {
        Position = UDim2.fromOffset(16, 0),
        Size = UDim2.new(1, -32, 0, 48),
        -- …나머지 프로퍼티는 앞 장 그대로…
        Text = countText,
    },

    D.TextButton {
        Position = UDim2.new(0, 20, 0, 52),
        Size = UDim2.new(1, -40, 0, 42),
        -- …나머지 프로퍼티는 앞 장 그대로…
        Text = "+ 1",

        Activated = function()
            count:Set(count:Get() + 1)
        end,
    },
}
```

---

## 1. 자리 하나 잡아 두기

기록이 들어갈 자리를 `card` 위에서 하나 만들고, **버튼 아래**에 놓습니다.

```luau
-- … 위쪽 코드에 이어집니다
const history = q.Slot()          -- ① 빈 Slot 하나

const card = D.Frame {
    -- …프로퍼티·라벨·버튼 생략…

    history,                      -- ② 배열 부분: 이 자리가 통째로 Slot의 구간
}

print(history.Offset:Get(), history.Length:Get())   --> 2  0
```

**실행하면** 화면은 아직 그대로입니다 — Slot이 비어 있으니까요. 자리만 잡아 둔 상태입니다.

배열 부분에 놓인 `Slot`은 **자기가 든 만큼**의 자리를 차지합니다. `card`의 배열 부분에서 `history`는 원소 하나지만, 만들어지는 자식은 지금 0개이고 셋을 넣으면 셋이 됩니다.

같이 찍힌 `2`는 이 Slot 앞에 이미 만들어진 자식이 둘(라벨, 버튼)이라는 뜻입니다. 그 이름이 `Offset`이고, 3절에서 다시 봅니다.

<details>
<summary><strong><code>--!strict</code>에서도 이대로 되나요?</strong></summary>

`Slot`은 타입 인자를 **명시**해야 합니다. `q.Slot()`은 `Slot<unknown>`으로 추론되기 때문입니다.

```luau
const history = q.Slot<<Instance>>()
```

[01장](./01-setup.md)에서 `export type Slot<T> = QuadTypes.Slot<T>`를 다시 내보내 두었으니, 파라미터 타입은 `props: { Children: q.Slot<Instance>? }`처럼 그대로 씁니다.

</details>

---

## 2. 넣고 빼기

`history`에 손을 대면 그 결과가 **그대로 화면에 반영됩니다.** `card`를 다시 만들지도, 어떤 렌더 함수를 다시 돌리지도 않습니다.

`+ 1` 버튼의 콜백에서 기록 한 줄을 쌓습니다.

```luau
-- … card 안 `+ 1` 버튼의 Activated를 이렇게 고칩니다
        Activated = function()
            count:Set(count:Get() + 1)

            history:Add(D.TextLabel {
                Position = UDim2.fromOffset(16, 104 + 22 * history.Length:Get()),
                Size = UDim2.new(1, -32, 0, 22),
                BackgroundTransparency = 1,
                TextColor3 = Color3.fromRGB(170, 170, 180),
                TextSize = 14,
                Text = `클릭 → {count:Get()}`,
            })
        end,
```

기록을 비울 버튼도 하나 답니다. `history` **뒤**, 카드 배열 부분의 마지막에 놓습니다.

```luau
-- … card의 배열 부분, history 아래에 이어집니다
    D.TextButton {
        Position = UDim2.new(0, 20, 1, -50),
        Size = UDim2.new(1, -40, 0, 34),
        BackgroundColor3 = Color3.fromRGB(60, 60, 70),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Text = "기록 지우기",
        UICorner = 8,

        Activated = function()
            history:Clear()
        end,
    },
```

**실행하면** 버튼을 누를 때마다 기록이 한 줄씩 쌓이고, `기록 지우기`를 누르면 한꺼번에 사라집니다. 세 번 눌러 보면 이렇습니다.

```luau
print(history.Length:Get())   --> 3     (세 번 누른 뒤)
-- 기록 지우기
print(history.Length:Get())   --> 0
```

기록 라벨의 `Position`을 계산할 때 쓴 `history.Length:Get()`이 그 시점의 원소 개수입니다. 넣는 자리와 빼는 방법은 몇 가지 더 있습니다.

- **`:Add(값)`** — 맨 뒤에 붙입니다. **`:Add(값, n)`**이면 `n`번 자리에 끼워 넣습니다.
- **`:Remove(n)`** — 그 자리 원소를 떼고 **파괴합니다**.
- **`:Clear()`** — 전부 파괴하고 비웁니다.
- 살려서 꺼내려면 `:Extract`, 전부 살려서 꺼내려면 `:ExtractAll`입니다.

---

## 3. `Offset`과 `Length` — 내 구간이 어디서 시작하나

Slot은 자기 상태를 두 개의 `Source`로 들고 있습니다.

- **`slot.Length`** — 이 Slot이 차지하는 자식의 **개수**
- **`slot.Offset`** — 이 Slot의 첫 원소 앞에 자식이 **몇 개** 있는지. 그래서 **0부터 셉니다** — 앞에 아무것도 없으면 0이고, 이 Slot의 첫 원소는 전체에서 `Offset + 1`번째입니다

세는 대상은 **배열 부분이 만든 자식**입니다. `UICorner = 12`처럼 해시 부분의 숏핸드가 붙여 주는 관리 자식은 배열 부분에서 온 것이 아니라 이 셈에 들어가지 않습니다.

관계는 Slot을 하나 더 놓아 보면 바로 보입니다. 카드 맨 아래, `기록 지우기` 버튼 **뒤**에 요약 줄을 담을 Slot을 하나 더 둡니다.

```luau
-- … 위쪽 코드에 이어집니다
const footer = q.Slot {
    D.TextLabel {
        Position = UDim2.fromOffset(16, 244),
        Size = UDim2.new(1, -32, 0, 20),
        Text = count:Compute(function(c) return `총 {c:Get()}번` end),
    },
}
--   card의 배열 부분 맨 끝, `기록 지우기` 버튼 뒤에 `footer,`를 놓습니다

print(history.Offset:Get(), history.Length:Get())   --> 2  0
print(footer.Offset:Get(), footer.Length:Get())     --> 3  1
```

`history` 앞에는 고정 자식이 둘(라벨·버튼)이라 `Offset`이 2이고, `footer` 앞에는 그 둘에 `history`의 0개와 `기록 지우기` 버튼 하나가 더해져 3입니다.

앞이 자라면 뒤가 따라 밀립니다. `+ 1`을 세 번 눌러 보면 이렇습니다.

```luau
print(history.Offset:Get(), history.Length:Get())   --> 2  3
print(footer.Offset:Get(), footer.Length:Get())     --> 6  1
```

**실행하면** `history`는 자리가 그대로인데 길이만 늘고, `footer`의 `Offset`이 3에서 6으로 따라 움직입니다.

> `Length`는 **마운트되기 전에는 0입니다.** 채워지는 것은 부기 재계산이고, 그건 Slot이 실제로 어딘가에 놓인 뒤에 돌기 때문입니다.

---

## 4. `Slot` 안에 `Slot`

Slot의 원소로 다른 Slot을 넣을 수 있습니다. 바깥 Slot의 **한 자리**를 안쪽 Slot의 원소 **전부**가 차지합니다. 기록 목록 끝에 묶음 하나를 통째로 붙여 보겠습니다.

```luau
-- … 위쪽 코드에 이어집니다(`기록 지우기`를 누른 뒤 `+ 1`을 두 번 눌러 기록이 둘인 상태)
const recent = q.Slot {
    D.TextLabel { Position = UDim2.fromOffset(16, 148), Size = UDim2.new(1, -32, 0, 22), Text = "— 최근 —" },
}

history:Add(recent)                                -- 기록 목록 끝에 묶음째로
print(history.Length:Get(), recent.Length:Get())   --> 3  1
print(footer.Offset:Get())                         --> 6

recent:Add(D.TextLabel {
    Position = UDim2.fromOffset(16, 170), Size = UDim2.new(1, -32, 0, 22), Text = "묶음 안 하나 더",
})
print(history.Length:Get(), recent.Length:Get())   --> 4  2
print(footer.Offset:Get())                         --> 7
```

**실행하면** 안쪽 Slot에 하나를 넣었을 뿐인데 `history.Length`도, 그 뒤에 있는 `footer.Offset`도 같이 늘어납니다. 부기가 위로 전파되기 때문입니다 — 그래서 Slot을 몇 겹으로 쌓아도 `Offset` 계산이 어긋나지 않습니다.

---

## 5. 전체에서 몇 번째인지가 필요할 때

`Offset`과 `Length`는 둘 다 `Source`라 **그대로 구독할 수 있습니다.** `LayoutOrder`처럼 "내가 부모 전체에서 몇 번째인가"를 요구하는 프로퍼티가 있으면, 그 값을 계산해 꽂아 두면 됩니다.

```luau
-- i는 이 Slot 안에서의 자기 순번. 앞이 늘고 줄 때마다 LayoutOrder가 따라간다
LayoutOrder = history.Offset:Compute(function(o) return o:Get() + i end),
```

여기서 `i`는 **`:List`의 `updateFn`이 두 번째 인자 `index`로 넘겨주는 값**입니다([10장](./10-lists.md)). 이 장처럼 손으로 `:Add` 할 때는 넣는 쪽이 그 순번을 알고 있으니 그대로 쓰면 됩니다.

이 장의 기록 라벨이 `Position`을 **넣는 시점에 한 번** 계산해 굳혀 둔다는 점도 같은 이야기입니다 — 중간에 하나를 끼워 넣거나 빼도 나머지가 다시 흘러내리지는 않습니다. 순번이 바뀔 때마다 자리가 따라오게 하려면 위처럼 `index`와 `Offset`으로 계산한 값을 프로퍼티에 **꽂아** 두어야 합니다.

---

## 6. 이 CRUD를 데이터가 대신해 준다면

지금까지는 `:Add`/`:Clear`를 **손으로** 불렀습니다. 화면에 보일 것이 "데이터 배열 하나"에서 나온다면 그 손이 매번 같은 일을 합니다 — 늘어난 항목만 만들고, 빠진 항목만 지우고, 남은 항목은 그대로 두는 일.

그걸 quad가 대신해 주는 것이 `Slot`의 다른 모드인 **`:List`**이고, [10. 목록 만들기](./10-lists.md)에서 다룹니다.

<details>
<summary><strong>그럼 이 <code>history</code>에 나중에 <code>:List</code>를 걸어도 되나요?</strong></summary>

안 됩니다. `Slot`은 **두 모드 중 하나**로만 삽니다 — 손으로 넣고 빼는 **수동 CRUD** 모드(이 장)와, 데이터에 맞춰 quad가 맞춰 주는 **`:List`/`:Single`** 모드입니다. 둘은 상호 배타이고, 섞으려 하면 그 자리에서 에러가 납니다.

- `:Add`를 한 번이라도 쓴 Slot, 또는 `q.Slot { ... }`처럼 초기 원소를 주고 만든 Slot(**심지어 빈 `q.Slot {}`**)에는 `:List`를 걸 수 없습니다.
- 반대로 `:List`를 건 뒤의 수동 CRUD도 막힙니다.

그래서 목록용 Slot은 인자 없이 `q.Slot()`으로 만들고 곧바로 `:List`를 겁니다. 위 `history`는 `q.Slot()`으로 만들긴 했지만 `:Add`를 쓴 순간 수동 모드로 굳었습니다.

한 가지 더. **하나의 원소는 동시에 한 자리에만** 마운트될 수 있습니다. 이미 다른 Slot에 든 것을 그대로 `:Add` 하면 거부되니, 먼저 `:Extract`로 꺼내세요.

</details>

---

## 더 알고 싶다면

- [레퍼런스: `Slot`](../reference/core/07-slot.md) — CRUD 열셋(`:Splice`·`:Move`·`:Swap`·`:IndexOf` 등), 죽은 Slot과 마운트 규칙, `q.dispose`
- [Quadnomicon Vol. 2](../quadnomicon/02-slot-prefix-sum-tree.md) — `Offset`/`Length` 부기가 어떤 부분합 트리 위에서 도는지
