---
title: "00. 설치"
description: "pesde와 Rojo로 Quad를 프로젝트에 깔고, 타입 검사 플래그 넷을 편집기와 CI에 넣습니다"
---
# [시작하기] 00. 설치

> **대상 독자**: Roblox Studio 또는 Luau CLI 툴체인(Rojo, pesde 등) 환경에서 Quad를 프로젝트에 붙이려는 개발자
> **목표**: 패키지를 내려받아 게임 트리에 올리고, 타입 검사 플래그를 켜기

이 장은 **까는 것만** 다룹니다. 실제로 화면에 무언가를 띄우는 건 다음 장인
[01. 프레임워크 설정하기](./01-setup.md)입니다.

---

## 1. 배포 방식 한눈에 보기

Quad는 아래 세 가지 경로로 배포합니다. **[2026-09-14 기준] 제공되는 건 pesde 경로 하나입니다**(pesde 레지스트리에 `3.2.0`이 게시됨) — Wally 게시와 릴리스 페이지는 아직 없습니다.

| 배포 방식 | 추천 대상 | 필요한 도구 | 상태 |
|---|---|---|---|
| **1. pesde + Rojo** | Luau 패키지 매니저를 쓰는 프로젝트 | `pesde`, `rojo` | **제공 중** (`3.2.0`) |
| **2. Wally + Rojo** | 이미 Wally를 쓰고 있는 프로젝트 | `wally`, `rojo` | 미제공 |
| **3. Standalone `.rbxm`** | CLI 도구 없이 Studio만 쓰는 경우 | 없음 | 미제공 |

<details>
<summary><strong>Wally나 <code>.rbxm</code>으로는 못 쓰나요?</strong></summary>

**[2026-09-11 기준] 아직 그 경로가 없습니다.** Wally 레지스트리 게시도, 배포용 `.rbxm`을 올릴 릴리스 페이지도 준비되지 않았습니다 — 생기면 이 절에 패키지 이름·버전과 링크를 채워 넣습니다.

Wally로 오게 되더라도 받을 것은 **셋**입니다. [01장](./01-setup.md)의 설정 모듈이 `quad_types`를 require해 타입을 다시 내보내기 때문에, `quad_base`·`quad_roblox`만으로는 그 require가 풀리지 않습니다.

</details>

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
- **`quad_types`** — 타입만 든 패키지입니다. [01장](./01-setup.md)의 설정 모듈이 이걸 require해 타입을 다시 내보내는데, **직접 의존성으로 적어야** 최상위에 링커가 생겨 그 require가 풀립니다.

`quad_error` / `type_version_check`는 위 셋의 의존성으로 따라 들어오므로 적을 필요가 없습니다. `^3.0.0`은 3.x 안에서 최신을 받겠다는 뜻입니다 — 정확한 버전으로 고정하려면 `version = "3.2.0"`처럼 쓰세요. 이 문서의 예제는 3.2.0 기준이라, `3.1.0` 이하로 고정하면 `q.Declaration`이 옛 이름 `q.D`로만 있고(3.0.0이면 `q.Operator.Indexed`도 `Index`) 그 예제들이 돌지 않습니다.

이름을 적을 때 주의할 것이 하나 있습니다. **저장소상 패키지 이름은 언더스코어만 씁니다** — `qwreey/quad_base`, `qwreey/quad_roblox`처럼요(폴더 이름은 `quad-base`/`quad-roblox`로 하이픈이고, 매니페스트의 `name`만 언더스코어입니다). 다섯 패키지가 같은 버전으로 게시되며 현재 버전은 `3.2.0`입니다. 저장소 루트의 `qwreey/quad`는 워크스페이스 루트일 뿐 게시 대상이 아니라(`private = true`) 이 이름으로는 설치할 수 없습니다.

### 2단계: Rojo 프로젝트 맵 연결

**pesde는 설치 디렉터리를 "의존 대상 패키지 자신의 target" 이름으로 나눕니다.** 다섯 패키지 중 `quad_roblox`만 `roblox` 타깃이고, 나머지 넷은 `luau`·`roblox` 두 타깃으로 게시됩니다. 그래서 여러분의 매니페스트 `[target] environment`가 `roblox`이면 **다섯 개가 전부 `roblox_packages/` 하나에 들어옵니다**. 이 경우 `luau_packages/`는 생기지 않습니다.
<!-- 2026-09-10: 레지스트리 게시 뒤 빈 roblox 프로젝트에 ^3.0.0을 설치해 확인 -->

<details>
<summary><strong>타깃이 <code>roblox</code>가 아니면 어떻게 되나요?</strong></summary>

`environment`가 `roblox`가 아니면(예: luau) 넷의 luau 사본이 `luau_packages/`로 들어가므로 그 디렉터리도 트리에 올려야 합니다.

</details>

pesde는 설치 디렉터리 안에 얇은 링커를 놓고 실체는 `.pesde/` 아래에 둡니다 — 직접 적은 셋만 최상위에 링커가 생기지만, 따라 들어오는 둘도 그 아래로 링크되므로 **트리에 올릴 건 `roblox_packages/` 하나**입니다(그 폴더를 통째로 매핑해야 하는 이유는 아래 매핑 지시에 있습니다).

> **`roblox_sync_config_generator` 스크립트** — pesde는 roblox 타깃 프로젝트의 매니페스트에 `[scripts] roblox_sync_config_generator`가 없으면 설치 때 `not having a roblox_sync_config_generator script in the manifest might cause issues with linking` 경고를 냅니다. pesde 공식 Roblox 가이드가 안내하는 scripts 패키지를 매니페스트에 넣어 두는 걸 권장합니다.
> <!-- 2026-09-10: 이 스크립트 없이 아래 매핑만으로 Studio 싱크가 실제로 되는지는 실기기에서 아직 확인하지 않음 -->


이 문서의 예제들은 아래 모양을 씁니다. 디스크의 `src/client/UI/`가 게임 트리의 `ReplicatedStorage.Client.UI`가 되고, 진입점 하나가 `StarterPlayerScripts`로 갑니다.

```
src/client/UI/Quad.luau       → ReplicatedStorage/Client/UI/Quad   (설정 모듈, 01장)
src/client/UI/Counter.luau    → ReplicatedStorage/Client/UI/Counter (컴포넌트, 11장)
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

Quad를 쓰는 코드는 **아래 네 Luau 플래그가 전부 켜져 있어야** 타입 검사가 돕니다.

| 플래그 | 값 | 없으면 |
|---|---|---|
| `LuauSolverV2` | `true` | quad 소스의 타입 검사가 실패합니다 — `TypeError: read keyword is illegal here` |
| `LuauTarjanChildLimit` | `160000` | `D.Frame { Name = "x" }` 한 줄만 있어도 `TypeError: Internal error: Code is too complex to typecheck!`로 죽습니다. 생성된 `D`의 프로퍼티 유니언이 크기 때문입니다 |
| `LuauSubtypingIterationLimit` | `100000` | 컴포넌트가 커질 때 같은 이유로 필요해집니다 |
| `LuauTypeInferIterationLimit` | `1000000` | 〃 |

편집기와 CI 양쪽에 같은 값을 넣으세요.

#### VS Code — Luau Language Server 확장

대부분은 VS Code에서 JohnnyMorganz의 **Luau Language Server** 확장(`johnnymorganz.luau-lsp`)을 쓸 것입니다. 확장을 설치한 뒤, 프로젝트 루트의 `.vscode/settings.json`에 아래를 넣습니다.

```json
{
  "luau-lsp.platform.type": "roblox",
  "luau-lsp.fflags.enableNewSolver": true,
  "luau-lsp.fflags.override": {
    "LuauTarjanChildLimit": "160000",
    "LuauSubtypingIterationLimit": "100000",
    "LuauTypeInferIterationLimit": "1000000"
  }
}
```
<!-- 2026-09-14: 확장 1.69.0의 editors/code/package.json·src/extension.ts로 설정 키와 적용 순서를 확인(sync → enableNewSolver → override). 같은 날 사용자 실측: code-server + 확장 1.69.0(linux-x64)에서 이 블록과 똑같은 설정으로(사용자 설정 파일에 넣음) D 선언 자동완성·새 솔버 적용·에러 없음 확인. 워크스페이스 .vscode/settings.json 경로 자체는 따로 돌려 보지 않음(같은 설정 키라 결과는 같아야 함). 음성대조: override의 한도 셋을 빼면 곧바로 타입이 error-type으로 무너지고(눈에 띄는 에러 없이 조용히), 다시 넣으면 정상 — 확장이 한도를 넓게 잡아 두지 않으며 이 셋이 있어야 동작함 -->

- **`enableNewSolver`가 첫 플래그(`LuauSolverV2`)를 켭니다.** 나머지 셋은 `override`에 넣습니다. `override`에 `"LuauSolverV2": "true"`를 같이 적어도 결과는 같습니다.
- **`override`의 값은 문자열입니다** — `"160000"`처럼 따옴표로 감싸세요. 스키마가 문자열만 받습니다.
- **사용자 설정이 아니라 워크스페이스 설정(`.vscode/settings.json`)에 두는 걸 권합니다.** 저장소에 같이 커밋하면 팀원 모두 같은 값으로 검사하고, Quad를 안 쓰는 다른 프로젝트의 검사는 바뀌지 않습니다.
- **`--definitions`에 해당하는 설정은 따로 필요 없습니다.** 확장이 Roblox 타입 정의를 알아서 내려받습니다(`luau-lsp.types.roblox`, 기본 켜짐). Rojo가 `PATH`에 있으면 `default.project.json`으로 sourcemap도 자동 생성하므로(`luau-lsp.sourcemap.autogenerate`, 기본 켜짐) 2단계에서 만든 매핑을 그대로 따라 require를 풉니다.
- **확장은 기본으로 Roblox가 공개한 Luau 플래그를 받아와 적용합니다**(`luau-lsp.fflags.sync`). `override`가 그 뒤에 적용되므로 위 값이 이깁니다.
- 설정을 바꾸면 확장이 언어 서버를 다시 띄우라는 알림을 냅니다. 알림에서 다시 띄우거나 VS Code 창을 다시 로드하세요(명령 팔레트 → `Developer: Reload Window`).

적용됐는지는 `D.Frame { Name = "x" }` 한 줄로 확인할 수 있습니다. 편집기에서는 한도 플래그가 빠져도 **눈에 띄는 에러 없이 조용히 무너지는 경우가 많습니다** — `D.`나 props 안에서 자동완성이 안 나오거나, 마우스를 올린 타입이 `*error-type*`으로 보이면 설정이 먹지 않은 것입니다. CLI에서는 같은 상황이 "too complex to typecheck" 에러로 드러납니다.

#### CI와 터미널 — `luau-lsp analyze`

CI에서는 같은 확장의 CLI인 `luau-lsp`로 검사합니다. 편집기와 달리 Roblox 타입 정의를 자동으로 받지 않으므로 `--definitions`로 직접 넘깁니다.

```bash
luau-lsp analyze \
  --flag:LuauSolverV2=true \
  --flag:LuauTarjanChildLimit=160000 \
  --flag:LuauSubtypingIterationLimit=100000 \
  --flag:LuauTypeInferIterationLimit=1000000 \
  --definitions=<Roblox 타입 정의 파일> \
  <검사할 파일들>
```

<details>
<summary><strong>Neovim 같은 다른 편집기는요?</strong></summary>

같은 `luau-lsp` 언어 서버를 쓰므로 넣을 값은 똑같습니다. 서버를 띄우는 인자에 위와 같은 `--flag:이름=값` 넷을 붙이거나, 쓰는 플러그인이 FFlag 설정을 따로 받으면 그 자리에 넣으세요.

</details>

---

## 이해 점검

```quiz
# 세 패키지를 직접 적는 이유

`quad_base`·`quad_roblox`·`quad_types` 셋을 의존성에 직접 적어야 하는 이유는 무엇인가요?

- [ ] 셋 중 하나라도 빠지면 나머지가 내려받아지지 않도록 레지스트리가 막아 두었기 때문입니다
- [x] `quad_base`는 개발 의존성이라 전파되지 않고, `quad_types`는 직접 의존성이어야 최상위에 링커가 생기기 때문입니다
- [ ] 따라 들어오는 `quad_error`·`type_version_check`까지 다섯을 전부 적어야 하기 때문입니다

`quad_roblox`는 `quad_base`를 개발 의존성으로만 잡는데 개발 의존성은 소비자에게 전파되지 않고, `quad_types`는 직접 의존성으로 적어야 최상위에 링커가 생겨 설정 모듈의 require가 풀립니다. `quad_error`와 `type_version_check`는 위 셋의 의존성으로 따라 들어오므로 적을 필요가 없습니다.
```

```quiz
# 타입 검사 플래그

`D.Frame { Name = "x" }` 한 줄만 있어도 `Internal error: Code is too complex to typecheck!`로 죽는다면 무엇이 빠진 것인가요?

- [ ] `LuauSolverV2=true` — 이 값이 없을 때 나는 에러입니다
- [x] `LuauTarjanChildLimit` — 생성된 `D`의 프로퍼티 유니언이 커서 이 한도를 올려야 합니다
- [ ] `LuauSubtypingIterationLimit` — 프로퍼티를 한 줄만 적어도 이 한도부터 걸립니다

생성된 `D`의 프로퍼티 유니언이 크기 때문에, `LuauTarjanChildLimit`을 올리지 않으면 한 줄짜리 선언에서도 이 에러가 납니다. `LuauSolverV2=true`가 빠졌을 때 나는 것은 `read keyword is illegal here`이고, 나머지 둘은 컴포넌트가 커질 때 같은 이유로 필요해집니다.
```

---

## 더 알고 싶다면

- [레퍼런스: 설치와 프로바이더](../reference/roblox/01-install.md) — `quad-roblox`가 설치하는 것 전부
- [08. quad v1에서 v2로 옮기기](../how-to/08-migrating-from-v1.md) — v1 프로젝트의 툴체인을 바꿀 때
