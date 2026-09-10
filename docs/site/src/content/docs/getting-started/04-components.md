---
title: "04. 컴포넌트로 쪼개기"
description: "카운터를 평범한 함수로 감싸 props로 설정을 받고, 자식을 넘겨받고, Modifier로 스타일을 재사용합니다"
---
> **대상 독자**: [03. 반응하기](/getting-started/03-reacting/)를 끝낸 개발자
> **목표**: 카운터를 함수 하나로 묶어 두 개를 나란히 띄우기

지금 카운터는 스크립트 한가운데에 통째로 적혀 있습니다. 하나 더 필요해지면 복사해야 합니다. 함수로 묶습니다.

---

## 1. 컴포넌트는 평범한 함수입니다

Quad에서 컴포넌트는 특수한 클래스도 매크로도 아닙니다. **props 테이블을 받아 만들어진 Instance를 돌려주는 평범한 Luau 함수**입니다. 03장의 코드를 `local function`으로 감싸고, 바뀌어야 할 값을 `props`에서 받습니다.

```luau
local function Counter(props)
    -- 상태는 컴포넌트 안에서 만든다 — 부른 쪽마다 자기 것을 갖는다
    local count = q.Source(props.Start or 0)

    local countText = count:Compute(function(c)
        return `{props.Label}: {c:Get()}`
    end)

    return D.Frame {
        Size = UDim2.fromOffset(200, 120),
        BackgroundColor3 = Color3.fromRGB(35, 35, 42),
        UICorner = 12,

        D.TextLabel {
            Size = UDim2.new(1, -24, 0, 48),
            BackgroundTransparency = 1,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextScaled = true,
            Text = countText,
        },

        D.TextButton {
            Size = UDim2.new(1, -24, 0, 40),
            Position = UDim2.new(0, 12, 1, -52),
            BackgroundColor3 = Color3.fromRGB(0, 162, 255),
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Text = "+ 1",
            UICorner = 8,

            Activated = function()
                count:Set(count:Get() + 1)
            end,
        },
    }
end
```

이제 둘을 나란히 놓습니다. **01~03에서 만들었던 최상위 `card`와 `card.Parent = screen` 줄은 지웁니다** — 그 코드는 이제 `Counter` 안으로 들어갔습니다.

```luau
local row = D.Frame {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(420, 120),
    BackgroundTransparency = 1,

    D.UIListLayout { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12) },

    Counter { Label = "왼쪽", Start = 0 },
    Counter { Label = "오른쪽", Start = 10 },
}
row.Parent = screen
```

**실행하면** 카운터 두 개가 나란히 뜨고, 각자 따로 셉니다. `Counter`를 부를 때마다 그 안의 `q.Source(...)`가 새로 만들어지기 때문입니다 — 컴포넌트는 **한 번 실행되는 셋업 함수**이고, 상태는 그 실행에 속합니다.

`Counter { ... }`는 `Counter({ ... })`의 Lua 문법 설탕입니다 — `D.Frame { ... }`과 같은 모양이라 부르는 쪽에서 구분되지 않습니다.

> **철학: 마법은 없다 (No Magic)**
> 컴포넌트가 뒤에서 몰래 전역 상태를 만들거나 부모의 라이프사이클을 가로채지 않습니다. 필요한 것은 전부 `props`로 명시적으로 들어옵니다. **트리를 거슬러 올라가 값을 찾아 주는 장치도 없습니다** — 부모가 가진 값이 자식에게 저절로 내려오는 경로는 없고, 계층을 건너뛰어 값을 넘기고 싶으면 `q.Context`로 명시적으로 넘깁니다([05. 디자인 토큰과 테마 전환](/how-to/05-theme-and-dynamic-styling/) 참고).

---

## 2. 자식 넘겨받기

호출하는 쪽이 카운터 안에 무언가를 더 넣고 싶다면, 배열 하나를 받아 그대로 펼치면 됩니다.

`Counter`가 돌려주는 `D.Frame`의 **마지막 원소**로 한 줄을 더합니다.

```luau
        -- …버튼 생략…

        table.unpack(props.children or {}),
    }
end
```

부르는 쪽:

```luau
Counter {
    Label = "오른쪽",
    Start = 10,
    children = {
        D.TextLabel { Text = "덤으로 붙는 자식", TextSize = 12 },
    },
},
```

`table.unpack(...)`은 **테이블 리터럴의 마지막 원소일 때만** 전부 펼쳐집니다. 중간에 두면 첫 값 하나만 들어가니 주의하세요. 그리고 **자식 배열을 담은 변수를 그대로 넘길 수는 없습니다** — `D.Frame(children)`은 타입이 맞지 않아 거부됩니다. props 테이블은 리터럴 자리에서만 추론이 살아 있으므로 위처럼 마지막 원소에 펼쳐 넣으세요.

`props.children`이라는 이름은 이 문서가 따르는 관례이고, 언어나 엔진이 강제하는 것은 아닙니다.

---

## 3. 스타일을 값으로 들고 다니기 — `Modifier`

카드의 배경색과 테두리를 다른 곳에서도 쓰고 싶습니다. `Modifier`는 **"이 프로퍼티들을 이렇게 설정한다"를 값 하나로 만든 것**이고, props의 **배열 부분**에 놓으면 그 필드들이 해시 부분으로 펼쳐집니다.

```luau
local CardStyle = D.Modifier.Frame {
    BackgroundColor3 = Color3.fromRGB(35, 35, 42),
    BorderSizePixel = 0,
}
```

`Counter` 안의 `D.Frame`에서 `BackgroundColor3` 한 줄을 지우고, 배열 부분 맨 앞에 `CardStyle`을 놓습니다.

```luau
    return D.Frame {
        CardStyle,                       -- ← 배열 부분

        Size = UDim2.fromOffset(200, 120),
        UICorner = 12,

        -- …자식들 생략…
    }
```

**실행하면** 겉모습은 그대로입니다 — 다만 이제 그 스타일은 값이라, 다른 컴포넌트에도 같은 것을 놓을 수 있습니다.

`D.Modifier.<Class>`는 **클래스 태그가 붙은** 생성자입니다. `TextButton` 전용 `Modifier`를 `Frame`의 배열 부분에 넣으면 타입 검사에서 걸립니다. 테이블을 넘기는 위 형태와 빌더 체인 형태(`D.Modifier.TextButton():TextSize(16)`) 둘 다 됩니다.

우선순위 규칙은 하나만 기억하면 이 장에서는 충분합니다. **해시 부분에 직접 적은 키가 `Modifier`보다 우선합니다.** 나머지 두 규칙과, 컴포넌트가 바깥에서 `Modifier`·`Ref`를 넘겨받을 때 지켜야 하는 경계 규약은 아래 how-to에 있습니다.

---

## 4. 층이 깊어지면 — `q.Context` 가방 하나

값은 props로 내리는 게 기본입니다. 다만 층이 깊어지면 중간 컴포넌트들이 자기가 쓰지도 않는 값을 계속 받아 넘겨야 합니다. `q.Context`는 그럴 때 **값 여러 개를 가방 하나로 묶어** 넘기는 도구입니다.

```luau
local ThemeProvider = q.Context.Provider("Theme")

-- 앱 진입점에서 한 번
local ctx = q.Context():Set(ThemeProvider, { Accent = Color3.fromRGB(0, 162, 255) })

-- 컴포넌트는 가방을 파라미터로 받아 자기 키만 읽는다
local function Counter(props)
    local theme = props.Ctx:Get(ThemeProvider)
    -- …
    --     BackgroundColor3 = theme.Accent,
end

Counter { Label = "왼쪽", Start = 0, Ctx = ctx }
```

여기서 중요한 것은 **가방도 손으로 넘긴다**는 점입니다. React의 Context처럼 트리를 거슬러 올라가 값을 찾아 주는 조회는 quad에 없습니다 — 줄어드는 것은 "중간 층이 알아야 할 이름의 수"이지, 넘기는 행위 자체가 아닙니다.

- `q.Context.Provider(name?)`가 돌려주는 것은 **테이블 신원 키**입니다 — 모듈 사이에 문자열 충돌이 없고, 같은 이름을 두 번 줘도 서로 다른 키입니다. 이름은 에러 메시지용 선택 인자입니다.
- `:Set`은 **가방 자신을 바꾸고** 자기를 돌려줍니다(체이닝).
- `:Get`은 없는 키에 에러를 내고, `:Peek`은 `nil`을 돌려줍니다.

---

## 더 알고 싶다면

- [09. 컴포넌트 경계 규약과 스타일 합성](/how-to/09-component-conventions/) — 바깥에서 `Modifier`/`Ref`를 받는 컴포넌트의 `or None` 관용구, 우선순위 불변식 셋, `Tag`/`Attr`, 재사용 로직 추출, 체크리스트
- [레퍼런스: `Modifier`](/reference/core/09-modifier/) — setter 체인, `Peek`, `Overridden`, 클래스 태그와 다운캐스트
- [레퍼런스: `Context` / `Provider`](/reference/sugar/01-context/) — 타입을 붙이는 두 가지 방법, 에러 문구, 가방의 수명
- [05. 디자인 토큰과 테마 전환](/how-to/05-theme-and-dynamic-styling/) — 토큰을 아래로 내리는 두 방법

---

## 다음 단계
- [05. 움직이게 하기 — `Animate`와 `Tween`](/getting-started/05-animation/)
