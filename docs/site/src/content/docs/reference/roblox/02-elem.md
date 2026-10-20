---
title: "Elem — Instance 생성"
description: "q.Elem \"Class\" {…}의 호출 모양, 문자 키(프로퍼티·이벤트)와 숫자 키(자식·디스크립터·Spread), 숏핸드, 클래스 맵과 q.ForClasses"
---
> **[3.4.0]** 3.3까지는 생성 네임스페이스 `q.Declaration`(관례 별칭 `D`)으로 `D.Frame {…}`라고 썼습니다. 3.4.0부터는 클래스를 먼저 받는 `q.Elem "Frame" {…}`입니다. 타입도 생성 파일이 아니라, 타입 검사기의 클래스 타입에서 타입 함수가 만듭니다. 기존 코드는 `scripts/migrate-3.4.py`로 옮길 수 있고, 바뀐 것 전체는 [변경 이력](/changelog/)에 있습니다.

`q.Elem "Frame"`은 그 클래스의 **생성자**를 돌려줍니다. 생성자는 **props 테이블 하나**를 받아 만들어진
Instance를 돌려줍니다. 생성자는 파일 머리에서 한 번 꺼내 두는 것이 관례입니다.

이 페이지의 심볼: [`q.Elem "Class" (props)`](#qelem-class-props) · [문자 키](#문자-키--프로퍼티와-이벤트) ·
[숫자 키](#숫자-키--자식과-디스크립터) · [숏핸드 키 넷](#숏핸드-키-넷) · [클래스 맵](#클래스-맵--어떤-이름을-받는가) ·
[`q.ForClasses<<Map>>()`](#qforclassesmap) · [타입 이름](#타입-이름--propsc--elemctorc--propertymapc)

:::note
`q.Elem`은 `quad-roblox` 백엔드 전용입니다. `q = Quad:UseProvider(QuadRoblox)` 뒤에만 존재하고, 그 전에는
`Quad0108` 안내 스텁입니다([설치와 프로바이더](/reference/roblox/01-install/)).
:::

```luau
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("@game/ReplicatedStorage/Client/UI/Quad")
local Frame = q.Elem "Frame"
local TextButton = q.Elem "TextButton"
local UIPadding = q.Elem "UIPadding"
```

---

## `q.Elem "Class" (props)`

:::caution
**props 테이블은 일회용입니다 — 다시 쓰는 것은 정의되지 않은 동작입니다.** 생성자(와 `q.Dispatch.drive`)는 그 테이블을 제자리에서 **소진**합니다. 안의 Spread는 펼쳐지고, `OnCreated`/`OnRendered`/Modifier는 처리된 표시로 바뀝니다. 그 뒤 그 테이블은 쓴 것입니다. 같은 테이블을 두 번째 인스턴스에 넘기면 에러 없이 그 훅들이 빠지고, **같은 인스턴스에 다시 넘기는 것도 지원하지 않습니다**(핸들러마다 "이미 소진된 테이블이 또 올 수 있다"를 생각하며 짜게 하지 않으려는 설계라 게이트도 두지 않습니다). 인스턴스마다 새 테이블을 만드세요. 함수로 감싸면 자연히 그렇게 됩니다.
:::

**시그니처**

```luau
Elem: <K>(name: K & keyof<CreatableMap>) -> ElemCtor<Class>
-- ElemCtor<C> = (props: Props<C>) -> C   (타입 함수가 클래스 타입에서 계산한다)
```

**인자** — 클래스 이름 문자열. 타입은 [클래스 맵](#클래스-맵--어떤-이름을-받는가)에 있는 이름만 받습니다. 런타임은
문자열인지만 봅니다(`Quad0278`). 맵에 없는 클래스는 `Instance.new`를 만나는 자리에서 엔진이 던집니다.

**반환** — 그 클래스의 생성자. 생성자는 props 테이블 하나를 받아 만들어진 Instance를 돌려줍니다. 타입은 그 클래스
그대로입니다(`q.Elem "Frame"`의 생성자는 `Frame`을 돌려줌). props 테이블에는 문자 키와 숫자 키가 **한 테이블에 섞여**
들어갑니다.

**예제**

```luau
local hovered = q.Source(false)
local label = q.Source("확인")
local ref = q.PreRef<<TextButton?>>(nil)

local button = TextButton {
	-- 문자 키 — 프로퍼티와 이벤트
	Text = label,                                   -- State: 값이 바뀌면 프로퍼티가 따라간다
	Size = UDim2.fromOffset(120, 36),               -- 평범한 값
	BackgroundColor3 = hovered:Compute(function(self: q.StateData<boolean>): Color3
		return if self:Get() then Color3.fromRGB(60, 130, 255) else Color3.fromRGB(30, 30, 30)
	end),
	TextTransparency = q.Tween({ Value = 0, Time = 0.2 }), -- Tween 값
	MouseEnter = function()                          -- 이벤트: 엔진 인자만 받는다
		hovered:Set(true)
	end,
	MouseLeave = function()
		hovered:Set(false)
	end,
	UICorner = 6,                                    -- 숏핸드 키

	-- 숫자 키 — 자식·Modifier·Spread·Ref·디스크립터
	UIPadding { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) },
	q.Modifier "TextButton" ():TextSize(18),
	ref,
	q.Tag("primary"),
	q.OnChange "TextButton" "Text" (function(v: string)
		print(v)
	end),
}

button.Parent = script.Parent -- 붙이는 것은 props가 아니라 밖의 한 줄
```

**왜 파일 머리에서 꺼내 두는가.** 읽기 좋은 것이 첫째 이유이고, 둘째는 타입 검사 비용입니다. 생성자 타입은 꺼내 두는
자리에서 한 번 계산되므로, 한 모듈에 생성자 호출이 수천 개여도 검사가 버팁니다. `q.Elem "Frame" {…}`처럼 쓸 때마다
꺼내도 동작은 같습니다. 다만 아주 큰 모듈에서는 Studio의 기본 한도(`LuauSolverConstraintLimit`)에 먼저 닿을 수 있습니다.
같은 이유로 [`q.OnChange`·`q.OnEvent`](/reference/roblox/05-onchange/) 디스크립터도 한 모듈에 천 개를 넘기면 그 한도에 닿기 시작합니다
([2026-10-20 실측]).

**동작 — 만들어지는 순서**

1. 엔진에 Instance를 만든다.
2. quad가 그 Instance를 **소유**한다. 생명주기 바인딩의 전제입니다([Claim과 Mapper](/reference/roblox/04-claim-mapper/)의
   "한 번만 claim한다").
3. props를 처리한다. 첫 패스에서 숫자 키의 [Spread](/reference/roblox/03-modifier-spread/#qspread-class-props)가 그 자리에
   펼쳐지고, 이어서 `Modifier`가 소진됩니다(아래). 그다음 **숫자 키가 문자 키보다 먼저** 처리됩니다.
   `OnChange`가 같은 props의 프로퍼티 쓰기를 받아볼 수 있는 것이 이 순서 덕입니다([q.OnChange](/reference/roblox/05-onchange/)의 초기값 발화).

---

## 문자 키 — 프로퍼티와 이벤트

**프로퍼티 값의 대수**

| 넣는 것 | 뜻 |
|---|---|
| 값 그대로 | 한 번 쓴다 |
| [`State`](/reference/core/03-state/)(= `Source`/파생 State) | 발행될 때마다 다시 쓴다 |
| `q.Tween{ … }` | 그 값으로 애니메이션한다([Tween과 Animate](/reference/roblox/06-tween-animate/)) |
| [`q.None`](/reference/core/10-lifetime-sentinels/#qnone) | 그 자리를 `nil`로 쓴다 — 객체 참조(`Adornee`/`NextSelection*` 등)를 놓는 방법 |
| `State`가 `nil`이나 `None`을 내놓을 때 | 위와 같이 `nil`을 쓴다(기본값 복원 경로는 없음) — 그 프로퍼티가 `nil`을 못 받으면 엔진이 던집니다. strict 타입은 이 규칙을 따라갑니다 — 값이 Instance인 객체 참조 프로퍼티(`Adornee`·`NextSelection*`·`PrimaryPart` 등)는 `nil`/`None`을 내놓는 State(`State<Frame?>`)를 받고, `Text`·`BackgroundTransparency`처럼 엔진이 `nil`을 거부하는 프로퍼티는 타입이 먼저 거부합니다 |

**`Tween` 팔이 있는 타입은 정해져 있습니다** — `number` · `boolean` · `UDim` · `UDim2` · `Vector2` ·
`Vector2int16` · `Vector3` · `Color3` · `CFrame` · `Rect`(유니언이면 멤버가 전부 여기 속할 때). 그 밖의 타입(`Enum.*`,
`string`, Instance 참조 등)의 프로퍼티는 값 / `State` / `None` 셋뿐이고, 거기에 `Tween`을 넣으면 타입 에러입니다.
`Animate`로 만든 State(`src:Apply(q.Animate{…})`)를 놓는 경우만은 `:Apply` 결과가 타입 검사를 받지 않아 잡히지 않습니다.
그때 런타임에서 첫 값은 스냅되고 둘째 값부터 엔진이 거부합니다.

`None`(또는 `State`가 내놓은 `nil`/`None`)으로 쓴 `nil`을 받아들이지 못하는 프로퍼티라면 엔진이 자기 에러를 던지고, 그 에러는 여러분이
봐야 할 에러입니다 — quad는 삼키지 않습니다.

**이벤트**

이벤트 이름을 키로 쓰면 그 신호에 연결됩니다. 콜백은 **엔진 인자만** 받습니다 — `self`도, Instance도
앞에 붙지 않습니다.

```luau
TextButton { Activated = function(inputObject: InputObject, clickCount: number) end }
```

값 자리에는 콜백 / `State<콜백>`(`nil`·`None`을 내놓아도 됨 — `State<콜백?>`) / `None`이 올 수 있습니다. `None`(또는 State가 계산한 `nil`)이면 그
자리의 연결을 끊고 새로 연결하지 않습니다. 같은 자리에 다른 콜백을 다시 발행하면 옛 연결을 끊고
하나만 남깁니다(`Connect`는 멱등이 아니라서 같은 값 dedup이 없습니다 — 재발행마다 Disconnect+Connect 한 번).

문자 키는 한 이벤트에 콜백 하나입니다. 같은 이벤트에 여럿을 걸어야 하면(훅 둘이 각자 `MouseLeave`를 쓰는 경우)
숫자 키 자리의 [`q.OnEvent`](/reference/roblox/05-onchange/#qonevent-class-name-fn) 디스크립터를 쓰세요 — 디스크립터는 서로 겹치지 않습니다.

**`AncestryChanged`의 둘째 인자 `parent`는 `Instance?`입니다.** 인스턴스가 트리에서 빠질 때 엔진이 `nil`을 주므로 타입도 그렇게 나옵니다 — `function(child: Instance, parent: Instance)`로 주석하면 타입 에러이고, 본문에서 `nil`을 먼저 거르세요(`q.OnChange "Frame" "Parent"`의 콜백 인자도 같습니다 — [05-onchange](/reference/roblox/05-onchange/)).

**타입 검사는 인자가 모자란 콜백을 잡지 않습니다.** Luau의 함수 서브타이핑 규칙상 `MouseEnter =
function(x) end`이나 `MouseEnter = function() end`처럼 선언보다 **적게** 받는 함수는 에러가 아닙니다
(엔진이 넘긴 나머지 인자를 버릴 뿐입니다). 인자가 **더 많거나** 타입이 다르면 그때는 잡힙니다.

함수가 아닌 값이 오면 quad가 먼저 거부합니다.

```
Event: handler for "{k}" must be a function (got {typeof(v)})
```

(엔진은 이 자리에서 던지지 않고 출력 창에만 남기기 때문에, 게이트가 quad 쪽에 있습니다.)

**어떤 키가 매치되는가**

프로퍼티인지 이벤트인지는 **엔진 리플렉션**으로 판정합니다 — 그 클래스(상속 포함)의 쓰기 가능한
프로퍼티면 프로퍼티 핸들러가, 이벤트면 이벤트 핸들러가 받습니다. 두 집합은 서로 겹치지 않습니다.
읽기 전용 프로퍼티(`AbsoluteSize` 등)는 쓰기 표면이 아니라 여기서 매치되지 않습니다(타입도 먼저 거부합니다) — 읽고 싶으면
[`q.OnChange`](/reference/roblox/05-onchange/)를 쓰세요.

둘 다 아닌 문자 키는 일반 no-match 에러입니다.

```
Quad0076 Dispatch: no handler matched key {tostring(k)} (value: {typeof(v)}{, brand: …}) - this key may not be a field of this element (a typo, a read-only field, or one from another class), or the provider that handles it (e.g. quad-roblox) is not initialized
```

**`Parent`는 props가 아닙니다**

`Parent` 키는 **어떤 핸들러에도 매치되지 않도록** 프로퍼티 핸들러의 매치 규칙에서 빠져 있고, 타입 표면에도 없습니다.
그래서 `Parent`를 넣으면 타입 에러이고, 타입을 건너뛴 코드에서는 위의 일반 no-match 에러가 납니다. 부모는 만들어진
뒤 밖에서 `inst.Parent = …` 한 줄로 붙이세요.

**각 클래스의 프로퍼티·이벤트 목록**

quad는 Roblox 클래스를 **설명하지 않습니다** — React가 `<div>`의 속성을 설명하지 않는 것과 같습니다.
`Frame`에 어떤 프로퍼티가 있고 `TextButton`에 어떤 이벤트가 있는지는 Roblox 공식 레퍼런스가 소스입니다.

> `https://create.roblox.com/docs/reference/engine/classes/<Class>`
> (예: `.../classes/Frame`, `.../classes/TextButton`)

quad가 더하는 것은 그 위의 **값 대수**(State/Tween/None)와 숫자 키 자리뿐입니다. 이름과 타입은 **여러분의 타입 검사기가
가진 클래스 타입**에서 옵니다 — 타입 함수가 그 클래스 타입을 읽어 props 표면을 만들므로, 에디터 자동완성과 hover가
그대로 보입니다.

:::caution 검사기마다 다를 수 있는 멤버
타입 표면은 검사기의 클래스 정의를 읽으므로, **그 정의보다 새로운 멤버는 타입이 모릅니다.** 예를 들어 이 저장소가
고정한 luau-lsp 정의에는 `UIShadow.ShowBehindParent`가 없어서 그 키를 props에 쓰면 타입 에러가 납니다. 같은 코드가 더 새
정의를 쓰는 에디터(VSCode 확장·Studio)에서는 통과합니다. 엔진에는 있는데 여러분의 검사기 정의에 아직 없는 멤버라면,
만든 뒤 밖에서 한 줄로 쓰세요 — `(shadow :: any).ShowBehindParent = true`. 반대로 엔진에서 빠진 멤버가 정의에 남아 있으면
타입은 통과하고 런타임에서 `Quad0076`이 납니다.
:::

:::caution 레거시 프로퍼티
엔진이 레거시로 표시한 프로퍼티 중 **넷은** 타입 표면에 일부러 남겨 두었습니다 — v1 코드를 옮길 때 이름 자체를 못 쓰는
일이 없도록 한 것입니다. 기준은 "v1 코드를 옮길 때 재작성 노고가 큰가"이고, 소문자 별칭(`className`·`focus`) 같은 v1
이전의 유물이나 잘 안 쓰이던 것(`Draggable`, `BillboardGui`의 거리 한계 둘)은 빠집니다. `NotScriptable`은 예외 없이 빠집니다.

| 프로퍼티 | 태그 | 있는 곳 |
|---|---|---|
| `Font` | Hidden | `TextLabel`·`TextButton`·`TextBox` |
| `Transparency` | Hidden | GuiObject 계열 |
| `FontSize` | Deprecated | `TextLabel`·`TextButton`·`TextBox` |
| `TextWrap` | Deprecated | `TextLabel`·`TextButton`·`TextBox` |

검사기의 클래스 정의가 이 넷을 이미 가지고 있으면 그대로 쓰고, 없으면 quad가 넣어 줍니다(정의마다 달라서 —
예를 들어 VSCode 확장의 정의에는 `GuiObject.Transparency`가 없습니다).
`Font`·`FontSize`·`TextWrap`은 세 클래스가 각자 따로 선언한 멤버입니다. 엔진이 이 이름을 쓰기 가능한 프로퍼티로 실제로 준다는 것은 `TextLabel`에서만 실측했습니다([2026-09-09]) — `TextButton`·`TextBox`에서는 미실측이라, 그 둘에서 거부되면 타입 에러가 아니라 런타임 `Quad0076`으로 드러납니다.

읽기 표면([`q.OnChange`](/reference/roblox/05-onchange/))도 위 넷을 받습니다. 다만 그 이름들로 변경 시그널이 실제로 발화하는지는 실기기 미실측입니다 — `className`은 한때 있었으나 발화하지 않아 뺐고, 같은 질문이 넷에도 걸립니다. 안전한 쪽은 새 이름(`FontFace`·`TextSize`·`TextWrapped`·`BackgroundTransparency`)으로 듣는 것입니다.

**에디터는 작성 지점에서 경고해주지 않습니다.** 테이블 리터럴 키를 자동완성할 때는 deprecated 표시가 실리지 않습니다
(Luau의 `@deprecated` 속성이 함수 전용이라 테이블 타입 필드에는 붙일 수 없습니다) — 그 몫은 문서에 있습니다.
무엇으로 갈아타야 하는지는 위의 Roblox 공식 레퍼런스가 소스입니다(예: `Font` → `FontFace`).

되살린 레거시 이름과 현행 이름(`Font`↔`FontFace`, `FontSize`↔`TextSize`, `TextWrap`↔`TextWrapped`,
`Transparency`↔`BackgroundTransparency`)을 **한 props에 같이** 쓰면 둘은 quad에게 다른 키라 체인이
둘이고, 어느 쪽이 마지막에 쓰이는지는 테이블 순회 순서에 달려 **정해져 있지 않습니다**(적은 순서와
무관 — mock 확인, [2026-09-27 기준]). Tween 기록도 키마다 따로라 한쪽에 `Animate`를 걸고 다른 쪽에
값을 쓰면 서로 취소하지 않습니다. 한 프로퍼티에는 한 이름만 쓰세요 — 이관 중이면 `Font`류로 통일하고
끝나면 `FontFace`류로 바꾸세요. 엔진 쪽 별칭 동작은 실기기 미실측.
:::

---

## 숫자 키 — 자식과 디스크립터

숫자 키에 놓는 Instance는 **quad가 소유한 것**이어야 합니다 — `q.Elem`의 생성자로 만들었거나 [`Claim`](/reference/roblox/04-claim-mapper/)으로 넘겨받은 것. `Instance.new`나 다른 라이브러리가 만든 인스턴스를 그대로 놓으면 `Quad0219 Dispatch: this Instance is not claimed by quad - build it with q.Elem or take it over with Claim first (an Instance made by another quad module instance also counts as not claimed here, and so does a destroyed one - a destroyed Instance cannot be reused)`로 거부됩니다(그 인스턴스가 밖에서 파괴돼도 quad가 알 수 없기 때문입니다). 꼬리 구절대로, 다른 quad 인스턴스(`q.NewModule()`을 따로 부른 코드나 `quad_base` 사본이 둘인 프로젝트)가 만든 Instance도 이쪽에는 미claim입니다. `Slot`의 원소도 같은 규칙입니다.

**자리를 쥔 `State`에 거부될 값을 넣으면 그 자리는 빈 채로 남습니다.** `Frame { src }`의 `src:Set(x)`에서 `x`가 미claim 인스턴스이거나 다른 자리에 이미 앉은 인스턴스이면 에러가 나지만, 그때는 옛 자식이 이미 내려간 뒤입니다 — 자리는 옛 값의 철거 → 새 값의 처리 순서로 돌고, 거부는 새 값의 처리에서 납니다(그 자리가 `Slot`을 쥐고 있었으면 그 트리도 이미 언마운트됐습니다). 에러는 시끄럽게 나므로 조용히 어긋나지는 않지만, 그 에러를 pcall로 삼키고 계속 가면 "자리 하나가 빈 채 값만 옮겨간" 상태가 남습니다. 두 자리의 자식을 맞바꾸려면 `s1:Set(c2); s2:Set(c1)`이 아니라 **둘 다 먼저 `:Set(nil)`로 비우고** 채우세요.

숫자 키 자리에는 자식 Instance와 **디스크립터**들이 들어갑니다. 이 자리에 올 수 있는 값은
이만큼입니다.

| 값 | 무엇을 하나 |
|---|---|
| Instance | 정적 자식으로 붙는다 — quad가 만든(또는 `Claim`한) 것만, 그리고 한 번에 한 자리에만(같은 Instance를 두 부모에 놓거나 `{ c, c }`로 놓으면 둘째가 거부됩니다; 앉아 있는 동안 `q.dispose`도 거부) |
| [`Slot`](/reference/core/06-slot/) | 동적 자식 구간 — 목록/단일 교체 |
| [`Ref` / `PreRef` / `PostRef`](/reference/core/07-ref/) | 만들어진 Instance를 그 핸들에 채운다 |
| [`Observer` / `Effect`](/reference/core/05-observer-effect/) | 그 Instance의 생애에 묶인다(leaf 종료 관용구) |
| [`Spread`](/reference/roblox/03-modifier-spread/#qspread-class-props) | 요소 테이블에 적을 수 있는 것 묶음을 이 자리에 펼친다(아래) |
| [`Modifier`](/reference/roblox/03-modifier-spread/) | 프로퍼티 묶음을 이 자리에 펼친다(아래) |
| [`q.Tag(...)` / `q.Attr{...}` / `q.StringAttr`·`NumberAttr`·`BooleanAttr`](/reference/core/09-tag-attr/) | CollectionService 태그·Attribute |
| [`q.OnChange "Class" "Name" (fn)`](/reference/roblox/05-onchange/) / `q.OnEvent "Class" "Name" (fn)` / `q.Out "Class" "Name" (src)` | 프로퍼티 변경·이벤트 신호 바인딩 |
| [`q.None`](/reference/core/10-lifetime-sentinels/#qnone) | 아무것도 아닌 자리(구멍 메꾸기) |
| 위의 것들을 담은 `State` | 발행될 때마다 그 자리를 갈아 끼운다(Spread는 제외 — 처리 전에 펼쳐지는 값이라 State에 담지 않습니다) |

`Spread`·`Modifier`·`Ref`류·`Observer`·`Slot` 같은 **핸들러 층 값은 문자 키가 아니라 숫자 키 자리에** 놓습니다.
문자 **키의 값**으로 놓는 것은 오용이라 바로 거부합니다(`Quad0068` Modifier, `Quad0277` Spread).

**nil 구멍을 만들지 마세요 — `or q.None`**

배열 리터럴 중간에 `nil`이 들어가면 배열 순회가 끊겨 부기(bookkeeping)가 깨집니다. 조건부 자리는
[`q.None`](/reference/core/10-lifetime-sentinels/#qnone)으로 메꾸는 것이 관용구입니다.

```luau
Frame {
	props.Modifier or q.None,
	props.Spread or q.None,
	props.Child or q.None,
}
```

**Spread와 Modifier는 첫 패스에서 펼쳐집니다 — 같은 키는 누가 이기는가**

숫자 키 자리의 `Spread`는 props 처리 첫 패스에서 자기 배열 값을 **그 자리에** 끼워 넣고, 자기 문자 키를 비어 있는
키에만 채웁니다. 이어서 `Modifier`가 자기 필드를 남은 빈 키에 펼치고 그 자리를 비웁니다. 같은 키가 여러 곳에 있으면:

| 순위 | 어디에 적힌 키 | 규칙 |
|---|---|---|
| 1 | 요소 테이블에 직접 적은 문자 키(값이 `None`이어도) | 항상 이긴다 |
| 2 | Spread가 가져온 키 | **먼저 자리 잡은 Spread가 이긴다** |
| 3 | Modifier가 가져온 키 | **뒤에 오는 Modifier가 이긴다** |

Spread의 "먼저가 이긴다"는 JavaScript의 객체 펼치기(`{...a, ...b}` — 뒤가 이김)와 반대입니다. Luau 테이블 생성자는 문자
키와 배열 값 사이의 순서를 남기지 않아서, 직접 적은 키를 일관되게 맨 앞 층으로 두려면 "먼저 자리 잡은 것이 이긴다"여야
합니다. Spread가 가져온 **함수 값**이 앞선 Spread에 밀려 버려지면 `q.debug`일 때 한 줄로 알려 줍니다(직접 적은 키에 덮인
것은 명시적인 덮어쓰기라 알리지 않습니다). 둘 다 불려야 하는 콜백이라면 문자 키 대신 `q.OnEvent` 디스크립터를 쓰세요.

**클래스별로 좁혀집니다**

숫자 키 자리의 타입은 클래스마다 다릅니다. `Ref`는 **그 클래스(또는 조상)의 Ref만** 받고, `Modifier`와 `Spread`도
자기 클래스와 조상 클래스의 것만 받습니다.

```luau
local frameRef = q.Ref<<Frame?>>(nil)
local labelRef = q.Ref<<TextLabel?>>(nil)

Frame { frameRef }                         -- OK
Frame { labelRef }                         -- 타입 에러: 형제 클래스의 Ref는 거부된다
Frame { q.Modifier "GuiObject" ():ZIndex(2) } -- OK: 조상 클래스
Frame { q.Spread "TextLabel" {} }          -- 타입 에러: 형제 클래스의 Spread
```

[`q.Mapper`](/reference/roblox/04-claim-mapper/) 디스크립터는 `Claim` 전용이라 여기 오면 no-match입니다.

---

## 숏핸드 키 넷

GuiObject 계열 클래스에는 자주 쓰는 UI 자식을 문자 키로 줄여 쓰는 편의 키가 넷 있습니다(타입은 GuiObject 계열에만 열어 두었지만 런타임 핸들러는 키만 보므로, 타입을 건너뛴 경로로 다른 클래스에 넣으면 그 안에 관리 자식이 조용히 생깁니다).

| 키 | 값 | 하는 일 |
|---|---|---|
| `UICorner` | `number` 또는 `UDim` | 관리되는 `UICorner` 자식의 `CornerRadius`. number는 offset UDim으로 바뀐다 |
| `UIPadding` | `UDim` | 관리되는 `UIPadding` 자식의 네 방향 패딩 |
| `UIPaddingOffset` | `number` | 같은 자식의 네 방향 패딩을 offset UDim으로 |
| `UIScale` | `number` | 관리되는 `UIScale` 자식의 `Scale` |

```luau
Frame { UICorner = 8, UIPaddingOffset = 12 }
```

- 값 자리에 `State`와 `Tween`이 그대로 들어갑니다(같은 값 대수).
- `UIPadding`과 `UIPaddingOffset`은 **같은 관리 자식**을 공유합니다 — 한 인스턴스에 둘을 같이 쓰지
  마세요. 둘 다 문자 키라 처리 순서가 테이블 순회 순서를 따르고, 그래서 어느 쪽이 이기는지는 **정해져 있지 않습니다**.
- 숏핸드에 `q.Tween`/`q.Animate`를 걸면 관리 자식의 프로퍼티(`UIPadding`/`UIPaddingOffset`은 넷 —
  `PaddingLeft`/`Right`/`Top`/`Bottom`)에 같은 Tween이 걸리지만, 콜백 `Started`/`Completed`/`Cancelled`는
  값 하나에 **한 번** — 마지막 프로퍼티가 보고할 때 `(숏핸드를 건 인스턴스, 숏핸드 키, 여러분이 준 값)`으로
  불립니다. `Completed` 안에서 같은 State를 `:Set`해 다음 트윈을 잇는 관용구도 그대로 됩니다(네 변이
  한 값으로 모입니다 — mock 확인, [2026-09-28 기준]).
- 값이 `nil`/`None`이 되면 그 관리 자식을 파괴합니다.
- 관리 자식은 quad가 만든 것이고, 여러분이 직접 넣은 `UICorner` 자식은 건드리지 않습니다. 다만
  템플릿의 `UICorner`와 이 숏핸드를 같이 쓰면 둘이 생기니 하나만 쓰세요.

---

## 클래스 맵 — 어떤 이름을 받는가

`q.Elem`·`q.Mapper`는 **만들 수 있는 클래스** 31개를, `q.Modifier`·`q.Spread`는 거기에 그 조상 클래스(`GuiObject`·
`GuiButton`·`UIComponent`·`Instance` 등 Instance로는 만들 수 없는 것)를 더한 47개를 받습니다. 맵에 없는 이름은 타입 에러입니다.

만들 수 있는 클래스 31개:

`BillboardGui` · `Camera` · `CanvasGroup` · `Folder` · `Frame` · `ImageButton` · `ImageLabel` ·
`ScreenGui` · `ScrollingFrame` · `SurfaceGui` · `TextBox` · `TextButton` · `TextLabel` ·
`UIAspectRatioConstraint` · `UICorner` · `UIDragDetector` · `UIFlexItem` · `UIGradient` ·
`UIGridLayout` · `UIListLayout` · `UIPadding` · `UIPageLayout` · `UIScale` · `UIShadow` ·
`UISizeConstraint` · `UIStroke` · `UITableLayout` · `UITextSizeConstraint` · `VideoFrame` ·
`ViewportFrame` · `WorldModel`

서비스와 엔진이 Deprecated/NotBrowsable/Internal로 표시한 클래스는 빠집니다. 이 맵에 없는 클래스(파트, 모델 등)는
[`q.ForClasses`](#qforclassesmap)로 자기 맵을 주고 씁니다.

---

## `q.ForClasses<<Map>>()`

**시그니처**

```luau
ForClasses: <M>() -> Surface<M>   -- Elem·Modifier·Spread·Mapper·OnChange·OnEvent·Out, 이름 맵이 M인 같은 표면
```

**인자** — 타입 인자 하나: 이름 → 클래스 타입의 테이블 타입. 값 인자는 없습니다.

**반환** — `q.Elem`·`q.Modifier`·`q.Spread`·`q.Mapper`·`q.OnChange`·`q.OnEvent`·`q.Out`과 같은 일곱을 담은 테이블.
타입만 여러분의 맵으로 계산되고, 런타임은 같은 함수입니다.

```luau
type World = { Part: Part, BasePart: BasePart, MeshPart: MeshPart, Model: Model }
local W = q.ForClasses<<World>>()
local Part = W.Elem "Part"

local floor = Part {
	Anchored = true,
	Size = Vector3.new(64, 1, 64),
	W.Modifier "BasePart" ():CanCollide(true),          -- 조상 클래스의 Modifier도 같은 규칙
	W.OnEvent "Part" "Touched" (function(hit: BasePart) end),
}
```

- **내장 맵과 합쳐지지 않습니다.** GUI 클래스는 `q.Elem`으로, 그 밖은 `W.Elem`으로 나란히 씁니다. 합치면 이름 바운드가
  다시 커져서 합치지 않는 모양을 유지합니다.
- **맵을 검사하지 않습니다.** `{ Part: Frame }`처럼 이름과 클래스가 어긋난 맵은 그대로 믿습니다(그 생성자는 런타임에 `Part`를
  만들지만 타입은 `Frame`입니다).
- **맵은 작게 유지하세요.** 맵이 커지면 타입 검사가 "too complex"로 다시 무너집니다([2026-10-20 실측] — 이름 130개까지는
  깨끗). 100개 아래로, 분야별로(월드·이펙트·사운드 등) 나눠 맵을 여러 개 두세요.
- 타입 없는 탈출구는 따로 없습니다. 맵에 클래스를 더하는 것이 탈출구입니다.

---

## 타입 이름 — `Props<C>` · `ElemCtor<C>` · `PropertyMap<C>`

컴포넌트 props에 적거나 함수 시그니처에 쓸 수 있도록 quad-roblox 루트가 내보내는 이름입니다. 셋 다 클래스를 타입
인자로 받습니다(`C`는 클래스 타입 — `Props<Frame>`).

| 이름 | 무엇 |
|---|---|
| `Props<C>` | 생성자가 받는 props 테이블 전체(문자 키 + 숫자 키) |
| `PropsHashPart<C>` | 문자 키 부분만 |
| `PropsArrayItem<C>` | 숫자 키 자리에 올 수 있는 값 하나 |
| `ElemCtor<C>` | 생성자 타입 `(Props<C>) -> C` |
| `MapperProps<C>` | [`q.Mapper`](/reference/roblox/04-claim-mapper/)의 props(숫자 키에 다른 매퍼 디스크립터도 받는다) |
| `PropertyMap<C>` | 쓰기 프로퍼티 이름 → 값 타입(`index<PropertyMap<Frame>, "Size">`는 `UDim2`) |

읽기 쪽(읽기 전용 포함) 프로퍼티 맵은 따로 내보내지 않습니다 — 클래스 타입 자체를 `index<Frame, "AbsoluteSize">`처럼
읽으세요. 차이는 하나입니다: [`q.OnChange`](/reference/roblox/05-onchange/)의 콜백은 값이 Instance인 프로퍼티를 `T?`로 받는데(엔진이
`nil`을 주므로), 클래스 타입은 `T` 그대로일 수 있습니다.

---

**관련**

- [02. 첫 화면 — 카드 하나 그리기](/getting-started/02-first-screen/)
- [01. 컴포넌트 경계 규약과 스타일 합성](/how-to/01-component-conventions/) — `Modifier`/`Spread`/`Ref`를 props로 넘기기
- [05. 디자인 토큰과 테마 전환](/how-to/05-theme-and-dynamic-styling/)
- [Quadnomicon Vol. 8 — 확장 가능한 디스패치 엔진](/quadnomicon/08-extensible-dispatch-engine/)
