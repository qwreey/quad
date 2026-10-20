---
title: "에러 코드 — Ref·Observer·Effect·훅"
description: "Ref/PreRef/PostRef/Observer/Effect/생명주기 훅이 던지는 에러"
---
각 절은 `### QuadNNNN` — 메시지 원문(자리표시자는 `{…}`), 언제 나는가, 어떻게 고치는가. 번호로 찾으려면 [색인](/reference/errors/00-index/).


### Quad0086

`Effect: fn must return a cleanup function or nothing (got {typeof(cleanup)})` — `quad-base/src/Effect.luau`

- **언제**: `q.Effect(fn, ...)`의 `fn`이 함수도 `nil`도 아닌 값(숫자, 연결 객체 등)을 돌려줬을 때 — cleanup 자리는 함수 하나뿐입니다.
- **고치려면**: 정리할 게 있으면 함수로 감싸 돌려주세요 — 연결 객체는 `return function() conn:Disconnect() end`처럼 감싸세요. 여럿이면 한 클로저로 묶으세요.
- **에러 뒤**: 이 에러가 난 `Effect`는 `fn`이 던진 것과 같이 죽습니다 — 다시 돌지 않고, 구독·바인딩은 Quad0087/Quad0088/Quad0090으로 거부됩니다(계약 — [`q.Effect`](/reference/core/05-observer-effect/#qeffectfn-deps)). 고친 뒤에는 새 `Effect`를 만드세요.
- **참고**: [`q.Effect(fn, ...deps)`](/reference/core/05-observer-effect/#qeffectfn-deps)

### Quad0087

`Effect: cannot bind an Effect from inside its own fn or cleanup` — `quad-base/src/Effect.luau`

- **언제**: **그 핸들 자신**의 `fn`이나 cleanup이 도는 동안 같은 핸들을 다시 바인딩하려 할 때 — 예: fn 안에서 자기 인스턴스를 `q.dispose`한 뒤 `q.Elem "Frame" { self }`, 또는 `:Unsubscribe()`가 부른 cleanup 안에서 `q.Elem "Frame" { self }`. fn/cleanup 안에서 **새로 만든** 핸들을 놓는 것은 에러 없이 통과합니다. `fn`(이나 cleanup)이 한 번 던졌거나 Quad0086·Quad0263으로 멈춘 `Effect`는 죽은 핸들이라([`q.Effect`](/reference/core/05-observer-effect/#qeffectfn-deps)의 계약), 그 뒤에는 fn 밖에서 불러도 이 에러가 납니다.
- **고치려면**: 자기 자신을 실행 중에 다시 놓지 마세요 — 다시 묶으려면 fn/cleanup이 끝난 뒤에. fn이 던져 죽은 `Effect`라면 그 예외의 원인을 고친 뒤 새 `Effect`를 만드세요(죽은 핸들은 다시 돌지 않습니다).
- **참고**: [`q.Effect(fn, ...deps)`](/reference/core/05-observer-effect/#qeffectfn-deps)

### Quad0088

`Effect: cannot change subscription from inside fn or cleanup, or after this Effect's fn or cleanup has thrown - a thrown Effect stays dead; create a new one` — `quad-base/src/Effect.luau`

- **언제**: `effect:WeakSubscribe()`를 그 `Effect` 자신의 `fn`이나 cleanup 실행 중에 부를 때. `fn`(이나 cleanup)이 한 번 던졌거나 Quad0086·Quad0263으로 멈춘 `Effect`는 죽은 핸들이라([`q.Effect`](/reference/core/05-observer-effect/#qeffectfn-deps)의 계약), 그 뒤에는 fn 밖에서 불러도 이 에러가 납니다.
- **고치려면**: 구독/재구독은 `fn`·cleanup 밖에서 하세요. 해제(`:Unsubscribe()`/`:WeakUnsubscribe()`)는 그 안에서도 됩니다. fn이 던져 죽은 `Effect`라면 그 예외의 원인을 고친 뒤 새 `Effect`를 만드세요(죽은 핸들은 다시 돌지 않습니다).
- **참고**: [`effect:WeakSubscribe()`](/reference/core/05-observer-effect/#effectweaksubscribe)

### Quad0089

`Effect: already subscribed` — `quad-base/src/Effect.luau`

- **언제**: `effect:WeakSubscribe()`를 부를 때 이미 구독돼 있을 때 — 강한 구독(`:Subscribe()`)이든 약한 구독이든 마찬가지라, `:WeakSubscribe()`를 두 번 불러도 이 에러입니다.
- **고치려면**: 이미 구독 중인 핸들은 그대로 두세요. 강한 구독을 약한 구독으로 바꾸려면 먼저 `:Unsubscribe()`로 푼 뒤 `:WeakSubscribe()`하세요.
- **참고**: [`effect:WeakSubscribe()`](/reference/core/05-observer-effect/#effectweaksubscribe)

### Quad0230

`Effect: already bound to an Instance` — `quad-base/src/Effect.luau`

- **언제**: `effect:WeakSubscribe()`를 부를 때 이미 어떤 인스턴스의 props 자리에 묶여 있어서(전역 구독과 자리 바인딩은 겹칠 수 없음) 전역 구독으로 바꿀 수 없을 때.
- **고치려면**: 자리에 묶인 핸들은 그대로 두거나, 전역 구독이 필요하면 새 `Effect`를 만들어 처음부터 `:Subscribe()`/`:WeakSubscribe()`로 쓰세요.
- **참고**: [`effect:WeakSubscribe()`](/reference/core/05-observer-effect/#effectweaksubscribe)

### Quad0090

`Effect: cannot change subscription from inside fn or cleanup, or after this Effect's fn or cleanup has thrown - a thrown Effect stays dead; create a new one` — `quad-base/src/Effect.luau`

- **언제**: `effect:Subscribe()`를 그 `Effect` 자신의 `fn`이나 cleanup 실행 중에 부를 때. `fn`(이나 cleanup)이 한 번 던졌거나 Quad0086·Quad0263으로 멈춘 `Effect`는 죽은 핸들이라([`q.Effect`](/reference/core/05-observer-effect/#qeffectfn-deps)의 계약), 그 뒤에는 fn 밖에서 불러도 이 에러가 납니다.
- **고치려면**: 구독/재구독은 `fn`·cleanup 밖에서 하세요. 해제는 그 안에서도 됩니다. fn이 던져 죽은 `Effect`라면 그 예외의 원인을 고친 뒤 새 `Effect`를 만드세요(죽은 핸들은 다시 돌지 않습니다).
- **참고**: [`effect:Subscribe()`](/reference/core/05-observer-effect/#effectsubscribe)

### Quad0091

`Effect: already subscribed` — `quad-base/src/Effect.luau`

- **언제**: `effect:Subscribe()`를 부를 때 이미 구독돼 있을 때 — 중복 `:Subscribe()`뿐 아니라, 약하게(`:WeakSubscribe()`) 구독된 핸들을 강한 구독으로 올리려 할 때도 이 에러입니다.
- **고치려면**: 이미 강하게 구독 중이면 다시 부르지 마세요. 약한 구독을 강한 구독으로 바꾸려면 먼저 `:WeakUnsubscribe()`로 푼 뒤 `:Subscribe()`하세요.
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

`Effect: only a strongly subscribed Effect can be released with :Unsubscribe() - a weakly subscribed one must be released with :WeakUnsubscribe(), and one held only by a seat must be released by clearing that seat` — `quad-base/src/Effect.luau`

- **언제**: `effect:Unsubscribe()`를 부를 때 그 핸들이 강하게 구독된 적이 없을 때(약한 구독뿐이거나, 자리에만 묶여 있거나, 이미 `:Unsubscribe()`로 한 번 풀린 뒤 다시 부른 경우).
- **고치려면**: 약한 구독을 풀려면 `:WeakUnsubscribe()`를 쓰세요. 강한 구독을 이미 한 번 풀었다면 다시 부르지 마세요. **자리에만 묶인** 핸들(숫자 키 자리에 놓인 Effect)에는 `:WeakUnsubscribe()`가 에러 없이 통과하지만 아무것도 풀지 않습니다 — 멈추려면 그 자리를 쥔 `State`를 `Set(nil)`하거나 `q.Backend.unbindLifetime(handle)`로 수명을 푸세요.
- **참고**: [`effect:Unsubscribe()`](/reference/core/05-observer-effect/#effectunsubscribe)

### Quad0094

`Effect: fn must be a function (got {typeof(fn)})` — `quad-base/src/Effect.luau`

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

- **언제**: `Effect`를 props의 문자 키 값 자리에 두거나, `State`/`Store`에 담아 그 자리에 닿게 했을 때. 단 그 키가 클래스의 반영 프로퍼티 이름이면 프로퍼티 핸들러가 먼저 받아 이 가드에 닿지 않습니다 — [`q.debug`](/reference/core/01-quad-module/#qdebug)를 켜면 그 자리에서 경고 한 줄이 나옵니다.
- **고치려면**: `Effect`는 props의 숫자 키(배열부) 리터럴 자리에만 놓으세요.
- **참고**: [숫자 키 자리에 넣기](/reference/core/05-observer-effect/#숫자-키-자리에-넣기)

### Quad0098

`Effect: Effect.Init(module) has not run for this quad instance` — `quad-base/src/Effect.luau`

- **언제**: `Effect.implFor(module)`이 그 quad 모듈 인스턴스에서 아직 `Effect.Init`이 돌지 않았는데 불렸을 때 던지는 내부 조립 순서 불변식입니다. 지금은 quad 안에서 이 함수를 부르는 곳이 없어, 현재 공개 표면에서 이 조건에 닿는 호출은 없습니다.
- **고치려면**: 사용자 코드가 닿는 경로가 없는 quad 내부 불변식입니다 — 재현되면 보고해 주세요.
- **참고**: [Observer / Effect](/reference/core/05-observer-effect/)

### Quad0101

`{name}: fn must be a function (got {typeof(fn)})` — `quad-base/src/LifecycleHooks.luau`

- **언제**: `q.OnCreated(fn)`/`q.OnRendered(fn)`/`q.OnDestroyed(fn)`에 넘긴 `fn`이 함수가 아닐 때. `{name}`은 실제로 부른 훅 이름입니다.
- **고치려면**: 콜백 함수를 넘기세요.
- **참고**: [공통 계약](/reference/sugar/04-lifecycle-hooks/#공통-계약)

### Quad0109

`Observer: cannot bind an Observer from inside its own fn (or after its fn threw - a throw leaves the in-run flag up)` — `quad-base/src/Observer.luau`

- **언제**: **그 핸들 자신**의 콜백이 도는 동안 같은 핸들을 다시 바인딩하려 할 때. 콜백 안에서 **새로 만든** `Observer`를 놓는 것은 통과합니다.
- **고치려면**: 자기 자신을 실행 중에 다시 놓지 마세요. 콜백이 던진 것이 원인이면 그 예외의 원인을 고치세요.
- **관측(계약 아님)**: 콜백이 한 번 던진 `Observer`는 지금 "실행 중" 표시가 풀리지 않은 채 남아, 그 뒤에는 콜백 밖에서 불러도 이 에러가 납니다(콜백 자체가 다음 변경에 다시 불리는 것은 계약입니다 — [`state:Observer(fn)`](/reference/core/05-observer-effect/#stateobserverfn)). 지금 동작에서 그 핸들을 다른 자리로 옮기려면 새 `Observer`를 만들어야 합니다.
- **참고**: [`state:Observer(fn)`](/reference/core/05-observer-effect/#stateobserverfn)

### Quad0110

`Observer: cannot change subscription from inside its own fn (or after its fn threw - a throw leaves the in-run flag up)` — `quad-base/src/Observer.luau`

- **언제**: `observer:WeakSubscribe()`를 그 `Observer` 자신의 콜백 실행 중에 부를 때.
- **고치려면**: 구독/재구독은 콜백 밖에서 하세요. 해제(`:Unsubscribe()`/`:WeakUnsubscribe()`)는 콜백 안에서도 됩니다. 콜백이 던진 것이 원인이면 그 예외의 원인을 고치세요.
- **관측(계약 아님)**: 콜백이 한 번 던진 `Observer`는 지금 "실행 중" 표시가 풀리지 않은 채 남아, 그 뒤에는 콜백 밖에서 불러도 이 에러가 납니다(콜백 자체가 다음 변경에 다시 불리는 것은 계약입니다 — [`state:Observer(fn)`](/reference/core/05-observer-effect/#stateobserverfn)). 지금 동작에서 그 핸들을 다른 자리로 옮기려면 새 `Observer`를 만들어야 합니다.
- **참고**: [`observer:WeakSubscribe()`](/reference/core/05-observer-effect/#observerweaksubscribe)

### Quad0111

`Observer: already subscribed` — `quad-base/src/Observer.luau`

- **언제**: `observer:WeakSubscribe()`를 부를 때 이미 구독돼 있을 때 — 강한 구독(`:Subscribe()`)이든 약한 구독이든 마찬가지라, `:WeakSubscribe()`를 두 번 불러도 이 에러입니다.
- **고치려면**: 이미 구독 중인 핸들은 그대로 두세요. 강한 구독을 약한 구독으로 바꾸려면 먼저 `:Unsubscribe()`로 푼 뒤 `:WeakSubscribe()`하세요.
- **참고**: [`observer:WeakSubscribe()`](/reference/core/05-observer-effect/#observerweaksubscribe)

### Quad0112

`Observer: subscribed strongly; use :Unsubscribe()` — `quad-base/src/Observer.luau`

- **언제**: `observer:WeakUnsubscribe()`를 부를 때 그 핸들이 강한 구독(`:Subscribe()`)으로 살아 있을 때 — 반쯤 풀린 핸들이 되는 것을 막습니다.
- **고치려면**: 강한 구독을 풀려면 `:Unsubscribe()`를 쓰세요.
- **참고**: [`observer:WeakUnsubscribe()`](/reference/core/05-observer-effect/#observerweakunsubscribe)

### Quad0113

`Observer: cannot change subscription from inside its own fn (or after its fn threw - a throw leaves the in-run flag up)` — `quad-base/src/Observer.luau`

- **언제**: `observer:Subscribe()`를 그 `Observer` 자신의 콜백 실행 중에 부를 때.
- **고치려면**: 구독/재구독은 콜백 밖에서 하세요. 해제는 그 안에서도 됩니다. 콜백이 던진 것이 원인이면 그 예외의 원인을 고치세요.
- **관측(계약 아님)**: 콜백이 한 번 던진 `Observer`는 지금 "실행 중" 표시가 풀리지 않은 채 남아, 그 뒤에는 콜백 밖에서 불러도 이 에러가 납니다(콜백 자체가 다음 변경에 다시 불리는 것은 계약입니다 — [`state:Observer(fn)`](/reference/core/05-observer-effect/#stateobserverfn)). 지금 동작에서 그 핸들을 다른 자리로 옮기려면 새 `Observer`를 만들어야 합니다.
- **참고**: [`observer:Subscribe()`](/reference/core/05-observer-effect/#observersubscribe)

### Quad0114

`Observer: already subscribed` — `quad-base/src/Observer.luau`

- **언제**: `observer:Subscribe()`를 부를 때 이미 구독돼 있을 때 — 중복 `:Subscribe()`뿐 아니라, 약하게(`:WeakSubscribe()`) 구독된 핸들을 강한 구독으로 올리려 할 때도 이 에러입니다.
- **고치려면**: 이미 강하게 구독 중이면 다시 부르지 마세요. 약한 구독을 강한 구독으로 바꾸려면 먼저 `:WeakUnsubscribe()`로 푼 뒤 `:Subscribe()`하세요.
- **참고**: [`observer:Subscribe()`](/reference/core/05-observer-effect/#observersubscribe)

### Quad0115

`Observer: only a strongly subscribed Observer can be released with :Unsubscribe() - a weakly subscribed one must be released with :WeakUnsubscribe(), and one held only by a seat must be released by clearing that seat` — `quad-base/src/Observer.luau`

- **언제**: `observer:Unsubscribe()`를 부를 때 그 핸들이 강하게 구독된 적이 없을 때(약한 구독뿐이거나, 자리에만 묶여 있거나, 이미 한 번 풀린 뒤 다시 부른 경우).
- **고치려면**: 약한 구독을 풀려면 `:WeakUnsubscribe()`를 쓰세요. **자리에만 묶인** 핸들(숫자 키 자리에 놓인 Observer)에는 그 호출이 에러 없이 통과하지만 아무것도 풀지 않습니다 — 멈추려면 그 자리를 쥔 `State`를 `Set(nil)`하거나 `q.Backend.unbindLifetime(handle)`로 수명을 푸세요.
- **참고**: [`observer:Unsubscribe()`](/reference/core/05-observer-effect/#observerunsubscribe)

### Quad0116

`Observer: must be an array item, not the value of a {typeof(k)} key` — `quad-base/src/Observer.luau`

- **언제**: `Observer`를 props의 문자 키 값 자리에 두거나, `State`/`Store`에 담아 그 자리에 닿게 했을 때. 단 그 키가 클래스의 반영 프로퍼티 이름이면 프로퍼티 핸들러가 먼저 받아 이 가드에 닿지 않습니다 — [`q.debug`](/reference/core/01-quad-module/#qdebug)를 켜면 그 자리에서 경고 한 줄이 나옵니다.
- **고치려면**: `Observer`는 props의 숫자 키(배열부) 리터럴 자리에만 놓으세요.
- **참고**: [숫자 키 자리에 넣기](/reference/core/05-observer-effect/#숫자-키-자리에-넣기)

### Quad0117

`Observer: Observer.Init(module) has not run for this quad instance` — `quad-base/src/Observer.luau`

- **언제**: `Observer.implFor(module)`이 그 quad 모듈 인스턴스에서 아직 `Observer.Init`이 돌지 않았는데 불렸을 때 — 정상 경로(`module:RunInit`)로는 나지 않는 내부 조립 순서 불변식입니다.
- **고치려면**: 사용자 코드가 직접 부딪히는 자리가 아닙니다(quad 내부 불변식). quad 모듈 조립(`New()`) 경로를 우회해 내부 함수를 직접 부르지 않았는지 확인하세요.
- **참고**: [Observer / Effect](/reference/core/05-observer-effect/)

### Quad0130

`Ref: cannot :Set from the coroutine that is waiting on this Ref, nor from one it resumed (Wait(thread) registered a {status} coroutine)` — `quad-base/src/Ref/init.luau`

- **언제**: `ref:Wait(thread)`로 등록해 둔 코루틴이 지금 `:Set`을 부르는 바로 그 코루틴이거나, 지금 코루틴을 resume한(바깥의) 코루틴일 때 — 대기자를 resume하는 것이 이 `:Set`인데, 실행 중인 코루틴은 resume할 수 없습니다. 인자 없는 `ref:Wait()`로 yield한 코루틴은 멈춰 있는 동안 `:Set`을 부를 수 없으므로 이 경우에 해당하지 않습니다.
- **고치려면**: `ref:Wait(thread)`에 지금 실행 중인 코루틴이나 그 바깥 코루틴을 등록하지 마세요 — `:Set`은 등록된 대기자와 무관한 코루틴에서 부르세요.
- **참고**: [`ref:Set(value)`](/reference/core/07-ref/#refsetvalue) · 그 Ref를 마운트하다 나면 `파일:줄` 접두가 quad 파일을 가리킵니다 — [디버깅 부록](/how-to/10-debugging-and-troubleshooting/)의 알려진 한계 3

### Quad0132

`{surface}: callback must be a function (got {typeof(fn)})` — `quad-base/src/Ref/init.luau`

- **언제**: `ref:Callback(fn)`/`ref:WeakCallback(fn)`/`ref:Uncallback(fn)`에 넘긴 `fn`이 함수가 아닐 때. `{surface}`는 실제로 부른 메소드 이름(`Ref:Callback` 등)입니다.
- **고치려면**: 콜백 함수를 넘기세요.
- **참고**: [Ref](/reference/core/07-ref/)

### Quad0133

`Ref: Wait(thread) argument must be a thread (got {typeof(thread)})` — `quad-base/src/Ref/init.luau`

- **언제**: `ref:Wait(thread)`에 넘긴 인자가 `thread`가 아닐 때.
- **고치려면**: 등록만 하고 싶은 코루틴 값을 넘기거나, 인자 없이 불러 지금 코루틴을 yield하며 등록하세요.
- **참고**: [`ref:Wait(thread?)`](/reference/core/07-ref/#refwaitthread)

### Quad0134

`Ref: Wait() must be called from a yieldable coroutine (pass a thread to register a waiter without yielding)` — `quad-base/src/Ref/init.luau`

- **언제**: 인자 없이 `ref:Wait()`를 불렀는데 지금 코루틴이 yield할 수 없는 곳일 때 — 메타메소드(`__index` 등)나 `table.sort` 비교자 같은 C 호출 경계 안. `luau` CLI의 메인 청크는 yield할 수 있어 이 에러 없이 스크립트가 멈춥니다(관측; Roblox 스크립트 최상위가 yield할 수 있는지는 실기기 미확인).
- **고치려면**: yield 가능한 코루틴 안에서 부르거나, 대기시킬 `thread`를 명시적으로 넘겨 등록만 하세요.
- **참고**: [`ref:Wait(thread?)`](/reference/core/07-ref/#refwaitthread)

### Quad0135

`Ref:Unwrap: the Ref is empty (Value is nil) - not filled yet, or never placed` — `quad-base/src/Ref/init.luau`

- **언제**: `ref:Unwrap()`을 불렀는데 `.Value`가 아직 `nil`일 때 — 아직 채워지지 않았거나, 애초에 자리에 놓이지 않았습니다.
- **고치려면**: 런타임 보장이 있는 자리(예: `PreRef`가 채워진 뒤의 이벤트 콜백)에서만 쓰세요. 그렇지 않으면 `.Value`를 직접 읽어 `nil` 검사를 하세요.
- **참고**: [`ref:Unwrap()`](/reference/core/07-ref/#refunwrap)

### Quad0136

`{kind}: must be a literal array item - it reached array index {k} through a State/Store value, which the pre-pass cannot see` — `quad-base/src/Ref/init.luau`

- **언제**: `PreRef`/`PostRef`가 리터럴 숫자 키 자리가 아니라 `State`/`Store` 값에 담겨 숫자 키 자리에 도착했을 때 — pre-pass가 그 경로를 미리 볼 수 없습니다. `{kind}`는 실제 종류(`PreRef`/`PostRef`)입니다. 평범한 `Ref`는 `State`/`Store`를 거쳐 숫자 키 자리에 와도 정상적으로 채워지므로 이 에러가 나지 않습니다.
- **고치려면**: 리터럴 숫자 키 자리에 직접 놓으세요.
- **참고**: [숫자 키 자리에만 놓는다](/reference/core/07-ref/#숫자-키-자리에만-놓는다)

### Quad0137

`{kind}: must be an array item, not the value of a {typeof(k)} key` — `quad-base/src/Ref/init.luau`

- **언제**: `PreRef`/`PostRef`를 props의 문자 키 값 자리에 두었을 때(평범한 `Ref`는 이 가드가 없습니다 — 3.3.0부터 [`Quad0076`](/reference/errors/02-dispatch-bookkeeping/#quad0076)이 문자 키 꼬리로 같은 안내를 합니다) — 단 그 키가 클래스의 반영 프로퍼티나 이벤트 이름이면 프로퍼티·이벤트 핸들러가 먼저 받아 이 가드에 닿지 않습니다(`Name = ref`는 핸들러의 번호 없는 타입 에러, `Size = ref`는 조용히 대입, `Activated = ref`는 `Quad0218` — mock에서의 관측, 계약 아님; 생성 props 타입이 strict에서 이 자리를 거부합니다). 그런 자리는 [`q.debug`](/reference/core/01-quad-module/#qdebug)를 켜면 경고 한 줄(`{kind}: found at string key …`)로 드러납니다.
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

### Quad0262 (폐기)

`Observer: the first run did not settle after 10000 re-runs - the fn keeps setting its own target (a Source propagates even an equal value; set only when the value differs)` — 폐기

- **폐기** — 이제 던지지 않습니다. `state:Observer(fn)`의 첫 발화가 도중에 온 변경으로 그 자리에서 다시 돌던 반복이 없어졌습니다 — 첫 발화 도중 온 변경은 보류됐다가 핸들이 묶이거나 구독될 때 한 번 반영되므로, 세어서 멈출 반복 자체가 없습니다. 콜백이 자기 대상(이나 그 원천)을 되쓰는 것은 정의되지 않은 동작이고, [`q.debug`](/reference/core/01-quad-module/#qdebug)를 켜면 살아난 핸들에서 그런 되먹임이 경고 한 줄로 드러납니다. 이 번호는 다른 에러에 다시 쓰지 않습니다.
- **참고**: [`state:Observer(fn)`](/reference/core/05-observer-effect/#stateobserverfn)

### Quad0263

`Effect: fn re-ran 10000 times in one loop - the fn keeps setting one of its own deps (Source:Set propagates even an equal value; write with Source:SetIfChanged to skip it)` — `quad-base/src/Effect.luau`

- **언제**: `Effect`의 지연 재실행 루프에서 `fn`이 1만 번 돈 뒤에도 또 다시 돌아야 할 때 — `fn`이 자기 의존성(이나 그 상류)을 계속 `:Set`해 끝나지 않는 경우입니다. 이 한도는 늘 켜져 있습니다([`q.debug`](/reference/core/01-quad-module/#qdebug)와 무관). 수렴하는 재실행은 정의된 동작이고, 수렴하지 않는 고리는 정의되지 않은 동작입니다 — 이 한도는 그 고리를 정의하는 것이 아니라 무한히 돌지 않고 끝나게 하는 장치입니다. 첫 실행이든, 구독한 뒤 어떤 `:Set`이 깨운 실행이든 같습니다. `source:Set`은 같은 값을 다시 넣어도 전파하므로 조건 없이 같은 값을 되쓰는 `fn`이 가장 흔한 원인입니다. 3.2.0까지는 이 한도가 없어 같은 코드가 에러 없이 끝나지 않습니다. 에러는 첫 실행이면 `q.Effect` 줄, 이후 실행이면 반복을 시작한 `:Set` 줄을 가리킵니다.
- **고치려면**: 되쓰기를 [`dep:SetIfChanged(c)`](/reference/core/02-source/#sourcesetifchangedv)로 하세요 — 값이 같으면(`==`) 아무것도 하지 않아 반복이 끝납니다.
- **에러 뒤**: 이 에러가 난 `Effect`는 `fn`이 던진 것과 같이 죽습니다(계약 — [`q.Effect`](/reference/core/05-observer-effect/#qeffectfn-deps)). 고친 뒤에는 새 `Effect`를 만드세요.
- **참고**: [`q.Effect(fn, ...deps)`](/reference/core/05-observer-effect/#qeffectfn-deps), [`source:SetIfChanged(v)`](/reference/core/02-source/#sourcesetifchangedv)
