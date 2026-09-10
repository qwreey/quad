---
title: "07. 자식이 들어갈 자리 — Slot"
description: "배열 부분의 한 자리를 Slot으로 잡아 두고 CRUD로 자식을 넣고 빼며, Offset과 Length가 어떻게 따라 움직이는지 봅니다"
---
# [시작하기] 07. 자식이 들어갈 자리 — `Slot`

> **대상 독자**: [06. Modifier](./06-modifier.md)를 끝낸 개발자
> **목표**: 만들어 놓은 화면의 자식을 나중에 넣고 빼기

지금까지 자식은 **만들 때 한 번** 적어 넣었습니다. 그런데 화면을 만든 **뒤에**
자식을 더하거나 빼야 할 때가 있습니다. `Slot`은 배열 부분의 한 자리를
"여기는 나중에 바뀔 구간"으로 잡아 두는 값입니다.

---

## 1. 자리 하나 잡아 두기

`Slot`을 배열 부분에 놓으면 **그 자리가 통째로 Slot의 자식 구간**이 됩니다.

```luau
const items = q.Slot {
    D.TextLabel { Text = "첫째" },
    D.TextLabel { Text = "둘째" },
}

const card = D.Frame {
    Size = UDim2.fromOffset(240, 160),
    BackgroundColor3 = Color3.fromRGB(35, 35, 42),

    items,                       -- ← 이 자리가 Slot의 구간
}

print(#card:GetChildren())   --> 2
```

**실행하면** 카드 안에 라벨 둘이 보입니다. `card`의 배열 부분에는 원소가 하나(`items`)뿐인데 자식은 둘입니다 — Slot이 자기가 든 만큼의 자리를 차지하기 때문입니다.

<details>
<summary><strong><code>--!strict</code>에서도 이대로 되나요?</strong></summary>

`Slot`은 타입 인자를 **명시**해야 합니다. `q.Slot()`은 `Slot<unknown>`으로 추론되기 때문입니다.

```luau
const items = q.Slot<<Instance>>({
    D.TextLabel { Text = "첫째" },
})
```

[01장](./01-setup.md)에서 `export type Slot<T> = QuadTypes.Slot<T>`를 다시 내보내 두었으니, 파라미터 타입은 `props: { Children: q.Slot<Instance>? }`처럼 그대로 씁니다.

</details>

---

## 2. 넣고 빼기

`items`에 손을 대면 그 결과가 **그대로 화면에 반영됩니다.** `card`를 다시 만들지도, 어떤 렌더 함수를 다시 돌리지도 않습니다.

```luau
items:Add(D.TextLabel { Text = "셋째" })
print(#card:GetChildren())   --> 3

items:Add(D.TextLabel { Text = "앞에" }, 1)   -- 1번 자리에 끼워 넣기
print(#card:GetChildren())   --> 4

items:Remove(1)              -- 그 자리 원소를 떼고 파괴한다
print(#card:GetChildren())   --> 3

items:Clear()                -- 전부 파괴하고 비운다
print(#card:GetChildren())   --> 0
```

**실행하면** 라벨이 그때그때 늘고 줄어듭니다. 살려서 꺼내고 싶으면 `:Remove` 대신 `:Extract`, 전부 살려 꺼내려면 `:ExtractAll`이 있습니다.

---

## 3. `Offset`과 `Length` — 내 구간이 어디서 시작하나

Slot은 자기 상태를 두 개의 `Source`로 들고 있습니다.

- **`slot.Length`** — 이 Slot이 차지하는 물리 자식의 **개수**
- **`slot.Offset`** — 이 Slot의 첫 원소 앞에 **몇 개의 물리 자식이 있는지**. 그래서 **0부터 셉니다** — 앞에 아무것도 없으면 0이고, 이 Slot의 첫 원소는 전체에서 `Offset + 1`번째입니다

한 부모에 Slot을 둘 놓고 직접 찍어 보면 관계가 보입니다.

```luau
const slotA = q.Slot { D.TextLabel { Text = "A1" }, D.TextLabel { Text = "A2" } }
const slotB = q.Slot { D.TextLabel { Text = "B1" } }

const panel = D.Frame {
    D.TextLabel { Text = "머리" },   -- 고정 자식 하나
    slotA,
    slotB,
}

print(slotA.Offset:Get(), slotA.Length:Get())   --> 1  2
print(slotB.Offset:Get(), slotB.Length:Get())   --> 3  1
```

`slotA` 앞에는 고정 자식 하나가 있으니 `Offset`이 1이고, `slotB` 앞에는 그 하나에 `slotA`의 둘이 더해져 3입니다.

앞이 자라면 뒤가 따라 밀립니다.

```luau
slotA:Add(D.TextLabel { Text = "A3" })

print(slotA.Offset:Get(), slotA.Length:Get())   --> 1  3
print(slotB.Offset:Get(), slotB.Length:Get())   --> 4  1
```

**실행하면** `slotA`는 자리가 그대로인데 길이만 늘고, `slotB`의 `Offset`이 3에서 4로 따라 움직입니다.

둘 다 `Source`라 그대로 구독할 수 있습니다 — 그래서 `LayoutOrder`처럼 "내가 전체에서 몇 번째인가"가 필요한 프로퍼티에 `자기 순번 + offset`을 바인딩할 수 있습니다. 실제로 그렇게 쓰는 모양은 [09장](./09-lists.md)에 나옵니다.

> `Length`는 **마운트되기 전에는 0입니다.** 채워지는 것은 부기 재계산이고, 그건 Slot이 실제로 어딘가에 놓인 뒤에 돌기 때문입니다.

---

## 4. `Slot` 안에 `Slot`

Slot의 원소로 다른 Slot을 넣을 수 있습니다. 바깥 Slot의 **한 자리**를 안쪽 Slot의 원소 **전부**가 차지합니다.

```luau
const inner = q.Slot { D.TextLabel { Text = "안쪽 1" }, D.TextLabel { Text = "안쪽 2" } }
const outer = q.Slot { inner, D.TextLabel { Text = "바깥" } }

const host = D.Frame { outer }
print(#host:GetChildren(), outer.Length:Get(), inner.Length:Get())   --> 3  3  2

inner:Add(D.TextLabel { Text = "안쪽 3" })
print(#host:GetChildren(), outer.Length:Get())                        --> 4  4
```

**실행하면** 안쪽 Slot에 하나를 넣었을 뿐인데 `outer.Length`와 실제 자식 수가 같이 늘어납니다. 부기가 위로 전파되기 때문입니다 — 그래서 Slot을 몇 겹으로 쌓아도 `Offset` 계산이 어긋나지 않습니다.

---

## 5. 이 CRUD를 데이터가 대신 해 준다면

지금까지는 `:Add`/`:Remove`를 **손으로** 불렀습니다. 화면에 보일 것이 "데이터 배열 하나"에서 나온다면 그 손이 매번 같은 일을 합니다 — 늘어난 항목만 만들고, 빠진 항목만 지우고, 남은 항목은 그대로 두는 일.

그걸 quad가 대신 해 주는 것이 `Slot`의 다른 모드인 **`:List`**이고, [09. 목록 만들기](./09-lists.md)에서 다룹니다.

<details>
<summary><strong>그럼 이 Slot에 나중에 <code>:List</code>를 걸어도 되나요?</strong></summary>

안 됩니다. `Slot`은 **두 모드 중 하나**로만 삽니다 — 손으로 넣고 빼는 **수동 CRUD** 모드(이 장)와, 데이터에 맞춰 quad가 맞춰 주는 **`:List`/`:Single`** 모드입니다. 둘은 상호 배타이고, 섞으려 하면 그 자리에서 에러가 납니다.

- `:Add`를 한 번이라도 쓴 Slot, 또는 `q.Slot { ... }`처럼 초기 원소를 주고 만든 Slot(**심지어 빈 `q.Slot {}`**)에는 `:List`를 걸 수 없습니다.
- 반대로 `:List`를 건 뒤의 수동 CRUD도 막힙니다.

그래서 목록용 Slot은 인자 없이 `q.Slot()`으로 만듭니다.

한 가지 더. **하나의 원소는 동시에 한 자리에만** 마운트될 수 있습니다. 이미 다른 Slot에 든 것을 그대로 `:Add` 하면 거부되니, 먼저 `:Extract`로 꺼내세요.

</details>

---

## 더 알고 싶다면

- [레퍼런스: `Slot`](../reference/core/07-slot.md) — CRUD 열셋(`:Splice`·`:Move`·`:Swap`·`:IndexOf` 등), 죽은 Slot과 마운트 규칙, `q.dispose`
- [Quadnomicon Vol. 2](../quadnomicon/02-slot-prefix-sum-tree.md) — `Offset`/`Length` 부기가 어떤 부분합 트리 위에서 도는지
