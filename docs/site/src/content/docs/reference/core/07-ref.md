---
title: Ref
description: 값 상자 프리미티브 — Ref/PreRef/PostRef, 콜백 등록, :Wait, :Unwrap
---

`Ref<T>`는 **값 상자**입니다. 값 하나와 리비전 하나를 들고, 값이 바뀔 때 등록된 콜백을 부릅니다. `State`가 아닙니다 — 전파도, `:Get`도, `:Compute`도 없습니다. quad가 `Ref`에 주는 유일한 추가 의미는 "직전과 구별되는 표식을 나른다"(= `Epoch`)입니다.

`Ref`가 실제로 빛나는 자리는 **컴포넌트가 만든 실물 인스턴스를 밖으로 꺼내오는 통로**입니다. props의 숫자 키 자리에 `Ref`를 놓으면 quad가 그 자리에 만들어진 인스턴스를 `:Set` 해줍니다. 언제 채워지느냐가 셋을 가릅니다 — [`q.PreRef`](#qprereftdefault)는 숫자 키 위치와 무관하게 **가장 먼저**, [`q.Ref`](#qreftdefault)는 **자기 숫자 키 자리가 처리될 때**(형제 자식들과 같은 순서 위에서), [`q.PostRef`](#qpostreftdefault)는 숫자 키와 문자 키가 **전부 끝난 뒤** 채워집니다.

이 페이지의 심볼: [`q.Ref`](#qreftdefault) · [`q.PreRef`](#qprereftdefault) · [`q.PostRef`](#qpostreftdefault) · [`ref.Value`](#refvalue) · [`ref.Revision`](#refrevision) · [`ref.Callbacks`](#refcallbacks) · [`ref.WeakCallbacks`](#refweakcallbacks) · [`ref:Set`](#refsetvalue) · [`ref:Callback`](#refcallbackfn) · [`ref:WeakCallback`](#refweakcallbackfn) · [`ref:Uncallback`](#refuncallbackfn) · [`ref:Wait`](#refwaitthread) · [`ref:Unwrap`](#refunwrap)

이 페이지의 모든 예제는 아래 프롤로그를 전제합니다.

```luau
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("@game/ReplicatedStorage/Client/UI/Quad")
local D = q.D
```

## 공통 타입

```luau
type RefCallback<T> = (value: T, ref: Ref<T>) -> ()

type Ref<T> = {
    read __quadRefAccepts: (T) -> (), -- 타입 전용 반공변 팬텀 필드(children 자리의 클래스 검사용)
    Value: T,
    Revision: number,
    Callbacks: { [RefCallback<T> | thread]: true },
    WeakCallbacks: { [RefCallback<T>]: true },
    Set: <Self>(self: Self, value: T) -> Self,
    Callback: <Self>(self: Self, fn: RefCallback<T>) -> Self,
    WeakCallback: <Self>(self: Self, fn: RefCallback<T>) -> Self,
    Uncallback: <Self>(self: Self, fn: RefCallback<T>) -> Self,
    Wait: <Self>(self: Self, thread: thread?) -> Self,
    Unwrap: (self: Ref<T>) -> StripNil<T>,
}

type PreRef<T> = Ref<T> & { read __quadPreRef: true }
type PostRef<T> = Ref<T> & { read __quadPostRef: true }
```

콜백의 두 번째 인자는 `Ref` 자신입니다(= 그 `Epoch`). 평범한 사용자 콜백은 그냥 무시하면 됩니다.

변경 메소드는 전부 `self`를 돌려주므로 체이닝됩니다. 반환 타입이 `<Self>` 제네릭이라 `q.PreRef(x):Callback(fn)`도 여전히 `PreRef`입니다.

## 숫자 키 자리에만 놓는다

`PreRef`/`PostRef`는 props의 **숫자 키 리터럴 항목**으로만 놓을 수 있습니다. 문자 키의 값으로 두거나 `Source`/`Store` 값에 담아 숫자 키 자리에 닿게 하면 전용 가드가 그 자리에서 던집니다(`PostRef`도 주어만 바뀐 같은 문구).

- `PreRef: must be an array item, not the value of a {typeof(k)} key`
- `PreRef: must be a literal array item — it reached array index {k} through a State/Store value, which the pre-pass cannot see`

평범한 `Ref`에는 그 가드가 없습니다. 숫자 키 자리에 닿기만 하면 되므로 `Source`/`Store` 값에 담아 넣어도 그대로 채워지고, 다른 자리에 두면 "Ref를 잘못 놓았다"는 진단 대신 그 자리의 주인이 내는 에러를 봅니다.

- Modifier 필드 — `Modifier: field "{k}" cannot hold a handler-layer value (Ref/Observer/Effect/Slot/Modifier)`
- 아무 핸들러도 맡지 않는 문자 키 — `Dispatch: no handler matched key {k} (value: {typeof(v)}, brand: Ref)`
- 반영 프로퍼티 키 — 생성된 props 타입이 그 값 자리에서 `Ref`를 거부합니다.

하나의 `Ref`는 **한 자리에만** 놓을 수 있습니다. 생명주기 결합이 그 자리에서 던집니다 — 같은 인스턴스의 두 자리면 `bindLifetime: value is already bound to this Instance (the same handle at two positions?)`, 다른 인스턴스면 `bindLifetime: value is already bound to another Instance`(생명주기는 백엔드가 심으므로 이 두 문구는 quad-roblox의 것입니다).

`PreRef`/`PostRef`는 그 위에 **일회용**이기까지 합니다.

- `PreRef: already fired — a PreRef is one-shot, make a new one for each instance`

## `q.Ref<<T>>(default)`

**시그니처**

```luau
Ref: <T>(default: T) -> Ref<T>
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `default` | `T` | 초기 `.Value` |

**반환** — 새 `Ref<T>`. `.Revision`은 0, 콜백 테이블 둘은 비어 있습니다.

**동작**

- 타입 파라미터는 **하나**입니다. nil이 들어올 수 있는 자리는 호출자가 넓힙니다 — `q.Ref<<Frame?>>(nil)`처럼 씁니다. props 숫자 키 자리에 놓는 Ref는 인스턴스가 채워지기 전까지 비어 있으므로 사실상 항상 `T?` 형태입니다.
- 숫자 키 자리에 놓으면, **그 자리가 처리되는 시점**에 `:Set(inst)`가 불립니다. 디스패치는 숫자 키를 인덱스 순서로 돌기 때문에, 앞 자리의 자식이 먼저 놓인 뒤 이 `Ref`가 채워지고, 뒤 자리는 그다음입니다. **그 숫자 키 자리 자체가 다른 값으로 재구동되면**(재바인드/retract 경로) `:Set(nil)`로 되돌아갑니다.
- **인스턴스가 `Destroy()`되는 것과는 무관합니다.** `Ref`는 대상 인스턴스의 `Destroy`를 감지하지도, 반응하지도 않습니다 — 이미 파괴된 인스턴스를 계속 가리킨 채로 남는 것도 정상적으로 가능하고, 그 이후 `.Value`를 읽고 쓰는 것은 UB입니다. 파괴 시점 정리가 필요하면 `Effect`나 이벤트 쪽에서 하세요.
- `Ref`는 `Epoch`이기도 합니다(다중 태깅) — `q.isRef`와 `q.isEpoch`가 둘 다 참입니다.

**예제**

```luau
local boxRef = q.Ref<<Frame?>>(nil)
local panel = D.Frame {
    boxRef,                       -- 숫자 키: 만들어진 Frame이 여기 담긴다
    D.TextLabel { Text = "제목" },
}
```

**관련** — [컴포넌트 경계 규약](/how-to/01-component-conventions/)

## `q.PreRef<<T>>(default)`

**시그니처**

```luau
PreRef: <T>(default: T) -> PreRef<T>
```

**동작** — 런타임은 `Ref`와 완전히 같고, 브랜드와 마커 필드만 다릅니다. 차이는 **발화 시점**입니다.

`PreRef`는 그 인스턴스에 **아무 일도 일어나기 전에** 채워집니다. 디스패치의 pre-pass가 숫자 키 자리를 한 번 훑으면서 위치와 무관하게 전부 먼저 발화시킵니다(`PreRef`끼리의 상대 순서는 숫자 키 순서(1부터)). 그래서 같은 props 안의 이벤트 핸들러나 프로퍼티 계산이 이미 채워진 `.Value`를 볼 수 있습니다.

일회용입니다 — 한 번 발화한 `PreRef`를 다른 인스턴스에 다시 놓으면 에러입니다. 인스턴스마다 새로 만드세요.

**예제**

```luau
local inputRef = q.PreRef<<TextBox?>>(nil)
local form = D.Frame {
    D.TextBox { inputRef },
    D.TextButton {
        Text = "지우기",
        Activated = function()
            inputRef:Unwrap().Text = "" -- pre-pass가 이미 채웠다
        end,
    },
}
```

**관련** — [컴포넌트 경계 규약](/how-to/01-component-conventions/)

## `q.PostRef<<T>>(default)`

**시그니처**

```luau
PostRef: <T>(default: T) -> PostRef<T>
```

**동작** — `PreRef`의 거울입니다. 이 인스턴스의 **숫자 키(자식·서브트리)와 문자 키(프로퍼티·이벤트)가 전부 끝난 뒤** 채워집니다. 여러 개면 숫자 키 순서(1부터)로 발화합니다.

"자식이 전부 붙었다"까지가 계약입니다 — **부모에 붙었는지는 계약이 아닙니다**(어느 쪽으로도 보장하지 않습니다). 발화 기준은 이 인스턴스의 drive(숫자 키·문자 키 처리)가 끝난 시점이지 부모에 마운트되는 시점이 아니므로, 발화 순간 `Parent`는 `nil`일 수도 이미 채워져 있을 수도 있고(리터럴 중첩이냐 `Claim`처럼 이미 트리에 있던 인스턴스냐에 따라), **그 뒤로 바뀌지 않을 수도 있습니다** — 이후의 `Parent` 변경을 기다리는 코드는 영영 안 돌 수 있습니다. 완성된 **자기 아래** 서브트리를 재는 코드(레이아웃 측정 등)가 이 자리입니다.

`PreRef`와 마찬가지로 일회용이고, 숫자 키 리터럴 전용입니다.

**예제**

```luau
local doneRef = q.PostRef<<Frame?>>(nil)
local card = D.Frame {
    doneRef,
    D.TextLabel { Text = "A" },
    D.TextLabel { Text = "B" },
}
doneRef:Callback(function(inst)
    if inst then
        -- 자식 둘이 이미 다 붙어 있다
    end
end)
```

## `ref.Value`

**시그니처**

```luau
Value: T
```

**동작** — 지금 담긴 값. 직접 읽습니다. `:Set`이 가장 먼저 갱신하는 것이 이 필드이므로, 콜백 안에서 `ref.Value`를 읽으면 이미 새 값입니다.

직접 대입해도 막지는 않지만 리비전도 콜백도 돌지 않습니다 — 쓸 때는 항상 [`:Set`](#refsetvalue)을 쓰세요.

props 숫자 키 자리에 놓은 Ref는 채워지기 전까지 `nil`이라 타입이 사실상 `Ref<T?>`입니다. 런타임 보장이 있는 자리라면 [`:Unwrap()`](#refunwrap)이 그 `nil`을 벗겨줍니다.

## `ref.Revision`

**시그니처**

```luau
Revision: number
```

**동작** — `:Set` 때마다 바뀌는 표식입니다. `Ref`를 `Epoch`으로 만드는 필드입니다.

계약은 **같다/다르다뿐입니다.** 크기 비교나 증가 방향에 의존하지 마세요 — 32비트 범위를 순환합니다.

## `ref.Callbacks`

**시그니처**

```luau
Callbacks: { [RefCallback<T> | thread]: true }
```

**동작** — 강하게 붙들린 콜백들의 **집합**(배열이 아닙니다). 키가 콜백 함수 자신이라 중복 등록은 자동으로 하나로 합쳐집니다 — "몇 번 등록했나"라는 질문이 존재하지 않습니다.

[`:Wait()`](#refwaitthread)의 대기 코루틴도 여기 `thread` 키로 들어갔다가 `:Set`이 소진합니다.

## `ref.WeakCallbacks`

**시그니처**

```luau
WeakCallbacks: { [RefCallback<T>]: true }
```

**동작** — 같은 집합이되 **weak 키** 테이블입니다. 여기에만 등록된 콜백은 다른 곳에서 붙들지 않으면 GC 대상이 됩니다.

약한 등록이 프리미티브이고, `:Callback`은 그 위에 "GC로부터 지켜주기"만 더한 것입니다. `:Set`은 두 테이블을 합쳐 순회하므로 발화 동작은 둘이 같습니다.

## `ref:Set(value)`

**시그니처**

```luau
Set: <Self>(self: Self, value: T) -> Self
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `value` | `T` | 새 값 |

**반환** — `self`.

**동작** — 순서가 계약입니다.

1. `.Value`를 먼저 확정합니다.
2. `.Revision`을 바꿉니다.
3. `Callbacks`와 `WeakCallbacks`를 **스냅샷으로 합쳐** 순회합니다. 순회 중 등록/해제를 해도 이번 순회는 흔들리지 않고, 순회 중 해제된 콜백은 건너뜁니다.

콜백이 순회 도중 다시 `:Set`을 부르면(재진입), 안쪽 순회가 이미 모두에게 더 새 값을 전달했으므로 **바깥 순회는 남은 콜백을 건너뛰고 멈춥니다** — 콜백이 낡은 값을 받는 일은 없습니다.

`thread` 키(= `:Wait` 대기자)는 소진되고 `Ref` 자신을 인자로 resume됩니다. 대기 중인 코루틴 자신이나 그 코루틴이 resume한 코루틴에서 `:Set`을 부르면 그 자리에서 던집니다.

- `Ref: cannot :Set from the coroutine that is waiting on this Ref, nor from one it resumed (Wait(thread) registered a {status} coroutine)`

**예제**

```luau
local ref = q.Ref(0)
ref:Callback(function(v) print("값", v) end) -- 등록 즉시 0으로 한 번 불린다
ref:Set(1):Set(2)                            -- 체이닝
```

## `ref:Callback(fn)`

**시그니처**

```luau
Callback: <Self>(self: Self, fn: RefCallback<T>) -> Self
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `fn` | `(value: T, ref: Ref<T>) -> ()` | 값이 바뀔 때 부를 함수 |

**반환** — `self`.

**동작**

- **등록하는 그 자리에서 한 번 즉시 호출됩니다** — 지금 담긴 값으로. 아직 비어 있으면 `nil`로 불립니다(nil 가드는 호출자 몫입니다).
- 콜백을 강하게 붙듭니다(`Callbacks`). 중복 등록은 집합 의미로 한 번입니다.
- 인자 검증: `Ref:Callback: callback must be a function (got {typeof(fn)})`.

## `ref:WeakCallback(fn)`

**시그니처**

```luau
WeakCallback: <Self>(self: Self, fn: RefCallback<T>) -> Self
```

**동작** — `:Callback`과 모든 동작이 같고, **GC 보호만 없습니다**(`WeakCallbacks`에 weak 키로 들어갑니다). 등록 즉시 한 번 호출되는 것도 같습니다.

콜백을 다른 곳에서 붙들고 있고 그 수명에 Ref 구독을 맞추고 싶을 때 씁니다. 인자 검증: `Ref:WeakCallback: callback must be a function (got {typeof(fn)})`.

## `ref:Uncallback(fn)`

**시그니처**

```luau
Uncallback: <Self>(self: Self, fn: RefCallback<T>) -> Self
```

**동작** — 등록을 해제합니다. **두 테이블 모두에서** 지웁니다 — 약하게 등록한 콜백도 이걸로만 뗄 수 있습니다.

등록이 집합이라 "몇 번 뗄지"를 셀 필요가 없습니다. 인자 검증: `Ref:Uncallback: callback must be a function (got {typeof(fn)})`.

## `ref:Wait(thread?)`

**시그니처**

```luau
Wait: <Self>(self: Self, thread: thread?) -> Self
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `thread` | `thread?` | 주면 **등록만** 하고 즉시 반환합니다. 생략하면 지금 코루틴을 등록하고 여기서 yield합니다 |

**반환** — `self`. 그래서 `ref:Wait().Value`가 갓 도착한 값을 읽는 관용구입니다.

**동작**

- **항상 다음 `:Set`을 기다립니다.** 이미 값이 차 있어도 기다립니다 — `Ref<T?>`에서는 `nil`도 정당한 값이라 "차 있는가"를 여기서 판정할 수 없기 때문입니다. 미리 확인하고 싶으면 `if ref.Value then … else ref:Wait().Value end` 관용구를 쓰세요.
- 인자 없이 부르려면 yield 가능한 코루틴 안이어야 합니다.
  - `Ref: Wait() must be called from a yieldable coroutine (pass a thread to register a waiter without yielding)`
- 명시적 `thread`를 주면 등록만 합니다 — 코루틴은 자기 자신만 멈출 수 있지 남의 코루틴을 대신 멈출 수 없기 때문입니다.
  - `Ref: Wait(thread) expects a thread (got {typeof(thread)})`
- 대기자는 `Callbacks`에 `thread` 키로 들어가고, `:Set`이 그 키를 소진하며 resume합니다. 중복 등록은 집합이라 무해합니다.

**예제**

```luau
local ref = q.Ref<<string?>>(nil)
task.spawn(function()
    local value = ref:Wait().Value -- 다음 :Set 까지 여기서 멈춘다
    print("도착", value)
end)
ref:Set("hello")
```

## `ref:Unwrap()`

**시그니처**

```luau
Unwrap: (self: Ref<T>) -> StripNil<T> -- StripNil은 T에서 nil 성분만 벗기는 타입 함수
```

**반환** — 담긴 값. 타입에서는 `nil`만 제거됩니다(`Frame?` → `Frame`).

**동작** — 숫자 키 자리에 놓은 `PreRef`는 이벤트 콜백이 돌기 전에 반드시 채워지는데, 타입은 여전히 `Ref<Frame?>`라 매번 `if inst then` 가드를 써야 했습니다. `:Unwrap()`은 그 자리를 위한 것입니다.

**규약이지 강제가 아닙니다** — 런타임 보장이 있는 자리에서만 쓰세요. 비어 있으면 호출한 줄을 blame하며 던집니다.

- `Ref:Unwrap: the Ref is empty (Value is nil) — not filled yet, or never placed`

`Ref`/`PreRef`/`PostRef` 셋 다 같은 동작입니다.

**예제**

```luau
local btnRef = q.PreRef<<TextButton?>>(nil)
local button = D.TextButton {
    btnRef,
    Text = "보내기",
    Activated = function()
        btnRef:Unwrap().BackgroundTransparency = 0.5 -- 가드 없이
    end,
}
```

**관련** — [디버깅과 문제 해결](/how-to/09-debugging-and-troubleshooting/)
