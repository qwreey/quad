---
title: "에러 코드 — Roblox: Declaration·Claim·핸들러"
description: "D.*/Mapper/Claim/Property/Event/OnChange/Out/숏핸드가 던지는 에러"
---
# [레퍼런스] 에러 코드 — Roblox: Declaration·Claim·핸들러

각 절은 `### QuadNNNN` — 메시지 원문(자리표시자는 `{…}`), 언제 나는가, 어떻게 고치는가. 번호로 찾으려면 [색인](./00-index.md).


### Quad0215

`setTimeout: func must be a function (got {typeof(func)})` — `quad-roblox/src/EngineOps.luau`

- **언제**: 백엔드가 심는 시간 op `setTimeout(func, delay)`의 `func` 자리가 함수가 아닐 때(`Debounce`/`Throttle`이 내부에서 이 op를 씁니다).
- **고치려면**: 함수를 넘기세요.
- **참고**: [`extend/01-backend-provider-contract`](../extend/01-backend-provider-contract.md) — "5. 메타데이터 op와 시간 op"

### Quad0216

`setTimeout: delay must be a non-negative number (got {typeof(delay)})` — `quad-roblox/src/EngineOps.luau`

- **언제**: `setTimeout(func, delay)`의 `delay`가 숫자가 아니거나, NaN이거나, 음수일 때.
- **고치려면**: 0 이상의 숫자를 넘기세요.
- **참고**: [`extend/01-backend-provider-contract`](../extend/01-backend-provider-contract.md) — "5. 메타데이터 op와 시간 op"

### Quad0217

`clearTimeout: expected a Timeout from setTimeout (got {typeof(timeout)})` — `quad-roblox/src/EngineOps.luau`

- **언제**: `clearTimeout(timeout)`에 `setTimeout`이 돌려준 `Timeout` 핸들이 아닌 값을 넘겼을 때 — 마커 필드(`__quadTimeout`)로 신원을 확인합니다.
- **고치려면**: `setTimeout`이 돌려준 값을 그대로 넘기세요.
- **참고**: [`extend/01-backend-provider-contract`](../extend/01-backend-provider-contract.md) — "5. 메타데이터 op와 시간 op"

### Quad0218

`Event: handler for "{k}" must be a function (got {typeof(v)})` — `quad-roblox/src/Handlers/Event.luau`

- **언제**: `D.<Class> { EventName = v }`에서 이벤트 이름 키의 값 `v`가 함수도, `None`/`nil`(연결 해제 전용)도 아닐 때.
- **고치려면**: 콜백 함수나 `q.None`/`nil`을 넘기세요.
- **참고**: [D — 문자 키](../roblox/02-d.md#문자-키--프로퍼티와-이벤트)

### Quad0219

`InstanceChild: this Instance is not claimed by quad — build it with the Declaration or take it over with Claim first (an Instance made by another quad module instance also counts as not claimed here, and so does a destroyed one — a destroyed Instance cannot be reused)` — `quad-roblox/src/Handlers/InstanceChild.luau`

- **언제**: 숫자 키 자리에 quad가 소유하지 않은 Instance(`Instance.new`나 다른 라이브러리가 만든 것, 다른 quad 모듈 인스턴스가 만든 것, 또는 이미 파괴된 것)를 놓았을 때.
- **고치려면**: `D.<Class> { ... }`로 만들었거나 [`Claim`](../roblox/04-claim-mapper.md#qclaiminst-desc)으로 넘겨받은 Instance만 자식 자리에 놓으세요.
- **참고**: [D — 숫자 키](../roblox/02-d.md#숫자-키--자식과-디스크립터)

### Quad0220

`InstanceChild: cannot place an Instance inside itself or one of its own descendants (that would be a cycle)` — `quad-roblox/src/Handlers/InstanceChild.luau`

- **언제**: 어떤 Instance를 자기 자신이나 자기 조상의 숫자 키 자리에 자식으로 놓으려 할 때 — 조상 사슬을 따라 올라가며 검사합니다.
- **고치려면**: 순환이 생기지 않게 트리 구조를 바꾸세요.
- **참고**: [D — 숫자 키](../roblox/02-d.md#숫자-키--자식과-디스크립터)

### Quad0221

`OnChange: property name must be a non-empty string` — `quad-roblox/src/Handlers/OnChange.luau`

- **언제**: `q.OnChange(name, fn)`의 `name`이 문자열이 아니거나 빈 문자열일 때.
- **고치려면**: 비어 있지 않은 프로퍼티 이름 문자열을 넘기세요.
- **참고**: [`q.OnChange(name, fn)`](../roblox/05-onchange.md#qonchangename-fn)

### Quad0222

`OnChange: callback for "{name}" must be a function (got {typeof(fn)})` — `quad-roblox/src/Handlers/OnChange.luau`

- **언제**: `q.OnChange(name, fn)`의 `fn`이 함수가 아닐 때.
- **고치려면**: `(newValue) -> ()` 모양의 함수를 넘기세요.
- **참고**: [`q.OnChange(name, fn)`](../roblox/05-onchange.md#qonchangename-fn)

### Quad0223

`Out: property name must be a non-empty string` — `quad-roblox/src/Handlers/OnChange.luau`

- **언제**: `q.Out(name, src)`의 `name`이 문자열이 아니거나 빈 문자열일 때.
- **고치려면**: 비어 있지 않은 프로퍼티 이름 문자열을 넘기세요.
- **참고**: [`q.Out(name, src)`](../roblox/05-onchange.md#qoutname-src)

### Quad0224

`Out: second argument for "{name}" must be a Source to write back into (got {got})` — `quad-roblox/src/Handlers/OnChange.luau`

- **언제**: `q.Out(name, src)`의 `src`가 `Source`가 아닐 때 — `:Compute` 결과 같은 읽기 전용 `State`는 `Set`이 없어 `{got}`가 `"a read-only State (a :Compute result?)"`로 나옵니다.
- **고치려면**: `Source`를 넘기세요.
- **참고**: [`q.Out(name, src)`](../roblox/05-onchange.md#qoutname-src)

### Quad0225

`nativeClaim: Instance is already claimed by quad` — `quad-roblox/src/LifetimeHandle.luau`

- **언제**: 같은 Instance를 `nativeClaim`으로 두 번 claim할 때 — 같은 인스턴스가 `Claim`에 두 번 걸리거나, `New`가 만든 인스턴스를 다시 claim하려 할 때입니다.
- **고치려면**: 이미 quad 소유인 Instance를 다시 claim하지 마세요.
- **참고**: [`extend/01-backend-provider-contract`](../extend/01-backend-provider-contract.md) — "3. 판정·훅·조회 op"

### Quad0226

`bindLifetime: Instance is not claimed by quad — it was not created or claimed through quad, or it has already been destroyed (a destroyed Instance cannot be reused)` — `quad-roblox/src/LifetimeHandle.luau`

- **언제**: `q.Backend.bindLifetime(inst, value)`의 `inst`가 이 백엔드의 quad 소유 요소가 아닐 때(quad 밖에서 만들어졌거나, 이미 파괴됐을 때).
- **고치려면**: quad가 만들었거나 `Claim`으로 넘겨받은, 아직 살아 있는 Instance에만 값을 묶으세요.
- **참고**: [`q.Backend.bindLifetime(inst, value)`](../core/10-lifetime-sentinels.md#qbackendbindlifetimeinst-value)

### Quad0228

`quad-roblox: requires a quad-base matching version pattern '{VERSION_PATTERN}' (got '{tostring(q.Version)}')` — `quad-roblox/src/init.luau`

- **언제**: `q:UseProvider(QuadRoblox)`에 넘긴 `quad-base` 모듈의 `Version`이 이 quad-roblox 사본이 요구하는 버전 패턴과 맞지 않을 때(`{VERSION_PATTERN}`은 이 패키지에 박힌 상수, `{tostring(q.Version)}`은 넘어온 모듈의 실제 버전).
- **고치려면**: quad-base와 quad-roblox의 버전을 맞추세요(같은 메이저, 요구 마이너 이상).
- **참고**: [`QuadRoblox`](../roblox/01-install.md#quadroblox)
