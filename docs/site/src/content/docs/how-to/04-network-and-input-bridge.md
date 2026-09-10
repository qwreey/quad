---
title: "04. RemoteEvent와 엔진 입력을 상태로 브릿징하기"
description: "RemoteEvent와 엔진 입력 신호를 Source로 브릿징해 UI에 선언적으로 반영하는 법을 설명합니다"
---
> **난이도**: 중급
> **다루는 개념**: `Source`, `Store`, `Effect`, `OnDestroyed`, 단방향 데이터 흐름

---

## 1. 해결하려는 문제

UI는 혼자 있지 않습니다 — 서버의 `RemoteEvent`, `UserInputService`의 하드웨어
입력, `RunService`의 프레임 신호가 전부 UI에 닿습니다. 명령형으로 짜면 리스너
안에서 직접 Frame 위치를 바꾸고 Text를 대입하다가 상태 동기화가 깨집니다.

quad에서 권장하는 모양은 하나입니다 — **외부 신호는 `Source`로 밀어넣고, UI는
그 상태만 선언적으로 구독**합니다.

```luau
-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 참고)
local Quad = require(<quad-base 모듈 경로>)
local QuadRoblox = require(<quad-roblox 모듈 경로>).QuadRoblox
local QuadTypes = require(<quad-types 모듈 경로>)
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
local D = q.D
```

---

## 2. RemoteEvent 브릿징

상태 레이어와 UI 레이어를 파일로 나눕니다. 상태 레이어는 `Source:Set`만
합니다.

```luau
-- PlayerProfileState.luau (상태 레이어)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileStore = q.Store({
    Gold = q.Source(0),
    Level = q.Source(1),
})

local ProfileUpdated = ReplicatedStorage:WaitForChild("ProfileUpdated") :: RemoteEvent

ProfileUpdated.OnClientEvent:Connect(function(newData)
    if newData.Gold ~= nil then
        ProfileStore.Gold:Set(newData.Gold)
    end
    if newData.Level ~= nil then
        ProfileStore.Level:Set(newData.Level)
    end
end)

return ProfileStore
```

UI 레이어는 `RemoteEvent`의 존재를 모릅니다.

```luau
-- GoldDisplay.luau (UI 레이어)
local ProfileStore = require(script.Parent.PlayerProfileState)

local function withCommas(n: number): string
    local s = tostring(math.floor(n))
    local replaced = 1
    while replaced > 0 do
        s, replaced = string.gsub(s, "^(-?%d+)(%d%d%d)", "%1,%2")
    end
    return s
end

local function GoldDisplay()
    -- 파생 상태는 props 테이블 밖에서(함수 인자 테이블 안의 인라인 :Compute는
    -- 에디터 타입 검사에서 무주석 콜백 파라미터를 못 푼다)
    local goldText: QuadTypes.State<string> = ProfileStore.Gold:Compute(function(gold)
        return `보유 골드: {withCommas(gold:Get())} G`
    end)

    return D.TextLabel {
        Text = goldText,
        TextColor3 = Color3.fromRGB(255, 215, 0),
        FontFace = Font.fromEnum(Enum.Font.GothamBold),
    }
end
```

> **글꼴은 `FontFace`가 현행 API입니다.** **[2026-09-09]** 옛 `Font = Enum.Font.GothamBold`도
> 생성 `D`에 있어 타입 검사를 통과하지만 엔진이 `Hidden`으로 표시한 레거시입니다(필드에
> `-- @deprecated` 주석) — v1 이식 중에만 쓰세요.

> ⚠️ `:Compute` 콜백의 첫 인자는 **값이 아니라 State 핸들**입니다 —
> `gold:Get()`으로 꺼내야 하고, 꺼낸 값은 그냥 `number`입니다. 숫자에
> `:gsub` 같은 문자열 메소드를 바로 부를 수 없습니다.

---

## 3. 하드웨어 입력 브릿징

`Tab` 키로 인벤토리를 여닫는 예시입니다.

```luau
local UserInputService = game:GetService("UserInputService")

local isInventoryOpen = q.Source(false)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end
    if input.KeyCode == Enum.KeyCode.Tab then
        isInventoryOpen:Set(not isInventoryOpen:Get())
    end
end)

local function InventoryModal()
    return D.Frame {
        Size = UDim2.fromOffset(500, 400),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),

        Visible = isInventoryOpen,

        D.TextButton {
            Text = "X",
            MouseButton1Click = function()
                isInventoryOpen:Set(false)
            end,
        },
    }
end
```

---

## 4. 컴포넌트 수명에 리스너 묶기

컴포넌트가 살아 있는 동안에만 엔진 신호를 듣고 싶다면, 연결을 `q.Effect`
안에서 만들고 **cleanup 함수로 돌려주면** 됩니다. quad가 그 `Effect`를
인스턴스 수명에 묶고, 인스턴스가 파괴될 때 cleanup을 부릅니다.

```luau
local function CrosshairOverlay()
    local mousePos = q.Source(Vector2.zero)
    local dotPosition: QuadTypes.State<UDim2> = mousePos:Compute(function(pos)
        local p = pos:Get()
        return UDim2.fromOffset(p.X, p.Y)
    end)

    return D.Frame {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,

        -- 배열 부분에 둔다 — 마운트 시 연결, 파괴 시 해제
        q.Effect(function()
            local conn = UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    mousePos:Set(Vector2.new(input.Position.X, input.Position.Y))
                end
            end)
            return function()
                conn:Disconnect()
            end
        end),

        D.Frame {
            Size = UDim2.fromOffset(8, 8),
            Position = dotPosition,
            BackgroundColor3 = Color3.fromRGB(255, 0, 0),
        },
    }
end
```

`Effect`의 cleanup 반환은 선택입니다 — 정리할 게 없으면 아무것도 돌려주지
않아도 됩니다.

정리만 필요한 자리에는 생명주기 훅 슈가가 더 짧습니다.

| 훅 | 언제 | 무엇을 받나 |
|---|---|---|
| `q.OnCreated(fn)` | quad가 이 인스턴스에 무언가 하기 전 | 인스턴스 |
| `q.OnRendered(fn)` | 이 인스턴스의 처리가 끝난 뒤 | 인스턴스 |
| `q.OnDestroyed(fn)` | 인스턴스가 파괴될 때 | — |

```luau
local conn: RBXScriptConnection? -- 컴포넌트 안에서 만든 커넥션을 바깥 지역 변수로 들고 있는 경우
-- ... conn = SomeSignal:Connect(...) ...
q.OnDestroyed(function()
    if conn then conn:Disconnect() end
end)
```

인스턴스 자체를 나중에 참조해야 하면 `q.Ref(nil :: Frame?)`를 배열 부분에 두고
`ref.Value`(또는 `ref:Unwrap()`)로 읽습니다. **초기값의 타입이 곧 `Ref`의
타입**이라, `q.Ref(nil)`은 `Ref<nil>`이 되어 프로퍼티 자리에서 거부됩니다 —
요소 타입을 캐스트로 붙이세요. `Ref` 계열 값도 해시 키가 아니라 배열 부분에
놓습니다.

---

## 5. 핵심 요약

1. **단방향 주입**: 엔진 리스너 안에서 UI 인스턴스를 직접 고치지 말고 항상
   `Source:Set`으로 상태를 바꿉니다.
2. **UI와 네트워크 디커플링**: 컴포넌트는 `Store`/`State`만 소비하게 두면
   헤드리스 테스트가 쉬워집니다
   ([06. 헤드리스 테스트](/how-to/06-headless-testing/)).
3. **수명 동기화**: 컴포넌트에 매달린 외부 연결은 `Effect`의 cleanup이나
   `OnDestroyed`로 반드시 같이 정리합니다.
