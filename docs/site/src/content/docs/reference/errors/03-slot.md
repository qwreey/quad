---
title: "에러 코드 — Slot"
description: "Slot CRUD·:List·:Single·dispose가 던지는 에러"
---
각 절은 `### QuadNNNN` — 메시지 원문(자리표시자는 `{…}`), 언제 나는가, 어떻게 고치는가. 번호로 찾으려면 [색인](/reference/errors/00-index/).


### Quad0140

`Slot: destroyed Slot cannot be mounted` — `quad-base/src/Slot/Handler.luau`

- **언제**: 이미 파괴된 `Slot`을 부모의 숫자 키 자리에 놓아 마운트하려 할 때 — `claimOwnerAt`/`bindLifetime`이 커밋되기 전에 걸러집니다.
- **고치려면**: 파괴된 `Slot`은 되살릴 수 없습니다 — 새 `Slot`을 만들어 놓으세요.
- **참고**: [죽은 Slot과 마운트 규칙](/reference/core/06-slot/#죽은-slot과-마운트-규칙)

### Quad0141 (폐기)

`Slot: must be an array item, not the value of a {typeof(k)} key` — 폐기

- **폐기** — 이제 던지지 않습니다. `Slot`을 props의 문자 키 값 자리에 두면(직접이든 `State`/`Store`에 담아서든) 따로 있던 가드 대신 [`Quad0076`](/reference/errors/02-dispatch-bookkeeping/#quad0076)이 `brand: Slot`과 ` - a quad value at a string key: it belongs in a numeric (array) slot` 꼬리로 같은 안내를 합니다. 문자 키가 클래스의 반영 프로퍼티 이름이면 프로퍼티 핸들러가 먼저 받으니 [`q.debug`](/reference/core/01-quad-module/#qdebug)를 켜 경고 한 줄로 찾으세요. 이 번호는 다른 에러에 다시 쓰지 않습니다.

### Quad0142

`Slot:List: data must be a plain array (got {typeof(items)}) - a data State must hold one too` — `quad-base/src/Slot/List.luau`

- **언제**: `:List`/`:Single`의 재조정이 돌 때(마운트 시점, 또는 `data`가 `State`면 그 값이 바뀔 때마다) `data`(또는 그 `State`가 담은 현재 값)가 테이블이 아니거나 메타테이블이 있을 때 — 브랜드된 quad 값(`Store`/`Tween`/`Modifier` 등)도 메타테이블이 있어 배열로 치지 않습니다.
- **고치려면**: `data`(또는 그 `State`의 값)를 평범한 `{ ... }` 배열로 주세요.
- **참고**: [`slot:List(data, updateFn, keyFn?, opts?)`](/reference/core/06-slot/#slotlistdata-updatefn-keyfn-opts)

### Quad0143

`Slot:List: data must be a plain array - key "{tostring(k)}" is not an array position` — `quad-base/src/Slot/List.luau`

- **언제**: 재조정 중 `data` 테이블에 정수가 아니거나 1보다 작은 키가 있을 때 — 딕셔너리(아이디 맵, 디코딩된 JSON 오브젝트 등)를 통째로 `:List`에 준 경우가 대표적입니다. **(3.3.0부터)** 평소에는 배열 부분이 비어 있는데 다른 키가 있는 경우(바로 그 딕셔너리)만 봅니다 — 키 전수 검사는 재조정마다 O(N)이라 [`q.debug`](/reference/core/01-quad-module/#qdebug)가 켜져 있을 때만 돕니다. 그래서 배열에 문자 키가 **덧붙은** 데이터(`{ a, b, extra = 1 }`)는 debug를 꺼 두면 덧붙은 키가 조용히 무시되고 배열 부분만 재조정됩니다.
- **고치려면**: `data`를 1부터 시작하는 배열로 주세요.
- **참고**: [`slot:List(data, updateFn, keyFn?, opts?)`](/reference/core/06-slot/#slotlistdata-updatefn-keyfn-opts)

### Quad0144

`Slot:List: keyFn returned {if key == nil then "nil" else "NaN"} for item #{i}` — `quad-base/src/Slot/List.luau`

- **언제**: `keyFn(item, i)`이 `nil` 또는 NaN을 돌려줬을 때 — 재조정은 이 키로 항목의 신원을 구별하므로 둘 다 쓸 수 없습니다.
- **고치려면**: `keyFn`이 항목마다 유일하고 안정적인 값을 돌려주게 하세요.
- **참고**: [`slot:List(data, updateFn, keyFn?, opts?)`](/reference/core/06-slot/#slotlistdata-updatefn-keyfn-opts)

### Quad0145

`Slot:List: duplicate key {tostring(key)}` — `quad-base/src/Slot/List.luau`

- **언제**: `keyFn`이 두 항목에 같은 키를 돌려줬을 때 — 재조정은 키로 항목을 구별하므로 겹치면 어느 쪽이 그 자리인지 정할 수 없습니다.
- **고치려면**: `keyFn`이 항목마다 유일한 값을 돌려주게 하세요(id 필드 등).
- **참고**: [`slot:List(data, updateFn, keyFn?, opts?)`](/reference/core/06-slot/#slotlistdata-updatefn-keyfn-opts)

### Quad0146

`Slot:List: updateFn returned q.KeyGone - it is the marker updateFn RECEIVES when a key disappears; return nil/q.None to drop the element or q.Detach to hold it` — `quad-base/src/Slot/List.luau`

- **언제**: `updateFn`이 결과 자리에 `q.KeyGone`을 그대로 반환했을 때 — `KeyGone`은 사라진 키를 알리려고 `updateFn`이 **받는** 입력 마커이지, 반환값이 아닙니다.
- **고치려면**: 그 항목을 버리려면 `nil`/`q.None`을, 파괴하지 않고 보관하려면 `q.Detach`를 반환하세요.
- **참고**: [`q.KeyGone`](/reference/core/10-lifetime-sentinels/#qkeygone)

### Quad0147

`Slot:List: KeyGone accepts only nil/None (destroy) or Detach (hold)` — `quad-base/src/Slot/List.luau`

- **언제**: 사라진 키를 처리하는 `KeyGone` 호출(`ctx.Item == q.KeyGone`)에서 `updateFn`이 새 원소를 반환했을 때.
- **고치려면**: 그 호출에서는 `nil`/`q.None`(파괴) 또는 `q.Detach`(보관)만 반환하세요.
- **참고**: [`q.KeyGone`](/reference/core/10-lifetime-sentinels/#qkeygone)

### Quad0148

`Slot: already has :List/:Single/:Lazy installed` — `quad-base/src/Slot/List.luau`

- **언제**: 이미 `:List`나 `:Single`을 건 `Slot`에 다시 `:List`/`:Single`을 걸려고 할 때 — 재조정 모드 설치는 한 Slot에 한 번뿐입니다.
- **고치려면**: 다른 데이터를 반영하려면 그 `:List`가 참조하는 `data` State를 바꾸세요 — 재설치는 하지 않습니다.
- **참고**: [`slot:List(data, updateFn, keyFn?, opts?)`](/reference/core/06-slot/#slotlistdata-updatefn-keyfn-opts)

### Quad0149

`Slot: cannot install :List/:Single/:Lazy on a manual Slot (one that used CRUD or was built as Slot{ ... }, even empty)` — `quad-base/src/Slot/List.luau`

- **언제**: 이미 수동 CRUD(`Add`/`Remove`/...)를 쓴 `Slot`이나, 생성자에 `initial` 테이블을 준 `Slot`(빈 `q.Slot({})`도 포함)에 `:List`/`:Single`을 걸려고 할 때 — 두 모드는 상호 배타입니다. 자기 검증에서 거부된 CRUD 호출은 수동으로 표시하지 않습니다.
- **고치려면**: `:List`/`:Single`을 쓸 `Slot`은 CRUD 없이, 인자 없는 `q.Slot()`으로 만드세요.
- **참고**: [`slot:List(data, updateFn, keyFn?, opts?)`](/reference/core/06-slot/#slotlistdata-updatefn-keyfn-opts)

### Quad0150

`Slot:List: updateFn must be a function (got {typeof(updateFn)})` — `quad-base/src/Slot/List.luau`

- **언제**: `:List`의 두 번째 인자 `updateFn`이 함수가 아닐 때.
- **고치려면**: 항목 하나를 원소로 바꾸는 함수를 넘기세요.
- **참고**: [`slot:List(data, updateFn, keyFn?, opts?)`](/reference/core/06-slot/#slotlistdata-updatefn-keyfn-opts)

### Quad0151

`Slot:List: data must be a plain array or a State of one (got {typeof(data)})` — `quad-base/src/Slot/List.luau`

- **언제**: `:List`의 첫 인자 `data`가 평범한 배열도, 배열을 담은 `State`도 아닐 때 — 브랜드된 quad 값(`Store`/`Tween`/`Modifier` 등)은 메타테이블이 있어 여기 걸립니다.
- **고치려면**: 배열 리터럴이나 배열을 담은 `State`를 넘기세요.
- **참고**: [`slot:List(data, updateFn, keyFn?, opts?)`](/reference/core/06-slot/#slotlistdata-updatefn-keyfn-opts)

### Quad0152

`Slot:List: keyFn must be a function (got {typeof(keyFn)})` — `quad-base/src/Slot/List.luau`

- **언제**: `:List`의 `keyFn` 인자를 줬는데 함수가 아닐 때(생략은 허용 — 그러면 인덱스가 키가 됩니다).
- **고치려면**: `(item, index) -> any` 모양의 함수를 넘기거나 생략하세요.
- **참고**: [`slot:List(data, updateFn, keyFn?, opts?)`](/reference/core/06-slot/#slotlistdata-updatefn-keyfn-opts)

### Quad0153

`Slot:List: opts must be a table (got {typeof(opts)})` — `quad-base/src/Slot/List.luau`

- **언제**: `:List`의 `opts` 인자를 줬는데 테이블이 아닐 때.
- **고치려면**: `{ OwnsElements = false }`처럼 테이블로 주거나 생략하세요.
- **참고**: [`slot:List(data, updateFn, keyFn?, opts?)`](/reference/core/06-slot/#slotlistdata-updatefn-keyfn-opts)

### Quad0154

`Slot:Single: updateFn must be a function (got {typeof(updateFn)})` — `quad-base/src/Slot/List.luau`

- **언제**: `:Single`의 `updateFn` 인자를 줬는데 함수가 아닐 때.
- **고치려면**: 함수를 넘기거나 생략하세요(생략하면 값을 그대로 원소로 쓰는 항등 함수).
- **참고**: [`slot:Single(state, updateFn?, opts?)`](/reference/core/06-slot/#slotsinglestate-updatefn-opts)

### Quad0155

`Slot:Single: opts must be a table (got {typeof(opts)})` — `quad-base/src/Slot/List.luau`

- **언제**: `:Single`의 `opts` 인자를 줬는데 테이블이 아닐 때.
- **고치려면**: 테이블로 주거나 생략하세요.
- **참고**: [`slot:Single(state, updateFn?, opts?)`](/reference/core/06-slot/#slotsinglestate-updatefn-opts)

### Quad0156

`Slot: this element is already mounted - multiple mounts are not allowed (a State or :List element is settled when its Slot mounts or the value changes, so two elements that became the same Instance - two States holding one value, an updateFn returning the same Instance twice, a :Lazy fn returning an element already mounted elsewhere - collide here, not at Add)` — `quad-base/src/Slot/Owner.luau`

- **언제**: `:List`/`:Single`·`:Lazy`나 `State` 원소(그 래퍼)가 원소를 정착시킬 때(`:Lazy`는 `fn`이 이미 다른 자리에 마운트된 원소를 돌려줬을 때) — 마운트 때, 그 뒤엔 값이 바뀔 때 — 그 값이 이미 다른 자리에 마운트돼 있을 때(레지스트리는 Slot 원소·정적 자식·숏핸드 관리 자식이 하나를 같이 쓰지만, 정적 자식 자리는 Quad0160, 수동 Slot CRUD는 Quad0172·Quad0170이 냅니다). 흔한 원인은 한 Slot의 원소 둘이 마운트 때 같은 Instance가 된 것입니다 — 마운트 전 Slot에 같은 Instance를 쥔 `State` 둘(또는 그 Instance와 그것을 쥔 `State`)을 넣으면 넣는 줄은 통과하고(넣을 때 `State`의 값을 읽지 않습니다) 마운트 줄에서 이 에러가 납니다. `updateFn`이 같은 원소를 두 키에 돌려주거나 자기 Slot을 돌려준 경우도 이 문구입니다. 런타임 메시지 끝에는 "if its owner was destroyed outside quad …" 꼬리가 붙습니다.
- **고치려면**: 한 Instance는 한 자리에만 — 원소마다 다른 Instance가 되게 하세요(`State`마다 다른 값, `updateFn`이 키마다 다른 원소). 다른 곳에 있던 값이면 먼저 옛 자리에서 빼세요(`Extract`, 데이터 키 삭제 등). 같은 원소를 두 키에 돌려줬다면 `Extract`는 `Quad0166`을 내니 `updateFn`을 고치고, 자기 Slot을 돌려준 경우는 뺄 옛 자리가 없으니 반환값을 고치세요. 그 값의 원래 owner가 quad 밖에서(`inst:Destroy()`) 파괴됐다면 되살릴 수 없습니다.
- **관측 — 계약 아님**: 마운트 때 던지면 그 Slot은 자식이 빠진 채 남고 그 사슬의 다음 CRUD가 `Quad0167`로 막힙니다 — 그 Slot은 버리세요.
- **참고**: [죽은 Slot과 마운트 규칙](/reference/core/06-slot/#죽은-slot과-마운트-규칙)

### Quad0157

`Bookkeeping.claimOwnerAt: element must not be nil` — `quad-base/src/Slot/Owner.luau`

- **언제**: `q.Bookkeeping.claimOwnerAt(element, inst, k)`에 `element`로 `nil`을 넘겼을 때.
- **고치려면**: 실제 값을 넘기세요.
- **참고**: [`q.Bookkeeping.claimOwnerAt(element, inst, k)`](/reference/extend/02-dispatch-handler-contract/#qbookkeepingclaimowneratelement-inst-k)

### Quad0158

`Bookkeeping.claimOwnerAt: inst (ownerKey) must not be nil` — `quad-base/src/Slot/Owner.luau`

- **언제**: `claimOwnerAt`의 `inst`(그 자리의 주인 — ownerKey)로 `nil`을 넘겼을 때.
- **고치려면**: 실제 owner를 넘기세요.
- **같은 실수를 다른 자리에서 알리는 것**: 부기 함수(`getBookkeeping`/`setLength` 등)는 Quad0020, `releaseOwner`는 Quad0162입니다 — 같은 `nil` owner 실수를 부른 함수에 따라 번호를 달리해 알립니다.
- **참고**: [`q.Bookkeeping.claimOwnerAt(element, inst, k)`](/reference/extend/02-dispatch-handler-contract/#qbookkeepingclaimowneratelement-inst-k)

### Quad0159

`Bookkeeping.claimOwnerAt: k (seat key - a position or a shorthand child name) must not be nil` — `quad-base/src/Slot/Owner.luau`

- **언제**: `claimOwnerAt`의 `k`(자리 키 — 위치 숫자 또는 숏핸드 자식 이름)로 `nil`을 넘겼을 때 — `nil` 위치로 등록하면 나중에 그 자리를 되짚거나 해제할 수 없는 자리가 생깁니다.
- **고치려면**: 실제 위치 숫자나 자식 이름을 넘기세요.
- **참고**: [`q.Bookkeeping.claimOwnerAt(element, inst, k)`](/reference/extend/02-dispatch-handler-contract/#qbookkeepingclaimowneratelement-inst-k)

### Quad0160

`Bookkeeping.claimOwnerAt: this element is already mounted elsewhere - one value takes one seat, so the same element cannot sit in two parent tables, twice in one table, or in two Slots` (+ 런타임엔 "if its owner was destroyed outside quad …" 꼬리) — `quad-base/src/Slot/Owner.luau`

- **언제**: `claimOwnerAt`이 등록하려는 값이 이미 다른 자리에 등록돼 있을 때(정확히 같은 자리의 재확인은 예외 — 던지지 않고 `false`를 돌려줍니다).
- **고치려면**: Quad0156과 같습니다 — 먼저 옛 자리에서 빼세요. 다만 리터럴 정적 자식(`D.Frame({ el })`)으로 앉은 값은 뺄 공개 경로가 없습니다(`el.Parent = nil`로도 안 풀림) — 옮겨 다닐 값은 State 자리나 Slot에 두세요.
- **참고**: [죽은 Slot과 마운트 규칙](/reference/core/06-slot/#죽은-slot과-마운트-규칙), [`q.Bookkeeping.claimOwnerAt(element, inst, k)`](/reference/extend/02-dispatch-handler-contract/#qbookkeepingclaimowneratelement-inst-k)

### Quad0161

`Bookkeeping.releaseOwner: element must not be nil` — `quad-base/src/Slot/Owner.luau`

- **언제**: `q.Bookkeeping.releaseOwner(element, ownerKey)`에 `element`로 `nil`을 넘겼을 때.
- **고치려면**: 실제 값을 넘기세요.
- **참고**: [`q.Bookkeeping.releaseOwner(element, ownerKey)`](/reference/extend/02-dispatch-handler-contract/#qbookkeepingreleaseownerelement-ownerkey)

### Quad0162

`Bookkeeping.releaseOwner: ownerKey must not be nil` — `quad-base/src/Slot/Owner.luau`

- **언제**: `releaseOwner`의 `ownerKey`로 `nil`을 넘겼을 때.
- **고치려면**: 실제 owner를 넘기세요.
- **같은 실수를 다른 자리에서 알리는 것**: 부기 함수(`getBookkeeping`/`setLength` 등)는 Quad0020, `claimOwnerAt`은 Quad0158입니다 — 같은 `nil` owner 실수를 부른 함수에 따라 번호를 달리해 알립니다.
- **참고**: [`q.Bookkeeping.releaseOwner(element, ownerKey)`](/reference/extend/02-dispatch-handler-contract/#qbookkeepingreleaseownerelement-ownerkey)

### Quad0163

`Bookkeeping.releaseOwner: this element is not owned by this ownerKey - ownership tracking is broken` — `quad-base/src/Slot/Owner.luau`

- **언제**: `releaseOwner`에 넘긴 `ownerKey`가 그 값을 실제로 쥔 owner와 다를 때 — 자기가 잡지 않은 자리를 풀려고 한 것으로, 소유권 부기가 깨졌다는 신호입니다.
- **고치려면**: 자기가 `claimOwnerAt`으로 잡은 자리만 `releaseOwner`로 푸세요.
- **참고**: [`q.Bookkeeping.releaseOwner(element, ownerKey)`](/reference/extend/02-dispatch-handler-contract/#qbookkeepingreleaseownerelement-ownerkey)

### Quad0164

`Slot: destroyed Slot cannot be mounted` — `quad-base/src/Slot/Tree.luau`

- **같은 뜻**: Quad0140
- **언제**: 이미 파괴된 `Slot`을 마운트(부모의 숫자 키 자리에 놓는 것)하려 할 때 — `materializeSlotTree`의 첫 검사입니다. 공개 경로에서는 핸들러 사전검사 Quad0140이 먼저 걸리고, 중첩 경로에서는 Quad0160/Quad0179가 먼저 나므로 이 ID를 직접 볼 일은 드뭅니다.
- **고치려면**: 파괴된 `Slot`은 되살릴 수 없습니다 — 새 `Slot`을 만드세요.
- **참고**: [죽은 Slot과 마운트 규칙](/reference/core/06-slot/#죽은-slot과-마운트-규칙)

### Quad0165

`Slot: destroyed Slot cannot be reused` — `quad-base/src/Slot/init.luau`

- **언제**: 파괴된 `Slot`에 CRUD(`Add`/`Remove`/...)나 `:List`/`:Single` 설치를 다시 쓰려고 할 때 — 모든 공개 CRUD·설치 진입점이 이 가드(`assertLive`)를 거칩니다.
- **고치려면**: 파괴된 `Slot`은 되살릴 수 없습니다 — 새 `Slot`을 만드세요.
- **참고**: [죽은 Slot과 마운트 규칙](/reference/core/06-slot/#죽은-slot과-마운트-규칙)

### Quad0166

`Slot: manual CRUD is not allowed after :List/:Single/:Lazy` — `quad-base/src/Slot/init.luau`

- **언제**: `:List`/`:Single`을 이미 건 `Slot`에 수동 CRUD(`Add`/`Remove`/`Replace`/...)를 쓰려고 할 때.
- **고치려면**: `:List`/`:Single`을 건 `Slot`은 그 데이터 `State`를 통해서만 바꾸세요 — 수동 CRUD가 필요하면 그 설치 없이 새 `Slot`을 만드세요.
- **참고**: [`slot:List(data, updateFn, keyFn?, opts?)`](/reference/core/06-slot/#slotlistdata-updatefn-keyfn-opts)

### Quad0167

`Slot: cannot mutate a Slot while it is being mounted or while one of its elements is being inserted/removed (it, or a Slot inside it, is mid-operation) - a :List/:Single updateFn, an Observer that fires during that mount, or a backend signal callback that runs synchronously inside the insert/remove (an element's parent changed) must not CRUD this Slot or an ancestor Slot; run it through slot:WhenIdle(fn) - fn runs as soon as the operation has finished (or an earlier operation on this Slot or a Slot inside it threw mid-way - then this Slot stays unusable: dispose its host Instance)` — `quad-base/src/Slot/init.luau`

- **언제**: 이 `Slot`이나 그 안의 `Slot`이 마운트되는 동안(`_materializing`) 이 `Slot`에 CRUD나 `:List`/`:Single` 설치를 쓰려고 할 때 — 중첩된 `:List`의 첫 `updateFn`이나 그 안에서 도는 `Observer`가 조상 `Slot`을 건드리면 여기 걸립니다. 이미 마운트된 트리에 `Add`/`Splice`/`Replace`로 `:List` Slot을 넣을 때도 같고, 이때 막히는 범위는 바로 위 부모만이 아니라 **맨 위까지의 조상 `Slot` 전부**입니다(3.3.0부터 — 3.2.0에는 이 거부가 없어 조상을 고치면 내부 에러로 죽거나 조부모를 지울 때 유령 자리가 남았습니다).
- **언제(엔진 호출 안)**: [3.3.0부터] 원소를 붙이거나 떼는 **엔진 호출이 도는 동안**에도 같은 표시가 섭니다 — 그 호출 안에서 동기로 불리는 신호 콜백(Roblox에서 `SignalBehavior`가 Immediate일 때 원소의 `Parent` 변경 신호 — `q.OnChange("Parent", fn)`의 `fn`)이 **그 연산이 진행 중인 `Slot`과 그 위의 조상 `Slot`들**(원소를 받거나 내보내는 `Slot`과 맨 위까지의 조상, 통째로 붙고 있는 `Slot`과 그 안의 `Slot`, 파괴되고 있는 `Slot`)을 CRUD하면 여기 걸립니다. 조상까지 막는 이유는 자식 `Slot`의 `Length`가 엔진 호출이 끝난 뒤에야 갱신되기 때문입니다 — 그 사이 조상이 자식 뒤 자리를 계산하면 낡은 길이를 씁니다. 그 연산은 끝까지 마쳐지고 부기는 온전합니다(막힌 것은 콜백의 CRUD뿐). Deferred에서는 콜백이 연산이 끝난 뒤에 불리므로 걸리지 않습니다. 같은 부모 아래의 형제 `Slot`과 무관한 `Slot`은 막지 않고, 언마운트 도중의 콜백은 이미 떼어진 `Slot`을 보므로 막지 않습니다.
- **고치려면**: 그 일을 [`slot:WhenIdle(fn)`](/reference/core/06-slot/#slotwhenidlefn)에 넘기세요 — `fn(slot)`은 그 `Slot`이 한가하면 바로, 연산 중이면 그 연산이 끝난 직후에 실행됩니다(신호 설정과 무관하게 같은 코드). index는 `fn` 안에서 다시 구하세요(`slot:IndexOf(element)`). `updateFn` 안에서 조상을 바꾸려던 것이라면 먼저 그 일이 `updateFn`의 몫인지 보세요 — `updateFn`은 항목 하나를 원소로 바꾸는 함수입니다. "`Observer`에서"라도 그 `Observer`가 마운트 중에 동기로 발화하면(첫 발화 포함) 같은 에러이고 처방도 같습니다. 앞선 연산이 도중에 던진 뒤에 이 에러가 난다면 그 예외의 원인을 고치세요.
- **관측(계약 아님)**: 엔진 호출 자체가 던지면(예: 인스턴스를 자기 자손에 넣어 엔진이 순환을 거부) 그 `Slot`에 표시가 남아 이후의 CRUD가 이 에러로 막힙니다.
- **관측(계약 아님)**: 마운트 도중 어디서든 던지면 그 마운트에 걸린 사슬 전체에 "마운트 중" 표시가 남아, 그 뒤 **이 `Slot`과 그 조상 `Slot`들**은 이 에러로 계속 막힙니다(quad는 사용자 코드의 예외를 복구하지 않습니다). `D.Frame({ outer })`처럼 호스트를 만드는 호출 자체가 던진 경우엔 호스트가 반환되지 않습니다.
- **참고**: [`slot:List(data, updateFn, keyFn?, opts?)`](/reference/core/06-slot/#slotlistdata-updatefn-keyfn-opts)

### Quad0269

`Slot:List: data has a nil hole at index {hole} (the array goes on to index {highest}) - the list would end there and every item behind it would be treated as gone, its element destroyed; remove the nil or put a placeholder value there` — `quad-base/src/Slot/List.luau`

- **언제**: [`q.debug`](/reference/core/01-quad-module/#qdebug)가 켜져 있고, `slot:List`의 `data` 배열 중간에 `nil`이 있을 때(`{ "a", nil, "c" }`). 재조정이 아무것도 파괴하기 전에 멈춥니다. 꺼져 있으면 검사하지 않습니다 — 목록이 구멍에서 끝나고 구멍 뒤 항목의 원소는 "키가 사라졌다" 경로로 파괴됩니다(정의되지 않은 동작).
- **고치려면**: 배열에 `nil`을 넣지 마세요. 빈 칸이 필요한 데이터면 자리표시 값(예: `false`나 전용 표식)을 넣고 `updateFn`에서 그 값을 다루세요. 끝자리의 `nil`은 구멍이 아닙니다(배열이 거기서 끝날 뿐).
- **참고**: [`slot:List(data, updateFn, keyFn?, opts?)`](/reference/core/06-slot/#slotlistdata-updatefn-keyfn-opts)

### Quad0270

`Slot: initial elements have a nil hole at index {hole} (the array goes on to index {highest}) - the elements behind it would be ignored; build the array without the nil (a Slot element cannot be nil or None)` — `quad-base/src/Slot/init.luau`

- **언제**: [`q.debug`](/reference/core/01-quad-module/#qdebug)가 켜져 있고, `q.Slot({ a, nil, c })`처럼 `initial` 배열 중간에 `nil`이 있을 때(조건부 원소를 `cond and x or nil`로 넣은 경우가 흔합니다). 꺼져 있으면 구멍 뒤 원소가 조용히 무시됩니다(정의되지 않은 동작).
- **고치려면**: 구멍 없이 배열을 만드세요 — 조건부 원소는 배열을 만든 뒤 `table.insert`로 넣거나, Slot을 만든 뒤 `slot:Add`로 넣습니다. Slot 원소 자리에는 `nil`도 `q.None`도 둘 수 없습니다.
- **참고**: [`q.Slot<<T>>(initial?)`](/reference/core/06-slot/#qslottinitial)

### Quad0268

`Slot:WhenIdle: fn must be a function (got {typeof(fn)})` — `quad-base/src/Slot/init.luau`

- **언제**: `slot:WhenIdle(fn)`의 `fn`이 함수가 아닐 때(`nil` 포함).
- **고치려면**: `function(slot) … end`를 넘기세요.
- **참고**: [`slot:WhenIdle(fn)`](/reference/core/06-slot/#slotwhenidlefn)

### Quad0168

`{surface}: index must be a positive integer (got {tostring(index)})` — `quad-base/src/Slot/init.luau`

- **언제**: `Add`/`Remove`/`Replace`/`Extract`/`Splice`/`Move`/`Swap` 같은 CRUD의 `index` 인자가 숫자가 아니거나, 정수가 아니거나, 1보다 작을 때(`Remove(0)`/`Remove(-1)`, NaN 포함). `{surface}`는 실제로 부른 메소드 이름(`Slot:Add` 등)입니다.
- **고치려면**: 1 이상의 정수 인덱스를 넘기세요.
- **참고**: [`slot:Add(element, index?)`](/reference/core/06-slot/#slotaddelement-index)

### Quad0236

`{surface}: index out of range (got {index}, limit {limit})` — `quad-base/src/Slot/init.luau`

- **언제**: Quad0168과 같은 CRUD의 `index`가 정수이지만 허용 범위(1..n, `Add`/`Splice`는 1..n+1)를 벗어났을 때. Quad0168과 한 호출(`checkIndex`)의 두 갈래입니다.
- **고치려면**: 현재 길이에 맞는 범위 안의 인덱스를 넘기세요 — 클램프하지 않습니다.
- **참고**: [`slot:Add(element, index?)`](/reference/core/06-slot/#slotaddelement-index)

### Quad0169 (폐기)

`{surface}: destroyed Slot cannot be an element` — 폐기

- **폐기** — 이제 던지지 않습니다. `Slot` CRUD는 원소로 넣는 `State`의 값을 넣을 때 읽지 않습니다 — 그 값이 파괴된 `Slot`이면 래퍼가 값을 정착시킬 때(마운트 때, 그 뒤엔 값이 바뀔 때) [`Quad0242`](#quad0242)가 같은 뜻으로 납니다. 이 번호는 다른 에러에 다시 쓰지 않습니다.
- **참고**: [죽은 Slot과 마운트 규칙](/reference/core/06-slot/#죽은-slot과-마운트-규칙)

### Quad0170

`Slot: this element is already in this Slot (a second mount) - reorder with Move/Swap instead of adding it again` — `quad-base/src/Slot/Owner.luau`

- **언제**: 수동 `Slot`이 이미 들고 있는 원소를 다시 넣으려 할 때 — `slot:Add(a); slot:Add(a)`, `Replace(i, slot:Get(i))`, 그리고 한 호출 안의 중복(`q.Slot({ a, a })`, `Splice(i, 0, a, a)` — [`q.debug`](/reference/core/01-quad-module/#qdebug)가 꺼져 있을 때; 켜져 있으면 넣기 전에 [`Quad0171`](#quad0171)). 원소를 자리에 넣는 순간 걸리므로 마운트 전 Slot에서도 같습니다. 여러 원소를 받는 호출이 중간 원소에서 던지면 앞 원소는 이미 들어가 있습니다(관측 — 계약 아님). `Splice`가 같은 호출에서 빼는 원소를 다시 넣는 것은 이 에러가 아닙니다(빼는 쪽이 먼저 풀립니다).
- **고치려면**: 순서만 바꾸려면 `Move`/`Swap`을 쓰세요 — 재추가는 두 번째 마운트로 거부됩니다. 한 호출 안에서는 원소를 한 번씩만 주세요.
- **참고**: [`slot:Splice(index, removeCount, ...newElements)`](/reference/core/06-slot/#slotspliceindex-removecount-newelements)

### Quad0171

`{surface}: the same element appears twice` — `quad-base/src/Slot/init.luau`

- **언제**: [`q.debug`](/reference/core/01-quad-module/#qdebug)가 켜져 있을 때, 한 번의 호출(`Splice`, 생성자 `initial` 등) 안에 같은 값이 두 번 들어 있을 때 — 원소를 하나도 넣기 전에 받은 값 그대로 비교합니다(같은 `State` 두 번도 걸리지만, 같은 Instance를 쥔 서로 다른 `State` 둘은 값을 읽지 않으므로 여기서 걸리지 않고 마운트 때 [`Quad0156`](#quad0156)). **(3.3.0부터)** debug 층 검사입니다 — 꺼 두면 두 번째 값이 자리에 들어가는 순간 [`Quad0170`](#quad0170)이 납니다.
- **고치려면**: 배치 안의 원소를 중복 없이 주세요.
- **참고**: [`q.Slot<<T>>(initial?)`](/reference/core/06-slot/)

### Quad0172

`Slot: this element is already mounted - multiple mounts are not allowed` (+ 같은 꼬리) — `quad-base/src/Slot/Owner.luau`

- **언제**: 수동 `Slot`에 이미 다른 곳(다른 `Slot`의 원소, 정적 자식, 숏핸드가 만드는 관리 자식 등)에 마운트된 값을 원소로 넣으려 할 때 — 원소를 자리에 넣는 순간 걸립니다(여러 원소를 받는 `Splice`·생성자가 중간 원소에서 던지면 앞의 변경은 이미 일어나 있습니다 — 관측, 계약 아님).
- **고치려면**: Quad0156과 같습니다 — 먼저 옛 자리에서 빼세요(Slot 원소는 `Extract`, State 자리는 `Set(nil)`). 리터럴 정적 자식(`D.Frame({ el })`)으로 앉은 값은 뺄 공개 경로가 없습니다(`el.Parent = nil`로도 안 풀림) — 옮겨 다닐 값은 처음부터 State 자리나 Slot에 두세요.
- **참고**: [죽은 Slot과 마운트 규칙](/reference/core/06-slot/#죽은-slot과-마운트-규칙)

### Quad0173

`{surface}: cannot add a Slot to itself or to one of its own descendants (that would be a cycle)` — `quad-base/src/Slot/init.luau`

- **언제**: [`q.debug`](/reference/core/01-quad-module/#qdebug)가 켜져 있을 때, `Slot`을 자기 자신이나 자기 조상(원소 관계로 이어진)에 원소로 넣으려 할 때 — 그대로 두면 순환이 생겨 이후 CRUD·해체가 끝나지 않는 재귀로 들어갑니다(아래 관측 줄). **(3.3.0부터)** 원소 관계를 따라 올라가는 이 검사는 넣는 Slot마다 깊이만큼 비용이 들어 debug 층으로 내려갔습니다 — 꺼 두면 넣는 줄은 그대로 통과하고 그 순환은 정의되지 않은 동작입니다. 개발 중에는 debug를 켜 두세요.
- **고치려면**: 순환이 생기지 않게 구조를 바꾸세요. (인스턴스를 매개로 한 순환은 이 검사 밖입니다 — 정의되지 않은 동작.)
- **관측(계약 아님)**: debug를 꺼 둔 채 순환을 넣으면 그 순환 트리의 다음 CRUD나 해체가 스택 오버플로나 내부 불변식 에러로 죽고(어느 쪽인지는 연산마다 다릅니다), 그 뒤의 부기 무결은 약속하지 않습니다.
- **참고**: [`slot:Add(element, index?)`](/reference/core/06-slot/#slotaddelement-index)

### Quad0174

`Slot:Splice: removeCount out of range` — `quad-base/src/Slot/init.luau`

- **언제**: `:Splice`의 `removeCount`가 숫자가 아니거나 음수/소수이거나, `index + removeCount - 1`이 현재 길이를 넘을 때.
- **고치려면**: 실제로 남아 있는 만큼만 지우세요 — 클램프하지 않습니다.
- **참고**: [`slot:Splice(index, removeCount, ...newElements)`](/reference/core/06-slot/#slotspliceindex-removecount-newelements)

### Quad0175

`Slot:Get: index must be a number (got {typeof(index)})` — `quad-base/src/Slot/init.luau`

- **언제**: `:Get`의 `index` 인자가 숫자가 아닐 때 — "빈 Slot"처럼 조용히 `nil`을 주지 않고 던집니다.
- **고치려면**: 숫자 인덱스를 넘기세요(범위 밖은 `nil`을 돌려줄 뿐 던지지 않습니다).
- **참고**: [`slot:Get(index)`](/reference/core/06-slot/#slotgetindex)

### Quad0176

`Slot: initial elements must be a plain { element, ... } array (got {typeof(initial)} - a bare element or quad value needs the braces)` — `quad-base/src/Slot/init.luau`

- **언제**: 생성자 `q.Slot(initial)`의 `initial`이 테이블이 아니거나, 메타테이블이 있거나(브랜드된 quad 값), 괄호 없이 값 하나만 넘겼을 때(`Slot(frame)`).
- **고치려면**: `{ element, ... }` 모양의 평범한 배열로 감싸서 넘기세요.
- **참고**: [`q.Slot<<T>>(initial?)`](/reference/core/06-slot/)

### Quad0177

`Slot: initial elements must be an array - key "{tostring(k)}" is not an array position` — `quad-base/src/Slot/init.luau`

- **언제**: `initial` 테이블의 키 중 정수가 아니거나 1보다 작은 것이 있을 때.
- **고치려면**: 1부터 시작하는 배열로 주세요.
- **참고**: [`q.Slot<<T>>(initial?)`](/reference/core/06-slot/)

### Quad0178

`dispose: value must not be nil` — `quad-base/src/Slot/init.luau`

- **언제**: `q.dispose(value)`에 `nil`을 넘겼을 때.
- **고치려면**: 파괴할 실제 값을 넘기세요.
- **참고**: [`q.dispose(value)`](/reference/core/10-lifetime-sentinels/#qdisposevalue)

### Quad0179

``dispose: this value is still held by a Slot or a mounted position - Remove/Extract it from a manual Slot, drop its key from a :List Slot's data, destroy the owner Slot (a detached element goes with its owner), or take it off its numeric-key seat first (Set(nil) the State holding it; a shorthand-managed child goes with its key) (if its owner was destroyed outside quad - `inst:Destroy()` - the value went with it and cannot be reused after its parent is destroyed; extract it before destroying, as with an Instance)`` — `quad-base/src/Slot/init.luau`

- **언제**: 아직 어떤 `Slot`의 원소이거나 마운트된 자리(정적 자식·숏핸드 관리 자식 포함)를 차지하고 있는 값을 `dispose`하려 할 때. [`source:SetAndDispose(v)`](/reference/core/02-source/#sourcesetanddisposev)가 옛 값을 파괴하려 할 때도 같습니다 — 그 `Source`가 아닌 다른 자리가 옛 값을 쥐고 있거나, 둘 사이의 `Debounce`·`Blocker`가 전파를 늦춰 옛 값이 아직 자리에 있을 때입니다(새 값은 이미 들어간 뒤).
- **고치려면**: 먼저 그 자리에서 빼세요 — 수동 `Slot`이면 `Remove`/`Extract`, `:List` `Slot`이면 데이터에서 그 키 제거, 숫자 키 자리면 그 자리를 쥔 `State`를 `Set(nil)`, 숏핸드 관리 자식이면 그 키를 `nil`로. owner `Slot` 자체를 파괴해서 풀려면 그 Slot이 State 자리에 있을 때 `Set(nil)` 뒤 dispose하거나 호스트를 dispose하세요 — 숫자 키 리터럴 자리에 앉은 Slot에 `q.dispose(slot)`을 부르면 같은 에러가 납니다(리터럴 정적 자식은 뺄 공개 경로가 없음 — Quad0172).
- **참고**: [`q.dispose(value)`](/reference/core/10-lifetime-sentinels/#qdisposevalue)

### Quad0180

`dispose: this backend cannot dispose this value` — `quad-base/src/Slot/init.luau`

- **언제**: `dispose`에 준 값이 `Slot`도 아니고 백엔드가 요소로 인정하는 값(`q.Backend.isInst`가 참)도 아닐 때 — 백엔드가 아예 설치되지 않은 모듈에서는 그 전에 `q.Backend.isInst` 스텁이 먼저 던집니다. [`source:SetAndDispose(v)`](/reference/core/02-source/#sourcesetanddisposev)의 옛 값이 그런 값(숫자·문자열·평범한 테이블)일 때도 납니다(새 값은 이미 들어간 뒤).
- **고치려면**: `Slot`이거나 `q.Backend.isInst`가 참인 값을 넘기세요. 파괴할 것이 없는 `Source`에는 `SetAndDispose` 대신 `:Set`을 쓰세요.
- **참고**: [`q.dispose(value)`](/reference/core/10-lifetime-sentinels/#qdisposevalue)

### Quad0238

`Slot: handler-layer values (Ref/PreRef/PostRef/Observer/Effect/Modifier) cannot be elements` — `quad-base/src/Slot/Elements.luau`

- **언제**: `Ref`/`PreRef`/`PostRef`/`Observer`/`Effect`/`Modifier` 같은 핸들러 레이어 값을 `Slot`의 원소(생성자 `initial`, `:Add`/`:Replace`/`:Splice`/`:List`/`:Single`의 새 원소)로 넣으려 할 때 — 이런 값은 마운트할 물리 원소가 아니라 다른 값에 붙이는 부착물입니다.
- **고치려면**: 그 값이 붙어야 할 실제 원소(Instance 등) 자리에 붙이고, `Slot`에는 마운트 가능한 값만 넣으세요.
- **참고**: [원소 대수](/reference/core/06-slot/#원소-대수--넣는-자리와-꺼내는-자리의-타입이-다르다)

### Quad0239

`Slot: nil/None cannot be an element - only actually mountable values` — `quad-base/src/Slot/Elements.luau`

- **언제**: `nil`이나 `q.None`을 `Slot`의 원소로 넣으려 할 때 — `Slot`은 "빈 자리"를 원소 부재가 아니라 배열에서 그 항목이 아예 없는 것으로 표현하므로, `nil`/`None`은 원소 자리에 들어올 수 없습니다.
- **고치려면**: 그 자리를 비우려면 `:Remove`/`:Extract`/`:Splice`로 배열에서 빼세요.
- **참고**: [원소 대수](/reference/core/06-slot/#원소-대수--넣는-자리와-꺼내는-자리의-타입이-다르다)

### Quad0240

`Slot: this backend cannot mount this value` — `quad-base/src/Slot/Elements.luau`

- **언제**: 백엔드의 `isInst`가 거짓을 돌려주는 값(Roblox 백엔드라면 `Instance`가 아닌 값)을 `Slot`의 원소로 넣으려 할 때.
- **고치려면**: 그 백엔드가 마운트할 수 있는 값(Roblox면 `Instance`), `State`/`Source`, 또는 다른 `Slot`만 넣으세요.
- **참고**: [원소 대수](/reference/core/06-slot/#원소-대수--넣는-자리와-꺼내는-자리의-타입이-다르다)

### Quad0241

`Slot: this element is not claimed by quad - build it with the Declaration or take it over with Claim first (an Instance made by another quad module instance also counts as not claimed here, and so does a destroyed one - a destroyed Instance cannot be reused)` — `quad-base/src/Slot/Elements.luau`

- **언제**: quad 밖에서 만들어졌거나(`Instance.new`, 다른 라이브러리) 아직 `Claim`으로 넘겨받지 않은 값, 다른 quad 모듈 인스턴스가 만든 값, 또는 이미 파괴된 값을 `Slot`의 원소로 넣으려 할 때 — 죽음을 추적할 수 없는 값은 받지 않습니다.
- **고치려면**: `Declaration`으로 만들거나 [`Claim`](/reference/roblox/04-claim-mapper/)으로 먼저 넘겨받으세요. `Slot`이 대신 claim해 주지 않습니다.
- **참고**: [원소 대수](/reference/core/06-slot/#원소-대수--넣는-자리와-꺼내는-자리의-타입이-다르다), [`Claim`](/reference/roblox/04-claim-mapper/)

### Quad0242

`Slot: destroyed Slot cannot be an element` — `quad-base/src/Slot/Elements.luau`

- **언제**: 이미 파괴된 `Slot`을 다른 `Slot`의 원소로 넣으려 할 때 — 직접 넣으면 그 호출에서, `State`에 담아 넣었으면 그 래퍼가 값을 정착시킬 때(마운트 때, 그 뒤엔 값이 바뀔 때; 폐기된 Quad0169가 하던 일).
- **고치려면**: 파괴된 `Slot`은 원소로 쓸 수 없습니다 — 새 `Slot`을 만드세요.
- **참고**: [죽은 Slot과 마운트 규칙](/reference/core/06-slot/#죽은-slot과-마운트-규칙)

### Quad0259

`{surface}: opts.OwnsElements must be a boolean (got {typeof(opts.OwnsElements)})` — `quad-base/src/Slot/List.luau`(`{surface}`는 부른 표면 — `Slot:List` 또는 `Slot:Single`)

- **언제**: `:List`/`:Single`의 `opts.OwnsElements`에 불리언이 아닌 값(`"false"`, `0` 등)을 줬을 때. 전에는 `false`와 정확히 같을 때만 비소유였어서 이런 값은 조용히 소유로 처리됐습니다.
- **고치려면**: `true`나 `false`를 주거나 옵션을 생략하세요(생략하면 소유).
- **참고**: [`slot:List(data, updateFn, keyFn?, opts?)`](/reference/core/06-slot/#slotlistdata-updatefn-keyfn-opts)

### Quad0260

`Slot:List: data item #{i} is q.KeyGone - it is the marker updateFn receives when a key disappears, not a data value` — `quad-base/src/Slot/List.luau`

- **언제**: `:List`의 데이터 배열 항목 자체가 `q.KeyGone`일 때. 전에는 그 항목이 `Item = q.KeyGone`인 평범한 호출로 `updateFn`에 들어가 관용구 첫 줄(`if ctx.Item == q.KeyGone then …`)에서 조용히 빠졌습니다.
- **고치려면**: 데이터에는 실제 값만 두세요 — 항목을 없애려면 배열에서 빼면 됩니다. `q.KeyGone`은 키가 사라질 때 `updateFn`이 **받는** 표시입니다.
- **참고**: [`slot:List(data, updateFn, keyFn?, opts?)`](/reference/core/06-slot/#slotlistdata-updatefn-keyfn-opts)

### Quad0271

`Slot:Lazy: fn must be a function (got {typeof(fn)})` — `quad-base/src/Slot/List.luau`

- **언제**: `slot:Lazy(fn)`에 함수가 아닌 값을 넘겼을 때.
- **고치려면**: 이 Slot의 내용을 지어 돌려주는 함수를 넘기세요 — 이미 지은 원소라면 `Lazy` 없이 `q.Slot{ element }`로 넣으면 됩니다.
- **참고**: [`slot:Lazy(fn)`](/reference/core/06-slot/#slotlazyfn)

### Quad0272

`Slot:Lazy: fn must return one value (got {n}) - put several elements in a Slot and return that (what fn returned is not cleaned up; the Slot stays empty)` — `quad-base/src/Slot/List.luau`

- **언제**: `slot:Lazy(fn)`의 `fn`이 값을 둘 이상 돌려줬을 때 — 그 Slot이 처음 마운트되는 자리에서 납니다. 던진 뒤 `fn`이 이미 만들어 돌려준 원소들은 **정리되지 않고 남습니다** — quad는 사용자 실수로 깨진 자리를 대신 치우지 않습니다(다른 에러 뒤와 같습니다). 그 Slot은 빈 채로 남고 `fn`은 다시 돌지 않습니다.
- **고치려면**: 여러 원소는 `q.Slot{ a, b, c }`에 담아 그 Slot 하나를 돌려주세요.
- **참고**: [`slot:Lazy(fn)`](/reference/core/06-slot/#slotlazyfn)
