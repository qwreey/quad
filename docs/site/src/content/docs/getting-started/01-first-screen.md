---
title: "01. 첫 화면 — Frame 하나 그리기"
description: "D.Frame 하나를 만들어 PlayerGui에 붙이고, props 테이블의 해시 부분과 배열 부분이 각각 무엇인지 확인합니다"
---
> **대상 독자**: Quad를 설치했고 아직 한 줄도 안 써 본 개발자
> **목표**: 화면에 사각형 하나를 띄우고, 그게 어떻게 만들어졌는지 눈으로 확인하기

이 장부터 06장까지는 **하나의 예제**를 조금씩 키웁니다. 마지막에는 클릭할 때마다 숫자와 색이 바뀌는 카운터가 되고, 각 장은 그 직전 장의 코드에 몇 줄을 더하는 식으로 진행합니다.

---

## 준비 코드

`LocalScript`(예: `StarterPlayerScripts`) 하나를 만들고 이 넉 줄로 시작합니다.

```luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 2절의 Rojo 매핑에 맞출 것)
local Quad = require(ReplicatedStorage.roblox_packages.quad_base)
local QuadRoblox = require(ReplicatedStorage.roblox_packages.quad_roblox).QuadRoblox
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
local D = q.D
```

**두 `require` 경로는 그대로 복사해도 되는 자리가 아닙니다.** 위 경로는 [00. 설치](/getting-started/00-installation/) §2의 Rojo 매핑을 그대로 쓴 것이니, 프로젝트 구성이 다르면 00 §2에 맞춰 조정하세요. 백엔드를 설치하기 전에는 `q.D`가 `nil`입니다. 실제 프로젝트에서 이 넉 줄을 어디에 두는지는 [06. 정리](/getting-started/06-mental-models/#4-프로젝트에서-q를-어디에-두나--설정-모듈-하나)에서 다룹니다.

---

## 이번에 쓰는 코드

```luau
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local screen = D.ScreenGui { ResetOnSpawn = false }
screen.Parent = playerGui

local card = D.Frame {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(240, 160),
    BackgroundColor3 = Color3.fromRGB(35, 35, 42),
}
card.Parent = screen

print(card.ClassName) --> "Frame"
```

**실행하면** 화면 한가운데에 어두운 사각형이 하나 뜨고, 출력 창에 `Frame`이 찍힙니다.

---

## 방금 무슨 일이 일어났나

**`D.Frame { ... }`을 부른 그 순간 실제 Roblox Instance가 만들어져 돌아왔습니다.** 그래서 `card.ClassName`이 바로 찍힙니다 — 나중에 렌더러가 만들어 줄 "설계도"를 받은 게 아닙니다. 왜 이렇게 만들었는지는 [06. 정리](/getting-started/06-mental-models/#1-멘탈-모델-1-가상-dom은-없다-domless-immediate-creation)에서 되짚습니다.

**중괄호 안의 `이름 = 값`은 그 인스턴스의 프로퍼티입니다.** props 테이블에서 이 부분을 **해시 부분**이라고 부릅니다. 어떤 이름을 쓸 수 있는지는 quad가 정하는 게 아니라 그 클래스가 정합니다 — `Frame`의 프로퍼티 목록은 [Roblox 공식 레퍼런스](https://create.roblox.com/docs/reference/engine/classes/Frame)가 소스입니다.

**`Parent`만은 프로퍼티 자리에 넘길 수 없습니다.** `D.Frame { Parent = screen }`처럼 쓰면 어떤 핸들러도 그 키를 받지 않아 에러가 납니다. `D.…`가 돌려주는 것은 이미 실물 Instance이므로, 만들어진 뒤 밖에서 `.Parent`를 대입해 붙이세요.

---

## 자식 하나 넣어 보기

라벨을 넣습니다. **자식 전용 키는 따로 없습니다** — 이름 없이 그냥 원소로 놓으면 그게 자식입니다.

`card`의 중괄호 안, 프로퍼티들 아래에 이 블록을 더하세요.

```luau
local card = D.Frame {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(240, 160),
    BackgroundColor3 = Color3.fromRGB(35, 35, 42),
    UICorner = 12,

    -- 여기부터가 배열 부분: 키 없는 원소는 자식이 된다
    D.TextLabel {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, -32, 0, 48),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextScaled = true,
        Text = "카운트: 0",
    },
}
```

**실행하면** 사각형 가운데에 흰 글씨로 `카운트: 0`이 보이고, 모서리가 둥글어집니다.

한 테이블 안에 두 가지가 섞여 있습니다. **이름이 붙은 것(해시 부분)은 프로퍼티**, **이름 없는 원소(배열 부분)는 자식**입니다. 배열 부분에는 자식 말고도 여러 가지가 올 수 있는데, 그건 다음 장부터 하나씩 나옵니다.

같이 끼워 넣은 `UICorner = 12`는 프로퍼티가 아닙니다. `UICorner`/`UIPadding`/`UIPaddingOffset`/`UIScale` 네 키는 quad가 그 자리에 관리 자식(`UICorner` 인스턴스)을 만들어 붙여 주는 **숏핸드**입니다.

---

## 더 알고 싶다면

- [레퍼런스: `D` — Instance 생성](/reference/roblox/02-d/) — 해시 부분·배열 부분에 올 수 있는 것 전부, 숏핸드 키 넷, `D`에 별칭이 없는 클래스를 만드는 `D.New`
- [00. 설치](/getting-started/00-installation/) §4 — 타입 검사 플래그 넷(편집기와 CI에 같은 값을 넣어야 합니다)

---

## 다음 단계
- [02. 값이 흐르게 하기 — 원천에서 프로퍼티까지](/getting-started/02-flowing-values/)
