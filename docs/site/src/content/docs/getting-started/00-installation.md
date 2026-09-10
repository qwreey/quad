---
title: "00. 설치"
description: "pesde와 Rojo로 Quad를 프로젝트에 깔고, 타입 검사 플래그 넷을 편집기와 CI에 넣습니다"
---
> **대상 독자**: Roblox Studio 또는 Luau CLI 툴체인(Rojo, pesde 등) 환경에서 Quad를 프로젝트에 붙이려는 개발자
> **목표**: 패키지를 내려받아 게임 트리에 올리고, 타입 검사 플래그를 켜기

이 장은 **까는 것만** 다룹니다. 실제로 화면에 무언가를 띄우는 건 다음 장인
[01. 프레임워크 설정하기](/getting-started/01-setup/)입니다.

---

## 1. 배포 방식 한눈에 보기

Quad는 아래 세 가지 경로로 배포합니다. **[2026-09-10 기준] 제공되는 건 pesde 경로 하나입니다**(`3.0.0`이 pesde 레지스트리에 게시됨) — Wally 게시와 릴리스 페이지는 아직 없습니다.

| 배포 방식 | 추천 대상 | 필요한 도구 | 상태 |
|---|---|---|---|
| **1. pesde + Rojo** | Luau 패키지 매니저를 쓰는 프로젝트 | `pesde`, `rojo` | **제공 중** (`3.0.0`) |
| **2. Wally + Rojo** | 이미 Wally를 쓰고 있는 프로젝트 | `wally`, `rojo` | 미제공 |
| **3. Standalone `.rbxm`** | CLI 도구 없이 Studio만 쓰는 경우 | 없음 | 미제공 |

---

## 2. pesde + Rojo

[pesde](https://docs.pesde.dev/)는 의존성을 내려받아 배치하는 도구일 뿐, Studio 안의 `ModuleScript`로 싱크해 주지는 않습니다. 따라서 **Rojo가 반드시 함께 필요합니다** — pesde가 디스크에 놓은 폴더를 게임 트리로 투영하는 건 Rojo의 몫입니다.

### 1단계: 패키지 셋 추가

```toml
[dependencies]
quad_base = { name = "qwreey/quad_base", version = "^3.0.0" }
quad_roblox = { name = "qwreey/quad_roblox", version = "^3.0.0" }
quad_types = { name = "qwreey/quad_types", version = "^3.0.0" }
```

셋을 **직접** 적는 데는 각각 이유가 있습니다.

- **`quad_roblox`** — Roblox 백엔드. 여러분이 실제로 쓰는 `D`가 여기서 옵니다.
- **`quad_base`** — `quad_roblox`는 이걸 **개발 의존성**으로만 잡습니다(런타임에는 모듈 인스턴스를 인자로 받으므로 require하지 않습니다). 개발 의존성은 소비자에게 전파되지 않으니 직접 적어야 합니다.
- **`quad_types`** — 타입만 든 패키지입니다. [01장](/getting-started/01-setup/)의 설정 모듈이 이걸 require해 타입을 다시 내보내는데, **직접 의존성으로 적어야** 최상위에 링커가 생겨 그 require가 풀립니다.

`quad_error` / `type_version_check`는 위 셋의 의존성으로 따라 들어오므로 적을 필요가 없습니다. `^3.0.0`은 3.x 안에서 최신을 받겠다는 뜻입니다 — 정확한 버전으로 고정하려면 `version = "3.0.0"`처럼 쓰세요.

이름을 적을 때 주의할 것이 하나 있습니다. **저장소상 패키지 이름은 언더스코어만 씁니다** — `qwreey/quad_base`, `qwreey/quad_roblox`처럼요(폴더 이름은 `quad-base`/`quad-roblox`로 하이픈이고, 매니페스트의 `name`만 언더스코어입니다). 다섯 패키지가 같은 버전으로 게시되며 현재 버전은 `3.0.0`입니다. 저장소 루트의 `qwreey/quad`는 워크스페이스 루트일 뿐 게시 대상이 아니라(`private = true`) 이 이름으로는 설치할 수 없습니다.

### 2단계: Rojo 프로젝트 맵 연결

**pesde는 설치 디렉터리를 "의존 대상 패키지 자신의 target" 이름으로 나눕니다.** 다섯 패키지 중 `quad_roblox`만 `roblox` 타깃이고, 나머지 넷은 `luau`·`roblox` 두 타깃으로 게시됩니다. 그래서 여러분의 매니페스트 `[target] environment`가 `roblox`이면 **다섯 개가 전부 `roblox_packages/` 하나에 들어옵니다**. 이 경우 `luau_packages/`는 생기지 않습니다.
<!-- 2026-09-10: 레지스트리 게시 뒤 빈 roblox 프로젝트에 ^3.0.0을 설치해 확인 -->
`environment`가 `roblox`가 아니면(예: luau) 넷의 luau 사본이 `luau_packages/`로 들어가므로 그 디렉터리도 트리에 올려야 합니다.

pesde는 설치 디렉터리 안에 `roblox_packages/quad_base.luau`처럼 얇은 링커를 놓고 실체는 `roblox_packages/.pesde/<scope>+<name>/<version>/<name>/src`에 둡니다. 직접 적은 셋만 최상위에 링커가 생기고, 따라 들어오는 둘은 `.pesde` 아래 각 패키지의 자기 `roblox_packages/`에 링크됩니다 — 그래서 트리에 올릴 건 여전히 `roblox_packages/` 하나입니다.

> **`roblox_sync_config_generator` 스크립트** — pesde는 roblox 타깃 프로젝트의 매니페스트에 `[scripts] roblox_sync_config_generator`가 없으면 설치 때 `not having a roblox_sync_config_generator script in the manifest might cause issues with linking` 경고를 냅니다. pesde 공식 Roblox 가이드가 안내하는 scripts 패키지를 매니페스트에 넣어 두는 걸 권장합니다.
> <!-- 2026-09-10: 이 스크립트 없이 아래 매핑만으로 Studio 싱크가 실제로 되는지는 실기기에서 아직 확인하지 않음 -->


이 문서의 예제들은 아래 모양을 씁니다. 디스크의 `src/client/UI/`가 게임 트리의 `ReplicatedStorage.Client.UI`가 되고, 진입점 하나가 `StarterPlayerScripts`로 갑니다.

```
src/client/UI/Quad.luau       → ReplicatedStorage/Client/UI/Quad   (설정 모듈, 01장)
src/client/UI/Counter.luau    → ReplicatedStorage/Client/UI/Counter (컴포넌트, 10장)
src/client/Main.client.luau   → StarterPlayerScripts/Main          (진입점, 01장)
roblox_packages/              → ReplicatedStorage/roblox_packages
```

```json
{
  "name": "MyQuadApp",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "$className": "ReplicatedStorage",
      "roblox_packages": { "$path": "roblox_packages" },
      "Client": {
        "$className": "Folder",
        "UI": { "$path": "src/client/UI" }
      }
    },
    "StarterPlayer": {
      "$className": "StarterPlayer",
      "StarterPlayerScripts": {
        "$className": "StarterPlayerScripts",
        "Main": { "$path": "src/client/Main.client.luau" }
      }
    }
  }
}
```

이 매핑에서 중요한 건 이름이 아니라 **모양**입니다. Quad 소스는 `require("./roblox_packages/…")`처럼 **자기 폴더의 형제**를 상대 경로로 가리키므로, 디스크에서 형제였던 것이 Instance 공간에서도 형제여야 합니다. 그리고 패키지 디렉터리는 **통째로** 매핑하세요 — pesde가 놓는 `roblox_packages/quad_roblox.luau`는 그 아래 `.pesde/…` 실체를 가리키는 얇은 링커라, 점으로 시작하는 그 하위 트리까지 같이 올라가야 require가 풀립니다(Rojo는 `.pesde`를 정상적으로 따라갑니다).

위 경로들은 **프로젝트 구성에 따라 달라지는 자리**입니다. 실제 이름은 여러분의 `default.project.json`에 맞춰 바꾸세요.

### 3단계: 타입 검사 플래그

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

<details>
<summary><strong>Wally나 <code>.rbxm</code>으로는 못 쓰나요?</strong></summary>

**[2026-09-10 기준] 아직 그 경로가 없습니다.** Wally 레지스트리 게시도, 배포용 `.rbxm`을 올릴 릴리스 페이지도 준비되지 않았습니다 — 생기면 이 절에 패키지 이름·버전과 링크를 채워 넣습니다.

Wally로 오게 되더라도 받을 것은 **셋**입니다. [01장](/getting-started/01-setup/)의 설정 모듈이 `quad_types`를 require해 타입을 다시 내보내기 때문에, `quad_base`·`quad_roblox`만으로는 그 require가 풀리지 않습니다.

</details>

---

## 더 알고 싶다면

- [레퍼런스: 설치·확장 표면](/reference/roblox/01-install/) — `quad-roblox`가 설치하는 것 전부
- [08. quad v1에서 v2로 옮기기](/how-to/08-migrating-from-v1/) — v1 프로젝트의 툴체인을 바꿀 때
