---
title: "11. 컴포넌트로 쪼개기"
description: "카운터를 평범한 함수로 감싸 props로 설정을 받고, Slot으로 자식을 넘겨받습니다"
---
> **대상 독자**: [10. 자식이 들어갈 자리](/getting-started/10-slot/)를 끝낸 개발자
> **목표**: 카운터를 모듈 하나로 묶어 두 개를 나란히 띄우고, 바깥에서 자식을 넣을 수 있게 만들기

지금 카운터는 진입점 한가운데에 통째로 적혀 있어서, 하나 더 필요해지는 순간 그 덩어리를 복사하는 수밖에 없습니다. 그래서 함수로 묶습니다.

---

## 1. 컴포넌트는 평범한 함수입니다

Quad에서 컴포넌트는 특수한 클래스도 매크로도 아닙니다. **props 테이블을 받아 만들어진 Instance를 돌려주는 평범한 Luau 함수**입니다.

`src/client/UI/Counter.luau`를 새로 만들고, 지금까지의 코드를 그리로 옮깁니다. 바뀌어야 할 값은 `props`에서 받습니다.

옮겨 가는 것은 **이 장에 필요한 뼈대**(카운트·라벨·버튼)뿐입니다. 05~09장에서 붙였던 태그·속성·`CardStyle` Modifier·`buttonRef`와 그 `Effect`·생명주기 훅은 여기서 뺐고, 07장의 버튼 색 파이프도 잠시 리터럴로 돌아갑니다([12장](/getting-started/12-functions/)에서 파이프로 되돌립니다). 그것들을 컴포넌트 안쪽에 두는 모양은 [01. 컴포넌트 경계 규약과 스타일 합성](/how-to/01-component-conventions/)이 다룹니다.

```luau
-- 새 파일: ReplicatedStorage/Client/UI/Counter
const q = require("./Quad")     -- 같은 폴더의 설정 모듈
const D = q.D

return function(props)
    -- 상태는 컴포넌트 안에서 만든다 — 부른 쪽마다 자기 것을 갖는다
    const count = q.Source(props.Start or 0)

    const countText = count:Compute(function(c)
        return `{props.Label}: {c:Get()}`
    end)

    return D.Frame {
        Size = UDim2.fromOffset(200, 120),
        BackgroundColor3 = Color3.fromRGB(35, 35, 42),
        UICorner = 12,

        D.TextLabel {
            Position = UDim2.fromOffset(12, 0),
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

이제 진입점에서 둘을 나란히 놓습니다. **02~09에서 만들었던 `card`와 `card.Parent = screen` 줄은 지웁니다** — 그 코드는 이제 `Counter` 안으로 들어갔습니다.

```luau
-- (Main.client.luau 계속 — 이제 진입점은 부르기만 합니다)
const Counter = require("@game/ReplicatedStorage/Client/UI/Counter")

const row = D.Frame {
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

`Counter { ... }`는 `Counter({ ... })`의 Lua 슈거입니다 — `D.Frame { ... }`과 같은 모양이라 부르는 쪽에서 구분되지 않습니다.

> **철학: 마법은 없다 (No Magic)**
> 컴포넌트가 뒤에서 몰래 전역 상태를 만들거나 부모의 라이프사이클을 가로채지 않습니다. **필요한 것은 전부 `props`로 명시적으로 들어옵니다** — 트리를 거슬러 올라가 값을 찾아 주는 장치도 없습니다([14. 층을 건너 값 넘기기](/getting-started/14-context/)).

---

## 2. 자식을 넘겨받기

부르는 쪽이 카운터 안에 무언가를 더 넣고 싶다면, [10장](/getting-started/10-slot/)에서 만든 `Slot`을 props로 받으면 됩니다. `Counter`가 돌려주는 `D.Frame`의 **마지막 원소**로 한 줄을 더합니다.

```luau
-- … (Counter.luau 계속) 돌려주는 D.Frame의 마지막 원소로
        -- …버튼 생략…

        props.Children or q.None,
    }
end
```

부르는 쪽은 그 자리에 넣을 것을 `q.Slot { ... }`으로 싸서 넘깁니다.

```luau
-- … (Main.client.luau) 부르는 쪽에서
Counter {
    Label = "오른쪽",
    Start = 10,
    Children = q.Slot {
        D.TextLabel { Text = "덤으로 붙는 자식", TextSize = 12 },
    },
},
```

**실행하면** 오른쪽 카운터 안에만 라벨이 하나 더 붙습니다. `Children`을 안 넘긴 왼쪽 카운터는 그대로입니다 — `props.Children`이 `nil`이라 `q.None`이 그 자리를 지키기 때문입니다.

**`or q.None`은 생략하면 안 됩니다.** 숫자 키 자리의 표현식이 `nil`로 평가되면 그 자리가 [02장](/getting-started/02-first-screen/)에서 본 **구멍**이 됩니다. 지금은 마지막 자리라 우연히 넘어가지만, 뒤에 원소를 하나라도 더 붙이는 순간 그 자리에서 에러가 납니다. 02장에서 예고했던 그 값이 여기서 처음 필요해집니다.

```luau
-- ❌ props.Children이 없으면 이 자리가 구멍이 된다(뒤에 원소가 오면 에러)
D.Frame { D.TextLabel { … }, props.Children }

-- ✅ None이 자리를 지킨다 — 기여는 0이지만 위치는 그대로
D.Frame { D.TextLabel { … }, props.Children or q.None }
```

`q.None`은 "여기에 아무것도 없다"를 뜻하는 명시적 센티널입니다. 바깥에서 받은 것을 자기 숫자 키 자리에 꽂는 것이라면 `Modifier`든 `Ref`든 전부 같은 관용구를 씁니다.

<details>
<summary><strong><code>Slot</code>은 왜 <code>Children = …</code> 같은 문자 키로 못 넘기나요?</strong></summary>

`props.Children`이라는 이름부터가 이 문서가 따르는 관례이고, 언어나 엔진이 강제하는 것은 아닙니다.

넘길 수는 있습니다 — 위 코드가 그렇게 합니다. 못 하는 것은 **꽂는 쪽**입니다. `D.Frame { Children = props.Children }`처럼 문자 키의 **값 자리**에 두면 디스패치가 거부합니다.

props 테이블의 두 부분이 서로 다른 것을 받기 때문입니다.

- **문자 키**(`이름 = 값`)에는 **프로퍼티와 이벤트**가 옵니다. 값 자리에는 리터럴·`State`·`Tween`·`None`이 올 수 있고, 어떤 이름이 프로퍼티이고 어떤 이름이 이벤트인지는 엔진 리플렉션이 판정합니다. `UICorner`/`UIPadding`/`UIPaddingOffset`/`UIScale` 네 키만은 프로퍼티가 아니라 관리 자식을 만드는 숏핸드입니다.
- **숫자 키**(이름 없이 놓인 원소)에는 **자식 인스턴스와 디스크립터**가 옵니다 — `Modifier`, `Ref`/`PreRef`/`PostRef`, `Slot`, `Observer`/`Effect`, `Tag`/`Attr`, `q.OnChange(...)`. **순서가 의미를 갖습니다.**

그래서 컴포넌트는 그런 값을 props의 아무 이름으로나 받되(`props.Children`, `props.Modifier`, `props.Ref`), 자기 안쪽에 꽂을 때는 **숫자 키 자리에 `or q.None`을 붙여** 놓습니다. 이 경계 규약 전체는 [01. 컴포넌트 경계 규약과 스타일 합성](/how-to/01-component-conventions/) §1·§2에 있습니다.

</details>


---

## 더 알고 싶다면

- [01. 컴포넌트 경계 규약과 스타일 합성](/how-to/01-component-conventions/) — 바깥에서 `Modifier`/`Ref`를 받는 컴포넌트의 `or None` 관용구, 우선순위 불변식 셋, `Tag`/`Attr`, 재사용 로직 추출, 체크리스트
- [레퍼런스: `Slot`](/reference/core/06-slot/) — CRUD 열셋, 죽은 Slot과 마운트 규칙, `q.dispose`
