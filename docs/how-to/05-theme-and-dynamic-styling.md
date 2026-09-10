---
title: "05. 디자인 토큰과 테마 전환 — `Animate`와 `Modifier.Overridden`"
description: "디자인 토큰과 Animate, Modifier Overridden으로 다크 라이트 테마 전환을 구현하는 법을 설명합니다"
---
# [실전 레시피] 05. 디자인 토큰과 테마 전환 — `Animate`와 `Modifier.Overridden`

> **대상 독자**: 다크/라이트 테마와 재사용 가능한 스타일 아키텍처를 만들려는 개발자
> **다루는 개념**: 디자인 토큰, `q.Context`, `state:Apply(factory)`, `q.Operator.Indexed`,
> `q.Animate`, `Modifier.Overridden`

```luau
-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 참고)
local Quad = require(<quad-base 모듈 경로>)
local QuadRoblox = require(<quad-roblox 모듈 경로>).QuadRoblox
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
local D = q.D
-- 클래스별 Modifier 타입(`FrameModifier`/`IntoFrame` 등)은 생성된 D 모듈에서 가져온다
local DTypes = require(<quad-roblox D 모듈 경로>)
```

---

## 1. 디자인 토큰 아키텍처

색을 컴포넌트마다 하드코딩하는 대신, 의미 역할로 이름을 붙입니다 —
`Background`, `Surface`, `TextPrimary`, `TextMuted`, `Accent`, `Border`.

quad에는 트리를 훑어 올라가는 **암묵적** 컨텍스트가 없습니다. 토큰을 아래로
내리는 방법은 둘입니다.

- **props로 직접 넘기기** — 층이 얕으면 이게 가장 단순합니다.
- **`q.Context`** — 중간 층이 앱의 스토어 스키마를 몰라도 가방 하나를 그대로
  전달할 수 있는 **명시적** 값 컨테이너입니다. 트리 탐색은 여전히 없습니다:
  컴포넌트는 가방을 이름 붙은 파라미터로 받아 자기 키만 읽습니다.

```luau
local ThemeProvider = q.Context.Provider("Theme")

-- 앱 진입점에서 한 번
local ctx = q.Context():Set(ThemeProvider, Theme)

-- 아래 어딘가에서
local theme = ctx:Get(ThemeProvider)   -- 없으면 에러
local maybe = ctx:Peek(ThemeProvider)  -- 없으면 nil
```

- `Context.Provider(name?)`가 돌려주는 것은 **테이블 신원 키**입니다 —
  모듈 간 문자열 충돌이 없습니다. 이름은 에러 메시지용 선택 인자입니다.
- `:Set`은 **가방 자신을 변경하고** 자기를 돌려줍니다(체이닝). 값이 `nil`이면
  에러입니다 — "없음"은 안 넣는 것으로 표현합니다.
- `:Get`은 없으면 에러, `:Peek`은 `nil`입니다. 가방을 열거하는 표면은
  일부러 없습니다.

---

## 2. 테마 토큰 만들기

```luau
-- Theme.luau
export type ColorPalette = {
    Background: Color3,
    Surface: Color3,
    TextPrimary: Color3,
    TextMuted: Color3,
    Accent: Color3,
    Border: Color3,
}

local LIGHT: ColorPalette = {
    Background = Color3.fromRGB(248, 249, 250),
    Surface = Color3.fromRGB(255, 255, 255),
    TextPrimary = Color3.fromRGB(33, 37, 41),
    TextMuted = Color3.fromRGB(108, 117, 125),
    Accent = Color3.fromRGB(13, 110, 253),
    Border = Color3.fromRGB(222, 226, 230),
}

local DARK: ColorPalette = {
    Background = Color3.fromRGB(18, 18, 18),
    Surface = Color3.fromRGB(30, 30, 30),
    TextPrimary = Color3.fromRGB(240, 240, 240),
    TextMuted = Color3.fromRGB(160, 160, 160),
    Accent = Color3.fromRGB(66, 153, 225),
    Border = Color3.fromRGB(45, 45, 45),
}

local isDark = q.Source(true)

-- 지금 쓸 팔레트를 고르는 것은 한 번이면 된다
local palette = isDark:Compute(function(dark)
    return if dark:Get() then DARK else LIGHT
end)

-- 토큰 하나 = "팔레트에서 키 하나를 읽는 State"에 애니메이션을 얹은 것
local function token(key: string)
    return palette
        :Apply(q.Operator.Indexed<<Color3>>(key))
        :Apply(q.Animate({
            Time = 0.25,
            Style = Enum.EasingStyle.Quad,
            Direction = Enum.EasingDirection.Out,
        }))
end

return {
    IsDark = isDark,
    Toggle = function()
        isDark:Set(not isDark:Get())
    end,
    Tokens = {
        Background = token("Background"),
        Surface = token("Surface"),
        TextPrimary = token("TextPrimary"),
        TextMuted = token("TextMuted"),
        Accent = token("Accent"),
        Border = token("Border"),
    },
}
```

### `:Apply(factory)` — 팩토리가 만든 연산을 State에 얹는다

`state:Apply(factory)`는 "팩토리가 만들어 준 연산을 이 State에 적용해 새 State를
얻는다"는 일반형입니다. 위 `token`이 그 모양을 두 번 씁니다 —
`q.Operator.Indexed<<V>>(key)`는 상류 값에서 키 하나를 읽어 주는 팩토리(`:Compute`
슈거)이고, 이어 붙인 `q.Animate({...})`도 같은 자리에 놓이는 팩토리입니다. 덕분에
토큰마다 `function(p) return p.Background end`를 손으로 하나씩 둘 필요가 없습니다.

`Indexed`의 값 타입은 키에서 추론되지 않으니 `<<Color3>>`처럼 호출자가 직접 적고,
없는 키는 에러 없이 `nil`이 되니 키 이름은 팔레트 쪽과 맞춰 두세요. 이런 이름 붙은
콤비네이터가 열넷 있습니다 — [레퍼런스: `Operator`](../reference/sugar/02-operator.md).

### 애니메이션은 `state:Apply(q.Animate{...})`로 붙인다

`q.Tween{...}`은 **한 번의 목표값**을 서술하는 옵션 테이블이고, 그 `Value`는
plain 값이어야 합니다(State를 넣으면 에러입니다). 값이 바뀔 때마다 자동으로
보간되게 하려면 State에 `q.Animate`를 `:Apply`합니다.

- 옵션 이름은 `Time` / `Style` / `Direction` / `RepeatCount` / `Reverses` /
  `DelayTime` / `Override`("Cancel" 또는 "Finish") / `Dedup` /
  `CanAnimate`이고, `Info`에 `TweenInfo`를 통째로 줄 수도 있습니다.
- 옵션에도 State를 넣을 수 있지만 **옵션 State가 바뀌었다고 다시
  애니메이션하지는 않습니다** — 다음 값 변경 때 최신 옵션이 반영됩니다.
- `CanAnimate = false`면 보간 없이 값이 그대로 나갑니다(모션 축소 옵션에
  쓰기 좋습니다).

---

## 3. `Modifier.Overridden`으로 스타일 합성

`Modifier`는 **불변**입니다 — 모든 setter는 바깥 테이블과 필드 테이블을 둘 다
얕게 복제해서 새 `Modifier`를 만들고, 만들어진 `Modifier`는 얼어 있습니다.
그래서 공용 기본 스타일을 컴포넌트에 넘겨도 원본이 오염되지 않습니다.

```luau
-- Styles.luau
return {
    Button = D.Modifier.TextButton()
        :Size(UDim2.new(0, 120, 0, 40))
        :BackgroundColor3(Theme.Tokens.Accent)
        :BorderSizePixel(0),
}
```

초기 필드 테이블 형태도 같은 값입니다 — `D.Modifier.TextButton { Size = ... }`.

```luau
-- ThemedButton.luau
local function ThemedButton(props: {
    read Text: string?,
    read OnClick: () -> (),
    read Modifier: DTypes.IntoTextButton?,
})
    -- 호출자 오버라이드가 있으면 기본 스타일 위에 얹는다(뒤가 이긴다)
    local effective = if props.Modifier
        then q.Modifier.Overridden(Styles.Button, props.Modifier:AsTextButton())
        else Styles.Button

    return D.TextButton {
        effective,
        Text = props.Text or "",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        FontFace = Font.fromEnum(Enum.Font.GothamBold),
        TextSize = 14,
        Activated = function()
            props.OnClick()
        end,
    }
end
```

> **글꼴은 `FontFace`로 쓰세요.** 예제가 전부 `FontFace = Font.fromEnum(...)`인 이유는 그게
> 현행 API이기 때문입니다. **[2026-09-09]** 옛 `Font = Enum.Font.GothamBold`도 생성 `D`에
> 있어 타입 검사를 통과하지만, 엔진이 `Hidden`으로 표시한 레거시라 필드에 `-- @deprecated`
> 주석이 붙어 있습니다 — quad v1 코드를 옮기는 동안에만 쓰고 새 코드에는 `FontFace`를 쓰세요.

- `Modifier.Overridden(a, b, ...)`는 **필드 단위로 합치고 뒤 인자가
  이깁니다**. 닷 형태와 콜론 형태(`a:Overridden(b)`)가 같은 함수입니다.
- props로 받은 `Modifier`는 `IntoTextButton` 인터페이스로 받고
  `:AsTextButton()`으로 검사형 하강을 합니다 — 상위 클래스 Modifier
  (`D.Modifier.GuiObject()`)도 그대로 들어옵니다. `mod:As<<T>>()`는 **무검사**
  캐스트이니 필요할 때만 쓰세요.
- `Modifier`는 숫자 키 자리에 놓습니다. 선택적이면 `props.Modifier or q.None`
  관용구를 씁니다.

---

## 4. 테마가 붙은 카드 조립

```luau
local function SettingsCard()
    return D.Frame {
        Size = UDim2.new(0, 360, 0, 240),
        Position = UDim2.new(0.5, -180, 0.5, -120),
        BackgroundColor3 = Theme.Tokens.Surface,
        BorderSizePixel = 0,

        UICorner = UDim.new(0, 12), -- 숏핸드: 관리 자식 UICorner를 만들어 붙인다

        D.TextLabel {
            Size = UDim2.new(1, -40, 0, 30),
            Position = UDim2.new(0, 20, 0, 20),
            BackgroundTransparency = 1,
            FontFace = Font.fromEnum(Enum.Font.GothamBold),
            TextSize = 18,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = Theme.Tokens.TextPrimary,
            Text = "화면 설정",
        },

        D.TextLabel {
            Size = UDim2.new(1, -40, 0, 20),
            Position = UDim2.new(0, 20, 0, 55),
            BackgroundTransparency = 1,
            FontFace = Font.fromEnum(Enum.Font.Gotham),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = Theme.Tokens.TextMuted,
            Text = "테마와 표시 옵션을 바꿉니다.",
        },

        ThemedButton {
            Text = "테마 전환",
            OnClick = Theme.Toggle,
            Modifier = D.Modifier.TextButton()
                :Position(UDim2.new(0, 20, 1, -60))
                :Size(UDim2.new(0, 140, 0, 38)),
        },
    }
end
```

`Parent`는 props가 아닙니다 — 만든 뒤 밖에서 `card.Parent = screenGui` 한 줄로
붙입니다.

---

## 5. 이 구조가 주는 것

1. **토큰 갱신 경로가 하나입니다.** `isDark:Set`만 바뀌면 그 토큰을 쓰는 모든
   프로퍼티가 같은 경로로 갱신됩니다.
2. **전환이 부드럽습니다.** 각 토큰이 `:Apply(q.Animate{...})`를 거치므로
   색이 튀지 않고 보간됩니다.
3. **스타일 격리가 구조적으로 보장됩니다.** `Modifier`가 불변이라, 커스터마이즈
   한 사본을 넘겨도 공용 원본이 바뀌지 않습니다.
