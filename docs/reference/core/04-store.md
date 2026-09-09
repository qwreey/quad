---
title: Store
description: 이름 붙은 Source 모음 — 명시적 초기화, 점 접근, Of/Names와 예약 키
---
# Store&lt;T&gt;

`Store`는 **이름 붙은 `Source`들의 가방**입니다. 값을 담는 새 반응형 노드가 아니라, 이미 만든 [`Source`](./02-source.md)들을 한 레코드로 묶어 타입이 붙은 점 접근(`store.hp`)을 주는 것이 전부입니다.

이 페이지의 심볼: [`q.Store(defaults)`](#qstoredefaults) · [`store.key`](#storekey-선언된-필드) · [`store:Of<<U>>(name)`](#storeofuname) · [`store:Names()`](#storenames) · [예약 키](#예약-키)

```luau
-- 설치 경로는 프로젝트 구성에 따라 다르다(getting-started/00-installation 참고)
local Quad = require(<quad-base 모듈 경로>)
local QuadRoblox = require(<quad-roblox 모듈 경로>).QuadRoblox
local QuadTypes = require(<quad-types 모듈 경로>) -- 타입 주석용(`QuadTypes.Source<T>` 등)
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
```

---

## `q.Store(defaults)`

**시그니처**

```luau
Store: (() -> Store<{}>) & (<T>(defaults: T) -> Store<T>)

export type Store<T> = T & {
	Of: <U>(self: any, name: string) -> Source<U>,
	Names: (self: any) -> { string },
	__reservedCheck: CheckReservedKeys<keyof<T>>,
}
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `defaults` | `{ [string]: Source<any> }` | 초기 필드. 메타테이블 없는 **평범한 테이블**이어야 하고, 값은 **전부 `Source`**여야 합니다. 생략하면 빈 Store입니다. |

**반환** — `Store<T>`. `T`는 넘긴 레코드 타입 그대로입니다(타입 함수 없이 평범한 레코드).

**동작**

- **초기화는 명시적입니다.** 넘긴 테이블이 그대로 store가 되고, 메소드는 메타테이블 쪽에 있습니다. 그래서 `store.hp`는 **넣은 그 `Source` 객체 자신**이고, `:Names()`에 메소드 이름이 섞이지 않습니다.
- 값 검증은 화이트리스트입니다 — `Source`가 아닌 값은 그 자리에서 거부합니다. 통과시켰다면 첫 `:Get()`에서야 죽었을 것이기 때문입니다.
- 검증 에러 문구:

  | 상황 | 문구 |
  |---|---|
  | 값이 `Source`가 아님 | `Store: default for "{tostring(name)}" is not a Source (got {typeof(value)})` |
  | 테이블이 아님 | `Store: defaults must be a table of Sources (got {typeof(defaults)})` |
  | 메타테이블이 달림(`Source` 하나를 그대로 넘긴 경우 등) | `Store: defaults must be a plain table without a metatable (a bare Source instead of { name = Source }?)` |
  | 브랜드 값(AttrKey·Mapper 디스크립터 등) | `Store: defaults must be a plain { name = Source } table (got an AttrKey/Mapper descriptor)` |
  | 키가 문자열이 아니거나 빈 문자열 | `Store: {what} must be a non-empty string` (`{what}`은 생성자에서 `key`, `:Of`에서 `Of name`) |
  | 예약된 이름 | `Store: "{name}" is a reserved store key` |

- `Source`의 값 제약이 그대로 따라옵니다 — Modifier는 담을 수 없습니다. 이 검사는 `Source` 생성자가 하므로 `:Of`로 만든 필드에도 적용됩니다.
- `print(store)`는 정렬된 키 목록으로 `Store{hp, mp}` 모양입니다.

**예제**

```luau
local store = q.Store({
	hp = q.Source(100),
	name = q.Source("player"),
})

print(store.hp:Get()) --> 100
store.hp:Set(80)
```

**관련** — [How-To 02 폼 검증](../../how-to/02-form-validation-pattern.md) · [02-source](./02-source.md)

---

## store.key (선언된 필드)

**동작**

- 선언한 키는 **평범한 레코드 필드**입니다 — 넣은 `Source`가 그 자리에 그대로 있고, 타입도 넘긴 레코드 타입 그대로 붙습니다. `store.hp`는 `Source<number>`이지 래퍼가 아닙니다.
- **선언하지 않은 키를 점으로 읽으면 `nil`입니다.** 점 접근에는 지연 생성이 없습니다 — 없는 이름을 그 자리에서 만들어주는 문은 [`:Of`](#storeofuname) 하나뿐입니다.

```luau
local store = q.Store({ hp = q.Source(100) })
print(store.hp:Get()) --> 100
print((store :: any).mp) --> nil (선언 안 한 이름 — 만들어지지 않는다)
```

---

## `store:Of<<U>>(name)`

**시그니처**

```luau
Of: <U>(self: any, name: string) -> Source<U>
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `name` | `string` | 필드 이름. 빈 문자열이 아닌 문자열이어야 하고, 예약 이름이면 안 됩니다. |

**반환** — 그 이름의 `Source<U>`. 없으면 **그 자리에서 만들어 저장하고** 돌려줍니다.

**동작**

- 계산된 이름을 쓰는 **유일한 문**이자 지연 생성이 남아 있는 유일한 자리입니다. 타입이 이름을 알 수 없으므로 결과 타입은 호출자가 타입 인자로 직접 줍니다 — 그만큼 타입 안전은 여기서 포기하는 것입니다.
- 새로 만들어진 `Source`의 값은 **`nil`**입니다. `store:Of<<number>>("mp"):Get()`은 타입이 `number`여도 첫 호출에선 `nil`입니다 — 필요하면 바로 `:Set`하세요.
- 같은 이름으로 다시 부르면 **같은 객체**가 옵니다.
- 이름 검증: `Store: {what} must be a non-empty string`(여기서 `{what}`은 `Of name`) / `Store: "{name}" is a reserved store key`

**예제**

```luau
local store = q.Store({ hp = q.Source(100) })

local mp = store:Of<<number>>("mp") -- 결과 타입은 호출자가 직접 준다
mp:Set(50) -- 갓 만들어진 Source의 값은 nil이므로 먼저 채운다
print(store:Of<<number>>("mp") == mp) --> true (같은 객체)
```

---

## `store:Names()`

**시그니처**

```luau
Names: (self: any) -> { string }
```

**반환** — 지금 이 store에 있는 필드 이름들.

**동작**

- 생성자에 선언한 키와 `:Of`가 만든 키가 **둘 다** 들어갑니다.
- 메소드(`Of`/`Names`)는 메타테이블 쪽에 있어 세지 않고, 타입에만 있는 팬텀 필드도 들어가지 않습니다.
- **순서는 보장되지 않습니다** — 필요하면 직접 정렬하세요.

**예제**

```luau
local store = q.Store({ hp = q.Source(100) })
store:Of("mp")

local names = store:Names()
table.sort(names)
print(table.concat(names, ",")) --> hp,mp
```

---

## 예약 키

`Of`, `Names`, `__reservedCheck` 셋은 store 필드 이름으로 쓸 수 없습니다. 앞의 둘은 메소드 이름이고, 마지막은 타입 검사용 팬텀 필드입니다.

- **런타임**: 생성자와 `:Of` 둘 다 같은 문으로 막습니다 — `Store: "{name}" is a reserved store key`
- **타입 검사 시점**: `Store<T>`에 얹힌 타입 함수가 주석 자리에서 먼저 경고를 냅니다. 타입 함수는 에러를 던질 수 없어 출력으로만 알립니다 — `quad.Store: "{v}" is a reserved key`

**관련** — [02-source](./02-source.md) · [03-state](./03-state.md)
