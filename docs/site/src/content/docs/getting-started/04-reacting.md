---
title: "04. 반응하기 — 이벤트와 관측"
description: "버튼 이벤트로 Source에 값을 넣어 카운터를 완성하고, 값이 바뀔 때 화면 밖에서 무언가 하는 Observer를 붙입니다"
---
> **대상 독자**: [03. 값이 흐르게 하기](/getting-started/03-flowing-values/)를 끝낸 개발자
> **목표**: 버튼을 눌러 값을 넣고, 값이 바뀔 때 화면 밖에서도 무언가 하기

03장에서는 값을 코드로 직접 `:Set` 했습니다. 이제 그 자리를 **사용자의 클릭**으로 바꿉니다.

---

## 지금까지의 코드

```luau
-- (Main.client.luau 계속 — 카드를 화면 가운데 놓는 AnchorPoint/Position은 생략합니다)
const count = q.Source(0)

const countText = count:Compute(function(c)
    return `카운트: {c:Get()}`
end)

const card = D.Frame {
    Size = UDim2.fromOffset(240, 160),
    BackgroundColor3 = Color3.fromRGB(35, 35, 42),
    UICorner = 12,

    D.TextLabel {
        Position = UDim2.fromOffset(16, 0),
        Size = UDim2.new(1, -32, 0, 48),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextScaled = true,
        Text = countText,
    },
}
```

---

## 1. 버튼 달기

`card`의 배열 부분, 라벨 **아래**에 버튼을 하나 더합니다.

```luau
    -- … card의 배열 부분, 라벨 바로 아래에 이어집니다
    D.TextButton {
        Size = UDim2.new(1, -40, 0, 42),
        Position = UDim2.new(0, 20, 1, -62),
        BackgroundColor3 = Color3.fromRGB(0, 162, 255),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Text = "+ 1",
        TextSize = 16,
        UICorner = 8,

        -- 이벤트도 해시 부분에 이름으로 적는다
        Activated = function()
            count:Set(count:Get() + 1)
        end,
    },
```

**실행하면** 버튼을 누를 때마다 위 라벨의 숫자가 하나씩 올라갑니다. 여기까지가 완결된 카운터입니다.

**이벤트는 프로퍼티와 같은 자리(해시 부분)에 씁니다.** 그 이름이 프로퍼티인지 이벤트인지는 엔진 리플렉션이 판정하므로, `Activated` 같은 이름을 그대로 키로 쓰면 됩니다.

**콜백은 엔진이 주는 인자만 받습니다** — `self`도, 인스턴스도 앞에 붙지 않습니다. `Activated`라면 `function(inputObject, clickCount)`가 그대로 들어옵니다. 이 예제에서는 인자를 안 쓰니 빈 파라미터로 뒀습니다.

흐름을 다시 보면 이렇습니다.

```
클릭 → count:Set(n + 1) → :Compute 재계산 → Text 프로퍼티가 갱신
```

버튼 콜백이 손대는 것은 **원천 하나뿐**입니다. 화면을 직접 고치는 코드는 어디에도 없습니다.

---

## 2. 값이 바뀔 때 화면 밖에서 뭔가 하기 — `:Observer`

프로퍼티로 흘려보낼 게 아니라 **로그를 찍거나, 소리를 내거나, 서버로 보내야** 할 때가 있습니다. 그럴 때 쓰는 것이 `:Observer(fn)`입니다.

라벨의 배열 부분에 한 덩이를 더합니다.

```luau
    -- … card 안의 라벨에 이어집니다
    D.TextLabel {
        -- …프로퍼티 생략…
        Text = countText,

        -- 배열 부분: 이 라벨이 살아 있는 동안 count를 관측한다
        count:Observer(function(target)
            print("카운트가", target:Get(), "가 되었습니다")
        end),
    },
```

**실행하면** 만들어지는 즉시 한 줄이 찍히고, 그 뒤로 버튼을 누를 때마다 한 줄씩 더 찍힙니다. 콜백이 받는 것은 값이 아니라 관측 대상의 핸들이라 `target:Get()`으로 읽습니다 — `:Compute`와 같습니다.

<details>
<summary><strong>배열 부분에 안 넣으면 어떻게 되나요?</strong></summary>

**`:Observer(fn)`은 등록하는 그 자리에서 한 번 발화하고, 그 뒤로는 조용합니다.** 이후 변경까지 받으려면 **살아나야** 하는데, 경로가 둘입니다.

1. **인스턴스에 묶는 것** — props의 배열 부분에 넣으면 quad가 묶어 줍니다. 그 인스턴스가 사는 동안만 살고, 인스턴스가 파괴되면 같이 정리됩니다. UI에 딸린 관측은 대개 이쪽입니다.
2. **전역 구독** — `:Subscribe()`(강한 유지) 또는 `:WeakSubscribe()`(약한 유지). 인스턴스와 무관하게 사는 구독입니다.

어느 쪽도 하지 않으면 등록 시 한 번이 전부입니다.

```luau
-- 어디에도 묶지 않으면 등록 시 한 번뿐이다
const lonely = count:Observer(function(target)
    print("이건 한 번만 찍힙니다", target:Get())
end)

count:Set(99) -- lonely는 발화하지 않는다(보류)
```

묶이기 전에 일어난 변경은 버려지는 게 아니라 **보류**돼 있다가, 살아나는 순간 최신값으로 정확히 한 번 재생됩니다.

</details>

---

## 더 알고 싶다면

- [레퍼런스: `D` — 해시 부분](/reference/roblox/02-d/#해시-부분--프로퍼티와-이벤트) — 이벤트 값 자리에 올 수 있는 것, 콜백이 아닌 값을 넣었을 때의 에러
- [레퍼런스: `Observer` / `Effect`](/reference/core/05-observer-effect/) — 구독 네 진입점, 보류와 재생
- [04. 외부 신호를 상태로 들여오기](/how-to/04-network-and-input-bridge/) — `RemoteEvent`·`UserInputService`를 `Source:Set`으로 격리하기
