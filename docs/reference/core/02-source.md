---
title: Source
description: 값을 직접 쓸 수 있는 반응형 루트 노드 — Set/SetIfChanged/SetAndDispose/Emit/Revision, 그리고 State 메소드 전부
---
# Source&lt;T&gt;

`Source`는 **값을 직접 쓸 수 있는 유일한 반응형 노드**입니다. 파생 노드인 [`State`](./03-state.md)는 읽기 전용이고, 전파는 언제나 어떤 `Source`의 `:Set`/`:Emit`에서 시작합니다.

이 페이지의 심볼: [`q.Source(v)`](#qsourcev) · [`source:Set(v)`](#sourcesetv) · [`source:SetIfChanged(v)`](#sourcesetifchangedv) · [`source:SetAndDispose(v)`](#sourcesetanddisposev) · [`source:Emit()`](#sourceemit) · [`source.Revision`](#sourcerevision) · [Source가 물려받는 State 메소드](#source가-물려받는-state-메소드)

```luau
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("@game/ReplicatedStorage/Client/UI/Quad")
local D = q.Declaration
```

`Source`의 생성·읽기·쓰기와 `:Compute`/`:Depend` 같은 파생 자체는 백엔드가 없어도 동작합니다. 백엔드가 필요한 것은 이 노드에 붙는 **구독 핸들의 생명주기**입니다 — `:Observer`로 만든 핸들을 실제로 살리는 것(`:Subscribe`, 인스턴스 바인딩)부터가 백엔드 몫입니다([05-observer-effect](./05-observer-effect.md) 참고).

---

## `q.Source(v)`

**시그니처**

```luau
Source: <T>(v: T) -> Source<T>

export type Source<T> = State<T> & {
	read Revision: number,
	Set: (self: Source<T>, v: T) -> Source<T>,
	SetIfChanged: (self: Source<T>, v: T) -> Source<T>,
	SetAndDispose: (self: Source<T>, v: T) -> Source<T>,
	Emit: (self: Source<T>) -> Source<T>,
}
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `v` | `T` | 초기값. `nil`도 값으로 허용됩니다(`q.Source<<number?>>(nil)` — 타입 인자는 명시해야 `Source<number?>`가 됩니다). |

**반환** — `Source<T>`. 만들어진 시점의 `Revision`은 `0`입니다.

**동작**

- 값으로 **Modifier는 담을 수 없습니다**. 생성자에서 걸리면
  `Quad0182 Source: cannot hold a Modifier as a Source value`
- 판정 술어는 셋 다 참입니다 — `q.isSource(s)`, `q.isEpoch(s)`, `q.isState(s)`. 세 번째는 술어 합성의 결과이고, 값 자체가 `State` 브랜드에 등록되지는 않습니다.
- `print(source)`는 `Source(<현재 값>)` 모양으로 찍힙니다. 읽기만 하며 계산을 유발하지 않습니다.

**예제**

```luau
local hp = q.Source(100)
print(hp:Get()) --> 100
```

**관련** — [Getting Started 03 값이 흐르게 하기](../../getting-started/03-flowing-values.md) · [Quadnomicon Vol. 1](../../quadnomicon/01-revision-and-epochmap.md)

---

## `source:Set(v)`

**시그니처**

```luau
Set: (self: Source<T>, v: T) -> Source<T>
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `v` | `T` | 새 값. Modifier는 거부됩니다. |

**반환** — `self`(체이닝 가능).

**동작**

- **같은 값을 다시 넣어도 언제나 리비전을 올리고 전파합니다.** 값 비교로 중복을 죽이지 않습니다 — 중복 제거는 하류의 판단이고(에폭 판정·게이트), `==` 비교는 테이블을 제자리에서 고친 변경을 조용히 삼켜버리기 때문입니다. 값이 같으면 쓰기를 건너뛰는 프레임워크에서 오셨다면 기대가 반대일 수 있습니다 — 같은 값을 무시하려면 [`:SetIfChanged(v)`](#sourcesetifchangedv)를 쓰세요.
- `:Get()`은 넣은 참조를 그대로 돌려줍니다(사본이 아닙니다). 테이블을 담아 두고 제자리에서 고쳤다면 [`:Emit()`](#sourceemit)으로 신호만 보내면 됩니다.
- Modifier를 넣으면 `Quad0181 Source: cannot Set a Modifier as a Source value`
- 전파를 받는 하류(파생 State·Observer·Effect)끼리의 **순서는 정해져 있지 않습니다** — 등록 순서도 아닙니다.

**예제**

```luau
local hp = q.Source(100)
hp:Set(80):Set(60) -- self를 돌려주므로 이어 쓸 수 있다
print(hp:Get()) --> 60
```

---

## `source:SetIfChanged(v)`

> **[2026-10-01 기준]** `:SetIfChanged`는 게시된 3.2.0에는 없습니다 — 다음 릴리즈부터([변경 이력](../../../CHANGELOG.md) `[Unreleased]`). 그전엔 `if v ~= src:Get() then src:Set(v) end`가 같은 일을 합니다.

**시그니처**

```luau
SetIfChanged: (self: Source<T>, v: T) -> Source<T>
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `v` | `T` | 새 값. Modifier는 거부됩니다(`:Set`과 같은 검사). |

**반환** — `self`(체이닝 가능). 값을 실제로 썼는지와 상관없이 같습니다 — 썼는지가 궁금하면 `if v ~= src:Get() then src:Set(v) end`로 풀어 쓰면 됩니다.

**동작**

- `v == 현재 값`이면 **아무것도 하지 않습니다** — 값도 [`Revision`](#sourcerevision)도 그대로이고 하류에 아무것도 전파하지 않습니다. 다르면 [`:Set(v)`](#sourcesetv)과 똑같습니다.
- 비교는 Luau의 `==` 그대로입니다. 테이블은 참조로 비교하므로 제자리에서 고친 테이블을 다시 넣으면 "같다"로 보고 건너뜁니다 — 그때는 [`:Emit()`](#sourceemit)을 쓰세요. 두 값이 **같은 `__eq` 메타메서드**를 가지면 그 메타메서드가 같음을 정합니다(값 객체가 자기 뜻대로 같음을 정의할 수 있습니다; 메타메서드가 서로 다르면 Luau는 그것을 부르지 않고 다르다고 봅니다).
- `NaN`은 자기 자신과 같지 않으므로 `NaN`을 넣으면 늘 씁니다.
- 값 검사는 비교보다 **먼저** 합니다 — Modifier를 넣으면 현재 값과 같든 다르든 `Quad0181 Source: cannot Set a Modifier as a Source value`.
- [`q.Store`](./04-store.md)의 필드도 `Source`이므로 `store.hp:SetIfChanged(v)`처럼 그대로 씁니다.

**쓰는 자리** — 기본은 `:Set`이고, 이 메서드는 **되먹임 고리를 끊어야 하는 좁은 자리**를 위한 것입니다.

- [`Effect`](./05-observer-effect.md#qeffectfn-deps)가 자기 의존성을 다듬어 되쓸 때 — `:Set`으로 쓰면 같은 값도 전파해 지연 재실행이 끝나지 않고 1만 회에서 `Quad0263`으로 멈춥니다. `:SetIfChanged`면 값이 자리 잡는 순간 반복이 끝납니다.
- 엔진 → `Source` 브릿지와 입력 핸들러 — 프로퍼티 변경 신호나 입력 이벤트가 이미 들고 있는 값을 다시 올려 보낼 때. [`q.Out`](../roblox/05-onchange.md#qoutname-src)이 안에서 이것으로 되씁니다.
- Observer 콜백이 **자기 상류**를 되쓰는 것은 이 메서드를 써도 여전히 정의되지 않은 동작입니다 — [`state:Observer(fn)`](./05-observer-effect.md#stateobserverfn)의 "Observer는 최종 소비자입니다" 문단이 정본입니다.

**예제**

```luau
local hp = q.Source(120)
q.Effect(function()
	hp:SetIfChanged(math.clamp(hp:Get(), 0, 100)) -- 100으로 자리 잡으면 더 쓰지 않는다
end, hp)
print(hp:Get()) --> 100
```

---

## `source:SetAndDispose(v)`

> **[2026-10-01 기준]** `:SetAndDispose`는 게시된 3.2.0에는 없습니다 — 다음 릴리즈부터([변경 이력](../../../CHANGELOG.md) `[Unreleased]`). 그전엔 `local old = src:Get(); src:Set(v); q.dispose(old)`가 같은 일을 합니다(옛 값이 `nil`이 아닐 때).

**시그니처**

```luau
SetAndDispose: (self: Source<T>, v: T) -> Source<T>
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `v` | `T` | 새 값. Modifier는 거부됩니다(`:Set`과 같은 검사). |

**반환** — `self`(체이닝 가능).

**동작**

- [`:Set(v)`](#sourcesetv)을 한 뒤, **바뀌기 전 값**을 [`q.dispose`](./10-lifetime-sentinels.md#qdisposevalue)로 파괴합니다. 옛 값을 `:Get()`으로 미리 잡아 둘 필요가 없습니다.
- 순서가 이 메서드의 요점입니다. 전파가 끝나야 그 값을 앉혀 두었던 하류(숫자 키 자리, Slot)가 자리를 놓아 주고, 그 뒤라야 `dispose`가 받아 줍니다 — 앉아 있는 값을 먼저 `q.dispose`하면 `Quad0179`로 거부되고, `:Set` 전에 `inst:Destroy()`로 직접 지우는 것은 정의되지 않은 동작입니다.
- 값 검사는 쓰기보다 **먼저** 합니다 — Modifier를 넣으면 `Quad0181 Source: cannot Set a Modifier as a Source value`이고, 값도 옛 값도 그대로입니다.
- 쓰기는 `:Set`과 같아서 같은 값도 전파합니다.
- 옛 값을 파괴하지 않고 넘어가는 경우는 둘입니다.
  - 옛 값이 `nil`이나 [`q.None`](./10-lifetime-sentinels.md#qnone)일 때 — 빈 자리라 지울 것이 없습니다. 처음 채우는 호출도 그대로 쓸 수 있습니다.
  - 옛 값이 방금 넣은 `v`와 **같은 참조**일 때 — 지우면 방금 넣은 값을 지우게 됩니다.
- 그 밖의 옛 값은 `q.dispose`의 계약 그대로입니다. Slot이면 트리째, 백엔드 요소(Roblox면 Instance)면 파괴합니다. `dispose`가 받지 않는 값이면 그 에러가 그대로 납니다 — 숫자·문자열·평범한 테이블처럼 파괴할 수 없는 값이면 `Quad0180 dispose: this backend cannot dispose this value`, 아직 다른 자리가 쥐고 있으면 `Quad0179 dispose: this value is still held by …`.
- ⚠️ 이 에러들은 **쓰기가 이미 끝난 뒤에** 납니다. 새 값은 들어가 있고 하류도 전파를 받았으며, 되돌리지 않습니다.
- ⚠️ `Source`와 값이 놓인 자리 사이에 [`Debounce`](../sugar/03-debounce-throttle.md)나 [`Blocker`](../sugar/06-blocker.md)처럼 전파를 늦추거나 막는 것이 있으면, `:SetAndDispose`가 돌아올 때 옛 값은 아직 자리에 있어 `Quad0179`가 납니다. 그런 경로에서는 자리가 실제로 빈 뒤에 `q.dispose`를 직접 부르세요.
- [`q.Store`](./04-store.md)의 필드도 `Source`이므로 `store.panel:SetAndDispose(v)`처럼 그대로 씁니다.

**예제**

```luau
local panel = q.Source<<Instance?>>(nil)
local screen = D.Frame { panel } -- panel이 쥔 Frame이 이 자리에 앉는다

panel:SetAndDispose(D.Frame {}) -- 처음: 옛 값이 nil이라 지울 것이 없다
panel:SetAndDispose(D.Frame {}) -- 바꾸기: 새 Frame이 앉은 뒤 옛 Frame이 파괴된다
panel:SetAndDispose(nil)        -- 비우기: 자리를 비운 뒤 마지막 Frame을 파괴한다
```

---

## `source:Emit()`

**시그니처**

```luau
Emit: (self: Source<T>) -> Source<T>
```

**반환** — `self`.

**동작**

- 값은 **건드리지 않고** 리비전만 올려 하류에 전파합니다. 담아둔 테이블·배열을 제자리에서 고친 뒤 알릴 때 쓰는 문입니다.
- 루트 `Source`에만 있는 개념입니다. 파생 `State`에는 `:Emit`이 없습니다 — 파생 노드의 값은 자기 것이 아니기 때문입니다.

**예제**

```luau
local items = q.Source({ "a" })
table.insert(items:Get(), "b") -- 제자리 변경 — 이것만으로는 아무도 모른다
items:Emit()                   -- 이제 하류가 안다
```

---

## `source.Revision`

**시그니처**

```luau
read Revision: number
```

**동작**

- `:Set`/`:Emit`이 일어날 때마다(`:SetIfChanged`는 실제로 쓸 때만) 바뀌는 **불투명한 표식**입니다. 하류는 "이 값을 마지막으로 본 뒤에 움직였는가"를 이 값의 **일치/불일치**로만 판정합니다.
- 크고 작음을 비교하지 마세요 — 갱신 방향은 계약이 아니며 32비트 범위를 순환합니다. 저장해 둔 값과 같으면 그 사이 아무 일도 없었다는 뜻, 다르면 움직였다는 뜻, 그게 전부입니다.
- 갓 만든 `Source`의 값은 `0`입니다.

**관련** — [Quadnomicon Vol. 1 — Revision과 EpochMap](../../quadnomicon/01-revision-and-epochmap.md)

---

## Source가 물려받는 State 메소드

`Source`는 타입으로도 런타임으로도 `State`를 포함합니다 — 파생 메소드는 별도 변환 없이 `Source` 위에서 바로 부를 수 있습니다.

| 메소드 | 문서 |
|---|---|
| `:Get()` | [03-state](./03-state.md#stateget) |
| `:Compute(fn, ...deps)` | [03-state](./03-state.md#statecomputefn-deps) |
| `:Depend(...)` | [03-state](./03-state.md#statedepend) |
| `:Apply(factory)` | [03-state](./03-state.md#stateapplyfactory) |
| `:Observer(fn)` | [05-observer-effect](./05-observer-effect.md#stateobserverfn) |
| `:Gate(setup)` | [03-state](./03-state.md#stategatesetup) |

한 가지 예외는 `:Get()`입니다. `Source`는 자기 값을 그대로 돌려주는 자기만의 `:Get()`을 갖습니다(캐시도 재계산도 없습니다). 나머지는 `State`의 구현을 그대로 씁니다.

```luau
local hp = q.Source(100)
local label: q.State<string> = hp:Compute(function(self)
	return `HP {self:Get()}`
end)
```

**관련** — [03-state](./03-state.md) · [04-store](./04-store.md) · [How-To 02 폼 검증](../../how-to/02-form-validation-pattern.md)
