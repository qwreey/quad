---
title: Modifier
description: 불변 프로퍼티 가방 — 생성·setter 체인·Peek/Apply/Overridden·클래스 태그와 다운캐스트
---

# Modifier

`Modifier`는 **불변 프로퍼티 가방**입니다. "이 프로퍼티들을 이렇게 설정한다"를 값 하나로 만들어 들고 다니다가, 인스턴스 props의 **배열 부분**에 놓으면 그 필드들이 해시 부분으로 펼쳐집니다. 테마·변형·조건부 스타일을 컴포넌트 경계 너머로 넘기는 통로입니다.

모든 연산이 **새 값을 돌려줍니다.** setter 하나를 부를 때마다 얕은 clone이 하나 생기고 원본은 그대로 남습니다(값 자체도 `table.freeze`돼 있습니다). 그래서 하나의 기본 Modifier에서 갈라져 나온 형제 가지들이 서로를 오염시킬 수 없습니다.

`q.Modifier(...)`는 **무타입** Modifier를 만듭니다. quad-roblox를 설치하면 클래스 태그가 붙은 타입드 생성자 `D.Modifier.<Class>(...)`가 같이 생기는데, 그건 `q.Modifier.TypedFactory("<Class>")`가 돌려준 생성자에 생성된 필드 setter 타입을 입힌 것입니다(자세한 것은 quad-roblox 레퍼런스).

이 페이지의 심볼: [`q.Modifier`](#qmodifier) · [`mod:<Field>`](#modfieldvalue) · [`mod:Peek`](#modpeektkey) · [`mod:Apply`](#modapplyfactory) · [`mod:Overridden`](#modoverridden) · [`mod:As(name)`](#modasname) · [`mod:As<Class>()`](#modasclass) · [`q.Modifier.Overridden`](#qmodifieroverridden) · [`q.Modifier.TypedFactory`](#qmodifiertypedfactorytname) · [`q.Modifier.DefineSubtype`](#qmodifierdefinesubtypeparent-subtype)

이 페이지의 모든 예제는 아래 프롤로그를 전제합니다.

```luau
-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 참고)
local Quad = require(<quad-base 모듈 경로>)
local QuadRoblox = require(<quad-roblox 모듈 경로>).QuadRoblox
local QuadTypes = require(<quad-types 모듈 경로>) -- 타입 주석용(`QuadTypes.StateData<T>` 등)
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
local D = q.D
```

## 공통 타입

```luau
type Modifier = {
    read __quadModifier: true, -- 무타입 Modifier의 클래스 태그. 타입드면 클래스 이름 문자열
    Peek: <T>(self: Modifier, key: string) -> FieldOut<T>?,
    Apply: <U>(self: any, factory: (any) -> U) -> U,
    Overridden: (self: Modifier, ...any) -> any,
    As: <T>(self: Modifier, name: string?) -> T,
}

-- 필드에 "저장된 그대로"의 값: 리터럴 | State 핸들 자체 | None(명시 해제)
type FieldOut<T> = T | State<T> | None
```

`Peek`/`As`는 결과 타입을 호출자가 명시하는 자리이고(`mod:Peek<<UDim2>>("Size")`), `Apply`의 `self`와 factory 인자가 `any`인 것은 children 유니언의 클래스 검사를 살리기 위한 의도된 절충입니다.

## 배열 부분에 놓는다

Modifier는 props의 **배열 부분** 항목입니다. 해시 키의 값 자리에 두면 합칠 대상이 없으므로 그 자리에서 거부됩니다.

- `Modifier: a Modifier cannot be a value of key "{tostring(k)}" — place it in the array part`

펼치기 규칙은 셋입니다.

1. **인라인 해시 키가 항상 이깁니다.** props에 직접 적은 `Size = …`는 어떤 Modifier의 `Size`보다 우선합니다(직접 적은 `None`도 마찬가지).
2. **배열 부분의 뒤쪽 Modifier가 앞쪽을 이깁니다.**
3. 소비된 배열 자리는 내부 센티널로 채워져 배열에 구멍이 생기지 않습니다.

```luau
local base = q.Modifier { BackgroundTransparency = 1 }
local accent = q.Modifier { BackgroundTransparency = 0.5 }
local box = D.Frame { base, accent, Name = "Box" } -- accent가 이겨 0.5
```

## `q.Modifier(...)`

**시그니처**

```luau
Modifier: setmetatable<{
    Overridden: (...any) -> any,
    TypedFactory: <T>(name: string) -> (...(Modifier | { [string]: any })) -> T,
    DefineSubtype: (parent: string, subtype: string) -> (),
}, { __call: (self: any, ...(Modifier | { [string]: any })) -> Modifier }>
```

즉 호출하면 생성, 필드로 접근하면 합성 도구인 **콜러블 네임스페이스**입니다.

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `...` | `Modifier` 또는 `{ [string]: any }` | Modifier이거나 평범한 필드 테이블. 뒤 인자가 필드 단위로 덮어씁니다 |

**반환** — 새 무타입 `Modifier`(태그 `true`).

**동작**

- 인자가 없으면 빈 Modifier입니다 — `q.Modifier()`와 `q.Modifier({})`는 같습니다.
- 필드 테이블은 **메타테이블 없는 평범한 테이블**이어야 합니다. `Source`/`Ref`/`Tag` 같은 quad 값을 넘기면 그 내부 필드가 합쳐지는 대신 거부됩니다.
- 초기 필드 테이블의 값으로 **함수는 못 씁니다.** setter 자리에서 함수는 변환 함수라 의미가 갈리기 때문입니다 — 변환이 필요하면 `mod:Field(fn)`을 쓰세요.
- 핸들러 계층 값(`Ref`/`Observer`/`Effect`/`Slot`/`Modifier`)은 필드가 될 수 없습니다. `State`/`Source`는 통과합니다.

**에러**

- `Modifier: argument #{i} must be a Modifier or a plain field table (got {typeof(arg)})`
- `Modifier: initial-field table keys must be non-empty field names (got {if k == "" then '""' else typeof(k)} at argument #{i})`
- `Modifier: field "{k}" collides with a reserved Modifier method`
- `Modifier: field "{k}" matches the reserved cast prefix As<Class> — casts are methods, not fields`
- `Modifier: field "{k}" in an initial-field table cannot be a function — use mod:{k}(fn) for a transform`
- `Modifier: field "{k}" cannot hold a handler-layer value (Ref/Observer/Effect/Slot/Modifier)`

**예제**

```luau
local card = q.Modifier {
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
}
local wide = q.Modifier(card, { Size = UDim2.fromScale(1, 0.4) }) -- card를 깔고 Size를 얹는다
local panel = D.Frame { wide }
```

**관련** — [테마와 동적 스타일링](../../how-to/05-theme-and-dynamic-styling.md), [컴포넌트 경계 규약](../../how-to/01-component-conventions.md)

## `mod:<Field>(value)`

예약 메소드(`Peek`/`Apply`/`Overridden`/`As`)와 캐스트 접두사(`As` + 대문자)를 뺀 **모든 문자열 키**가 setter입니다. 클래스별 코드가 따로 생성되는 게 아니라 하나의 제네릭 `__index`가 그때그때 setter를 만들어 줍니다.

**시그니처(생성된 클래스 타입에서의 모양)**

```luau
<Field>: (self: <Class>Modifier, value: Field<T>) -> <Class>Modifier
```

**동작** — 인자에 따라 넷으로 갈립니다.

| 넘긴 것 | 되는 일 |
|---|---|
| 리터럴 값 | 그 필드를 그 값으로 덮어씁니다 |
| `State`/`Source` | 필드가 그 핸들 자체를 들고 반응형으로 남습니다 |
| 함수 | **변환**입니다. 지금 값이 평범한 값이면 그 값을 인자로 지금 불러 결과를 저장하고, `State`면 `old:Compute(fn)`으로 파생 State를 만들어 반응성을 유지합니다 |
| `nil` | 그 필드가 결과에서 **사라집니다**(가방에 아예 없음) |
| `q.None` | 그 필드를 `None`으로 둡니다 — 명시적 해제이고, 유일한 "지우기" 표현입니다 |

⚠️ 변환 함수가 받는 `old`는 **두 경우가 다릅니다.** 지금 값이 평범한 값이면 그 값 자체가 오고, `State`면 `:Compute`로 넘어가므로 **핸들**이 옵니다 — 그때는 `old:Get()`으로 읽어야 합니다.

`nil`과 `q.None`의 차이가 핵심입니다. `nil`은 "이 Modifier는 이 필드에 관심 없음"(다른 Modifier나 인라인 키가 채울 수 있음)이고, `q.None`은 "이 필드를 비워라"라는 값입니다.

setter는 태그를 유지합니다 — 타입드 Modifier에 setter를 걸어도 클래스가 그대로 남습니다.

:::note
setter는 런타임에 어떤 이름으로든 생기지만, **타입은 클래스별 Modifier 타입에만 있습니다.** 무타입 `q.Modifier()`의 타입에는 예약 메소드 넷뿐이라 `--!strict`에서 `q.Modifier():Size(...)`는 없는 속성입니다. strict 코드에서는 타입드 생성자(`D.Modifier.<Class>` 또는 [`q.Modifier.TypedFactory`](#qmodifiertypedfactorytname))를 쓰거나, 필드를 생성자 테이블(`q.Modifier { Size = … }`)로 넘기세요.
:::

**에러**

- `Modifier: field "{key}" cannot hold a handler-layer value (Ref/Observer/Effect/Slot/Modifier)`
- `Modifier: setter keys must be strings (got {typeof(key)}) — put a non-string key in the props table itself (Frame { [key] = value })`

**예제**

```luau
local scale = q.Source(1)
local base = D.Modifier.Frame { BackgroundTransparency = 0.5, LayoutOrder = 1 }

local dimmed = base:BackgroundTransparency(0.9)     -- 리터럴
local live = base:LayoutOrder(scale)                -- State 핸들 그대로
local cleared = base:BackgroundTransparency(q.None) -- 명시 해제

-- 변환: 지금 값이 평범한 값이면 그 값이 온다(필드가 없으면 nil)
local bumped = base:LayoutOrder(function(old) return (old :: number) + 1 end)
-- 변환: 지금 값이 State면 :Compute로 이어지고 old는 핸들이다
local doubled = live:LayoutOrder(function(old)
    return (old :: QuadTypes.StateData<number>):Get() * 2
end)

-- base 는 여전히 0.5 — 전부 새 값이다
```

그 필드가 아직 없으면 `old`는 `nil`입니다 — 타입도 `FieldOut<T>?`로 그걸 말합니다. `--!strict`에서는 `old`가 그 필드의 값 대수 전부라 위처럼 필요한 팔로 캐스트해야 합니다.

## `mod:Peek<<T>>(key)`

**시그니처**

```luau
Peek: <T>(self: Modifier, key: string) -> FieldOut<T>?
type FieldOut<T> = T | State<T> | None
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `key` | `string` | 필드 이름(빈 문자열 불가) |

**반환** — **저장된 그대로**의 값. 필드가 없으면 `nil`.

**동작** — 절대 `:Get()`을 부르지 않습니다. `State`를 저장했으면 그 핸들이 그대로 나오고, `None`을 저장했으면 `None`이 나옵니다. setter의 변환 함수가 받는 `old`와 같은 타입입니다.

`T` 자리에는 **그 필드의 값 대수 전부**를 넣습니다. 백엔드 값 어휘가 있으면 그것까지 포함해야 합니다 — quad-roblox의 클래스 타입드 Modifier는 자기 `Peek`가 `X | Tween<X>`까지 덮도록 별칭을 씌워 두지만, 무타입 base `Modifier()`의 `Peek`는 위 정의를 그대로 쓰므로 Tween 팔이 없습니다. 그 필드가 Tween을 품을 수 있으면 `mod:Peek<<UDim2 | Tween<UDim2>>>("Size")`처럼 부르세요.

**에러**

- `Modifier:Peek: key must be a non-empty string (got {if key == "" then '""' else typeof(key)})`

**예제**

```luau
local size = q.Source(UDim2.fromOffset(100, 40))
local mod = q.Modifier { Size = size, Visible = true }

local storedSize = mod:Peek<<UDim2>>("Size")   -- Source 핸들 자체가 나온다
local visible = mod:Peek<<boolean>>("Visible") -- true
local missing = mod:Peek<<string>>("Text")     -- nil
```

## `mod:Apply(factory)`

**시그니처**

```luau
Apply: <U>(self: any, factory: (any) -> U) -> U
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `factory` | `(mod) -> U` | Modifier를 받아 무엇이든 돌려주는 함수 |

**반환** — `factory(self)`의 결과 그대로.

**동작** — **순수한 호출 슈거입니다.** 계약도, 검사도, 추가 의미도 없습니다. 재사용 가능한 스타일 조합을 함수로 떼어 두고 체인 중간에 끼워 넣을 때 씁니다.

주석이 붙은 factory는 타입이 그대로 서고, 무주석 factory는 `any`가 됩니다.

**예제**

```luau
local function rounded(mod: any)
    return mod:BorderSizePixel(0):BackgroundTransparency(0.1)
end

local styled = q.Modifier():Apply(rounded)
```

## `mod:Overridden(...)`

**시그니처**

```luau
Overridden: (self: Modifier, ...any) -> any
```

**반환** — 합쳐진 새 Modifier(태그 `true` — **무타입**).

**동작** — 필드 단위 합성이고 **뒤 인자가 이깁니다.** 콜론 형태 `a:Overridden(b)`와 네임스페이스 형태 `q.Modifier.Overridden(a, b)`는 정확히 같은 함수입니다(자세한 계약은 [`q.Modifier.Overridden`](#qmodifieroverridden)).

결과는 무타입이 됩니다 — 입력들의 태그가 서로 다를 수 있고 합성은 그중 하나를 고르지 않기 때문입니다. 클래스가 필요하면 [`mod:As<Class>()`](#modasclass)로 다시 태그하세요.

## `mod:As(name)`

**시그니처**

```luau
As: <T>(self: Modifier, name: string?) -> T
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `name` | `string?` | 태그를 바꿀 클래스 이름. 생략하면 값은 그대로 두고 타입만 캐스트 |

**반환** — `T`(호출자가 명시).

**동작** — **무검사 캐스트**입니다. quad가 모르는 곳으로 억지로 보내는 탈출구입니다.

- 인자가 없으면 값은 손대지 않고 타입만 바꿉니다 — `mod:As<<MyModifier>>()`.
- 이름을 주면 **존재 검사만** 하고 태그를 갈아 끼웁니다. 조상 관계는 보지 않습니다 — 그게 검사형 `As<Class>()`의 몫입니다.

**에러**

- `Modifier:As: name must be a class name string (got {typeof(name)})`
- `Modifier: unknown modifier class "{name}" — Modifier.TypedFactory/DefineSubtype it first`

## `mod:As<Class>()`

**시그니처**

```luau
As<Class>: (self: <Ancestor>Modifier) -> <Class>Modifier -- 클래스별로 생성되는 메소드
```

**반환** — 그 클래스로 태그된 새 Modifier.

**동작** — **검사형 다운캐스트**입니다. `As` 뒤에 대문자로 시작하는 이름을 붙인 모든 키가 여기로 갑니다(`mod:AsFrame()`, `mod:AsTextButton()`). 통과하려면 **두 조건이 모두** 맞아야 합니다.

1. 대상 클래스가 등록돼 있어야 하고,
2. 지금 Modifier의 태그가 셋 중 하나여야 합니다 — 무타입(`true`)이거나, 대상 클래스 자신이거나, **대상의 조상**(여러 부모 경로 전부를 봅니다).

`As` + 대문자 접두사는 **필드 이름으로 영원히 예약**돼 있습니다. 그래서 오타 `mod:AsTextLabl()`은 조용히 `AsTextLabl`이라는 필드를 만드는 대신 에러가 됩니다. `AspectRatio`처럼 `As` 다음이 소문자면 접두사가 아니라 평범한 setter입니다.

**에러**

- `Modifier: unknown modifier class "{target}" — Modifier.TypedFactory/DefineSubtype it first (or use :As(name) for an unchecked cast)`
- `Modifier: cannot cast a "{tag}" modifier to "{target}" — not an ancestor (use :As(name) to force)`

**예제**

```luau
local common = D.Modifier.GuiObject():Visible(true) -- GuiObject 태그
local button = common:AsTextButton()                -- 조상 → 자손: 통과
```

## `q.Modifier.Overridden(...)`

**시그니처**

```luau
Overridden: (...any) -> any
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `...` | `Modifier` | 합칠 Modifier들. 하나 이상 |

**반환** — 새 무타입 Modifier.

**동작** — 필드 단위로 합치고 **뒤 인자가 이깁니다.** [`q.Modifier(...)`](#qmodifier)의 병합 정책과 같지만, 이쪽은 **Modifier만** 받습니다(평범한 필드 테이블을 못 받습니다).

`State`/함수 분기가 없습니다 — 값은 이미 구워진 상태라 그대로 옮겨집니다.

**에러**

- `Modifier.Overridden: expects at least one Modifier`
- `Modifier.Overridden: argument #{i} is not a Modifier (got {typeof(arg)})`

**예제**

```luau
local theme = q.Modifier { BackgroundTransparency = 0.2 }
local danger = q.Modifier { BackgroundTransparency = 0 }

local merged = q.Modifier.Overridden(theme, danger) -- danger가 이긴다
local same = theme:Overridden(danger)               -- 같은 함수, 같은 결과
```

**관련** — [테마와 동적 스타일링](../../how-to/05-theme-and-dynamic-styling.md)

## `q.Modifier.TypedFactory<<T>>(name)`

**시그니처**

```luau
TypedFactory: <T>(name: string) -> (...(Modifier | { [string]: any })) -> T
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `name` | `string` | Modifier **클래스** 이름(빈 문자열 불가) |

**반환** — 그 클래스로 태그된 생성자. 호출 모양은 `q.Modifier(...)`와 같습니다.

**동작** — 하는 일이 **하나**입니다. 이름을 등록해 알려진 클래스로 만들고, 그 태그를 심는 생성자를 돌려줍니다. 상속 관계는 아무것도 모릅니다 — 그건 [`DefineSubtype`](#qmodifierdefinesubtypeparent-subtype)의 몫입니다.

**공개 API입니다.** 백엔드가 자기 엔진 클래스를 등록하는 데 첫 번째로 쓰지만, 컴포넌트 작성자가 자기 가상 클래스를 등록하는 길도 똑같습니다 — 커스텀 필드를 가진 `MaterialButtonModifier`는 `FrameModifier`와 동등한 일급 시민입니다.

같은 이름으로 다시 부르면 **같은 생성자 객체**가 나옵니다(dedup). 두 모듈이 같은 클래스를 등록해도 안전합니다.

**에러**

- `Modifier.TypedFactory: name must be a non-empty class name string (got {typeof(name)})`

**예제**

```luau
type CardModifier = {
    read __quadModifier: "Card",
    Elevation: (self: CardModifier, value: number) -> CardModifier,
    Peek: <T>(self: CardModifier, key: string) -> QuadTypes.FieldOut<T>?,
    As: <T>(self: CardModifier, name: string?) -> T,
}

local Card = q.Modifier.TypedFactory<<CardModifier>>("Card")
local raised = Card({ Elevation = 2 })
```

## `q.Modifier.DefineSubtype(parent, subtype)`

**시그니처**

```luau
DefineSubtype: (parent: string, subtype: string) -> ()
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `parent` | `string` | 상위 클래스 이름 |
| `subtype` | `string` | 하위 클래스 이름 |

**반환** — 없음.

**동작** — 하는 일이 **하나**입니다. `subtype ⊂ parent` 간선 **하나**를 등록합니다. 두 이름 모두 그 자리에서 알려진 클래스가 되므로 등록 순서를 신경 쓸 필요가 없습니다.

- 한 subtype이 **부모를 여럿** 가질 수 있습니다(인터페이스/다중 상속). Modifier 필드는 있거나 없거나 둘 중 하나라 충돌할 것이 없습니다.
- 같은 간선을 두 번 등록하면 아무 일도 하지 않습니다.
- 거부되는 것은 **순환뿐**입니다.

등록된 간선은 검사형 [`mod:As<Class>()`](#modasclass)가 조상 관계를 판정할 때 쓰입니다.

**에러**

- `Modifier.DefineSubtype: parent must be a non-empty class name string (got {typeof(name)})`
- `Modifier.DefineSubtype: subtype must be a non-empty class name string (got {typeof(name)})`
- `Modifier.DefineSubtype: "{subtype}" ⊂ "{parent}" would make a cycle`

**예제**

```luau
q.Modifier.TypedFactory<<any>>("Clickable")
q.Modifier.TypedFactory<<any>>("Card")
q.Modifier.DefineSubtype("Clickable", "Card") -- Card ⊂ Clickable
```
