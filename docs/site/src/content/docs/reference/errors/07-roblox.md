---
title: "에러 코드 — Roblox: Elem·Claim·핸들러"
description: "D.*/Mapper/Claim/Property/Event/OnChange/Out/숏핸드가 던지는 에러"
---
각 절은 `### QuadNNNN` — 메시지 원문(자리표시자는 `{…}`), 언제 나는가, 어떻게 고치는가. 번호로 찾으려면 [색인](/reference/errors/00-index/).


### Quad0215

`setTimeout: func must be a function (got {typeof(func)})` — `quad-roblox/src/EngineOps.luau`

- **언제**: 백엔드가 심는 시간 op `setTimeout(func, delay)`의 `func` 자리가 함수가 아닐 때(`Debounce`/`Throttle`이 내부에서 이 op를 씁니다).
- **고치려면**: 함수를 넘기세요.
- **참고**: [`extend/01-backend-provider-contract`](/reference/extend/01-backend-provider-contract/) — "5. 메타데이터 op와 시간 op"

### Quad0216

`setTimeout: delay must be a non-negative number (got {if type(delay) == "number" then tostring(delay) else typeof(delay)})` — `quad-roblox/src/EngineOps.luau`

- **언제**: `setTimeout(func, delay)`의 `delay`가 숫자가 아니거나, NaN이거나, 음수일 때.
- **고치려면**: 0 이상의 숫자를 넘기세요.
- **참고**: [`extend/01-backend-provider-contract`](/reference/extend/01-backend-provider-contract/) — "5. 메타데이터 op와 시간 op"

### Quad0217

`clearTimeout: timeout must be a Timeout from setTimeout (got {typeof(timeout)})` — `quad-roblox/src/EngineOps.luau`

- **언제**: `clearTimeout(timeout)`에 `setTimeout`이 돌려준 `Timeout` 핸들이 아닌 값을 넘겼을 때 — 마커 필드(`__quadTimeout`)로 신원을 확인합니다.
- **고치려면**: `setTimeout`이 돌려준 값을 그대로 넘기세요.
- **참고**: [`extend/01-backend-provider-contract`](/reference/extend/01-backend-provider-contract/) — "5. 메타데이터 op와 시간 op"

### Quad0218

`Event: handler for "{k}" must be a function (got {typeof(v)})` — `quad-roblox/src/Handlers/Event.luau`

- **언제**: `D.<Class> { EventName = v }`에서 이벤트 이름 키의 값 `v`가 함수도, `None`/`nil`(연결 해제 전용)도 아닐 때.
- **고치려면**: 콜백 함수나 `q.None`/`nil`을 넘기세요.
- **참고**: [Elem — 문자 키](/reference/roblox/02-elem/#문자-키--프로퍼티와-이벤트)

### Quad0219

`Dispatch: this Instance is not claimed by quad - build it with q.Elem or take it over with Claim first (an Instance made by another quad module instance also counts as not claimed here, and so does a destroyed one - a destroyed Instance cannot be reused)` — `quad-roblox/src/Handlers/InstanceChild.luau`

- **언제**: 숫자 키 자리에 quad가 소유하지 않은 Instance(`Instance.new`나 다른 라이브러리가 만든 것, 다른 quad 모듈 인스턴스가 만든 것, 또는 이미 파괴된 것)를 놓았을 때.
- **고치려면**: `D.<Class> { ... }`로 만들었거나 [`Claim`](/reference/roblox/04-claim-mapper/#qclaiminst-desc)으로 넘겨받은 Instance만 자식 자리에 놓으세요.
- **참고**: [Elem — 숫자 키](/reference/roblox/02-elem/#숫자-키--자식과-디스크립터)

### Quad0220

`Dispatch: cannot place an Instance inside itself or one of its own descendants (that would be a cycle)` — `quad-roblox/src/Handlers/InstanceChild.luau`

- **언제**: [`q.debug`](/reference/core/01-quad-module/#qdebug)가 켜져 있을 때, 어떤 Instance를 자기 자신이나 자기 자손의 숫자 키 자리에 자식으로 놓으려 할 때 — 놓이는 자리의 Instance에서 조상 사슬을 따라 올라가며 그 Instance를 만나는지 검사합니다. **(3.3.0부터)** 조상 사슬 걷기라 debug 층으로 내려갔습니다 — 꺼 두면 Roblox 엔진의 `… would result in circular reference` 에러가 대신 멈춥니다. 다만 그 에러는 quad가 자리를 잡은 **뒤**에 나므로, 그 요소의 부기는 그 뒤로 믿을 수 없습니다(던진 뒤의 무결은 약속하지 않습니다).
- **고치려면**: 순환이 생기지 않게 트리 구조를 바꾸세요.
- **참고**: [Elem — 숫자 키](/reference/roblox/02-elem/#숫자-키--자식과-디스크립터)

### Quad0221

`OnChange: property name must be a non-empty string` — `quad-roblox/src/Handlers/OnChange.luau`

- **언제**: `q.OnChange "Class" "Name" (fn)`의 이름 자리(`"Name"`)가 문자열이 아니거나 빈 문자열일 때.
- **고치려면**: 비어 있지 않은 프로퍼티 이름 문자열을 넘기세요.
- **참고**: [`q.OnChange "Class" "Name" (fn)`](/reference/roblox/05-onchange/#qonchange-class-name-fn)

### Quad0222

`OnChange: callback for "{name}" must be a function (got {typeof(fn)})` — `quad-roblox/src/Handlers/OnChange.luau`

- **언제**: `q.OnChange "Class" "Name" (fn)`의 `fn`이 함수가 아닐 때.
- **고치려면**: `(newValue) -> ()` 모양의 함수를 넘기세요.
- **참고**: [`q.OnChange "Class" "Name" (fn)`](/reference/roblox/05-onchange/#qonchange-class-name-fn)

### Quad0223

`Out: property name must be a non-empty string` — `quad-roblox/src/Handlers/OnChange.luau`

- **언제**: `q.Out "Class" "Name" (src)`의 이름 자리(`"Name"`)가 문자열이 아니거나 빈 문자열일 때.
- **고치려면**: 비어 있지 않은 프로퍼티 이름 문자열을 넘기세요.
- **참고**: [`q.Out "Class" "Name" (src)`](/reference/roblox/05-onchange/#qout-class-name-src)

### Quad0224

`Out: "{name}" needs a Source to write back into (got {got})` — `quad-roblox/src/Handlers/OnChange.luau`

- **언제**: `q.Out "Class" "Name" (src)`의 `src`가 `Source`가 아닐 때 — `:Compute` 결과 같은 읽기 전용 `State`는 `Set`이 없어 `{got}`가 `"a read-only State (a :Compute result?)"`로 나옵니다.
- **고치려면**: `Source`를 넘기세요.
- **참고**: [`q.Out "Class" "Name" (src)`](/reference/roblox/05-onchange/#qout-class-name-src)

### Quad0225

`nativeClaim: Instance is already claimed by quad` — `quad-roblox/src/LifetimeHandle.luau`

- **언제**: 같은 Instance를 `nativeClaim`으로 두 번 claim할 때. 공개 경로(`q.Claim`을 두 번, `New`가 만든 인스턴스를 claim)는 `Claim`의 1패스가 `isClaimed`로 먼저 걸러 `Quad0029`를 내므로, 이 에러는 백엔드 op를 직접 부르거나 파괴된 인스턴스를 GC 전에 다시 claim하는 정의되지 않은 경로에서만 봅니다.
- **고치려면**: 이미 quad 소유인 Instance를 다시 claim하지 마세요.
- **참고**: [`extend/01-backend-provider-contract`](/reference/extend/01-backend-provider-contract/) — "3. 판정·훅·조회 op"

### Quad0226

`bindLifetime: this Instance is not claimed by quad - it was not created or claimed through quad, or it has already been destroyed (a destroyed Instance cannot be reused)` — `quad-roblox/src/LifetimeHandle.luau`

`inst`가 Instance가 아니면(평범한 테이블·문자열 키) 이유 절이 `owner must be an Instance claimed by quad (got {typeof(inst)})`로 바뀝니다.

- **언제**: `q.Backend.bindLifetime(inst, value)`의 `inst`가 이 백엔드의 quad 소유 요소가 아닐 때(quad 밖에서 만들어졌거나, 이미 파괴됐을 때). 직접 부르지 않아도 닿습니다 — `q.Dispatch.process`로 quad가 만들지도 `Claim`하지도 않은 Instance의 자리에 `Effect`처럼 수명에 묶이는 값을 놓거나, `q.Backend.holdLifetime`을 그런 Instance에 직접 부르면 같은 메시지가 납니다(메시지는 부르지 않은 `bindLifetime`을 말합니다). [`q.Bookkeeping.setLength`](/reference/extend/02-dispatch-handler-contract/#qbookkeepingsetlengthownerkey-i-len-anchor-element)에 State 길이를 넘기며 `anchor`를 생략했는데 `ownerKey`가 Slot이면 Instance가 아닌 키로 묶으려다 이 에러(`owner must be …` 꼴)가 납니다.
- **고치려면**: quad가 만들었거나 `Claim`으로 넘겨받은, 아직 살아 있는 Instance에만 값을 놓거나 묶으세요 — 밖에서 만든 Instance는 먼저 `q.Claim`으로 넘겨받으세요. `setLength`라면 `ownerKey`가 Slot일 때 `anchor`에 그 Slot이 붙은 물리 Instance를 넘기세요.
- **참고**: [`q.Backend.bindLifetime(inst, value)`](/reference/core/10-lifetime-sentinels/#qbackendbindlifetimeinst-value)

### Quad0228

`quad-roblox: requires a quad-base matching version pattern '{VERSION_PATTERN}' (got '{tostring(q.Version)}')` — `quad-roblox/src/init.luau`

- **언제**: `q:UseProvider(QuadRoblox)`에 넘긴 `quad-base` 모듈의 `Version`이 이 quad-roblox 사본이 요구하는 버전 패턴과 맞지 않을 때(`{VERSION_PATTERN}`은 이 패키지에 박힌 상수, `{tostring(q.Version)}`은 넘어온 모듈의 실제 버전).
- **고치려면**: quad-base와 quad-roblox의 버전을 맞추세요 — 저장소 현재 패턴 `"3.3^.0^"` 기준으로 같은 메이저에서 3.3.0 이상의 **릴리즈** 빌드(하한은 bump마다 패치까지 올라갑니다). quad-base가 프리릴리즈(`3.4.0-rc.1`)면 꼬리 유무가 달라 이 조건을 만족해도 막히니, 그 rc를 정확히 적은 quad-roblox 빌드를 쓰세요([설치](/reference/roblox/01-install/#quadroblox)의 문법).
- **참고**: [`QuadRoblox`](/reference/roblox/01-install/#quadroblox)

### Quad0278

`{fn}: the first argument must be a class name string (got {typeof(name)})` — `quad-roblox/src/Surface/Runtime.luau`

- **언제**: 클래스를 먼저 받는 생성자(`q.Elem`·`q.Modifier`·`q.Spread`·`q.Mapper`·`q.OnChange`·`q.OnEvent`·`q.Out`, `q.ForClasses`가 돌려주는 같은 이름들)의 첫 인자가 문자열이 아니거나 빈 문자열일 때. `{fn}`은 그 생성자 이름입니다. 런타임은 문자열인지만 봅니다 — 없는 클래스 이름은 타입 검사가 먼저 잡고, 런타임에선 엔진이 그 클래스를 만나는 자리(`Instance.new`, 시그널 조회)에서 엔진 에러가 납니다.
- **고치려면**: 클래스 이름 문자열을 먼저 넘기세요(`q.Elem "Frame" { … }`).

### Quad0279

`OnEvent: event name must be a non-empty string` — `quad-roblox/src/Handlers/OnEvent.luau`

- **언제**: `q.OnEvent "Frame" (name)`의 이벤트 이름이 문자열이 아니거나 빈 문자열일 때.
- **고치려면**: 비어 있지 않은 이벤트 이름 문자열을 넘기세요(`q.OnEvent "Frame" "MouseEnter" (fn)`).

### Quad0280

`OnEvent: callback for "{name}" must be a function (got {typeof(fn)})` — `quad-roblox/src/Handlers/OnEvent.luau`

- **언제**: `q.OnEvent "Frame" "MouseEnter" (fn)`의 `fn`이 함수가 아닐 때.
- **고치려면**: 그 이벤트의 인자를 받는 함수를 넘기세요.

### Quad0281

`{fn}: each stage takes one argument - write q.{fn} "Class" "Name" (…) (3.3's q.{fn}(name, …) form is gone)` — `quad-roblox/src/Surface/Runtime.luau`

- **언제**: `q.OnChange`·`q.Out`·`q.OnEvent`의 클래스 단계나 이름 단계에 인자를 둘 이상 넘겼을 때 — 흔히 3.3의 `q.OnChange("Text", fn)`을 그대로 둔 코드이거나, 손으로 옮기다 클래스만 앞에 붙인 `q.OnChange "TextLabel" ("Text", fn)`입니다. 앞의 꼴은 `"Text"`를 클래스 이름으로 받아 단계 함수를 돌려주고 뒤의 꼴은 콜백을 버리므로, 막지 않으면 그 함수가 요소에 놓여 한참 뒤 Dispatch에서 엉뚱한 에러가 납니다.
- **고치려면**: 클래스 → 이름 → 콜백 순서로 따로 부르세요(`q.OnChange "TextLabel" "Text" (fn)`). 옮기기는 `scripts/migrate-3.4.py`가 해 줍니다.
