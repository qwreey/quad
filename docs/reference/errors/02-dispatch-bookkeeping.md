---
title: "에러 코드 — 디스패치와 장부"
description: "Dispatch/Bookkeeping/Modifier/None/핸들러 계약이 던지는 에러"
---
# [레퍼런스] 에러 코드 — 디스패치와 장부

각 절은 `### QuadNNNN` — 메시지 원문(자리표시자는 `{…}`), 언제 나는가, 어떻게 고치는가. 번호로 찾으려면 [색인](./00-index.md).


### Quad0019

`Bookkeeping.{fnName}: position must be a positive integer (got {tostring(i)})` — `quad-base/src/Bookkeeping.luau`

- **언제**: `q.Bookkeeping.setLength`/`setOffsetSource`/`setEmpty`/`getOffsetAt` 등 위치(`i`/`at`)를 받는 공개 함수에 양의 정수가 아닌 값을 넘겼을 때. `{fnName}`은 실제로 부른 함수 이름입니다.
- **고치려면**: 1부터 시작하는 정수를 넘기세요.
- **참고**: [Length/Offset 부기](../extend/02-dispatch-handler-contract.md#lengthoffset-부기)

### Quad0020

`Bookkeeping.{fnName}: ownerKey must not be nil` — `quad-base/src/Bookkeeping.luau`

- **언제**: `q.Bookkeeping`의 공개 함수에 `ownerKey`(부기의 주인 — 요소 또는 Slot)로 `nil`을 넘겼을 때.
- **고치려면**: 실제 owner를 넘기세요.
- **참고**: [Length/Offset 부기](../extend/02-dispatch-handler-contract.md#lengthoffset-부기)

### Quad0021

`Bookkeeping.{fnName}: length must be a non-negative integer (got {tostring(n)})` — `quad-base/src/Bookkeeping.luau`

- **언제**: `q.Bookkeeping.setLength(ownerKey, i, len, ...)`의 `len`(상수인 경우) 또는 그 값에 바인딩된 `State`가 내놓은 값이 음수/소수/숫자가 아닐 때.
- **고치려면**: 0 이상의 정수를 쓰세요.
- **참고**: [`q.Bookkeeping.setLength(ownerKey, i, len, anchor, element)`](../extend/02-dispatch-handler-contract.md#qbookkeepingsetlengthownerkey-i-len-anchor-element)

### Quad0022

`Bookkeeping.getOffsetAt: position {at} is past N+1 (N = {last}, at most {last + 1} may be queried) — or a leaf handler skipped its position registration: position {i} is not registered` — `quad-base/src/Bookkeeping.luau`

- **언제**: `q.Bookkeeping.getOffsetAt(ownerKey, at)`으로 조회한 `at`이 등록된 마지막 위치(`N`) + 1보다 클 때 — 범위 밖 조회입니다. (같은 자리에서 중간의 어떤 위치가 등록 자체를 건너뛴 경우도 이 갈래로 잡힙니다 — 두 원인을 코드가 구분할 수 없어 메시지가 둘 다 말합니다.)
- **고치려면**: 등록된 범위(`1..N+1`) 안에서 조회하거나, 먼저 그 위치를 `setLength`/`setOffsetSource`(또는 `setEmpty`)로 등록하세요.
- **참고**: [`q.Bookkeeping.getOffsetAt(ownerKey, at)`](../extend/02-dispatch-handler-contract.md#qbookkeepinggetoffsetatownerkey-at)

### Quad0023

`Bookkeeping.recompute: sourceList[{i}] is nil — a nil hole in the numeric-key part of props ({ a, nil, b })? fill the optional slot with q.None (the children placed before this raise stay seated in the half-built Instance, reachable as child.Parent — q.dispose that Instance to clean up; it takes those children with it, so build the retry with new ones); if you are writing a handler, bookkeeping is broken (setLength without setOffsetSource? the contract says None)` — `quad-base/src/Bookkeeping.luau`

- **언제**: 재계산 도중 위치 `i`의 오프셋 발행 채널(`sourceList[i]`)이 `nil`일 때 — 대표 원인은 배열 리터럴 중간에 `nil`이 낀 props(`{ a, nil, b }`)이고, 핸들러를 직접 쓰는 입장이면 `setOffsetSource`(또는 `setEmpty`) 등록을 빠뜨린 경우입니다.
- **고치려면**: 사용자라면 그 옵셔널 자리를 `q.None`으로 채우세요. 핸들러 작성자라면 그 자리의 `setOffsetSource` 등록을 빠뜨리지 않았는지 확인하세요.
- **참고**: [Length/Offset 부기](../extend/02-dispatch-handler-contract.md#lengthoffset-부기)

### Quad0024

`Bookkeeping.recompute: lengthList[{i}] is nil — bookkeeping is broken (setOffsetSource without setLength?)` — `quad-base/src/Bookkeeping.luau`

- **언제**: 재계산 도중 위치 `i`의 길이(`lengthList[i]`)가 `nil`일 때 — 내부 불변식 위반으로, 어떤 핸들러가 `setOffsetSource`만 부르고 `setLength`는 부르지 않은 경우입니다.
- **고치려면**: 그 핸들러가 `setLength`도 함께 부르게 하세요(또는 둘 다 하는 `setEmpty`를 쓰세요).
- **참고**: [Length/Offset 부기](../extend/02-dispatch-handler-contract.md#lengthoffset-부기)

### Quad0025

`Bookkeeping.setOffsetSource: source must be a Source<number> or None (got {typeof(source)})` — `quad-base/src/Bookkeeping.luau`

- **언제**: `q.Bookkeeping.setOffsetSource(ownerKey, i, source)`의 `source`가 `Source<number>`도 `q.None`도 아닐 때.
- **고치려면**: 부기 채널로 `Source<number>`나 `q.None`(발행 채널 없음)을 넘기세요.
- **참고**: [`q.Bookkeeping.setOffsetSource(ownerKey, i, source)`](../extend/02-dispatch-handler-contract.md#qbookkeepingsetoffsetsourceownerkey-i-source)

### Quad0229

`Bookkeeping.getOffsetAt: position {at} needs positions 1..{at - 1} registered but {i} is not — a leaf handler skipped its position registration` — `quad-base/src/Bookkeeping.luau`

- **언제**: 조회한 `at`은 등록 범위 안(`N+1` 이하)인데, 그 앞의 어떤 위치 `i`가 등록되지 않았을 때 — 어떤 leaf 핸들러가 자기 자리의 위치 등록(`setLength`/`setOffsetSource`)을 건너뛴 경우입니다. `getOffsetAt`의 if/else 두 갈래 중 하나로, 같은 조건문의 다른 갈래가 Quad0022입니다.
- **고치려면**: 그 자리를 담당한 핸들러가 반드시 `setLength`와 `setOffsetSource`(또는 그 둘을 한 번에 하는 `setEmpty`)를 부르게 하세요.
- **참고**: [`q.Bookkeeping.getOffsetAt(ownerKey, at)`](../extend/02-dispatch-handler-contract.md#qbookkeepinggetoffsetatownerkey-at)

### Quad0049

`Modifier:Peek: key must be a non-empty string (got {if key == "" then '""' else typeof(key)})` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: `mod:Peek(key)`를 부를 때 `key`가 빈 문자열이거나 문자열이 아닌 경우. setter 경로(`mod:Field(...)`)가 거부하는 것과 같은 키 도메인이라, 예전에는 `Peek`이 그런 키에 조용히 `nil`을 돌려주던 것을 바로잡았습니다.
- **고치려면**: 필드 이름은 비어있지 않은 문자열로 넘기세요.
- **참고**: [`mod:Peek<<T>>(key)`](../core/08-modifier.md#modpeektkey)

### Quad0050

`Modifier:Apply: factory must be a function (got {typeof(factory)})` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: `mod:Apply(factory)`의 `factory`가 함수가 아닐 때.
- **고치려면**: Modifier를 받아 값을 돌려주는 함수를 넘기세요.
- **참고**: [`mod:Apply(factory)`](../core/08-modifier.md#modapplyfactory)

### Quad0051

`Modifier:As: name must be a class name string (got {typeof(name)})` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: `mod:As(name)`에서 `name`을 줬는데 문자열이 아닐 때(생략은 허용됩니다).
- **고치려면**: 클래스 이름 문자열을 넘기거나 생략하세요.
- **참고**: [`mod:As(name)`](../core/08-modifier.md#modasname)

### Quad0052

`Modifier: unknown modifier class "{name}" — Modifier.TypedFactory/DefineSubtype it first` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: `mod:As(name)`에 준 `name`이 아직 `Modifier.TypedFactory`나 `DefineSubtype`으로 등록되지 않은 클래스일 때.
- **고치려면**: 먼저 `q.Modifier.TypedFactory(name)`이나 `DefineSubtype`으로 그 이름을 등록하세요.
- **참고**: [`mod:As(name)`](../core/08-modifier.md#modasname)

### Quad0053

`Modifier.Overridden: expects at least one Modifier` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: `q.Modifier.Overridden(...)`(콜론 형태 `mod:Overridden(...)`도 같은 함수)을 인자 없이 부를 때.
- **고치려면**: 합칠 Modifier를 최소 하나 넘기세요.
- **참고**: [`q.Modifier.Overridden(...)`](../core/08-modifier.md#qmodifieroverridden)

### Quad0054

`Modifier.Overridden: argument #{i} is not a Modifier (got {typeof(arg)})` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: `Overridden`에 넘긴 인자 중 하나가 Modifier가 아닐 때 — `q.Modifier(...)`와 달리 평범한 필드 테이블은 받지 않습니다.
- **고치려면**: 모든 인자를 Modifier로 넘기세요 — 평범한 테이블을 합치려면 `q.Modifier(...)`를 쓰세요.
- **참고**: [`q.Modifier.Overridden(...)`](../core/08-modifier.md#qmodifieroverridden)

### Quad0055

`Modifier: unknown modifier class "{target}" — Modifier.TypedFactory/DefineSubtype it first (or use :As(name) for an unchecked cast)` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: `mod:As<Class>()` 검사형 다운캐스트의 대상 클래스가 아직 등록되지 않았을 때.
- **고치려면**: 대상 클래스를 `TypedFactory`/`DefineSubtype`으로 먼저 등록하거나, 존재 검사만 하는 `mod:As(name)`을 대신 쓰세요.
- **참고**: [`mod:As<Class>()`](../core/08-modifier.md#modasclass)

### Quad0056

`Modifier: cannot cast a "{tag}" modifier to "{target}" — not an ancestor (use :As(name) to force)` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: `mod:As<Class>()`의 대상이 등록은 돼 있지만, 지금 Modifier의 태그가 무타입도 대상 자신도 대상의 조상도 아닐 때.
- **고치려면**: 실제 조상/자손 관계를 확인하거나, 조상 검사 없이 강제로 태그를 바꾸려면 `mod:As(name)`을 쓰세요.
- **참고**: [`mod:As<Class>()`](../core/08-modifier.md#modasclass)

### Quad0057

`Modifier: field "{key}" cannot hold a handler-layer value (Ref/Observer/Effect/Slot/Modifier)` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: `mod:Field(value)`의 `value`(리터럴이든 변환 함수의 반환이든)가 `Ref`/`PreRef`/`PostRef`/`Observer`/`Effect`/`Slot`/`Modifier` 같은 핸들러 계층 값일 때. `State`/`Source`는 통과합니다.
- **고치려면**: 그 값은 필드가 아니라 props의 숫자 키 자리에 놓으세요.
- **참고**: [`mod:<Field>(value)`](../core/08-modifier.md#modfieldvalue)

### Quad0058

`Modifier: setter keys must be strings (got {typeof(key)}) — put a non-string key in the props table itself (Frame { [key] = value })` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: `mod[key](...)`를 문자열이 아닌 `key`로 부를 때(`AttrKey`/`MapperDescriptor` 같은 비문자열 키). 생성자의 같은 규칙(Quad0059)과 짝입니다.
- **고치려면**: 그 키는 Modifier가 아니라 props 테이블에 직접(`[key] = value`) 넣으세요.
- **참고**: [`mod:<Field>(value)`](../core/08-modifier.md#modfieldvalue)

### Quad0059

`Modifier: initial-field table keys must be non-empty field names (got {if k == "" then '""' else typeof(k)} at argument #{i})` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: `q.Modifier{ ... }`/`D.Modifier.<Class>{ ... }` 생성자에 넘긴 필드 테이블의 키가 빈 문자열이거나 문자열이 아닐 때.
- **고치려면**: 필드 이름은 비어있지 않은 문자열로 쓰세요.
- **참고**: [`q.Modifier(...)`](../core/08-modifier.md#qmodifier)

### Quad0060

`Modifier: field "{k}" collides with a reserved Modifier method` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: 초기 필드 테이블의 키가 `Peek`/`Apply`/`Overridden`/`As` 같은 예약 메소드 이름과 같을 때 — setter 경로에서는 애초에 만들어질 수 없는 필드라 생성자도 같은 이름을 거부합니다.
- **고치려면**: 그 이름을 피하세요 — 예약 메소드는 필드가 될 수 없습니다.
- **참고**: [`q.Modifier(...)`](../core/08-modifier.md#qmodifier)

### Quad0061

`Modifier: field "{k}" matches the reserved cast prefix As<Class> — casts are methods, not fields` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: 초기 필드 테이블의 키가 `As` + 대문자로 시작하는 예약된 캐스트 접두사 모양일 때.
- **고치려면**: 그 이름을 피하세요 — `As<Class>` 모양은 항상 캐스트 메소드로 예약돼 있습니다.
- **참고**: [`q.Modifier(...)`](../core/08-modifier.md#qmodifier)

### Quad0062

`Modifier: field "{k}" starts with "__" — metamethod-looking names are never properties` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: 초기 필드 테이블의 키가 `"__"`로 시작할 때 — setter 경로(`__index`)도 그런 이름엔 항상 `nil`을 돌려주므로 생성자에서도 같은 이름을 막습니다.
- **고치려면**: `"__"`로 시작하지 않는 필드 이름을 쓰세요.
- **참고**: [`q.Modifier(...)`](../core/08-modifier.md#qmodifier)

### Quad0063

`Modifier: field "{k}" in an initial-field table cannot be a function — a transform goes through mod:{k}(fn); an event handler does not belong in a Modifier (put it as an inline key on the Declaration, or wrap it in a State)` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: 초기 필드 테이블의 값으로 함수를 줬을 때 — setter 자리에서 함수는 변환 함수라는 다른 뜻이라, 생성자에서 그대로 받으면 두 경로가 조용히 갈립니다.
- **고치려면**: 변환이 필요하면 `mod:{k}(fn)`을 쓰고, 이벤트 핸들러라면 Modifier가 아니라 Declaration의 인라인 키나 State로 넘기세요.
- **참고**: [`q.Modifier(...)`](../core/08-modifier.md#qmodifier)

### Quad0064

`Modifier: field "{k}" cannot hold a handler-layer value (Ref/Observer/Effect/Slot/Modifier)` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: 초기 필드 테이블의 값이 핸들러 계층 값(`Ref`/`Observer`/`Effect`/`Slot`/`Modifier`)일 때 — setter 경로(Quad0057)와 같은 규칙을 생성자에도 적용합니다.
- **고치려면**: 그 값은 필드가 아니라 props의 숫자 키 자리에 놓으세요.
- **참고**: [`q.Modifier(...)`](../core/08-modifier.md#qmodifier)

### Quad0065

`Modifier: argument #{i} must be a Modifier or a plain field table (got {typeof(arg)})` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: `q.Modifier(...)`/`D.Modifier.<Class>(...)`에 넘긴 인자가 Modifier도, 메타테이블 없는 평범한 필드 테이블도 아닐 때(`Source`/`Ref`/`Tag` 같은 다른 quad 값을 넘긴 경우 등).
- **고치려면**: Modifier나 평범한 `{ field = value }` 테이블만 넘기세요.
- **참고**: [`q.Modifier(...)`](../core/08-modifier.md#qmodifier)

### Quad0066

`Modifier.{fn}: {what} must be a non-empty class name string (got {typeof(name)})` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: `q.Modifier.TypedFactory(name)`의 `name`이나 `q.Modifier.DefineSubtype(parent, subtype)`의 `parent`/`subtype`이 빈 문자열이거나 문자열이 아닐 때. `{fn}`/`{what}`은 실제로 부른 함수와 검사한 인자 이름입니다.
- **고치려면**: 비어있지 않은 클래스 이름 문자열을 넘기세요.
- **참고**: [`q.Modifier.TypedFactory<<T>>(name)`](../core/08-modifier.md#qmodifiertypedfactorytname)

### Quad0067

`Modifier.DefineSubtype: "{subtype}" ⊂ "{parent}" would make a cycle` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: `q.Modifier.DefineSubtype(parent, subtype)`이 등록하려는 간선이 이미 있는 조상 관계를 거슬러 올라가 순환을 만들 때.
- **고치려면**: 순환이 생기지 않는 방향으로 등록하세요.
- **참고**: [`q.Modifier.DefineSubtype(parent, subtype)`](../core/08-modifier.md#qmodifierdefinesubtypeparent-subtype)

### Quad0068

`Modifier: a Modifier cannot be a value of key "{tostring(k)}" — place it in the array part` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: Modifier를 props의 문자 키 값 자리에 뒀을 때 — 합칠 대상이 없는 자리입니다.
- **고치려면**: Modifier는 숫자 키(배열부) 자리에 놓으세요.
- **참고**: [숫자 키 자리에 놓는다](../core/08-modifier.md#숫자-키-자리에-놓는다)

### Quad0069

`{kind}: already fired — a {kind} is one-shot, make a new one for each instance` — `quad-base/src/Dispatch/Ref.luau`

- **언제**: 이미 한 번 발화(`v:Set(inst)`)한 `PreRef`/`PostRef`를 다른 인스턴스의 props 숫자 키 자리에 또 놓았을 때. `{kind}`는 `PreRef` 또는 `PostRef`입니다.
- **고치려면**: 인스턴스마다 새 `PreRef`/`PostRef`를 만드세요 — 하나를 재사용하지 마세요.
- **참고**: [숫자 키 자리에만 놓는다](../core/07-ref.md#숫자-키-자리에만-놓는다)

### Quad0070

`StoreBind: the State's value chain is circular (a State that eventually holds itself) — a State may hold another State, but not a cycle` — `quad-base/src/Dispatch/StoreBind.luau`

- **언제**: props 자리에 놓인 State의 값을 따라가다(State가 다른 State를 값으로 들고 있으면 그 State도 마저 벗기는 재귀) 결국 자기 자신으로 돌아오는 순환을 만났을 때(예: `a:Set(b); b:Set(a)`).
- **고치려면**: State가 다른 State를 값으로 들고 있는 것 자체는 되지만, 그 사슬이 순환하면 안 됩니다 — 순환이 생기지 않게 값 대입을 정리하세요.
- **참고**: [Quadnomicon Vol. 8 — 확장 가능한 디스패치 엔진](../../quadnomicon/08-extensible-dispatch-engine.md)

### Quad0071

`Dispatch.retractFrom: no slot at index {i} — the chain array has a hole, bookkeeping is broken` — `quad-base/src/Dispatch/init.luau`

- **언제**: `retractFrom`이 체인 배열을 되감다가 구멍(`nil` 슬롯)을 만났을 때 — 정상 경로로는 나지 않는 내부 불변식 위반입니다.
- **고치려면**: (문서 미정) — 사용자 코드가 손볼 여지가 없는 내부 버그 신호입니다. 재현되면 리포트하세요.
- **참고**: [`q.Dispatch.retractFrom(inst, key, index)`](../extend/02-dispatch-handler-contract.md#qdispatchretractfrominst-key-index)

### Quad0072

`Dispatch.{fnName}: inst must not be nil` — `quad-base/src/Dispatch/init.luau`

- **언제**: `q.Dispatch.process`/`q.Dispatch.retractFrom`을 `inst = nil`로 직접 부를 때. `{fnName}`은 실제로 부른 함수 이름입니다.
- **고치려면**: 실제 대상 요소(`inst`)를 넘기세요.
- **참고**: [`q.Dispatch.process(inst, key, value, index)`](../extend/02-dispatch-handler-contract.md#qdispatchprocessinst-key-value-index)

### Quad0073

`Dispatch.{fnName}: index must be a positive integer (got {tostring(index)})` — `quad-base/src/Dispatch/init.luau`

- **언제**: `q.Dispatch.process`/`q.Dispatch.retractFrom`의 `index`가 1 이상의 정수가 아닐 때.
- **고치려면**: 체인 깊이는 1부터 시작하는 정수입니다 — 최초 진입은 `1`, 위임은 `index + 1`을 넘기세요.
- **참고**: [`q.Dispatch.process(inst, key, value, index)`](../extend/02-dispatch-handler-contract.md#qdispatchprocessinst-key-value-index)

### Quad0074

`Dispatch.{fnName}: key must not be nil` — `quad-base/src/Dispatch/init.luau`

- **언제**: `q.Dispatch.process`/`q.Dispatch.retractFrom`을 `key = nil`로 부를 때.
- **고치려면**: 실제 props 키(숫자 또는 문자열)를 넘기세요.
- **참고**: [`q.Dispatch.process(inst, key, value, index)`](../extend/02-dispatch-handler-contract.md#qdispatchprocessinst-key-value-index)

### Quad0075

`Dispatch.process: index {index} would leave a gap in the chain (the chain has {#list} slots — a delegating handler passes index + 1)` — `quad-base/src/Dispatch/init.luau`

- **언제**: `process`에 준 `index`가 그 자리 체인의 다음 자연스러운 깊이(`#list + 1`)보다 클 때 — 위임 핸들러가 `index + 1`이 아닌 값을 건너뛰어 부른 경우입니다.
- **고치려면**: 위임할 때는 항상 받은 `index + 1`을 그대로 넘기세요.
- **참고**: [`q.Dispatch.process(inst, key, value, index)`](../extend/02-dispatch-handler-contract.md#qdispatchprocessinst-key-value-index)

### Quad0076

`Dispatch: no handler matched key {tostring(k)} (value: {typeof(v)}, brand: {brand}) — ...` — `quad-base/src/Dispatch/init.luau`

- **언제**: 그 값을 받아줄 핸들러가 하나도 없을 때 — 값의 브랜드를 알아낼 수 있으면 같이 싣고, 브랜드별/키 종류별로 다른 안내(hint)가 뒤에 붙습니다(값이 `nil`이면 벗겨진 `None`이거나 반응형 `nil`일 수 있다는 안내도 붙습니다). `noMatchMessage` 헬퍼가 만드는 문구이고, `Dispatch.process`의 매치 실패 raise가 이 헬퍼를 부릅니다.
- **고치려면**: 그 값을 다루는 프로바이더(quad-roblox 등)가 설치돼 있는지 확인하거나, 그 값을 올바른 종류의 키(숫자/문자) 자리에 놓으세요.
- **참고**: [`q.Dispatch.process(inst, key, value, index)`](../extend/02-dispatch-handler-contract.md#qdispatchprocessinst-key-value-index)

### Quad0077

`Dispatch: handler {describeHandler(h)} returned no retractor at key {tostring(k)}, index {index} — return Void when there is nothing to undo` — `quad-base/src/Dispatch/init.luau`

- **언제**: 매치된 핸들러의 `process`가 retractor(되돌리는 함수)를 돌려주지 않았을 때 — 프로바이더 계약 위반입니다. `noRetractorMessage` 헬퍼가 만드는 문구이고, `process`의 두 갈래(같은 핸들러 재처리 / 다른 핸들러로 교체) raise가 모두 이 헬퍼를 부릅니다.
- **고치려면**: 그 핸들러를 만든 쪽이 `process`에서 항상 함수(할 일이 없으면 `q.Void`)를 돌려주게 고치세요.
- **참고**: [`q.Dispatch.addHandler(handler)`](../extend/02-dispatch-handler-contract.md#qdispatchaddhandlerhandler)

### Quad0079

`Dispatch.addHandler: handler must be a table with isHandlable/process functions and a numeric priority (got {typeof(handler)})` — `quad-base/src/Dispatch/init.luau`

- **언제**: `q.Dispatch.addHandler`에 넘긴 `handler`가 테이블이 아니거나, `isHandlable`/`process`가 함수가 아니거나, `priority`가 숫자가 아닐 때.
- **고치려면**: `{ isHandlable, process, priority, ... }` 모양의 핸들러 레코드를 넘기세요.
- **참고**: [`q.Dispatch.addHandler(handler)`](../extend/02-dispatch-handler-contract.md#qdispatchaddhandlerhandler)

### Quad0080

`Dispatch.addHandler: priority must be a finite number (got {tostring(pr)})` — `quad-base/src/Dispatch/init.luau`

- **언제**: `handler.priority`가 NaN이거나 ±무한대일 때 — 그런 값은 정렬 순서를 정의할 수 없고 동률 검사(`==`)도 항상 거짓이 됩니다.
- **고치려면**: `HANDLER_PRIORITY_*` 밴드에서 오프셋한 유한한 숫자를 쓰세요.
- **참고**: [`q.Dispatch.addHandler(handler)`](../extend/02-dispatch-handler-contract.md#qdispatchaddhandlerhandler)

### Quad0081

`Dispatch.addHandler: keyType must be "number", "string" or nil (got {tostring(kt)})` — `quad-base/src/Dispatch/init.luau`

- **언제**: `handler.keyType`이 `"number"`/`"string"`/`nil` 중 하나가 아닐 때 — 오타가 있으면 그 핸들러가 어느 버킷에도 안 들어가 조용히 매치되지 않게 됩니다.
- **고치려면**: `keyType`은 생략하거나 `"number"`/`"string"` 중 하나로 쓰세요.
- **참고**: [`q.Dispatch.addHandler(handler)`](../extend/02-dispatch-handler-contract.md#qdispatchaddhandlerhandler)

### Quad0082

`Dispatch.drive: props must be a table (got {typeof(flattened)})` — `quad-base/src/Dispatch/init.luau`

- **언제**: `q.Dispatch.drive(inst, flattened)`의 `flattened`가 테이블이 아닐 때(백엔드의 생성 경로/`Claim`이 아니라 직접 부를 때 밟을 수 있는 자리입니다).
- **고치려면**: props 테이블을 넘기세요.
- **참고**: [`q.Dispatch.drive(inst, flattened)`](../extend/02-dispatch-handler-contract.md#qdispatchdriveinst-flattened)

### Quad0083

`Dispatch.drive: props must be a plain \{ ... \} table — a quad value needs the braces (got {brandNameOf(flattened) or "a table with a metatable"})` — `quad-base/src/Dispatch/init.luau`

- **언제**: `flattened` 자체가 메타테이블을 가진 값(quad 값 등)일 때 — `D.Frame(q.Source(1))`처럼 중괄호를 잊어 quad 값 하나를 그대로 props로 넘긴 흔한 실수를 잡습니다.
- **고치려면**: 항상 중괄호로 감싼 평범한 테이블을 넘기세요 — `D.Frame { q.Source(1) }`.
- **참고**: [`q.Dispatch.drive(inst, flattened)`](../extend/02-dispatch-handler-contract.md#qdispatchdriveinst-flattened)

### Quad0084

`Dispatch.drive: inst must not be nil` — `quad-base/src/Dispatch/init.luau`

- **언제**: `q.Dispatch.drive`를 `inst = nil`로 부를 때.
- **고치려면**: 실제 대상 요소를 넘기세요.
- **참고**: [`q.Dispatch.drive(inst, flattened)`](../extend/02-dispatch-handler-contract.md#qdispatchdriveinst-flattened)

### Quad0085

`Dispatch.drive: array keys must be positive integers (got {k})` — `quad-base/src/Dispatch/init.luau`

- **언제**: `flattened`의 숫자 키 중 하나가 1 이상의 정수가 아닐 때(0, 음수, 소수 등) — 어떤 핸들러가 부기를 만지기 전에 먼저 봅니다.
- **고치려면**: 배열부 키는 1부터 시작하는 정수만 쓰세요(중간의 `nil` 구멍은 별개로 정의되지 않은 동작입니다).
- **참고**: [`q.Dispatch.drive(inst, flattened)`](../extend/02-dispatch-handler-contract.md#qdispatchdriveinst-flattened)
