---
title: "00. 설치 및 환경 구축"
description: "Quad를 프로젝트에 설치하는 세 가지 배포 경로와 각 경로의 현재 제공 상태를 안내합니다"
---
> **대상 독자**: Roblox Studio 또는 Luau CLI 툴체인(Rojo, pesde 등) 환경에서 Quad를 프로젝트에 붙이려는 개발자
> **목표**: Quad를 프로젝트에 넣고 첫 `require`와 첫 마운트를 성공시키기

---

## 1. 배포 방식 한눈에 보기

Quad는 아래 세 가지 경로로 배포될 예정입니다. **다만 [2026-09-09 기준] 셋 중 어느 것도 아직 제공되지 않습니다** — 레지스트리에 게시된 패키지도, 릴리스 페이지도 아직 없습니다.

| 배포 방식 | 추천 대상 | 필요한 도구 | 상태 |
|---|---|---|---|
| **1. pesde + Rojo** | Luau 패키지 매니저를 쓰는 프로젝트 | `pesde`, `rojo` | 미제공 |
| **2. Wally + Rojo** | 이미 Wally를 쓰고 있는 프로젝트 | `wally`, `rojo` | 미제공 |
| **3. Standalone `.rbxm`** | CLI 도구 없이 Studio만 쓰는 경우 | 없음 | 미제공 |

아래 각 절은 "그 경로가 열렸을 때 어떤 모양이 될지"를 미리 적어둔 것입니다. 각 절 머리의 표시가 사라지면 그 경로가 실제로 열렸다는 뜻입니다.

### 공통 전제 — 패키지는 둘이다

어느 경로로 설치하든 **Quad는 패키지 두 개를 같이 씁니다**.

- **`quad-base`** — 엔진에 무관한 코어(`Source`/`State`/`Slot`/`Modifier`/디스패치). 이것만으로는 Roblox Instance를 만들 수 없습니다.
- **`quad-roblox`** — Roblox 백엔드. `D`(Instance 생성기), `Tween`, `Animate`, `OnChange`, `isTween`을 제공합니다.

둘을 붙이는 건 `UseProvider` 한 줄입니다.

```luau
local q = Quad:UseProvider(QuadRoblox)
```

`quad-base`만 require하면 `Quad.D`, `Quad.Tween`, `Quad.Animate`, `Quad.OnChange`는 전부 `nil`입니다 — 이 줄을 부르기 전까지는 백엔드가 설치되지 않은 상태입니다. 또한 `UseProvider`는 모듈 하나당 프로바이더 하나입니다 — 같은 프로바이더 함수로 다시 부르면 아무 일도 없고(멱등), 다른 프로바이더로 부르면 에러입니다.

`require`가 돌려주는 `Quad`는 이미 쓸 수 있는 기본 인스턴스입니다. `Quad.New()`는 서로 격리된 별도 인스턴스가 필요할 때만 씁니다.

저장소상 패키지 이름은 언더스코어만 씁니다 — **`qwreey/quad_base`**, **`qwreey/quad_roblox`**(폴더 이름은 `quad-base`/`quad-roblox`로 하이픈, 매니페스트의 `name`만 언더스코어입니다). 현재 버전은 둘 다 `0.0.0`. 저장소 루트의 `qwreey/quad`는 워크스페이스 루트일 뿐 게시 대상이 아니므로(`private = true`) 이 이름으로는 설치할 수 없습니다.

---

## 2. 방법 1: pesde + Rojo

> ⚠️ **[2026-09-09 기준] 이 경로는 아직 제공되지 않습니다** — 레지스트리 게시가 생기면 이 표시를 지웁니다.

[pesde](https://docs.pesde.dev/)는 의존성을 내려받아 배치하는 도구일 뿐, Studio 안의 `ModuleScript`로 싱크해 주지는 않습니다. 따라서 **Rojo가 반드시 함께 필요합니다** — pesde가 디스크에 놓은 폴더를 게임 트리로 투영하는 건 Rojo의 몫입니다.

### 1단계: 패키지 둘 추가

`quad-roblox`는 런타임에 `quad_types`와 `type_version_check`만 의존하고, `quad_base`는 **개발 의존성**으로만 잡습니다(런타임에는 모듈 인스턴스를 인자로 받으므로 require하지 않습니다). 개발 의존성은 소비자에게 전파되지 않으므로, **`quad_base`는 직접 추가해야 합니다.** 여러분의 매니페스트 `[target]`이 `roblox`이면 넷(`quad_base`·`quad_types`·`quad_error`·`type_version_check`)은 roblox 타깃으로 게시된 사본이 선택됩니다 — 넷 다 luau·roblox 두 타깃으로 게시되기 때문입니다.

```toml
[dependencies]
quad_base = { name = "qwreey/quad_base", version = "0.0.0" }
quad_roblox = { name = "qwreey/quad_roblox", version = "0.0.0" }
```

`quad_types` / `quad_error` / `type_version_check`는 위 둘의 의존성으로 따라 들어오므로 직접 적을 필요가 없습니다. 버전 `0.0.0`은 지금 저장소의 값이므로, 게시 시점 버전으로 바꿔 쓰세요.

### 2단계: Rojo 프로젝트 맵 연결

**pesde는 설치 디렉터리를 "의존 대상 패키지 자신의 target" 이름으로 나눕니다.** Quad는 여기서 두 디렉터리에 걸칩니다:

| 패키지 | 게시된 타깃 | roblox 프로젝트에서 설치되는 곳 |
|---|---|---|
| `quad_roblox` | `roblox` | `roblox_packages/` |
| `quad_base`, `quad_types`, `quad_error`, `type_version_check` | `luau`와 `roblox` 둘 다 | `roblox_packages/`(프로젝트 target이 `roblox`일 때; luau 프로젝트에선 `luau_packages/`) |

> **roblox 타깃 프로젝트라면 `roblox_packages/` 하나만 매핑하면 됩니다** — 표준 pesde-Roblox 가이드 그대로입니다. 여러분의 매니페스트 `[target] environment`가 `roblox`가 아니면(예: luau) 넷의 luau 사본이 `luau_packages/`로 들어가므로, 그때는 그 디렉터리도 트리에 올려야 합니다.

pesde는 설치 디렉터리 안에 `roblox_packages/quad_base.luau`처럼 얇은 링커를 놓고 실체는 `.pesde/…/src`에 둡니다(레포 밖 프로젝트 설치로 확인). 넷이 roblox 사본으로 한 디렉터리에 모이는 레이아웃은 **[2026-09-10 기준]** 게시 스테이징에서 확인한 것이고, 레지스트리 게시 뒤 소비자 프로젝트에서 한 번 더 확인합니다.

> **`roblox_sync_config_generator` 스크립트** — pesde는 roblox 타깃 프로젝트의 매니페스트에 `[scripts] roblox_sync_config_generator`가 없으면 설치 때 `not having a roblox_sync_config_generator script in the manifest might cause issues with linking` 경고를 냅니다. pesde 공식 Roblox 가이드가 안내하는 scripts 패키지를 매니페스트에 넣어 두세요. 이 스크립트 없이 위 매핑만으로 Studio 싱크가 실제로 되는지는 **[2026-09-10 기준]** 실기기에서 아직 확인하지 않았습니다.

```json
{
  "name": "MyQuadApp",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "$className": "ReplicatedStorage",
      "roblox_packages": { "$path": "roblox_packages" },
      "Client": { "$path": "src/client" }
    }
  }
}
```

이 매핑에서 중요한 건 이름이 아니라 **모양**입니다. Quad 소스는 `require("./roblox_packages/…")`처럼 **자기 폴더의 형제**를 상대 경로로 가리키므로, 디스크에서 형제였던 것이 Instance 공간에서도 형제여야 합니다. 저장소 자신의 `default.project.json`도 같은 규칙을 따릅니다 — 패키지마다 `Folder` 하나를 두고 그 아래에 `src`와 링크 디렉터리를 나란히 놓습니다(단, 그건 모노레포 개발용 매핑이라 소비자 트리와 모양이 다릅니다). 그리고 패키지 디렉터리는 **통째로** 매핑하세요 — pesde가 놓는 `roblox_packages/quad_roblox.luau`는 그 아래 `.pesde/…` 실체를 가리키는 얇은 링커라, 점으로 시작하는 그 하위 트리까지 같이 올라가야 require가 풀립니다(Rojo는 `.pesde`를 정상적으로 따라갑니다 — 이 저장소의 sourcemap에서 확인됨).

위 경로들은 **프로젝트 구성에 따라 달라지는 자리**입니다. 실제 이름은 여러분의 `default.project.json`에 맞춰 바꾸세요.

### 3단계: require

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 설치 경로는 프로젝트 구성에 따라 다르다(위 2단계의 Rojo 매핑과 맞출 것)
local Quad = require(ReplicatedStorage.roblox_packages.quad_base)
local QuadRoblox = require(ReplicatedStorage.roblox_packages.quad_roblox).QuadRoblox
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
local D = q.D
```

`quad-roblox` 모듈이 돌려주는 테이블에서 꺼내야 하는 건 **`QuadRoblox` 필드**입니다 — 그 자체가 `UseProvider`에 넘길 프로바이더 함수입니다.

`.luaurc`의 `aliases`는 편집기 자동완성/타입체크 전용이라 런타임 `require`에서는 동작하지 않습니다. 실제 `require`는 위처럼 Instance 경로(또는 상대 경로 문자열)로 쓰세요.

### 4단계: 타입 검사 플래그

Quad를 쓰는 코드는 **아래 네 플래그가 전부 켜져 있어야** 타입 검사가 돕니다. 편집기(luau-lsp)와 CI 양쪽에 같은 값을 넣으세요.

```bash
luau-lsp analyze \
  --flag:LuauSolverV2=true \
  --flag:LuauTarjanChildLimit=160000 \
  --flag:LuauSubtypingIterationLimit=100000 \
  --flag:LuauTypeInferIterationLimit=1000000 \
  --definitions=<Roblox 타입 정의 파일> \
  <검사할 파일들>
```

- **`LuauSolverV2=true`가 없으면** quad 소스 자체가 파싱되지 않습니다 — `TypeError: read keyword is illegal here`.
- **`LuauTarjanChildLimit`을 올리지 않으면** `D.Frame { Name = "x" }` 한 줄만 있어도 `TypeError: Internal error: Code is too complex to typecheck!`로 죽습니다. 생성된 `D`의 프로퍼티 유니언이 크기 때문입니다.
- 나머지 둘(`LuauSubtypingIterationLimit`/`LuauTypeInferIterationLimit`)은 컴포넌트가 커질 때 같은 이유로 필요해집니다.

---

## 3. 방법 2: Wally + Rojo

> ⚠️ **[2026-09-09 기준] 이 경로는 아직 제공되지 않습니다** — Wally 레지스트리 게시가 생기면 이 표시를 지웁니다.

Wally 쪽 절차 자체는 일반적인 Wally 프로젝트와 다르지 않습니다. `wally.toml`의 `[dependencies]`에 `quad-base`와 `quad-roblox`에 해당하는 항목 **둘**을 넣고, `wally install`로 받은 뒤 Rojo로 `Packages` 디렉터리를 게임 트리에 매핑하고, 두 모듈을 require해 `UseProvider`로 붙입니다.

Wally 레지스트리에서 쓸 패키지 이름과 버전은 아직 정해지지 않았습니다 — 게시 시점에 이 절에 채워 넣습니다.

---

## 4. 방법 3: Standalone `.rbxm`

> ⚠️ **[2026-09-09 기준] 이 경로는 아직 제공되지 않습니다** — 릴리스가 생기면 이 표시를 지웁니다.

CLI 도구 없이 Studio만 쓰는 경우를 위한 경로입니다. 모델 파일을 내려받아 Explorer의 `ReplicatedStorage` 안으로 드래그 앤 드롭하고, 거기 들어온 모듈 둘을 require해 `UseProvider`로 붙이는 방식이 됩니다.

배포용 `.rbxm`을 올릴 릴리스 페이지는 아직 없습니다 — 생기면 이 절에 링크와 파일 이름을 채워 넣습니다.

---

## 5. 설치 확인

설치가 끝났다면, 클라이언트 스크립트(`LocalScript`)에서 아래 최소 코드로 확인할 수 있습니다.

```luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 설치 경로는 프로젝트 구성에 따라 다르다(2절 참고)
local Quad = require(ReplicatedStorage.roblox_packages.quad_base)
local QuadRoblox = require(ReplicatedStorage.roblox_packages.quad_roblox).QuadRoblox
local q = Quad:UseProvider(QuadRoblox)
local D = q.D

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local gui = D.ScreenGui {
	ResetOnSpawn = false,

	D.Frame {
		Size = UDim2.fromOffset(200, 80),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(35, 35, 45),

		D.TextLabel {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 18,
			Text = "Quad is running",
		},
	},
}

-- 마운트는 밖에서: `Parent`는 프로퍼티 자리에 못 넘긴다
gui.Parent = playerGui
```

두 가지를 눈여겨보세요.

- **자식은 배열 부분에** 놓습니다. `D.Frame { ... }`에 넘기는 테이블에서 `Size = …` 같은 프로퍼티는 해시 키로, 자식 Instance는 키 없는 배열 원소로 들어갑니다.
- **`Parent`는 프로퍼티가 아닙니다.** `D.ScreenGui { Parent = playerGui }`처럼 쓰면 어떤 핸들러도 그 키를 받지 않아 디스패치가 에러를 냅니다. `D.…`가 돌려주는 것은 이미 실물 Instance이므로, 만들어진 뒤 밖에서 `.Parent`를 대입해 붙입니다.

화면 중앙에 어두운 사각형과 글씨가 보이면 설치가 끝난 것입니다.
다음 장인 [01. 핵심 멘탈 모델](/quad/ko/getting-started/01-core-mental-model/)로 넘어가 Quad의 반응형 설계를 배워보세요.
