---
title: "08. quad v1에서 v2로 옮기기"
description: "quad v1 코드베이스를 v2 모양으로 단계별로 옮기는 이관 순서와 방법을 안내합니다"
---
> **대상 독자**: `Quad.Init(id)` / `Class "Frame"` / `Store.GetStore(...)` 로 쓰던 quad v1 코드베이스를 지금의 quad로 옮기려는 개발자
> **목표**: 자동 변환 없이, v1의 관용구마다 대응하는 v2 모양을 찾아 다시 쓰기

---

## 1. 전제

**자동 변환 도구는 없습니다.** v1과 v2는 문법이 비슷해 보이는 자리가 있어도 실행 모델이 다릅니다 — v1은 중앙 디스패처 하나가 키를 `typeof` 스니핑으로 분기했고, v2는 값의 종류마다 핸들러가 등록되는 확장 가능한 디스패치를 씁니다. 겉모양만 치환하면 대개 타입 검사에서 막히고, 막히지 않는 몇 가지는 런타임까지 조용히 흘러갑니다(8절).

권하는 순서는 **상태 → 컴포넌트 → 스타일 → 애니메이션**입니다. 상태(4절)를 먼저 옮겨두면 컴포넌트(5절)를 옮길 때 바인딩 자리가 이미 준비돼 있습니다. 한 화면씩 옮기고 그때마다 타입 검사를 돌리세요(2절) — v2는 strict 타입 검사가 마이그레이션 체크리스트 역할을 상당 부분 대신합니다(7절).

---

## 2. 툴체인 먼저

이관을 시작하기 전에 **타입 검사부터 통과하는 환경을 만드세요.** 기본 플래그로는 quad 코드가 아예 검사되지 않습니다.

```bash
luau-lsp analyze \
  --flag:LuauSolverV2=true \
  --flag:LuauTarjanChildLimit=160000 \
  --flag:LuauSubtypingIterationLimit=100000 \
  --flag:LuauTypeInferIterationLimit=1000000 \
  --definitions=<Roblox 타입 정의 파일> \
  <검사할 파일들>
```

넷 다 필요합니다. `LuauSolverV2=true`가 없으면 quad 소스의 타입 검사가 실패하고(`TypeError: read keyword is illegal here`), `LuauTarjanChildLimit`을 올리지 않으면 `D.Frame { Name = "x" }` 한 줄도 `TypeError: Internal error: Code is too complex to typecheck!`로 죽습니다(생성된 `D`의 프로퍼티 유니언이 큽니다). 나머지 둘은 큰 컴포넌트에서 같은 이유로 필요해집니다. 편집기(luau-lsp)에도 같은 플래그를 넣으세요 — [00. 설치 및 환경 구축](/getting-started/00-installation/) 참고.

그리고 v1의 `require(path).Init(id)` 자리는 **모듈 둘 + `UseProvider` 한 줄**로 바뀝니다.

```luau
-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 참고)
local Quad = require(<quad-base 모듈 경로>)
local QuadRoblox = require(<quad-roblox 모듈 경로>).QuadRoblox
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
local D = q.D
```

`require(quad-base)`가 돌려주는 값이 **이미** 기본 인스턴스입니다. v1의 `Init(id)`처럼 id로 같은 인스턴스를 다시 얻는 개념은 없습니다 — 격리된 인스턴스가 필요하면 `Quad.New()`를 쓰고, 여러 스크립트가 같은 상태를 나눠 쓰려면 그 `Store`를 모듈에서 export 하거나 `q.Context`로 넘기세요.

<!-- v1 소스 확인 2026-09-11: 2.24 exports.lua의 Init은 id가 없으면 매번 새 this를 만든다. 3.x UseProvider의 멱등·락은 quad-base init.luau. -->
v1의 `Init()`은 id 없이 부를 때마다 **새 인스턴스**를 만들었습니다. 그래서 설치 줄이 여러 파일에 흩어지면 스코프가 조용히 갈라졌습니다. 3.x에서는 같은 프로바이더로 `UseProvider`를 다시 불러도 아무 일도 하지 않으므로(다른 프로바이더를 주면 에러), 설치 줄을 여러 스크립트가 각자 적어도 인스턴스가 갈라지지 않습니다.

---

## 3. 개념 1:1 대응표

| v1 | v2 | 어디서 다루나 |
|---|---|---|
| `require(quad).Init(id)` | `Quad:UseProvider(QuadRoblox)` | 2절 |
| `Class "Frame"` → `Frame {...}` | `D.Frame {...}` | [첫 화면 만들기](/getting-started/02-first-screen/) |
| `Mount(parent, obj)` | `obj.Parent = parent` | 5절 |
| `mounts:Add(item)` / `:Unmount()` | `q.Slot<<Instance>>()` + `:Add`/`:Clear` | 5절 |
| `[Event "Activated"] = fn(self, …)` | 문자 키 `Activated = fn(…)` (self 없음) | 5절 |
| `[Event.Prop "Text"] = fn` | `q.OnChange("Text", fn)` (숫자 키 자리) | 5절 |
| `Class.Extend()` + `:Render(props)` | 평범한 함수 | 5절 |
| `self "_button"` 링커 | `q.PreRef<<Frame?>>(nil)` + `ref:Unwrap()` | 5절 |
| `Store.GetStore("myStore")` | `q.Store { key = q.Source(v) }` (이름 조회 없음) | 4절 |
| `myStore "color"` | `store.color` | 4절 |
| `register:With(fn)` | `state:Compute(fn, ...deps)` | 4절 |
| `register:Add(v)` | `state:Apply(q.Operator.Sum(v))` (숫자만) | 4절 |
| `register:Default(v)` | `state:Apply(q.Operator.Alternative(v))` | 4절 |
| `Style {...}`, `Frame { s }` | `D.Modifier.Frame {...}` (숫자 키 자리) | 5절 |

> **`:With`는 이름만 같은 다른 것입니다.** v1의 `register:With(fn)`은 "이 값으로부터 파생시켜라"였고, v2에서 그 자리는 `:Compute(fn, ...deps)`입니다. v2에도 `state:With(...)`가 **있지만** 그건 의존성을 추가한 노드를 하나 더 만드는 별개의 API입니다. 옮길 때 이름만 보고 그대로 두지 마세요.

---

## 4. 반응형 재작성

### 스토어 — 이름 조회는 없고, 값은 `Source`다

v1의 `Store.GetStore("myStore")`처럼 문자열 id로 스토어를 찾아오는 창구는 없습니다. `q.Store`가 만든 값을 직접 들고 다니거나, 모듈에서 export 하거나, `q.Context`로 넘깁니다.

```luau
-- v1: local myStore = Store.GetStore("myStore")  — 이름으로 찾는 전역 스토어는 없다
-- defaults의 값은 반드시 Source다(평범한 값을 주면 생성자가 그 자리에서 에러)
local store = q.Store { Color = q.Source(Color3.fromRGB(255, 255, 255)) }
store.Color:Set(Color3.fromRGB(0, 0, 0))

-- v1: 선언한 적 없는 키를 그냥 대입(myStore.Text = "...")  → :Of가 유일한 문
local text = store:Of<<string>>("Text") -- 타입 인자를 빼면 Source<any>가 된다
text:Set("0 sec")

local label = D.TextLabel { Text = text, BackgroundColor3 = store.Color }
```

<!-- mock 실측 2026-09-11: store.Text = "x" 뒤 필드는 plain string이 되고(rawequal false), 먼저 만든 라벨은 옛 Source를 계속 본다 — 옛 Source:Set()이 여전히 라벨을 갱신했다. -->
- **`store.key`는 넣은 `Source` 그 자체입니다.** 값을 바꿀 땐 `store.key:Set(v)`를 쓰세요. `store.key = v`는 필드를 통째로 갈아치워 `Source`를 잃어버립니다. v1에서는 `myStore.color = v`가 구독자를 깨우는 정상적인 쓰기였으니 이 자리는 특히 조심하세요 — 대입해도 에러가 나지 않고, **이미 그 `Source`에 물려 있던 바인딩은 옛 `Source`를 계속 보기 때문에** 화면이 조용히 갱신을 멈춘 것처럼 보입니다.
- **선언 안 한 키를 대입하는 v1 습관은 `store:Of<<T>>(name)`로 옮깁니다.** 없는 이름이면 그 자리에서 `Source`를 만들어 저장합니다. `Of`로 **나중에** 늘어난 키는 다음 재디스패치 때 반영됩니다.

### 파생 — dep은 값이 아니라 핸들로 온다

v1의 `myStore "a,b":With(function(a, b) ... end)`처럼 문자열로 키를 나열하던 자리는 `:Compute(fn, ...deps)`입니다. 넘어오는 dep은 **값이 아니라 State 핸들**이라 `:Get()`으로 읽습니다.

```luau
local QuadTypes = require(<quad-types 모듈 경로>)

local width = q.Source(200)
local topbar = q.Source(60)

-- v1: myStore "width,topbar":With(function(w, tb) ... end)
local size = width:Compute(function(
	self: QuadTypes.StateData<number>,
	_prev: UDim2?,
	tb: QuadTypes.StateData<number>
): UDim2
	return UDim2.fromOffset(self:Get(), tb:Get())
end, topbar)

local frame = D.Frame { Size = size }
```

`--!strict`에서는 **콜백 파라미터 주석이 사실상 필수**입니다(7절 첫 줄). 콜백 안에서 다른 State를 그냥 읽는 것으로는 의존성이 잡히지 않습니다 — 뒤 인자로 명시하세요.

<!-- v1 소스 확인 2026-09-11: 2.24 store.lua의 CalcWithDefault/CalcWithNewValue가 with(tstore, set, rawKey, withItem)로 호출한다. -->
**콜백 인자 자리가 다릅니다.** v1의 `register:With(fn)`은 `fn(스토어, 새 값, 키, 대상)` 순으로 불렀습니다. `:Compute`의 둘째 인자는 새 값이 아니라 **직전 계산 결과**이고, 첫 계산에서는 `nil`입니다. v1 콜백 본문을 그대로 옮기면 이 자리에서 조용히 어긋나니 인자 이름부터 다시 붙이세요.

### 연산자 — `Sum`은 숫자 전용이다

v1 register의 `:Add`/`:Default`는 이름 붙은 콤비네이터로 옮깁니다. 다만 `Sum`/`Product`/`Min`/`Max`/`Clamp`와 비트 연산은 **숫자에만** 성립합니다. v1에서 `UDim2`나 `Color3`를 더하던 코드는 `:Compute`로 가야 합니다.

```luau
local Op = q.Operator

-- v1: register:Add(500)  (숫자일 때만 성립한다)
local price = q.Source(100)
local total = price:Apply(Op.Sum(500))

-- v1: register:Default("Guest")
local nickname = q.Source<<string?>>(nil)
local shown = nickname:Apply(Op.Alternative("Guest"))

-- v1: register:With(테이블)  — 테이블 한 칸을 반응형으로 읽기
local theme = q.Source({ Primary = Color3.fromRGB(0, 120, 255) })
local primary = theme:Apply(Op.Indexed<<Color3>>("Primary"))

-- v1의 UDim2/Color3 덧셈은 Operator가 아니라 :Compute로
local base = q.Source(UDim2.fromOffset(0, 0))
local offset = q.Source(UDim2.fromOffset(0, 40))
local moved = base:Compute(function(
	self: QuadTypes.StateData<UDim2>,
	_prev: UDim2?,
	off: QuadTypes.StateData<UDim2>
): UDim2
	return self:Get() + off:Get()
end, offset)
```

<!-- mock 실측 2026-09-11: :Apply(Sum(5)):Apply(Alternative(0))는 "attempt to perform arithmetic (add) on nil and number"로 죽고, 역순은 5를 준다. Alternative는 nil→Guest, 값→값, 다시 nil→Guest로 매번 적용된다. v1 소스 확인: 2.24 store.lua에서 dvalue를 보는 곳은 CalcWithDefault뿐이고 갱신 경로 CalcWithNewValue에는 없다. -->
**`Alternative`는 `Default`보다 자주 발화합니다.** v1의 `:Default(v)`는 생성 시점 계산에서 스토어 값이 `nil`일 때만 쓰였고, 그 값에는 `:Add`나 `:With`가 붙지 않았습니다. 3.x의 `Alternative(v)`는 체인에 놓인 그 자리에서 값이 `nil`이 될 때마다 적용되고, 결과는 뒤 연산자로 계속 흘러갑니다.

그래서 **체인 순서가 결과를 바꿉니다.** `:Apply(Op.Sum(5)):Apply(Op.Alternative(0))`는 `Sum`이 먼저 `nil`을 받아 산술 에러로 죽습니다. 대체를 먼저 두는 `:Apply(Op.Alternative(0)):Apply(Op.Sum(5))`가 v1의 `:Default` 뒤 `:Add`에 해당하는 모양입니다.

전체 목록과 각 연산자의 계약은 [Operator 레퍼런스](/reference/sugar/02-operator/)에 있습니다.

### 애니메이션 — `:Tween{}`은 `:Apply(q.Animate{})`로

```luau
-- v1: myStore "color":Tween{ Time = 2 }
local hovered = q.Source(false)
local color = hovered:Compute(function(self: QuadTypes.StateData<boolean>): Color3
	return if self:Get() then Color3.fromRGB(60, 60, 60) else Color3.fromRGB(35, 35, 35)
end):Apply(q.Animate { Time = 0.2, Style = Enum.EasingStyle.Quad })

-- 값마다 옵션을 다르게 주고 싶으면 Tween을 :Compute 안에서 만든다
local target = q.Source(UDim2.fromScale(0, 0))
local position = target:Compute(function(self: QuadTypes.StateData<UDim2>): any
	return q.Tween { Value = self:Get(), Time = 0.5, Override = "Cancel" }
end)

local frame = D.Frame { BackgroundColor3 = color, Position = position }
```

<!-- v1 소스 확인 2026-09-11: 2.24 md/kr/include/tweenOptions.md가 Easing(문자열|함수, 기본 Exp2)·Direction(문자열, 기본 Out)을 정의한다. 3.x가 복사하는 필드 아홉은 quad-roblox Animate의 FIELDS, 기본 Style은 Property 핸들러의 buildInfo. mock 실측 2026-09-11: Easing 키를 넣어도 q.Animate/q.Tween 생성이 통과하고, strict luau-lsp도 모르는 키를 잡지 않았다(Time = "문자열"은 잡는다). -->
**옵션 이름이 v1과 겹치지 않습니다.** v1의 `TweenOptions`는 `Easing`(문자열이나 함수, 기본 `Exp2`)과 문자열 `Direction`을 받았습니다. `q.Animate`/`q.Tween`이 읽는 필드는 `Info`·`Time`·`Style`·`Direction`·`RepeatCount`·`Reverses`·`DelayTime`·`Override`·`Dedup` 아홉 개뿐입니다.

모르는 키는 **에러도 타입 진단도 없이 무시됩니다.** `Easing`을 그대로 옮겨 적으면 그 줄은 통과하고 곡선만 기본값인 `Enum.EasingStyle.Quad`가 됩니다 — 이징은 `Style = Enum.EasingStyle.*`로 옮기세요. `Direction`도 문자열이 아니라 `Enum.EasingDirection.*`이고, 문자열을 그대로 두면 quad가 막지 않고 엔진의 `TweenInfo` 생성까지 흘려보냅니다.

### 관측 — `:Register`/`:Observe` 자리

- `register:Register(fn)`(약한 참조로 등록되던 것) → `state:Observer(fn)`. 콜백은 **값이 아니라** `(targetState, observer, emitFrom?)`을 받습니다.
- `register:Observe(fn)` → `Observer`를 만들어 `:Subscribe()` 하거나 `q.Effect(fn, ...deps)`.
<!-- mock 실측 2026-09-11: s:Observer(fn)도 q.Effect(fn, s)도 만드는 그 줄에서 콜백이 한 번 찍혔다. v1 소스 확인: 2.24 store.lua의 Register는 등록만 한다. -->
- **둘 다 만드는 순간 한 번 돕니다.** 그 뒤로 계속 불리게 하려면 props의 숫자 키 자리에 넣어 인스턴스 수명에 묶거나 `:Subscribe()`를 부르세요 — 만들어두기만 하면 첫 한 번 뒤로는 조용합니다. v1의 `register:Register`는 등록할 때 부르지 않았으니, 옮길 때 이 첫 호출을 감안하세요.

v1에 없던 것도 생겼습니다 — `state:Apply(blocker)`(전파 차단), `q.Debounce`/`q.Throttle`(시간 게이트). 이들은 `:Gate`가 아니라 **`:Apply`로 붙입니다.**

---

## 5. 트리와 수명

### 마운트 — `Mount`는 `.Parent`다

v1의 `mount.lua`는 부모/자식 부기와 생명주기 파괴까지 들고 있는 무거운 모듈이었습니다. v2에는 그 자리가 둘로 갈립니다: **단일 부착은 그냥 `.Parent` 대입**, **동적인 자식 묶음은 `Slot`**.

```luau
local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local children: { Instance } = { D.TextLabel { Text = "제목" }, D.TextLabel { Text = "본문" } }

-- v1: Mount(screenGui, Frame{...}, another)
local gui = D.ScreenGui {
	D.Frame {
		-- 자식 배열 변수는 테이블 리터럴의 마지막 원소로 펼쳐서만 넘긴다
		table.unpack(children),
	},
}

-- v1의 Mount 자리: 만들어진 뒤 밖에서 .Parent를 대입한다
gui.Parent = playerGui
```

`Parent`는 프로퍼티로 넘길 수 없습니다 — 어떤 핸들러도 그 키를 받지 않아 디스패치가 에러를 냅니다.

<!-- mock 실측 2026-09-11: D.Frame({Name="첫째"},{Name="둘째"})는 에러 없이 통과하고 Name이 "첫째"로 남았다. v1 소스 확인: 2.24 class.lua의 Make가 pack(...)으로 여러 테이블을 돌고, Import(ClassName, defaultProperties)가 그 기본값 테이블을 마지막 인자로 덧붙인다. -->
**props 테이블은 하나만 받습니다.** v1은 `Class("Frame", 기본값)`처럼 테이블을 여러 개 넘길 수 있었고 그것들을 앞에서부터 합쳤습니다. `D.<Class>`는 첫 테이블만 읽고 **뒤에 넘긴 테이블을 에러 없이 버립니다.** 공통 기본값은 옮기는 쪽에서 한 테이블로 합치거나 `Modifier`로 만들어 숫자 키 자리에 놓으세요.

<!-- mock 실측 2026-09-11: D.Frame { (false and D.TextLabel{}) } 은 아래 메시지로 죽고, `or q.None`을 붙이면 자식 0개로 통과했다. v1 소스 확인: 2.24 class.lua의 자식 분기가 `indexType == "number" and valueType ~= "boolean"`이라 boolean을 건너뛴다. strict 검사 2026-09-11: (cond and D.TextLabel{...}) or q.None 을 자식 자리에 둔 파일이 플래그 넷으로 클린. -->
**자식 자리의 `false`도 에러입니다.** v1은 `cond and Frame {...}`이 만드는 `false`를 조용히 건너뛰었지만, 3.x에는 그 값을 받는 핸들러가 없습니다.

```
Dispatch: no handler matched key 1 (value: boolean) — check that the provider for this value (e.g. quad-roblox) is initialized
```

조건부 자식은 `(cond and D.Frame {...}) or q.None`으로 적으세요. `q.None`은 실재하는 값이라 자리를 채우고 아무것도 만들지 않습니다.

### `mounts:Add` / `:Unmount` → `Slot`

v1에서 목록을 다시 그릴 때 쓰던 `mounts:Unmount()` 뒤 재추가는 `slot:Clear()` 뒤 다시 `:Add`로 옮길 수 있지만, **데이터가 있는 목록이라면 `slot:List(data, updateFn, keyFn)`가 본래 자리**입니다. 키가 같은 항목은 인스턴스를 재활용하고, 사라진 키만 파괴합니다.

```luau
type Row = { Id: string, Title: string }
type RowUD = { title: QuadTypes.Source<string>, order: QuadTypes.Source<number> }

-- v1: local mounts = Mount(parent); mounts:Add(item); mounts:Unmount()
local rows = q.Source<<{ Row }>>({ { Id = "a", Title = "첫 줄" } })
local slot = q.Slot<<Instance>>()

slot:List(rows, function(
	item: Row | QuadTypes.KeyGone,
	index: number,
	_offset: QuadTypes.Source<number>,
	prev: QuadTypes.SlotItem<Instance>?,
	ud: RowUD?
): (any, RowUD?)
	if item == q.KeyGone then
		return nil -- 키가 사라졌다: 파괴
	end
	local data = item :: Row
	if prev and ud then
		ud.title:Set(data.Title) -- 캐시해둔 Source만 갱신하고 인스턴스는 재활용한다
		ud.order:Set(index)      -- 순서도 Source로 들고 있어야 재정렬이 반영된다
		return prev, ud
	end
	local title, order = q.Source(data.Title), q.Source(index)
	return D.TextLabel { LayoutOrder = order, Text = title }, { title = title, order = order }
end, function(item: Row): string
	return item.Id
end)

local list = D.Frame { slot }
```

`Slot`은 컨테이너 `Frame`을 만들지 않습니다 — 자식이 부모 밑에 바로 붙습니다. 자세한 계약은 [03. `Slot:List`로 긴 목록 다루기](/how-to/03-virtualized-infinite-scroll/)에 있습니다.

### 컴포넌트 — `Class.Extend()`는 함수 하나로

v1의 `Class.Extend()`는 `Init`/`Render`/`AfterRender`/`Getter`/`Setter`/`UpdateTriggers`/`Unload`를 갖는 객체였습니다. v2의 컴포넌트는 **props를 받아 인스턴스(또는 `Slot`)를 반환하는 평범한 함수**입니다.

| v1 | v2 |
|---|---|
| `:Render(props)` | 함수 본문 |
| `:Init` + `props:Default("Size", v)` | `props.Size or 기본값` |
| `:AfterRender(obj)` | `q.OnRendered<<T>>(fn)` — 단, 부모에 붙었음은 보장하지 않습니다 |
| `:Unload` | `q.OnDestroyed(fn)` |
| `.Getter` / `.Setter` / `.UpdateTriggers` / `:Update()` | 없음 — 프로퍼티 단위 갱신이라 전체 재렌더 개념 자체가 없습니다 |
| `self "_button"` 링커 | `q.PreRef<<TextButton?>>(nil)` 를 숫자 키 자리에 |

<!-- v1 소스 확인 2026-09-11: 2.24 class.lua의 this:Destroy가 `if unload then unload(self,object) else destroy(object) end`이고, :Update 경로가 옛 인스턴스에 대해 self:Destroy(lastObject)를 부른다. 3.x OnDestroyed는 quad-base LifecycleHooks에서 Effect의 정리 함수로 만들어진다. -->
**`Unload`와 `q.OnDestroyed`는 역할이 다릅니다.** v1의 `Unload`는 정의하면 기본 파괴를 **대신했고**, `:Update()`로 인스턴스를 갈아끼울 때 옛 인스턴스에 대해서도 불렸습니다. `q.OnDestroyed`는 `Effect`가 돌려주는 정리 함수라 파괴를 대신하지 않습니다 — 파괴는 그대로 일어나고 그 김에 정리만 실행됩니다. `Unload` 안에서 파괴를 막거나 다른 것을 대신 파괴하던 코드는 옮길 자리가 없으니 호출하는 쪽에서 다시 그리세요.

### 이벤트와 훅

```luau
-- v1: [Event "Activated"] = function(self, ...) end  — self는 오지 않는다
-- v1: self "_button" 링커  → PreRef
local buttonRef = q.PreRef<<TextButton?>>(nil)
local pressed = q.Source(0)

local button = D.TextButton {
	buttonRef,
	Text = "누르기",

	-- Frame에는 Activated가 없다: GuiButton 계열을 쓴다
	Activated = function(_input: InputObject, _clickCount: number)
		pressed:Set(pressed:Get() + 1)
		buttonRef:Unwrap().BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	end,

	-- v1: [Event.Prop "Text"] = fn
	q.OnChange("Text", function(newText: string)
		print(newText)
	end),

	-- v1: Event.Created / AfterRender / Extend의 :Unload
	q.OnCreated<<TextButton>>(function(inst)
		inst.AutoButtonColor = false
	end),
	q.OnRendered<<TextButton>>(function(inst)
		print(inst.Name)
	end),
	q.OnDestroyed(function()
		print("bye")
	end),
}
```

이벤트 핸들러는 **엔진이 주는 인자만** 받습니다(`self` 없음). 인자 개수도 맞아야 합니다.

<!-- v1 소스 확인 2026-09-11: 2.24 event.lua의 Property:: 특수 바인딩이 func(this, this[property])로 부른다. mock 실측 2026-09-11: 3.x 콜백은 인자 하나(값)만 받았다. -->
`q.OnChange` 콜백도 마찬가지입니다. v1의 `[Event.Prop "Text"] = fn`은 `fn(대상, 값)` 둘을 줬지만, `q.OnChange("Text", fn)`은 **값 하나만** 넘깁니다. 대상 인스턴스가 필요하면 같은 props에 `Ref`를 놓고 그쪽에서 얻으세요.

<!-- mock 실측 2026-09-11: 같은 props에 Text = "초기값"과 q.OnChange("Text", …)를 같이 두면 생성 직후 이미 1회 호출됐고 인자는 "초기값"이었다. v1 소스 확인: 2.24 class.lua의 Make가 이벤트 바인딩을 프로퍼티·자식 뒤에 연결한다. 지연 신호 모드에서의 v1 동작은 실측하지 않았다. -->
**`q.OnChange`는 같은 props가 적은 초기값에도 한 번 불립니다 — 단, 그 값이 엔진 기본값과 다를 때만.** 숫자 키 쪽이 문자 키보다 먼저 처리되어, 연결이 이미 살아 있는 상태에서 그 프로퍼티의 첫 쓰기가 도착하기 때문입니다(기본값과 같은 값이면 엔진이 시그널을 쏘지 않습니다 — [레퍼런스: `OnChange`](/reference/roblox/05-onchange/)). v1의 `Event.Prop`은 프로퍼티를 다 적용한 뒤에 연결됐으니 초기값에는 불리지 않았습니다 — 소리를 내거나 로그를 남기는 콜백이라면 생성 때 한 번 더 도는 것을 감안하세요.

<!-- v1 소스 확인 2026-09-11: 2.24 class.lua의 Make는 문자 키 프로퍼티 → 숫자 키 자식·스타일 → 이벤트 바인딩 순으로 돌고, Event.Created는 그 이벤트 바인딩 단계에 있다. mock 실측 2026-09-11: OnCreated 안에서 읽은 Text가 nil(props 미적용)이었고, 훅이 쓴 값은 props 값으로 덮였다. OnRendered에서는 props 값이 보였다. -->
**`q.OnCreated`는 v1의 `Event.Created`보다 이릅니다.** v1은 props를 다 적용한 뒤에 불렀지만 `q.OnCreated`는 props보다 **먼저** 돕니다. 그래서 그 안에서 프로퍼티를 읽으면 엔진 기본값이 나오고, 거기서 쓴 값은 뒤따라오는 props가 덮어씁니다. 적용된 값이 필요한 코드는 `q.OnRendered`로 옮기세요.

### 스타일 — `Style`은 `Modifier`로

v1의 `Style`은 이름 매칭 기반이라 선언 순서에 따라 안 먹는 함정이 있었습니다. v2의 `Modifier`는 값이고, **props의 숫자 키 자리에 놓인 순서**가 곧 우선순위입니다.

```luau
-- v1: local s = Style { BorderSizePixel = 0 }; Frame { s }
local CardStyle = D.Modifier.Frame {
	BorderSizePixel = 0,
	BackgroundColor3 = Color3.fromRGB(35, 35, 45),
}
local Accent = D.Modifier.Frame():BackgroundColor3(Color3.fromRGB(0, 120, 255))

local card = D.Frame {
	Size = UDim2.fromOffset(200, 80),
	UICorner = 12, -- v1의 Corner = 16
	CardStyle,
	Accent, -- 뒤에 온 Modifier가 필드 단위로 이긴다
}
```

`Style "Child" {}`처럼 **이름으로 대상을 고르는 형태는 없습니다.** 그 스타일을 쓸 요소에 직접 `Modifier`를 넘기세요. 우선순위 규칙 셋은 [01. 컴포넌트 경계 규약과 스타일 합성](/how-to/01-component-conventions/) §3에 있습니다.

<!-- mock 실측 2026-09-11: 같은 키를 가진 Modifier 둘을 {A, B}로 놓으면 B가, {B, A}로 놓으면 A가 이겼다. 명시 프로퍼티는 둘 다 이겼다. v1 소스 확인: 2.24 class.lua의 ProcessQuadProperty가 `if processedProperty[index] then return end`로 시작하고 props를 1..n 정순으로 돌아, 먼저 처리된 쪽(배열 앞)이 이긴다. -->
**겹치는 스타일끼리는 v1과 승자가 반대입니다.** 명시한 프로퍼티가 스타일을 이기는 것은 양쪽이 같지만, 같은 키를 가진 스타일이 둘 이상일 때 v1은 **배열에서 앞선 것**을 남겼고 3.x `Modifier`는 **뒤에 온 것**이 이깁니다. v1에서 "기본 스타일을 먼저, 예외를 나중에" 적어두었다면 옮길 때 순서를 뒤집어야 같은 화면이 나옵니다.

<!-- v1 소스 확인 2026-09-11: 2.24 class.lua의 Corner/PaddingAll/PaddingAllOffset/Scale이 대상 자신이거나 FindFirstChildOfClass로 찾은 것을 쓰고, 없을 때만 _quad_round 등의 이름으로 만든다. 3.x는 자기가 만든 자식을 Relate로 기억하고 사용자가 만든 UICorner는 건드리지 않는다(InstanceShorthand). -->
**숏핸드가 만지는 대상도 좁아졌습니다.** v1은 대상 자신이 `UICorner`면 그것을, 아니면 이미 붙어 있던 `UICorner` 자식을 찾아 썼습니다. 3.x는 **자기가 만든 자식만** 기억하고 사용자가 넣어 둔 같은 클래스 인스턴스는 건드리지 않습니다. Studio에서 `UICorner`를 미리 넣어 두고 v1 숏핸드로 조절하던 프리팹은 그 자식을 지우고 `UICorner` 키만 남기세요. 값의 모양도 조금 넓어져서, `UICorner`는 숫자뿐 아니라 `UDim`도 받습니다.

### 정리(cleanup)

v1의 `Signal.Bindable`·`Disconnecter`(Maid류)에 해당하는 것은 없습니다. quad는 인스턴스마다 걸어둔 엔진 연결로 생존을 판정하고, 인스턴스가 죽으면 거기 묶인 구독과 트윈도 멈춥니다. 직접 만든 커넥션만 `q.OnDestroyed`에서 끊으면 됩니다.

---

## 6. 제거된 기능과 이관 경로

| v1 기능 | v2 | 이관 경로 |
|---|---|---|
| `Frame "id" {...}` / `Store.GetObject(id)` / `GetObjects` / `AddObject` | 없음 | id 기반 전역 조회는 폐지됐습니다. 분류가 필요하면 `q.Tag`, 특정 인스턴스 참조가 필요하면 그 자리에서 `Ref`를 놓으세요. |
| `Style "Child" {}` (id 타겟) | 없음 | 대상 요소에 `Modifier`를 직접 넘깁니다. |
| `Init(QuadId)` 네임스페이스 공유 | 없음 | 기본 인스턴스 싱글톤 + 필요할 때만 `Quad.New()`. 공유는 export 또는 `q.Context`. |
| `Class.Extend`의 `Getter`/`Setter`/`UpdateTriggers`/`:Update()` | 없음 | 프로퍼티 단위 갱신이라 전체 재렌더가 필요 없습니다. |
| register 체이닝(`:With`→`:Add`→`:Tween` 누적) | 없음 | 매 호출이 새 노드를 만드는 `:Compute`/`:Apply`로 명시적으로 잇습니다. |
| `Tween.RunTween` / `RunTweens` / `StopTween` / `IsTweening` / `Tween.Easings.*` / 함수 이징 / `CallBack`·`OnStepped`·`Ended` / 테이블 트윈 | 없음 | 명령형 트윈 API가 통째로 없습니다. `q.Tween{}` / `q.Animate{}`로 선언하고, 겹칠 때의 처리는 `Override = "Cancel" \| "Finish"`로 정합니다. 이징은 `Style = Enum.EasingStyle.*` 또는 `Info = TweenInfo` — 커스텀 함수 이징과 스텝 콜백은 제공하지 않습니다. |
| `Apply(myFrame){props}` (이미 있는 인스턴스 재바인드 — `master`의 미배포 2.25 계열에만 있고 릴리즈 2.24에는 없습니다) | `q.Claim(inst, D.Mapper...)` | 재바인드 일반형은 기각됐고, **Studio에서 만든 프리팹을 통째로 넘겨받는 claim** 형태로만 부활했습니다. 한 번만 claim 가능하고 직계 자식을 전부 매핑해야 하며, 공동 소유 컨테이너(`PlayerGui` 등)는 대상이 아닙니다 — [07. Studio UI 바인딩과 `Claim`](/how-to/07-studio-ui-binding-and-claim/). |
| `Signal.Bindable` / `Disconnecter` | 없음 | 정리는 인스턴스 수명에 묶입니다(5절). |
| `Quad.Lang` | 없음 | 로케일은 라이브러리 범위 밖으로 분리됐습니다. |
| `tracker.lua`(핫리로드 감시) | 없음 | 그 자리를 대신할 스토리북 도구는 예정이고 아직 없습니다. |
| `Quad.Round` | 없음 | 별개의 유틸이었고 옮겨오지 않았습니다. |
| `RoundSize` | 없음 | 없어진 숏핸드는 이것 하나입니다. `Corner`/`PaddingAll`/`PaddingAllOffset`/`Scale`은 `UICorner`/`UIPadding`/`UIPaddingOffset`/`UIScale`로 **이름이 바뀌었을 뿐**이고(5절), 그 밖의 자리는 엔진 프로퍼티를 직접 씁니다. |

> **⚠️ `Ref`는 id 조회의 대체재가 아닙니다.** `Ref`의 용도는 "이미 밖에서 관리되고 있는 인스턴스의 참조를 얻는 것"이지 "이름으로 아무 데서나 찾아오는 것"이 아닙니다. v1에서 `Store.GetObject("id")`로 멀리 있는 요소를 집어오던 코드는, 그 요소를 만드는 자리에서 `Ref`를 놓고 **그 `Ref`를 값으로 넘기는** 모양으로 다시 쓰세요.

v1에 없던 것도 챙겨두면 좋습니다 — `q.Tag`/`q.Attr`(선언적 메타데이터), `q.Fallback`/`q.Traceback`(컴포넌트 에러 격리), `q.Context`(계층 건너 명시적 전달).

---

## 7. strict 체크리스트

v1 코드를 직역하면 아래 열여덟 가지에서 막힙니다. 진단 문구는 실제로 나오는 문자열의 머리 부분입니다.

| v1 직역 모양 | 진단 | 처방 |
|---|---|---|
| 프로퍼티 자리에 인라인 무주석 `:Compute` | `Expected this to be '(StateData<number>, UDim2?, ...any) -> UDim2' but got '(t1) -> UDim2 …'` | 콜백 파라미터에 `QuadTypes.StateData<T>` 주석을 붙이고, 가능하면 지역 변수로 빼세요 |
| `q.Slot()` — 타입 인자 없음 | `… but got 'Slot<unknown>'` | `q.Slot<<Instance>>()`. **홑화살괄호 `q.Slot<Instance>()`는 문법 오류입니다** |
| `q.OnCreated(fn)` — 타입 인자 없음 | `Type functions do not currently support types of the form '*error-type*'` | `q.OnCreated<<Frame>>(fn)` (`OnRendered`도 같음) |
| 생성 `D`에 없는 키(v1의 `Corner`/`PaddingAllOffset`/`Scale`) | `Expected this to be 'number', but got '"Corner"'` + 배열 유니언 불일치 한 줄 | 두 줄짜리 이 모양은 "그런 프로퍼티가 없다"는 뜻입니다(키가 배열 인덱스로 오독됩니다). `UICorner`/`UIPaddingOffset`/`UIScale` 숏핸드로 바꾸세요 |
| 이벤트 콜백 첫 인자에 `self` | `Expected this to be '((() -> ()) \| None \| StateMarker<() -> ()>)?' but got '(unknown, unknown, unknown) -> ()'` | `self`를 지우고 엔진 시그니처와 인자 개수를 맞추세요 |
| `Frame`에 `Activated` | `Expected this to be 'number', but got '"Activated"'` | `TextButton` / `ImageButton` 같은 `GuiButton` 계열로 |
| 숫자 키 자리에 `nil`이 들어감 | `the 2nd component of the union is 'nil', which is not a subtype of …` | `props.Modifier or q.None` |
| 미리 만들어둔 props 테이블을 `D.Frame(props)` | `Expected this to be 'FrameParam<…>' … 'string' is not exactly 'StateMarker<string>'` | 양방향 추론은 **리터럴 자리에서만** 삽니다. 테이블 리터럴로 직접 쓰세요 |
| 자식 배열 변수를 `D.ScreenGui(children)` | 같은 계열의 파라미터 불일치 | `D.ScreenGui { table.unpack(children) }` — 리터럴의 **마지막** 원소일 때만 전부 펼쳐집니다 |
| `q.Store()` 뒤 `store.Text = v` | `Cannot add property 'Text' to table '{ } & { Names: …, Of: … }'` | `defaults`에 선언하거나 `store:Of<<string>>("Text")` |
| `State<Frame>`을 `State<Instance>` 파라미터에 | `'Frame' is not exactly 'Instance'` (수백 줄) | `State<T>`는 불변입니다. 입력 자리는 생성 prop 타입(공변 마커)이나 `State<Instance>`로 선언하세요 |
| `Slot:List` updateFn이 먼저 `return nil` | `Expected this to be 'nil', but got 'TextLabel'` | 반환 팩을 주석하세요: `): (any, UD?)` |
| `q.Context.Provider("Theme")` 무캐스트 | prop 자리에서 `Get()` 결과가 `unknown` | `q.Context.Provider<<Theme>>("Theme")` |
| `q.Ref(nil)` | `… but got 'Ref<nil>'` | `q.Ref<<Frame?>>(nil)` — 타입 인자로 넓힙니다 |
| `[q.AttrKey("Hp")] = v` (문자 키) | `Expected this to be 'number', but got 'AttrKeyObject'` | 런타임은 정상이지만 타입이 안 열립니다. 숫자 키 자리의 `q.Attr{ Hp = v }` / `q.NumberAttr("Hp", v)`를 쓰세요 |
| `D.New("Folder")({...})`의 결과를 사용 | `Type 'unknown' does not have key 'Name'` | `D.New<<Folder>>("Folder")({...})` |
| `Text = 42` | `Expected this to be '(None \| StateMarker<string> \| string)?', but got 'number'` | `tostring(42)` — 암묵 변환은 없습니다 |
| `Op.Sum(UDim2…)` 같은 비숫자 | `None of the overloads for function that accept 2 arguments are compatible` | 산술·비트 연산자는 숫자 전용입니다. 다른 타입은 `:Compute`로 |

> **`<<T>>` 표기**: quad는 Luau의 **명시적 타입 인자** 문법을 씁니다. 화살괄호가 **둘**입니다 — `q.Slot<<Instance>>()`, `q.OnCreated<<Frame>>(fn)`, `store:Of<<string>>("Text")`, `D.New<<Folder>>("Folder")`, `Op.Indexed<<Color3>>("Primary")`, `q.Ref<<Frame?>>(nil)`. 하나만 쓰면 비교 연산으로 파싱돼 문법 오류가 납니다.

> **[2026-09-09] `Font`는 다시 씁니다 — 다만 레거시입니다.** 생성 `D`에 `Font`/`FontSize`/`TextWrap`/`Transparency`가 돌아왔습니다(엔진이 Deprecated·Hidden으로 표시한 프로퍼티를 v1 마이그레이션용으로 되살린 결정 — 필드마다 `-- @deprecated (Roblox <tags>)` 주석이 붙어 있습니다). v1 코드를 그대로 옮길 땐 `Font = Enum.Font.GothamMedium`이 타입 검사를 통과하니 먼저 컴파일을 통과시키고, **새로 쓰는 코드와 정리 단계에서는 현행 API인 `FontFace = Font.fromEnum(Enum.Font.GothamMedium)`으로 옮기세요**. ⚠️ 테이블 키 자동완성에는 이 deprecated 표시가 실리지 않습니다(에디터가 경고해주지 않는다는 뜻 — 멤버 접근 hover에만 보입니다).

---

## 8. 직역하면 못 잡는 것

타입 검사가 잡아주지 못하고 런타임까지 흘러가는 자리가 있습니다. 자주 밟는 둘을 여기서 다루고, 나머지 둘은 각각 제자리에서 다뤘습니다 — 둘째 props 테이블이 조용히 버려지는 것은 5절 마운트 절, `q.Animate`가 모르는 옵션 키를 조용히 무시하는 것은 4절 애니메이션 절입니다.

**1. 숫자 키 자리의 `nil` 구멍 — props가 느슨한 타입일 때.** v1의 props는 타입 없는 가방이라, 직역하면 `{ [string]: any }`나 `any?` 같은 모양이 되기 쉽습니다. 그러면 숫자 키 자리에 `nil`이 들어가도 **타입 검사가 조용히 통과하고**, 실행할 때 부기 안쪽에서 죽습니다.

```
Dispatch.recompute: sourceList[1] is nil — a nil hole in the numeric-key part of props ({ a, nil, b })? fill the optional slot with q.None; if you are writing a handler, bookkeeping is broken (setLength without setOffsetSource? the contract says None)
```

메시지 앞부분이 구멍을 의심하라고 말해 주지만, 가리키는 줄은 작성자의 줄이 아니라 엔진 안쪽입니다. **선택적으로 넘기는 값은 예외 없이 `or q.None`을 붙이세요** — `props.Modifier or q.None`. props 타입을 `any`로 두지 말고 정확히 적어두면 이 실수는 타입 검사에서 잡힙니다.

**2. 동적 스토어.** v1처럼 `store.NewKey = v`로 키를 늘리던 코드는 타입에서 막히지만(7절), `store:Of`로 옮긴 뒤에도 **주석을 빠뜨리면** `Source<any>`가 되어 그 아래 전부가 검사에서 빠집니다. `store:Of<<T>>(name)`의 타입 인자는 생략하지 마세요.

---

## 9. 이관 후 검증

1. **타입 검사부터.** 2절의 플래그로 프로젝트 전체를 돌리고 7절의 진단이 0이 될 때까지 고치세요. 이게 체크리스트의 대부분을 대신합니다.
2. **로직은 헤드리스로.** 컴포넌트가 `Store`/`State`만 소비하도록 두면 Roblox 없이 상태 전이를 검증할 수 있습니다 — [06. 헤드리스 테스트](/how-to/06-headless-testing/).
3. **Studio 스모크.** 화면 하나씩 띄워보되 (a) 목록의 추가/삭제/재정렬, (b) 애니메이션이 겹칠 때, (c) 화면을 `Destroy()`한 뒤 구독이 멈추는지를 특히 보세요 — v1에서 정리 경로가 없던 자리들이라 옮기면서 모양이 가장 많이 바뀝니다.
4. **에러가 나면** [09. 디버깅과 문제 해결](/how-to/09-debugging-and-troubleshooting/)의 에러 메시지 읽는 법을 먼저 보세요.
