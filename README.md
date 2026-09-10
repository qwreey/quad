# quad

**quad** is a DOMless UI renderer for Roblox: reactive state (`Store` / `State` / `Source`) bound straight to Instances, no virtual DOM, a pluggable dispatch engine, and an engine-agnostic core you can test without Roblox. Documentation is in Korean under [`docs/`](./docs/README.md); an English translation is planned after the Korean text has been reviewed by real users.

---

Roblox 엔진용 **DOMless UI 렌더러**입니다. 가상 DOM 없이 반응형 상태(`Store` / `State` / `Source`)를 Instance 프로퍼티에 직접 묶고, 특수 키 처리는 라이브러리 밖에서 확장할 수 있는 디스패치 엔진이 맡으며, 코어(`quad_base`)는 엔진 없이도 돕니다.

- **왜 이렇게 만들었나, 무엇을 포기했나**: [왜 Quad인가](./docs/overview/01-why-quad.md)
- **quad v1(2.x)을 쓰고 계시다면**: [quad v1에서 오는 분께](./docs/overview/02-from-v1.md) — v1은 `master` 브랜치에 그대로 있습니다.
- **처음 써보기**: [설치](./docs/getting-started/00-installation.md) → [핵심 멘탈 모델](./docs/getting-started/01-core-mental-model.md) → [10분 카운터](./docs/getting-started/02-quickstart-counter.md)
- **전체 목차**: [docs/README.md](./docs/README.md) (Overview · Getting Started · How-To · API Reference · The Quadnomicon)

## 설치

패키지 매니저는 [pesde](https://pesde.dev)입니다. 패키지 이름은 `qwreey/quad_base`(코어, luau 타깃)와 `qwreey/quad_roblox`(Roblox 백엔드, roblox 타깃) 둘이고, 나머지(`quad_types`·`quad_error`·`type_version_check`)는 의존성으로 따라 들어옵니다.

```toml
[dependencies]
quad_base = { name = "qwreey/quad_base", version = "^3.0.0" }
quad_roblox = { name = "qwreey/quad_roblox", version = "^3.0.0" }
```

> **[2026-09-10 기준]** 레지스트리 게시 전입니다 — 첫 게시 버전은 `3.0.0`이고, 2.x는 v1(`master` 브랜치)의 번호입니다. Rojo 매핑(`luau_packages`와 `roblox_packages` 둘 다)과 타입 검사 플래그 넷은 [설치 문서](./docs/getting-started/00-installation.md)를 보세요.

## 첫 줄

```luau
-- ScreenGui가 위치할 LocalScript (예: StarterPlayerScripts)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 2절의 Rojo 매핑에 맞출 것)
local Quad = require(ReplicatedStorage.luau_packages.quad_base)
local QuadRoblox = require(ReplicatedStorage.roblox_packages.quad_roblox).QuadRoblox
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
local D = q.D
```

`Quad:UseProvider(QuadRoblox)` 전에는 `D`/`Tween`/`Animate`/`OnChange`가 없습니다. 이어지는 카운터 컴포넌트는 [10분 카운터](./docs/getting-started/02-quickstart-counter.md)에 있습니다.

## 변경 이력과 버전

[`CHANGELOG.md`](./CHANGELOG.md). SemVer를 따르고, 3.x가 이 재작성(v2)의 첫 계열입니다.

## 라이선스

[MIT](./LICENSE)
