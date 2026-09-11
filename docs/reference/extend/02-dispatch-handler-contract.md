---
title: 디스패치 핸들러 계약
description: Handler 레코드와 retractor 계약, 우선순위 밴드, q.Dispatch 표면
---
# 디스패치 핸들러 계약

`D.Frame { ... }` 같은 리터럴이 실제 요소를 만들 때, quad는 props의 **자리 하나하나**를 디스패치 엔진에 넘깁니다. 엔진은 등록된 핸들러들을 우선순위대로 훑어 그 (요소, 키, 값) 조합을 처리할 첫 핸들러를 찾고, 그 핸들러가 돌려준 **retractor**를 그 자리에 보관합니다. 나중에 같은 자리에 다른 값이 오면 보관해둔 retractor로 이전 상태를 무릅니다.

이 페이지는 **핸들러를 직접 작성하는 사람**을 위한 계약입니다. 새 값 타입(백엔드의 `Tween`, 플러그인의 스프링 값)이나 새 props 어휘를 추가하려면 여기 규약을 지키는 테이블 하나를 `q.Dispatch.addHandler`로 등록하면 됩니다.

이 페이지의 심볼: [Handler 레코드](#handler-레코드) · [retractor](#retractor) · [우선순위 밴드](#우선순위-밴드) · [q.Dispatch.addHandler(handler)](#qdispatchaddhandlerhandler) · [q.Dispatch.listHandlers()](#qdispatchlisthandlers) · [q.Dispatch.getHandler(inst, key, value)](#qdispatchgethandlerinst-key-value) · [q.Dispatch.process(inst, key, value, index)](#qdispatchprocessinst-key-value-index) · [q.Dispatch.retractFrom(inst, key, index)](#qdispatchretractfrominst-key-index) · [q.Dispatch.drive(inst, flattened)](#qdispatchdriveinst-flattened) · [q.Dispatch.setLength(ownerKey, i, len, anchor, element)](#qdispatchsetlengthownerkey-i-len-anchor-element) · [q.Dispatch.setOffsetSource(ownerKey, i, source)](#qdispatchsetoffsetsourceownerkey-i-source) · [q.Dispatch.setEmpty(ownerKey, i, anchor)](#qdispatchsetemptyownerkey-i-anchor) · [q.Dispatch.getOffsetAt(ownerKey, at)](#qdispatchgetoffsetatownerkey-at) · [q.Dispatch.getBlocker(ownerKey)](#qdispatchgetblockerownerkey) · [q.Dispatch.getBookkeeping(ownerKey)](#qdispatchgetbookkeepingownerkey)

```luau
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("@game/ReplicatedStorage/Client/UI/Quad")
local D = q.D
```

`q.Dispatch`는 모듈 인스턴스마다 따로 있는 네임스페이스입니다 — 핸들러 레지스트리와 부기는 인스턴스별 상태라, 한 인스턴스에 등록한 핸들러는 다른 인스턴스에서 보이지 않습니다.

## Handler 레코드

**시그니처**

```luau
export type Handler = {
	name: string?,
	keyType: ("number" | "string")?,
	isHandlable: (inst: any, key: any, value: any) -> boolean,
	priority: number,
	process: (inst: any, key: any, value: any, index: number) -> (nextValue: any?, retracting: boolean) -> (),
}
```

| 필드 | 필수 | 설명 |
|---|---|---|
| `isHandlable` | ✅ | **순수 판별**. 이 (요소, 키, 값)을 내가 처리할 수 있는가. 부작용을 넣지 마세요 — 매치되지 않는 스캔에서도 계속 불립니다. |
| `priority` | ✅ | 스캔 순서. 큰 값이 먼저입니다. 아래 밴드 상수에서 출발해 `± n`으로 미세 조정합니다. |
| `process` | ✅ | 실제 처리. 반환값은 **retractor**이며 생략할 수 없습니다 — 무를 것이 없어도 `q.Void`를 돌려줍니다. |
| `name` | — | **진단 전용**. 동률 경고와 `listHandlers` 덤프에 쓰입니다. 스캔·매치에는 아무 영향이 없고, 없으면 priority만 보입니다. |
| `keyType` | — | "나는 이 타입의 키에서만 매치될 수 있다"는 선언. 스캔 버킷을 좁히는 힌트입니다. |

`process`의 `index`는 그 자리의 **체인 깊이**입니다. 값을 한 겹 벗겨 아래로 위임하는 핸들러(래핑 핸들러)는 `q.Dispatch.process(inst, key, 벗긴값, index + 1)`을 부릅니다 — 그러면 같은 자리에 핸들러가 층으로 쌓이고, 무를 때는 깊은 층부터 역순으로 풀립니다.

**`keyType`은 `isHandlable`을 대신하지 않습니다.** 최종 판별자는 여전히 `isHandlable`이고, 선언은 그 술어가 어차피 거부할 키를 아예 묻지 않게 할 뿐입니다. 그래서 둘이 어긋나게 선언하면 **조용히** 그 버킷에서 빠지고, 더 낮은 우선순위의 미선언 핸들러가 대신 매치될 수 있습니다 — 선언 값은 `isHandlable`의 `type(key)` 가드와 같아야 합니다. 선언하지 않으면 모든 버킷에 듭니다.

## retractor

**시그니처**

```luau
(nextValue: any?, retracting: boolean) -> ()
```

`process`가 돌려주는 함수입니다. 그 자리를 무를 때 엔진이 부릅니다.

| 이름 | 설명 |
|---|---|
| `nextValue` | 같은 핸들러가 곧 처리할 새 값. 단순 철거일 때는 `nil`. |
| `retracting` | `true`면 **단순 철거** — 이 자리는 다시 처리되지 않습니다. `false`면 같은 핸들러의 재처리가 곧 뒤따릅니다. |

두 번째 인자가 존재하는 이유는 하나입니다: `nil`을 값으로 받을 수 있는 핸들러가 **"철거의 nil"과 "값인 nil"을 구별**할 수 있어야 하기 때문입니다. `retracting`을 보지 않고 `nextValue == nil`만 보면 둘을 섞습니다.

같은 핸들러가 같은 자리를 계속 맡을 때는 아래 층을 건드리지 않습니다 — 앉아 있던 retractor에게 새 값을 넘겨 자기 전이를 하게 한 뒤, 그 한 층만 새 retractor로 교체합니다. 핸들러가 **바뀌면** 그 층과 그 아래를 전부 무르고(깊은 쪽부터) 새로 설치합니다.

관측되는 호출 순서 — `Note` 키에 값을 두 번 넣고 마지막에 철거하면:

| 시점 | 호출 |
|---|---|
| 첫 값 | `process(inst, "Note", 값1, 1)` |
| 둘째 값 | `retractor(값2, false)` → `process(inst, "Note", 값2, 1)` |
| 철거 | `retractor(nil, true)` |

## 우선순위 밴드

**시그니처**

```luau
HANDLER_PRIORITY_HIGH: number
HANDLER_PRIORITY_NORMAL: number
HANDLER_PRIORITY_LOW: number
HANDLER_PRIORITY_FALLBACK: number
```

| 상수 | 값 | 쓰임 |
|---|---|---|
| `q.Dispatch.HANDLER_PRIORITY_HIGH` | `1000` | 센티널·래핑처럼 다른 어떤 해석보다 먼저 봐야 하는 것 |
| `q.Dispatch.HANDLER_PRIORITY_NORMAL` | `0` | 보통의 값 핸들러 |
| `q.Dispatch.HANDLER_PRIORITY_LOW` | `-1000` | 더 구체적인 핸들러에 양보하는 것 |
| `q.Dispatch.HANDLER_PRIORITY_FALLBACK` | `-1000000` | 아무도 못 잡았을 때의 마지막 그물 |

우선순위 공간은 **열린 숫자**입니다 — 계약은 밴드의 순서와 의미이고, 리터럴 값 자체는 계약이 아닙니다. `HANDLER_PRIORITY_NORMAL + 1`처럼 밴드에서 오프셋해 쓰는 것이 의도된 사용법입니다.

**동률에는 정의된 순서가 없습니다.** `q.debug`가 참이면 등록 시점에 진단 줄이 출력됩니다(같은 버킷을 두고 경쟁할 수 있는 핸들러들 사이에서만 — 서로 다른 `keyType`을 선언한 둘은 애초에 같은 버킷에 없으므로 동률로 치지 않습니다).

## `q.Dispatch.addHandler(handler)`

**시그니처**

```luau
addHandler: (handler: Handler) -> ()
```

**동작** — 핸들러를 이 모듈 인스턴스의 레지스트리에 등록합니다. 레지스트리는 항상 우선순위 내림차순으로 정렬돼 있고, 키 타입별 스캔 목록이 등록 때마다 다시 만들어집니다. 받은 `isHandlable`/`process`는 그 자리에서 에러 태그 층에 등록됩니다 — 그래야 프로바이더의 프레임이 사용자 코드가 아니라 quad 기계로 보이고, blame이 사용자 줄에 닿습니다.

모양 검사가 먼저 돕니다.

```
Dispatch.addHandler: handler must be a table with isHandlable/process functions and a numeric priority (got {typeof})
Dispatch.addHandler: keyType must be "number", "string" or nil (got {값})
```

## `q.Dispatch.listHandlers()`

**시그니처**

```luau
listHandlers: () -> { Handler }
```

**반환** — 등록된 핸들러 전부를 우선순위 순으로 담은 **사본**. 호출자가 만져도 레지스트리는 흔들리지 않습니다.

**동작** — 순수 조회입니다. 아무것도 출력하지 않습니다 — 보여줄지 말지는 부르는 쪽의 일입니다.

## `q.Dispatch.getHandler(inst, key, value)`

**시그니처**

```luau
getHandler: (inst: any, key: any, value: any) -> Handler?
```

**반환** — 우선순위 순으로 `isHandlable`이 참을 준 **첫** 핸들러, 없으면 `nil`.

**동작** — 순수 스캔입니다. `process`/`retract`를 부르지 않고 부기도 건드리지 않습니다. 매치 실패를 에러로 만드는 것은 `process`의 일이라, 여기서는 조용히 `nil`입니다. 키의 `type`에 맞는 버킷만 훑습니다.

## `q.Dispatch.process(inst, key, value, index)`

**시그니처**

```luau
process: (inst: any, key: any, value: any, index: number) -> ()
```

| 이름 | 타입 | 설명 |
|---|---|---|
| `inst` | `any` | 대상 요소. `nil`이면 에러 |
| `key` | `any` | props의 키(숫자 키 자리면 숫자, 문자 키면 문자열 등) |
| `value` | `any` | 그 자리의 값 |
| `index` | `number` | 체인 깊이. 최초 진입은 `1`, 위임은 `index + 1` |

**동작** — 그 자리에 값을 설치합니다. 위 [retractor](#retractor) 절의 전이 규칙이 여기서 실행됩니다. 체인 리스트는 `process` 본문이 핸들러를 부르기 **전에** 등록됩니다 — 그래야 핸들러가 재귀적으로 자기 자신을 다시 부를 때 같은 리스트에 층을 쌓습니다.

매치되는 핸들러가 없으면 즉시 던지고, 메시지는 사용자의 진입 줄까지 올라갑니다. 값의 브랜드를 알아낼 수 있으면 같이 싣습니다.

```
Dispatch: no handler matched key {키} (value: {typeof}, brand: {브랜드}) — check that the provider for this value (e.g. quad-roblox) is initialized
```

값이 `nil`이면 뒤에 한 줄이 더 붙습니다 — 그 `nil`은 벗겨진 `None`일 수도, 반응형 `nil`일 수도 있고, 그 키를 맡은 핸들러가 `nil`을 받아들여야 한다는 안내입니다.

핸들러가 retractor를 돌려주지 않으면 프로바이더 계약 위반입니다.

```
Dispatch: handler "{이름}" (priority {n}) returned no retractor at key {키}, index {i} — return Void when there is nothing to undo
```

`inst`가 `nil`이면 `Dispatch.process: inst must not be nil`.

## `q.Dispatch.retractFrom(inst, key, index)`

**시그니처**

```luau
retractFrom: (inst: any, key: any, index: number) -> ()
```

**동작** — `index`(포함)부터 그 자리 체인의 꼬리까지를 **깊은 쪽부터** 무릅니다. 얕은 층이 깊은 층을 만들었으므로 역순이 맞습니다. 각 retractor는 `(nil, true)`로 불립니다 — 단순 철거이고 뒤따르는 재처리가 없다는 뜻입니다.

체인이 비면 그 자리의 **체인 기록**이 놓입니다(Length/Offset 부기는 핸들러가 `setLength(…, 0)` 경로로 직접 풀어야 합니다). `inst`가 `nil`이면 `Dispatch.retractFrom: inst must not be nil`.

## `q.Dispatch.drive(inst, flattened)`

**시그니처**

```luau
drive: (inst: any, flattened: { [any]: any }) -> ()
```

**동작** — props 테이블 하나를 요소에 통째로 적용하는 파이프라인입니다. 백엔드의 생성 경로(`D.<Class>{ ... }`)와 `Claim`이 같은 함수를 부릅니다. 순서:

1. **숫자 키 자리 도메인 검사** — 숫자 키는 양의 정수여야 합니다. 어떤 핸들러가 부기를 만지기 전에 먼저 봅니다.
2. **flatten** — 숫자 키 자리의 Modifier를 그 자리에서 소비하고, 그 필드들을 문자 키 자리에 병합합니다. 배열 길이는 바뀌지 않습니다.
3. **배치 게이트 열기** — 숫자 키가 있을 때만 그 요소의 배치 Blocker를 켭니다(자식이 없는 요소가 괜히 부기를 키우지 않도록).
4. **`PreRef` 사전 통과** — 숫자 키의 `PreRef`가 여기서 발화하고, `PostRef`는 수집됩니다. 소비된 자리는 센티널로 바뀌어 배열에 구멍이 생기지 않습니다.
5. **본문 루프** — 모든 자리에 대해 `process(inst, key, value, 1)`.
6. **`PostRef` 발화** — 본문 루프 뒤, 배치가 닫히기 **전에**. 그래서 콜백 안에서 한 `slot:Add` 같은 변경도 같은 배치에 흡수됩니다.
7. **배치 닫기** — 게이트를 닫고 정확히 한 번 재계산합니다.

입력 게이트:

```
Dispatch.drive: props must be a table (got {typeof})
Dispatch.drive: props must be a plain { ... } table — a quad value needs the braces (got {브랜드})
Dispatch.drive: inst must not be nil
Dispatch.drive: array keys must be positive integers (got {키})
```

둘째 문구는 `D.Frame(q.Source(1))`처럼 중괄호를 잊은 형태를 잡습니다 — 그 값의 내부 필드가 props로 해석되는 조용한 오작동을 막습니다.

## Length/Offset 부기

아래 부기 함수들은 **말단(leaf) 핸들러 작성자**를 위한 표면입니다. 숫자 키 자리는 물리 트리에서 여러 개의 실제 요소를 차지할 수 있으므로(자식 하나일 수도, Slot이 펼치는 N개일 수도 있다), 엔진은 자리마다 "길이"와 "시작 오프셋"을 부기해 부분합으로 관리합니다.

**계약**: 숫자 키 자리를 맡은 말단 핸들러는 **자리마다 길이와 오프셋 소스를 둘 다 등록**해야 합니다. 하나라도 빠뜨리면 그 owner의 오프셋 산술이 깨지고, 나중에 `getOffsetAt`이 "등록을 건너뛴 핸들러가 있다"고 알려주는 자리에서 터집니다. 해제 순서는 **`setOffsetSource(None)` 다음 `setLength(0)`**이고, 그 쌍을 한 번에 하는 함수가 `setEmpty`입니다. 문자 키 핸들러에는 이 의무가 없습니다.

공통 인자 검사는 세 종류이고 함수 이름만 바뀝니다.

```
Dispatch.{함수}: ownerKey must not be nil
Dispatch.{함수}: position must be a positive integer (got {tostring(i)})
Dispatch.{함수}: length must be a non-negative integer (got {tostring(n)})
```

## `q.Dispatch.setLength(ownerKey, i, len, anchor, element)`

**시그니처**

```luau
setLength: (ownerKey: any, i: number, len: number | StateMarker<number>, anchor: any?, element: any?) -> ()
```

| 이름 | 타입 | 설명 |
|---|---|---|
| `ownerKey` | `any` | 부기의 주인 — 요소이거나 Slot |
| `i` | `number` | 숫자 키 자리(1부터) |
| `len` | `number \| StateMarker<number>` | 이 자리가 차지하는 물리 요소 수. 상수이거나 `State<number>` |
| `anchor` | `any?` | State 길이일 때 구독의 수명을 묶을 대상. 생략하면 `ownerKey` |
| `element` | `any?` | 이 자리에 놓인 요소 — 나중에 자리를 되짚기 위한 역맵에 기록됩니다 |

**동작** — 자리 `i`의 길이를 등록합니다. `len`이 `State`면 그 상태를 구독해 값이 바뀔 때마다 뒤 자리들의 오프셋을 다시 계산하고, 상수면 같은 게이트를 한 번 통과합니다. 등록은 그 자리와 그 **뒤** 자리들의 캐시를 무효화합니다(자리 `i` 자신의 오프셋은 앞 자리들의 합이라 바뀌지 않습니다).

`State` 길이의 값 검사는 그 상태의 옵서버 안에서 돕니다 — 재계산 창 안에서 던져 owner를 얼어붙게 만들지 않기 위해서입니다.

## `q.Dispatch.setOffsetSource(ownerKey, i, source)`

**시그니처**

```luau
setOffsetSource: (ownerKey: any, i: number, source: any) -> () -- Source<number> | None
```

**동작** — 자리 `i`의 **오프셋 발행 채널**을 등록합니다. `Source<number>`를 주면 그 자리의 절대 오프셋이 바뀔 때마다 그 소스에 `:Set`됩니다(등록 즉시 현재 값과 다르면 한 번 발행). `q.None`을 주면 "발행 채널 없음"이라는 뜻입니다 — **참여하지 않는다는 뜻이 아닙니다**(참여 여부는 길이 쪽이 답합니다). 그런 자리의 오프셋이 필요하면 `getOffsetAt`으로 당겨옵니다.

```
Dispatch.setOffsetSource: source must be a Source<number> or None (got {typeof})
```

이 검사는 부기를 한 글자도 쓰기 전에 돕니다 — 잘못된 소스를 절반쯤 기록한 채 실패하면 그 owner의 오프셋 산술이 영구히 얼어붙기 때문입니다.

## `q.Dispatch.setEmpty(ownerKey, i, anchor)`

**시그니처**

```luau
setEmpty: (ownerKey: any, i: number, anchor: any?) -> ()
```

**동작** — "이 자리는 비어 있다"를 등록하는 관용구 한 줄. 내부적으로 `setOffsetSource(ownerKey, i, None)` 다음 `setLength(ownerKey, i, 0, anchor)`를 그 순서대로 부릅니다. 아무것도 마운트하지 않는 말단 핸들러(값이 `nil`인 자리, 소비된 센티널 자리)가 자기 자리를 순서 산술에서 빼지 않고 등록하는 방법입니다.

## `q.Dispatch.getOffsetAt(ownerKey, at)`

**시그니처**

```luau
getOffsetAt: (ownerKey: any, at: number) -> number
```

**반환** — 자리 `at`의 절대 오프셋(0부터 세는 개수). Slot이 owner면 그 Slot 자신의 `.Offset`이 출발점이고, 물리 요소가 owner면 0입니다.

**동작** — 부분합 캐시를 채우며 계산합니다. 길이가 `State`면 그 자리에서 사용자 코드(`:Get()`)가 돌 수 있으므로, 그 코드가 아래쪽을 무효화했으면 그 지점부터 다시 채웁니다.

조회할 수 있는 최대 자리는 **등록된 마지막 자리 + 1**입니다. 그보다 뒤를 묻거나, 중간 자리가 등록되지 않았으면 던집니다.

```
Dispatch.getOffsetAt: position {at} is past N+1 (N = {n}, at most {n+1} may be queried) — or a leaf handler skipped its position registration: position {i} is not registered
Dispatch.getOffsetAt: position {at} needs positions 1..{at-1} registered but {i} is not — a leaf handler skipped its position registration
```

## `q.Dispatch.getBlocker(ownerKey)`

**시그니처**

```luau
getBlocker: (ownerKey: any) -> Blocker
```

**반환** — 그 owner의 **배치 Blocker**(없으면 만들어서). 켜져 있는 동안 자리 등록이 재계산을 촉발하지 않습니다 — 여러 자리를 한 번에 등록할 때 매 자리마다 전체 재계산이 도는 것을 막는 게이트입니다. `drive`가 숫자 키가 있을 때 이걸 켜고, 마지막에 닫으면서 정확히 한 번 재계산합니다.

## `q.Dispatch.getBookkeeping(ownerKey)`

**시그니처**

```luau
getBookkeeping: (ownerKey: any) -> any
```

**반환** — 그 owner의 내부 부기 테이블(없으면 만들어서). **절대 `nil`을 돌려주지 않으므로** 부르는 쪽이 다시 가드할 필요가 없습니다.

반환 타입이 `any`인 이유는 그 테이블의 필드 구성이 공개 계약이 아니기 때문입니다 — 진단·디버깅용으로 열려 있을 뿐, 필드 모양에 의존하는 코드를 쓰지 마세요.

## 예제 — 커스텀 값 타입 하나 붙이기

값 타입 하나와 그걸 맡을 핸들러를 등록합니다. 아래 코드는 위 프롤로그만 있으면 그대로 돕니다(등록까지가 전부이고, 실제 마운트는 그 값이 props 자리에 놓일 때 일어납니다).

```luau
-- 이 확장이 다루는 값
local function LogValue(text: string)
	return table.freeze({ __logValue = text })
end

q.Dispatch.addHandler({
	name = "LogValueHandler",
	keyType = "string", -- 문자 키에서만 경쟁한다
	isHandlable = function(_inst: any, key: any, value: any): boolean
		return type(key) == "string" and type(value) == "table" and (value :: any).__logValue ~= nil
	end,
	priority = q.Dispatch.HANDLER_PRIORITY_NORMAL,
	process = function(_inst: any, key: any, value: any, _index: number)
		print(`mount {key} = {(value :: any).__logValue}`)
		return function(_nextValue: any?, retracting: boolean)
			print(`unmount {key} (retracting = {tostring(retracting)})`)
		end
	end,
})
```

이제 어떤 요소의 `"Note"` 자리에 `LogValue("hello")`가 놓이면 `mount Note = hello`가 찍힙니다. 같은 자리에 `LogValue("world")`가 오면 `unmount Note (retracting = false)` → `mount Note = world` 순으로, 그 자리가 철거되면 `unmount Note (retracting = true)`로 끝납니다.

숫자 키 자리를 맡는 핸들러라면 `process` 안에서 자리 등록을 반드시 해야 합니다 — 물리 요소를 하나 놓았다면 `q.Dispatch.setOffsetSource(inst, key, 오프셋소스)` 다음 `q.Dispatch.setLength(inst, key, 1)`, 아무것도 놓지 않았다면 `q.Dispatch.setEmpty(inst, key)`.

## 한계와 주의

- **`process`가 던지면 그 자리의 정리는 되돌릴 수 없습니다.** 엔진은 `process`를 `pcall`로 감싸지 않습니다(핫 패스이고, quad는 예외 이후의 부기 정합성을 보장하지 않습니다). 그 자리의 슬롯은 no-op 표식을 단 채 남고, 명시적 철거로도 복구되지 않습니다.
- **`keyType`을 잘못 선언하면 조용히 빠집니다.** 등록 자체는 통과하고(값이 `"number"`/`"string"`/`nil` 중 하나이기만 하면), 그 핸들러는 어긋난 버킷에서 아예 후보로 오르지 않습니다.
- **동률 순서는 정의돼 있지 않습니다.** 진단은 `q.debug`가 참일 때만 나옵니다.
- **`isHandlable`은 부작용 없이 순수해야 합니다.** 매치되지 않는 스캔에서도 반복해서 불립니다.
- `Destroy`로 요소가 사라질 때 retractor는 **불리지 않습니다**. 그건 정리가 아니라 메모리 해제이고, 체인·retractor·구독이 그 요소의 수명에 묶여 통째로 수거됩니다.

## 관련

- [백엔드 프로바이더 규약](./01-backend-provider-contract.md) — 핸들러가 부르는 주입 op(`native*`, 생명주기)의 계약
- [core/10 — 생명주기와 센티널](../core/10-lifetime-sentinels.md) — retractor 자리에 돌려주는 `q.Void`, 값 자리의 `q.None`
- [sugar/06 — Blocker](../sugar/06-blocker.md) — 배치 게이트에 쓰이는 `Blocker`
- [Quadnomicon Vol. 8 — 확장 가능한 디스패치 엔진](../../quadnomicon/08-extensible-dispatch-engine.md) — 이 엔진이 왜 이렇게 생겼는가
- [Quadnomicon Vol. 2 — Slot-in-Slot 부분합 트리](../../quadnomicon/02-slot-prefix-sum-tree.md) — Length/Offset 부분합 트리의 설계
