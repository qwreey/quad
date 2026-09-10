---
title: "02. 값이 흐르게 하기 — 원천에서 프로퍼티까지"
description: "값의 원천을 만들고, 중간에 파이프를 끼우고, 그 끝을 프로퍼티에 꽂아 화면이 값을 따라오게 만듭니다"
---
# [시작하기] 02. 값이 흐르게 하기 — 원천에서 프로퍼티까지

> **대상 독자**: [01. 첫 화면](./01-first-screen.md)을 끝낸 개발자
> **목표**: 값 하나를 바꿨을 때 화면이 저절로 따라오게 만들고, 그 길에 파이프를 하나 끼워 보기

01장의 라벨은 `Text = "카운트: 0"`으로 **한 번 찍고 끝난** 글씨입니다. 이 장에서는 그 자리를 **흐르는 값**으로 바꿉니다.

---

## 지금까지의 코드

```luau
-- (AnchorPoint/Position 같은 배치 프로퍼티는 이 장부터 생략합니다 — 01장 그대로 두면 됩니다)
local card = D.Frame {
    Size = UDim2.fromOffset(240, 160),
    BackgroundColor3 = Color3.fromRGB(35, 35, 42),
    UICorner = 12,

    D.TextLabel {
        Size = UDim2.new(1, -32, 0, 48),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextScaled = true,
        Text = "카운트: 0",
    },
}
```

---

## 1. 값의 원천 만들기

먼저 값을 **담아 둘 자리**를 하나 만듭니다. `q.Source(...)`가 그 자리입니다.

`card` 위에 한 줄을 두고, 라벨의 `Text` 한 줄을 그 자리로 바꿉니다.

```luau
local label = q.Source("카운트: 0")   -- ① 값의 원천

local card = D.Frame {
    -- …생략…
    D.TextLabel {
        -- …생략…
        Text = label,                  -- ② 리터럴 대신 원천을 그대로 꽂는다
    },
}

label:Set("카운트: 1")                 -- ③ 원천의 값을 바꾼다
```

**실행하면** 화면에는 `카운트: 1`이 보입니다. 라벨을 다시 만들지도, `label.Text = ...`를 다시 대입하지도 않았는데 화면이 바뀌었습니다.

프로퍼티 자리에 **값 대신 원천을 꽂으면**, 그 프로퍼티는 그때부터 원천을 따라갑니다. `:Set`을 부를 때마다 quad가 그 자리에 새 값을 씁니다.

---

## 2. 중간에 파이프 끼우기

그런데 우리가 세는 것은 **숫자**입니다. 원천을 숫자로 두고, 화면에 보일 문자열은 그 숫자에서 **만들어 내는** 쪽이 낫습니다. 원천과 프로퍼티 사이에 파이프를 하나 끼웁니다.

```luau
local count = q.Source(0)                      -- ① 원천은 숫자

local countText = count:Compute(function(c)    -- ② 파이프: 숫자 → 보여 줄 문자열
    return `카운트: {c:Get()}`
end)

local card = D.Frame {
    -- …생략…
    D.TextLabel {
        -- …생략…
        Text = countText,                       -- ③ 파이프의 끝을 프로퍼티에 꽂는다
    },
}

count:Set(7)
```

**실행하면** 화면에 `카운트: 7`이 보입니다. `count`가 움직이면 파이프가 다시 계산되고, 그 결과가 프로퍼티까지 흘러갑니다.

```
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│ q.Source(0)  │ ───▶ │ :Compute(fn) │ ───▶ │ Text = …     │
└──────────────┘      └──────────────┘      └──────────────┘
     원천                  파이프                프로퍼티
   값을 넣는다            값을 바꾼다            화면에 그린다
```

파이프의 콜백에서 눈여겨볼 것이 하나 있습니다. **콜백이 받는 `c`는 값이 아니라 핸들입니다** — 그래서 `c:Get()`으로 읽습니다. 그리고 파이프는 게을러서, **아무도 `:Get()`을 부르지 않으면 `:Compute`의 함수는 아예 돌지 않습니다.**

---

## 3. 원천이 둘 이상일 때

파이프는 다른 값도 같이 볼 수 있습니다. **다만 콜백 안에서 읽는 것만으로는 의존성이 잡히지 않습니다** — 볼 대상을 `:Compute`의 뒤 인자로 **명시**해야 합니다.

```luau
local suffix = q.Source("회")

local both = count:Compute(function(c, previous, s)
    return `{c:Get()}{s:Get()}`
end, suffix)                      -- ← suffix를 명시해야 suffix가 움직일 때도 다시 흐른다

print(both:Get())  --> "7회"
suffix:Set("번")
print(both:Get())  --> "7번"
```

콜백의 자리는 `(self, previous, ...deps)`입니다 — 첫 자리는 `:Compute`를 부른 그 노드, 둘째 자리는 이 파이프가 직전에 내놓은 결과값, 셋째부터가 뒤에 적은 의존성들이고 전부 핸들입니다. 값은 그대로 두고 **구독 범위만 넓히고** 싶으면 `count:With(suffix)`도 있습니다.

---

## 4. 그래서 이름이 둘입니다

여기까지 만든 것에 이름을 붙입니다.

- **`Source`** — 값을 **넣을 수 있는** 원천. `q.Source(v)`로 만들고 `:Set(v)`으로 씁니다.
- **`State`** — 읽기만 되는 파이프의 끝. `:Compute`/`:With`가 만들어 준 노드가 이것입니다. **공개 생성자가 없습니다** — `q.State(...)` 같은 것은 없습니다.

그리고 규칙 하나. **모든 `Source`는 그대로 `State`입니다.** `State`를 요구하는 자리(프로퍼티 자리, `:Compute`의 의존성 자리)에 `Source`를 그냥 넘기면 됩니다 — 언래핑도, 변환도 없습니다. 위 1절에서 `Text = label`이 그대로 통했던 게 그래서입니다.

> 이 문서의 예제는 Roblox 기본 모드(`--!nonstrict`)를 가정합니다. `--!strict`로 쓸 때 파생 노드와 콜백 파라미터에 붙여야 하는 타입 주석은 [09. 컴포넌트 경계 규약과 스타일 합성](../how-to/09-component-conventions.md) §6에 있습니다.

---

## 더 알고 싶다면

- [레퍼런스: `Source`](../reference/core/02-source.md) — `:Set`이 같은 값에도 늘 전파하는 이유, 제자리 변경을 알리는 `:Emit`
- [레퍼런스: `State`](../reference/core/03-state.md) — `:Get`의 lazy 계산, `:Compute`의 인자 검증, `:Apply`와 `:Gate`

---

## 다음 단계
- [03. 반응하기 — 이벤트와 관측](./03-reacting.md)
