---
title: "10분 완성: 첫 인터랙티브 카운터 컴포넌트"
description: "10분 안에 클릭할 때마다 값과 색이 바뀌는 반응형 카운터 컴포넌트를 만들어 봅니다"
---
> **소요 시간**: 10분  
> **준비물**: Roblox Studio 또는 Rojo 환경  
> **결과물**: 클릭할 때마다 숫자와 색이 바뀌는 반응형 카운터 UI

이 문서의 §1 → §2 → §3은 위에서 아래로 이어 붙이면 그대로 돌아가는 **하나의 프로그램**입니다. §4는 거기에 애니메이션을 얹는 변경입니다.

---

## 1. Quad 불러오기

`require(quad-base)`가 돌려주는 값이 이미 기본 모듈 인스턴스입니다. 여기에 Roblox 백엔드를 설치하면 `D`/`Tween`/`Animate`/`OnChange`가 생깁니다 — **백엔드를 설치하기 전에는 `q.D`가 `nil`입니다.**

```luau
-- ScreenGui가 위치할 LocalScript (예: StarterPlayerScripts)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 2절의 Rojo 매핑에 맞출 것)
local Quad = require(ReplicatedStorage.roblox_packages.quad_base)
local QuadRoblox = require(ReplicatedStorage.roblox_packages.quad_roblox).QuadRoblox
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
local D = q.D
```

**두 `require` 경로는 그대로 복사해도 되는 자리가 아닙니다.** 위 경로는 [00. 설치](/ko/getting-started/00-installation/) §2의 Rojo 매핑을 그대로 쓴 것이니, 프로젝트 구성이 다르면 00 §2에 맞춰 조정하세요. 나머지 줄은 그대로 이어 붙이면 됩니다.

---

## 2. 카운터 컴포넌트 작성

Quad의 컴포넌트는 특별한 타입이 아니라 **평범한 Luau 함수**입니다. 상태를 안에서 만들고, 만들어진 인스턴스를 반환합니다. (이 문서의 예제는 Roblox 기본 모드 `--!nonstrict`를 가정합니다 — `--!strict`에서는 프로퍼티 자리의 인라인 `:Compute` 콜백 파라미터에 `QuadTypes.StateData<T>` 주석이 필요합니다.)

```luau
local function CounterApp()
    -- [1] 원본 상태(Source) 생성: 초기값 0
    local count = q.Source(0)

    -- [2] 파생 상태(:Compute): 홀수/짝수 판별 텍스트
    --     콜백에 넘어오는 것은 값이 아니라 핸들이라 :Get()으로 읽는다
    local parityText = count:Compute(function(c)
        return if c:Get() % 2 == 0 then "짝수입니다" else "홀수입니다"
    end)

    -- [3] 선언적 UI 반환
    return D.ScreenGui {
        ResetOnSpawn = false,

        -- 중앙 카드 프레임
        D.Frame {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(240, 180),
            BackgroundColor3 = Color3.fromRGB(35, 35, 42),

            -- 둥근 모서리 (UICorner 숏핸드 — 숫자는 offset, UDim도 그대로 받는다)
            UICorner = 12,

            -- 숫자 표시 라벨
            D.TextLabel {
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, 24),
                Size = UDim2.new(1, -32, 0, 48),
                BackgroundTransparency = 1,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                -- 숫자가 바뀔 때마다 텍스트가 자동 갱신됨
                Text = count:Compute(function(c)
                    return `카운트: {c:Get()}`
                end),
            },

            -- 상태 설명 라벨
            D.TextLabel {
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, 76),
                Size = UDim2.new(1, -32, 0, 20),
                BackgroundTransparency = 1,
                TextColor3 = Color3.fromRGB(160, 160, 175),
                TextSize = 14,
                Text = parityText,
            },

            -- 증가 버튼
            D.TextButton {
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, 0, 1, -20),
                Size = UDim2.new(1, -40, 0, 42),
                BackgroundColor3 = Color3.fromRGB(0, 162, 255),
                TextColor3 = Color3.fromRGB(255, 255, 255),
                Text = "+ 1 증가",
                TextSize = 16,
                UICorner = 8,

                -- 이벤트 핸들러는 엔진이 주는 인자만 받는다(self는 안 온다)
                MouseButton1Click = function()
                    count:Set(count:Get() + 1)
                end,
            },
        },
    }
end
```

---

## 3. 화면(PlayerGui)에 마운트하기

`Parent`는 프로퍼티 자리에 넘길 수 없습니다 — 넘기면 디스패치가 거부합니다. 컴포넌트가 반환한 것은 이미 실물 `ScreenGui`이므로, **만들어진 뒤 밖에서** `.Parent`를 대입해 붙입니다.

```luau
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- 컴포넌트 생성 및 마운트
local appGui = CounterApp()
appGui.Parent = playerGui
```

여기까지가 완결된 프로그램입니다. 버튼을 누르면 두 라벨이 함께 갱신됩니다.

---

## 4. 애니메이션 추가하기: `Animate`와 `Tween`

색이 툭 튀지 않고 부드럽게 넘어가게 해봅시다. `TweenService:Create`를 직접 부를 필요는 없습니다.

### 방법 A: `:Apply(q.Animate { ... })`

`Animate`는 State에 `:Apply`로 얹는 팩토리입니다. 원래 State의 값이 바뀔 때마다, 그 값을 `Tween` 값 래퍼로 감싼 새 State를 만들어 줍니다.

**어디에 넣나** — §2의 코드를 두 군데만 고칩니다.

**하나.** `CounterApp` 안, `parityText` 바로 아래에 목표 색 State를 하나 더 만듭니다.

```luau
-- 짝수일 때 하늘색, 홀수일 때 흰색
local numberColor = count:Compute(function(c)
    return if c:Get() % 2 == 0
        then Color3.fromRGB(0, 200, 255)
        else Color3.fromRGB(255, 255, 255)
end)
```

**둘.** §2의 숫자 표시 라벨에서 `TextColor3 = Color3.fromRGB(255, 255, 255),` 한 줄을 `TextColor3 = numberColor:Apply(q.Animate { Time = 0.3, Style = Enum.EasingStyle.Quad }),`로 바꿉니다. 나머지는 그대로 둡니다.

`Animate`의 옵션(`Time`/`Style`/`Direction`/`Override`/`CanAnimate` …)은 리터럴이어도 State여도 됩니다. State를 넣으면 **그 옵션이 바뀐 것만으로는 재계산되지 않고**, 다음번 값 변경 때 최신 옵션이 반영됩니다. `CanAnimate`를 생략하면 항상 애니메이션하고, `false`면 보간 없이 값이 그대로 나갑니다(모션 줄이기 설정을 꽂는 자리).

### 방법 B: `q.Tween { ... }` 값 래퍼

`Animate`가 만들어 주는 것이 바로 이 `Tween` 값입니다. **`Tween`은 상태 노드가 아니라 값 래퍼입니다** — 반응 그래프 안에 사는 애니메이션 노드가 아니라, State가 내놓는 값을 감싸 "이 목표로 보간해 달라"고 프로퍼티 핸들러에 전달하는 불변 값입니다. 값마다 시간이나 스타일을 다르게 주고 싶으면 `:Compute` 안에서 직접 만들면 됩니다.

```luau
TextColor3 = count:Compute(function(c)
    local n = c:Get()
    local isMilestone = n > 0 and n % 10 == 0

    -- 프로퍼티 핸들러가 알아보는 불변 값 래퍼
    return q.Tween {
        Value = if isMilestone then Color3.fromRGB(255, 215, 0) else Color3.fromRGB(255, 255, 255),
        Time = if isMilestone then 0.6 else 0.2,
        Style = Enum.EasingStyle.Quad,
        Override = "Cancel", -- "Cancel" 또는 "Finish"; 생략하면 이 필드는 비어 있고 소비 측이 Cancel로 처리한다
    }
end),
```

알아둘 것 넷:

- **`Value`는 plain 값이어야 합니다** — State를 넣을 수 없습니다. 반응성은 `Tween`을 감싼 State가 담당합니다.
- **처음 설정될 때는 트윈이 걸리지 않고 값이 바로 찍힙니다.** 이미 값이 있는 프로퍼티가 바뀔 때부터 엔진 트윈이 만들어집니다.
- **목표 `Value`가 이전과 같으면 새 트윈을 만들지 않습니다.** 위 예제에서 1~9회 클릭은 목표가 계속 흰색이라 트윈이 0개이고, 10회째에 금색으로 바뀔 때 하나 생깁니다. 같은 값이어도 매번 다시 재생하고 싶으면 `Dedup = false`를 넣으세요.
- **목표가 다르면 진행 중이던 트윈을 정리하고 새로 겁니다.** `Override = "Cancel"`은 이전 트윈을 그 자리에서 취소하고, `"Finish"`는 이전 목표값으로 먼저 스냅한 뒤 새 트윈을 시작합니다.

---

## 5. 방금 경험한 Quad의 4가지 원리

1. **가상 DOM이 없음**: `CounterApp()`이 반환된 시점에 실제 `ScreenGui`/`Frame`/`TextButton`이 이미 존재합니다.
2. **반응형 상태 분리**: 원본은 `q.Source`, 파생은 `:Compute`로 나뉩니다. 파생 State를 프로퍼티 자리에 꽂으면 그 프로퍼티가 따라 갱신됩니다.
3. **선언적 애니메이션**: 값 자리에 `Tween` 값을 두는 것만으로 트윈이 관리됩니다 — 목표가 같으면 새로 만들지 않고, 다르면 `Override` 정책대로 이전 트윈을 정리한 뒤 새로 겁니다.
4. **명시적 마운트**: `Parent`는 프로퍼티가 아니라 밖에서 대입하는 것입니다. 그리고 `appGui:Destroy()`하면 거기 묶인 구독과 트윈은 더 이상 실행되지 않고, 메모리 회수는 Luau GC에 맡겨집니다.

---

## 다음 단계
- [컴포넌트 합성: 순수 함수와 경계 규약](/ko/getting-started/03-component-composition/)
