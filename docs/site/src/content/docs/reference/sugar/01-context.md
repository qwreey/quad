---
title: "Context"
description: "명시적 타입드 값 가방 Context와 그 키 Provider의 생성자·메소드·에러 계약"
---
**명시적** 타입드 값 가방입니다. 트리를 거슬러 올라가는 암묵적 컨텍스트가 아닙니다 — 아무것도 조회하지 않고, 컴포넌트는 이름 붙은 파라미터로 가방을 받아 자기 키만 읽습니다. 노리는 자리는 중간 계층입니다: 앱의 스토어 스키마를 모르는 셸이나 레이아웃 컴포넌트가, 스토어 타입을 하나하나 적지 않고 `Context` 하나만 아래로 넘길 수 있게 합니다.

이 페이지의 심볼: [`q.Context()`](#qcontext) · [`q.Context.Provider(name?)`](#qcontextprovidername) · [`ctx:Set(provider, value)`](#ctxsetprovider-value) · [`ctx:Get(provider)`](#ctxgetprovider) · [`ctx:Peek(provider)`](#ctxpeekprovider) · [`provider.Name`](#providername) · [술어 둘](#술어)

`quad-base`에 있으므로 백엔드와 무관하게 존재합니다.

```luau
-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 참고)
local Quad = require(<quad-base 모듈 경로>)
local QuadTypes = require(<quad-types 모듈 경로>)
local QuadRoblox = require(<quad-roblox 모듈 경로>).QuadRoblox
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
local D = q.D
```

---

## `q.Context()`

**시그니처**

```luau
Context: ContextConstructor
-- export type ContextConstructor =
--     setmetatable<{ Provider: <T>(name: string?) -> Provider<T> }, { __call: (self: any) -> Context }>
```

`q.Context`는 **호출 가능한 네임스페이스**입니다 — `q.Context()`로 부르면 가방을 만들고, `q.Context.Provider`로 키를 만듭니다.

**인자** 없음. **반환** — 빈 `Context`.

**동작** — 가방은 자기가 담은 Provider와 값을 **강하게** 붙듭니다(약한 변형은 없습니다). 열거 표면은 일부러 없습니다 — 가방은 하나의 진실이지, 서브트리마다 갈라 쓰는 물건이 아닙니다. `tostring`은 담긴 개수를 보여줍니다(`Context(2)`).

---

## `q.Context.Provider(name?)`

**시그니처**

```luau
Provider: <T>(name: string?) -> Provider<T>
-- export type Provider<T> = { read __quadProvider: true, read __quadProviderValue: T, read Name: string? }
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `name` | `string?` | 선택. 에러 메시지와 `tostring`에만 쓰인다 |

**반환** — 새 `Provider<T>`. 매번 서로 다른 frozen 테이블입니다.

**동작** — 키는 **테이블 신원**입니다. 문자열 키가 아니므로 모듈 사이에서 충돌하지 않고, 같은 `name`을 두 번 줘도 서로 다른 키입니다. 신원은 quad-base **사본마다**입니다 — 다른 사본에서 만든 Provider는 여기서 `q.isProvider`가 아닙니다(브랜드와 같은 규칙).

`name`이 문자열이 아니면 만드는 그 줄에서 던집니다.

```
Context.Provider: name must be a string (got number)
```

**타입은 만드는 자리에서 한 번 붙입니다.** `T`는 값에 없는 팬텀이라, 캐스트든 명시적 타입 인자든 한쪽으로 적어주면 그 뒤로는 `Get`이 알아서 추론됩니다. 둘 다 구 솔버(`luau-analyze`)·신 솔버(`luau-lsp --flag:LuauSolverV2=true`) 양쪽에서 통과합니다.

```luau
type Theme = { ButtonBg: Color3 }

-- (1) 캐스트
local ThemeProvider = q.Context.Provider("Theme") :: QuadTypes.Provider<Theme>
-- (2) 명시적 타입 인자
local UserProvider = q.Context.Provider<<{ Name: string }>>("User")
```

---

## `ctx:Set(provider, value)`

**시그니처**

```luau
Set: <T>(self: Context, provider: Provider<T>, value: T) -> Context
```

**인자** — `provider`(이 가방의 키), `value`(붙일 값, `nil` 불가). **반환** — **self**(체이닝).

**동작** — **부르는 그 가방을 변경합니다.** 이미 있는 키면 덮어씁니다. 불변 복제 API는 없습니다 — 부모 가방을 서브트리용으로 확장하려면 만드는 쪽이 먼저 복사해야 합니다.

`false`는 값입니다. 부재로 취급되는 것은 `nil`뿐이고, `nil`을 넣으려 하면 막힙니다.

```
Context:Set: value for Provider(Theme) must not be nil (absence is "not set")
```

키 자리에 Provider가 아닌 값이 오면 세 메소드가 모두 같은 모양으로 막습니다(`Set`/`Get`/`Peek` 자리에 따라 앞의 이름만 바뀝니다).

```
Context:Set: key must be a Provider from Context.Provider() (got string)
```

---

## `ctx:Get(provider)`

**시그니처**

```luau
Get: <T>(self: Context, provider: Provider<T>) -> T
```

**반환** — 등록된 값. 타입은 `Provider<T>`의 팬텀 `T`에서 나옵니다.

**동작** — **없으면 에러입니다.** 필요한 Provider를 안 준 것은 프로그래밍 실수라는 판단이고, blame은 `:Get`을 부른 줄로 갑니다. 있는지부터 확인하고 싶으면 `:Peek`을 쓰십시오. 메시지의 `Provider(...)` 자리는 그 Provider의 `tostring`이라 이름 없는 Provider면 `Provider`만 찍힙니다.

```
Context:Get: no value for Provider(Locale) — the creator of this Context did not :Set it (use :Peek to test)
```

---

## `ctx:Peek(provider)`

**시그니처**

```luau
Peek: <T>(self: Context, provider: Provider<T>) -> T?
```

**반환** — 값 또는 `nil`. 키 게이트만 있고 부재 에러는 없습니다 — "있는지" 묻는 자리입니다.

---

## `provider.Name`

**시그니처**

```luau
read Name: string?
```

생성 때 준 이름 그대로이고 읽기 전용입니다(Provider 테이블 자체가 frozen). 안 줬으면 `nil`이며, 에러 메시지와 `tostring`이 이걸 씁니다 — `tostring(named) == "Provider(Theme)"`, 이름이 없으면 `"Provider"`.

---

## 술어

| 호출 | 뜻 |
|---|---|
| `q.isContext(x)` | `x`가 이 quad 사본의 `Context` 가방인가 |
| `q.isProvider(x)` | `x`가 이 quad 사본의 `Provider` 키인가 |

---

## 예제 — 중간 계층이 스키마를 모른 채 넘긴다

컴포넌트는 플레인 함수이므로, 중간 계층은 그냥 파라미터를 하나 더 받는 함수입니다.

```luau
type Theme = { ButtonBg: Color3 }
local ThemeProvider = q.Context.Provider("Theme") :: QuadTypes.Provider<Theme>
local UserProvider = q.Context.Provider<<{ Name: string }>>("User")

-- 리프 컴포넌트 — 필요한 키만 꺼내 쓴다
local function ThemedButton(props: { Context: QuadTypes.Context }): TextButton
    local theme = props.Context:Get(ThemeProvider)
    return D.TextButton { BackgroundColor3 = theme.ButtonBg }
end

-- 중간 셸 — Theme/User가 뭔지 모른 채 가방만 내려보낸다
local function AppShell(props: { Context: QuadTypes.Context, Content: Instance }): Frame
    return D.Frame {
        ThemedButton({ Context = props.Context }),
        props.Content,
    }
end

local rootCtx = q.Context()
    :Set(ThemeProvider, { ButtonBg = Color3.fromRGB(40, 40, 40) })
    :Set(UserProvider, { Name = "q" })

local maybeUser: { Name: string }? = rootCtx:Peek(UserProvider) -- 없으면 nil
local shell = AppShell({ Context = rootCtx, Content = D.Frame {} })
```

---

## 관련

- [컴포넌트 합성](/getting-started/03-component-composition/) — 컴포넌트가 플레인 함수라는 것과 props 경계
- [디자인 토큰과 테마 전환](/how-to/05-theme-and-dynamic-styling/) — `Context`로 테마를 내려보내는 실전 배치
