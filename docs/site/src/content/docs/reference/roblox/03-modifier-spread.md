---
title: "Modifier와 Spread"
description: "q.Modifier \"Class\" — 타입드 프로퍼티 묶음(setter 체인, 검사형/무검사 다운캐스트), q.Spread \"Class\" — 요소 테이블 조각 묶음(:Append, 잠금), 입력 자리 마커 ModifierInto/SpreadInto"
---
둘 다 요소 테이블의 숫자 키 자리에 놓여 그 자리에서 펼쳐지는 값이지만, 하는 일이 다릅니다.

| | `q.Modifier "Class"` | `q.Spread "Class"` |
|---|---|---|
| 담는 것 | **프로퍼티 필드만** | 요소 테이블에 적을 수 있는 것 전부(프로퍼티·이벤트 키, 자식, Ref, 훅, 디스크립터) |
| 값 | 불변 — 모든 연산이 새 값 | 일회용·가변 — `:Append`로 더하고, 놓이면 잠긴다 |
| 같은 키 | 뒤에 오는 Modifier가 이긴다 | 먼저 자리 잡은 Spread가 이긴다 |
| 쓰임 | 스타일 묶음을 값으로 들고 다니기, 테마 | 컴포넌트가 안쪽 요소에 "아무거나 더 꽂을 자리"를 열어 주기 |

> **[3.4.0]** 3.3까지는 `D.Modifier.<Class>()`였고, 타입 없는 기본 Modifier는 `q.Modifier(...)`였습니다. 3.4.0부터 클래스를 먼저 받는 `q.Modifier "Frame" ()`이 타입드 생성자이고, 타입 없는 기본은 [`q.Raw.Modifier`](/reference/core/01-quad-module/#qraw)입니다. Spread는 3.4.0에 새로 생겼습니다.

이 페이지의 심볼: [`q.Modifier "Class" (...)`](#qmodifier-class-) · [`mod:<Field>(value)`](#modfieldvalue) ·
[`mod:As<Class>()`](#modasclass) · [`mod:As()` / `mod:As(name)` / `mod:As<<T>>()`](#modas--modasname--modast) ·
[`q.Spread "Class" (props)`](#qspread-class-props) · [`spread:Append(other)`](#spreadappendother) ·
[`Modifier<C>` / `ModifierInto<C>` / `Spread<C>` / `SpreadInto<C>`](#modifierc--modifierintoc--spreadc--spreadintoc)

:::note
`q.Modifier`·`q.Spread`는 `quad-roblox` 백엔드 전용입니다 — `q = Quad:UseProvider(QuadRoblox)` 뒤에만 존재합니다.
타입 없는 기본은 `quad-base`의 [`q.Raw.Modifier`](/reference/core/01-quad-module/#qraw)·`q.Raw.Spread`입니다 — 둘 다 필드가
검사되지 않아 이 페이지의 타입드 요소 배열부는 받지 않습니다(백엔드를 짓는 쪽의 원재료). 예약 메소드
(`Apply`/`Peek`/`Overridden`/`As`)의 정본은 [core/08 — Modifier](/reference/core/08-modifier/)입니다. 이 페이지는 **클래스가
붙었을 때 달라지는 것**을 다룹니다.
:::

```luau
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("@game/ReplicatedStorage/Client/UI/Quad")
local FrameModifier = q.Modifier "Frame"
local GuiModifier = q.Modifier "GuiObject"
```

---

## `q.Modifier "Class" (...)`

**시그니처**

```luau
Modifier: <K>(name: K & keyof<ModClassMap>) -> (...any) -> Modifier<Class>
```

`q.Modifier "Frame"`은 그 클래스로 태그된 Modifier 생성자를 돌려줍니다. 생성자의 인자는 0개 이상이고, 각 인자는
**Modifier**이거나 **평범한 `{ 필드 = 값 }` 테이블**입니다. 순서대로 필드 단위로 병합하고 **뒤 인자가 이깁니다**. 인자가
없으면 빈 Modifier입니다.

**반환** — 그 클래스로 태그된 새 Modifier(`Modifier<Frame>`). 값은 frozen이고, 모든 연산은 새 값을 돌려줍니다.

필드 이름과 값 타입은 **체인 형태**(`q.Modifier "TextButton" ():Text("x")`)에서만 검사됩니다. 테이블 형태(`q.Modifier
"Frame" ({ Size = … })`)는 필드 이름도 값 타입도 검사하지 않습니다 — `{ Sise = 1 }`·`{ Size = "x" }`·`{ Activated = fn }`이
전부 타입을 통과하고 런타임에서 잡힙니다(필드 이름·값은 drive에서 `Quad0076` 등으로, 함수 값은 Modifier를 만드는 순간
`Quad0063`으로). 클래스 태그는 두 형태 모두 붙습니다.

**예제**

```luau
-- 빌더 체인
local base = GuiModifier()
	:Size(UDim2.fromOffset(160, 40))
	:BackgroundColor3(Color3.fromRGB(60, 130, 255))
	:Visible(true)

-- 테이블 형태(+ 병합 — 뒤 인자가 이긴다)
local boxed = FrameModifier({ BackgroundTransparency = 0.5 }, { Visible = false })

-- 숫자 키 자리에 놓으면 그 자리에서 필드가 펼쳐진다
local card = q.Elem "Frame" { boxed, FrameModifier():ZIndex(2) }
```

**초기 필드 테이블의 규칙**

`{ 필드 = 값 }` 테이블에는 setter 경로가 만들 수 없는 것을 넣을 수 없습니다 — 두 경로가 조용히
갈라지지 않게 하기 위함입니다.

| 넣으면 | 에러 |
|---|---|
| 문자열이 아닌 키, 또는 `""` | `Quad0059 Modifier: initial-field table keys must be non-empty field names (got {…} at argument #{i})` |
| 예약 메소드 이름 | `Quad0060 Modifier: field "{k}" collides with a reserved Modifier method` |
| `As<Class>` 접두 이름 | `Quad0061 Modifier: field "{k}" matches the reserved cast prefix As<Class> - casts are methods, not fields` |
| 함수 값 | `Quad0063 Modifier: field "{k}" in an initial-field table cannot be a function - a transform goes through mod:{k}(fn); an event handler does not belong in a Modifier (put it as an inline key on the element, or wrap it in a State)` |
| Modifier도 평범한 테이블도 아닌 인자 | `Quad0065 Modifier: argument #{i} must be a Modifier or a plain field table (got {typeof(arg)})` |

**Modifier 클래스는 47개**입니다 — `q.Elem`의 31개보다 많습니다. `GuiObject`/`GuiButton`/`UIComponent`/`Instance`처럼
**Instance로는 만들 수 없는 조상 클래스**에도 Modifier가 있어서, "GuiObject라면 무엇에든 붙는 스타일"을 하나의 값으로
들고 다닐 수 있습니다([클래스 맵](/reference/roblox/02-elem/#클래스-맵--어떤-이름을-받는가)). 그 밖의 클래스는
[`q.ForClasses`](/reference/roblox/02-elem/#qforclassesmap)의 `Modifier`로 씁니다.

---

## `mod:<Field>(value)`

**시그니처**

```luau
-- 클래스의 쓰기 가능한 프로퍼티마다 하나씩 있다. Modifier<Frame>의 Size라면:
Size: (self: Modifier<Frame>, value: ModifierField<UDim2>) -> Modifier<Frame>

-- 값의 대수(quad-roblox 루트가 내보내는 이름)
export type ModifierField<T> =
	(T | Tween<T> | StateMarker<T | Tween<T>> | None)?                    -- nil = 필드 부재
	| ((old: ModifierFieldOut<T>?) -> (T | Tween<T> | StateMarker<T | Tween<T>> | None)?)
export type ModifierFieldOut<T> = T | TweenView<T> | StateView<T | TweenView<T>> | None  -- "저장된 그대로"
```

**반환** — 그 필드만 바뀐 **새 Modifier**. 원본은 그대로입니다(모든 setter가 얕은 복제).
태그는 유지되므로 체인 중간에 클래스가 바뀌지 않습니다.

**값의 대수**

| 넣는 것 | 뜻 |
|---|---|
| 리터럴 값 | 그 값으로 덮어쓴다 |
| `Tween` | 트윈 값으로 덮어쓴다(소비는 프로퍼티 핸들러 — [Tween과 Animate](/reference/roblox/06-tween-animate/)) |
| `State` | State를 통째로 필드에 넣는다(발행될 때마다 프로퍼티가 따라간다) |
| `q.None` | **언셋** — 그 필드를 명시적으로 `None`으로 만든다 |
| `nil` | 필드가 **부재**가 된다(언셋이 아니라 "안 적은 것") — `mod:X(if c then v else nil)`·`number?` 인자도 strict에서 그대로 됩니다 |
| 함수 | **변환 함수** — 아래 |

**보간할 수 없는 타입에는 `Tween` 팔이 없습니다** — [`q.Elem`의 프로퍼티 값 대수](/reference/roblox/02-elem/#문자-키--프로퍼티와-이벤트)와
같은 구분입니다(`Tween` 팔이 있는 타입은 `number`·`boolean`·`UDim`·`UDim2`·`Vector2`·`Vector2int16`·`Vector3`·`Color3`·
`CFrame`·`Rect`). nil 쓰기를 엔진이 받는 자리(숏핸드 `UICorner` 등, 값이 Instance인 객체 참조)는 State 팔이 `nil`/`None`까지
받습니다.

**변환 함수**

인자로 함수를 주면 그건 값이 아니라 변환입니다. 현재 저장된 값(`old`)을 받아 새 값을 돌려줍니다.

- 저장된 값이 평범한 값이면 **지금 바로** 불립니다.
- 저장된 값이 `State`이면 `old:Compute(fn)`이 되어 **반응성이 유지된** 파생 State가 들어갑니다.

```luau
local bumped = FrameModifier():ZIndex(2):ZIndex(function(old)
	if type(old) == "number" then
		return old + 1
	end
	return 1
end)
-- bumped의 ZIndex는 3, 원본은 그대로 2
```

`old`의 타입은 **저장된 그대로**입니다 — 값일 수도, `Tween`일 수도, `State`일 수도, `None`일 수도,
아직 없을 수도(`nil`) 있습니다. 그래서 `old` 자리는 `ModifierFieldOut<T>?`이고, 좁혀 쓰려면 위 예처럼 검사해야 합니다.

**`old`의 Tween·State 팔은 읽기 뷰입니다([3.4.0]).** State 팔은 `Get`만 있는 뷰(`old:Get()`은 되고 `:Compute` 등은 타입에
없음), Tween 팔은 `Value`만 있는 뷰입니다. 타입 함수가 프로퍼티마다 만드는 표면에는 전체 `State<T>`·`Tween<T>` 타입을
넣을 수 없어서입니다([2026-10-20 실측]). 3.3의 생성 타입은 전체형이었습니다. 다른 메소드가 필요하면 `q.isState(old)`로
확인한 뒤 캐스트하세요.

**핸들러 층 값은 필드에 들어갈 수 없습니다**

`Ref`/`PreRef`/`PostRef`/`Observer`/`Effect`/`Slot`/`Modifier`/`Spread`를 필드 값으로 주면 리터럴은 그 자리에서
던지고(`Quad0057`), 변환 함수의 반환도 **저장된 값이 평범한 값일 때는** 그 자리에서 던집니다. 저장된 값이 `State`면
변환이 `old:Compute(fn)`으로 들어가 lazy라 setter는 통과하고 마운트 때 드러납니다 — `Modifier`를 돌려주면 State 쪽
가드 `Quad0185`, `Ref`를 돌려주면 quad가 막지 못하는 정의되지 않은 동작입니다(관측, 계약 아님: 프로퍼티에 `Ref` 테이블이 쓰였습니다 —
[2026-09-27 mock 실측]).

```
Quad0057 Modifier: field "{key}" cannot hold a handler-layer value (Ref/Observer/Effect/Slot/Modifier/Spread/mapper descriptor)
```

`State`/`Source`는 통과합니다. 핸들러 층 값은 필드가 아니라 **props의 숫자 키 자리**에 놓는 것이 자리입니다 — 그런 것까지
묶어 넘기려면 Modifier가 아니라 [Spread](#qspread-class-props)를 쓰세요.

**필드 이름**

setter 키는 문자열이어야 합니다. `AttrKey` 같은 비문자열 키는 Modifier가 아니라 props 테이블에
직접 넣습니다.

```
Quad0058 Modifier: setter keys must be strings (got {typeof(key)}) - put a non-string key in the props table itself (Frame { [key] = value })
```

`tostring(mod)`은 `Modifier<Frame>(3 fields)` 형태로 클래스 태그와 필드 수를 보여줍니다.

---

## `mod:As<Class>()`

**시그니처**

```luau
-- 자기 하위 클래스마다 하나씩 있다. Modifier<GuiObject>라면:
AsFrame: (self: Modifier<GuiObject>) -> Modifier<Frame>
AsTextLabel: (self: Modifier<GuiObject>) -> Modifier<TextLabel>
-- … 그리고 항등 캐스트
AsGuiObject: (self: Modifier<GuiObject>) -> Modifier<GuiObject>
```

**검사형 하강**입니다. 조상 클래스의 Modifier를 구체 클래스로 내려 그 클래스의 setter를 쓰게 합니다.
**자동완성에 뜨는 목록이 곧 갈 수 있는 곳의 목록**입니다.

```luau
local base = GuiModifier():Visible(true)
local label = base:AsTextLabel():Text("제목"):TextSize(20)
local frame = base:AsFrame():Style(Enum.FrameStyle.Custom)
```

**동작 — 런타임 검사도 같이 합니다**

대상 클래스가 등록돼 있어야 하고, 자기 태그가 (a) 태그 없음, (b) 대상 자신, (c) 대상의 **조상** 중
하나여야 합니다. 엔진의 만들 수 있는 클래스 사슬은 설치 때 전부 등록되므로(`q.ForClasses`로 쓰는 `BasePart` → `Part` 등도),
직접 등록할 것은 여러분이 만든 커스텀 클래스뿐입니다.

```
Quad0056 Modifier: cannot cast a "{tag}" modifier to "{target}" - not an ancestor (use :As(name) to force)
Quad0055 Modifier: unknown modifier class "{target}" - Modifier.TypedFactory/DefineSubtype it first (or use :As(name) for an unchecked cast)
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
| `mod:As<<T>>()` | 타입 인자로 결과 타입을 강제한다(맵에 없는 타입으로도 갈 수 있다) |

타입 인자 없는 `mod:As(name)`·`mod:As()`의 결과 타입은 `unknown`이라 strict에서 그 값을 배열부에 두면 거부됩니다 —
타입이 따라오게 하려면 `mod:As<<RobloxModule.Modifier<TextButton>>>("TextButton")`처럼 타입 인자를 같이 주세요.

```luau
local forced: RobloxModule.Modifier<TextLabel> = GuiModifier():As<<RobloxModule.Modifier<TextLabel>>>()
local retagged = q.Modifier "TextLabel" ():As("Frame") -- 태그만 Frame으로(조상 검사 없음)
```

이름이 문자열이 아니거나 등록되지 않은 이름이면 던집니다.

```
Quad0051 Modifier:As: name must be a class name string (got {typeof(name)})
Quad0052 Modifier: unknown modifier class "{name}" - Modifier.TypedFactory/DefineSubtype it first
```

**넷째 무검사 경로 — 클래스 생성자에 다른 클래스의 Modifier를 넘기기.** `q.Modifier "Frame"`의 생성자는 base
`Raw.Modifier(...)`와 같은 병합 본문에 그 클래스 태그를 심는 것이라, 인자로 받은 Modifier의 태그를 보지 않습니다. 그래서
`FrameModifier(q.Modifier "TextButton" ({ TextSize = 3 }))`은 `TextSize` 필드를 든 채 `Frame`으로 다시 태그된 Modifier가
되고, strict도 통과합니다. 검사형 `As<Class>()`라면 형제 클래스로 가는 순간 `Quad0056`으로 막히는 이동이므로, 클래스를
바꿀 뜻이 없다면 생성자에는 같은 클래스(또는 조상 클래스)의 Modifier만 넘기세요.

**예약 메소드 — `Apply` / `Peek` / `Overridden`**

셋은 `quad-base` Modifier의 것이고 클래스가 붙어도 모양이 같습니다. 클래스와 관련해서 알아둘 것만
짚으면:

- `Apply: <U>(self: any, factory: (any) -> U) -> U` — `self`가 `any`라 팩토리에 주석을 달아도 `mod:Apply(factory)`는 인자도
  결과도 검사되지 않습니다. 팩토리 결과에 클래스 검사를 걸고 싶으면 결과를 `local v: RobloxModule.Modifier<TextButton> = …`처럼
  주석 단 변수에 담으세요 — 그 자리는 검사됩니다.
- `Peek: <T>(self, key: string) -> ModifierFieldOut<T>?` — **저장된 그대로** 돌려줍니다(State는 State인 채로,
  `None`은 `None`인 채로). 호출부가 `T`를 명시합니다: `mod:Peek<<UDim2>>("Size")`. 반환 타입의 Tween·State 팔은 위
  `old`와 같은 읽기 뷰입니다. 빈 문자열이나 비문자열 키는 `Quad0049 Modifier:Peek: key must be a non-empty string (got {…})`.
- `Overridden(a, b, …)` / `a:Overridden(b, …)` — 필드 단위 병합, 뒤가 이깁니다. 결과는 **태그 없는**
  Modifier입니다(입력들의 태그가 서로 다를 수 있어 하나를 고르지 않습니다) — 클래스가 필요하면
  `As<Class>()`로 다시 태그하세요.

---

## `q.Spread "Class" (props)`

**시그니처**

```luau
Spread: <K>(name: K & keyof<ModClassMap>) -> (props: Props<Class>) -> Spread<Class>
```

`q.Spread "Frame"`은 그 클래스의 Spread 생성자를 돌려줍니다. 생성자는 **요소 테이블과 같은 모양의 테이블**을 받습니다 —
문자 키(프로퍼티·이벤트)와 숫자 키(자식·Ref·Observer·Effect·디스크립터·Modifier·다른 Spread)를 그대로 적습니다. 값은
그 클래스의 [요소 props](/reference/roblox/02-elem/)와 같은 규칙으로 검사됩니다.

**반환** — `Spread<Class>`. 요소의 숫자 키 자리에 놓으면 그 자리에 펼쳐집니다.

Roblox 요소에는 이 생성자를 쓰세요. base의 `q.Raw.Spread {…}`는 런타임으로는 같은 값을 만들지만 클래스 태그가 없어(타입
`__quadSpread: true`) `q.Elem` 배열부의 `SpreadInto<C>` 자리에 들어가지 않습니다 — 클래스 검사를 끄는 자리를 열지 않으려고
일부러 받지 않습니다. `q.Raw.Spread`는 백엔드를 짓는 쪽의 원재료입니다.

```luau
local hoverHook = q.Spread "GuiObject" {
	q.OnEvent "GuiObject" "MouseEnter" (function() hovered:Set(true) end),
	q.OnEvent "GuiObject" "MouseLeave" (function() hovered:Set(false) end),
	Active = true,
}

local row = q.Elem "Frame" {
	hoverHook,                          -- 디스크립터 둘과 Active가 이 자리에 펼쳐진다
	Size = UDim2.new(1, 0, 0, 24),
}
```

**규칙**

- **깊이는 1입니다.** 생성자 테이블의 숫자 키에 놓인 다른 Spread는 그 자리에서 펼쳐 넣습니다. 펼쳐진 Spread는 잠깁니다.
- **같은 키는 먼저 자리 잡은 것이 이깁니다.** 생성자에 직접 적은 키가 맨 앞 층이고, 그다음은 놓인 순서대로입니다.
  요소에 놓였을 때도 같습니다 — 요소에 직접 적은 키 > 앞선 Spread > 뒤 Spread > Modifier
  ([숫자 키 — 누가 이기는가](/reference/roblox/02-elem/#숫자-키--자식과-디스크립터)). JavaScript 펼치기(뒤가 이김)와 반대입니다.
- **배열 값은 놓인 자리에 순서대로 들어갑니다.** 자식은 그 자리의 형제 순서를 그대로 가집니다.
- **요소에 놓이거나 다른 Spread에 펼쳐지면 잠깁니다.** 잠긴 Spread는 `:Append`가 거부되지만(`Quad0275`), 읽기와 다시
  놓기는 됩니다. 다만 안에 든 Ref·자식 Instance는 한 번에 한 자리에만 앉으므로 그런 것을 든 Spread를 두 요소에 놓으면
  그 값들이 자기 규칙대로 거부됩니다.
- 함수 값이 앞선 Spread에 밀려 버려지면 `q.debug`일 때 한 줄로 알립니다. 둘 다 불려야 하는 콜백은 문자 키 대신
  `q.OnEvent` 디스크립터로 담으세요 — 디스크립터는 배열 값이라 겹치지 않습니다.

| 넣으면 | 에러 |
|---|---|
| 평범한 테이블이 아닌 인자(`nil`, quad 값) | `Quad0273 Spread: the argument must be a plain table written like an element table (got {typeof(t)})` |
| 문자 키의 값으로 다른 Spread | `Quad0274 Spread: a Spread cannot be the value of key "{tostring(k)}" - place it in the array part` |
| 요소의 문자 키 값으로 Spread | `Quad0277 Dispatch.drive: a Spread cannot be the value of key "{tostring(k)}" - place it in the array part` |

---

## `spread:Append(other)`

**시그니처**

```luau
Append: (self: Spread<C>, other: SpreadInto<C>) -> ()
```

다른 Spread(같은 클래스나 조상 클래스의 것)를 끝에 펼쳐 넣습니다. **아무것도 돌려주지 않습니다** — Spread는 가변이고,
체인으로 쓰는 불변 값은 Modifier입니다. 넣은 쪽의 키는 비어 있는 키만 채우고(먼저 자리 잡은 것이 이김), 배열 값은 뒤에
붙습니다. 넣은 Spread는 잠깁니다.

```luau
local function Field(props: { Spread: RobloxModule.SpreadInto<TextBox>? })
	local own = q.Spread "TextBox" { focusHook, ClearTextOnFocus = false }
	if props.Spread then
		own:Append(props.Spread)        -- 호출자가 넘긴 것을 뒤에(같은 키는 컴포넌트 쪽이 이김)
	end
	return q.Elem "TextBox" { own }
end
```

| 넣으면 | 에러 |
|---|---|
| Spread가 아닌 값(평범한 테이블, Modifier) | `Quad0276 Spread:Append: the argument must be a Spread (got {typeof(other)})` |
| 잠긴 Spread에, 또는 자기 자신을 | `Quad0275 Spread:Append: this Spread is locked - it was already placed in an element or spread into another Spread (a Spread cannot be appended to itself)` |

읽기·지우기 메소드는 없습니다(필요가 드러나면 더합니다 — 메소드를 나중에 더하는 것은 호환을 깨지 않습니다).

---

## `Modifier<C>` / `ModifierInto<C>` / `Spread<C>` / `SpreadInto<C>`

quad-roblox 루트가 내보내는 타입 이름입니다. 클래스를 타입 인자로 받습니다.

| 이름 | 무엇 | 쓰는 자리 |
|---|---|---|
| `Modifier<C>` | 그 클래스의 Modifier 값 — setter·`As<Class>`·예약 메소드가 다 있다 | 만든 값을 담는 변수, setter를 부르는 함수의 인자 |
| `ModifierInto<C>` | **입력 자리 마커** — `C`나 그 조상 클래스로 태그된 Modifier를 받는다. 메소드가 없다 | 컴포넌트 props의 `Modifier` 필드 |
| `Spread<C>` | 그 클래스의 Spread 값 — `:Append`가 있다 | 만든 값을 담는 변수 |
| `SpreadInto<C>` | **입력 자리 마커** — `C`나 그 조상 클래스의 Spread를 받는다 | 컴포넌트 props의 `Spread` 필드 |

컴포넌트가 밖에서 받을 때는 **마커를 받으세요**. 마커는 값의 클래스 태그만 보므로 그 클래스의 것도, 조상 클래스의 것도
들어오고, 형제 클래스의 것은 거부됩니다. 받은 값은 그대로 안쪽 요소의 숫자 키 자리에 놓습니다.

```luau
type ThemedProps = {
	read Modifier: RobloxModule.ModifierInto<TextButton>?,
	read Spread: RobloxModule.SpreadInto<TextButton>?,
	read Text: string?,
}

local function Themed(props: ThemedProps): TextButton
	return q.Elem "TextButton" {
		props.Modifier or q.None,
		props.Spread or q.None,
		Text = props.Text or "",
	}
end

Themed({ Modifier = GuiModifier():ZIndex(2), Text = "a" })            -- 조상 클래스도 OK
Themed({ Modifier = q.Modifier "TextButton" ():TextSize(18) })        -- 자기 클래스
Themed({ Modifier = q.Modifier "TextLabel" ():TextSize(18) })         -- 타입 에러: 형제 클래스
```

마커에는 메소드가 없습니다 — 받은 Modifier에 setter를 더 불러야 하는 컴포넌트는 `Modifier<C>`를 받고, 호출하는 쪽이
`:As<Class>()`로 내려서 넘깁니다. [2026-10-20] 두 킷을 옮긴 실측에서 입력 자리에 메소드가 필요한 곳은 0곳이었습니다.

**[3.4.0] 3.3과 달라진 것.** 3.3의 `Into<Class>`는 `AsTextButton` 메소드를 가진 값이면 무엇이든 받는 인터페이스였고, 클래스별
`<Class>Modifier` 타입이 따로 있었습니다. 이제 둘 다 클래스를 인자로 받는 일반 이름(`Modifier<C>`·`ModifierInto<C>`)이고,
입력 자리는 태그만 보는 마커입니다. 그래서 **여러분이 만든 커스텀 클래스 Modifier**(`q.Raw.Modifier.TypedFactory`)는
`ModifierInto<TextButton>`에 바로 들어가지 않습니다 — 커스텀 타입이 선언한 `AsTextButton`으로 내려서 넘기거나, 컴포넌트가
커스텀 타입 자체를 받아 자기 필드를 소비한 뒤 무검사 `:As<<RobloxModule.Modifier<TextButton>>>("TextButton")`으로 꽂으세요
([core/08 — Modifier](/reference/core/08-modifier/)의 커스텀 클래스).

---

**관련**

- [Elem — Instance 생성](/reference/roblox/02-elem/) — Spread와 Modifier가 숫자 키 자리에서 펼쳐지는 규칙
- [01. 컴포넌트 경계 규약과 스타일 합성](/how-to/01-component-conventions/)
- [05. 디자인 토큰과 테마 전환](/how-to/05-theme-and-dynamic-styling/)
