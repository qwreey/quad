---
title: "06. 정리 — 방금 겪은 것에 이름 붙이기"
description: "01~05에서 실제로 겪은 동작에 이름을 붙이고, 프로젝트에서 q를 두는 자리와 v1에서 오는 분을 위한 요약을 정리합니다"
---
> **대상 독자**: [05. 움직이게 하기](/getting-started/05-animation/)까지 따라온 개발자, 또는 다른 선언형 라이브러리(React·Roact·Fusion·Vide)에서 넘어온 개발자
> **목표**: 앞의 다섯 장에서 이미 겪은 것들에 이름을 붙여, 다음에 읽을 문서에서 그 이름을 알아보기

여기서 새로 배우는 것은 없습니다. **이미 손으로 해 본 것**에 이름을 붙일 뿐입니다.

---

## 1. 멘탈 모델 1: 가상 DOM은 없다 (DOMless Immediate Creation)

> **어디서 겪었나** — [01. 첫 화면](/getting-started/01-first-screen/)에서 `print(card.ClassName)`이 바로 `Frame`을 찍었을 때.

React나 Roact를 사용해 본 개발자라면 "컴포넌트가 가상 트리를 반환하고, 렌더러가 이전 트리와 비교(Diffing)하여 실제 인스턴스에 반영한다"는 개념에 익숙할 것입니다.

**Quad에는 가상 DOM이 존재하지 않습니다.** `D.Frame { ... }`을 호출하는 그 순간 실제 Roblox Instance가 만들어지고, 곧바로 반환됩니다. `D.Frame { ... }`는 다른 선언형 라이브러리에서 `scope:New "Frame" { ... }`(Fusion)이나 `create "Frame" { ... }`(Vide)라고 쓰던 자리입니다.

- **중간 트리가 없다**: 넘긴 테이블은 그 자리에서 해석되어 인스턴스에 반영되고 끝납니다. 이전 트리와 새 트리를 비교하는 단계 자체가 없습니다.
- **예측 가능한 생명주기**: 컴포넌트 함수가 반환되는 시점에 물리 인스턴스가 이미 존재하므로, 반환값을 그대로 쓰거나 `Ref`/`PreRef`로 잡아둘 수 있습니다.
- **부모는 밖에서 정한다**: `Parent`는 프로퍼티로 넘길 수 없습니다(거부됩니다). 만들어진 인스턴스에 `.Parent = ...`를 대입하세요.

`D`에는 UI에 쓰이는 클래스가 미리 생성돼 있습니다. 거기 없는 클래스는 `D.New<<Folder>>("Folder")({ Name = "Holder" })`처럼 **타입 인자를 준 `D.New`**로 만듭니다(먼저 클래스 이름을 받아 props를 받는 커링 형태이고, `--!strict`에서 결과를 쓰려면 타입 인자가 필요합니다).

---

## 2. 멘탈 모델 2: 반응형 온톨로지 — `Source`는 값을 쓸 수 있는 `State`다

> **어디서 겪었나** — [02. 값이 흐르게 하기](/getting-started/02-flowing-values/)에서 `q.Source(0)`를 만들고 `:Compute`로 파이프를 끼웠을 때, 그리고 [03. 반응하기](/getting-started/03-reacting/)에서 `:Observer`를 배열 부분에 놓았을 때.

Quad의 반응성에는 두 이름만 있으면 됩니다. 그리고 이 둘은 서로 다른 종류가 아니라 **한쪽이 다른 쪽의 확장**입니다.

```
┌──────────────────────────────────────────────┐
│  State<T> — 읽고, 파생시키고, 관측한다          │
│  :Get()  :Compute(fn, ...)  :With(...)       │
│  :Apply(factory)  :Observer(fn)  :Gate(setup)│
│                                              │
│  ┌────────────────────────────────────────┐  │
│  │  Source<T> — 위의 전부 + 값을 넣는다     │  │
│  │  :Set(v)   :Emit()   .Revision         │  │
│  └────────────────────────────────────────┘  │
└──────────────────────────────────────────────┘
```

> 다이어그램의 `:Gate(setup)`은 전파를 직접 제어하는 저수준 자리입니다. 실제로 쓰게 되는 모양은 그 위에 얹힌 `Blocker`(`state:Apply(blocker)`)이고, 그건 [03. `Slot:List`로 긴 목록 다루기](/how-to/03-virtualized-infinite-scroll/) §5에서 다룹니다.

1. **`State<T>`**: 값을 읽을 수 있는 반응형 노드입니다. `:Compute(fn, ...deps)`로 파생 State를 만들고, `:Observer(fn)`으로 변경을 관측합니다. **`State`에는 공개 생성자가 없습니다** — `q.State(...)` 같은 것은 없고, State는 `q.Source(...)`이거나 `:Compute`/`:With`/`:Apply`/`:Gate`가 만들어 준 파생 노드입니다.
2. **`Source<T>`**: `State`가 할 수 있는 일을 전부 하면서, 추가로 `:Set(v)`으로 값을 넣을 수 있는 노드입니다. 그래서 상태의 '원천'입니다.
3. **핵심 규칙**: **모든 `Source`는 그대로 `State`입니다.** `State`를 요구하는 자리(프로퍼티 바인딩, `:Compute`의 dep 등)에 `Source`를 그냥 넘기면 됩니다. 언래핑도, 프록시 변환도 없습니다.

> **`:Observer(fn)`은 등록하는 그 자리에서 한 번 발화하고, 그 뒤로는 조용합니다.** 이후 변경을 받으려면 인스턴스에 묶이거나(props의 배열 부분에 넣으면 quad가 묶어 줍니다) `:Subscribe()`를 불러야 합니다. 묶이기 전에 일어난 변경은 보류돼 있다가 묶는 순간 한 번 재생됩니다 — 실제로 확인하는 코드는 [06. 헤드리스 테스트](/how-to/06-headless-testing/) §3에 있습니다.

> `:Compute`의 콜백은 `(self, previous, ...deps)`를 받고, 넘어오는 것은 **값이 아니라 핸들**입니다. dep도 마찬가지라 `dep:Get()`으로 읽습니다. **콜백 안에서 다른 State를 읽는 것만으로는 의존성이 잡히지 않습니다** — 의존성은 `:Compute(fn, ...deps)`의 뒤 인자나 `:With(...)`로 명시해야 합니다. 이 문서의 예제는 Roblox 기본 모드(`--!nonstrict`)를 가정합니다 — `--!strict`로 쓸 때는 콜백 파라미터에 `QuadTypes.StateData<T>` 주석을 붙이세요([컴포넌트 경계 규약](/how-to/09-component-conventions/) §6 참고).

---

## 3. 멘탈 모델 3: props 테이블 — 해시 부분과 배열 부분

> **어디서 겪었나** — [01](/getting-started/01-first-screen/)에서 자식을 이름 없이 놓았을 때, [03](/getting-started/03-reacting/)에서 이벤트를 해시 키로 적고 `Observer`를 배열 부분에 놓았을 때, [04](/getting-started/04-components/)에서 `Modifier`를 배열 부분에 놓았을 때.

`D.Frame { ... }`에 넘기는 테이블은 단순한 설정 딕셔너리가 아닙니다. **해시 부분**과 **배열 부분**이 각각 다른 뜻을 갖습니다.

- **해시 부분**(`이름 = 값`)에는 **프로퍼티와 이벤트**가 옵니다. 값 자리에는 리터럴·`State`·`Tween`·`None`이 올 수 있고, 어떤 이름이 프로퍼티이고 어떤 이름이 이벤트인지는 엔진 리플렉션이 판정합니다. `UICorner`/`UIPadding`/`UIPaddingOffset`/`UIScale` 네 키만은 프로퍼티가 아니라 관리 자식을 만드는 숏핸드입니다.
- **배열 부분**(키 없는 원소)에는 **자식 인스턴스와 디스크립터**가 옵니다 — `Modifier`, `Ref`/`PreRef`/`PostRef`, `Slot`, `Observer`/`Effect`, `Tag`/`Attr`, `q.OnChange(...)`. **순서가 의미를 갖습니다.**

이 두 부분의 병합 규칙(무엇이 무엇을 덮는가), 한 번에 처리된다는 것, 그리고 정리(teardown)까지는 [09. 컴포넌트 경계 규약과 스타일 합성](/how-to/09-component-conventions/) §1이 다룹니다. 미리 하나만 짚자면, **정리해야 할 것들을 담아 들고 다니는 스코프 객체가 quad에는 없습니다**(Fusion의 `Scope`, Vide의 소유 스코프 자리에 해당하는 것이 없습니다) — 인스턴스를 `Destroy()`하면 거기 묶인 구독과 트윈이 함께 끝납니다.

---

## 4. 프로젝트에서 `q`를 어디에 두나 — 설정 모듈 하나

[01장](/getting-started/01-first-screen/)의 준비 코드 넉 줄을 화면마다 되풀이하지 않습니다. 보통은 **ModuleScript 하나**를 프로젝트의 quad 설정 모듈로 두고, 거기서 패키지를 require해 프로바이더(그리고 있다면 프로젝트 공통 플러그인)를 설치한 `q`를 돌려줍니다. 나머지 코드는 전부 그 모듈을 require합니다 — 보일러플레이트가 한 곳으로 모이고, 백엔드·플러그인 구성이 프로젝트에 딱 한 자리에만 적힙니다.

```luau
-- ReplicatedStorage/Client/UI/Quad.luau — 프로젝트의 quad 설정 모듈
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Quad = require(ReplicatedStorage.roblox_packages.quad_base)
local QuadRoblox = require(ReplicatedStorage.roblox_packages.quad_roblox).QuadRoblox

-- 프로바이더 설치. 공통 플러그인이 있으면 같은 줄에 이어 붙인다:
--   Quad:UseProvider(QuadRoblox):AddPlugin(MyThemePlugin)
return Quad:UseProvider(QuadRoblox)
```

```luau
-- 화면·컴포넌트 모듈 — 설정 모듈만 require한다
local q = require(ReplicatedStorage.Client.UI.Quad)
local D = q.D
```

반환 타입은 `UseProvider`/`AddPlugin`이 돌려주는 `Self & P`라, 설정 모듈을 require한 쪽에서도 `q.D`·`q.Tween`이 그대로 타입으로 보입니다.

`require(quad-base)`가 돌려주는 값은 이미 만들어진 기본 모듈 인스턴스이고, Roblox의 `require` 캐시 덕에 **어느 ModuleScript에서 require해도 같은 하나(싱글턴)**입니다. `UseProvider`는 그 싱글턴에 백엔드를 설치하는 것이라, **여러 모듈이 각자 `Quad:UseProvider(QuadRoblox)`를 불러도 됩니다** — 같은 프로바이더면 두 번째부터는 아무 일도 하지 않고(멱등), 다른 프로바이더를 넘길 때만 에러입니다.

이 설정 모듈이 **싱글턴을 그대로 쓴다**는 점이 중요합니다. 같은 게임에 quad를 쓰는 다른 코드(다른 라이브러리, 다른 팀의 화면)가 자기 자리에서 또 `Quad:UseProvider(QuadRoblox)`를 불러도 같은 프로바이더라 아무 일도 안 일어나고, 그쪽이 만든 `State`와 여기서 만든 `State`는 같은 모듈의 것이라 섞어 쓸 수 있습니다.

`Quad.New()`가 끼어드는 자리가 바로 이 설정 모듈입니다. 싱글턴과 **분리된** 인스턴스가 필요하면(같은 게임 안의 다른 quad 소비자와 프로바이더·플러그인 구성을 공유하고 싶지 않을 때, 헤드리스 테스트에서 mock 프로바이더를 붙일 때) 설정 모듈의 그 줄만 `Quad.New():UseProvider(...)`로 바꾸면 되고, 나머지 코드는 그대로입니다. 새 인스턴스에는 프로바이더가 들어 있지 않으니 설치는 여기서 해야 합니다 — 세부는 [레퍼런스: Quad 모듈](/reference/core/01-quad-module/).

---

<details>
<summary><strong>v1에서 오신 분께</strong> — quad v1(<code>Quad.Init(id)</code> / <code>Class "Frame"</code>)을 쓰셨다면 펼쳐 보세요</summary>

v1을 쓰던 분이 가장 자주 넘어지는 자리들입니다. 큰 그림(무엇이 왜 없어졌고 어떤 틀로 옮기는지)은 [quad v1에서 오는 분께](/overview/02-from-v1/), 전체 이관 절차는 [08. quad v1에서 v2로 옮기기](/how-to/08-migrating-from-v1/)에 있습니다.

- **`:With`는 이름만 같은 다른 것**입니다 — v1의 파생은 v2에서 `:Compute(fn, ...deps)`입니다.
- **`Mount(parent, obj)`는 없습니다** — 만들어진 뒤 `obj.Parent = parent`.
- **이벤트는 해시 키에, `self`는 오지 않습니다** — `[Event "Activated"] = fn(self, …)` → `Activated = fn(…)`.
- **`Class.Extend()`는 없습니다** — 컴포넌트는 props를 받아 인스턴스를 돌려주는 평범한 함수입니다.
- **`myStore "key"`는 `store.key`**입니다 — 문자열 레지스터가 아니라 그 자리에 넣은 `Source` 그 자체입니다.
- **id로 찾아오는 창구가 없습니다** — `Frame "id" {}` / `Store.GetObject(id)`는 폐지됐고, `Ref`는 그 대체재가 아닙니다.
- **`Style`은 `Modifier`이고 배열 부분에 놓입니다** — 이름 매칭이 아니라 **놓인 순서**가 우선순위입니다.

</details>

---

## 다음 단계
- [09. 컴포넌트 경계 규약과 스타일 합성](/how-to/09-component-conventions/) — 재사용 가능한 컴포넌트를 만들 때 지켜야 하는 것들
- [실전 레시피 전체](/how-to/01-debugging-and-troubleshooting/) — 에러 읽는 법, 폼 검증, 긴 목록, 외부 신호, 테마, 헤드리스 테스트
- [The Quadnomicon](/quadnomicon/01-revision-and-epochmap/) — 위의 동작들이 내부에서 어떻게 구현돼 있는지
