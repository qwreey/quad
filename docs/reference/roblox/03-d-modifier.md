---
title: "D.Modifier — 타입드 프로퍼티 묶음"
description: "클래스별 Modifier 생성자, setter 체인의 값 대수, 검사형/무검사 다운캐스트, Into<Class> 인터페이스"
---
# `D.Modifier` — 타입드 프로퍼티 묶음

`Modifier`는 "프로퍼티 묶음"을 값으로 들고 다니는 불변 객체입니다. `D.Modifier.<Class>()`는 그것에
**클래스 태그와 타입드 setter**를 붙인 생성자로, 잘못된 필드 이름과 잘못된 클래스 조합을 컴파일
시점에 잡아줍니다.

이 페이지의 심볼: [`D.Modifier.<Class>(...)`](#dmodifierclass) · [`mod:<Field>(value)`](#modfieldvalue) ·
[`mod:As<Class>()`](#modasclass) · [`mod:As()` / `mod:As(name)` / `mod:As<<T>>()`](#modas--modasname--modast) ·
[`Into<Class>` / `<Class>Modifier`](#intoclass--classmodifier)

:::note
`D.Modifier`는 `quad-roblox` 백엔드 전용입니다 — `q = Quad:UseProvider(QuadRoblox)` 뒤에만 존재합니다.
타입 없는 기본 `q.Modifier(...)`는 `quad-base`의 것이고, 예약 메소드(`Apply`/`Peek`/`Overridden`/`As`)의
정본도 그쪽입니다([core/09 — Modifier](../core/09-modifier.md)). 이 페이지는 **클래스가 붙었을 때
달라지는 것**을 다룹니다.
:::

```luau
-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 참고)
local Quad = require(<quad-base 모듈 경로>)
local QuadRoblox = require(<quad-roblox 모듈 경로>).QuadRoblox
local DModule = require(<quad-roblox 모듈 경로의 D 하위 모듈>) -- 클래스별 Modifier 타입이 사는 생성 모듈
local q = Quad:UseProvider(QuadRoblox)
local D = q.D
```

---

## `D.Modifier.<Class>(...)`

**시그니처**

```luau
-- 클래스마다 하나씩 생성된 태그 생성자. Frame이라면:
D.Modifier.Frame: (...(FrameModifier | { [string]: any })) -> FrameModifier
```

**인자** — 0개 이상. 각 인자는 **Modifier**이거나 **평범한 `{ 필드 = 값 }` 테이블**입니다. 순서대로
필드 단위 병합이고 **뒤 인자가 이깁니다**. 인자가 없으면 빈 Modifier입니다.

**반환** — 그 클래스로 태그된 새 Modifier(`FrameModifier` 등). 값은 frozen이고, 모든 연산은 새 값을
돌려줍니다.

**예제**

```luau
-- 빌더 체인
local base = D.Modifier.GuiObject()
	:Size(UDim2.fromOffset(160, 40))
	:BackgroundColor3(Color3.fromRGB(60, 130, 255))
	:Visible(true)

-- 테이블 형태(+ 병합 — 뒤 인자가 이긴다)
local boxed = D.Modifier.Frame({ BackgroundTransparency = 0.5 }, { Visible = false })

-- 배열 부분에 놓으면 그 자리에서 필드가 펼쳐진다
local card = D.Frame({ boxed, D.Modifier.Frame():ZIndex(2) })
```

**초기 필드 테이블의 규칙**

`{ 필드 = 값 }` 테이블에는 setter 경로가 만들 수 없는 것을 넣을 수 없습니다 — 두 경로가 조용히
갈라지지 않게 하기 위함입니다.

| 넣으면 | 에러 |
|---|---|
| 문자열이 아닌 키, 또는 `""` | `Modifier: initial-field table keys must be non-empty field names (got {…} at argument #{i})` |
| 예약 메소드 이름 | `Modifier: field "{k}" collides with a reserved Modifier method` |
| `As<Class>` 접두 이름 | `Modifier: field "{k}" matches the reserved cast prefix As<Class> — casts are methods, not fields` |
| 함수 값 | `Modifier: field "{k}" in an initial-field table cannot be a function — use mod:{k}(fn) for a transform` |
| Modifier도 평범한 테이블도 아닌 인자 | `Modifier: argument #{i} must be a Modifier or a plain field table (got {typeof(arg)})` |

**생성되는 Modifier 클래스는 47개**입니다 — `D`의 별칭 31개보다 많습니다. `GuiObject`/`GuiButton`/
`UIComponent`/`Instance`처럼 **Instance로는 만들 수 없는 조상 클래스**에도 Modifier 타입이 있어서,
"GuiObject라면 무엇에든 붙는 스타일"을 하나의 값으로 들고 다닐 수 있습니다.

---

## `mod:<Field>(value)`

**시그니처**

```luau
-- 클래스의 쓰기 가능한 프로퍼티마다 하나씩 생성된다. FrameModifier의 Size라면:
Size: (self: FrameModifier, value: Field<UDim2>) -> FrameModifier

-- 값의 대수(생성 모듈의 별칭)
export type FieldV<T> = T | Tween<T> | StateMarker<T | Tween<T>> | None
export type Field<T> = FieldV<T> | ((old: FieldOut<T>?) -> FieldV<T>?)
```

**반환** — 그 필드만 바뀐 **새 Modifier**. 원본은 그대로입니다(모든 setter가 얕은 복제).
태그는 유지되므로 체인 중간에 클래스가 바뀌지 않습니다.

**값의 대수**

| 넣는 것 | 뜻 |
|---|---|
| 리터럴 값 | 그 값으로 덮어쓴다 |
| `Tween` | 트윈 값으로 덮어쓴다(소비는 프로퍼티 핸들러 — [Tween과 Animate](./06-tween-animate.md)) |
| `State` | State를 통째로 필드에 넣는다(발행될 때마다 프로퍼티가 따라간다) |
| `q.None` | **언셋** — 그 필드를 명시적으로 `None`으로 만든다 |
| `nil` | 필드가 **부재**가 된다(언셋이 아니라 "안 적은 것") |
| 함수 | **변환 함수** — 아래 |

**보간할 수 없는 타입에는 `Tween` 팔이 없습니다.** 그런 프로퍼티의 setter는 `Field<T>`가 아니라
`FieldP<T>`를 받습니다 — [`D`의 프로퍼티 값 대수](./02-d.md#해시-부분--프로퍼티와-이벤트)와 같은
구분입니다(`Tween` 팔이 있는 타입은 `number`·`boolean`·`UDim`·`UDim2`·`Vector2`·`Vector3`·`Color3`·
`CFrame`·`Rect`).

```luau
-- 값 부분에서 Tween 팔이 빠진다(변환 함수의 old도 Tween 없는 전체형)
export type FieldPV<T> = T | StateMarker<T> | None
export type FieldP<T> = FieldPV<T> | ((old: FieldOutP<T>?) -> FieldPV<T>?)

-- 예: Enum.Font는 보간 불가라 FieldP
Font: (self: TextBoxModifier, value: FieldP<Enum.Font>) -> TextBoxModifier
```

**변환 함수**

인자로 함수를 주면 그건 값이 아니라 변환입니다. 현재 저장된 값(`old`)을 받아 새 값을 돌려줍니다.

- 저장된 값이 평범한 값이면 **지금 바로** 불립니다.
- 저장된 값이 `State`이면 `old:Compute(fn)`이 되어 **반응성이 유지된** 파생 State가 들어갑니다.

```luau
local bumped = D.Modifier.Frame():ZIndex(2):ZIndex(function(old)
	if type(old) == "number" then
		return old + 1
	end
	return 1
end)
-- bumped의 ZIndex는 3, 원본은 그대로 2
```

`old`의 타입은 **저장된 그대로**입니다 — 값일 수도, `Tween`일 수도, `State`일 수도, `None`일 수도,
아직 없을 수도(`nil`) 있습니다. 그래서 `Field<T>`의 `old` 자리는 `FieldOut<T>?`이고, 좁혀 쓰려면
위 예처럼 검사해야 합니다.

**핸들러 층 값은 필드에 들어갈 수 없습니다**

`Ref`/`PreRef`/`PostRef`/`Observer`/`EffectHandle`/`Slot`/`Modifier`를 필드 값으로 주면 — 리터럴이든
변환 함수의 반환이든 — 그 자리에서 던집니다.

```
Modifier: field "{key}" cannot hold a handler-layer value (Ref/Observer/Effect/Slot/Modifier)
```

`State`/`Source`는 통과합니다. 이 값들은 필드가 아니라 **props의 배열 부분**에 놓는 것이 자리입니다
([D — 배열 부분](./02-d.md#배열-부분--자식과-디스크립터)).

**필드 이름**

setter 키는 문자열이어야 합니다. `AttrKey` 같은 비문자열 키는 Modifier가 아니라 props 테이블에
직접 넣습니다.

```
Modifier: setter keys must be strings (got {typeof(key)}) — put a non-string key in the props table itself (Frame { [key] = value })
```

`tostring(mod)`은 `Modifier<Frame>(3 fields)` 형태로 클래스 태그와 필드 수를 보여줍니다.

---

## `mod:As<Class>()`

**시그니처**

```luau
-- 자기 하위 클래스마다 하나씩 생성된다. GuiObjectModifier라면:
AsFrame: (self: GuiObjectModifier) -> FrameModifier
AsTextLabel: (self: GuiObjectModifier) -> TextLabelModifier
-- … 그리고 항등 캐스트
AsGuiObject: (self: GuiObjectModifier) -> GuiObjectModifier
```

**검사형 하강**입니다. 조상 클래스의 Modifier를 구체 클래스로 내려 그 클래스의 setter를 쓰게 합니다.
**자동완성에 뜨는 목록이 곧 갈 수 있는 곳의 목록**입니다.

```luau
local base = D.Modifier.GuiObject():Visible(true)
local label = base:AsTextLabel():Text("제목"):TextSize(20)
local frame = base:AsFrame():Style(Enum.FrameStyle.Custom)
```

**동작 — 런타임 검사도 같이 합니다**

대상 클래스가 등록돼 있어야 하고, 자기 태그가 (a) 태그 없음, (b) 대상 자신, (c) 대상의 **조상** 중
하나여야 합니다.

```
Modifier: cannot cast a "{tag}" modifier to "{target}" — not an ancestor (use :As(name) to force)
Modifier: unknown modifier class "{target}" — Modifier.TypedFactory/DefineSubtype it first (or use :As(name) for an unchecked cast)
```

`As` + 대문자로 시작하는 이름은 **전부 캐스트로 예약**돼 있어 절대 필드 setter가 되지 않습니다.
그래서 `mod:AsTextLabl()` 같은 오타는 조용히 `AsTextLabl` 필드를 만드는 대신 위의 "unknown modifier
class" 에러를 냅니다.

---

## `mod:As()` / `mod:As(name)` / `mod:As<<T>>()`

같은 메소드 이름이지만 **무검사 경로**입니다. 셋을 구분해서 쓰세요.

| 형태 | 하는 일 |
|---|---|
| `mod:As()` | 값을 그대로 돌려준다. 태그도 그대로 — **타입 레벨 캐스트만** |
| `mod:As(name)` | 그 이름으로 **다시 태그**한다. 존재 검사만 하고 **조상 검사는 안 한다** |
| `mod:As<<T>>()` | 타입 인자로 결과 타입을 강제한다(`D`가 모르는 타입으로도 갈 수 있다) |

```luau
local forced: DModule.TextLabelModifier = D.Modifier.GuiObject():As<<DModule.TextLabelModifier>>()
local retagged = D.Modifier.TextLabel():As("Frame") -- 태그만 Frame으로(조상 검사 없음)
```

이름이 문자열이 아니거나 등록되지 않은 이름이면 던집니다.

```
Modifier:As: name must be a class name string (got {typeof(name)})
Modifier: unknown modifier class "{name}" — Modifier.TypedFactory/DefineSubtype it first
```

---

## `Into<Class>` / `<Class>Modifier`

생성 모듈은 클래스마다 타입 둘을 내보냅니다.

```luau
export type FrameModifier = { … }                                    -- 값 타입
export type IntoFrame = { AsFrame: (self: any) -> FrameModifier }    -- 인터페이스
```

컴포넌트가 밖에서 Modifier를 받을 때는 **`Into<Class>`를 받으세요**. 그러면 그 클래스의 Modifier도,
**조상 클래스**의 Modifier도, `As<Class>()`를 구현한 **커스텀 클래스**의 것도 다 들어옵니다.

```luau
type ThemedProps = {
	read Modifier: DModule.IntoTextButton?,
	read Text: string?,
}

local function Themed(props: ThemedProps): TextButton
	return D.TextButton({
		if props.Modifier then props.Modifier:AsTextButton() else q.None,
		Text = props.Text or "",
	})
end

Themed({ Modifier = D.Modifier.GuiObject():ZIndex(2), Text = "a" }) -- 조상 클래스도 OK
Themed({ Modifier = D.Modifier.TextButton():TextSize(18) })          -- 자기 클래스(항등 캐스트)
```

컴포넌트가 자기 Modifier 클래스를 만들고 싶다면 `quad-base`의 `q.Modifier.TypedFactory(name)`으로
태그 생성자를 얻고 `q.Modifier.DefineSubtype(parent, subtype)`으로 상속 간선을 등록하면 됩니다
([core/09 — Modifier](../core/09-modifier.md)) —
`D.Modifier.<Class>`가 쓰는 것과 정확히 같은 등록 경로라, 커스텀 클래스도 `Into<Class>` 자리에서
`FrameModifier`와 같은 지위를 갖습니다.

**예약 메소드 — `Apply` / `Peek` / `Overridden`**

셋은 `quad-base` Modifier의 것이고 클래스가 붙어도 모양이 같습니다. 클래스와 관련해서 알아둘 것만
짚으면:

- `Apply: <U>(self: any, factory: (any) -> U) -> U` — `self`가 `any`라 **팩토리에 주석을 달아야**
  클래스 검사가 살아납니다. 주석을 달면 조상 클래스 팩토리도 그대로 받습니다.

  ```luau
  local Boldify = function(mod: DModule.TextButtonModifier): DModule.TextButtonModifier
  	return mod:TextSize(20)
  end
  local bold = D.Modifier.TextButton():Text("go"):Apply(Boldify)
  ```
- `Peek: <T>(self, key: string) -> FieldOut<T>?`([core/09 — Modifier](../core/09-modifier.md)) —
  **저장된 그대로** 돌려줍니다(State는 State인 채로,
  `None`은 `None`인 채로). 호출부가 `T`를 명시합니다: `mod:Peek<<UDim2>>("Size")`.
  빈 문자열이나 비문자열 키는 `Modifier:Peek: key must be a non-empty string (got {…})`.
- `Overridden(a, b, …)` / `a:Overridden(b, …)` — 필드 단위 병합, 뒤가 이깁니다. 결과는 **태그 없는**
  Modifier입니다(입력들의 태그가 서로 다를 수 있어 하나를 고르지 않습니다) — 클래스가 필요하면
  `As<Class>()`로 다시 태그하세요.

---

**관련**

- [D — Instance 생성](./02-d.md) — Modifier가 배열 부분에서 소진되는 규칙
- [03. 컴포넌트 합성](../../getting-started/03-component-composition.md)
- [05. 테마와 동적 스타일링](../../how-to/05-theme-and-dynamic-styling.md)
