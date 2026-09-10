---
title: "01. 프레임워크 설정하기"
description: "설정 모듈 하나에 q를 만들어 두고, 진입점에서 ScreenGui를 띄워 첫 글씨를 확인합니다"
---
# [시작하기] 01. 프레임워크 설정하기

> **대상 독자**: [00. 설치](./00-installation.md)를 끝낸 개발자
> **목표**: 프로젝트에 quad 설정 모듈 하나와 화면 진입점 하나를 만들고, 화면에 글씨가 뜨는 것까지 확인하기

Quad를 쓰는 프로젝트는 보통 **모듈 두 개**로 시작합니다. 하나는 quad를 조립해
`q`를 돌려주는 **설정 모듈**, 다른 하나는 그 `q`로 화면을 띄우는 **진입점**입니다.
이 장에서 그 둘을 만들고, 남은 장들은 전부 그 위에 코드를 더합니다.

---

## 1. 설정 모듈 — `ReplicatedStorage/Client/UI/Quad`

`src/client/UI/Quad.luau`를 만들고 아래를 넣습니다.

```luau
--!strict
-- 새 파일: ReplicatedStorage/Client/UI/Quad — 이 프로젝트의 quad 설정 모듈
const Quad = require("@game/ReplicatedStorage/roblox_packages/quad_base")
const QuadRoblox = require("@game/ReplicatedStorage/roblox_packages/quad_roblox").QuadRoblox
const QuadTypes = require("@game/ReplicatedStorage/roblox_packages/quad_types")

-- 자주 쓰는 타입을 여기서 다시 내보낸다 — 쓰는 쪽은 `q.State<number>`처럼 적으면 된다
export type State<T> = QuadTypes.State<T>
export type Source<T> = QuadTypes.Source<T>
export type Slot<T> = QuadTypes.Slot<T>
export type StateData<T> = QuadTypes.StateData<T>
export type Provider<T> = QuadTypes.Provider<T>
export type Context = QuadTypes.Context
export type Ref<T> = QuadTypes.Ref<T>
export type Observer = QuadTypes.Observer
export type EffectHandle = QuadTypes.EffectHandle

-- 백엔드 설치. 공통 플러그인이 있으면 같은 줄에 이어 붙인다:
--   Quad:UseProvider(QuadRoblox):AddPlugin(MyThemePlugin)
return Quad:UseProvider(QuadRoblox)
```

**설정 모듈만 `--!strict`이고, 이 문서의 나머지 화면 코드는 Roblox 기본 모드(`--!nonstrict`)를 가정합니다.** 설정 모듈은 프로젝트 전체가 쓰는 타입이 나오는 자리라 엄격하게 두는 편이 이득이고, 화면 코드까지 `--!strict`으로 올릴 때 붙여야 하는 타입 주석은 [01. 컴포넌트 경계 규약과 스타일 합성](../how-to/01-component-conventions.md) §6에 모아 두었습니다.

<details>
<summary><strong><code>const</code>와 문자열 <code>require</code> — 낯선 문법 둘</strong></summary>

**`const`**는 Luau의 **재대입할 수 없는 바인딩**입니다. `local`과 같은 자리에 쓰되 나중에 다른 값을 넣을 수 없다는 것만 다릅니다.

```luau
const D = q.D   -- 이 이름은 이제 바뀌지 않는다
local n = 0     -- 이쪽은 바뀔 수 있다
```

이 문서는 **재대입이 없는 자리에 `const`를 씁니다**. 취향이나 툴체인 사정으로 안 쓰고 싶다면 전부 `local`로 바꿔 읽으면 됩니다 — 동작은 같습니다.

**문자열 `require`**는 Luau가 모듈을 가리키는 방식입니다. 같은 폴더의 형제는 `./Counter`, 위 폴더는 `../`, 자기 패키지 루트는 `@self/`, 그리고 `@game/`은 DataModel 루트에서 시작하는 경로입니다. 위 코드가 쓴 `@game/ReplicatedStorage/roblox_packages/quad_base`가 그것입니다.

인스턴스 경로(`require(ReplicatedStorage.roblox_packages.quad_base)`)도 물론 됩니다. 다만 이 문서가 문자열 쪽을 권하는 이유는 **`WaitForChild` 체인이 타입을 죽이기** 때문입니다. `require(ReplicatedStorage:WaitForChild("roblox_packages"):WaitForChild("quad_base"))`는 반환이 `any`가 되어 자동완성도 타입 검사도 사라지는데, 인스턴스 경로를 쓰다 복제가 덜 된 자식을 만나면 결국 `WaitForChild`로 가게 됩니다. 문자열 경로는 그대로 타입이 살아 있습니다.

`.luaurc`의 `aliases`(사용자 정의 별칭)는 편집기·툴링 전용이라 **엔진 런타임에서는 동작하지 않습니다**. `./`·`../`·`@self/`·`@game/`만 씁니다.

</details>

둘을 붙이는 것이 `Quad:UseProvider(QuadRoblox)` 한 줄입니다. 이 줄을 프로젝트에 **딱 한 자리**에 두는 것이 이 모듈의 존재 이유입니다 — 화면마다 되풀이할 보일러플레이트가 없어지고, 백엔드·플러그인 구성이 한 곳에만 적힙니다.

<details>
<summary><strong>패키지가 왜 <code>Quad</code>, <code>QuadRoblox</code> 둘인가요?</strong></summary>

**`quad-base`**는 엔진을 모르는 코어입니다 — `Source`/`State`/`Slot`/`Modifier`와 디스패치 엔진이 여기 있고, 이것만으로는 Roblox `Instance`를 하나도 만들 수 없습니다. **`quad-roblox`**는 Roblox 백엔드로, `D`(Instance 생성기)·`Tween`·`Animate`·`OnChange`가 여기서 옵니다.

`UseProvider` 전까지 `Quad.D`·`Quad.Tween`·`Quad.Animate`·`Quad.OnChange`는 전부 `nil`입니다. 코어가 엔진 어휘를 모르기 때문에 같은 코어 위에 다른 백엔드(헤드리스 테스트용 mock 등)를 붙일 수 있고, 그 갈아 끼우는 자리가 바로 이 한 줄입니다.

</details>

반환 타입은 `UseProvider`가 돌려주는 `Self & P`라, 이 모듈을 require한 쪽에서도 `q.D`·`q.Tween`이 타입으로 그대로 보입니다. 다시 내보낸 타입 아홉도 마찬가지로 `q.State<number>`처럼 그대로 쓸 수 있습니다.

<details>
<summary><strong>다른 모듈에서 <code>UseProvider</code>를 또 부르면 어떻게 되나요?</strong></summary>

`require(quad-base)`가 돌려주는 값은 이미 만들어진 기본 모듈 인스턴스이고, Roblox의 `require` 캐시 덕에 **어느 ModuleScript에서 require해도 같은 하나(싱글턴)**입니다. `UseProvider`는 그 싱글턴에 백엔드를 설치하는 것이라, **여러 모듈이 각자 `Quad:UseProvider(QuadRoblox)`를 불러도 됩니다** — 같은 프로바이더면 두 번째부터는 아무 일도 하지 않고(멱등), 다른 프로바이더를 넘길 때만 에러입니다.

이 설정 모듈이 **싱글턴을 그대로 쓴다**는 점이 중요합니다. 같은 게임에 quad를 쓰는 다른 코드(다른 라이브러리, 다른 팀의 화면)가 자기 자리에서 또 `Quad:UseProvider(QuadRoblox)`를 불러도 같은 프로바이더라 아무 일도 안 일어나고, 그쪽이 만든 `State`와 여기서 만든 `State`는 같은 모듈의 것이라 섞어 쓸 수 있습니다.

`Quad.New()`가 끼어드는 자리도 이 설정 모듈입니다. 싱글턴과 **분리된** 인스턴스가 필요할 때가 있습니다 — 같은 게임 안의 다른 quad 소비자와 프로바이더·플러그인 구성을 공유하고 싶지 않을 때, 또는 헤드리스 테스트에서 mock 프로바이더를 붙일 때입니다. 그럴 땐 이 모듈의 그 줄만 `Quad.New():UseProvider(...)`로 바꾸면 되고 나머지 코드는 그대로입니다. 새 인스턴스에는 프로바이더가 들어 있지 않으니 설치는 여기서 해야 합니다 — 세부는 [레퍼런스: Quad 모듈](../reference/core/01-quad-module.md).

</details>

---

## 2. 진입점 — `StarterPlayerScripts/Main`

`src/client/Main.client.luau`를 만듭니다. 설정 모듈을 가져와 `ScreenGui`를 하나 띄우고, 잘 붙었는지 확인할 라벨을 하나 넣습니다.

```luau
-- 새 파일: StarterPlayerScripts/Main — 이 클라이언트의 화면 진입점
local Players = game:GetService("Players")

if not game:IsLoaded() then game.Loaded:Wait() end

const q = require("@game/ReplicatedStorage/Client/UI/Quad")
const D = q.D

const playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

const screen = D.ScreenGui { ResetOnSpawn = false }

const hello = D.TextLabel {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(240, 40),
    BackgroundTransparency = 1,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 18,
    Text = "Quad is running",
}
hello.Parent = screen

-- 마운트는 밖에서: `Parent`는 프로퍼티 자리에 못 넘긴다
screen.Parent = playerGui
```

<details>
<summary><strong><code>game.Loaded:Wait()</code> 줄은 왜 있나요?</strong></summary>

문자열 `require`는 대상이 아직 없으면 **기다리지 않고 즉시 실패하기** 때문입니다. 없는 대상을 가리키면 `error requiring "@game/ReplicatedStorage/LateModule": could not resolve child component "LateModule"`로 그 자리에서 끝나고, Play Solo에서는 스크립트 **첫 줄에서도** 이미 복제가 끝나 있어(`game:IsLoaded()`가 `true`) 이 줄이 없어도 성공합니다.
<!-- 2026-09-10 Studio 실측으로 확인 -->

문제는 Play Solo가 서버와 클라이언트를 한 프로세스에서 돌린다는 점입니다. 실접속 클라이언트는 코드를 네트워크로 동적으로 복제하므로 그 순서를 보장할 수 없습니다. 한 줄로 그 불확실성을 없앨 수 있으니 넣어 두는 쪽을 권합니다.
<!-- 2026-09-10: 실접속 클라이언트 시나리오는 실기기에서 확인하지 못함 -->

</details>

**실행하면** 화면 한가운데에 흰 글씨로 `Quad is running`이 뜹니다. 여기까지 왔다면 설치와 배선이 끝난 것입니다.

다음 장부터는 이 파일 안에서 계속 짭니다 — `hello` 라벨을 지우고 그 자리를 카드로 바꾸는 것이 [02장](./02-first-screen.md)입니다.

---

## 더 알고 싶다면

- [레퍼런스: Quad 모듈](../reference/core/01-quad-module.md) — `New`/`UseProvider`/`AddPlugin`/`RunInit`
- [06. 헤드리스 테스트](../how-to/06-headless-testing.md) — 설정 모듈의 그 한 줄을 mock 프로바이더로 바꾸는 자리
