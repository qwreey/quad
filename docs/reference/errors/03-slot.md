---
title: "에러 코드 — Slot"
description: "Slot CRUD·:List·:Single·dispose가 던지는 에러"
---
# [레퍼런스] 에러 코드 — Slot

각 절은 `### QuadNNNN` — 메시지 원문(자리표시자는 `{…}`), 언제 나는가, 어떻게 고치는가. 번호로 찾으려면 [색인](./00-index.md).


### Quad0140

`Slot: destroyed Slot cannot be mounted` — `quad-base/src/Slot/Handler.luau`

- **언제**: 이미 파괴된 `Slot`을 부모의 숫자 키 자리에 놓아 마운트하려 할 때 — `claimOwnerAt`/`bindLifetime`이 커밋되기 전에 걸러집니다.
- **고치려면**: 파괴된 `Slot`은 되살릴 수 없습니다 — 새 `Slot`을 만들어 놓으세요.
- **참고**: [죽은 Slot과 마운트 규칙](../core/06-slot.md#죽은-slot과-마운트-규칙)

### Quad0141

`Slot: must be an array item, not the value of a {typeof(k)} key` — `quad-base/src/Slot/Handler.luau`

- **언제**: `Slot`을 props의 문자 키 값 자리에 두거나, `State`/`Store`에 담아 그 자리에 닿게 했을 때.
- **고치려면**: `Slot`은 부모의 숫자 키(배열부) 리터럴 자리에만 놓으세요.
- **참고**: [Slot](../core/06-slot.md)

### Quad0142

`Slot:List: data must be a plain array (got {typeof(items)}) — a data State must hold one too` — `quad-base/src/Slot/List.luau`

- **언제**: `:List`/`:Single`의 재조정이 돌 때(마운트 시점, 또는 `data`가 `State`면 그 값이 바뀔 때마다) `data`(또는 그 `State`가 담은 현재 값)가 테이블이 아니거나 메타테이블이 있을 때 — 브랜드된 quad 값(`Store`/`Tween`/`Modifier` 등)도 메타테이블이 있어 배열로 치지 않습니다.
- **고치려면**: `data`(또는 그 `State`의 값)를 평범한 `{ ... }` 배열로 주세요.
- **참고**: [`slot:List(data, updateFn, keyFn?, opts?)`](../core/06-slot.md#slotlistdata-updatefn-keyfn-opts)

### Quad0143

`Slot:List: data must be a plain array — key "{tostring(k)}" is not an array position` — `quad-base/src/Slot/List.luau`

- **언제**: 재조정 중 `data` 테이블에 정수가 아니거나 1보다 작은 키가 있을 때 — 딕셔너리(아이디 맵, 디코딩된 JSON 오브젝트 등)를 통째로 `:List`에 준 경우가 대표적입니다.
- **고치려면**: `data`를 1부터 시작하는 배열로 주세요.
- **참고**: [`slot:List(data, updateFn, keyFn?, opts?)`](../core/06-slot.md#slotlistdata-updatefn-keyfn-opts)

### Quad0144

`Slot:List: keyFn returned {if key == nil then "nil" else "NaN"} for item #{i}` — `quad-base/src/Slot/List.luau`

- **언제**: `keyFn(item, i)`이 `nil` 또는 NaN을 돌려줬을 때 — 재조정은 이 키로 항목의 신원을 구별하므로 둘 다 쓸 수 없습니다.
- **고치려면**: `keyFn`이 항목마다 유일하고 안정적인 값을 돌려주게 하세요.
- **참고**: [`slot:List(data, updateFn, keyFn?, opts?)`](../core/06-slot.md#slotlistdata-updatefn-keyfn-opts)

### Quad0145

`Slot:List: duplicate key {tostring(key)}` — `quad-base/src/Slot/List.luau`

- **언제**: `keyFn`이 두 항목에 같은 키를 돌려줬을 때 — 재조정은 키로 항목을 구별하므로 겹치면 어느 쪽이 그 자리인지 정할 수 없습니다.
- **고치려면**: `keyFn`이 항목마다 유일한 값을 돌려주게 하세요(id 필드 등).
- **참고**: [`slot:List(data, updateFn, keyFn?, opts?)`](../core/06-slot.md#slotlistdata-updatefn-keyfn-opts)

### Quad0146

`Slot:List: updateFn returned q.KeyGone — it is the marker updateFn RECEIVES when a key disappears; return nil/q.None to drop the element or q.Detach to hold it` — `quad-base/src/Slot/List.luau`

- **언제**: `updateFn`이 결과 자리에 `q.KeyGone`을 그대로 반환했을 때 — `KeyGone`은 사라진 키를 알리려고 `updateFn`이 **받는** 입력 마커이지, 반환값이 아닙니다.
- **고치려면**: 그 항목을 버리려면 `nil`/`q.None`을, 파괴하지 않고 보관하려면 `q.Detach`를 반환하세요.
- **참고**: [`q.KeyGone`](../core/10-lifetime-sentinels.md#qkeygone)

### Quad0147

`Slot:List: KeyGone accepts only nil/None (destroy) or Detach (hold)` — `quad-base/src/Slot/List.luau`

- **언제**: 사라진 키를 처리하는 `KeyGone` 호출(`ctx.Item == q.KeyGone`)에서 `updateFn`이 새 원소를 반환했을 때.
- **고치려면**: 그 호출에서는 `nil`/`q.None`(파괴) 또는 `q.Detach`(보관)만 반환하세요.
- **참고**: [`q.KeyGone`](../core/10-lifetime-sentinels.md#qkeygone)

### Quad0148

`Slot: already has :List/:Single installed` — `quad-base/src/Slot/List.luau`

- **언제**: 이미 `:List`나 `:Single`을 건 `Slot`에 다시 `:List`/`:Single`을 걸려고 할 때 — 재조정 모드 설치는 한 Slot에 한 번뿐입니다.
- **고치려면**: 다른 데이터를 반영하려면 그 `:List`가 참조하는 `data` State를 바꾸세요 — 재설치는 하지 않습니다.
- **참고**: [`slot:List(data, updateFn, keyFn?, opts?)`](../core/06-slot.md#slotlistdata-updatefn-keyfn-opts)

### Quad0149

`Slot: cannot install :List/:Single on a manual Slot (one that used CRUD or was built as Slot{ ... }, even empty)` — `quad-base/src/Slot/List.luau`

- **언제**: 이미 수동 CRUD(`Add`/`Remove`/... 또는 `initial` 원소를 준 생성자)를 쓴 `Slot`에 `:List`/`:Single`을 걸려고 할 때 — 두 모드는 상호 배타입니다.
- **고치려면**: `:List`/`:Single`을 쓸 `Slot`은 CRUD 없이 빈 `q.Slot()`으로 만드세요.
- **참고**: [`slot:List(data, updateFn, keyFn?, opts?)`](../core/06-slot.md#slotlistdata-updatefn-keyfn-opts)

### Quad0150

`Slot:List: updateFn must be a function (got {typeof(updateFn)})` — `quad-base/src/Slot/List.luau`

- **언제**: `:List`의 두 번째 인자 `updateFn`이 함수가 아닐 때.
- **고치려면**: 항목 하나를 원소로 바꾸는 함수를 넘기세요.
- **참고**: [`slot:List(data, updateFn, keyFn?, opts?)`](../core/06-slot.md#slotlistdata-updatefn-keyfn-opts)

### Quad0151

`Slot:List: data must be a plain array or a State of one (got {typeof(data)})` — `quad-base/src/Slot/List.luau`

- **언제**: `:List`의 첫 인자 `data`가 평범한 배열도, 배열을 담은 `State`도 아닐 때 — 브랜드된 quad 값(`Store`/`Tween`/`Modifier` 등)은 메타테이블이 있어 여기 걸립니다.
- **고치려면**: 배열 리터럴이나 배열을 담은 `State`를 넘기세요.
- **참고**: [`slot:List(data, updateFn, keyFn?, opts?)`](../core/06-slot.md#slotlistdata-updatefn-keyfn-opts)

### Quad0152

`Slot:List: keyFn must be a function (got {typeof(keyFn)})` — `quad-base/src/Slot/List.luau`

- **언제**: `:List`의 `keyFn` 인자를 줬는데 함수가 아닐 때(생략은 허용 — 그러면 인덱스가 키가 됩니다).
- **고치려면**: `(item, index) -> any` 모양의 함수를 넘기거나 생략하세요.
- **참고**: [`slot:List(data, updateFn, keyFn?, opts?)`](../core/06-slot.md#slotlistdata-updatefn-keyfn-opts)

### Quad0153

`Slot:List: opts must be a table (got {typeof(opts)})` — `quad-base/src/Slot/List.luau`

- **언제**: `:List`의 `opts` 인자를 줬는데 테이블이 아닐 때.
- **고치려면**: `{ OwnsElements = false }`처럼 테이블로 주거나 생략하세요.
- **참고**: [`slot:List(data, updateFn, keyFn?, opts?)`](../core/06-slot.md#slotlistdata-updatefn-keyfn-opts)

### Quad0154

`Slot:Single: updateFn must be a function (got {typeof(updateFn)})` — `quad-base/src/Slot/List.luau`

- **언제**: `:Single`의 `updateFn` 인자를 줬는데 함수가 아닐 때.
- **고치려면**: 함수를 넘기거나 생략하세요(생략하면 값을 그대로 원소로 쓰는 항등 함수).
- **참고**: [`slot:Single(state, updateFn?, opts?)`](../core/06-slot.md#slotsinglestate-updatefn-opts)

### Quad0155

`Slot:Single: opts must be a table (got {typeof(opts)})` — `quad-base/src/Slot/List.luau`

- **언제**: `:Single`의 `opts` 인자를 줬는데 테이블이 아닐 때.
- **고치려면**: 테이블로 주거나 생략하세요.
- **참고**: [`slot:Single(state, updateFn?, opts?)`](../core/06-slot.md#slotsinglestate-updatefn-opts)

### Quad0156

`Slot: this element is already mounted — multiple mounts are not allowed` — `quad-base/src/Slot/Owner.luau`

- **언제**: 이미 다른 자리(Slot 원소·정적 자식·숏핸드가 만드는 관리 자식 — 전부 한 레지스트리를 같이 씁니다)에 마운트된 값을 다시 마운트하려 할 때.
- **고치려면**: 그 값을 먼저 옛 자리에서 빼세요(`Extract`, 데이터 키 삭제 등). 다만 그 값의 원래 owner가 quad 밖에서(`inst:Destroy()`) 파괴됐다면 되살릴 수 없습니다.
- **참고**: [죽은 Slot과 마운트 규칙](../core/06-slot.md#죽은-slot과-마운트-규칙)

### Quad0157

`Bookkeeping.claimOwnerAt: element must not be nil` — `quad-base/src/Slot/Owner.luau`

- **언제**: `q.Bookkeeping.claimOwnerAt(element, inst, k)`에 `element`로 `nil`을 넘겼을 때.
- **고치려면**: 실제 값을 넘기세요.
- **참고**: [`q.Bookkeeping.claimOwnerAt(element, inst, k)`](../extend/02-dispatch-handler-contract.md#qbookkeepingclaimowneratelement-inst-k)

### Quad0158

`Bookkeeping.claimOwnerAt: inst (ownerKey) must not be nil` — `quad-base/src/Slot/Owner.luau`

- **언제**: `claimOwnerAt`의 `inst`(그 자리의 주인 — ownerKey)로 `nil`을 넘겼을 때.
- **고치려면**: 실제 owner를 넘기세요.
- **참고**: [`q.Bookkeeping.claimOwnerAt(element, inst, k)`](../extend/02-dispatch-handler-contract.md#qbookkeepingclaimowneratelement-inst-k)

### Quad0159

`Bookkeeping.claimOwnerAt: k (seat key — a position or a shorthand child name) must not be nil` — `quad-base/src/Slot/Owner.luau`

- **언제**: `claimOwnerAt`의 `k`(자리 키 — 위치 숫자 또는 숏핸드 자식 이름)로 `nil`을 넘겼을 때 — `nil` 위치로 등록하면 나중에 그 자리를 되짚거나 해제할 수 없는 자리가 생깁니다.
- **고치려면**: 실제 위치 숫자나 자식 이름을 넘기세요.
- **참고**: [`q.Bookkeeping.claimOwnerAt(element, inst, k)`](../extend/02-dispatch-handler-contract.md#qbookkeepingclaimowneratelement-inst-k)

### Quad0160

`Bookkeeping.claimOwnerAt: this element is already mounted elsewhere — multiple mounts are not allowed` — `quad-base/src/Slot/Owner.luau`

- **언제**: `claimOwnerAt`이 등록하려는 값이 이미 다른 자리에 등록돼 있을 때(정확히 같은 자리의 재확인은 예외 — 던지지 않고 `false`를 돌려줍니다).
- **고치려면**: Quad0156과 같습니다 — 먼저 옛 자리에서 빼세요.
- **참고**: [죽은 Slot과 마운트 규칙](../core/06-slot.md#죽은-slot과-마운트-규칙), [`q.Bookkeeping.claimOwnerAt(element, inst, k)`](../extend/02-dispatch-handler-contract.md#qbookkeepingclaimowneratelement-inst-k)

### Quad0161

`Bookkeeping.releaseOwner: element must not be nil` — `quad-base/src/Slot/Owner.luau`

- **언제**: `q.Bookkeeping.releaseOwner(element, ownerKey)`에 `element`로 `nil`을 넘겼을 때.
- **고치려면**: 실제 값을 넘기세요.
- **참고**: [`q.Bookkeeping.releaseOwner(element, ownerKey)`](../extend/02-dispatch-handler-contract.md#qbookkeepingreleaseownerelement-ownerkey)

### Quad0162

`Bookkeeping.releaseOwner: ownerKey must not be nil` — `quad-base/src/Slot/Owner.luau`

- **언제**: `releaseOwner`의 `ownerKey`로 `nil`을 넘겼을 때.
- **고치려면**: 실제 owner를 넘기세요.
- **참고**: [`q.Bookkeeping.releaseOwner(element, ownerKey)`](../extend/02-dispatch-handler-contract.md#qbookkeepingreleaseownerelement-ownerkey)

### Quad0163

`Bookkeeping.releaseOwner: this element is not owned by this ownerKey — ownership tracking is broken` — `quad-base/src/Slot/Owner.luau`

- **언제**: `releaseOwner`에 넘긴 `ownerKey`가 그 값을 실제로 쥔 owner와 다를 때 — 자기가 잡지 않은 자리를 풀려고 한 것으로, 소유권 부기가 깨졌다는 신호입니다.
- **고치려면**: 자기가 `claimOwnerAt`으로 잡은 자리만 `releaseOwner`로 푸세요.
- **참고**: [`q.Bookkeeping.releaseOwner(element, ownerKey)`](../extend/02-dispatch-handler-contract.md#qbookkeepingreleaseownerelement-ownerkey)

### Quad0164

`Slot: destroyed Slot cannot be mounted` — `quad-base/src/Slot/Tree.luau`

- **같은 뜻**: Quad0140
- **언제**: 이미 파괴된 `Slot`을 마운트(부모의 숫자 키 자리에 놓는 것)하려 할 때 — `materializeSlotTree`의 첫 검사입니다.
- **고치려면**: 파괴된 `Slot`은 되살릴 수 없습니다 — 새 `Slot`을 만드세요.
- **참고**: [죽은 Slot과 마운트 규칙](../core/06-slot.md#죽은-slot과-마운트-규칙)

### Quad0165

`Slot: destroyed Slot cannot be reused` — `quad-base/src/Slot/init.luau`

- **언제**: 파괴된 `Slot`에 CRUD(`Add`/`Remove`/...)나 `:List`/`:Single` 설치를 다시 쓰려고 할 때 — 모든 공개 CRUD·설치 진입점이 이 가드(`assertLive`)를 거칩니다.
- **고치려면**: 파괴된 `Slot`은 되살릴 수 없습니다 — 새 `Slot`을 만드세요.
- **참고**: [죽은 Slot과 마운트 규칙](../core/06-slot.md#죽은-slot과-마운트-규칙)

### Quad0166

`Slot: manual CRUD is not allowed after :List/:Single` — `quad-base/src/Slot/init.luau`

- **언제**: `:List`/`:Single`을 이미 건 `Slot`에 수동 CRUD(`Add`/`Remove`/`Replace`/...)를 쓰려고 할 때.
- **고치려면**: `:List`/`:Single`을 건 `Slot`은 그 데이터 `State`를 통해서만 바꾸세요 — 수동 CRUD가 필요하면 그 설치 없이 새 `Slot`을 만드세요.
- **참고**: [`slot:List(data, updateFn, keyFn?, opts?)`](../core/06-slot.md#slotlistdata-updatefn-keyfn-opts)

### Quad0167

`Slot: cannot mutate a Slot while it is being mounted — a :List/:Single updateFn (or an Observer that fires during the mount) must not CRUD an ancestor Slot; do it after the mount, from an Observer (or an earlier mount into this Slot threw mid-way — then this Slot stays unusable: dispose its host Instance)` — `quad-base/src/Slot/init.luau`

- **언제**: 이 `Slot`의 마운트 walk이 스택에 있는 동안(`_materializing`) 이 `Slot`에 CRUD나 `:List`/`:Single` 설치를 쓰려고 할 때 — 중첩된 `:List`의 첫 `updateFn`이나 그 안에서 도는 `Observer`가 조상 `Slot`을 건드리면 여기 걸립니다.
- **고치려면**: 마운트가 끝난 뒤(`Observer`에서) 하세요. 이미 이 에러가 났다면 이전 마운트가 도중에 던진 것이라 이 `Slot`은 계속 쓸 수 없습니다 — 호스트 Instance를 `q.dispose`하세요.
- **참고**: [`slot:List(data, updateFn, keyFn?, opts?)`](../core/06-slot.md#slotlistdata-updatefn-keyfn-opts)

### Quad0168

`{surface}: index must be a positive integer (got {tostring(index)})` — `quad-base/src/Slot/init.luau`

- **언제**: `Add`/`Remove`/`Replace`/`Extract`/`Splice`/`Move`/`Swap` 같은 CRUD의 `index` 인자가 숫자가 아니거나 정수가 아닐 때. `{surface}`는 실제로 부른 메소드 이름(`Slot:Add` 등)입니다.
- **고치려면**: 정수 인덱스를 넘기세요.
- **참고**: [`slot:Add(element, index?)`](../core/06-slot.md#slotaddelement-index)

### Quad0236

`{surface}: index out of range (got {index}, limit {limit})` — `quad-base/src/Slot/init.luau`

- **언제**: Quad0168과 같은 CRUD의 `index`가 정수이지만 허용 범위(1..n, `Add`/`Splice`는 1..n+1)를 벗어났을 때. Quad0168과 한 호출(`checkIndex`)의 두 갈래입니다.
- **고치려면**: 현재 길이에 맞는 범위 안의 인덱스를 넘기세요 — 클램프하지 않습니다.
- **참고**: [`slot:Add(element, index?)`](../core/06-slot.md#slotaddelement-index)

### Quad0169

`{surface}: destroyed Slot cannot be an element` — `quad-base/src/Slot/init.luau`

- **언제**: 이미 파괴된 `Slot`을 다른 `Slot`의 원소로 넣으려 할 때(`prepareElements`의 배치 사전검사).
- **고치려면**: 파괴된 `Slot`은 원소로 쓸 수 없습니다 — 새 `Slot`을 만드세요.
- **참고**: [죽은 Slot과 마운트 규칙](../core/06-slot.md#죽은-slot과-마운트-규칙)

### Quad0170

`{surface}: this element is already in this Slot — reorder with Move/Swap instead of adding it again` — `quad-base/src/Slot/init.luau`

- **언제**: 이 `Slot`이 이미 들고 있는 원소를 다시 넣으려 할 때(`Replace(i, slot:Get(i))`, `Splice`가 방금 뺀 원소를 같은 호출에서 다시 넣는 경우 등).
- **고치려면**: 순서만 바꾸려면 `Move`/`Swap`을 쓰세요 — 재추가는 두 번째 마운트로 거부됩니다.
- **참고**: [`slot:Splice(index, removeCount, ...newElements)`](../core/06-slot.md#slotspliceindex-removecount-newelements)

### Quad0171

`{surface}: the same element appears twice` — `quad-base/src/Slot/init.luau`

- **언제**: 한 번의 배치 호출(`Splice`, 생성자 `initial` 등) 안에 같은 원소가 두 번 들어 있을 때.
- **고치려면**: 배치 안의 원소를 중복 없이 주세요.
- **참고**: [`q.Slot<<T>>(initial?)`](../core/06-slot.md)

### Quad0172

`{surface}: this element is already mounted — multiple mounts are not allowed` — `quad-base/src/Slot/init.luau`

- **언제**: 이미 다른 곳(다른 `Slot`의 원소, 정적 자식, 숏핸드가 만드는 관리 자식 등)에 마운트된 값을 원소로 넣으려 할 때(`prepareElements`의 배치 사전검사).
- **고치려면**: Quad0156과 같습니다 — 먼저 옛 자리에서 빼세요.
- **참고**: [죽은 Slot과 마운트 규칙](../core/06-slot.md#죽은-slot과-마운트-규칙)

### Quad0173

`{surface}: cannot add a Slot to itself or to one of its own descendants (that would be a cycle)` — `quad-base/src/Slot/init.luau`

- **언제**: `Slot`을 자기 자신이나 자기 조상(원소 관계로 이어진)에 원소로 넣으려 할 때 — 그대로 두면 순환이 생겨 이후 CRUD가 `teardownTree`/`releaseOwner`에서 무한히 재귀합니다.
- **고치려면**: 순환이 생기지 않게 구조를 바꾸세요. (인스턴스를 매개로 한 순환은 이 검사 밖입니다 — 정의되지 않은 동작.)
- **참고**: [`slot:Add(element, index?)`](../core/06-slot.md#slotaddelement-index)

### Quad0174

`Slot:Splice: removeCount out of range` — `quad-base/src/Slot/init.luau`

- **언제**: `:Splice`의 `removeCount`가 숫자가 아니거나 음수/소수이거나, `index + removeCount - 1`이 현재 길이를 넘을 때.
- **고치려면**: 실제로 남아 있는 만큼만 지우세요 — 클램프하지 않습니다.
- **참고**: [`slot:Splice(index, removeCount, ...newElements)`](../core/06-slot.md#slotspliceindex-removecount-newelements)

### Quad0175

`Slot:Get: index must be a number (got {typeof(index)})` — `quad-base/src/Slot/init.luau`

- **언제**: `:Get`의 `index` 인자가 숫자가 아닐 때 — "빈 Slot"처럼 조용히 `nil`을 주지 않고 던집니다.
- **고치려면**: 숫자 인덱스를 넘기세요(범위 밖은 `nil`을 돌려줄 뿐 던지지 않습니다).
- **참고**: [`slot:Get(index)`](../core/06-slot.md#slotgetindex)

### Quad0176

`Slot: initial elements must be a plain { element, ... } array (got {typeof(initial)} — a bare element or quad value needs the braces)` — `quad-base/src/Slot/init.luau`

- **언제**: 생성자 `q.Slot(initial)`의 `initial`이 테이블이 아니거나, 메타테이블이 있거나(브랜드된 quad 값), 괄호 없이 값 하나만 넘겼을 때(`Slot(frame)`).
- **고치려면**: `{ element, ... }` 모양의 평범한 배열로 감싸서 넘기세요.
- **참고**: [`q.Slot<<T>>(initial?)`](../core/06-slot.md)

### Quad0177

`Slot: initial elements must be an array — key "{tostring(k)}" is not an array position` — `quad-base/src/Slot/init.luau`

- **언제**: `initial` 테이블의 키 중 정수가 아니거나 1보다 작은 것이 있을 때.
- **고치려면**: 1부터 시작하는 배열로 주세요.
- **참고**: [`q.Slot<<T>>(initial?)`](../core/06-slot.md)

### Quad0178

`dispose: value must not be nil` — `quad-base/src/Slot/init.luau`

- **언제**: `q.dispose(value)`에 `nil`을 넘겼을 때.
- **고치려면**: 파괴할 실제 값을 넘기세요.
- **참고**: [`q.dispose(value)`](../core/10-lifetime-sentinels.md#qdisposevalue)

### Quad0179

`dispose: this value is still held by a Slot or a mounted position — Remove/Extract it from a manual Slot, drop its key from a :List Slot's data, destroy the owner Slot (a detached element goes with its owner), or take it off its numeric-key seat first (Set(nil) the State holding it; a shorthand-managed child goes with its key)` — `quad-base/src/Slot/init.luau`

- **언제**: 아직 어떤 `Slot`의 원소이거나 마운트된 자리(정적 자식·숏핸드 관리 자식 포함)를 차지하고 있는 값을 `dispose`하려 할 때.
- **고치려면**: 먼저 그 자리에서 빼세요 — 수동 `Slot`이면 `Remove`/`Extract`, `:List` `Slot`이면 데이터에서 그 키 제거(또는 owner `Slot` 자체를 파괴), 숫자 키 자리면 그 자리를 쥔 `State`를 `Set(nil)`, 숏핸드 관리 자식이면 그 키를 `nil`로.
- **참고**: [`q.dispose(value)`](../core/10-lifetime-sentinels.md#qdisposevalue)

### Quad0180

`dispose: this backend cannot dispose this value` — `quad-base/src/Slot/init.luau`

- **언제**: `dispose`에 준 값이 `Slot`도 아니고 백엔드가 요소로 인정하는 값(`q.Backend.isInst`가 참)도 아닐 때 — 백엔드가 아예 설치되지 않은 모듈에서는 그 전에 `q.Backend.isInst` 스텁이 먼저 던집니다.
- **고치려면**: `Slot`이거나 `q.Backend.isInst`가 참인 값을 넘기세요.
- **참고**: [`q.dispose(value)`](../core/10-lifetime-sentinels.md#qdisposevalue)

### Quad0238

`Slot: handler-layer values (Ref/PreRef/PostRef/Observer/Effect/Modifier) cannot be elements` — `quad-base/src/Slot/Elements.luau`

- **언제**: `Ref`/`PreRef`/`PostRef`/`Observer`/`Effect`/`Modifier` 같은 핸들러 레이어 값을 `Slot`의 원소(생성자 `initial`, `:Add`/`:Replace`/`:Splice`/`:List`/`:Single`의 새 원소)로 넣으려 할 때 — 이런 값은 마운트할 물리 원소가 아니라 다른 값에 붙이는 부착물입니다.
- **고치려면**: 그 값이 붙어야 할 실제 원소(Instance 등) 자리에 붙이고, `Slot`에는 마운트 가능한 값만 넣으세요.
- **참고**: [원소 대수](../core/06-slot.md#원소-대수--넣는-자리와-꺼내는-자리의-타입이-다르다)

### Quad0239

`Slot: nil/None cannot be an element — only actually mountable values` — `quad-base/src/Slot/Elements.luau`

- **언제**: `nil`이나 `q.None`을 `Slot`의 원소로 넣으려 할 때 — `Slot`은 "빈 자리"를 원소 부재가 아니라 배열에서 그 항목이 아예 없는 것으로 표현하므로, `nil`/`None`은 원소 자리에 들어올 수 없습니다.
- **고치려면**: 그 자리를 비우려면 `:Remove`/`:Extract`/`:Splice`로 배열에서 빼세요.
- **참고**: [원소 대수](../core/06-slot.md#원소-대수--넣는-자리와-꺼내는-자리의-타입이-다르다)

### Quad0240

`Slot: this backend cannot mount this value` — `quad-base/src/Slot/Elements.luau`

- **언제**: 백엔드의 `isInst`가 거짓을 돌려주는 값(Roblox 백엔드라면 `Instance`가 아닌 값)을 `Slot`의 원소로 넣으려 할 때.
- **고치려면**: 그 백엔드가 마운트할 수 있는 값(Roblox면 `Instance`), `State`/`Source`, 또는 다른 `Slot`만 넣으세요.
- **참고**: [원소 대수](../core/06-slot.md#원소-대수--넣는-자리와-꺼내는-자리의-타입이-다르다)

### Quad0241

`Slot: this element is not claimed by quad — build it with the Declaration or take it over with Claim first (an Instance made by another quad module instance also counts as not claimed here, and so does a destroyed one — a destroyed Instance cannot be reused)` — `quad-base/src/Slot/Elements.luau`

- **언제**: quad 밖에서 만들어졌거나(`Instance.new`, 다른 라이브러리) 아직 `Claim`으로 넘겨받지 않은 값, 다른 quad 모듈 인스턴스가 만든 값, 또는 이미 파괴된 값을 `Slot`의 원소로 넣으려 할 때 — 죽음을 추적할 수 없는 값은 받지 않습니다.
- **고치려면**: `Declaration`으로 만들거나 [`Claim`](../roblox/04-claim-mapper.md)으로 먼저 넘겨받으세요. `Slot`이 대신 claim해 주지 않습니다.
- **참고**: [원소 대수](../core/06-slot.md#원소-대수--넣는-자리와-꺼내는-자리의-타입이-다르다), [`Claim`](../roblox/04-claim-mapper.md)

### Quad0242

`Slot: destroyed Slot cannot be an element` — `quad-base/src/Slot/Elements.luau`

- **언제**: 이미 파괴된 `Slot`을 다른 `Slot`의 원소로 직접 넣으려 할 때(`wrapElement`의 원소 자체가 파괴된 Slot인 경우 — 같은 뜻: Quad0169, 그쪽은 State로 감싸인 occupant가 파괴된 Slot인 경우).
- **고치려면**: 파괴된 `Slot`은 원소로 쓸 수 없습니다 — 새 `Slot`을 만드세요.
- **참고**: [죽은 Slot과 마운트 규칙](../core/06-slot.md#죽은-slot과-마운트-규칙)
