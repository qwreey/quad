---
title: "에러 코드 — 모듈·백엔드 계약"
description: "UseProvider/플러그인/Brand/ModuleIdentity/미설치 op 스텁/Relate/Claim(base)이 던지는 에러"
---
# [레퍼런스] 에러 코드 — 모듈·백엔드 계약

각 절은 `### QuadNNNN` — 메시지 원문(자리표시자는 `{…}`), 언제 나는가, 어떻게 고치는가. 번호로 찾으려면 [색인](./00-index.md).


### Quad0026

`newMapperClass: className must be a non-empty string (got {typeof(className)})` — `quad-base/src/Claim.luau`

- **언제**: `q.newMapperClass(className)`에 넘긴 `className`이 문자열이 아니거나 빈 문자열일 때.
- **고치려면**: 클래스 이름을 비어 있지 않은 문자열로 주세요.
- **참고**: [`q.newMapperClass(className)`](../roblox/04-claim-mapper.md#qnewmapperclassclassname)

### Quad0027

`Claim: mapper descriptor was already used (descriptors are one-shot)` — `quad-base/src/Claim.luau`

- **언제**: 이미 한 번 `q.Claim`에 쓰인 디스크립터(1회용)를 다시 쓰려고 할 때.
- **고치려면**: 디스크립터 값을 저장해 재사용하지 말고, 필요하면 그것을 만드는 호출을 팩토리 함수로 감싸 매번 새로 만드세요.
- **참고**: [`q.Claim(inst, desc)`](../roblox/04-claim-mapper.md#qclaiminst-desc)

### Quad0028

`Claim: two mapper descriptors resolved to the same Instance {tostring(inst)} — each child needs exactly one descriptor` — `quad-base/src/Claim.luau`

- **언제**: 서로 다른 두 디스크립터가 해석 결과 같은 Instance를 가리켰을 때 — 한 자식에 매퍼가 두 번 걸린 경우입니다.
- **고치려면**: 자식마다 디스크립터를 하나씩만 두세요.
- **참고**: [`q.Claim(inst, desc)`](../roblox/04-claim-mapper.md#qclaiminst-desc)

### Quad0029

`Claim: {tostring(inst)} is already claimed by quad — a Declaration-made or already-Claimed Instance cannot be claimed again (leave it out of the descriptor and drive it separately, or dispose it and rebuild)` — `quad-base/src/Claim.luau`

- **언제**: 디스크립터가 해석한 Instance가 이미 quad에 의해 소유돼 있을 때 — `D.New`로 만들었거나 먼저 `Claim`된 것(루트도 자식도 해당)입니다.
- **고치려면**: 그 자식을 디스크립터에서 빼고 따로 다루거나, `q.dispose`한 뒤 새로 만드세요.
- **참고**: [`q.Claim(inst, desc)`](../roblox/04-claim-mapper.md#qclaiminst-desc)

### Quad0030

`Claim: mapper props must be a table (got {typeof(desc._props)})` — `quad-base/src/Claim.luau`

- **언제**: 디스크립터의 props가 테이블이 아닐 때.
- **고치려면**: props에 테이블을 넘기세요.
- **참고**: [`q.Claim(inst, desc)`](../roblox/04-claim-mapper.md#qclaiminst-desc)

### Quad0031

`Claim: array keys must be positive integers (got {i})` — `quad-base/src/Claim.luau`

- **언제**: 디스크립터 props의 숫자 키(다른 매퍼 디스크립터를 담은 자리) 중 양의 정수가 아닌 것이 있을 때.
- **고치려면**: 숫자 키는 1부터 시작하는 정수로 쓰세요.
- **참고**: [`q.Claim(inst, desc)`](../roblox/04-claim-mapper.md#qclaiminst-desc)

### Quad0032

`Claim: no child matched key {tostring(v._key)} under {tostring(inst)} (mapper {tostring(v._className)}) — a child with that name must also be a {tostring(v._className)}` — `quad-base/src/Claim.luau`

- **언제**: 매퍼 디스크립터가 지목한 이름의 자식이 없거나, 이름은 맞는데 그 클래스(`IsA`)가 아닐 때.
- **고치려면**: 템플릿(claim 대상 Instance)에 그 이름·클래스의 자식이 실제로 있는지 확인하세요.
- **참고**: [`q.Claim(inst, desc)`](../roblox/04-claim-mapper.md#qclaiminst-desc)

### Quad0033

`Claim: first argument must be an Instance of the installed backend (got {typeof(inst)})` — `quad-base/src/Claim.luau`

- **언제**: `q.Claim(inst, desc)`의 첫 인자가 설치된 백엔드의 Instance가 아닐 때.
- **고치려면**: 실제 Instance를 넘기세요.
- **참고**: [`q.Claim(inst, desc)`](../roblox/04-claim-mapper.md#qclaiminst-desc)

### Quad0034

`Claim: second argument must be a D.Mapper descriptor` — `quad-base/src/Claim.luau`

- **언제**: `q.Claim(inst, desc)`의 둘째 인자가 `D.Mapper` 디스크립터가 아닐 때.
- **고치려면**: `D.Mapper.<Class>(key)(props)`(또는 `q.newMapperClass`)로 만든 디스크립터를 넘기세요.
- **참고**: [`q.Claim(inst, desc)`](../roblox/04-claim-mapper.md#qclaiminst-desc)

### Quad0102

`bindLifetime: inst must not be nil` — `quad-base/src/LifetimeHandle.luau`

- **언제**: `q.Backend.bindLifetime(inst, value)`의 `inst`가 `nil`일 때 — 값을 묶으려면 살아 있는 요소가 있어야 합니다.
- **고치려면**: 실제 요소(Instance 등)를 넘기세요.
- **참고**: [`q.Backend.bindLifetime(inst, value)`](../core/10-lifetime-sentinels.md#qbackendbindlifetimeinst-value)

### Quad0103

`bindLifetime: value must not be nil` — `quad-base/src/LifetimeHandle.luau`

- **언제**: `q.Backend.bindLifetime(inst, value)`의 `value`가 `nil`일 때.
- **고치려면**: 실제로 묶을 값(Observer/Effect/Ref/Slot 등)을 넘기세요.
- **참고**: [`q.Backend.bindLifetime(inst, value)`](../core/10-lifetime-sentinels.md#qbackendbindlifetimeinst-value)

### Quad0104

`bindLifetime: value is already subscribed` — `quad-base/src/LifetimeHandle.luau`

- **언제**: 이미 전역 구독(`:Subscribe()`/`:WeakSubscribe()`)으로 살아 있는 `Observer`/`Effect`를 다시 어떤 요소의 자리에 묶으려 할 때 — 전역 구독과 자리 바인딩은 겹칠 수 없습니다.
- **고치려면**: 구독 중인 핸들은 그대로 두거나, 새 핸들을 만들어 자리에 놓으세요.
- **참고**: [`q.Backend.bindLifetime(inst, value)`](../core/10-lifetime-sentinels.md#qbackendbindlifetimeinst-value)

### Quad0105

`unbindLifetime: value must not be nil` — `quad-base/src/LifetimeHandle.luau`

- **언제**: `q.Backend.unbindLifetime(value)`에 `nil`을 넘겼을 때 — 묶여 있지 않은 값은 no-op이지만, `nil`은 애초에 값이 아니라 인자 누락으로 취급합니다.
- **고치려면**: 실제로 풀려는 값을 넘기세요.
- **참고**: [`q.Backend.unbindLifetime(value)`](../core/10-lifetime-sentinels.md#qbackendunbindlifetimevalue)

### Quad0106

`{what}: this value was made by another quad module instance (a second quad_base copy, or q.New()) — values cannot cross instances` — `quad-base/src/ModuleIdentity.luau`

- **언제**: 한 quad 모듈 인스턴스가 만든 Observer·Effect·Slot·State를 다른 인스턴스의 트리 자리(숫자 키, 프로퍼티 값, `:List`의 데이터, `Slot`의 원소 자리 등)에 놓았을 때. `{what}`은 그 값이 놓인 자리를 가리키는 이름(`"Observer"`/`"Slot"` 등)입니다.
- **고치려면**: 값을 만든 인스턴스와 놓는 인스턴스를 같게 맞추세요 — 여러 `quad-base` 사본이 섞이지 않았는지도 확인하세요.
- **참고**: [`q.New()`](../core/01-quad-module.md#qnew)

### Quad0108

`quad: {name} is not available — no backend has installed {what} (install a provider with quad:UseProvider — a bare Quad.New() has none{hint or ""})` — `quad-base/src/NotInstalled.luau`

- **언제**: 프로바이더를 설치하지 않은 `Quad.New()`에서 백엔드가 채워야 할 op(생명주기 hold op, 엔진 op, 시간 op 등)를 부를 때 — `{name}`은 그 op 이름입니다.
- **고치려면**: `quad:UseProvider(...)`로 백엔드를 설치하세요. 테스트에서는 `mock.installLifetime` 등을 쓰세요.
- **참고**: [`q.Backend.bindLifetime(inst, value)`](../core/10-lifetime-sentinels.md#qbackendbindlifetimeinst-value)

### Quad0138

`Relate:{method}: inst must not be nil` — `quad-base/src/Relate.luau`

- **언제**: `q.Relate()`가 돌려준 릴레이션의 `SetStrong`/`GetStrong`/`SetWeak`/`GetWeak` 중 하나를 부를 때 `inst` 자리에 `nil`을 넘겼을 때. `{method}`는 실제로 부른 메소드 이름입니다.
- **고치려면**: 실제 요소를 `inst` 자리에 넘기세요.
- **참고**: [`q.Relate()`](../core/01-quad-module.md#qrelate)

### Quad0139

`Relate:{method}: key must not be nil` — `quad-base/src/Relate.luau`

- **언제**: 같은 네 메소드 중 하나를 부를 때 `key` 자리에 `nil`을 넘겼을 때.
- **고치려면**: 실제 키 값을 넘기세요.
- **참고**: [`q.Relate()`](../core/01-quad-module.md#qrelate)

### Quad0232

`bindLifetime: value is already bound to this Instance (the same handle at two positions?)` — `quad-base/src/LifetimeHandle.luau`

- **언제**: 이미 어떤 요소의 자리에 묶여 있는 값을 **같은** 요소의 다른 자리에 또 묶으려 할 때 — 같은 핸들을 한 인스턴스 안 두 자리(`D.Frame { eff, eff }` 등)에 놓은 경우입니다.
- **고치려면**: 새 핸들을 만들어 두 번째 자리에 놓으세요 — 하나의 핸들은 한 자리에만 묶일 수 있습니다.
- **참고**: [`q.Backend.bindLifetime(inst, value)`](../core/10-lifetime-sentinels.md#qbackendbindlifetimeinst-value)

### Quad0233

`bindLifetime: value is already bound to another Instance` — `quad-base/src/LifetimeHandle.luau`

- **언제**: 이미 다른 요소의 자리에 묶여 있는 값을 또 다른 요소의 자리에 묶으려 할 때.
- **고치려면**: 새 핸들을 만들어 놓으세요 — 하나의 핸들은 한 요소에만 묶일 수 있습니다.
- **참고**: [`q.Backend.bindLifetime(inst, value)`](../core/10-lifetime-sentinels.md#qbackendbindlifetimeinst-value)

### Quad0208

`Quad:RunInit: initFn must be a function (got {typeof(initFn)})` — `quad-base/src/init.luau`

- **언제**: `q:RunInit(initFn)`의 `initFn` 자리가 함수가 아닐 때.
- **고치려면**: `(module) -> any` 모양의 함수를 넘기세요.
- **참고**: [`q:RunInit(initFn)`](../core/01-quad-module.md#qruninitinitfn)

### Quad0209

`{who}: the function must return its extension table (got {typeof(extension)} — return an empty table if it adds nothing)` — `quad-base/src/init.luau`

- **언제**: `{who}`은 부른 자리 이름입니다 — `q:UseProvider(providerFn)`이 부른 `providerFn(self)`가 테이블을 반환하지 않았을 때(`q:AddPlugin`은 자기 자리에서 먼저 검사하므로 이 문은 사실상 `UseProvider` 경로에서만 닿습니다).
- **고치려면**: 확장 테이블을 반환하세요 — 아무것도 추가하지 않는다면 빈 테이블 `{}`을 반환하세요.
- **참고**: [`q:UseProvider(providerFn)`](../core/01-quad-module.md#quseproviderproviderfn)

### Quad0210

`AddPlugin: plugin must be a function (got {typeof(pluginFn)})` — `quad-base/src/init.luau`

- **언제**: `q:AddPlugin(pluginFn)`의 `pluginFn` 자리가 함수가 아닐 때.
- **고치려면**: `(module) -> extension` 모양의 함수를 넘기세요.
- **참고**: [`q:AddPlugin(pluginFn)`](../core/01-quad-module.md#qaddpluginpluginfn)

### Quad0211

`AddPlugin: the function must return its extension table (got {typeof(extension)} — return an empty table if it adds nothing)` — `quad-base/src/init.luau`

- **언제**: `pluginFn(self)`가 테이블을 반환하지 않았을 때 — 모듈을 고쳐 쓰기만 하고 아무것도 반환하지 않는 플러그인이 흔한 실수입니다.
- **고치려면**: 확장 테이블을 반환하세요 — 아무것도 추가하지 않는다면 빈 테이블 `{}`을 반환하세요.
- **참고**: [`q:AddPlugin(pluginFn)`](../core/01-quad-module.md#qaddpluginpluginfn)

### Quad0212

`UseProvider: provider must be a function (got {typeof(providerFn)})` — `quad-base/src/init.luau`

- **언제**: `q:UseProvider(providerFn)`의 `providerFn` 자리가 함수가 아닐 때(`UseProvider(nil)`은 전에 조용히 통과했습니다).
- **고치려면**: `(module) -> extension` 모양의 함수를 넘기세요.
- **참고**: [`q:UseProvider(providerFn)`](../core/01-quad-module.md#quseproviderproviderfn)

### Quad0213

`UseProvider: this Quad module already has a provider — a module cannot serve two backends` — `quad-base/src/init.luau`

- **언제**: 이미 다른 프로바이더 함수(identity 기준)로 `UseProvider`를 부른 모듈에 다시 (다른) `providerFn`으로 `UseProvider`를 부를 때 — 같은 함수를 다시 넘기는 것은 멱등 no-op이라 에러가 아닙니다.
- **고치려면**: 모듈당 프로바이더는 하나입니다 — 새 모듈 인스턴스(`q.New()`)를 만들어 다른 백엔드를 설치하세요.
- **참고**: [`q:UseProvider(providerFn)`](../core/01-quad-module.md#quseproviderproviderfn)
