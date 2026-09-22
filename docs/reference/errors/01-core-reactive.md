---
title: "에러 코드 — 반응형 코어"
description: "Source/State/Store/Blocker/Context/Operator/Debounce·Throttle/Gate가 던지는 에러"
---
# [레퍼런스] 에러 코드 — 반응형 코어

각 절은 `### QuadNNNN` — 메시지 원문(자리표시자는 `{…}`), 언제 나는가, 어떻게 고치는가. 번호로 찾으려면 [색인](./00-index.md).


### Quad0017

`Blocker: Policy emit must be a function (got {typeof(emit)})` — `quad-base/src/Blocker.luau`

- **언제**: `blocker:Policy(emit)`을 직접 부를 때 `emit`이 함수가 아닌 경우. `state:Apply(blocker)`를 쓰면 언제나 함수를 넘기므로 그 경로에서는 나지 않습니다.
- **고치려면**: 게이트의 `setup`이 넘겨준 `emit` 함수를 그대로 넘기세요.
- **참고**: [`blocker:Policy(emit)`](../sugar/06-blocker.md#blockerpolicyemit)

### Quad0018

`Blocker: Apply target must be a State (got {typeof(state)})` — `quad-base/src/Blocker.luau`

- **언제**: `state:Apply(blocker)`의 대상이 `State`가 아닐 때.
- **고치려면**: `State`에 `Apply`하세요.
- **참고**: [`state:Apply(blocker)`](../sugar/06-blocker.md#stateapplyblocker)

### Quad0035

`Context.Provider: name must be a string (got {typeof(name)})` — `quad-base/src/Context.luau`

- **언제**: `q.Context.Provider(name?)`에 준 `name`이 문자열이 아닐 때(생략은 허용됩니다).
- **고치려면**: 문자열이거나 생략(`nil`)으로 두세요.
- **참고**: [`q.Context.Provider(name?)`](../sugar/01-context.md#qcontextprovidername)

### Quad0036

`Context:{fnName}: key must be a Provider from Context.Provider() (got {typeof(provider)})` — `quad-base/src/Context.luau`

- **언제**: `ctx:Set`/`ctx:Get`/`ctx:Peek`의 `provider` 자리에 `q.Context.Provider()`로 만든 값이 아닌 것을 넘겼을 때. `{fnName}`은 실제로 부른 메소드 이름입니다.
- **고치려면**: `q.Context.Provider()`로 만든 키를 넘기세요.
- **참고**: [`ctx:Set(provider, value)`](../sugar/01-context.md#ctxsetprovider-value)

### Quad0037

`Context:Set: value for {tostring(provider)} must not be nil (absence is "not set")` — `quad-base/src/Context.luau`

- **언제**: `ctx:Set(provider, value)`의 `value`로 `nil`을 넘겼을 때 — 부재는 애초에 `:Set`을 하지 않는 것으로 표현합니다.
- **고치려면**: 지우려는 의도라면 `:Set`을 아예 부르지 마세요 — `nil` 대신 실제 값을 넘기세요.
- **참고**: [`ctx:Set(provider, value)`](../sugar/01-context.md#ctxsetprovider-value)

### Quad0038

`Context:Get: no value for {tostring(provider)} — the creator of this Context did not :Set it (use :Peek to test)` — `quad-base/src/Context.luau`

- **언제**: `ctx:Get(provider)`를 불렀는데 그 `Provider`에 아직 아무도 `:Set`하지 않았을 때.
- **고치려면**: 먼저 `:Set`을 부르거나, 없을 수도 있는 값이면 `:Get` 대신 `ctx:Peek(provider)`를 쓰세요.
- **참고**: [`ctx:Get(provider)`](../sugar/01-context.md#ctxgetprovider)

### Quad0039

`{name}: {field} must be a non-negative number (got {typeof(v)})` — `quad-base/src/Debounce.luau`

- **언제**: `Time`(또는 `MaxTime`)에 바인딩한 `State`가 상류 신호 시점에 내놓은 값이 숫자가 아니거나 음수/NaN일 때. 생성 시점이 아니라 **신호가 들어오는 시점**에 읽어 검사합니다.
- **고치려면**: 그 `State`가 항상 0 이상의 숫자를 내놓게 하세요.
- **참고**: [`q.Debounce{...}`](../sugar/03-debounce-throttle.md#qdebounce)

### Quad0040

`{name}: {field} is required (a number of seconds or a State<number>)` — `quad-base/src/Debounce.luau`

- **언제**: `Debounce{...}`/`Throttle{...}`에 필수 옵션인 `Time`을 아예 안 줬을 때.
- **고치려면**: `Time`에 초 단위 숫자나 `State<number>`를 넘기세요.
- **참고**: [`q.Debounce{...}`](../sugar/03-debounce-throttle.md#qdebounce)

### Quad0041

`{name}: {field} must be a non-negative number or a State<number> (got {typeof(t)})` — `quad-base/src/Debounce.luau`

- **언제**: 옵션 생성 시점에 `Time`/`MaxTime`이 `State`도 숫자도 아니거나, 숫자인데 음수/NaN일 때.
- **고치려면**: 0 이상의 숫자나 `State<number>`를 넘기세요.
- **참고**: [`q.Debounce{...}`](../sugar/03-debounce-throttle.md#qdebounce)

### Quad0042

`{name}: {field} must be a boolean (got {typeof(v)})` — `quad-base/src/Debounce.luau`

- **언제**: `Leading`/`Trailing` 옵션에 `boolean`도 `nil`도 아닌 값을 줬을 때.
- **고치려면**: `true`/`false` 중 하나로 주거나 생략하세요.
- **참고**: [`q.Debounce{...}`](../sugar/03-debounce-throttle.md#qdebounce)

### Quad0043

`{self._name}: Apply target must be a State (got {typeof(state)})` — `quad-base/src/Debounce.luau`

- **언제**: `state:Apply(factory)`의 대상이 `State`가 아닐 때(`factory`는 `Debounce{...}`/`Throttle{...}`가 돌려준 값).
- **고치려면**: `State`에 `Apply`하세요.
- **참고**: [공통 계약](../sugar/03-debounce-throttle.md#공통-계약)

### Quad0044

`{name}: Handle is already filled — one Handle Ref per :Apply (make a new Ref, or drop Handle and use the factory's :Flush()/:Cancel() broadcast; a Ref with a non-nil default is rejected the same way)` — `quad-base/src/Debounce.luau`

- **언제**: `opts.Handle`로 넘긴 `Ref`가 이미 다른 `:Apply` 호출의 제어 핸들로 채워져 있을 때(또는 기본값이 `nil`이 아닌 `Ref`를 애초에 줬을 때) — 하나의 `Ref`는 하나의 `:Apply`만 가리킬 수 있습니다.
- **고치려면**: 새 `Ref`를 만들거나, `Handle`을 빼고 팩토리의 `:Flush()`/`:Cancel()` 브로드캐스트를 쓰세요.
- **참고**: [제어 핸들(`GateHandle`)](../sugar/03-debounce-throttle.md#제어-핸들-gatehandle)

### Quad0045

`{name}: options table expected (got {typeof(opts)})` — `quad-base/src/Debounce.luau`

- **언제**: `q.Debounce{...}`/`q.Throttle{...}`에 넘긴 옵션 자체가 테이블이 아닐 때(안 준 경우 포함).
- **고치려면**: 옵션 테이블을 넘기세요.
- **참고**: [`q.Debounce{...}`](../sugar/03-debounce-throttle.md#qdebounce)

### Quad0046

`Throttle: MaxTime is Debounce-only (a throttle already passes every Time)` — `quad-base/src/Debounce.luau`

- **언제**: `q.Throttle{...}`에 `MaxTime`을 줬을 때 — `Throttle`은 이미 매 `Time`마다 통과시키므로 `MaxTime` 개념이 없습니다.
- **고치려면**: `MaxTime`을 빼세요(그 옵션은 `Debounce`에서만 유효합니다).
- **참고**: [`q.Throttle{...}`](../sugar/03-debounce-throttle.md#qthrottle)

### Quad0047

`{name}: Handle must be a Ref (got {typeof(opts.Handle)})` — `quad-base/src/Debounce.luau`

- **언제**: `Handle` 옵션에 `Ref`가 아닌 값을 줬을 때.
- **고치려면**: `q.Ref<<QuadTypes.GateHandle?>>(nil)`을 넘기세요.
- **참고**: [제어 핸들(`GateHandle`)](../sugar/03-debounce-throttle.md#제어-핸들-gatehandle)

### Quad0048

`{name}: Leading and Trailing both false would pass nothing through` — `quad-base/src/Debounce.luau`

- **언제**: `Leading`과 `Trailing`을 둘 다 `false`로 줬을 때 — 그러면 아무 신호도 하류로 통과하지 못합니다.
- **고치려면**: 적어도 하나는 `true`로 두세요(둘 다 기본값을 건드리지 않는 것도 방법입니다).
- **참고**: [옵션](../sugar/03-debounce-throttle.md#옵션)

### Quad0118

`Operator.{name}: argument #{i} is nil` — `quad-base/src/Operator.luau`

- **언제**: `Sum`/`Product`/`Min`/`Max`/`Clamp`/`Band`/`Bor`/`Bxor`/`Shl`/`Shr` 같은 커링 콤비네이터를 만들 때 `i`번째 인자가 `nil`일 때 — 자리마다 검사하므로 조용히 사라져 뒤 인자를 당겨오지 않습니다. `{name}`은 실제로 부른 콤비네이터 이름입니다.
- **고치려면**: 그 자리에 실제 값(숫자나 `State<number>`)을 채우세요.
- **참고**: [공통 계약](../sugar/02-operator.md#공통-계약)

### Quad0119

`Operator.{name}: argument #{i} must be a {kind} or a State<{kind}> (got {typeof(a)})` — `quad-base/src/Operator.luau`

- **언제**: 커링 콤비네이터를 만드는 줄에서 `i`번째 인자가 기대하는 값 종류(`kind`, 보통 `number`)도 그 `State<kind>`도 아닐 때.
- **고치려면**: 숫자(또는 다른 콤비네이터가 요구하는 타입)나 그 타입의 `State`를 넘기세요.
- **참고**: [공통 계약](../sugar/02-operator.md#공통-계약)

### Quad0120

`Operator.{name}: argument #{i} is a State whose current value is nil` — `quad-base/src/Operator.luau`

- **언제**: 인자로 넘긴 `State`의 **현재값**을 읽는 시점(연산이 도는 시점)에 그 값이 `nil`일 때 — 갓 만든 `store:Of(...)`나 없는 키를 읽은 `Indexed` 등이 원인일 수 있습니다.
- **고치려면**: 그 `State`가 항상 값을 갖게 하거나(기본값), `Operator.Alternative`로 먼저 nil을 걷어내세요.
- **참고**: [공통 계약](../sugar/02-operator.md#공통-계약)

### Quad0121

`Operator.{name}: argument #{i} is a State whose current value must be a {kind} (got {typeof(v)})` — `quad-base/src/Operator.luau`

- **언제**: 인자로 넘긴 `State`의 현재값이 `nil`은 아니지만 기대하는 타입(`kind`)이 아닐 때.
- **고치려면**: 그 `State`가 항상 올바른 타입의 값을 내놓게 하세요.
- **참고**: [공통 계약](../sugar/02-operator.md#공통-계약)

### Quad0122

`Operator.{name}: the Apply target's current value must be a {kind} (got {typeof(v)})` — `quad-base/src/Operator.luau`

- **언제**: `state:Apply(factory)`의 대상 `State` 자신의 현재값을 읽는 시점에 그 값이 기대하는 타입(`kind`)이 아닐 때 — 인자와 마찬가지로 `:Apply`를 받는 State의 값도 검사합니다.
- **고치려면**: `:Apply`하는 State가 항상 올바른 타입의 값을 갖게 하세요.
- **참고**: [공통 계약](../sugar/02-operator.md#공통-계약)

### Quad0123

`Operator.{name}: Apply target must be a State (got {typeof(self)})` — `quad-base/src/Operator.luau`

- **언제**: `state:Apply(factory)`의 대상이 `State`가 아닐 때.
- **고치려면**: `State`에 `Apply`하세요.
- **참고**: [공통 계약](../sugar/02-operator.md#공통-계약)

### Quad0124

`Operator.Clamp: min must be <= max and neither NaN (got min {r[1]}, max {r[2]})` — `quad-base/src/Operator.luau`

- **언제**: `Operator.Clamp(lo, hi)`의 경계를 읽는 시점에 `lo > hi`이거나 둘 중 하나가 `NaN`(흔히 `0/0`)일 때 — 반응형 경계가 한 프레임 엇갈리는 경우도 포함됩니다.
- **고치려면**: 보통은 경계가 다음 세대에 돌아오면 회복됩니다. 계속 나면 `lo`/`hi`를 내놓는 State들의 관계를 확인하세요.
- **참고**: [`q.Operator.Clamp(lo, hi)`](../sugar/02-operator.md#qoperatorclamplo-hi)

### Quad0125

`Operator.Indexed: key must not be nil` — `quad-base/src/Operator.luau`

- **언제**: `Operator.Indexed<<V>>(key)`를 만드는 즉시 `key`가 `nil`일 때.
- **고치려면**: 실제 키 값을 넘기세요.
- **참고**: [`q.Operator.Indexed<<V>>(key)`](../sugar/02-operator.md#qoperatorindexedvkey)

### Quad0126

`Operator.Indexed: key must be a plain value, not a State (the key is not reactive)` — `quad-base/src/Operator.luau`

- **언제**: `key` 자리에 `State`를 넘겼을 때 — 다른 콤비네이터들이 전부 `T | State<T>`를 받으므로 자연스러운 실수지만, `Indexed`의 키는 반응형이 아니라 그렇게 넘기면 조용히 `t[<State 객체>]`(항상 nil)를 읽습니다.
- **고치려면**: 키에는 plain 값을 넘기세요.
- **참고**: [`q.Operator.Indexed<<V>>(key)`](../sugar/02-operator.md#qoperatorindexedvkey)

### Quad0127

`Operator.Indexed: value is not a table (got {typeof(t)}) — cannot read [{tostring(key)}]` — `quad-base/src/Operator.luau`

- **언제**: 읽는 시점에 `:Apply`한 State의 현재값이 테이블이 아닐 때.
- **고치려면**: `Indexed`를 붙인 State가 항상 테이블 값을 갖게 하세요.
- **참고**: [`q.Operator.Indexed<<V>>(key)`](../sugar/02-operator.md#qoperatorindexedvkey)

### Quad0128

`Operator.Alternative: default must not be nil` — `quad-base/src/Operator.luau`

- **언제**: `Operator.Alternative(default)`를 만드는 즉시 `default`가 `nil`일 때.
- **고치려면**: 기본값(plain 값이나 State)을 넘기세요.
- **참고**: [`q.Operator.Alternative(default)`](../sugar/02-operator.md#qoperatoralternativedefault)

### Quad0129

`Operator.Alternative: the default State's current value is nil` — `quad-base/src/Operator.luau`

- **언제**: `default`로 넘긴 `State`의 현재값이 `nil`일 때(예: 아직 안 채운 `store:Of`) — 기본값 자리에는 실제 값이 있어야 합니다.
- **고치려면**: 그 `State`가 항상 값을 갖게 하세요.
- **참고**: [`q.Operator.Alternative(default)`](../sugar/02-operator.md#qoperatoralternativedefault)
