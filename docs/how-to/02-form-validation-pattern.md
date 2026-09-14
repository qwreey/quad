---
title: "02. 폼 유효성 검사와 제출 버튼 제어"
description: "값을 밖에서 받는 체크박스에서 시작해, 폼 상태를 테이블 하나로 묶어 컴포넌트에 주입하고, 실시간 검증·버튼 제어와 제출 결과 관측을 선언적으로 구현하는 법을 다룹니다"
---
# [실전 레시피] 02. 폼 유효성 검사와 제출 버튼 제어

> **대상 독자**: 입력이 여럿인 화면을 만들고, 그 결과를 컴포넌트 바깥에서 받아야 하는 개발자
> **다루는 개념**: 상태 주입(작게는 체크박스 하나부터), `Source`/`State`, `Store`, `:Compute`, `:With`, `OnChange`, `Observer`

---

## 1. 해결하려는 문제

로그인·회원가입 폼에서 반복되는 요구사항 넷입니다.

1. 입력이 바뀔 때마다 실시간으로 유효성을 검사한다.
2. 유효하지 않으면 에러 라벨을 보인다.
3. 모든 필드가 유효할 때만 제출 버튼을 활성화하고 색을 바꾼다.
4. **제출 결과는 폼이 아니라 바깥이 처리한다** — 서버로 보내는 것도, 다음 화면으로 넘기는 것도 폼의 일이 아닙니다.

`q.Store`는 시작하기에서 다루지 않았습니다 — 이름 붙은 `Source`들을 한 테이블에 담는 묶음이고, 전체 표면은 [레퍼런스: `Store`](../reference/core/04-store.md)에 있습니다.

`Store`에 원본 입력값을 모으고 `:Compute`로 판정을 파생시키면 앞의 셋이 전부
선언으로 끝나고, 그 묶음을 **컴포넌트 밖에서 만들어 props로 넣으면** 넷째도
따라옵니다.

```luau
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("@game/ReplicatedStorage/Client/UI/Quad")
local D = q.Declaration
```

---

## 2. 작은 것부터 — 값을 밖에서 받는 체크박스

폼을 통째로 짜기 전에, 같은 모양의 가장 작은 판을 하나 먼저 봅니다. **체크박스**입니다. 체크가 켜졌는지를 정작 필요로 하는 것은 체크박스 자신이 아니라 그것을 화면에 놓은 쪽이므로, 상태를 안에서 만들면 바깥이 값을 볼 길이 없습니다. 그래서 **원천은 부르는 쪽이 만들어 props로 넘깁니다.**

```luau
-- 재사용 컴포넌트(예: ReplicatedStorage/Client/UI/Checkbox)
local function Checkbox(props: { read Value: q.Source<boolean>, read Label: string }): TextButton
    local checked = props.Value

    -- 파생은 props 테이블 밖에서 만들어 둔다(§4의 주의 참고)
    local labelText: q.State<string> = checked:Compute(function(c)
        return `{if c:Get() then "☑" else "☐"} {props.Label}`
    end)

    return D.TextButton {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Text = labelText,

        Activated = function()
            checked:Set(not checked:Get())
        end,
    }
end
```

컴포넌트가 하는 일은 둘뿐입니다 — 받은 원천을 **읽어 그리고**, 눌리면 그 자리에 **되돌려 씁니다**. 값을 어떻게 쓸지는 전부 바깥의 몫이라, 바깥은 같은 원천에 파이프를 붙여 자기 판정을 만듭니다. 아래 폼에서 실제로 필요한 판정 하나를 미리 만들어 보면 이렇습니다.

```luau
-- 부르는 쪽 — 원천을 만들고, 그 위에 판정을 얹는다
local agreed = q.Source(false)

-- 약관에 동의해야만 제출할 수 있다
local canSubmit: q.State<boolean> = agreed:Compute(function(c)
    return c:Get()
end)

local submitColor: q.State<Color3> = canSubmit:Compute(function(enabled)
    return if enabled:Get()
        then Color3.fromRGB(0, 170, 255)
        else Color3.fromRGB(80, 80, 90)
end)

local panel = D.Frame {
    Checkbox { Label = "약관에 동의합니다", Value = agreed },

    D.TextButton {
        Text = "가입하기",
        AutoButtonColor = canSubmit,
        BackgroundColor3 = submitColor,
    },
}
```

체크박스를 누르면 `AutoButtonColor`와 버튼 색이 같이 따라옵니다. 체크박스는 제출 버튼이 있는지도 모르고, 제출 버튼은 체크박스가 있는지도 모릅니다 — 둘을 잇는 것은 **밖에서 만든 원천 하나**뿐입니다.
<!-- mock 실측 2026-09-14: gs.checkbox.luau 1·6 — 컴포넌트 안의 :Set이 바깥 판정(canSubmit)과 그 파생(submitColor)까지 돌고, 해제하면 그대로 되돌아온다 -->

읽기만 하면 되는 컴포넌트라면 `Source` 대신 파생된 `State`를 넘기세요. **`State`에는 `:Set`이 없어서** 받은 쪽이 값을 바꿀 길이 없고, 그래서 "이 컴포넌트는 읽기만 한다"가 넘기는 것의 종류로 드러납니다([레퍼런스: `State`](../reference/core/03-state.md)).

**이 모양을 값 여럿·검증·제출까지 키운 것이 아래의 폼입니다.** 원천이 하나에서 여럿이 되니 그것을 `Store` 하나에 모으고, 판정이 하나에서 여럿이 되니 `:Compute`를 겹치고, 결과를 바깥으로 내보낼 자리가 하나 더 필요해질 뿐 — 밖에서 만들어 넣는다는 뼈대는 그대로입니다.

---

## 3. 폼 상태를 테이블 하나로 묶기

`q.Store`는 **이름 붙은 `Source`들을 담는 테이블**입니다. 생성자에 넘기는 값은
전부 `Source`여야 하고(아니면 그 자리에서 거부합니다), 꺼낼 때는
`store.Username`처럼 필드로 읽으면 그 `Source` 자체가 나옵니다.

여기서 만드는 것은 `Store` 하나가 아니라, **그 폼 한 벌이 쓰는 상태 전부를 담은
테이블 하나**입니다 — 원본 입력(`Store`), 파생된 판정들, 그리고 제출 결과가
담기는 자리까지. 이 테이블이 그대로 컴포넌트의 props로 들어갑니다.

```luau
-- 폼 상태만 모아 둔 모듈(예: ReplicatedStorage/Client/UI/RegistrationFormState).
-- 화면을 만들지 않으므로 UI 없이도 require해서 검증할 수 있습니다.
type Submission = { Username: string, Password: string }

local function makeFormState()
    -- [1] 원본 입력값
    local store = q.Store({
        Username = q.Source(""),
        Password = q.Source(""),
    })

    -- [2] 필드별 판정 — 순수 파생 상태
    local isUsernameValid = store.Username:Compute(function(self)
        return #self:Get() >= 4
    end)

    local isPasswordValid = store.Password:Compute(function(self)
        local text = self:Get()
        return #text >= 8 and string.find(text, "%d") ~= nil
    end)

    -- [3] 둘을 하나로 — 후행 의존성으로 노드 하나만 더 만든다
    local canSubmit = isUsernameValid:Compute(function(validUser, _previous, validPass)
        return validUser:Get() and validPass:Get()
    end, isPasswordValid)

    -- [4] 제출 결과가 담기는 자리 — 바깥으로 나가는 하나뿐인 출구
    local submitted = q.Source<<Submission?>>(nil)

    return {
        Store = store,
        IsUsernameValid = isUsernameValid,
        IsPasswordValid = isPasswordValid,
        CanSubmit = canSubmit,
        Submitted = submitted,
    }
end

type FormState = typeof(makeFormState())
```

- 돌려주는 것은 **평범한 레코드**입니다 — `Store`는 그중 한 필드로 들어앉고, 나머지는 파생 노드와 결과 자리입니다. 이름은 마음대로 정해도 되지만 이 문서는 `Store`/`CanSubmit`/`Submitted`로 부릅니다.
- `FormState` 타입을 손으로 적을 필요는 없습니다. `typeof(makeFormState())`가 반환 테이블의 모양을 그대로 타입으로 씁니다(모듈로 나눌 땐 `Submission`과 함께 `export type`으로 내보내세요 — 부르는 쪽이 둘 다 씁니다).
- `q.Source<<Submission?>>(nil)`처럼 **타입 인자를 명시**해야 `Source<Submission?>`가 됩니다 — 값만 보고는 `nil`밖에 알 수 없기 때문입니다.

**폼 상태는 컴포넌트 밖에서 만들어 주입합니다** — §2의 체크박스와 같은 이유입니다. 전역에 싱글톤으로 두면 그 폼을
두 번 띄울 수 없고, 반대로 컴포넌트 안에서 만들어 버리면 바깥이 결과를 볼
길이 없습니다. `makeFormState()`를 **부르는 쪽마다 한 벌씩** 만들면 둘 다
풀립니다(근거는 [§6](#6-핵심-모범-사례)).

### `:Compute` 콜백의 인자 순서

```
state:Compute(function(self, previous, ...deps) ... end, ...deps)
```

- **첫 번째**는 `state` 자신입니다. 값이 아니라 핸들이므로 `:Get()`으로
  읽습니다.
- **두 번째**는 직전 계산 결과(`previous`)입니다 — 첫 사이클엔 `nil`입니다.
  **여기에 의존성이 오지 않습니다.**
- 세 번째부터가 뒤에 넘긴 의존성들이고, 이들도 전부 핸들이라 `:Get()`으로
  읽습니다.

`:With(other)`로 구독만 넓히고 클로저로 직접 읽는 방법도 있습니다. 노드가
하나 더 생길 뿐 금지된 방법은 아닙니다.

```luau
-- makeFormState 안에서, [3] 대신
local canSubmit = isUsernameValid:With(isPasswordValid):Compute(function(validUser)
    return validUser:Get() and isPasswordValid:Get()   -- :With한 값은 클로저로 읽는다
end)
```

> ⚠️ `:With`로 모은 값은 콜백에 **포지셔널로 넘어오지 않습니다**. 두 번째
> 자리에 오는 것은 여전히 `previous`입니다.

---

## 4. UI 조립 — 컴포넌트는 상태를 받기만 한다

컴포넌트가 하는 일은 **받은 상태를 화면에 잇는 것**뿐입니다. 상태를 만들지도,
결과를 어디로 보낼지 정하지도 않습니다.

```luau
local function RegistrationForm(props: { read Form: FormState }): Frame
    local form = props.Form
    local store = form.Store

    -- 파생 상태는 props 테이블 밖에서 만들어 둔다(아래 주의 참고).
    -- 보이는 모양(색·표시 여부)은 폼 상태가 아니라 이 컴포넌트의 것이다.
    local showUsernameError: q.State<boolean> = form.IsUsernameValid:Compute(function(valid)
        return not valid:Get()
    end)
    local submitColor: q.State<Color3> = form.CanSubmit:Compute(function(enabled)
        return if enabled:Get()
            then Color3.fromRGB(0, 170, 255)
            else Color3.fromRGB(80, 80, 90)
    end)

    return D.Frame {
        Size = UDim2.new(0, 320, 0, 240),
        BackgroundColor3 = Color3.fromRGB(30, 30, 35),

        -- 아이디 입력창
        D.TextBox {
            PlaceholderText = "아이디 (4자 이상)",
            Text = store.Username,
            q.OnChange("Text", function(newText)
                store.Username:Set(newText)
            end),
        },

        -- 아이디 에러 메시지
        D.TextLabel {
            Text = "아이디는 4글자 이상이어야 합니다.",
            TextColor3 = Color3.fromRGB(255, 100, 100),
            Visible = showUsernameError,
        },

        -- 비밀번호 입력창
        D.TextBox {
            PlaceholderText = "비밀번호 (8자 이상, 숫자 포함)",
            Text = store.Password,
            q.OnChange("Text", function(newText)
                store.Password:Set(newText)
            end),
        },

        -- 제출 버튼 — 결과를 직접 처리하지 않고 상태에 적기만 한다
        D.TextButton {
            Text = "가입하기",
            AutoButtonColor = form.CanSubmit,
            BackgroundColor3 = submitColor,
            MouseButton1Click = function()
                if not form.CanSubmit:Get() then
                    return
                end
                form.Submitted:Set({
                    Username = store.Username:Get(),
                    Password = store.Password:Get(),
                })
            end,
        },
    }
end
```

> `Text = store.Username`으로 값을 내려보내면서 같은 `Text`의 `OnChange`로 되쓰는 모양이 순환처럼 보이지만, 되먹임은 생기지 않습니다 — 되쓴 값은 입력창이 이미 가진 값이고, Roblox는 같은 값을 다시 대입해도 변경 이벤트를 발화하지 않습니다(엔진 동작). quad 쪽은 같은 값에도 emit을 하므로, 이 안전성은 프로퍼티 자리에서만 성립합니다.

`q.OnChange(name, fn)`는 **숫자 키 자리에 놓는 디스크립터**입니다(문자 키가
아닙니다). 콜백은 엔진이 주는 인자만 받습니다 — `self`는 넘어오지 않습니다.
이벤트 핸들러(`MouseButton1Click` 등)는 반대로 문자 키에 놓습니다. 읽기 전용
프로퍼티까지 포함한 이름 표면과 초기값 발화 계약은
[레퍼런스: `q.OnChange`](../reference/roblox/05-onchange.md)가 다룹니다.

> ⚠️ **`:Compute`를 props 테이블 안에 인라인으로 쓰면 에디터 타입 검사가
> 깨집니다.** 함수 인자로 넘기는 테이블 리터럴 안에서는 무주석 콜백의
> 파라미터가 풀리지 않습니다(런타임은 정상이지만 편집기에 빨간 줄이
> 그어집니다). 위처럼 **별도 문장으로 빼서 타입을 붙인 지역 변수**에 담거나,
> 콜백 파라미터에 `q.StateData<T>` 주석을 다세요. 숫자 키 자리에 놓는
> 값은 이 문제를 겪지 않습니다.

---

## 5. 밖에서 만들어 넘기고, 밖에서 결과 받기

부르는 쪽이 폼 상태를 만들어 넘기고, 같은 테이블의 `Submitted`를 관측합니다.
상태와 컴포넌트를 각각 모듈로 빼 두었다면(`makeFormState`를 내보내는 모듈과
`return RegistrationForm`하는 모듈), 진입점은 그 둘을 `require`합니다.

```luau
-- 진입점(예: Main.client.luau)
local form = makeFormState()

local screen = D.ScreenGui {
    RegistrationForm { Form = form },

    -- 숫자 키 자리의 Observer — 이 ScreenGui가 사는 동안만 관측한다
    form.Submitted:Observer(function(target)
        local payload = target:Get()
        if payload == nil then
            return -- 묶이는 순간의 첫 발화 — 아직 제출 전이다
        end
        -- 여기서 서버로 보내거나 다음 화면으로 넘긴다
        print("가입 요청:", payload.Username)
    end),
}
```

<!-- mock 실측 2026-09-13: gs.form.luau — Observer 생성 직후 이미 1회(payload nil, 묶기 전), 제출 뒤 2회(payload.Username "quad"), screen 파괴 뒤 Set해도 2회 그대로 -->

- **첫 발화는 `nil`을 들고 옵니다.** `Observer`는 값을 실어주지 않고 **만들어질 때**
  한 번 불리므로(실측: 숫자 키 자리에 놓기 전에 이미 1회), 아직 제출이 없는 상태를
  `nil`로 걸러내야 합니다. 제출 버튼을 누르면 그때 2회째가 오고, 그 시점의
  `Submitted`에 방금 적힌 payload가 들어 있습니다.
- **관측도 화면과 함께 죽습니다.** `q.dispose(screen)`으로 화면을 내린 뒤에 `Submitted`를 바꿔도
  콜백은 더 불리지 않습니다(실측: 발화 수 2 그대로). 화면보다 오래 사는 소비자가
  필요하면 숫자 키 자리 대신 `observer:Subscribe()`로 전역 구독을 잡으세요 —
  대신 그 수명은 직접 책임집니다([레퍼런스: `Observer`](../reference/core/05-observer-effect.md)).
- **같은 폼을 두 번 띄워도 섞이지 않습니다.** `makeFormState()`를 두 번 부르면
  두 벌이 독립적으로 돕니다(실측: 한쪽에만 아이디를 넣으면 다른 쪽 판정은 그대로
  `false`).

<details>
<summary><strong>상태 대신 콜백으로 받고 싶다면</strong></summary>

`props.OnSubmit` 콜백을 받는 모양도 됩니다. `Submitted` 자리를 대신하는 것이지
둘을 같이 두는 것이 아닙니다 — 출구가 둘이면 어느 쪽이 정본인지 부르는 쪽이
알 수 없습니다.

```luau
-- props에 콜백이 하나 늘고, makeFormState의 [4] Submitted 필드는 사라집니다
type Props = { read Form: FormState, read OnSubmit: (Submission) -> () }

local function submit(props: Props)
    if not props.Form.CanSubmit:Get() then
        return
    end
    props.OnSubmit({
        Username = props.Form.Store.Username:Get(),
        Password = props.Form.Store.Password:Get(),
    })
end
```

§3의 버튼은 `MouseButton1Click = function() submit(props) end`이 되고, 부르는
쪽은 `RegistrationForm { Form = form, OnSubmit = function(payload) … end }`으로
넘깁니다.

대신 잃는 것이 둘입니다. 관측자가 **하나**로 고정되고(둘이 보려면 부르는 쪽이
직접 갈라야 합니다), 콜백을 언제까지 부르는지가 계약에 안 남습니다 — 화면이
죽은 뒤의 호출을 막는 것은 `Observer`처럼 quad가 해 주는 일이 아니라 부르는 쪽
몫이 됩니다.

</details>

---

## 6. 핵심 모범 사례

1. **폼 상태는 밖에서 만들어 props로 주입하기.** 이유가 셋입니다 — 같은 폼을 두
   번 띄워도 서로 독립이고, 상위가 결과를 소비할 수 있고, UI를 켜지 않고 상태만
   `require`해서 검증할 수 있습니다([06. 헤드리스 테스트](./06-headless-testing.md)).
   전역 싱글톤은 첫째를, 컴포넌트 안에서 만드는 것은 나머지 둘을 막습니다.
2. **폼 상태와 표현을 가르기.** 판정(`CanSubmit`)은 폼 상태의 것이고, 그걸 무슨
   색으로 보일지(`submitColor`)는 컴포넌트의 것입니다. 이 선이 지켜져야 같은 폼
   상태에 다른 화면을 붙일 수 있습니다.
3. **결과는 상태로 내보내기.** 컴포넌트는 `Submitted:Set`까지만 하고, 그것을
   서버로 보낼지 화면을 넘길지는 바깥이 정합니다.
4. **`OnChange` 콜백에서는 `Source:Set`만.** 콜백 안에서 다른 인스턴스의
   프로퍼티를 직접 건드리지 마세요 — 상태만 바꾸면 나머지는 디스패치가
   합니다.
5. **여러 필드를 묶을 땐 후행 의존성.** `stateA:Compute(fn, stateB)` 한 줄이면
   중간 노드 없이 하나로 모입니다.
6. **`:Compute` 콜백은 순수하게.** 계산 중에 다른 상태를 `:Set`하지 마세요.

---

## 이해 점검

```quiz
# `:Compute` 콜백의 인자 자리

`state:Compute(function(...) end, ...deps)`에서 콜백이 받는 인자의 순서는 어떻게 되나요?

- [x] 첫째는 `state` 자신(핸들), 둘째는 직전 계산 결과, 셋째부터가 뒤에 넘긴 의존성들입니다
- [ ] 첫째가 직전 계산 결과이고 둘째부터 뒤에 넘긴 의존성들입니다
- [ ] `:With`로 모은 값도 둘째 자리부터 포지셔널로 이어서 들어옵니다

첫 인자와 의존성은 값이 아니라 핸들이라 `:Get()`으로 읽고, 둘째 자리는 첫 사이클에 `nil`인 `previous`입니다. `:With`로 모은 값은 포지셔널로 넘어오지 않으므로 클로저로 직접 읽어야 합니다.
```

```quiz
# 폼 상태를 어디서 만드나

폼 상태를 컴포넌트 안이 아니라 밖에서 만들어 props로 주입하는 이유는 무엇인가요?

- [x] 같은 폼을 두 번 띄워도 서로 독립이고, 상위가 결과를 소비할 수 있고, UI 없이 상태만 검증할 수 있기 때문입니다
- [ ] 전역 싱글톤 하나로 두면 세 이점이 모두 살아나므로 그 모양을 권하기 때문입니다
- [ ] 컴포넌트 안에서 만들면 같은 폼을 두 번 띄우는 것만 막히기 때문입니다

전역 싱글톤은 첫째(같은 폼 두 벌)를 막고, 컴포넌트 안에서 만드는 것은 나머지 둘(결과 소비·헤드리스 검증)을 막습니다. `makeFormState()`를 부르는 쪽마다 한 벌씩 만들면 셋이 다 풀립니다.
```

```quiz
# 제출 결과를 관측할 때

`Submitted`를 `:Observer`로 관측할 때 첫 발화에서 주의할 점은 무엇인가요?

- [x] `Observer`는 만들어질 때 한 번 불리므로 그 시점의 값은 아직 `nil`입니다 — `nil`을 걸러내야 합니다
- [ ] 콜백에 제출 payload가 인자로 실려 오므로 그 인자를 바로 쓰면 됩니다
- [ ] 숫자 키 자리에 놓기 전에는 한 번도 불리지 않으므로 첫 발화를 걱정할 필요가 없습니다

`Observer`는 값을 실어 주지 않아 콜백 안에서 `:Get()`으로 읽고, 숫자 키 자리에 놓기 전에 이미 1회 불립니다. 제출 버튼을 누르면 그때 2회째가 오고 그 시점의 값에 payload가 들어 있습니다.
```
