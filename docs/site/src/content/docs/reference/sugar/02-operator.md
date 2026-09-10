---
title: "Operator"
description: "이름 붙은 콤비네이터 열넷 — state:Apply로 붙이는 :Compute 슈거의 시그니처와 게이트"
---
`state:Compute(function(h) return not h:Get() end)` 같은 보일러플레이트를 없애고, **의존성 캡처가 어긋날 수 없는 재사용 가능한 이름**을 주는 콤비네이터 모음입니다. 전부 `state:Apply(factory)`로 붙습니다.

이 페이지의 심볼: [`q.Operator.Not`](#qoperatornot) · [`q.Operator.Sum(...)`](#qoperatorsum) · [`q.Operator.Product(...)`](#qoperatorproduct) · [`q.Operator.Min(...)`](#qoperatormin) · [`q.Operator.Max(...)`](#qoperatormax) · [`q.Operator.Clamp(lo, hi)`](#qoperatorclamplo-hi) · [`q.Operator.Band(...)`](#qoperatorband) · [`q.Operator.Bor(...)`](#qoperatorbor) · [`q.Operator.Bxor(...)`](#qoperatorbxor) · [`q.Operator.Bnot`](#qoperatorbnot) · [`q.Operator.Shl(n)`](#qoperatorshln) · [`q.Operator.Shr(n)`](#qoperatorshrn) · [`q.Operator.Alternative(default)`](#qoperatoralternativedefault) · [`q.Operator.Index<<V>>(key)`](#qoperatorindexvkey)

`quad-base`에 있으므로 백엔드와 무관하게 존재합니다.

```luau
-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 참고)
local Quad = require(<quad-base 모듈 경로>)
local QuadTypes = require(<quad-types 모듈 경로>)
local QuadRoblox = require(<quad-roblox 모듈 경로>).QuadRoblox
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
local Op = q.Operator
type State<T> = QuadTypes.State<T>
```

---

## 공통 계약

**모양은 둘뿐입니다.**

- **단항**(`Not`/`Bnot`) — 팩토리 자체가 곧 연산이므로 **호출하지 않고 그대로 넘깁니다**: `state:Apply(Op.Not)`.
- **나머지** — 인자를 받아 팩토리를 돌려주는 커링 형태: `state:Apply(Op.Sum(tax, 500))`.

**왜 `:Compute`가 아니라 `:Apply`인가.** 팩토리가 자기 deps를 직접 `:Compute`에 넘기므로, 한 번 이름 붙인 연산자를 여러 State에 `:Apply`해도 deps가 따라갑니다 — 이름과 의존성이 갈라질 수 없습니다.

```luau
local tax, shipping = q.Source(2), q.Source(3)
local basePrice, otherPrice = q.Source(10), q.Source(100)

local addTaxAndShipping = Op.Sum(tax, shipping) -- 한 번 이름 붙이고
local a: State<number> = basePrice:Apply(addTaxAndShipping) -- 15
local b: State<number> = otherPrice:Apply(addTaxAndShipping) -- 105
tax:Set(5) -- 재사용한 쪽까지 같이 갱신된다: 18 / 108
```

**숫자 인자는 plain 숫자든 `State<number>`든 됩니다.** plain 값은 상수로 캡처되고, State는 의존성으로 등록돼 바뀌면 결과가 갱신됩니다. 보조 타입 별칭 둘이 그 계약입니다.

```luau
export type NumArg = number | StateData<number>
export type NumOp = (self: StateData<number>) -> State<number>
```

**결과 State의 타입은 호출부가 명시합니다** — `local total: State<number> = price:Apply(Op.Sum(tax))`.

**에러가 나는 시점은 셋으로 갈립니다.**

| 무엇 | 언제 | 예 |
|---|---|---|
| 인자 타입·`nil` 인자 | **팩토리를 부르는 줄** | `Operator.Sum: argument #1 must be a number or a State<number> (got string)`<br>`Operator.Sum: argument #2 is nil` |
| `:Apply` 대상이 State가 아님 | **`:Apply` 하는 줄** | `Operator.Sum: Apply target must be a State (got table)` |
| 값이 계약에 안 맞음(`Index`만) | **값을 읽는 시점** | `Operator.Index: value is not a table (got number) — cannot read [x]` |

`nil` 인자가 조용히 사라져 뒤 인자를 당겨오는 일은 없습니다 — 자리마다 검사해서 `argument #N is nil`로 던집니다.

**산술·비트 연산자는 숫자 전용입니다.** `Sum`/`Product`/`Min`/`Max`/`Clamp`와 `Band`~`Shr`는 인자뿐 아니라 **`:Apply`를 받는 State의 값도** 숫자여야 합니다. `UDim2`나 `Color3` 같은 타입에 쓰면 타입 검사에서 `None of the overloads for function that accept 2 arguments are compatible.`로 막힙니다 — 그런 연산은 `state:Compute`로 직접 쓰십시오. 값 타입을 가리지 않는 것은 `Not`·`Alternative`·`Index` 셋입니다.

---

## 전체 목록

| 연산자 | 모양 | 뜻 |
|---|---|---|
| `Not` | `state:Apply(Op.Not)` | 논리 부정(단항) |
| `Sum` | `Op.Sum(...)` | self + 인자들 |
| `Product` | `Op.Product(...)` | self × 인자들 |
| `Min` | `Op.Min(...)` | self와 인자들의 최소 |
| `Max` | `Op.Max(...)` | self와 인자들의 최대 |
| `Clamp` | `Op.Clamp(lo, hi)` | `math.clamp` |
| `Band` | `Op.Band(...)` | `bit32.band` 폴딩 |
| `Bor` | `Op.Bor(...)` | `bit32.bor` 폴딩 |
| `Bxor` | `Op.Bxor(...)` | `bit32.bxor` 폴딩 |
| `Bnot` | `state:Apply(Op.Bnot)` | `bit32.bnot`(단항) |
| `Shl` | `Op.Shl(n)` | `bit32.lshift` |
| `Shr` | `Op.Shr(n)` | `bit32.rshift` |
| `Alternative` | `Op.Alternative(default)` | 널 병합 — `State<T?>` → `State<T>` |
| `Index` | `Op.Index<<V>>(key)` | 반응형 필드 읽기 |

---

## `q.Operator.Not`

**시그니처**

```luau
Not: (self: any) -> State<boolean>
```

단항이라 **팩토리 자체를 넘깁니다**. 값 타입을 가리지 않습니다 — 무엇이 오든 Luau의 `not`을 적용해 `State<boolean>`을 냅니다.

```luau
local isVisible = q.Source(true)
local isHidden: State<boolean> = isVisible:Apply(Op.Not) -- false
```

## `q.Operator.Sum(...)`

**시그니처**

```luau
Sum: (...NumArg) -> NumOp
```

self를 시작값으로 인자들을 순서대로 더합니다. 인자 개수 제한은 없습니다.

```luau
local basePrice, tax, shipping = q.Source(1000), q.Source(100), q.Source(50)
local total: State<number> = basePrice:Apply(Op.Sum(tax, shipping, 500)) -- 1650
tax:Set(200) -- total:Get() == 1750
```

## `q.Operator.Product(...)`

**시그니처**

```luau
Product: (...NumArg) -> NumOp
```

self에 인자들을 순서대로 곱합니다.

## `q.Operator.Min(...)`

**시그니처**

```luau
Min: (...NumArg) -> NumOp
```

self와 인자들의 최소값(`math.min` 폴딩).

## `q.Operator.Max(...)`

**시그니처**

```luau
Max: (...NumArg) -> NumOp
```

self와 인자들의 최대값(`math.max` 폴딩).

## `q.Operator.Clamp(lo, hi)`

**시그니처**

```luau
Clamp: (lo: NumArg, hi: NumArg) -> NumOp
```

`math.clamp(self, lo, hi)`. 인자가 정확히 둘이라 하나만 주면 `Operator.Clamp: argument #2 is nil`입니다.

```luau
local posX, maxX = q.Source(150), q.Source(100)
local boundX: State<number> = posX:Apply(Op.Clamp(0, maxX)) -- 100
```

## `q.Operator.Band(...)`

**시그니처**

```luau
Band: (...NumArg) -> NumOp
```

`bit32.band` 폴딩. Luau엔 비트 연산자가 없어 `bit32` 위의 얇은 층입니다.

```luau
local flags = q.Source(0b1100)
local masked: State<number> = flags:Apply(Op.Band(0b1010)) -- 8
```

## `q.Operator.Bor(...)`

**시그니처**

```luau
Bor: (...NumArg) -> NumOp
```

`bit32.bor` 폴딩.

## `q.Operator.Bxor(...)`

**시그니처**

```luau
Bxor: (...NumArg) -> NumOp
```

`bit32.bxor` 폴딩.

## `q.Operator.Bnot`

**시그니처**

```luau
Bnot: NumOp
```

`bit32.bnot`. 단항이므로 **호출하지 않고 그대로 넘깁니다** — `flags:Apply(Op.Bnot)`.

## `q.Operator.Shl(n)`

**시그니처**

```luau
Shl: (n: NumArg) -> NumOp
```

`bit32.lshift(self, n)`. `n`은 plain 숫자든 `State<number>`든 됩니다.

```luau
local flags = q.Source(0b1100)
local shifted: State<number> = flags:Apply(Op.Shl(2)) -- 0b110000
```

## `q.Operator.Shr(n)`

**시그니처**

```luau
Shr: (n: NumArg) -> NumOp
```

`bit32.rshift(self, n)`.

## `q.Operator.Alternative(default)`

**시그니처**

```luau
Alternative: <T>(default: T | StateData<T>) -> (self: StateData<T?>) -> State<T>
```

널 병합입니다 — self가 `nil`이면 `default`, 아니면 self. `default`가 State면 의존성으로 등록되므로 기본값 쪽이 바뀌어도 결과가 따라옵니다. 값 타입을 가리지 않습니다.

`default`가 `nil`이면 팩토리 호출 줄에서 `Operator.Alternative: default must not be nil`입니다.

```luau
local optionalName = q.Source(nil :: string?)
local safeName: State<string> = optionalName:Apply(Op.Alternative("Guest")) -- "Guest"
```

## `q.Operator.Index<<V>>(key)`

**시그니처**

```luau
Index: <V>(key: any) -> (self: any) -> State<V>
```

반응형 필드 읽기입니다. **결과 타입만 계약이 다릅니다** — 키에서 값 타입을 추론하는 형태는 지금 솔버로 표현할 수 없어서, 값 타입을 호출자가 명시적 타입 인자로 직접 적습니다.

런타임은 상류 값에 `[key]`를 한 번 읽는 것입니다. 상류 State 전체가 바뀔 때 갱신되고, 없는 키는 `nil`입니다 — 게이트가 없습니다(타입을 적은 사람이 책임집니다).

```luau
type Palette = { Primary: string, Size: number }
local palette = q.Source({ Primary = "red", Size = 10 } :: Palette)

local primary: State<string> = palette:Apply(Op.Index<<string>>("Primary"))
local size: State<number> = palette:Apply(Op.Index<<number>>("Size"))
local missing: State<string?> = palette:Apply(Op.Index<<string?>>("Nope")) -- nil
```

에러 둘. `key`가 `nil`이면 팩토리 호출 즉시입니다.

```
Operator.Index: key must not be nil
```

상류 값이 테이블이 아니면 **읽는 시점에** 던집니다(`[...]` 자리엔 그 키가 들어갑니다).

```
Operator.Index: value is not a table (got number) — cannot read [x]
```

---

## 의도적으로 없는 것

- **`And`/`Or`** — 상태 결합은 `if`/`else`를 쓰던 이유와 부딪힙니다.
- **비교 연산**(`Eq`/`Lt` …) — 결과를 먹일 분기가 없으면 의미가 없습니다.
- **`Sub`/`Div`** — 이름 붙은 콤비네이터로서의 선례가 없습니다.

셋 다 `state:Compute`로 직접 쓰면 됩니다.

---

## 관련

- [컴포넌트 경계 규약](/how-to/01-component-conventions/) — `:Apply` 자리와 컴포넌트 경계
- [v1에서 옮겨오기](/how-to/08-migrating-from-v1/) — v1의 연산 헬퍼가 어디로 갔는지
