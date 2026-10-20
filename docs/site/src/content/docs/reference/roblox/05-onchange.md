---
title: "OnChange·OnEvent·Out"
description: "프로퍼티 변경 신호와 엔진 이벤트를 숫자 키 자리 디스크립터로 붙이기 — 클래스 먼저 커리, 읽기 표면과 초기값 발화, Source 되쓰기"
---
`GetPropertyChangedSignal`과 엔진 이벤트 바인딩을 **props의 숫자 키 자리에 놓는 값**으로 만든 것입니다.
[`Tag`](/reference/core/09-tag-attr/)나 [생명주기 훅](/reference/sugar/04-lifecycle-hooks/)과 같은 자리에 놓입니다. 셋 다 클래스를 먼저 받고,
그다음 이름, 마지막에 콜백(또는 되쓸 `Source`)을 받습니다.

> **[3.4.0]** 3.3까지는 `q.OnChange("Text", fn)`·`q.Out("Text", src)`처럼 이름부터 받았고, 이름 집합은 생성 범위 전체를 합친
> 맵이었습니다(클래스마다 타입이 다른 이름은 `any`). 3.4.0부터 클래스를 먼저 받아(`q.OnChange "TextLabel" "Text" (fn)`) 그
> 클래스의 타입으로 검사합니다. 옛 두 인자 꼴은 `Quad0281`로 거부됩니다. `q.OnEvent`는 3.4.0에 새로 생겼습니다.

이 페이지의 심볼: [`q.OnChange "Class" "Name" (fn)`](#qonchange-class-name-fn) ·
[`q.OnEvent "Class" "Name" (fn)`](#qonevent-class-name-fn) · [`q.Out "Class" "Name" (src)`](#qout-class-name-src)

:::note
셋 다 `quad-roblox` 백엔드 전용입니다 — 신호를 찾는 일 자체가 엔진의 지식이라 백엔드가 소유합니다.
:::

```luau
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("@game/ReplicatedStorage/Client/UI/Quad")
local Frame = q.Elem "Frame"
local OnFrameChange = q.OnChange "Frame" -- 클래스 단계도 꺼내 둘 수 있다
```

---

## `q.OnChange "Class" "Name" (fn)`

**시그니처**

```luau
OnChange: <C>(class: C & keyof<ModClassMap>) -> <K>(name: K & keyof<읽기 표면>) -> (fn: (값) -> ()) -> OnChangeDescriptor<K>
```

**인자** — 세 단계로 받습니다.

| 단계 | 받는 것 | 설명 |
|---|---|---|
| 클래스 | 클래스 이름 | [Modifier·Spread와 같은 맵](/reference/roblox/02-elem/#클래스-맵--어떤-이름을-받는가)(조상 클래스 포함). 놓을 요소의 클래스나 그 조상 |
| 이름 | 프로퍼티 이름 | 그 클래스의 **읽기 표면**(쓰기 가능 + 읽기 전용) — 오타는 타입 에러 |
| 콜백 | `(newValue) -> ()` | 그 프로퍼티가 바뀔 때 불린다. 파라미터 타입은 클래스와 이름에서 정해진다 — 주석을 생략해도 잘못 쓰면 타입 에러가 나지만, 편집기의 hover·자동완성은 주석을 달아야 나온다 |

**값이 Instance인 프로퍼티의 콜백 인자는 `T?`입니다.** 예를 들어 `"Parent"`는 `Instance?` — 인스턴스가 트리에서 빠지는 순간 엔진이 `nil`을 주고, 그 순간을 잡는 것이 `Parent`를 지켜보는 주된 이유입니다. `function(p: Instance)`로 주석하면 타입 에러이고, 본문에서 `nil`을 먼저 걸러야 합니다. 같은 이유로 `AncestryChanged` 이벤트의 둘째 인자 `parent`도 `Instance?`입니다([`02-elem`](/reference/roblox/02-elem/) 이벤트 절).

**반환** — frozen 디스크립터 `{ Name, Callback }`(타입은 `OnChangeDescriptor<K>`). **캐시가 없어** 호출마다 새 값입니다.

**예제**

```luau
local size = q.Source(UDim2.fromScale(1, 0))

local box = Frame {
	Size = size,
	OnFrameChange "AbsoluteSize" (function(v: Vector2) -- 읽기 전용 프로퍼티도 된다
		print(v.X, v.Y)
	end),
	OnFrameChange "Visible" (function(v)               -- 주석을 생략해도 검사는 된다(v를 string으로 쓰면 에러)
		local _: boolean = v
	end),
}
```

**동작**

- 콜백은 **새 값**을 받습니다 — 핸들러가 `inst:GetPropertyChangedSignal(name)`에 연결하고, 신호가
  올 때 그 시점의 `inst[name]`을 읽어 넘깁니다. Deferred 신호 모드에서는 쓰기 한 번당 전달 한 번이고
  값은 전달 시점에 읽힙니다.
- **초기값도 콜백에 닿습니다 — 단, 쓰는 값이 엔진 기본값과 다를 때만.** props의 **숫자 키가 문자 키보다 먼저** 처리되므로, 같은 props에
  적은 프로퍼티 쓰기가 이미 연결된 바인딩에 도착합니다. 값이 기본값과 같으면(`Frame { Visible = true }`) 엔진이 동일값 대입에 시그널을 쏘지 않아 발화가 없습니다(엔진 0회 — 테스트용 mock 백엔드는 값 비교 없이 쏘므로 1회).

  ```luau
  local seen = {}
  q.Elem "TextLabel" {
  	Text = "a", -- 문자 키: 아래 바인딩이 연결된 뒤에 쓰인다
  	q.OnChange "TextLabel" "Text" (function(v)
  		table.insert(seen, v) -- seen[1] == "a" (SignalBehavior가 Deferred면 프레임 끝에 — 만든 직후엔 비어 있음)
  	end),
  }
  ```
- **같은 이름을 두 번 적으면 둘 다 연결됩니다.** 문자 키 형태였다면 조용히 마지막 것만 남았을 자리라,
  일부러 숫자 키 자리 형태로 만든 것입니다.
- 숫자 키 자리를 차지하지만 **길이는 0**입니다 — 물리 자식이 아니라서 형제 자식의 오프셋에 기여하지
  않습니다.
- [`State`](/reference/core/03-state/)에 담아 반응형으로 바꿔 끼울 수 있습니다.

  ```luau
  local desc = q.Source(OnFrameChange "Visible" (function(v: boolean) end))
  local box = Frame { desc }
  ```

  그 자리에 [`q.None`](/reference/core/10-lifetime-sentinels/#qnone)을 발행하면 연결이 끊기고, 새
  디스크립터를 발행하면 하나만 다시 연결됩니다.
  같은 값 dedup은 없습니다(`Connect`가 멱등이 아니라서, 재발행마다 Disconnect+Connect 한 번).
- 클래스 단계는 **놓을 요소의 클래스나 그 조상**을 적으세요. 디스크립터의 타입은 이름만 기억하므로 다른 클래스의 요소에 놓아도
  타입은 막지 않지만, 그 클래스에 없는 프로퍼티면 런타임에 엔진이 자기 에러를 냅니다. 한 모듈에 디스크립터가 천 개를 넘기면
  Studio 기본 한도에서 타입 검사가 무너지기 시작합니다([2026-10-20 실측] — [02-elem](/reference/roblox/02-elem/#qelem-class-props)).

**읽기 표면**

`OnChange`가 받는 이름 집합은 그 클래스의 **읽기 표면**입니다. 그래서 props의 문자 키로는 쓸 수 없는
읽기 전용 프로퍼티도 여기서는 유효합니다.

```luau
q.OnChange "Frame" "AbsoluteSize" (function(v: Vector2) end)    -- OK
q.OnChange "Frame" "AbsolutePosition" (function(v: Vector2) end) -- OK
q.OnChange "TextLabel" "TextBounds" (function(v: Vector2) end)   -- OK
```

이름이 그 클래스에 없으면 **타입 검사에서** 걸립니다. 타입을 우회해 넘긴 이름은 런타임에
엔진이 자기 에러를 냅니다 — quad는 프로퍼티 존재 여부를 다시 검사하지 않습니다.

이름의 타입은 클래스가 정합니다 — `UIStroke`의 `Color`는 `Color3`, `UIGradient`의 `Color`는 `ColorSequence`입니다(3.3에서는
이런 이름 여섯이 `any`였습니다).

**에러**

| 상황 | 문구 |
|---|---|
| 클래스 이름이 문자열이 아니거나 `""` | `Quad0278 OnChange: the first argument must be a class name string (got {…})` |
| 클래스 단계에 인자를 둘 이상(3.3의 `q.OnChange("Text", fn)`) | `Quad0281 OnChange: takes the class name only - write q.OnChange "Class" "Name" (…) (3.3's q.OnChange(name, …) form is gone)` |
| 이름이 문자열이 아니거나 `""` | `Quad0221 OnChange: property name must be a non-empty string` |
| 콜백이 함수가 아님 | `Quad0222 OnChange: callback for "{name}" must be a function (got {typeof(fn)})` |

---

## `q.OnEvent "Class" "Name" (fn)`

**시그니처**

```luau
OnEvent: <C>(class: C & keyof<ModClassMap>) -> <K>(name: K & keyof<이벤트>) -> (fn: 그 이벤트의 콜백) -> OnEventDescriptor<K>
```

엔진 이벤트를 **숫자 키 자리 디스크립터**로 연결합니다. 문자 키 `MouseEnter = fn`과 같은 연결이지만, 문자 키는 한 이벤트에
콜백 하나인 데 비해 디스크립터는 **몇 개든** 놓을 수 있습니다 — 훅 둘이 각자 `MouseLeave`를 거는 경우, 또는
[Spread](/reference/roblox/03-modifier-spread/#qspread-class-props)로 묶어 넘기는 핸들러가 요소의 자기 핸들러와 겹치는 경우에 씁니다.

```luau
local hovered = q.Source(false)
local OnGui = q.OnEvent "GuiObject"

local hoverHook = q.Spread "GuiObject" {
	OnGui "MouseEnter" (function(x: number, y: number) hovered:Set(true) end),
	OnGui "MouseLeave" (function() hovered:Set(false) end),
}

Frame {
	hoverHook,
	MouseLeave = function() print("요소 자신의 핸들러도 같이 불린다") end,
}
```

- 콜백은 **엔진 인자만** 받습니다(`self`·Instance 없음) — 문자 키 이벤트와 같습니다. 파라미터 타입은 클래스와 이벤트 이름에서 정해집니다.
- 철거될 때 연결을 끊습니다. 길이 0, `State`에 담아 바꿔 끼우기, 같은 이벤트 여럿 — `OnChange`와 같습니다.
- 이벤트 이름이 그 클래스에 없으면 타입 에러이고, 타입을 우회한 이름은 연결하는 순간 엔진이 자기 에러를 냅니다.

**에러**

| 상황 | 문구 |
|---|---|
| 클래스 단계(`Quad0278`·`Quad0281`) | `OnChange`와 같습니다 |
| 이벤트 이름이 문자열이 아니거나 `""` | `Quad0279 OnEvent: event name must be a non-empty string` |
| 콜백이 함수가 아님 | `Quad0280 OnEvent: callback for "{name}" must be a function (got {typeof(fn)})` |

---

## `q.Out "Class" "Name" (src)`

**시그니처**

```luau
Out: <C>(class: C & keyof<ModClassMap>) -> <K>(name: K & keyof<읽기 표면>) -> (src: Source<값>) -> OnChangeDescriptor<K>
-- src는 쓸 수 있는 값(Source)만 — :Compute 결과는 여기서 거부된다
```

엔진이 바꾼 프로퍼티 값을 **`Source`에 되쓰는** 슈거입니다. `OnChange` 위에 얹힌 팩토리라 돌려주는 값도 같은
디스크립터이고, 같은 숫자 키 자리에 놓습니다. 내려가는 방향은 평범한 문자 키 그대로라, 두 방향을 나란히 적습니다.

```luau
local text = q.Source("")

local box = q.Elem "TextBox" {
	Text = text,                          -- in: Source → 프로퍼티
	q.Out "TextBox" "Text" (text),        -- out: 프로퍼티 → Source
}
-- 사용자가 타이핑하면 text:Get()이 따라오고, text:Set("…")하면 입력창이 따라간다
```

**인자**

| 단계 | 받는 것 | 설명 |
|---|---|---|
| 클래스·이름 | | `OnChange`와 같은 읽기 표면 |
| `src` | `Source` | 되쓸 곳. 값 타입은 그 프로퍼티의 읽기 타입이고, 값이 Instance인 프로퍼티는 `Source<T?>`도 받습니다(`Adornee` 등). **`:Compute` 결과 같은 파생 `State`는 안 됩니다** — `Set`이 없어 주석 달린 변수(`local s: q.State<UDim2>`)면 타입 검사에서 걸리고(무주석 인라인 `:Compute` 결과는 타입이 비어 검사를 지나칩니다), 런타임이 거부합니다 |

**동작**

- 신호가 올 때 새 값이 `src:Get()`과 **같으면 쓰지 않습니다** — 되쓰기가 [`src:SetIfChanged(v)`](/reference/core/02-source/#sourcesetifchangedv)입니다. 왕복을 끊기 위해서가 아닙니다 — 엔진은 같은 값을 다시 대입해도
  변경 신호를 내지 않아 `Source → 프로퍼티 → 신호 → Source` 고리는 저절로 멈춥니다. 건너뛰는 이유는 **메아리**입니다: 숫자 키가 문자 키보다
  먼저 처리되므로 `Text = text`의 첫 쓰기가 이미 연결된 이 콜백에 닿는데, `Source:Set`은 같은 값에도 늘 전파하므로([`source:Set(v)`](/reference/core/02-source/#sourcesetv)) 건너뛰지 않으면
  `text`의 모든 구독자가 바인딩마다 한 번 더 헛돕니다.
- 그 밖은 `OnChange`와 같습니다 — 길이 0, 같은 이름 여럿 가능, `State`에 담아 바꿔 끼우기.
- 포커스나 커서는 건드리지 않습니다. 타이핑 중에 바깥에서 `text:Set`하면 입력창이 그 값으로 덮입니다 — 그런 정책이 필요하면
  `FocusLost` 이벤트로 확정하는 쪽을 직접 짜세요.
- 입력을 다듬어(앞뒤 공백 깎기 등) 쓰는 권장 경로는 [how-to 02 §6 입력 다듬기](/how-to/02-form-validation-pattern/#6-입력-다듬기--앞뒤-공백을-깎은-값이-필요할-때)에 있습니다.

**에러**

| 상황 | 문구 |
|---|---|
| 클래스 단계(`Quad0278`·`Quad0281`) | `OnChange`와 같습니다 |
| 이름이 문자열이 아니거나 `""` | `Quad0223 Out: property name must be a non-empty string` |
| 셋째 인자가 `Source`가 아님 | `Quad0224 Out: second argument for "{name}" must be a Source to write back into (got {…})` — `:Compute` 결과면 `got a read-only State (a :Compute result?)` |

:::caution
**애니메이션 중인 프로퍼티에는 걸지 마세요.** **[2026-09-26 기준]** 같은 프로퍼티에 [`q.Tween`](/reference/roblox/06-tween-animate/)/[`q.Animate`](/reference/roblox/06-tween-animate/)와 `q.Out`을 같이 걸면, 트윈이 매 프레임 쓰는 중간값이 `q.Out`을 거쳐 되쓸 `Source`에 앉고, `Animate`는 그 새 값을 다음 목표로 받아 방금 만든 트윈을 취소한 뒤 다시 만듭니다 — 그 결과 애니메이션이 첫 프레임에서 멈춘 것처럼 보입니다(mock에서 엔진의 프레임 쓰기를 대입 한 번으로 흉내 내 확인; 실기기에서 트윈 보간이 프레임마다 변경 신호를 내는지는 [2026-09-26 기준] 미실측입니다). `q.Out`은 사용자가 직접 바꾸는 프로퍼티(입력창의 `Text` 등)를 위한 것이고, 애니메이션이 거는 프로퍼티는 그 대상이 아닙니다 — 드래그하는 동안엔 `q.Out`으로 받고, 놓은 뒤 스냅은 애니메이션이 걸린 **다른** `Source`로 넘기는 식으로 두 원천을 가르세요 — 그 애니메이션에는 `Dedup = false`를 주세요(엔진이 드래그로 옮긴 뒤 같은 목표로 되돌릴 때 기록만 보고 건너뛰지 않게 — [관용구](/how-to/04-network-and-input-bridge/#끌어다-놓으면-제자리로-돌아가는-카드)).
:::

---

**관련**

- [Elem — 숫자 키](/reference/roblox/02-elem/#숫자-키--자식과-디스크립터)
- [02. 폼 검증 패턴](/how-to/02-form-validation-pattern/)
- [04. RemoteEvent와 엔진 입력을 상태로 브릿징하기](/how-to/04-network-and-input-bridge/)
