---
title: "04. 반응하기 — 이벤트"
description: "버튼 이벤트를 문자 키 자리에 적어 Source에 값을 넣고, 카운터를 완결시킵니다"
---
> **대상 독자**: [03. 값이 흐르게 하기](/getting-started/03-flowing-values/)를 끝낸 개발자
> **목표**: 버튼을 눌러 원천에 값을 넣고, 카운터를 완결시키기

03장에서는 값을 코드로 직접 `:Set` 했습니다. 이제 그 자리를 **사용자의 클릭**으로 바꿉니다.

---

## 지금까지의 코드

```luau
-- (Main.client.luau 계속 — 카드를 화면 가운데 놓는 AnchorPoint/Position은 생략합니다.
--  03장 §2의 count:Set(7)과 §3에서 확인용으로 만든 suffix/both 줄은 지웁니다)
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

`card`의 숫자 키 자리, 라벨 **아래**에 버튼을 하나 더합니다.

```luau
    -- … card의 숫자 키 자리, 라벨 바로 아래에 이어집니다
    D.TextButton {
        Size = UDim2.new(1, -40, 0, 42),
        Position = UDim2.new(0, 20, 1, -62),
        BackgroundColor3 = Color3.fromRGB(0, 162, 255),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Text = "+ 1",
        TextSize = 16,
        UICorner = 8,

        -- 이벤트도 문자 키 자리에 이름으로 적는다
        Activated = function()
            count:Set(count:Get() + 1)
        end,
    },
```

**실행하면** 버튼을 누를 때마다 위 라벨의 숫자가 하나씩 올라갑니다. 여기까지가 완결된 카운터입니다.

**이벤트는 프로퍼티와 같은 자리(문자 키)에 씁니다.** 그 이름이 프로퍼티인지 이벤트인지는 엔진 리플렉션이 판정하므로, `Activated` 같은 이름을 그대로 키로 쓰면 됩니다.

<details>
<summary><strong>콜백엔 정확히 어떤 인자가 오나요?</strong></summary>

**콜백은 엔진이 주는 인자만 받습니다** — `self`도, 인스턴스도 앞에 붙지 않습니다. `Activated`라면 `function(inputObject, clickCount)`가 그대로 들어옵니다. 이 예제에서는 인자를 안 쓰니 빈 파라미터로 뒀습니다.

</details>

흐름을 다시 보면 이렇습니다.

```
클릭 → count:Set(n + 1) → :Compute 재계산 → Text 프로퍼티가 갱신
```

버튼 콜백이 손대는 것은 **원천 하나뿐**입니다. 화면을 직접 고치는 코드는 어디에도 없습니다.

값이 바뀔 때 화면 **밖에서** 무언가 하는 길 — 로그를 찍거나, 소리를 내거나, 서버로 보내는 일 — 은 [07. 관측하기](/getting-started/07-observer-effect/)에서 다룹니다. 반대 방향, 즉 엔진이 바꾼 프로퍼티(입력창의 `Text`, 스크롤의 `CanvasPosition`)를 `Source`로 들여오는 것은 `q.OnChange("Text", fn)`이고 숫자 키 자리에 놓습니다 — 시작하기에서는 다루지 않으니 필요해지면 [레퍼런스: `OnChange`](/reference/roblox/05-onchange/)를 보세요.

---

## 더 알고 싶다면

- [레퍼런스: `D` — 문자 키](/reference/roblox/02-d/#문자-키--프로퍼티와-이벤트) — 이벤트 값 자리에 올 수 있는 것, 콜백이 아닌 값을 넣었을 때의 에러
- [04. RemoteEvent와 엔진 입력을 상태로 브릿징하기](/how-to/04-network-and-input-bridge/) — `RemoteEvent`·`UserInputService`를 `Source:Set`으로 격리하기
