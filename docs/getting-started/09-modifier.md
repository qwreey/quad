---
title: "09. 스타일을 값으로 들고 다니기 — Modifier"
description: "프로퍼티 묶음을 Modifier 값 하나로 만들어 여러 인스턴스에 놓고, 팩토리로 뽑아 모듈 하나에 모읍니다"
---
# [시작하기] 09. 스타일을 값으로 들고 다니기 — `Modifier`

> **대상 독자**: [08. 생성만 보고 싶다면](./08-lifecycle-hooks.md)을 끝낸 개발자
> **목표**: 반복되는 프로퍼티 묶음을 값 하나로 빼서 여러 곳에 놓기

카드와 버튼의 색·테두리를 다른 화면에서도 그대로 쓰고 싶습니다. `Modifier`는
**"이 프로퍼티들을 이렇게 설정한다"를 값 하나로 만든 것**입니다. 컴포넌트와는
무관합니다 — 지금처럼 평범한 잎(카드 `Frame`, 버튼) 하나하나에 그대로 놓습니다.

---

## 1. 값으로 빼기

```luau
-- … 위쪽 코드에 이어집니다(card 위에 한 덩이를 둡니다)
const CardStyle = D.Modifier.Frame {
    BackgroundColor3 = Color3.fromRGB(35, 35, 42),
    BorderSizePixel = 0,
}
```

`card`의 문자 키에서 `BackgroundColor3` 한 줄을 지우고, **숫자 키 맨 앞**에 `CardStyle`을 놓습니다.

```luau
-- … 위쪽 코드에 이어집니다
const card = D.Frame {
    CardStyle,                       -- ← 숫자 키

    Size = UDim2.fromOffset(240, 160),
    UICorner = 12,

    -- …자식들 생략…
}
```

**실행하면** 겉모습은 그대로입니다 — 다만 이제 그 스타일은 값이라, 다른 인스턴스에도 같은 것을 놓을 수 있습니다.

`D.Modifier.<Class>`는 **클래스 태그가 붙은** 생성자입니다. `TextButton` 전용 `Modifier`를 `Frame`의 숫자 키 자리에 넣으면 타입 검사에서 걸립니다. 테이블을 넘기는 위 형태와 빌더 체인 형태(`D.Modifier.TextButton():TextSize(16)`) 둘 다 됩니다.

---

## 2. 필드에도 값이 흐릅니다

`Modifier`의 필드 값 자리에는 리터럴뿐 아니라 **`State`/`Source`도 올 수 있습니다.** 그러면 그 `Modifier`를 놓은 인스턴스의 프로퍼티가 그 값을 따라갑니다.

```luau
-- … 위쪽 코드에 이어집니다(CardStyle을 이렇게 고칩니다)
const hot = q.Source(false)

const CardStyle = D.Modifier.Frame {
    BackgroundColor3 = hot:Compute(function(h)
        return if h:Get()
            then Color3.fromRGB(240, 60, 60)
            else Color3.fromRGB(35, 35, 42)
    end),
    BorderSizePixel = 0,
}

const card = D.Frame { CardStyle, Size = UDim2.fromOffset(240, 160) } -- …앞 장의 자식들은 그대로…

hot:Set(true)   -- 카드 배경이 빨강으로 바뀐다
```

**실행하면** `hot:Set(true)` 시점에 카드 배경이 바뀝니다. 03장에서 프로퍼티에 직접 꽂았던 그 흐름이, `Modifier`를 한 단계 거쳐 같은 자리에 도착한 것입니다.

우선순위는 이 장에서 하나만 알면 충분합니다. **직접 적은 문자 키가 `Modifier`보다 우선합니다.**

그리고 하나 더 알아 두면 좋은 성질이 있습니다. **`Modifier`는 불변입니다.** setter를 하나 부를 때마다 새 값이 생기고 원본은 그대로라, 하나의 기본 스타일에서 갈라 나온 형제들이 서로를 오염시키지 않습니다.

```luau
-- … 위쪽 코드에 이어집니다
const base = D.Modifier.TextButton { TextSize = 16 }
const big = base:TextSize(24)     -- base는 그대로 16
```

<details>
<summary><strong><code>Modifier</code>가 여럿이면 누가 이기나요?</strong></summary>

무엇이 무엇을 덮는지는 규칙 셋뿐입니다.

1. **직접 적은 문자 키가 이깁니다.** `D.TextButton { SomeMod, Text = "확정" }`에서 `Text`는 어떤 `Modifier`가 무엇을 갖고 오든 그대로 유지됩니다.
2. **숫자 키 자리에서는 뒤에 온 `Modifier`가 앞의 것을 필드 단위로 덮습니다.**
3. **`Modifier.Overridden(A, B)`도 같은 방향**입니다 — 뒤 인자가 앞 인자를 덮습니다. 닷 형태와 콜론 형태(`a:Overridden(b)`) 둘 다 됩니다.

빈 자리를 명시적으로 비우고 싶으면 `q.None`을 넣습니다. `nil`은 "이 `Modifier`는 그 필드에 관심 없음"이고, `q.None`은 "그 필드를 비워라"입니다 — 뜻이 다릅니다.

컴포넌트가 바깥에서 `Modifier`를 받아 자기 안쪽에 꽂을 때의 경계 규약(`props.Modifier or q.None`)과 상위 클래스 `Modifier`를 받는 법은 [01. 컴포넌트 경계 규약과 스타일 합성](../how-to/01-component-conventions.md) §2·§3에 있습니다.

</details>

---

## 3. 팩토리로 뽑고, 모듈 하나에 모으기

스타일을 함수로 만들면 인자를 받는 스타일이 됩니다.

```luau
-- … 위쪽 코드에 이어집니다
local function accent(color)
    return D.Modifier.TextButton {
        BackgroundColor3 = color,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
    }
end

const button = D.TextButton { accent(Color3.fromRGB(0, 162, 255)), Text = "+ 1" }
```

**실행하면** 버튼이 넘긴 색으로 칠해집니다 — 흰 글자와 `BorderSizePixel = 0`은 팩토리 안에 그대로 있어서, 색만 다른 버튼을 얼마든지 찍어낼 수 있습니다.

**권장하는 배치는 스타일을 모듈 하나에 모아 내보내는 것**입니다. 화면마다 색 리터럴이 흩어지지 않고, 나중에 테마를 바꿀 때 고칠 자리가 한 곳이 됩니다.

```luau
-- 새 파일: ReplicatedStorage/Client/UI/Styles
const q = require("@game/ReplicatedStorage/Client/UI/Quad")
const D = q.D

local function accent(color)
    return D.Modifier.TextButton {
        BackgroundColor3 = color,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
    }
end

return {
    Card = D.Modifier.Frame {
        BackgroundColor3 = Color3.fromRGB(35, 35, 42),
        BorderSizePixel = 0,
    },
    Accent = accent,
}
```

쓰는 쪽은 `const Styles = require("@game/ReplicatedStorage/Client/UI/Styles")` 뒤에 `Styles.Card`, `Styles.Accent(색)`을 숫자 키 자리에 놓습니다.


---

## 더 알고 싶다면

- [레퍼런스: `Modifier`](../reference/core/08-modifier.md) — setter 체인, `Peek`, `Overridden`, 클래스 태그와 다운캐스트
- [레퍼런스: `D.Modifier`](../reference/roblox/03-d-modifier.md) — 클래스별 생성자와 생성된 setter 타입
- [05. 디자인 토큰과 테마 전환](../how-to/05-theme-and-dynamic-styling.md) — 토큰을 모아 두고 테마를 갈아 끼우는 실전 배치
