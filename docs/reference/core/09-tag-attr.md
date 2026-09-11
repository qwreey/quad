---
title: Tag / Attr
description: 숫자 키 값 객체 둘 — 태그 집합과 속성 그룹, AttrKey와 타입드 스칼라 슈가
---

# Tag / Attr

`Tag`와 `Attr`은 props의 **숫자 키 자리에 놓는 값 객체**입니다. 인스턴스에 이름표를 붙이고(`Tag`), 이름 붙은 값을 심습니다(`Attr`). 둘 다 불변이고, 모든 연산이 새 값을 돌려줍니다.

`Modifier`와 달리 이 둘은 프로퍼티가 아니라 **엔진의 별도 채널**로 갑니다. quad-base는 그 채널을 직접 건드리지 않고 주입된 엔진 op 셋(`addTag`/`removeTag`/`setAttr`)에 넘깁니다 — 백엔드가 그걸 채웁니다. Roblox 백엔드는 각각 `CollectionService`와 `SetAttribute`로 이어집니다.

:::note
백엔드를 설치하기 전에 `Tag`/`Attr`을 실제로 인스턴스에 적용하면 "아직 설치되지 않았다"는 안내 에러가 납니다. 값을 만들고 합성하는 것 자체는 백엔드 없이도 됩니다.
:::

이 페이지의 심볼: [`q.Tag`](#qtagnames) · [`tag:Added`](#tagaddednames) · [`tag:Removed`](#tagremovednames) · [`tag:Contains`](#tagcontainsnames) · [`tag:Names`](#tagnames) · [`tag:Apply`](#tagapplyfactory) · [`q.Tag.Merged`](#qtagmergedtags) · [`q.Attr`](#qattr) · [`attr:NameMap`](#attrnamemap) · [`q.Attr.Merged`](#qattrmerged) · [`q.Attr.Overridden`](#qattroverridden) · [`q.AttrKey`](#qattrkeyname) · [`q.StringAttr`](#qstringattrname-value) · [`q.NumberAttr`](#qnumberattrname-value) · [`q.BooleanAttr`](#qbooleanattrname-value)

이 페이지의 모든 예제는 아래 프롤로그를 전제합니다.

```luau
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("@game/ReplicatedStorage/Client/UI/Quad")
local QuadTypes = require("@game/ReplicatedStorage/roblox_packages/quad_types") -- 설정 모듈이 다시 내보내지 않는 타입(`QuadTypes.None` 등)
local D = q.D
```

---

## Tag

`Tag`는 **이름의 집합**입니다. 순서가 없고 중복이 없습니다.

```luau
type TagNames = string | { read [number]: TagNames } | TagMarker

type Tag = {
    read __quadTag: true,
    Added: (self: Tag, names: TagNames) -> Tag,
    Removed: (self: Tag, names: TagNames) -> Tag,
    Contains: (self: Tag, ...string) -> boolean,
    Names: (self: Tag) -> () -> string?,
    Apply: <U>(self: Tag, factory: (Tag) -> U) -> U,
}
```

이름 자리에는 어디서나 셋 중 하나가 옵니다 — **문자열**, **다른 `Tag`**(그 집합 전체), 또는 **그것들의 평범한 리스트**(중첩 가능). 세 문을 하나가 지키므로 생성자든 `:Added`든 규칙이 같습니다.

```
Tag: names must be strings, Tags, or a plain {...} list of those (got {typeof(v)})
```

빈 문자열은 태그 이름이 아닙니다 — `Tag: names must be strings — an empty string is not a tag name`.

**참조 계수로 붙습니다.** 한 인스턴스의 여러 자리에서 같은 이름을 얹으면 자리마다 세어지고, 마지막 자리가 물러날 때 비로소 엔진에서 떨어집니다. 같은 불변 `Tag` 객체를 두 자리에 놓아도 두 번으로 셉니다. 엔진 호출은 이름별로 묶여 한 번에 나갑니다.

**자리의 `Tag`가 갈릴 때 엔진으로 나가는 것은 옛 집합과 새 집합의 차이뿐입니다** — 빠진 이름만 `removeTag`, 생긴 이름만 `addTag`, 각각 한 번에 묶여서. 두 집합이 같으면 호출이 없습니다.
<!-- mock 실측 2026-09-11: gs.handlerslot.luau — {Card,Even}→{Card,Odd}는 removeTag:Even addTag:Odd, 같은 집합이면 호출 0 -->

## `q.Tag(...names)`

**시그니처**

```luau
Tag: setmetatable<{ Merged: (...TagMarker) -> Tag }, { __call: (self: any, ...TagNames) -> Tag }>
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `...names` | `TagNames` | 문자열 / `Tag` / 그것들의 평범한 리스트. 개수 제한 없음 |

**반환** — 새 `Tag`(frozen).

**동작**

- 인자가 없어도 됩니다 — `q.Tag()`는 빈 태그 집합입니다.
- 인자마다 같은 문을 지납니다. `q.Tag(otherTag, "focus", { "a", "b" })`처럼 섞어 쓸 수 있습니다.
- nil 슬롯은 조용히 무시되지 않고 검증 에러가 됩니다.
- 리스트는 **배열**이어야 합니다 — 정수가 아닌 키가 섞이거나 nil 구멍이 있으면 에러입니다.
  - `Tag: names must be strings, Tags, or a plain {...} list of those — a name list is an array, not a hash table`
  - `Tag: names must be strings, Tags, or a plain {...} list of those — a name list cannot have nil holes`
  - `Tag: names must be strings, Tags, or a plain {...} list of those (got a table with a metatable)`
  - `Tag: names must be strings, Tags, or a plain {...} list of those (got an AttrKey/Mapper descriptor)`

**예제**

```luau
local interactive = q.Tag("clickable", "focusable")
local button = D.TextButton {
    interactive,
    q.Tag("primary"),
    Text = "확인",
}
```

**관련** — [시작하기 05. 이름표와 속성](../../getting-started/05-tag-attr.md), [컴포넌트 경계 규약](../../how-to/01-component-conventions.md), [확장 가능한 디스패치 엔진](../../quadnomicon/08-extensible-dispatch-engine.md)

## `tag:Added(names)`

**시그니처**

```luau
Added: (self: Tag, names: TagNames) -> Tag
```

**반환** — 이름이 더해진 **새** `Tag`. 원본은 그대로입니다.

**동작** — 인자 하나를 받고, 그 하나가 문자열이든 `Tag`든 리스트든 상관없습니다(생성자와 같은 문). 이미 있는 이름을 더하면 집합이라 변화가 없습니다.

**예제**

```luau
local base = q.Tag("card")
local selected = base:Added("selected")
local both = base:Added({ "selected", "hovered" })
```

## `tag:Removed(names)`

**시그니처**

```luau
Removed: (self: Tag, names: TagNames) -> Tag
```

**반환** — 이름이 빠진 새 `Tag`.

**동작** — `:Added`와 **똑같이 검증합니다.** 없는 이름을 빼는 것은 조용한 no-op이지만, 이름이 아닌 것을 넘기면 에러입니다.

## `tag:Contains(...names)`

**시그니처**

```luau
Contains: (self: Tag, ...string) -> boolean
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `...names` | `string` | 확인할 이름들 |

**반환** — 준 이름이 **전부** 있으면 `true`.

**동작** — 가변 인자입니다. 이름을 하나도 안 주면 공허하게 참입니다(동적으로 언팩한 목록이 비었을 때를 위한 것). 문자열이 아닌 인자는 조용한 `false`가 아니라 에러입니다.

- `Tag:Contains: names must be strings (got {typeof(name)} at argument {i})`

**예제**

```luau
local tag = q.Tag("card", "selected")
print(tag:Contains("card"))               -- true
print(tag:Contains("card", "selected"))   -- true (전부 있어야 참)
print(tag:Contains("card", "missing"))    -- false
```

## `tag:Names()`

**시그니처**

```luau
Names: (self: Tag) -> () -> string?
```

**반환** — 이름을 하나씩 돌려주고 끝나면 `nil`을 주는 **이터레이터 함수**.

**동작** — 집합이라 **순서 보장이 없습니다.** `for` 문의 제너릭 자리에 그대로 넣어 씁니다.

**예제**

```luau
local tag = q.Tag("a", "b")
for name in tag:Names() do
    print(name) -- 순서는 보장되지 않는다
end
```

## `tag:Apply(factory)`

**시그니처**

```luau
Apply: <U>(self: Tag, factory: (Tag) -> U) -> U
```

**반환** — `factory(self)`의 결과.

**동작** — `Modifier:Apply`와 같은 순수 호출 슈거입니다. 계약도 추가 의미도 없습니다. 함수가 아닌 것을 넘기면 그 자리에서 던집니다.

- `Tag: Apply factory must be a function (got {typeof(factory)})`

## `q.Tag.Merged(...tags)`

**시그니처**

```luau
Merged: (...TagMarker) -> Tag
```

**반환** — 모든 입력의 이름을 합친 새 `Tag`.

**동작** — 손실 없는 합집합입니다. `q.Tag(tag1, tag2, …)`와 결과가 같고, **`Tag`만 받는 엄격한 철자**라는 점만 다릅니다 — 문자열이나 리스트를 섞어 넘길 수 없습니다.

- `Tag.Merged: arguments must be Tag values`

**예제**

```luau
local a, b = q.Tag("x"), q.Tag("y")
local merged = q.Tag.Merged(a, b)  -- {x, y}
local same = q.Tag(a, b)           -- 같은 결과, 느슨한 철자
```

---

## Attr

`Attr`은 **이름 → 값 맵**입니다. 값은 원시 값이거나 `State`/`Source`이거나 `q.None`입니다.

```luau
type Attr = {
    read __quadAttr: true,
    NameMap: (self: Attr) -> { [string]: any },
}

type AttrConstructor = setmetatable<{
    Merged: (...Attr) -> Attr,
    Overridden: (...Attr) -> Attr,
}, { __call: (self: any, ...any) -> Attr }>
```

## 삭제 규칙 — `None`만이 지운다

세 가지를 구별하세요.

| 한 일 | 결과 |
|---|---|
| 값에 `q.None`을 둔다 | 엔진에서 그 속성이 **삭제**됩니다 |
| 바인딩된 `State`가 `q.None`이 된다 | 같습니다 — 삭제됩니다 |
| 바인딩된 `State`가 `nil`을 내놓는다 | 이것도 삭제됩니다 — 반응형 `nil`은 그 키의 핸들러가 받아 `setAttr(inst, name, nil)`로 내려갑니다 |
| 그 `Attr` 값 객체를 다른 것으로 **교체**한다 | 옛 속성 값이 엔진에 **그대로 남습니다** |

네 번째가 중요합니다. 자리에서 물러나는 `Attr`은 구독을 끊고 이름 소유권만 반납할 뿐, 엔진 쪽에는 손대지 않습니다. 지우고 싶으면 명시적으로 `q.None`(또는 바인딩된 `State`의 `nil`)을 보내야 합니다. **리터럴** `nil`이 그 자리에서 거부되는 것은 평범한 테이블이 `nil`을 담을 수 없어 항목이 조용히 사라지기 때문이고, 그래서 리터럴 자리에서 지우기의 유일한 표현은 `q.None`입니다.
<!-- mock 실측 2026-09-11: gs.attrnil.luau — 그룹 Attr·BooleanAttr·AttrKey 세 경로 모두 State의 nil이 삭제로 흐른다 -->

## `q.Attr(...)`

**시그니처**

```luau
__call: (self: any, ...any) -> Attr
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `...` | `Store` / `Attr` / 평범한 테이블 | 하나의 이름 맵으로 평탄화됩니다 |

**반환** — 새 `Attr`(frozen).

**동작**

- **`Store`**를 주면 그 스토어가 선언한 키 전부가 이름이 되고, 값은 각 `Source` 슬롯 자체입니다. 스토어를 그대로 속성으로 내보내는 관용구입니다.
- **다른 `Attr`**을 주면 그 이름 맵이 합쳐집니다.
- **평범한 테이블**(메타테이블 없는)을 주면 `{ [name] = value }`가 그대로 항목이 됩니다. 값은 원시 값 / `State` / `q.None`입니다.
- 이름이 겹치면 **뒤 인자가 조용히 이깁니다**(= `Attr.Overridden`의 정책). 겹침을 에러로 만들고 싶으면 [`q.Attr.Merged`](#qattrmerged)를 쓰세요.

**에러**

- `Attr: arguments must be Stores, Attr values or plain tables`
- `Attr: attribute name cannot be empty`
- `Attr: plain-table keys must be non-empty strings`
- `Attr: attribute "{name}" cannot be a function — attribute values are raw values or State`
- `Attr: attribute "{name}" cannot be a table — attribute values are raw values, None or State (got {typeof(v)})`

한 인스턴스의 두 자리에 **같은 그룹 값 객체**를 놓으면 그 자리에서 던집니다 — `Attr: the same group value is placed at two positions of this instance`.

**예제**

```luau
local hp = q.Source<<number | QuadTypes.None>>(100)
local stats = D.Frame {
    q.Attr({ Hp = hp, Name = "hero" }),
    D.TextLabel { Text = "체력" },
}
hp:Set(80)      -- 속성 Hp가 따라 바뀐다
hp:Set(q.None)  -- 속성 Hp가 삭제된다
```

**관련** — [시작하기 05. 이름표와 속성](../../getting-started/05-tag-attr.md), [확장 가능한 디스패치 엔진](../../quadnomicon/08-extensible-dispatch-engine.md)

## `attr:NameMap()`

**시그니처**

```luau
NameMap: (self: Attr) -> { [string]: any }
```

**반환** — 평탄화된 이름 맵(frozen). 값은 **저장된 그대로** — `Source` 슬롯은 핸들 자체로, `None`은 `None`으로 나옵니다.

**동작** — 읽기용입니다. 합성 결과를 검사하거나 테스트에서 확인할 때 씁니다.

**예제**

```luau
local attr = q.Attr({ A = 1, B = q.Source("x"), C = q.None })
local map = attr:NameMap()
print(map.A)          -- 1
print(map.C == q.None) -- true (:Get()을 부르지 않는다)
```

## `q.Attr.Merged(...)`

**시그니처**

```luau
Merged: (...Attr) -> Attr
```

**반환** — 합쳐진 새 `Attr`.

**동작** — `Attr` 값**만** 받고, 이름이 겹치면 **에러**입니다. 두 출처가 같은 속성을 주장하는 사고를 조용히 넘기지 않으려는 자리입니다.

- `Attr.Merged: arguments must be Attr values`
- `Attr.Merged: attribute name "{name}" appears more than once`

## `q.Attr.Overridden(...)`

**시그니처**

```luau
Overridden: (...Attr) -> Attr
```

**반환** — 합쳐진 새 `Attr`.

**동작** — `Attr` 값만 받되, 겹치면 **뒤 인자가 조용히 이깁니다.** 생성자 `q.Attr(...)`의 정책과 같고, 입력을 `Attr`로만 제한한 철자입니다.

- `Attr.Overridden: arguments must be Attr values`

**예제**

```luau
local theme = q.Attr({ Accent = "blue", Size = 1 })
local override = q.Attr({ Accent = "red" })

local final = q.Attr.Overridden(theme, override) -- Accent = "red"
-- q.Attr.Merged(theme, override) 였다면 겹침 에러
```

## `q.AttrKey(name)`

**시그니처**

```luau
AttrKey: (name: string) -> AttrKeyObject
type AttrKeyObject = { Name: string }
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `name` | `string` | 속성 이름(빈 문자열 불가) |

**반환** — 그 이름의 키 객체.

**동작** — 속성 **단일 키** 프리미티브입니다. props의 **문자 키 자리**에 놓아 씁니다 — `D.Frame { [q.AttrKey("Hp")] = 100 }`.

- **값 타입을 모르는 무타입 프리미티브입니다.** 값 검증은 백엔드의 `setAttr` 몫입니다. 패밀리 슈가(`StringAttr` 등)가 못 덮는 엔진 고유 타입(`Color3`, `UDim2`, `Instance` …)이 이 키의 자리입니다.
- 이름별 **weak 캐시**를 지납니다 — 무언가가 붙들고 있는 동안 `q.AttrKey("Hp") == q.AttrKey("Hp")`가 성립합니다.
- 값에 `q.None`을 두면 그 속성이 삭제됩니다.
- 한 인스턴스의 같은 이름을 **서로 다른 키 객체**가 주장하면 그 자리에서 던집니다 — `AttrKey: attribute "{k.Name}" is already bound by another owner`.

**에러**

- `AttrKey: name must be a non-empty string`

:::caution
**문자 키 형태는 런타임 전용입니다.** `D.Frame { [q.AttrKey("Hp")] = v }`는 정상 동작하지만, `--!strict` 신 솔버에서는 생성된 props 타입의 배열 인덱서에 걸려 키와 값 둘 다 타입 에러가 납니다(테이블 타입은 인덱서를 하나만 가질 수 있어 열어줄 방법이 없습니다). strict 모듈에서는 숫자 키 슈가 — [`q.Attr`](#qattr)이나 [`q.StringAttr`](#qstringattrname-value) 계열 — 을 쓰세요.
:::

**예제**

```luau
local marker = D.Frame {
    [q.AttrKey("SpawnColor")] = Color3.new(1, 0, 0), -- 패밀리가 못 덮는 엔진 타입
}
```

## `q.StringAttr(name, value)`

**시그니처**

```luau
StringAttr: AttrSugar<string>
type AttrSugar<T> = (name: string, value: T | StateMarker<T> | None) -> Attr
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `name` | `string` | 속성 이름(빈 문자열 불가) |
| `value` | `string` / `State<string>` / `q.None` | 값. `nil`은 거부됩니다 |

**반환** — 항목이 하나뿐인 `Attr`(즉 `q.Attr({ [name] = value })`).

**동작** — **타입드 스칼라 슈가**입니다. 자기 핸들러를 갖지 않고 그룹 경로를 그대로 씁니다. 차이는 값 검증뿐입니다 — 패밀리는 자기 타입을 알기 때문에 원시 값의 타입을 여기서 확인합니다(`State`와 `q.None`은 그대로 통과합니다).

숫자 키 자리에 놓으므로 strict 모드에서도 타입이 섭니다. `AttrKey`의 문자 키 형태를 대신하는 자리입니다.

**에러**

- `StringAttr: name must be a non-empty string`
- `StringAttr: value of "{name}" must not be nil — use None to delete`
- `StringAttr: value of "{name}" must be a string, State or None (got {typeof(value)})`

**예제**

```luau
local label = q.Source("hero")
local card = D.Frame {
    q.StringAttr("Label", label),
    q.StringAttr("Kind", "unit"),
}
label:Set("villain")                                    -- 속성 Label이 따라 바뀐다
local blank = D.Frame { q.StringAttr("Label", q.None) } -- 값 자리의 None: 그 속성을 지운다
```

## `q.NumberAttr(name, value)`

**시그니처**

```luau
NumberAttr: AttrSugar<number>
```

**동작** — [`q.StringAttr`](#qstringattrname-value)과 모든 것이 같고 원시 값 타입만 `number`입니다.

**에러** — `NumberAttr: name must be a non-empty string` / `NumberAttr: value of "{name}" must not be nil — use None to delete` / `NumberAttr: value of "{name}" must be a number, State or None (got {typeof(value)})`

## `q.BooleanAttr(name, value)`

**시그니처**

```luau
BooleanAttr: AttrSugar<boolean>
```

**동작** — [`q.StringAttr`](#qstringattrname-value)과 모든 것이 같고 원시 값 타입만 `boolean`입니다.

**에러** — `BooleanAttr: name must be a non-empty string` / `BooleanAttr: value of "{name}" must not be nil — use None to delete` / `BooleanAttr: value of "{name}" must be a boolean, State or None (got {typeof(value)})`

**예제**

```luau
local hp = q.Source(100)
local alive = D.Frame {
    q.NumberAttr("Hp", hp),
    q.BooleanAttr("Friendly", true),
}
```
