---
title: "02. 폼 유효성 검사와 제출 버튼 제어"
description: "Store와 Compute로 폼 입력 유효성 검사와 제출 버튼 활성화를 선언적으로 구현하는 법을 다룹니다"
---
# [실전 레시피] 02. 폼 유효성 검사와 제출 버튼 제어

> **난이도**: 초중급
> **다루는 개념**: `Store`, `Source`, `:Compute`, `:With`, `OnChange`

---

## 1. 해결하려는 문제

로그인·회원가입 폼에서 반복되는 요구사항 셋입니다.

1. 입력이 바뀔 때마다 실시간으로 유효성을 검사한다.
2. 유효하지 않으면 에러 라벨을 보인다.
3. 모든 필드가 유효할 때만 제출 버튼을 활성화하고 색을 바꾼다.

`Store`에 원본 입력값을 모으고 `:Compute`로 판정을 파생시키면, 이 셋이 전부
선언으로 끝납니다.

```luau
-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 참고)
local Quad = require(<quad-base 모듈 경로>)
local QuadRoblox = require(<quad-roblox 모듈 경로>).QuadRoblox
local QuadTypes = require(<quad-types 모듈 경로>)
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
local D = q.D
```

---

## 2. 상태 모델링

`q.Store`는 **이름 붙은 `Source`들을 담는 테이블**입니다. 생성자에 넘기는 값은
전부 `Source`여야 하고(아니면 그 자리에서 거부합니다), 꺼낼 때는
`store.Username`처럼 필드로 읽으면 그 `Source` 자체가 나옵니다.

**`Store`는 컴포넌트 안에서 만듭니다.** 전역에 싱글톤으로 두면 그 폼을 두 번
띄울 수 없습니다.

```luau
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

    return store, isUsernameValid, isPasswordValid, canSubmit
end
```

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

## 3. UI 조립

```luau
local function RegistrationForm()
    local store, isUsernameValid, _isPasswordValid, canSubmit = makeFormState()

    -- 파생 상태는 props 테이블 밖에서 만들어 둔다(아래 주의 참고)
    local showUsernameError: QuadTypes.State<boolean> = isUsernameValid:Compute(function(valid)
        return not valid:Get()
    end)
    local submitColor: QuadTypes.State<Color3> = canSubmit:Compute(function(enabled)
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

        -- 제출 버튼
        D.TextButton {
            Text = "가입하기",
            AutoButtonColor = canSubmit,
            BackgroundColor3 = submitColor,
            MouseButton1Click = function()
                if canSubmit:Get() then
                    print("회원가입 요청:", store.Username:Get())
                end
            end,
        },
    }
end

return RegistrationForm
```

> `Text = store.Username`으로 값을 내려보내면서 같은 `Text`의 `OnChange`로 되쓰는 모양이 순환처럼 보이지만, 되먹임은 생기지 않습니다 — 되쓴 값은 입력창이 이미 가진 값이고, Roblox는 같은 값을 다시 대입해도 변경 이벤트를 발화하지 않습니다(엔진 동작). quad 쪽은 같은 값에도 emit을 하므로, 이 안전성은 프로퍼티 자리에서만 성립합니다.

`q.OnChange(name, fn)`는 **숫자 키 자리에 놓는 디스크립터**입니다(문자 키가
아닙니다). 콜백은 엔진이 주는 인자만 받습니다 — `self`는 넘어오지 않습니다.
이벤트 핸들러(`MouseButton1Click` 등)는 반대로 문자 키에 놓습니다.

> ⚠️ **`:Compute`를 props 테이블 안에 인라인으로 쓰면 에디터 타입 검사가
> 깨집니다.** 함수 인자로 넘기는 테이블 리터럴 안에서는 무주석 콜백의
> 파라미터가 풀리지 않습니다(런타임은 정상이지만 편집기에 빨간 줄이
> 그어집니다). 위처럼 **별도 문장으로 빼서 타입을 붙인 지역 변수**에 담거나,
> 콜백 파라미터에 `QuadTypes.StateData<T>` 주석을 다세요. 숫자 키 자리에 놓는
> 값은 이 문제를 겪지 않습니다.

---

## 4. 핵심 모범 사례

1. **`Store`는 컴포넌트 안에서 만들거나 props로 주입받기.** 전역 싱글톤은
   컴포넌트를 한 번밖에 못 쓰게 만듭니다.
2. **`OnChange` 콜백에서는 `Source:Set`만.** 콜백 안에서 다른 인스턴스의
   프로퍼티를 직접 건드리지 마세요 — 상태만 바꾸면 나머지는 디스패치가
   합니다.
3. **여러 필드를 묶을 땐 후행 의존성.** `stateA:Compute(fn, stateB)` 한 줄이면
   중간 노드 없이 하나로 모입니다.
4. **`:Compute` 콜백은 순수하게.** 계산 중에 다른 상태를 `:Set`하지 마세요.
