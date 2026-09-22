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

- **언제**: `q.Bookkeeping`의 공개 함수에 `ownerKey`(부기의 주인 — 요소 또는 Slot)로 `nil`을 넘겼을 때.
- **고치려면**: 실제 owner를 넘기세요.
- **참고**: [Length/Offset 부기](/reference/extend/02-dispatch-handler-contract/#lengthoffset-부기)

### Quad0021

`Bookkeeping.{fnName}: length must be a non-negative integer (got {tostring(n)})` — `quad-base/src/Bookkeeping.luau`

- **언제**: `q.Bookkeeping.setLength(ownerKey, i, len, ...)`의 `len`(상수인 경우) 또는 그 값에 바인딩된 `State`가 내놓은 값이 음수/소수/숫자가 아닐 때.
- **고치려면**: 0 이상의 정수를 쓰세요.
- **참고**: [`q.Bookkeeping.setLength(ownerKey, i, len, anchor, element)`](/reference/extend/02-dispatch-handler-contract/#qbookkeepingsetlengthownerkey-i-len-anchor-element)

### Quad0022

`Bookkeeping.getOffsetAt: position {at} is past N+1 (N = {last}, at most {last + 1} may be queried) — or a leaf handler skipped its position registration: position {i} is not registered` — `quad-base/src/Bookkeeping.luau`

- **언제**: `q.Bookkeeping.getOffsetAt(ownerKey, at)`으로 조회한 `at`이 등록된 마지막 위치(`N`) + 1보다 클 때 — 범위 밖 조회입니다. (같은 자리에서 중간의 어떤 위치가 등록 자체를 건너뛴 경우도 이 갈래로 잡힙니다 — 두 원인을 코드가 구분할 수 없어 메시지가 둘 다 말합니다.)
- **고치려면**: 등록된 범위(`1..N+1`) 안에서 조회하거나, 먼저 그 위치를 `setLength`/`setOffsetSource`(또는 `setEmpty`)로 등록하세요.
- **참고**: [`q.Bookkeeping.getOffsetAt(ownerKey, at)`](/reference/extend/02-dispatch-handler-contract/#qbookkeepinggetoffsetatownerkey-at)

### Quad0023

`Bookkeeping.recompute: sourceList[{i}] is nil — a nil hole in the numeric-key part of props ({ a, nil, b })? fill the optional slot with q.None (the children placed before this raise stay seated in the half-built Instance, reachable as child.Parent — q.dispose that Instance to clean up; it takes those children with it, so build the retry with new ones); if you are writing a handler, bookkeeping is broken (setLength without setOffsetSource? the contract says None)` — `quad-base/src/Bookkeeping.luau`

- **언제**: 재계산 도중 위치 `i`의 오프셋 발행 채널(`sourceList[i]`)이 `nil`일 때 — 대표 원인은 배열 리터럴 중간에 `nil`이 낀 props(`{ a, nil, b }`)이고, 핸들러를 직접 쓰는 입장이면 `setOffsetSource`(또는 `setEmpty`) 등록을 빠뜨린 경우입니다.
- **고치려면**: 사용자라면 그 옵셔널 자리를 `q.None`으로 채우세요. 핸들러 작성자라면 그 자리의 `setOffsetSource` 등록을 빠뜨리지 않았는지 확인하세요.
- **참고**: [Length/Offset 부기](/reference/extend/02-dispatch-handler-contract/#lengthoffset-부기)

### Quad0024

`Bookkeeping.recompute: lengthList[{i}] is nil — bookkeeping is broken (setOffsetSource without setLength?)` — `quad-base/src/Bookkeeping.luau`

- **언제**: 재계산 도중 위치 `i`의 길이(`lengthList[i]`)가 `nil`일 때 — 내부 불변식 위반으로, 어떤 핸들러가 `setOffsetSource`만 부르고 `setLength`는 부르지 않은 경우입니다.
- **고치려면**: 그 핸들러가 `setLength`도 함께 부르게 하세요(또는 둘 다 하는 `setEmpty`를 쓰세요).
- **참고**: [Length/Offset 부기](/reference/extend/02-dispatch-handler-contract/#lengthoffset-부기)

### Quad0025

`Bookkeeping.setOffsetSource: source must be a Source<number> or None (got {typeof(source)})` — `quad-base/src/Bookkeeping.luau`

- **언제**: `q.Bookkeeping.setOffsetSource(ownerKey, i, source)`의 `source`가 `Source<number>`도 `q.None`도 아닐 때.
- **고치려면**: 부기 채널로 `Source<number>`나 `q.None`(발행 채널 없음)을 넘기세요.
- **참고**: [`q.Bookkeeping.setOffsetSource(ownerKey, i, source)`](/reference/extend/02-dispatch-handler-contract/#qbookkeepingsetoffsetsourceownerkey-i-source)

### Quad0229

`Bookkeeping.getOffsetAt: position {at} needs positions 1..{at - 1} registered but {i} is not — a leaf handler skipped its position registration` — `quad-base/src/Bookkeeping.luau`

- **언제**: 조회한 `at`은 등록 범위 안(`N+1` 이하)인데, 그 앞의 어떤 위치 `i`가 등록되지 않았을 때 — 어떤 leaf 핸들러가 자기 자리의 위치 등록(`setLength`/`setOffsetSource`)을 건너뛴 경우입니다. `getOffsetAt`의 if/else 두 갈래 중 하나로, 같은 조건문의 다른 갈래가 Quad0022입니다.
- **고치려면**: 그 자리를 담당한 핸들러가 반드시 `setLength`와 `setOffsetSource`(또는 그 둘을 한 번에 하는 `setEmpty`)를 부르게 하세요.
- **참고**: [`q.Bookkeeping.getOffsetAt(ownerKey, at)`](/reference/extend/02-dispatch-handler-contract/#qbookkeepinggetoffsetatownerkey-at)
