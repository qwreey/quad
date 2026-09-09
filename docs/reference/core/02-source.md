---
title: Source
description: 값을 직접 쓸 수 있는 반응형 루트 노드 — Set/Emit/Revision, 그리고 State 메소드 전부
---
# Source&lt;T&gt;

`Source`는 **값을 직접 쓸 수 있는 유일한 반응형 노드**입니다. 파생 노드인 [`State`](./03-state.md)는 읽기 전용이고, 전파는 언제나 어떤 `Source`의 `:Set`/`:Emit`에서 시작합니다.

이 페이지의 심볼: [`q.Source(value)`](#qsourcevalue) · [`source:Set(v)`](#sourcesetv) · [`source:Emit()`](#sourceemit) · [`source.Revision`](#sourcerevision) · [Source가 물려받는 State 메소드](#source가-물려받는-state-메소드)

```luau
-- 설치 경로는 프로젝트 구성에 따라 다르다(getting-started/00-installation 참고)
local Quad = require(<quad-base 모듈 경로>)
local QuadRoblox = require(<quad-roblox 모듈 경로>).QuadRoblox
local QuadTypes = require(<quad-types 모듈 경로>) -- 타입 주석용(`QuadTypes.State<T>` 등)
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
```

`Source`의 생성·읽기·쓰기와 `:Compute`/`:With` 같은 파생 자체는 백엔드가 없어도 동작합니다. 백엔드가 필요한 것은 이 노드에 붙는 **구독 핸들의 생명주기**입니다 — `:Observer`로 만든 핸들을 실제로 살리는 것(`:Subscribe`, 인스턴스 바인딩)부터가 백엔드 몫입니다([05-observer-effect](./05-observer-effect.md) 참고).

---

## `q.Source(value)`

**시그니처**

```luau
Source: <T>(v: T) -> Source<T>

export type Source<T> = State<T> & {
	Revision: number,
	Set: (self: Source<T>, v: T) -> Source<T>,
	Emit: (self: Source<T>) -> Source<T>,
}
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `v` | `T` | 초기값. `nil`도 값으로 허용됩니다(`q.Source(nil :: number?)` — 타입은 명시해야 `Source<number?>`가 됩니다). |

**반환** — `Source<T>`. 만들어진 시점의 `Revision`은 `0`입니다.

**동작**

- 값으로 **Modifier는 담을 수 없습니다**. 생성자에서 걸리면
  `Source: cannot hold a Modifier as a Source value`
- 판정 술어는 셋 다 참입니다 — `q.isSource(s)`, `q.isEpoch(s)`, `q.isState(s)`. 세 번째는 술어 합성의 결과이고, 값 자체가 `State` 브랜드에 등록되지는 않습니다.
- `print(source)`는 `Source(<현재 값>)` 모양으로 찍힙니다. 읽기만 하며 계산을 유발하지 않습니다.

**예제**

```luau
local hp = q.Source(100)
print(hp:Get()) --> 100
```

**관련** — [Getting Started 01 핵심 모델](../../getting-started/01-core-mental-model.md) · [Quadnomicon Vol. 1](../../quadnomicon/01-revision-and-epochmap.md)

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

- **같은 값을 다시 넣어도 언제나 리비전을 올리고 전파합니다.** 값 비교로 중복을 죽이지 않습니다 — 중복 제거는 하류의 판단이고(에폭 판정·게이트), `==` 비교는 테이블을 제자리에서 고친 변경을 조용히 삼켜버리기 때문입니다.
- `:Get()`은 넣은 참조를 그대로 돌려줍니다(사본이 아닙니다). 테이블을 담아 두고 제자리에서 고쳤다면 [`:Emit()`](#sourceemit)으로 신호만 보내면 됩니다.
- Modifier를 넣으면 `Source: cannot Set a Modifier as a Source value`

**예제**

```luau
local hp = q.Source(100)
hp:Set(80):Set(60) -- self를 돌려주므로 이어 쓸 수 있다
print(hp:Get()) --> 60
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
Revision: number
```

**동작**

- `:Set`/`:Emit`이 일어날 때마다 바뀌는 **불투명한 표식**입니다. 하류는 "이 값을 마지막으로 본 뒤에 움직였는가"를 이 값의 **일치/불일치**로만 판정합니다.
- 크고 작음을 비교하지 마세요 — 증가가 아니라 `bit32` 랩어라운드로 감소하는 방향으로 갱신됩니다. 저장해 둔 값과 같으면 그 사이 아무 일도 없었다는 뜻, 다르면 움직였다는 뜻, 그게 전부입니다.
- 갓 만든 `Source`의 값은 `0`입니다.

**관련** — [Quadnomicon Vol. 1 — Revision과 EpochMap](../../quadnomicon/01-revision-and-epochmap.md)

---

## Source가 물려받는 State 메소드

`Source`는 타입으로도 런타임으로도 `State`를 포함합니다 — 파생 메소드는 별도 변환 없이 `Source` 위에서 바로 부를 수 있습니다.

| 메소드 | 문서 |
|---|---|
| `:Get()` | [03-state](./03-state.md#stateget) |
| `:Compute(fn, ...deps)` | [03-state](./03-state.md#statecomputefn-deps) |
| `:With(...)` | [03-state](./03-state.md#statewith) |
| `:Apply(factory)` | [03-state](./03-state.md#stateapplyfactory) |
| `:Observer(fn)` | [05-observer-effect](./05-observer-effect.md#stateobserverfn) |
| `:Gate(setup)` | [03-state](./03-state.md#stategatesetup) |

한 가지 예외는 `:Get()`입니다. `Source`는 자기 값을 그대로 돌려주는 자기만의 `:Get()`을 갖습니다(캐시도 재계산도 없습니다). 나머지는 `State`의 구현을 그대로 씁니다.

```luau
local hp = q.Source(100)
local label: QuadTypes.State<string> = hp:Compute(function(self)
	return `HP {self:Get()}`
end)
```

**관련** — [03-state](./03-state.md) · [04-store](./04-store.md) · [How-To 02 폼 검증](../../how-to/02-form-validation-pattern.md)
