---
title: "생명주기 훅"
description: "OnCreated / OnRendered / OnDestroyed — 각 훅이 불리는 시점과 보장하지 않는 것"
---
요소의 생명주기에 콜백을 다는 **순수 팩토리** 셋입니다. 새 브랜드도, 새 디스패치 개념도 없습니다 — 돌려주는 값은 각각 `PreRef` / `PostRef` / `EffectHandle` 그 자체이고, 숫자 키 자리에 그대로 놓입니다.

이 페이지의 심볼: [`q.OnCreated<<I>>(fn)`](#qoncreatedifn) · [`q.OnRendered<<I>>(fn)`](#qonrenderedifn) · [`q.OnDestroyed(fn)`](#qondestroyedfn)

`quad-base`에 있으므로 백엔드와 무관하게 존재합니다.

```luau
-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 참고)
local Quad = require(<quad-base 모듈 경로>)
local QuadRoblox = require(<quad-roblox 모듈 경로>).QuadRoblox
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
local D = q.D
```

---

## 공통 계약

| 훅 | 반환 | 불리는 시점 |
|---|---|---|
| `OnCreated(fn)` | `PreRef<I?>` | 인스턴스가 만들어진 직후, 이 인스턴스에 아무 일도 일어나기 전 |
| `OnRendered(fn)` | `PostRef<I?>` | 이 인스턴스의 children(과 그 서브트리 전체)·프로퍼티·이벤트가 **전부 세팅된 뒤** |
| `OnDestroyed(fn)` | `EffectHandle` | 묶인 인스턴스가 죽을 때 정확히 1회(설치 시점에는 안 돈다) |

- 셋 다 **숫자 키 자리**(문자 키가 아닙니다)에 놓습니다.
- **여러 번 등록하는 것은 그냥 숫자 키 자리를 여러 개 쓰는 일**이고, 같은 종류끼리의 상대 순서는 숫자 키 순서(1부터)입니다. 종류가 섞여 있어도 `OnCreated`들이 먼저, `OnRendered`들이 마지막입니다.
- `OnCreated`/`OnRendered`의 콜백은 `(inst, ref)` 두 인자를 받고, **`inst`는 항상 non-nil**입니다 — 등록 시점의 `nil` 호출은 내부 가드가 걸러냅니다.
- `fn`이 함수가 아니면 그 줄에서 던집니다: `OnCreated: fn must be a function (got number)`(이름 자리는 훅마다 바뀝니다).

### 요소 타입은 명시적 타입 인자로 줄 것

`q.OnCreated<<Frame>>(function(inst) … end)` 형태를 쓰십시오. `quad-base`는 백엔드의 요소 타입을 모르므로 `I`가 제네릭 자리인데, 콜백 파라미터에 주석을 다는 형태(`function(inst: Frame)`)로는 그 자리가 채워지지 않습니다 — 신 솔버에서 이렇게 죽습니다.

```
TypeError: Type functions do not currently support types of the form '*error-type*'
```

---

## `q.OnCreated<<I>>(fn)`

**시그니처**

```luau
OnCreated: <I>(fn: (inst: I, ref: PreRef<I?>) -> ()) -> PreRef<I?>
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `fn` | `(inst: I, ref: PreRef<I?>) -> ()` | 인스턴스와 그 `PreRef`를 받는다 |

**반환** — `PreRef<I?>`. 그 자체가 `PreRef`이므로 `q.isPreRef`가 참이고, `PreRef`가 하는 일(pre-pass에서 채워짐)을 그대로 합니다.

**동작** — 프로퍼티·자식·이벤트 어느 것보다 **먼저** 불립니다. 그래서 인스턴스가 아직 아무것도 설정되지 않은 상태로 넘어옵니다 — 초기 상태를 바꾸거나 바깥 레지스트리에 등록하는 자리입니다.

## `q.OnRendered<<I>>(fn)`

**시그니처**

```luau
OnRendered: <I>(fn: (inst: I, ref: PostRef<I?>) -> ()) -> PostRef<I?>
```

**반환** — `PostRef<I?>`.

**동작** — 자기 서브트리가 완성된 뒤 불립니다. 자식 인스턴스들이 이미 붙어 있으므로, 자식을 세거나 자기 아래를 훑는 작업이 여기서 안전합니다.

:::caution
**부모에 붙었음을 보장하지 않습니다.** `PostRef`가 보장하는 것은 **자기 아래**(서브트리)의 완성이지 자기 위(조상 체인)가 아닙니다. 리터럴 중첩으로 만들어졌다면 아직 부모가 없을 수 있고, `Claim`이나 미리 세팅된 `.Parent`로 왔다면 이미 붙어 있을 수 있습니다 — 어느 쪽도 보장하지 않습니다. 그리고 **그 뒤로 `Parent`가 바뀌지 않을 수도 있습니다**(`Claim`이 그렇습니다) — 이 훅 뒤에 `Parent` 변경을 기다리는 코드를 짜면 한 번도 안 돌 수 있습니다.

React의 `componentDidMount`가 DOM 삽입 *뒤*인 것과 다르므로 "화면에 올라간 뒤"라고 기대하지 마십시오. 화면 좌표·`AbsoluteSize` 같은 조상 의존 값을 여기서 읽으면 안 됩니다.
:::

## `q.OnDestroyed(fn)`

**시그니처**

```luau
OnDestroyed: (fn: () -> ()) -> EffectHandle
```

**인자** — `fn`(인자 없는 정리 함수). **반환** — `EffectHandle`.

**동작** — 등록 시점에는 `fn`이 돌지 않습니다. 묶인 인스턴스가 죽을 때 정확히 한 번 돌고, 그 뒤에 바인딩을 풀어도 다시 돌지 않습니다. 숫자 키 자리에 놓으면 그 인스턴스에 묶입니다.

제네릭 자리가 없습니다 — 콜백이 인스턴스를 받지 않기 때문입니다.

---

## 예제

```luau
local function AnimatedBox(): Frame
    return D.Frame {
        Size = UDim2.fromOffset(100, 100),

        q.OnCreated<<Frame>>(function(inst)
            print("생성됨:", inst.ClassName)
        end),

        q.OnRendered<<Frame>>(function(inst)
            print("자기 서브트리 완성:", inst.Size)
        end),

        q.OnDestroyed(function()
            print("파괴 및 정리됨")
        end),
    }
end
```

---

## 관련

- [Ref](/reference/core/07-ref/) — 이 훅들이 얹혀 있는 `PreRef`/`PostRef` 프리미티브
- [네트워크·입력 브리지](/how-to/04-network-and-input-bridge/) — 바깥 연결을 만들고 `OnDestroyed`로 끊는 배치
- [Studio UI 바인딩과 Claim](/how-to/07-studio-ui-binding-and-claim/)
