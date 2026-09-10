---
title: "06. 인스턴스를 손에 쥐기와 부수 효과 — Ref와 Effect"
description: "만들어진 인스턴스를 Ref로 꺼내 쓰고, 의존성 여럿과 cleanup을 다루는 Effect를 배열 부분에 답니다"
---
# [시작하기] 06. 인스턴스를 손에 쥐기와 부수 효과 — `Ref`와 `Effect`

> **대상 독자**: [05. 이름표와 속성](./05-tag-attr.md)을 끝낸 개발자
> **목표**: 만들어진 인스턴스를 변수로 잡고, 값이 바뀔 때 정리까지 필요한 일을 붙이기

지금까지 화면에 무언가를 반영하는 길은 프로퍼티와 표시(태그·속성)였습니다.
이 장에서는 그 바깥의 두 가지를 배웁니다. **만들어진 인스턴스를 손에 쥐는 `Ref`**와
**정리(cleanup)가 필요한 부수 효과를 다루는 `Effect`**입니다.

---

## 1. 인스턴스를 잡아 두기 — `q.Ref`

`Ref`는 **빈 상자**입니다. props의 배열 부분에 놓아 두면 quad가 만들어진 인스턴스를 그 상자에 넣어 줍니다.

카드의 버튼에 상자를 하나 놓습니다.

```luau
const buttonRef = q.Ref(nil :: TextButton?)

const card = D.Frame {
    -- …생략…
    D.TextButton {
        buttonRef,                  -- ← 배열 부분: 만들어진 버튼이 여기 담긴다
        Text = "+ 1",
        Activated = function()
            count:Set(count:Get() + 1)
        end,
    },
}

print(buttonRef.Value.ClassName) --> "TextButton"
```

**실행하면** 출력 창에 `TextButton`이 찍힙니다.

**채워지는 시점은 "그 배열 자리가 처리될 때"입니다.** 위 예제에서는 `D.TextButton { ... }`이 만들어지는 그 순간이고, 그래서 `card`가 완성된 뒤에는 이미 들어 있습니다. 그 자리가 철거될 때는 다시 `nil`로 돌아갑니다.

<details>
<summary><strong>그럼 <code>ref.Value</code>가 비어 있을 때도 있나요?</strong></summary>

있습니다 — 만든 직후부터 그 배열 자리가 처리되기 전까지, 그리고 철거된 뒤가 그렇습니다. 그래서 `q.Ref(nil :: TextButton?)`처럼 **초깃값에 `nil`을 넣고 타입을 넓혀** 두는 것이 관례입니다.

런타임 보장이 있는 자리(예: 이벤트 콜백 안 — 그때는 이미 채워져 있습니다)에서 매번 `if inst then` 가드를 쓰기 번거로우면 `ref:Unwrap()`이 있습니다. 담긴 값을 돌려주되 타입에서 `nil`만 벗겨 주고, 정말 비어 있으면 부른 줄을 blame하며 던집니다.

```luau
Activated = function()
    buttonRef:Unwrap().BackgroundTransparency = 0.5 -- 가드 없이
end,
```

그리고 **하나의 `Ref`는 한 자리에만 놓습니다.** 같은 `Ref`를 두 인스턴스에 놓으면 그 자리에서 던집니다(`bindLifetime: value is already bound to another Instance`) — 인스턴스마다 새로 만드세요.

</details>

---

## 2. 정리가 필요한 일 — `q.Effect`

`Observer`는 "한 노드가 바뀌었다"만 알려 줍니다. 의존성이 **여럿**이거나, 매번 **뒤처리**가 필요하면 `q.Effect(fn, ...deps)`를 씁니다.

`card`의 배열 부분에 한 덩이를 더합니다.

```luau
    q.Effect(function()
        const n = count:Get()
        print("이펙트: 지금", n)

        return function()             -- ← 이 함수가 cleanup
            print("정리:", n, "회차의 뒤처리")
        end
    end, count),
```

**실행하면** 만들어지는 즉시 `이펙트: 지금 0`이 찍히고, 버튼을 누를 때마다 **먼저 직전 회차의 `정리:`가 찍힌 뒤** 새 `이펙트:`가 찍힙니다. 카드를 `Destroy()`하면 마지막 `정리:`가 한 번 더 찍히고 끝납니다.

`Observer`와 갈리는 지점은 셋입니다.

- **의존성을 여럿 겁니다** — `q.Effect(fn, a, b, c)`. 어느 하나가 움직여도 다시 돕니다.
- **값이 인자로 오지 않습니다** — 클로저로 `count:Get()`을 직접 읽습니다(`fn`이 받는 인자는 핸들 자신 하나뿐입니다).
- **cleanup을 돌려줄 수 있습니다** — 다음 실행 직전, 구독 해제, 그리고 매달린 인스턴스가 파괴될 때 정확히 한 번 돕니다.

`Observer`와 마찬가지로 **배열 부분에 넣어야 계속 삽니다.** 넣지 않으면 만들 때 한 번 돌고 조용해집니다.

---

## 3. 팩토리로 묶기

`Ref`·`Effect`·`Observer`는 전부 **값**이라, 그것을 만들어 돌려주는 함수를 따로 둘 수 있습니다. 반응형 로직에 이름을 붙여 재사용하는 정본 모양입니다.

```luau
-- "이 Ref가 가리키는 버튼의 색을 이 State에 맞춰 바꾼다"를 함수 하나로
local function highlightWhenBig(ref, state, threshold)
    return q.Effect(function()
        const inst = ref.Value
        if inst then
            inst.BackgroundColor3 = if state:Get() >= threshold
                then Color3.fromRGB(255, 190, 0)
                else Color3.fromRGB(0, 162, 255)
        end
    end, state, ref)
end
```

쓰는 쪽은 **그 호출을 배열 부분에 놓습니다.**

```luau
const card = D.Frame {
    -- …생략…
    D.TextButton { buttonRef, Text = "+ 1", Activated = … },

    highlightWhenBig(buttonRef, count, 10),   -- ← 배열 부분
}
```

**실행하면** 카운트가 10 이상이 될 때 버튼이 노란색으로 바뀝니다.

<details>
<summary><strong>이 <code>Effect</code>는 <code>buttonRef</code>가 차기 전에 도는 것 아닌가요?</strong></summary>

여기서는 아닙니다. Lua는 테이블 리터럴의 원소를 **위에서 아래로** 평가하므로, `D.TextButton { buttonRef, … }`가 먼저 실행되어 버튼이 만들어지고 `buttonRef`가 채워진 다음에야 `highlightWhenBig(...)`이 불립니다. `q.Effect`의 첫 실행은 만들어지는 그 자리에서 도니까, 그때 이미 상자에 값이 있습니다.

바꿔 말하면 **순서를 뒤집으면 첫 실행이 빈 상자를 봅니다**(그래서 위 팩토리에 `if inst then` 가드가 있습니다). 순서에 기대고 싶지 않거나, **그 인스턴스 자신**을 같은 props 테이블 안에서 읽어야 한다면 `q.PreRef`를 쓰세요 — 배열 위치와 무관하게 다른 어떤 처리보다 먼저 채워집니다. 반대로 자식과 프로퍼티가 전부 끝난 뒤 채워지는 `q.PostRef`도 있습니다. 셋의 발화 시점은 [레퍼런스: `Ref`](../reference/core/08-ref.md)가 정리해 두었습니다.

</details>

React의 Hook과 달리 이런 함수는 **호출 위치에 규칙이 없습니다.** 조건문 안에서도, 루프 안에서도, 이름이 `use`로 시작하지 않아도 됩니다 — 컴포넌트가 매 프레임 다시 실행되지 않는 **1회성 셋업 함수**이기 때문입니다.

---

## 더 알고 싶다면

- [레퍼런스: `Ref`](../reference/core/08-ref.md) — `PreRef`/`PostRef`의 발화 시점, `:Callback`/`:Wait`/`:Unwrap`
- [레퍼런스: `Observer` / `Effect`](../reference/core/05-observer-effect.md) — 구독 네 진입점, cleanup이 도는 세 자리
- [레퍼런스: 생명주기 훅](../reference/sugar/04-lifecycle-hooks.md) — `q.OnCreated`/`q.OnRendered`/`q.OnDestroyed`(위 셋 위에 얹은 슈거)
- [04. 외부 신호를 상태로 들여오기](../how-to/04-network-and-input-bridge.md) — `Effect`의 cleanup으로 엔진 연결을 끊는 실전 배치
