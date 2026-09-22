---
title: "에러 코드 — Tag·Attr"
description: "Tag/Attr/AttrKey/타입드 Attr가 던지는 에러"
---
각 절은 `### QuadNNNN` — 메시지 원문(자리표시자는 `{…}`), 언제 나는가, 어떻게 고치는가. 번호로 찾으려면 [색인](/reference/errors/00-index/).


### Quad0001

`AttrKey: name must be a non-empty string` — `quad-base/src/Attr/Key.luau`

- **언제**: `q.AttrKey(name)`에 넘긴 `name`이 문자열이 아니거나 빈 문자열일 때.
- **고치려면**: 비어 있지 않은 문자열 이름을 넘기세요.
- **참고**: [`q.AttrKey(name)`](/reference/core/09-tag-attr/#qattrkeyname)

### Quad0002

`AttrKey: attribute "{k.Name}" is already bound by another owner` — `quad-base/src/Attr/Key.luau`

- **언제**: 한 인스턴스의 같은 속성 이름을 서로 다른 `AttrKey` 객체가 동시에 주장할 때 — 먼저 그 이름을 차지한 키가 아직 자리에서 물러나지 않은 채로 다른 키 객체가 같은 이름에 값을 놓으려 할 때입니다.
- **고치려면**: 같은 이름엔 항상 캐시된 같은 `q.AttrKey(name)` 객체를 쓰거나, 먼저 것을 그 자리에서 물린 뒤에 다시 놓으세요.
- **참고**: [`q.AttrKey(name)`](/reference/core/09-tag-attr/#qattrkeyname)

### Quad0003

`{ctx}: attribute name cannot be empty` — `quad-base/src/Attr/init.luau`

- **언제**: `q.Attr(...)`에 넘긴 `Store`가 선언한 이름(`store:Names()`) 중 빈 문자열이 있을 때. `{ctx}`는 부른 자리 이름(`Attr`)입니다.
- **고치려면**: `Store`의 키 이름을 비어 있지 않게 하세요.
- **참고**: [`q.Attr(...)`](/reference/core/09-tag-attr/#qattr)

### Quad0004

`{ctx}: attribute name "{name}" appears more than once` — `quad-base/src/Attr/init.luau`

- **언제**: 내부 헬퍼 `flattenArg`가 `overwrite=false`로 `Store`를 펼치다가 그 이름이 맵에 이미 있을 때 던지는 조건입니다. 지금 공개 표면 중 이 조합(`Store` + `overwrite=false`)에 실제로 닿는 호출은 없습니다 — `q.Attr.Merged`/`q.Attr.Overridden`은 인자를 `Attr` 값으로만 제한해 `Store` 분기를 타지 않고, 생성자 `q.Attr(...)`는 항상 `overwrite=true`로 부릅니다.
- **고치려면**: (문서 미정 — 현재 도달 경로가 없습니다)
- **참고**: [`q.Attr(...)`](/reference/core/09-tag-attr/#qattr)

### Quad0005

`Attr.Merged: attribute name "{name}" appears more than once` — `quad-base/src/Attr/init.luau`

- **언제**: `q.Attr.Merged(...)`에 넘긴 여러 `Attr` 값이 같은 속성 이름을 중복해서 선언할 때.
- **고치려면**: 이름이 겹치지 않게 하거나, 겹침을 허용하려면 [`q.Attr.Overridden`](/reference/core/09-tag-attr/#qattroverridden)을 쓰세요.
- **참고**: [`q.Attr.Merged(...)`](/reference/core/09-tag-attr/#qattrmerged)

### Quad0006

`{ctx}: plain-table keys must be non-empty strings` — `quad-base/src/Attr/init.luau`

- **언제**: `q.Attr(...)`에 넘긴 평범한 테이블(메타테이블 없는)의 키 중 문자열이 아니거나 빈 문자열인 것이 있을 때.
- **고치려면**: 테이블 키를 비어 있지 않은 문자열로 쓰세요.
- **참고**: [`q.Attr(...)`](/reference/core/09-tag-attr/#qattr)

### Quad0007

`{ctx}: attribute "{name}" cannot be a function — attribute values are raw values or State` — `quad-base/src/Attr/init.luau`

- **언제**: 평범한 테이블 값 자리에 함수를 뒀을 때 — 속성 값은 원시 값이거나 `State`/`q.None`이어야 합니다.
- **고치려면**: 함수 대신 값 자체나 `State`를 넘기세요.
- **참고**: [`q.Attr(...)`](/reference/core/09-tag-attr/#qattr)

### Quad0008

`{ctx}: attribute "{name}" cannot be a table — attribute values are raw values, None or State (got {typeof(v)})` — `quad-base/src/Attr/init.luau`

- **언제**: 평범한 테이블 값 자리에 (`None`도 `State`도 아닌) 또 다른 테이블을 뒀을 때 — 엔진은 그런 테이블을 속성 값으로 저장할 수 없습니다(Slot/Ref/Tween/Modifier 등이 여기 걸립니다).
- **고치려면**: 원시 값이나 `State`, `q.None`만 값 자리에 두세요.
- **참고**: [`q.Attr(...)`](/reference/core/09-tag-attr/#qattr)

### Quad0009

`{ctx}: attribute name "{name}" appears more than once` — `quad-base/src/Attr/init.luau`

- **언제**: Quad0004와 같은 헬퍼의 같은 조건이 평범한 테이블 분기에서 일어난 것 — `flattenArg`가 `overwrite=false`로 평범한 테이블을 펼치다가 그 이름이 이미 맵에 있을 때입니다. Quad0004와 마찬가지로 현재 공개 표면에서 이 조합에 실제로 닿는 호출은 없습니다.
- **고치려면**: (문서 미정 — 현재 도달 경로가 없습니다)
- **참고**: [`q.Attr(...)`](/reference/core/09-tag-attr/#qattr)

### Quad0010

`{ctx}: arguments must be Stores, Attr values or plain tables` — `quad-base/src/Attr/init.luau`

- **언제**: `q.Attr(...)`에 `Store`/`Attr`/평범한 테이블이 아닌 다른 것을 넘겼을 때.
- **고치려면**: 인자를 그 세 종류 중 하나로 바꾸세요.
- **참고**: [`q.Attr(...)`](/reference/core/09-tag-attr/#qattr)

### Quad0011

`Attr.Merged: arguments must be Attr values` — `quad-base/src/Attr/init.luau`

- **언제**: `q.Attr.Merged(...)`에 `Attr` 값이 아닌 인자를 넘겼을 때.
- **고치려면**: 모든 인자를 `q.Attr(...)`로 만든 값으로 바꾸세요.
- **참고**: [`q.Attr.Merged(...)`](/reference/core/09-tag-attr/#qattrmerged)

### Quad0012

`Attr.Overridden: arguments must be Attr values` — `quad-base/src/Attr/init.luau`

- **언제**: `q.Attr.Overridden(...)`에 `Attr` 값이 아닌 인자를 넘겼을 때.
- **고치려면**: 모든 인자를 `Attr` 값으로 바꾸세요.
- **참고**: [`q.Attr.Overridden(...)`](/reference/core/09-tag-attr/#qattroverridden)

### Quad0013

`{fnName}: name must be a non-empty string` — `quad-base/src/Attr/init.luau`

- **언제**: `q.StringAttr`/`q.NumberAttr`/`q.BooleanAttr`에 넘긴 `name`이 문자열이 아니거나 빈 문자열일 때. `{fnName}`은 부른 패밀리 이름입니다.
- **고치려면**: 비어 있지 않은 문자열 이름을 쓰세요.
- **참고**: [`q.StringAttr(name, value)`](/reference/core/09-tag-attr/#qstringattrname-value)

### Quad0014

`{fnName}: value of "{name}" must not be nil — use None to delete` — `quad-base/src/Attr/init.luau`

- **언제**: 타입드 Attr 패밀리(`StringAttr`/`NumberAttr`/`BooleanAttr`)의 값 자리에 리터럴 `nil`을 넘겼을 때 — 평범한 테이블은 `nil`을 담을 수 없어 항목이 조용히 사라지는 것을 막습니다.
- **고치려면**: `nil` 대신 `q.None`을 쓰세요(지우는 뜻입니다).
- **참고**: [`q.StringAttr(name, value)`](/reference/core/09-tag-attr/#qstringattrname-value)

### Quad0015

`{fnName}: value of "{name}" must be a {luaType}, State or None (got {typeof(value)})` — `quad-base/src/Attr/init.luau`

- **언제**: 타입드 Attr 패밀리의 값이 `State`도 `q.None`도 아니면서, 그 패밀리의 원시 타입(`StringAttr`이면 `string` 등)과 다를 때.
- **고치려면**: 값 타입을 맞추거나 `State`/`q.None`으로 감싸세요.
- **참고**: [`q.StringAttr(name, value)`](/reference/core/09-tag-attr/#qstringattrname-value)

### Quad0016

`Attr: the same group value is placed at two positions of this instance` — `quad-base/src/Attr/init.luau`

- **언제**: 같은 `Attr` 그룹 값 객체(테이블 신원 기준)를 한 인스턴스의 서로 다른 두 props 자리에 동시에 놓았을 때.
- **고치려면**: 자리마다 별도의 `q.Attr(...)` 호출로 새 값을 만드세요.
- **참고**: [`q.Attr(...)`](/reference/core/09-tag-attr/#qattr)
