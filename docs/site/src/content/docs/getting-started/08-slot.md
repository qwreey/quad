---
title: "08. 자식이 들어갈 자리 — Slot"
description: "배열 부분의 한 자리를 Slot으로 잡아 두고 CRUD로 자식을 넣고 빼며, Offset과 Length가 어떻게 따라 움직이는지 봅니다"
---
> **대상 독자**: [07. Modifier](/getting-started/07-modifier/)를 끝낸 개발자
> **목표**: 만들어 놓은 화면의 자식을 나중에 넣고 빼기

지금까지 자식은 **만들 때 한 번** 적어 넣었습니다. 그런데 화면을 만든 **뒤에**
자식을 더하거나 빼야 할 때가 있습니다. `Slot`은 배열 부분의 한 자리를
"여기는 나중에 바뀔 구간"으로 잡아 두는 값입니다.

이 장의 예제는 카운터와 별개입니다 — 부기(장부)가 어떻게 움직이는지를 작은 상자 위에서 보고, 다음 장에서 카운터로 돌아갑니다.

---

## 1. 자리 하나 잡아 두기

`Slot`을 배열 부분에 놓으면 **그 자리가 통째로 Slot의 자식 구간**이 됩니다.

```luau
-- 새 예시: 별도 스크립트(카운터와 무관)
const items = q.Slot {
    D.TextLabel { Text = "첫째" },
    D.TextLabel { Text = "둘째" },
}

const box = D.Frame {
    Size = UDim2.fromOffset(240, 160),
    BackgroundColor3 = Color3.fromRGB(35, 35, 42),

    items,                       -- ← 이 자리가 Slot의 구간
}

print(#box:GetChildren())   --> 2
```

<img class="light-only" src="/assets/slot-card.svg" alt="Frame의 배열 부분에 놓인 items Slot — Slot이 든 원소 둘이 Frame의 실제 자식이 된다">
<img class="dark-only" src="/assets/slot-card-dark.svg" alt="Frame의 배열 부분에 놓인 items Slot — Slot이 든 원소 둘이 Frame의 실제 자식이 된다">

**실행하면** 상자 안에 라벨 둘이 보입니다. `box`의 배열 부분에는 원소가 하나(`items`)뿐인데 자식은 둘입니다 — Slot이 자기가 든 만큼의 자리를 차지하기 때문입니다.

<details>
<summary><strong><code>--!strict</code>에서도 이대로 되나요?</strong></summary>

`Slot`은 타입 인자를 **명시**해야 합니다. `q.Slot()`은 `Slot<unknown>`으로 추론되기 때문입니다.

```luau
const items = q.Slot<<Instance>>({
    D.TextLabel { Text = "첫째" },
})
```

[01장](/getting-started/01-setup/)에서 `export type Slot<T> = QuadTypes.Slot<T>`를 다시 내보내 두었으니, 파라미터 타입은 `props: { Children: q.Slot<Instance>? }`처럼 그대로 씁니다.

</details>

---

## 2. 넣고 빼기

`items`에 손을 대면 그 결과가 **그대로 화면에 반영됩니다.** `box`를 다시 만들지도, 어떤 렌더 함수를 다시 돌리지도 않습니다.

```luau
-- … 위쪽 코드에 이어집니다
items:Add(D.TextLabel { Text = "셋째" })
print(#box:GetChildren())   --> 3

items:Add(D.TextLabel { Text = "앞에" }, 1)   -- 1번 자리에 끼워 넣기
print(#box:GetChildren())   --> 4

items:Remove(1)              -- 그 자리 원소를 떼고 파괴한다
print(#box:GetChildren())   --> 3

items:Clear()                -- 전부 파괴하고 비운다
print(#box:GetChildren())   --> 0
```

**실행하면** 라벨이 그때그때 늘고 줄어듭니다. 살려서 꺼내고 싶으면 `:Remove` 대신 `:Extract`, 전부 살려 꺼내려면 `:ExtractAll`이 있습니다.

---

## 3. `Offset`과 `Length` — 내 구간이 어디서 시작하나

Slot은 자기 상태를 두 개의 `Source`로 들고 있습니다.

- **`slot.Length`** — 이 Slot이 차지하는 물리 자식의 **개수**
- **`slot.Offset`** — 이 Slot의 첫 원소 앞에 **몇 개의 물리 자식이 있는지**를 나타냅니다. 0부터 세므로 앞에 아무것도 없으면 0이고, 이 Slot의 첫 원소는 전체에서 `Offset + 1`번째가 됩니다

한 부모에 Slot을 둘 놓고 직접 찍어 보면 관계가 보입니다.

```luau
-- 새 예시: 별도 스크립트
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

<img class="light-only" src="/assets/slot-panel.svg" alt="panel 안의 고정 자식 하나와 slotA·slotB — slotA는 Offset 1 Length 2, slotB는 Offset 3 Length 1">
<img class="dark-only" src="/assets/slot-panel-dark.svg" alt="panel 안의 고정 자식 하나와 slotA·slotB — slotA는 Offset 1 Length 2, slotB는 Offset 3 Length 1">

`slotA` 앞에는 고정 자식 하나가 있으니 `Offset`이 1이고, `slotB` 앞에는 그 하나에 `slotA`의 둘이 더해져 3입니다.

앞이 자라면 뒤가 따라 밀립니다.

```luau
-- … 위쪽 코드에 이어집니다
slotA:Add(D.TextLabel { Text = "A3" })

print(slotA.Offset:Get(), slotA.Length:Get())   --> 1  3
print(slotB.Offset:Get(), slotB.Length:Get())   --> 4  1
```

**실행하면** `slotA`는 자리가 그대로인데 길이만 늘고, `slotB`의 `Offset`이 3에서 4로 따라 움직입니다.

> `Length`는 **마운트되기 전에는 0입니다.** 채워지는 것은 부기 재계산이고, 그건 Slot이 실제로 어딘가에 놓인 뒤에 돌기 때문입니다.

---

## 4. `Slot` 안에 `Slot`

Slot의 원소로 다른 Slot을 넣을 수 있습니다. 바깥 Slot의 **한 자리**를 안쪽 Slot의 원소 **전부**가 차지합니다. 안쪽 Slot의 `Offset`은 **부모 인스턴스 기준**입니다 — 자기 위에 놓인 원소들의 길이를 전부 더한 값입니다.

```luau
-- 새 예시: 별도 스크립트
const innerA = q.Slot { D.TextLabel { Text = "Inner1" }, D.TextLabel { Text = "Inner2" } }
const innerB = q.Slot { D.TextLabel { Text = "Inner3" } }

const outer = q.Slot {
    innerA,                          -- 원소 둘
    D.TextLabel { Text = "Outer" },  -- 원소 하나
    innerB,                          -- 원소 하나
}

const host = D.Frame { outer }

print(#host:GetChildren(), outer.Offset:Get(), outer.Length:Get())   --> 4  0  4
print(innerA.Offset:Get(), innerA.Length:Get())                      --> 0  2
print(innerB.Offset:Get(), innerB.Length:Get())                      --> 3  1
```

<img class="light-only" src="/assets/slot-host.svg" alt="host 안의 outer Slot(Offset 0 Length 4) — 그 안에 innerA(Offset 0 Length 2), Outer, innerB(Offset 3 Length 1). innerB의 Offset 3은 위에 놓인 Inner1·Inner2·Outer의 길이 합">
<img class="dark-only" src="/assets/slot-host-dark.svg" alt="host 안의 outer Slot(Offset 0 Length 4) — 그 안에 innerA(Offset 0 Length 2), Outer, innerB(Offset 3 Length 1). innerB의 Offset 3은 위에 놓인 Inner1·Inner2·Outer의 길이 합">

`innerB`의 `Offset`이 3인 것은 그 위에 `Inner1`·`Inner2`(innerA의 둘)와 `Outer`(하나)가 있기 때문입니다. `outer` 자신은 `host`의 첫 자리라 `Offset` 0이고, 안쪽 넷을 전부 품어 `Length` 4입니다.

안쪽에 하나를 더 넣으면 위로 전파됩니다.

```luau
-- … 위쪽 코드에 이어집니다
innerA:Add(D.TextLabel { Text = "Inner4" })

print(#host:GetChildren(), outer.Length:Get())   --> 5  5
print(innerB.Offset:Get(), innerB.Length:Get())  --> 4  1
```

**실행하면** `innerA`에 하나를 넣었을 뿐인데 `outer.Length`와 실제 자식 수가 같이 늘고, 그 아래 있던 `innerB`의 `Offset`도 3에서 4로 밀립니다 — 장부상 `Inner4`는 `innerA`의 구간 끝, 즉 `Outer` 앞에 들어갔기 때문입니다.

다만 `host:GetChildren()`을 찍어 보면 순서는 `Inner1, Inner2, Outer, Inner3, Inner4`입니다. Roblox에서 자식의 순서는 물리적으로 재배치되지 않고 **장부(`Offset`/`Length`)로만** 관리되며, 화면에서의 순서는 `Position`이나 아래 5절의 `LayoutOrder`가 정합니다.

부기가 위로 전파되기 때문에 Slot을 몇 겹으로 쌓아도 `Offset` 계산이 어긋나지 않습니다.

---

## 5. 전체에서 몇 번째인지가 필요할 때

`Offset`과 `Length`는 둘 다 `Source`라 **그대로 구독할 수 있습니다.** `LayoutOrder`처럼 "내가 부모 전체에서 몇 번째인가"를 요구하는 프로퍼티가 있으면, 그 값을 계산해 꽂아 두면 됩니다.

```luau
-- … 3절의 panel 예시에 이어집니다: slotB의 첫 원소가 전체에서 몇 번째인가
LayoutOrder = slotB.Offset:Compute(function(o) return o:Get() + 1 end),   -- 지금은 5
```

여기서 `+ 1`은 그 원소가 **Slot 안에서 몇 번째인가**입니다. 손으로 `:Add` 할 때는 넣는 쪽이 그 순번을 알고 있고, `:List`에서는 `updateFn`이 두 번째 인자 `index`로 넘겨줍니다([10장](/getting-started/10-lists/)). 앞의 Slot이 늘고 줄 때마다 `Offset`이 움직이므로 `LayoutOrder`도 따라갑니다.

---

## 6. 이 CRUD를 데이터가 대신해 준다면

지금까지는 `:Add`/`:Remove`를 **손으로** 불렀습니다. 화면에 보일 것이 "데이터 배열 하나"에서 나온다면 그 손이 매번 같은 일을 합니다 — 늘어난 항목만 만들고, 빠진 항목만 지우고, 남은 항목은 그대로 두는 일.

그걸 quad가 대신해 주는 것이 `Slot`의 다른 모드인 **`:List`**이고, [10. 목록 만들기](/getting-started/10-lists/)에서 다룹니다.

<details>
<summary><strong>그럼 이 Slot에 나중에 <code>:List</code>를 걸어도 되나요?</strong></summary>

안 됩니다. `Slot`은 **두 모드 중 하나**로만 삽니다 — 손으로 넣고 빼는 **수동 CRUD** 모드(이 장)와, 데이터에 맞춰 quad가 맞춰 주는 **`:List`/`:Single`** 모드입니다. 둘은 상호 배타이고, 섞으려 하면 그 자리에서 에러가 납니다.

- `:Add`를 한 번이라도 쓴 Slot, 또는 `q.Slot { ... }`처럼 초기 원소를 주고 만든 Slot(**심지어 빈 `q.Slot {}`**)에는 `:List`를 걸 수 없습니다.
- 반대로 `:List`를 건 뒤의 수동 CRUD도 막힙니다.

그래서 목록용 Slot은 인자 없이 `q.Slot()`으로 만들고 곧바로 `:List`를 겁니다.

한 가지 더. **하나의 원소는 동시에 한 자리에만** 마운트될 수 있습니다. 이미 다른 Slot에 든 것을 그대로 `:Add` 하면 거부되니, 먼저 `:Extract`로 꺼내세요.

</details>

---

## 더 알고 싶다면

- [레퍼런스: `Slot`](/reference/core/07-slot/) — CRUD 열셋(`:Splice`·`:Move`·`:Swap`·`:IndexOf` 등), 죽은 Slot과 마운트 규칙, `q.dispose`
- [Quadnomicon Vol. 2](/quadnomicon/02-slot-prefix-sum-tree/) — `Offset`/`Length` 부기가 어떤 부분합 트리 위에서 도는지
