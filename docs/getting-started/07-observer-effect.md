---
title: "07. 관측하기 — Observer와 Effect"
description: "값이 바뀔 때 화면 밖에서 무언가 하는 Observer와, 의존성 여럿·cleanup을 다루는 Effect를 숫자 키 자리에 답니다"
---
# [시작하기] 07. 관측하기 — `Observer`와 `Effect`

> **대상 독자**: [06. 인스턴스를 손에 쥐기](./06-ref.md)를 끝낸 개발자
> **목표**: 값이 바뀔 때 화면 밖에서 무언가 하고, 뒤처리가 필요한 일까지 붙이기

지금까지 값이 흘러가 닿는 곳은 **프로퍼티**뿐이었습니다. 그런데 값이 바뀔 때
로그를 찍거나, 소리를 내거나, 서버로 보내야 할 때가 있습니다. 화면 밖으로 나가는
이 두 길이 `Observer`와 `Effect`입니다.

---

## 1. 값이 바뀔 때 화면 밖에서 — `:Observer`

`:Observer(fn)`은 **한 노드를 관측**합니다. 라벨의 숫자 키 자리에 한 덩이를 더합니다.

```luau
    -- … card 안의 라벨에 이어집니다
    D.TextLabel {
        -- …프로퍼티 생략…
        Text = countText,

        -- 숫자 키: 이 라벨이 살아 있는 동안 count를 관측한다
        count:Observer(function(target)
            print("카운트가", target:Get(), "가 되었습니다")
        end),
    },
```

**실행하면** 만들어지는 즉시 한 줄이 찍히고, 그 뒤로 버튼을 누를 때마다 한 줄씩 더 찍힙니다. 콜백이 받는 것은 값이 아니라 관측 대상의 핸들이라 `target:Get()`으로 읽습니다 — `:Compute`와 같습니다.

<details>
<summary><strong>숫자 키 자리에 안 넣으면 어떻게 되나요?</strong></summary>

**`:Observer(fn)`은 등록하는 그 자리에서 한 번 발화하고, 그 뒤로는 조용합니다.** 이후 변경까지 받으려면 **살아나야** 하는데, 경로가 둘입니다.

1. **인스턴스에 묶는 것** — props의 숫자 키 자리에 넣으면 quad가 묶어 줍니다. 그 인스턴스가 사는 동안만 살고, 인스턴스가 파괴되면 **관측이 멈춥니다**. UI에 딸린 관측은 대개 이쪽입니다.
2. **전역 구독** — `:Subscribe()`(강한 유지) 또는 `:WeakSubscribe()`(약한 유지). 인스턴스와 무관하게 사는 구독입니다.

어느 쪽도 하지 않으면 등록 시 한 번이 전부입니다.

```luau
-- 어디에도 묶지 않으면 등록 시 한 번뿐이다
const lonely = count:Observer(function(target)
    print("이건 한 번만 찍힙니다", target:Get())
end)

count:Set(99) -- lonely는 발화하지 않는다(보류)
```

묶이기 전에 일어난 변경은 버려지는 게 아니라 **보류**돼 있다가, 살아나는 순간 최신값으로 정확히 한 번 재생됩니다. 이 보류와 재생이 왜 그렇게 설계됐는지는 [17장](./17-laziness.md)에서 다룹니다.

</details>
<!-- mock 실측 2026-09-11: gs.refprobe2.luau L1 — 라벨을 Destroy한 뒤 :Set(2)는 안 찍힌다(로그 0,1) -->

관측이 그 인스턴스와 함께 산다는 것은, **인스턴스를 파괴하면 그 자리에서 멈춘다**는 뜻이기도 합니다. 라벨을 `Destroy()`한 뒤에 `count:Set(2)`을 해도 그 줄은 더 이상 찍히지 않습니다.

<details>
<summary><strong>관측을 도중에 끄려면요?</strong></summary>

인스턴스를 파괴하지 않고 관측만 떼고 싶을 때가 있습니다. 숫자 키 자리에는 자식 인스턴스만 오는 게 아니라 **그 자리를 State로 잡아 둘 수도** 있어서, 관측 핸들 자체를 `Source`에 담아 놓으면 그 자리를 갈아 끼우는 것으로 끄고 켤 수 있습니다.

```luau
-- 관측 핸들을 State에 담아 자리에 놓는다
const logger = q.Source<<q.Observer?>>(count:Observer(function(t)
    print("카운트", t:Get())
end))

const card = D.Frame {
    logger,
    -- …자식들 생략…
}

logger:Set(nil)     -- 이 시점부터 위 print는 더 이상 돌지 않는다
```

**실행하면** `logger:Set(nil)` 전까지는 `count`가 바뀔 때마다 찍히고, 그 뒤로는 조용합니다.

`q.Observer` 타입은 [01장](./01-setup.md) 설정 모듈의 `export type Observer = QuadTypes.Observer` 줄에서 옵니다.

자리 하나를 State로 잡아 두고 갈아 끼우는 **같은 원리**가 [10장](./10-slot.md)에서는 자식 인스턴스에도 쓰입니다. 다만 이건 "이렇게도 된다"에 가깝지 강하게 권하는 패턴은 아닙니다 — 관측을 껐다 켤 일이 정말 있을 때만 쓰세요.

</details>
<!-- mock 실측 2026-09-11: gs.refprobe.luau H1/H2 — 로그 0,1,2 뒤 Set(nil)하면 Set(3)은 안 찍힌다 -->

---

## 2. 정리가 필요한 일 — `q.Effect`

`Observer`는 "한 노드가 바뀌었다"만 알려 줍니다. 의존성이 **여럿**이거나, 매번 **뒤처리**가 필요하면 `q.Effect(fn, ...deps)`를 씁니다.

`card`의 숫자 키 자리에 한 덩이를 더합니다.

```luau
    -- … card의 숫자 키 자리에 이어집니다
    q.Effect(function()
        const n = count:Get()
        print("이펙트: 지금", n)

        return function()             -- ← 이 함수가 cleanup
            print("정리:", n, "회차의 뒤처리")
        end
    end, count),
```

**실행하면** 만들어지는 즉시 `이펙트: 지금 0`이 찍힙니다. 버튼을 한 번 누르면 **먼저 `정리: 0회차`가 찍힌 뒤** `이펙트: 지금 1`이 이어집니다 — 다음 실행 직전에 직전 회차의 뒤처리가 도는 것입니다. 그리고 카드를 `Destroy()`하면 `정리: 1회차`가 한 번 더 찍히고 **끝납니다.** 그 뒤로는 `count`를 아무리 바꿔도 이 이펙트는 조용합니다.
<!-- mock 실측 2026-09-11: gs.gs2probe.luau 2a~2d — run0 / run0,clean0,run1 / +clean1 / 이후 Set에 변화 없음 -->
<!-- mock 실측 2026-09-11: gs.effectswap.luau — State<EffectHandle?> 자리를 B로 갈아 끼우면 A cleanup이 한 번 돈다(A run0/clean/run1 → swap → B run1, A cleanup → …) — 넷째 자리 -->

`Observer`와 갈리는 지점은 셋입니다.

- **의존성을 여럿 겁니다** — `q.Effect(fn, a, b, c)`. 어느 하나가 움직여도 다시 돕니다. `State`/`Source`뿐 아니라 **`Ref`도 의존성 자리에 놓을 수 있습니다**(바로 아래가 그 예입니다).
- **값이 인자로 오지 않습니다** — 클로저로 `count:Get()`을 직접 읽습니다(`fn`이 받는 인자는 핸들 자신 하나뿐입니다).
- **cleanup을 돌려줄 수 있습니다** — 도는 자리는 넷입니다. **다음 실행 직전**, **`:Unsubscribe()`로 강한 구독을 끊을 때**, **매달린 인스턴스가 파괴될 때**, 그리고 **그 숫자 키 자리를 다른 값으로 갈아 끼울 때**(1절 접힘에서 본 것처럼 자리를 `State`로 잡아 뒀다가 바꾸는 경우)이고, 그때마다 정확히 한 번입니다(약하게 풀어 주는 `:WeakUnsubscribe()`는 cleanup을 건드리지 않습니다).

`Observer`와 마찬가지로 **숫자 키 자리에 넣어야 계속 삽니다.** 넣지 않으면 만들 때 한 번 돌고 조용해집니다.

---

## 3. `Ref`를 의존성으로 걸기

`Effect`의 의존성 자리에 [06장](./06-ref.md)의 `Ref`를 같이 걸면 **"이 상자가 채워졌을 때"와 "이 값이 바뀌었을 때"를 한 함수에서** 다룰 수 있습니다.

카운트가 10 이상이면 버튼 색을 바꿔 보겠습니다. 상자는 06장 3절과 같은 평범한 `Ref`입니다.

```luau
-- … 위쪽 코드에 이어집니다
const buttonRef = q.Ref<<TextButton?>>(nil)

const card = D.Frame {
    -- …생략…
    D.TextButton {
        buttonRef,
        Text = "+ 1",
        BackgroundColor3 = Color3.fromRGB(0, 162, 255),
        Activated = function()
            count:Set(count:Get() + 1)
        end,
    },

    -- 숫자 키: 버튼 뒤에 놓는다
    q.Effect(function()
        const inst = buttonRef.Value
        if inst then
            inst.BackgroundColor3 = if count:Get() >= 10
                then Color3.fromRGB(255, 190, 0)
                else Color3.fromRGB(0, 162, 255)
        end
    end, count, buttonRef),
}
```

**실행하면** 버튼이 파란색으로 시작해서, 카운트가 10이 되는 순간 노란색으로 바뀌고, 다시 10 아래로 내려가면 파란색으로 돌아옵니다.
<!-- mock 실측 2026-09-11: gs.gs2probe.luau 6a/6b/6c — (0,162,255) → 10에서 (255,190,0) → 3으로 내리면 다시 (0,162,255) -->

<details>
<summary><strong>이 <code>Effect</code>는 <code>buttonRef</code>가 차기 전에 도는 것 아닌가요?</strong></summary>

여기서는 아닙니다. Lua는 테이블 리터럴의 원소를 **위에서 아래로** 평가하므로, `D.TextButton { buttonRef, … }`가 먼저 실행되어 버튼이 만들어지고 `buttonRef`가 채워진 다음에야 `q.Effect(...)`가 만들어집니다. `Effect`의 첫 실행은 만들어지는 그 자리에서 돌기 때문에, 그때 이미 상자에 값이 있습니다.

바꿔 말하면 **순서를 뒤집으면 첫 실행이 빈 상자를 봅니다**(그래서 위 코드에 `if inst then` 가드가 있습니다). 그 뒤 상자가 채워지면 `Ref`가 의존성이므로 `Effect`는 어차피 한 번 더 돕니다 — 다만 그때까지의 한 사이클은 아무 일도 안 한 셈이 됩니다.

순서에 기대고 싶지 않다면 `q.PreRef`를 쓰세요. 숫자 키 위치와 무관하게 가장 먼저 채워지므로 첫 실행부터 값이 있습니다.

</details>
<!-- mock 실측 2026-09-11: gs.gs5probe.luau R1/R3 — Effect를 버튼 앞에 두면 첫 실행이 empty, 상자가 채워지며 has로 한 번 더 돈다 -->

이 `Effect`처럼 **"어떤 Ref와 어떤 State를 묶어 이런 일을 한다"를 함수 하나로 이름 붙여 재사용**할 수 있습니다. 그 모양은 [12장](./12-functions.md)에서 한꺼번에 다룹니다.

---

## 더 알고 싶다면

- [레퍼런스: `Observer` / `Effect`](../reference/core/05-observer-effect.md) — 구독 네 진입점, 보류와 재생, cleanup이 도는 네 자리
- [레퍼런스: 생명주기 훅](../reference/sugar/04-lifecycle-hooks.md) — `q.OnCreated`/`q.OnRendered`/`q.OnDestroyed`(`Ref`/`Effect` 위에 얹은 슈거)
- [04. 외부 신호를 상태로 들여오기](../how-to/04-network-and-input-bridge.md) — `Effect`의 cleanup으로 엔진 연결을 끊는 실전 배치
