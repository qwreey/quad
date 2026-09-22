---
title: "에러 코드 — Ref·Observer·Effect·훅"
description: "Ref/PreRef/PostRef/Observer/Effect/생명주기 훅/bindLifetime이 던지는 에러"
---
각 절은 `### QuadNNNN` — 메시지 원문(자리표시자는 `{…}`), 언제 나는가, 어떻게 고치는가. 번호로 찾으려면 [색인](/reference/errors/00-index/).


### Quad0086

`Effect: fn must return a cleanup function or nothing (got {typeof(cleanup)})` — `quad-base/src/Effect.luau`

- **언제**: `q.Effect(fn, ...)`의 `fn`이 함수도 `nil`도 아닌 값(숫자, 연결 객체 등)을 돌려줬을 때 — cleanup 자리는 함수 하나뿐입니다.
- **고치려면**: 정리할 게 있으면 함수로 감싸 돌려주세요 — 연결 객체는 `return function() conn:Disconnect() end`처럼 감싸세요. 여럿이면 한 클로저로 묶으세요.
- **참고**: [`q.Effect(fn, ...deps)`](/reference/core/05-observer-effect/#qeffectfn-deps)

### Quad0087

`Effect: cannot bind an Effect from inside its own fn or cleanup` — `quad-base/src/Effect.luau`

- **언제**: `fn`이나 cleanup 안에서 새로 만든 `Effect`를 그 자리(props의 숫자 키)에 놓아 바인딩하려 할 때.
- **고치려면**: 새 핸들은 다음 렌더/실행에서 놓으세요 — `fn`/cleanup 실행 중에는 자기 자신도, 새로 만든 핸들도 그 자리에서 바인딩할 수 없습니다.
- **참고**: [`q.Effect(fn, ...deps)`](/reference/core/05-observer-effect/#qeffectfn-deps)

### Quad0088

`Effect: cannot change subscription from inside fn or cleanup` — `quad-base/src/Effect.luau`

- **언제**: `effect:WeakSubscribe()`를 그 `Effect` 자신의 `fn`이나 cleanup 실행 중에 부를 때.
- **고치려면**: 구독/재구독은 `fn`·cleanup 밖에서 하세요. 해제(`:Unsubscribe()`/`:WeakUnsubscribe()`)는 그 안에서도 됩니다.
- **참고**: [`effect:WeakSubscribe()`](/reference/core/05-observer-effect/#effectweaksubscribe)

### Quad0089

`Effect: already subscribed` — `quad-base/src/Effect.luau`

- **언제**: `effect:WeakSubscribe()`를 부를 때 이미 강하게(`:Subscribe()`) 구독돼 있어서 약한 구독으로 바꿀 수 없을 때.
- **고치려면**: 이미 구독 중인 핸들은 그대로 두거나, 새 `Effect`를 만드세요.
- **참고**: [`effect:WeakSubscribe()`](/reference/core/05-observer-effect/#effectweaksubscribe)

### Quad0230

`Effect: already bound to an Instance` — `quad-base/src/Effect.luau`

- **언제**: `effect:WeakSubscribe()`를 부를 때 이미 어떤 인스턴스의 props 자리에 묶여 있어서(전역 구독과 자리 바인딩은 겹칠 수 없음) 전역 구독으로 바꿀 수 없을 때.
- **고치려면**: 자리에 묶인 핸들은 그대로 두거나, 전역 구독이 필요하면 새 `Effect`를 만들어 처음부터 `:Subscribe()`/`:WeakSubscribe()`로 쓰세요.
- **참고**: [`effect:WeakSubscribe()`](/reference/core/05-observer-effect/#effectweaksubscribe)

### Quad0090

`Effect: cannot change subscription from inside fn or cleanup` — `quad-base/src/Effect.luau`

- **언제**: `effect:Subscribe()`를 그 `Effect` 자신의 `fn`이나 cleanup 실행 중에 부를 때.
- **고치려면**: 구독/재구독은 `fn`·cleanup 밖에서 하세요. 해제는 그 안에서도 됩니다.
- **참고**: [`effect:Subscribe()`](/reference/core/05-observer-effect/#effectsubscribe)

### Quad0091

`Effect: already subscribed` — `quad-base/src/Effect.luau`

- **언제**: `effect:Subscribe()`를 부를 때 이미 강하게 구독돼 있을 때(중복 `:Subscribe()`).
- **고치려면**: 이미 구독 중이면 다시 부르지 마세요.
- **참고**: [`effect:Subscribe()`](/reference/core/05-observer-effect/#effectsubscribe)

### Quad0231

`Effect: already bound to an Instance` — `quad-base/src/Effect.luau`

- **언제**: `effect:Subscribe()`를 부를 때 이미 어떤 인스턴스의 props 자리에 묶여 있을 때.
- **고치려면**: 자리에 묶인 핸들은 그대로 두거나, 전역 구독이 필요하면 새 `Effect`를 만드세요.
- **참고**: [`effect:Subscribe()`](/reference/core/05-observer-effect/#effectsubscribe)

### Quad0092

`Effect: subscribed strongly; use :Unsubscribe()` — `quad-base/src/Effect.luau`

- **언제**: `effect:WeakUnsubscribe()`를 부를 때 그 핸들이 강한 구독(`:Subscribe()`)으로 살아 있을 때.
- **고치려면**: 강한 구독을 풀려면 `:Unsubscribe()`를 쓰세요.
- **참고**: [`effect:WeakUnsubscribe()`](/reference/core/05-observer-effect/#effectweakunsubscribe)

### Quad0093

`Effect: not subscribed strongly; use :WeakUnsubscribe()` — `quad-base/src/Effect.luau`

- **언제**: `effect:Unsubscribe()`를 부를 때 그 핸들이 강하게 구독된 적이 없을 때(약한 구독뿐이거나, 자리에만 묶여 있거나, 이미 `:Unsubscribe()`로 한 번 풀린 뒤 다시 부른 경우).
- **고치려면**: 약한 구독을 풀려면 `:WeakUnsubscribe()`를 쓰세요. 강한 구독을 이미 한 번 풀었다면 다시 부르지 마세요.
- **참고**: [`effect:Unsubscribe()`](/reference/core/05-observer-effect/#effectunsubscribe)

### Quad0094

`Effect: fn must be a function` — `quad-base/src/Effect.luau`

- **언제**: `q.Effect(fn, ...)`의 `fn`이 함수가 아닐 때.
- **고치려면**: 함수를 넘기세요.
- **참고**: [`q.Effect(fn, ...deps)`](/reference/core/05-observer-effect/#qeffectfn-deps)

### Quad0095

`Effect: dep #{i} is nil` — `quad-base/src/Effect.luau`

- **언제**: `q.Effect(fn, ...deps)`의 의존성 목록 중 `i`번째가 `nil`일 때.
- **고치려면**: 모든 의존성 자리를 실제 값(`State`/`Source`/`Ref`)으로 채우세요.
- **참고**: [`q.Effect(fn, ...deps)`](/reference/core/05-observer-effect/#qeffectfn-deps)

### Quad0096

`Effect: dep #{i} is not a State/Source/Ref` — `quad-base/src/Effect.luau`

- **언제**: 의존성 목록의 `i`번째가 `State`/`Source`/`Ref` 중 어느 것도 아닐 때.
- **고치려면**: 의존성은 `State`/`Source`/`Ref`만 쓸 수 있습니다.
- **참고**: [`q.Effect(fn, ...deps)`](/reference/core/05-observer-effect/#qeffectfn-deps)

### Quad0097

`Effect: must be an array item, not the value of a {typeof(k)} key` — `quad-base/src/Effect.luau`

- **언제**: `Effect`를 props의 문자 키 값 자리에 두거나, `State`/`Store`에 담아 그 자리에 닿게 했을 때.
- **고치려면**: `Effect`는 props의 숫자 키(배열부) 리터럴 자리에만 놓으세요.
- **참고**: [숫자 키 자리에 넣기](/reference/core/05-observer-effect/#숫자-키-자리에-넣기)

### Quad0098

`Effect: Effect.Init(module) has not run for this quad instance` — `quad-base/src/Effect.luau`

- **언제**: `Effect.implFor(module)`이 그 quad 모듈 인스턴스에서 아직 `Effect.Init`이 돌지 않았는데 불렸을 때 — 정상 경로(`module:RunInit`)로는 나지 않는 내부 조립 순서 불변식입니다.
- **고치려면**: (문서 미정) — 사용자 코드가 직접 부딪히는 자리가 아닙니다. quad 모듈 조립(`New()`) 경로를 우회해 내부 함수를 직접 부르지 않았는지 확인하세요.
- **참고**: [Observer / Effect](/reference/core/05-observer-effect/)

### Quad0101

`{name}: fn must be a function (got {typeof(fn)})` — `quad-base/src/LifecycleHooks.luau`

- **언제**: `q.OnCreated(fn)`/`q.OnRendered(fn)`/`q.OnDestroyed(fn)`에 넘긴 `fn`이 함수가 아닐 때. `{name}`은 실제로 부른 훅 이름입니다.
- **고치려면**: 콜백 함수를 넘기세요.
- **참고**: [공통 계약](/reference/sugar/04-lifecycle-hooks/#공통-계약)

### Quad0109

`Observer: cannot bind an Observer from inside its own fn` — `quad-base/src/Observer.luau`

- **언제**: `state:Observer(fn)`의 콜백 안에서 새로 만든 `Observer`를 그 자리(props의 숫자 키)에 놓아 바인딩하려 할 때.
- **고치려면**: 새 핸들은 다음 렌더/실행에서 놓으세요 — 콜백 실행 중에는 자기 자신도, 새로 만든 핸들도 그 자리에서 바인딩할 수 없습니다.
- **참고**: [`state:Observer(fn)`](/reference/core/05-observer-effect/#stateobserverfn)

### Quad0110

`Observer: cannot change subscription from inside its own fn` — `quad-base/src/Observer.luau`

- **언제**: `observer:WeakSubscribe()`를 그 `Observer` 자신의 콜백 실행 중에 부를 때.
- **고치려면**: 구독/재구독은 콜백 밖에서 하세요. 해제(`:Unsubscribe()`/`:WeakUnsubscribe()`)는 콜백 안에서도 됩니다.
- **참고**: [`observer:WeakSubscribe()`](/reference/core/05-observer-effect/#observerweaksubscribe)

### Quad0111

`Observer: already subscribed` — `quad-base/src/Observer.luau`

- **언제**: `observer:WeakSubscribe()`를 부를 때 이미 강하게(`:Subscribe()`) 구독돼 있어서 약한 구독으로 바꿀 수 없을 때.
- **고치려면**: 이미 구독 중인 핸들은 그대로 두거나, 새 `Observer`를 만드세요.
- **참고**: [`observer:WeakSubscribe()`](/reference/core/05-observer-effect/#observerweaksubscribe)

### Quad0112

`Observer: subscribed strongly; use :Unsubscribe()` — `quad-base/src/Observer.luau`

- **언제**: `observer:WeakUnsubscribe()`를 부를 때 그 핸들이 강한 구독(`:Subscribe()`)으로 살아 있을 때 — 반쯤 풀린 핸들이 되는 것을 막습니다.
- **고치려면**: 강한 구독을 풀려면 `:Unsubscribe()`를 쓰세요.
- **참고**: [`observer:WeakUnsubscribe()`](/reference/core/05-observer-effect/#observerweakunsubscribe)

### Quad0113

`Observer: cannot change subscription from inside its own fn` — `quad-base/src/Observer.luau`

- **언제**: `observer:Subscribe()`를 그 `Observer` 자신의 콜백 실행 중에 부를 때.
- **고치려면**: 구독/재구독은 콜백 밖에서 하세요. 해제는 그 안에서도 됩니다.
- **참고**: [`observer:Subscribe()`](/reference/core/05-observer-effect/#observersubscribe)

### Quad0114

`Observer: already subscribed` — `quad-base/src/Observer.luau`

- **언제**: `observer:Subscribe()`를 부를 때 이미 강하게 구독돼 있을 때(중복 `:Subscribe()`).
- **고치려면**: 이미 구독 중이면 다시 부르지 마세요.
- **참고**: [`observer:Subscribe()`](/reference/core/05-observer-effect/#observersubscribe)

### Quad0115

`Observer: not subscribed strongly; use :WeakUnsubscribe()` — `quad-base/src/Observer.luau`

- **언제**: `observer:Unsubscribe()`를 부를 때 그 핸들이 강하게 구독된 적이 없을 때(약한 구독뿐이거나, 자리에만 묶여 있거나, 이미 한 번 풀린 뒤 다시 부른 경우).
- **고치려면**: 약한 구독을 풀려면 `:WeakUnsubscribe()`를 쓰세요.
- **참고**: [`observer:Unsubscribe()`](/reference/core/05-observer-effect/#observerunsubscribe)

### Quad0116

`Observer: must be an array item, not the value of a {typeof(k)} key` — `quad-base/src/Observer.luau`

- **언제**: `Observer`를 props의 문자 키 값 자리에 두거나, `State`/`Store`에 담아 그 자리에 닿게 했을 때.
- **고치려면**: `Observer`는 props의 숫자 키(배열부) 리터럴 자리에만 놓으세요.
- **참고**: [숫자 키 자리에 넣기](/reference/core/05-observer-effect/#숫자-키-자리에-넣기)

### Quad0117

`Observer: Observer.Init(module) has not run for this quad instance` — `quad-base/src/Observer.luau`

- **언제**: `Observer.implFor(module)`이 그 quad 모듈 인스턴스에서 아직 `Observer.Init`이 돌지 않았는데 불렸을 때 — 정상 경로(`module:RunInit`)로는 나지 않는 내부 조립 순서 불변식입니다.
- **고치려면**: (문서 미정) — 사용자 코드가 직접 부딪히는 자리가 아닙니다. quad 모듈 조립(`New()`) 경로를 우회해 내부 함수를 직접 부르지 않았는지 확인하세요.
- **참고**: [Observer / Effect](/reference/core/05-observer-effect/)

### Quad0130

`Ref: cannot :Set from the coroutine that is waiting on this Ref, nor from one it resumed (Wait(thread) registered a {status} coroutine)` — `quad-base/src/Ref/init.luau`

- **언제**: `ref:Wait()`로 대기 중인 바로 그 코루틴이나, 그 코루틴이 resume한 코루틴에서 같은 `Ref`에 `:Set`을 부를 때 — 대기 중인 코루틴을 resume하는 것 자체가 이 `:Set`이라 재진입이 됩니다.
- **고치려면**: `:Set`은 대기자 자신이 아닌 다른 코루틴에서 부르세요.
- **참고**: [`ref:Set(value)`](/reference/core/07-ref/#refsetvalue)

### Quad0132

`{surface}: callback must be a function (got {typeof(fn)})` — `quad-base/src/Ref/init.luau`

- **언제**: `ref:Callback(fn)`/`ref:WeakCallback(fn)`/`ref:Uncallback(fn)`에 넘긴 `fn`이 함수가 아닐 때. `{surface}`는 실제로 부른 메소드 이름(`Ref:Callback` 등)입니다.
- **고치려면**: 콜백 함수를 넘기세요.
- **참고**: [Ref](/reference/core/07-ref/)

### Quad0133

`Ref: Wait(thread) expects a thread (got {typeof(thread)})` — `quad-base/src/Ref/init.luau`

- **언제**: `ref:Wait(thread)`에 넘긴 인자가 `thread`가 아닐 때.
- **고치려면**: 등록만 하고 싶은 코루틴 값을 넘기거나, 인자 없이 불러 지금 코루틴을 yield하며 등록하세요.
- **참고**: [`ref:Wait(thread?)`](/reference/core/07-ref/#refwaitthread)

### Quad0134

`Ref: Wait() must be called from a yieldable coroutine (pass a thread to register a waiter without yielding)` — `quad-base/src/Ref/init.luau`

- **언제**: 인자 없이 `ref:Wait()`를 불렀는데 지금 코루틴이 yield할 수 없는 곳(메인 스레드, 메타메소드/C 호출 경계 등)일 때.
- **고치려면**: yield 가능한 코루틴 안에서 부르거나, 대기시킬 `thread`를 명시적으로 넘겨 등록만 하세요.
- **참고**: [`ref:Wait(thread?)`](/reference/core/07-ref/#refwaitthread)

### Quad0135

`Ref:Unwrap: the Ref is empty (Value is nil) — not filled yet, or never placed` — `quad-base/src/Ref/init.luau`

- **언제**: `ref:Unwrap()`을 불렀는데 `.Value`가 아직 `nil`일 때 — 아직 채워지지 않았거나, 애초에 자리에 놓이지 않았습니다.
- **고치려면**: 런타임 보장이 있는 자리(예: `PreRef`가 채워진 뒤의 이벤트 콜백)에서만 쓰세요. 그렇지 않으면 `.Value`를 직접 읽어 `nil` 검사를 하세요.
- **참고**: [`ref:Unwrap()`](/reference/core/07-ref/#refunwrap)

### Quad0136

`{kind}: must be a literal array item — it reached array index {k} through a State/Store value, which the pre-pass cannot see` — `quad-base/src/Ref/init.luau`

- **언제**: `PreRef`/`PostRef`/`Ref`가 리터럴 숫자 키 자리가 아니라 `State`/`Store` 값에 담겨 숫자 키 자리에 도착했을 때 — pre-pass가 그 경로를 미리 볼 수 없습니다. `{kind}`는 실제 종류(`PreRef`/`PostRef`/`Ref`)입니다.
- **고치려면**: 리터럴 숫자 키 자리에 직접 놓으세요.
- **참고**: [숫자 키 자리에만 놓는다](/reference/core/07-ref/#숫자-키-자리에만-놓는다)

### Quad0137

`{kind}: must be an array item, not the value of a {typeof(k)} key` — `quad-base/src/Ref/init.luau`

- **언제**: `PreRef`/`PostRef`/`Ref`를 props의 문자 키 값 자리에 두었을 때.
- **고치려면**: 숫자 키(배열부) 자리에만 놓으세요.
- **참고**: [숫자 키 자리에만 놓는다](/reference/core/07-ref/#숫자-키-자리에만-놓는다)

### Quad0234

`Observer: already bound to an Instance` — `quad-base/src/Observer.luau`

- **언제**: `observer:WeakSubscribe()`를 부를 때 이미 어떤 인스턴스의 props 자리에 묶여 있어서(전역 구독과 자리 바인딩은 겹칠 수 없음) 전역 구독으로 바꿀 수 없을 때.
- **고치려면**: 자리에 묶인 핸들은 그대로 두거나, 전역 구독이 필요하면 새 `Observer`를 만들어 처음부터 `:Subscribe()`/`:WeakSubscribe()`로 쓰세요.
- **참고**: [`observer:WeakSubscribe()`](/reference/core/05-observer-effect/#observerweaksubscribe)

### Quad0235

`Observer: already bound to an Instance` — `quad-base/src/Observer.luau`

- **언제**: `observer:Subscribe()`를 부를 때 이미 어떤 인스턴스의 props 자리에 묶여 있을 때.
- **고치려면**: 자리에 묶인 핸들은 그대로 두거나, 전역 구독이 필요하면 새 `Observer`를 만드세요.
- **참고**: [`observer:Subscribe()`](/reference/core/05-observer-effect/#observersubscribe)
