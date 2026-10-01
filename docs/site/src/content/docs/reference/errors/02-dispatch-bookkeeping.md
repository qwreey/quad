---
title: "에러 코드 — 디스패치와 장부"
description: "Dispatch/Bookkeeping/Modifier/None/핸들러 계약이 던지는 에러"
---
각 절은 `### QuadNNNN` — 메시지 원문(자리표시자는 `{…}`), 언제 나는가, 어떻게 고치는가. 번호로 찾으려면 [색인](/reference/errors/00-index/).


### Quad0019

`Bookkeeping.{fnName}: position must be a positive integer (got {tostring(i)})` — `quad-base/src/Bookkeeping.luau`

- **언제**: `q.Bookkeeping.setLength`/`setOffsetSource`/`setEmpty`/`getOffsetAt` 등 위치(`i`/`at`)를 받는 공개 함수에 양의 정수가 아닌 값을 넘겼을 때. `{fnName}`은 실제로 부른 함수 이름입니다.
- **고치려면**: 1부터 시작하는 정수를 넘기세요.
- **참고**: [Length/Offset 부기](/reference/extend/02-dispatch-handler-contract/#lengthoffset-부기)

### Quad0020

`Bookkeeping.{fnName}: ownerKey must not be nil` — `quad-base/src/Bookkeeping.luau`

- **언제**: `q.Bookkeeping`의 부기 함수(`getBookkeeping`/`getOffsetAt`/`setLength`/`setOffsetSource`/`setEmpty`)에 `ownerKey`(부기의 주인 — 요소 또는 Slot)로 `nil`을 넘겼을 때. `{fnName}`은 부른 함수 이름입니다. 같은 조건이라도 `claimOwnerAt`은 Quad0158, `releaseOwner`는 Quad0162로 따로 던집니다.
- **고치려면**: 실제 owner를 넘기세요.
- **참고**: [Length/Offset 부기](/reference/extend/02-dispatch-handler-contract/#lengthoffset-부기)

### Quad0021

`Bookkeeping.{fnName}: length must be a non-negative integer (got {tostring(n)})` — `quad-base/src/Bookkeeping.luau`

- **언제**: `q.Bookkeeping.setLength(ownerKey, i, len, ...)`의 `len`(상수인 경우), `State`인 경우 등록하는 순간의 현재 값(그 `setLength` 줄에서, 부기를 쓰기 전에), 또는 그 뒤 그 `State`가 내놓은 값(그 `:Set` 줄에서)이 음수/소수/숫자가 아닐 때.
- **고치려면**: 0 이상의 정수를 쓰세요.
- **참고**: [`q.Bookkeeping.setLength(ownerKey, i, len, anchor, element)`](/reference/extend/02-dispatch-handler-contract/#qbookkeepingsetlengthownerkey-i-len-anchor-element)

### Quad0022

`Bookkeeping.getOffsetAt: position {at} is past N+1 (N = {last}, at most {last + 1} may be queried) - or a leaf handler skipped its position registration: position {i} is not registered` — `quad-base/src/Bookkeeping.luau`

- **언제**: `q.Bookkeeping.getOffsetAt(ownerKey, at)`으로 조회한 `at`이 등록된 마지막 위치(`N`) + 1보다 클 때 — 범위 밖 조회입니다. (같은 자리에서 중간의 어떤 위치가 등록 자체를 건너뛴 경우도 이 갈래로 잡힙니다 — 두 원인을 코드가 구분할 수 없어 메시지가 둘 다 말합니다.) `q.Bookkeeping.setOffsetSource(ownerKey, i, source)`도 내부에서 `getOffsetAt(ownerKey, i)`를 부르므로, `i` 앞 위치들이 아직 등록되지 않았으면 같은 메시지가 납니다 — 이때 메시지는 직접 부르지 않은 `getOffsetAt`을 말합니다.
- **고치려면**: 등록된 범위(`1..N+1`) 안에서 조회하세요. 조회나 `setOffsetSource` 전에 그 앞 위치들을 **계약 순서대로**(위치마다 `setOffsetSource` → `setLength`, 또는 `setEmpty` 하나) 먼저 등록하세요 — 위치를 등록하는 것은 `setLength`/`setEmpty`뿐이고 `setOffsetSource`는 등록하지 않고 앞 위치를 조회합니다. 앞 위치를 `setLength`만으로 등록하면 이 에러 대신 `Quad0023`(그 위치의 발행 채널이 없음)이 납니다([2026-09-27 mock 실측]).
- **참고**: [`q.Bookkeeping.getOffsetAt(ownerKey, at)`](/reference/extend/02-dispatch-handler-contract/#qbookkeepinggetoffsetatownerkey-at)

### Quad0023

`Bookkeeping.recompute: sourceList[{i}] is nil - a nil hole in the numeric-key part of props ({ a, nil, b })? fill the optional slot with q.None (the children placed before this raise stay seated in the half-built Instance, reachable as child.Parent - q.dispose that Instance to clean up; it takes those children with it, so build the retry with new ones); if you are writing a handler, bookkeeping is broken (setLength without setOffsetSource? the contract says None)` — `quad-base/src/Bookkeeping.luau`

- **언제**: 재계산 도중 위치 `i`의 오프셋 발행 채널(`sourceList[i]`)이 `nil`일 때 — 대표 원인은 배열 리터럴 중간에 `nil`이 낀 props(`{ a, nil, b }`)이고, 핸들러를 직접 쓰는 입장이면 `setOffsetSource`(또는 `setEmpty`) 등록을 빠뜨린 경우입니다.
- **고치려면**: 사용자라면 그 옵셔널 자리를 `q.None`으로 채우세요. 핸들러 작성자라면 그 자리의 `setOffsetSource` 등록을 빠뜨리지 않았는지 확인하세요. 이 에러가 난 뒤 그 Instance는 반쯤 지어진 채(구멍 뒤 자식까지 붙어 있음 — 메시지의 "children placed before this raise"보다 넓음) 남습니다 — 같은 자식 값으로 다시 만들면 `Quad0160`, 그 Instance를 dispose한 뒤 다시 쓰면 `Quad0219`가 나니, 호스트를 dispose하고 자식도 새로 만들어 처음부터 하세요([2026-09-27 mock 실측 — 관측, 계약 아님]).
- **참고**: [Length/Offset 부기](/reference/extend/02-dispatch-handler-contract/#lengthoffset-부기)

### Quad0024

`Bookkeeping.recompute: lengthList[{i}] is nil - bookkeeping is broken (setOffsetSource without setLength?)` — `quad-base/src/Bookkeeping.luau`

- **언제**: 재계산 도중 위치 `i`의 길이(`lengthList[i]`)가 `nil`일 때 — 내부 불변식 위반으로, 어떤 핸들러가 `setOffsetSource`만 부르고 `setLength`는 부르지 않은 경우입니다.
- **고치려면**: 그 핸들러가 `setLength`도 함께 부르게 하세요(또는 둘 다 하는 `setEmpty`를 쓰세요).
- **참고**: [Length/Offset 부기](/reference/extend/02-dispatch-handler-contract/#lengthoffset-부기)

### Quad0025

`Bookkeeping.setOffsetSource: source must be a Source<number> or None (got {typeof(source)})` — `quad-base/src/Bookkeeping.luau`

- **언제**: `q.Bookkeeping.setOffsetSource(ownerKey, i, source)`의 `source`가 `Source<number>`도 `q.None`도 아닐 때.
- **고치려면**: 부기 채널로 `Source<number>`나 `q.None`(발행 채널 없음)을 넘기세요.
- **참고**: [`q.Bookkeeping.setOffsetSource(ownerKey, i, source)`](/reference/extend/02-dispatch-handler-contract/#qbookkeepingsetoffsetsourceownerkey-i-source)

### Quad0229

`Bookkeeping.getOffsetAt: position {at} needs positions 1..{at - 1} registered but {i} is not - a leaf handler skipped its position registration` — `quad-base/src/Bookkeeping.luau`

- **언제**: 조회한 `at`은 등록 범위 안(`N+1` 이하)인데, 그 앞의 어떤 위치 `i`가 등록되지 않았을 때 — 어떤 leaf 핸들러가 자기 자리의 위치 등록(`setLength`/`setOffsetSource`)을 건너뛴 경우입니다. `getOffsetAt`의 if/else 두 갈래 중 하나로, 같은 조건문의 다른 갈래가 Quad0022입니다. [2026-09-27 실측] 실제로는 배치 차단기(`drive`·Slot 내부가 켜는 것)가 켜져 재계산이 미뤄진 동안에만 이 갈래가 보입니다 — 차단기 밖에서 구멍이 생기면 `setLength`/`setEmpty` 끝의 재계산이 Quad0023/Quad0024로 먼저 던집니다.
- **고치려면**: 그 자리를 담당한 핸들러가 반드시 `setLength`와 `setOffsetSource`(또는 그 둘을 한 번에 하는 `setEmpty`)를 부르게 하세요.
- **참고**: [`q.Bookkeeping.getOffsetAt(ownerKey, at)`](/reference/extend/02-dispatch-handler-contract/#qbookkeepinggetoffsetatownerkey-at)

### Quad0049

`Modifier:Peek: key must be a non-empty string (got {if key == "" then '""' else typeof(key)})` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: `mod:Peek(key)`를 부를 때 `key`가 빈 문자열이거나 문자열이 아닌 경우. setter 경로(`mod:Field(...)`)가 거부하는 것과 같은 키 도메인이라, 예전에는 `Peek`이 그런 키에 조용히 `nil`을 돌려주던 것을 바로잡았습니다.
- **고치려면**: 필드 이름은 비어있지 않은 문자열로 넘기세요.
- **참고**: [`mod:Peek<<T>>(key)`](/reference/core/08-modifier/#modpeektkey)

### Quad0050

`Modifier:Apply: factory must be a function (got {typeof(factory)})` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: `mod:Apply(factory)`의 `factory`가 함수가 아닐 때.
- **고치려면**: Modifier를 받아 값을 돌려주는 함수를 넘기세요.
- **참고**: [`mod:Apply(factory)`](/reference/core/08-modifier/#modapplyfactory)

### Quad0051

`Modifier:As: name must be a class name string (got {typeof(name)})` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: `mod:As(name)`에서 `name`을 줬는데 문자열이 아닐 때(생략은 허용됩니다).
- **고치려면**: 클래스 이름 문자열을 넘기거나 생략하세요.
- **참고**: [`mod:As(name)`](/reference/core/08-modifier/#modasname)

### Quad0052

`Modifier: unknown modifier class "{name}" - Modifier.TypedFactory/DefineSubtype it first` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: `mod:As(name)`에 준 `name`이 아직 `Modifier.TypedFactory`나 `DefineSubtype`으로 등록되지 않은 클래스일 때.
- **고치려면**: 먼저 `q.Modifier.TypedFactory(name)`이나 `DefineSubtype`으로 그 이름을 등록하세요.
- **참고**: [`mod:As(name)`](/reference/core/08-modifier/#modasname)

### Quad0053

`Modifier.Overridden: must be given at least one Modifier` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: `q.Modifier.Overridden(...)`을 인자 없이 부를 때. 콜론 형태 `mod:Overridden()`은 `mod` 자신이 첫 인자로 들어가므로 이 에러가 나지 않습니다.
- **고치려면**: 합칠 Modifier를 최소 하나 넘기세요.
- **참고**: [`q.Modifier.Overridden(...)`](/reference/core/08-modifier/#qmodifieroverridden)

### Quad0054

`Modifier.Overridden: argument #{i} is not a Modifier (got {typeof(arg)})` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: `Overridden`에 넘긴 인자 중 하나가 Modifier가 아닐 때 — `q.Modifier(...)`와 달리 평범한 필드 테이블은 받지 않습니다.
- **고치려면**: 모든 인자를 Modifier로 넘기세요 — 평범한 테이블을 합치려면 `q.Modifier(...)`를 쓰세요.
- **참고**: [`q.Modifier.Overridden(...)`](/reference/core/08-modifier/#qmodifieroverridden)

### Quad0055

`Modifier: unknown modifier class "{target}" - Modifier.TypedFactory/DefineSubtype it first (or use :As(name) for an unchecked cast)` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: `mod:As<Class>()` 검사형 다운캐스트의 대상 클래스가 아직 등록되지 않았을 때.
- **고치려면**: 대상 클래스를 `TypedFactory`/`DefineSubtype`으로 먼저 등록하세요. 메시지가 안내하는 `mod:As(name)`은 조상 검사만 건너뛰고 이름이 등록됐는지는 똑같이 검사하므로, 등록되지 않은 이름에는 `:As(name)`도 Quad0052로 거부됩니다.
- **참고**: [`mod:As<Class>()`](/reference/core/08-modifier/#modasclass)

### Quad0056

`Modifier: cannot cast a "{tag}" modifier to "{target}" - not an ancestor (use :As(name) to force)` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: `mod:As<Class>()`의 대상이 등록은 돼 있지만, 지금 Modifier의 태그가 무타입도 대상 자신도 대상의 조상도 아닐 때.
- **고치려면**: 실제 조상/자손 관계를 확인하거나, 조상 검사 없이 강제로 태그를 바꾸려면 `mod:As(name)`을 쓰세요.
- **참고**: [`mod:As<Class>()`](/reference/core/08-modifier/#modasclass)

### Quad0057

`Modifier: field "{key}" cannot hold a handler-layer value (Ref/Observer/Effect/Slot/Modifier/mapper descriptor)` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: `mod:Field(value)`의 `value`(리터럴이든 변환 함수의 반환이든)가 `Ref`/`PreRef`/`PostRef`/`Observer`/`Effect`/`Slot`/`Modifier` 같은 핸들러 계층 값이거나 `Claim`/`Mapper`의 디스크립터(`M.Frame("Title")` 등 — 숫자 키 자리에서만 해석되는 값)일 때. `State`/`Source`는 통과합니다(`State`가 디스크립터를 담은 경우는 만들 때 값을 읽지 않으므로 여기서 걸리지 않습니다).
- **고치려면**: 그 값은 필드가 아니라 props의 숫자 키 자리에 놓으세요.
- **참고**: [`mod:<Field>(value)`](/reference/core/08-modifier/#modfieldvalue)

### Quad0058

`Modifier: setter keys must be strings (got {typeof(key)}) - put a non-string key in the props table itself (Frame { [key] = value })` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: `mod[key](...)`를 문자열이 아닌 `key`로 부를 때(`AttrKey`/`MapperDescriptor` 같은 비문자열 키). 생성자의 같은 규칙(Quad0059)과 짝입니다.
- **고치려면**: 그 키는 Modifier가 아니라 props 테이블에 직접(`[key] = value`) 넣으세요.
- **참고**: [`mod:<Field>(value)`](/reference/core/08-modifier/#modfieldvalue)

### Quad0059

`Modifier: initial-field table keys must be non-empty field names (got {if k == "" then '""' else typeof(k)} at argument #{i})` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: `q.Modifier{ ... }`/`D.Modifier.<Class>{ ... }` 생성자에 넘긴 필드 테이블의 키가 빈 문자열이거나 문자열이 아닐 때.
- **고치려면**: 필드 이름은 비어있지 않은 문자열로 쓰세요.
- **참고**: [`q.Modifier(...)`](/reference/core/08-modifier/#qmodifier)

### Quad0060

`Modifier: field "{k}" collides with a reserved Modifier method` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: 초기 필드 테이블의 키가 `Peek`/`Apply`/`Overridden`/`As` 같은 예약 메소드 이름과 같을 때 — setter 경로에서는 애초에 만들어질 수 없는 필드라 생성자도 같은 이름을 거부합니다.
- **고치려면**: 그 이름을 피하세요 — 예약 메소드는 필드가 될 수 없습니다.
- **참고**: [`q.Modifier(...)`](/reference/core/08-modifier/#qmodifier)

### Quad0061

`Modifier: field "{k}" matches the reserved cast prefix As<Class> - casts are methods, not fields` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: 초기 필드 테이블의 키가 `As` + 대문자로 시작하는 예약된 캐스트 접두사 모양일 때.
- **고치려면**: 그 이름을 피하세요 — `As<Class>` 모양은 항상 캐스트 메소드로 예약돼 있습니다.
- **참고**: [`q.Modifier(...)`](/reference/core/08-modifier/#qmodifier)

### Quad0062

`Modifier: field "{k}" starts with "__" - metamethod-looking names are never properties` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: 초기 필드 테이블의 키가 `"__"`로 시작할 때 — setter 경로(`__index`)도 그런 이름엔 항상 `nil`을 돌려주므로 생성자에서도 같은 이름을 막습니다.
- **고치려면**: `"__"`로 시작하지 않는 필드 이름을 쓰세요.
- **참고**: [`q.Modifier(...)`](/reference/core/08-modifier/#qmodifier)

### Quad0063

`Modifier: field "{k}" in an initial-field table cannot be a function - a transform goes through mod:{k}(fn); an event handler does not belong in a Modifier (put it as an inline key on the Declaration, or wrap it in a State)` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: 초기 필드 테이블의 값으로 함수를 줬을 때 — setter 자리에서 함수는 변환 함수라는 다른 뜻이라, 생성자에서 그대로 받으면 두 경로가 조용히 갈립니다.
- **고치려면**: 변환이 필요하면 `mod:{k}(fn)`을 쓰고, 이벤트 핸들러라면 Modifier가 아니라 Declaration의 인라인 키나 State로 넘기세요.
- **참고**: [`q.Modifier(...)`](/reference/core/08-modifier/#qmodifier)

### Quad0064

`Modifier: field "{k}" cannot hold a handler-layer value (Ref/Observer/Effect/Slot/Modifier/mapper descriptor)` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: 초기 필드 테이블의 값이 핸들러 계층 값(`Ref`/`Observer`/`Effect`/`Slot`/`Modifier`)이거나 `Claim`/`Mapper`의 디스크립터일 때 — setter 경로(Quad0057)와 같은 규칙을 생성자에도 적용합니다.
- **고치려면**: 그 값은 필드가 아니라 props의 숫자 키 자리에 놓으세요.
- **참고**: [`q.Modifier(...)`](/reference/core/08-modifier/#qmodifier)

### Quad0065

`Modifier: argument #{i} must be a Modifier or a plain field table (got {typeof(arg)})` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: `q.Modifier(...)`/`D.Modifier.<Class>(...)`에 넘긴 인자가 Modifier도, 메타테이블 없는 평범한 필드 테이블도 아닐 때(`Source`/`Ref`/`Tag` 같은 다른 quad 값을 넘긴 경우 등).
- **고치려면**: Modifier나 평범한 `{ field = value }` 테이블만 넘기세요.
- **참고**: [`q.Modifier(...)`](/reference/core/08-modifier/#qmodifier)

### Quad0066

`Modifier.{fn}: {what} must be a non-empty class name string (got {typeof(name)})` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: `q.Modifier.TypedFactory(name)`의 `name`이나 `q.Modifier.DefineSubtype(parent, subtype)`의 `parent`/`subtype`이 빈 문자열이거나 문자열이 아닐 때. `{fn}`/`{what}`은 실제로 부른 함수와 검사한 인자 이름입니다.
- **고치려면**: 비어있지 않은 클래스 이름 문자열을 넘기세요.
- **참고**: [`q.Modifier.TypedFactory<<T>>(name)`](/reference/core/08-modifier/#qmodifiertypedfactorytname)

### Quad0067

`Modifier.DefineSubtype: cannot make "{subtype}" a subtype of "{parent}" - that would make a cycle` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: `q.Modifier.DefineSubtype(parent, subtype)`이 등록하려는 간선이 이미 있는 조상 관계를 거슬러 올라가 순환을 만들 때.
- **고치려면**: 순환이 생기지 않는 방향으로 등록하세요.
- **참고**: [`q.Modifier.DefineSubtype(parent, subtype)`](/reference/core/08-modifier/#qmodifierdefinesubtypeparent-subtype)

### Quad0068

`Modifier: a Modifier cannot be a value of key "{tostring(k)}" - place it in the array part` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: Modifier를 props의 문자 키 값 자리에 뒀을 때 — 합칠 대상이 없는 자리입니다. 1부터 빈틈 없이 이어지는 배열부 밖의 숫자 키(`{ [5] = mod }`처럼 앞 자리가 비어 있는 키)도 배열부가 아니라서 같은 에러가 납니다 — 메시지에는 그 숫자가 키 이름으로 나옵니다.
- **고치려면**: Modifier는 1부터 빈틈 없이 이어지는 숫자 키(배열부) 자리에 놓으세요.
- **참고**: [숫자 키 자리에 놓는다](/reference/core/08-modifier/#숫자-키-자리에-놓는다)

### Quad0069

`{kind}: already used - a {kind} is one-shot (used up once quad places it, fired or not); make a new one for each instance` — `quad-base/src/Dispatch/Ref.luau`

- **언제**: 이미 한 번 props 숫자 키 자리에 놓여 처리된 `PreRef`/`PostRef`를 또 놓았을 때 — 다른 인스턴스의 props든, 같은 props 안의 두 자리(`{ p, p }`)든 마찬가지입니다. 표시는 quad가 자리에 놓인 값을 처리하는 순간 붙으므로 `PostRef`는 아직 발화하기 전이어도 해당하고, 사용자가 직접 `ref:Set(inst)`만 한 값은 해당하지 않습니다. `{kind}`는 `PreRef` 또는 `PostRef`입니다.
- **고치려면**: 인스턴스마다 새 `PreRef`/`PostRef`를 만드세요 — 하나를 재사용하지 마세요.
- **참고**: [숫자 키 자리에만 놓는다](/reference/core/07-ref/#숫자-키-자리에만-놓는다)

### Quad0070

`State: the value chain is circular (a State that eventually holds itself) - a State may hold another State, but not a cycle` — `quad-base/src/StoreBind.luau`

- **언제**: props 자리에 놓인 State의 값을 따라가다(State가 다른 State를 값으로 들고 있으면 그 State도 마저 벗기는 재귀) 결국 자기 자신으로 돌아오는 순환을 만났을 때(예: `a:Set(b); b:Set(a)`). **[2026-10-01]** Slot에 넣은 State도 같습니다 — 원소 State의 값 사슬이 순환하면(`st:Set(st)` 등) 넣는 줄이나 그 `:Set` 줄에서 던집니다(그 뒤 Slot의 상태는 계약이 아닙니다 — 지금은 이전 원소를 유지한 채 다음 정상 `:Set`으로 이어지는 것이 관측됨).
- **고치려면**: State가 다른 State를 값으로 들고 있는 것 자체는 되지만, 그 사슬이 순환하면 안 됩니다 — 순환이 생기지 않게 값 대입을 정리하세요.
- **참고**: [Quadnomicon Vol. 8 — 확장 가능한 디스패치 엔진](/quadnomicon/08-extensible-dispatch-engine/) · [`slot:Add`](/reference/core/06-slot/#slotaddelement-index)

### Quad0071

`Dispatch.retractFrom: no slot at index {i} - the chain array has a hole, bookkeeping is broken` — `quad-base/src/Dispatch/init.luau`

- **언제**: `retractFrom`이 체인 배열을 되감다가 구멍(`nil` 슬롯)을 만났을 때 — 계약을 지키는 호출로는 나지 않는 내부 불변식 위반입니다. 다만 계약을 어긴 호출은 공개 함수 `retractFrom`을 거쳐 이 상태에 닿을 수 있습니다 — 위임 핸들러의 안쪽 retractor가 같은 `(inst, key)`에 `retractFrom`을 다시 부르는 **간접 재진입**(정의되지 않은 동작 — [2026-09-27 mock 실측]).
- **고치려면**: retractor 안에서 같은 자리를 다시 철거하지 마세요(재진입은 계약 밖). 그런 코드가 없는데 났다면 내부 버그 신호입니다 — 재현되면 리포트하세요.
- **참고**: [`q.Dispatch.retractFrom(inst, key, index)`](/reference/extend/02-dispatch-handler-contract/#qdispatchretractfrominst-key-index)

### Quad0072

`Dispatch.{fnName}: inst must not be nil` — `quad-base/src/Dispatch/init.luau`

- **언제**: `q.Dispatch.process`/`q.Dispatch.retractFrom`/`q.Dispatch.getHandler`를 `inst = nil`로 직접 부를 때. `{fnName}`은 실제로 부른 함수 이름입니다(`getHandler`는 **[2026-09-26 기준]** 추가된 게이트).
- **고치려면**: 실제 대상 요소(`inst`)를 넘기세요.
- **참고**: [`q.Dispatch.process(inst, key, value, index)`](/reference/extend/02-dispatch-handler-contract/#qdispatchprocessinst-key-value-index)

### Quad0073

`Dispatch.{fnName}: index must be a positive integer (got {tostring(index)})` — `quad-base/src/Dispatch/init.luau`

- **언제**: `q.Dispatch.process`/`q.Dispatch.retractFrom`의 `index`가 1 이상의 정수가 아닐 때.
- **고치려면**: 체인 깊이는 1부터 시작하는 정수입니다 — 최초 진입은 `1`, 위임은 `index + 1`을 넘기세요.
- **참고**: [`q.Dispatch.process(inst, key, value, index)`](/reference/extend/02-dispatch-handler-contract/#qdispatchprocessinst-key-value-index)

### Quad0074

`Dispatch.{fnName}: key must not be nil` — `quad-base/src/Dispatch/init.luau`

- **언제**: `q.Dispatch.process`/`q.Dispatch.retractFrom`/`q.Dispatch.getHandler`를 `key = nil`로 부를 때(`getHandler`는 **[2026-09-26 기준]** 추가된 게이트).
- **고치려면**: 실제 props 키(숫자 또는 문자열)를 넘기세요.
- **참고**: [`q.Dispatch.process(inst, key, value, index)`](/reference/extend/02-dispatch-handler-contract/#qdispatchprocessinst-key-value-index)

### Quad0075

`Dispatch.process: index {index} would leave a gap in the chain (the chain has {#list} slots - a delegating handler passes index + 1)` — `quad-base/src/Dispatch/init.luau`

- **언제**: `process`에 준 `index`가 그 자리 체인의 다음 자연스러운 깊이(`#list + 1`)보다 클 때 — 위임 핸들러가 `index + 1`이 아닌 값을 건너뛰어 부른 경우입니다.
- **고치려면**: 위임할 때는 항상 받은 `index + 1`을 그대로 넘기세요.
- **참고**: [`q.Dispatch.process(inst, key, value, index)`](/reference/extend/02-dispatch-handler-contract/#qdispatchprocessinst-key-value-index)

### Quad0076

`Dispatch: no handler matched key {tostring(k)} (value: {typeof(v)}[, brand: {brands}])` + 꼬리 힌트 하나(+ nil 안내) — `brand:`는 브랜드가 있을 때만 붙습니다 — `quad-base/src/Dispatch/init.luau`

`brand:` 뒤에는 그 값이 답하는 브랜드 이름이 **전부, 이름순으로** 쉼표로 이어 붙습니다 — 모듈의 `is<Brand>` 필드 가운데 [`q.BrandPredicates`](/reference/core/11-predicates/#qbrandpredicates)에 등록된 술어만 묻습니다(quad-base의 `q.isX` 술어도 모듈이 만들어질 때 같은 집합에 등록됩니다). 그래서 `q.PreRef()`는 `Epoch, PreRef, Ref`, `q.Source(1)`은 `Epoch, Source, State`처럼 포함 관계에 있는 이름이 함께 나옵니다. 등록되지 않은 `is*` 헬퍼는 묻지 않고, 등록된 술어가 던지면 그 술어는 걸리지 않은 것으로 칩니다.

꼬리 힌트는 여섯 중 하나입니다 — 값이 등록된 브랜드 술어에 하나도 걸리지 않고 키가 **문자 키**면 ` - this key may not be a field of this element (a typo, a read-only field, or one from another class), or the provider that handles it (e.g. quad-roblox) is not initialized`(프로바이더가 설치된 흔한 경우엔 앞쪽 원인 — 오타 난 이름, 읽기 전용 프로퍼티, 다른 클래스의 이름 — 이고, 두 경우를 이 자리에서 가를 수 없어 둘 다 적습니다), 같은 값이 숫자 키면 ` - check that the provider for this value (e.g. quad-roblox) is initialized`; 등록된 술어에 하나라도 걸리면 — 등록됐다는 것은 그 브랜드의 주인(quad-base는 늘, 프로바이더는 설치 때 등록)이 설치돼 있다는 뜻이라 quad-base 브랜드(`Slot`/`Ref`/`State`/`Tag`/`Attr`/`Context`/`Provider`/`MapperDescriptor` 등)와 프로바이더 브랜드(`Tween` 등)가 같은 힌트를 받습니다 — 브랜드 이름 가운데 `Store`가 있을 때 ` - a Store is not a value for any key: use one of its fields (store.Name) or wrap it (q.Attr(store))`, `Context`/`Provider`가 있을 때 ` - a Context is not a value for any key: read the value you need out of it first`(그 이름이 들어갑니다), 그 밖의 브랜드가 문자 키일 때 ` - a quad value at a string key: it belongs in a numeric (array) slot`, 숫자 키일 때 ` - this quad value has no handler at an array position`. 값이 `nil`이면 그 뒤에 ` (a nil at this depth may be an unwrapped None or a reactive nil - the key's own handler must accept nil)`이 더 붙습니다. `brand: …` 조각은 등록된 술어에 걸린 것이 있을 때만 들어갑니다.

- **언제**: 그 값을 받아줄 핸들러가 하나도 없을 때. `noMatchMessage` 헬퍼가 만드는 문구이고, `Dispatch.process`의 매치 실패 raise가 이 헬퍼를 부릅니다.
- **고치려면**: 프로바이더(quad-roblox 등)가 설치돼 있다면 가장 흔한 원인은 문자 키 쪽입니다 — 그 클래스에 없는(오타 난) 프로퍼티·이벤트 이름, 읽기 전용 프로퍼티(`AbsoluteSize` 등 — 읽으려면 `q.OnChange`), 그리고 `Parent`(props가 아니라 만든 뒤 밖에서 `inst.Parent = …`로 붙입니다)를 확인하세요. quad 값이라면 올바른 종류의 키(숫자/문자) 자리에 놓으세요(배열 원소로만 쓰는 값 — `Tag`·`Attr` 등 — 이 반영 프로퍼티 이름 키에 놓이면 이 에러 대신 프로퍼티 핸들러가 먼저 받습니다; `q.debug`를 켜면 그 자리를 한 줄로 알려 줍니다) — 단 `Store`·`Context`·`Provider`는 어느 키에도 그대로 놓이지 않으니(숫자 키로 옮겨도 같은 에러) 메시지 꼬리대로 하세요 — `Store`는 `store.Name` 같은 필드를 놓거나 `q.Attr(store)`로 감싸고, `Context`/`Provider`는 필요한 값을 먼저 읽어 내세요. 설치 전이라면 그 값을 다루는 프로바이더가 설치돼 있는지 확인하세요.
- **참고**: [`q.Dispatch.process(inst, key, value, index)`](/reference/extend/02-dispatch-handler-contract/#qdispatchprocessinst-key-value-index)

### Quad0077

`Dispatch: handler {describeHandler(h)} must return a retractor function at key {tostring(k)}, index {index} (got {typeof(retractor)}) - return Void when there is nothing to undo` — `quad-base/src/Dispatch/init.luau`

- **언제**: 매치된 핸들러의 `process`가 retractor(되돌리는 함수)를 돌려주지 않았을 때 — 프로바이더 계약 위반입니다. `nil`은 늘 검사하고, 함수가 아닌 다른 값(`true`·숫자·테이블, `__call` 테이블 포함 — `addHandler`가 `process` 자체에 거는 [`Quad0079`](#quad0079)와 같은 기준)은 [`q.debug`](/reference/core/01-quad-module/#qdebug)가 켜져 있을 때만 검사합니다(매 `process`마다 도는 경로라 평소 비용을 더하지 않습니다). `q.debug`가 꺼져 있으면 그런 값은 저장됐다가 그 자리를 무를 때 quad 안에서 번호 없는 에러로 죽습니다. `noRetractorMessage` 헬퍼가 만드는 문구이고, `process`의 두 갈래(같은 핸들러 재처리 / 다른 핸들러로 교체)의 `nil` 검사와 debug 검사가 모두 이 헬퍼를 부릅니다.
- **고치려면**: 그 핸들러를 만든 쪽이 `process`에서 항상 함수(할 일이 없으면 `q.Void`)를 돌려주게 고치세요. 프로바이더를 만들 때는 `q.debug`를 켜고 시험하세요.
- **참고**: [`q.Dispatch.addHandler(handler)`](/reference/extend/02-dispatch-handler-contract/#qdispatchaddhandlerhandler)

### Quad0079

`Dispatch.addHandler: handler must be a table with isHandlable/process functions and a numeric priority (got {typeof(handler)})` — `quad-base/src/Dispatch/init.luau`

- **언제**: `q.Dispatch.addHandler`에 넘긴 `handler`가 테이블이 아니거나, `isHandlable`/`process`가 함수가 아니거나, `priority`가 숫자가 아닐 때.
- **고치려면**: `{ isHandlable, process, priority, ... }` 모양의 핸들러 레코드를 넘기세요.
- **참고**: [`q.Dispatch.addHandler(handler)`](/reference/extend/02-dispatch-handler-contract/#qdispatchaddhandlerhandler)

### Quad0080

`Dispatch.addHandler: priority must be a finite number (got {tostring(pr)})` — `quad-base/src/Dispatch/init.luau`

- **언제**: `handler.priority`가 NaN이거나 ±무한대일 때 — 그런 값은 정렬 순서를 정의할 수 없고 동률 검사(`==`)도 항상 거짓이 됩니다.
- **고치려면**: `HANDLER_PRIORITY_*` 밴드에서 오프셋한 유한한 숫자를 쓰세요.
- **참고**: [`q.Dispatch.addHandler(handler)`](/reference/extend/02-dispatch-handler-contract/#qdispatchaddhandlerhandler)

### Quad0081

`Dispatch.addHandler: keyType must be "number", "string" or nil (got {tostring(kt)})` — `quad-base/src/Dispatch/init.luau`

- **언제**: `handler.keyType`이 `"number"`/`"string"`/`nil` 중 하나가 아닐 때 — 오타가 있으면 그 핸들러가 어느 버킷에도 안 들어가 조용히 매치되지 않게 됩니다.
- **고치려면**: `keyType`은 생략하거나 `"number"`/`"string"` 중 하나로 쓰세요.
- **참고**: [`q.Dispatch.addHandler(handler)`](/reference/extend/02-dispatch-handler-contract/#qdispatchaddhandlerhandler)

### Quad0082

`Dispatch.drive: props must be a table (got {typeof(flattened)})` — `quad-base/src/Dispatch/init.luau`

- **언제**: `q.Dispatch.drive(inst, flattened)`의 `flattened`가 테이블이 아닐 때(백엔드의 생성 경로/`Claim`이 아니라 직접 부를 때 밟을 수 있는 자리입니다).
- **고치려면**: props 테이블을 넘기세요.
- **참고**: [`q.Dispatch.drive(inst, flattened)`](/reference/extend/02-dispatch-handler-contract/#qdispatchdriveinst-flattened)

### Quad0083

`Dispatch.drive: props must be a plain { ... } table - a quad value needs the braces (got {브랜드 이름들 또는 "a table with a metatable"})` — `quad-base/src/Dispatch/init.luau`

- **언제**: `flattened` 자체가 메타테이블을 가진 값이거나, 메타테이블이 없는 quad 브랜드 값(`q.AttrKey(...)`·매퍼 디스크립터)일 때 — `D.Frame(q.Source(1))`처럼 중괄호를 잊어 quad 값 하나를 그대로 props로 넘긴 흔한 실수를 잡습니다. **[2026-10-01 기준, 다음 릴리즈부터]** 프로바이더가 등록한 브랜드 술어(`q.BrandPredicates`)까지 훑는 검사는 [`q.debug`](/reference/core/01-quad-module/#qdebug)가 켜져 있을 때만 돕니다 — 메타테이블 없는 평범한 테이블에 브랜드를 붙이는 프로바이더 값은 debug를 꺼 두면 여기 걸리지 않고 그 필드들이 props로 해석됩니다(대개 `Quad0076`). quad-base 값은 전부 debug와 무관하게 걸립니다.
- **고치려면**: 항상 중괄호로 감싼 평범한 테이블을 넘기세요 — `D.Frame { Name = q.Source("x") }`, `D.Frame { q.Attr{...} }`, `D.Frame { child }`처럼. (`D.Frame { q.Source(1) }`은 감싸도 `Quad0076`입니다 — 숫자 키에 놓인 `Source<number>`를 받는 핸들러가 없습니다.)
- **참고**: [`q.Dispatch.drive(inst, flattened)`](/reference/extend/02-dispatch-handler-contract/#qdispatchdriveinst-flattened)

### Quad0084

`Dispatch.drive: inst must not be nil` — `quad-base/src/Dispatch/init.luau`

- **언제**: `q.Dispatch.drive`를 `inst = nil`로 부를 때.
- **고치려면**: 실제 대상 요소를 넘기세요.
- **참고**: [`q.Dispatch.drive(inst, flattened)`](/reference/extend/02-dispatch-handler-contract/#qdispatchdriveinst-flattened)

### Quad0085

`Dispatch.drive: array keys must be positive integers (got {k})` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: `flattened`의 숫자 키 중 하나가 1 이상의 정수가 아닐 때(0, 음수, 소수 등) — 어떤 핸들러가 부기를 만지기 전에 먼저 봅니다.
- **고치려면**: 배열부 키는 1부터 시작하는 정수만 쓰세요(중간의 `nil` 구멍은 별개로 정의되지 않은 동작입니다).
- **참고**: [`q.Dispatch.drive(inst, flattened)`](/reference/extend/02-dispatch-handler-contract/#qdispatchdriveinst-flattened)

### Quad0264

`Modifier: the transform for field "{key}" returned a function - a field cannot hold a function (an event handler does not belong in a Modifier; put it as an inline key on the Declaration, or wrap it in a State)` — `quad-base/src/Dispatch/Modifier/init.luau`

- **언제**: `mod:Field(fn)`의 변환 함수가 **함수를 돌려줬을 때**(지금 필드 값이 평범한 값인 갈래) — 흔히 `q.Modifier():Activated(function(_old) return function() … end end)`처럼 이벤트 핸들러를 Modifier에 넣으려는 우회입니다. 초기 필드 테이블로 같은 값을 넣으면 [`Quad0063`](#quad0063)으로 거부되는데, 이 길로는 생 함수가 필드에 들어가 두 경로가 갈렸습니다. 지금 필드 값이 `State`면 변환이 `:Compute`로 미뤄져 여기서 걸리지 않습니다.
- **고치려면**: 이벤트 핸들러는 Modifier가 아니라 Declaration의 인라인 키(`D.TextButton { Activated = fn }`)로 넘기세요. 꼭 Modifier로 옮겨야 하면 `State`에 담아 넘기세요.
- **참고**: [`mod:<Field>(value)`](/reference/core/08-modifier/#modfieldvalue)

### Quad0266

`Dispatch.addHandler: debugOnly must be a boolean or nil (got {typeof(fd)})` — `quad-base/src/Dispatch/init.luau`

- **언제**: `handler.debugOnly`가 `true`/`false`/`nil`이 아닐 때 — `"yes"`나 `1`처럼 참 같은 값이 그대로 통과하면 그 핸들러가 조용히 평소(debug 아님) 스캔 목록에 남습니다(`== true`만 debug 전용 목록으로 옮겨지므로).
- **고치려면**: `debugOnly`는 생략하거나 `true`/`false`로 쓰세요.
- **참고**: [`q.Dispatch.addHandler(handler)`](/reference/extend/02-dispatch-handler-contract/#qdispatchaddhandlerhandler)

### Quad0267

`Bookkeeping.recompute: rewound 10000 times in one pass - a subscriber keeps changing a length before the position it is told about (a Slot Offset callback that adds and removes on every value never settles)` — `quad-base/src/Bookkeeping.luau`

- **언제**: 한 번의 자리 계산이 1만 번 넘게 되감았을 때 — 자리 계산 도중 발행된 `Offset`을 받은 콜백이 그 앞자리의 길이를 바꿔 계산이 그 자리부터 다시 돌기를 끝없이 되풀이하는 경우입니다. 흔한 모양은 `slot.Offset`을 보는 Observer·Effect가 값마다 옆 Slot의 원소를 넣었다 뺐다 하는 것입니다. 이 한도는 늘 켜져 있고([`q.debug`](/reference/core/01-quad-module/#qdebug)와 무관) [`Quad0263`](/reference/errors/04-ref-observer-effect/#quad0263)(`Effect`의 지연 재실행)과 같은 수입니다 — 1만 번 전까지의 되감기는 정의된 동작이고, 목록이 아무리 길어도 되감기가 없으면 걸리지 않습니다. **[2026-10-02 기준]** 게시된 3.2.0에는 이 한도가 없어 같은 코드가 에러 없이 끝나지 않습니다. 에러는 그 계산을 시작한 줄(CRUD·`:Set`·`setLength`)을 가리킵니다.
- **고치려면**: 콜백이 넣고 빼는 조건이 한 값에서 멈추게 하세요 — 받은 값에 따라 넣기와 빼기가 번갈아 참이 되면 끝나지 않습니다. 넣을지 말지를 콜백이 바꾸는 그 길이에 기대지 않는 값(데이터 개수 등)으로 정하세요. 이 에러는 자리 계산 도중에 나므로 그 부모의 부기는 멈춘 채 남습니다([`slot.Offset`](/reference/core/06-slot/#slotoffset)의 caution) — 그 부모는 새로 만드세요.
- **참고**: [`slot.Offset`](/reference/core/06-slot/#slotoffset), [Length/Offset 부기](/reference/extend/02-dispatch-handler-contract/#lengthoffset-부기)
