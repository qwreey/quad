---
title: "07. 관측하기 — Observer와 Effect"
description: "값이 바뀔 때 화면 밖에서 무언가 하는 Observer와 Effect를 숫자 키 자리에 달고, 화면 안쪽은 값으로 표현한다는 경계를 잡습니다"
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

- **의존성을 여럿 겁니다** — `q.Effect(fn, a, b, c)`. 어느 하나가 움직여도 다시 돕니다. `State`/`Source`뿐 아니라 **`Ref`도 의존성 자리에 놓을 수 있습니다**(4절이 그 예입니다).
- **값이 인자로 오지 않습니다** — 클로저로 `count:Get()`을 직접 읽습니다(`fn`이 받는 인자는 핸들 자신 하나뿐입니다).
- **cleanup을 돌려줄 수 있습니다** — 도는 자리는 넷이고, 넷 각각에서 정확히 한 번씩 돕니다.
  - 다음 실행 직전
  - `:Unsubscribe()`로 강한 구독을 끊을 때
  - 매달린 인스턴스가 파괴될 때
  - 그 숫자 키 자리를 다른 값으로 갈아 끼울 때(1절 접힘처럼 자리를 `State`로 잡아 뒀다가 바꾸는 경우)

  약하게 풀어 주는 `:WeakUnsubscribe()`는 cleanup을 건드리지 않습니다.

`Observer`와 마찬가지로 **숫자 키 자리에 넣어야 계속 삽니다.** 넣지 않으면 만들 때 한 번 돌고 조용해집니다.

---

## 3. 화면 안쪽을 바꾸고 싶다면 — `Effect`가 아니라 값으로

앞의 두 절이 세운 규칙은 "`Observer`와 `Effect`는 **화면 밖으로 나가는 길**"이었습니다. 그래서 "카운트가 10 이상이면 버튼을 노란색으로"처럼 **화면 안쪽**을 바꾸는 일은 이 둘의 일이 아닙니다. 그건 [03장](./03-flowing-values.md)에서 이미 배운 파이프의 일입니다.

버튼의 `BackgroundColor3`에 색 리터럴 대신 파이프를 꽂습니다.

```luau
-- … card 안의 버튼을 이렇게 고칩니다
    D.TextButton {
        Text = "+ 1",
        BackgroundColor3 = count:Compute(function(c)
            return if c:Get() >= 10
                then Color3.fromRGB(255, 190, 0)
                else Color3.fromRGB(0, 162, 255)
        end),
        Activated = function()
            count:Set(count:Get() + 1)
        end,
    },
```

**실행하면** 버튼이 파란색으로 시작해서, 카운트가 10이 되는 순간 노란색으로 바뀌고, 다시 10 아래로 내려가면 파란색으로 돌아옵니다.
<!-- mock 실측 2026-09-11: gs.polish2.luau "07 §3" — (0,162,255) → 10에서 (255,190,0) → 3으로 내리면 다시 (0,162,255) -->

화면에 보이는 것은 **값이 흘러 닿는 프로퍼티**로 적는 것이 quad의 기본입니다. 같은 일을 `Effect` 안에서 `inst.BackgroundColor3 = …`로 적으면 세 가지가 어긋납니다.

- **한 프로퍼티에 주인이 둘이 됩니다.** 같은 프로퍼티에 이미 State가 꽂혀 있으면 파이프가 값을 쓰고 `Effect`가 그 위에 또 쓰고, 다음 변경에 다시 뒤집힙니다. quad는 그 손쓰기를 모릅니다. [06장](./06-ref.md) 2절이 `Activated` 안에서 `BackgroundTransparency`를 손으로 쓴 것은, 그 프로퍼티에 `State`가 꽂혀 있지 않아 다시 쓸 주인이 없기 때문입니다(정적 리터럴 `BackgroundTransparency = 0`은 한 번 쓰이고 끝입니다).
- **되돌릴 방법이 없습니다.** 조건이 풀렸을 때 원래 색으로 돌려놓는 일까지 직접 적어야 합니다. 파이프는 조건이 풀리면 그냥 다른 값을 흘려보냅니다.
- **이 장의 규칙을 스스로 깹니다.** `Effect`가 화면 밖으로 나가는 길이라는 약속이 흐려집니다.

정리하면 **계속 바뀌는 값**은 파이프로 꽂고, **한 번 일으키는 동작**은 그 자리에서 손으로 써도 됩니다. 계속 바뀌는 값을 `Effect`로 미는 것이 이 절이 말리는 모양입니다.

<details>
<summary><strong>그럼 <code>Effect</code>는 언제 쓰나요?</strong></summary>

**quad 바깥에 있는 것에 손댈 때**입니다 — 엔진 서비스에 연결하고, 타이머를 걸고, 다른 시스템에 자기를 등록하는 일. 이런 일은 끝날 때 **되돌려야 하고**, `Effect`에 cleanup이 있는 이유가 바로 그것입니다. 바로 아래 4절이 그 모양이고, [08장](./08-lifecycle-hooks.md)이 그 위에 이름 붙은 훅을 얹습니다. 엔진 연결을 걸고 끊는 실전 배치는 [04. RemoteEvent와 엔진 입력을 상태로 브릿징하기](../how-to/04-network-and-input-bridge.md)에 있습니다.

</details>

---

## 4. `Ref`를 의존성으로 걸기

`Effect`의 의존성 자리에 [06장](./06-ref.md)의 `Ref`를 같이 걸면 **"이 상자가 채워졌을 때"와 "이 값이 바뀌었을 때"를 한 함수에서** 다룰 수 있습니다.

바깥으로 나가는 일 하나를 붙여 보겠습니다 — 카운트가 10 이상인 동안 **게임패드 선택**(`GuiService.SelectedObject`)을 이 버튼에 두는 것입니다. 선택을 걸었으면 조건이 풀릴 때 **풀어 줘야** 하므로 cleanup이 필요한 일이고, 대상이 인스턴스라 `Ref`가 필요합니다. 상자는 06장 1절과 같은 평범한 `Ref`입니다.

```luau
-- … 위쪽 코드에 이어집니다
const GuiService = game:GetService("GuiService")
const buttonRef = q.Ref<<TextButton?>>(nil)
const isBig = count:Compute(function(c) return c:Get() >= 10 end)

const card = D.Frame {
    -- …생략…
    D.TextButton {
        buttonRef,                                  -- ← 06장과 같은 평범한 Ref(인스턴스마다 새로 만든다)
        Text = "+ 1",
        -- …3절의 BackgroundColor3 파이프는 그대로 둡니다…
        Activated = function() count:Set(count:Get() + 1) end,
    },

    -- 숫자 키: 카운트가 10 이상인 동안 게임패드 선택을 이 버튼에 둔다
    q.Effect(function()
        const inst = buttonRef.Value
        if inst and isBig:Get() then
            GuiService.SelectedObject = inst

            return function()                       -- ← 되돌리기
                if GuiService.SelectedObject == inst then
                    GuiService.SelectedObject = nil
                end
            end
        end
        return nil
    end, isBig, buttonRef),
}
```

**실행하면** 카운트가 10이 되는 순간 게임패드 선택이 이 버튼으로 옮겨 오고, 10 아래로 내려가면 cleanup이 돌아 선택이 풀립니다. 선택이 걸려 있는 채로 카드를 `Destroy()`해도 cleanup이 한 번 돌아, 사라진 버튼이 선택된 채로 남지 않습니다.
<!-- mock 실측 2026-09-11: GuiService를 { SelectedObject = nil } 셰임으로 대체 — count를 의존성으로 건 판에서 10에서 select, 11에서 cleanup 뒤 다시 select, 3에서 unselect, 파괴 때 unselect. Studio 실측은 사람 몫 -->
<!-- mock 실측 2026-09-11: gs.polish2.luau "07 §4" — isBig 의존 버전: 1에서 run(false) 다시(파이프는 값이 같아도 통지를 내려보낸다), 10에서 select, 11에서 unselect 뒤 다시 select, 3에서 unselect, 12에서 select 뒤 Destroy로 unselect -->

의존성 자리에 `count`를 그대로 걸 수도 있었습니다. 그런데 이 `Effect`가 정말 신경 쓰는 것은 카운트 숫자가 아니라 **10을 넘었는가**입니다. 그래서 그 판정을 `isBig` 한 줄로 먼저 만들어 두고 그것을 겁니다 — **의존성은 값 자체가 아니라 "바뀌었을 때 다시 돌아야 하는 것"으로 고릅니다.** 같은 자리에 `count`를 걸어도 화면 결과는 같지만, 의도가 코드에 남지 않습니다. 다만 도는 횟수까지 줄지는 않습니다 — 파이프는 계산 결과가 같아도 통지를 내려보내므로, 10에서 11로 갈 때도 cleanup이 돌고 곧바로 다시 선택합니다(눈에는 안 보이는 한 사이클입니다).

<details>
<summary><strong>이 <code>Effect</code>는 <code>buttonRef</code>가 차기 전에 도는 것 아닌가요?</strong></summary>

여기서는 아닙니다. Lua는 테이블 리터럴의 원소를 **위에서 아래로** 평가하므로, `D.TextButton { buttonRef, … }`가 먼저 실행되어 버튼이 만들어지고 `buttonRef`가 채워진 다음에야 `q.Effect(...)`가 만들어집니다. `Effect`의 첫 실행은 만들어지는 그 자리에서 돌기 때문에, 그때 이미 상자에 값이 있습니다.

바꿔 말하면 **순서를 뒤집으면 첫 실행이 빈 상자를 봅니다**(그래서 위 코드에 `if inst and …` 가드가 있습니다). 그 뒤 상자가 채워지면 `Ref`가 의존성이므로 `Effect`는 어차피 한 번 더 돕니다 — 다만 그때까지의 한 사이클은 아무 일도 안 한 셈이 됩니다.

순서에 기대고 싶지 않다면 `q.PreRef`를 쓰세요. 숫자 키 위치와 무관하게 가장 먼저 채워지므로 첫 실행부터 값이 있습니다.

</details>
<!-- mock 실측 2026-09-11: gs.gs5probe.luau R1/R3 — Effect를 버튼 앞에 두면 첫 실행이 empty, 상자가 채워지며 has로 한 번 더 돈다 -->

이 `Effect`처럼 **"어떤 Ref와 어떤 State를 묶어 이런 일을 한다"를 함수 하나로 이름 붙여 재사용**할 수 있고, 컴포넌트를 쓰기 시작하면 그 함수를 **컴포넌트에 넘겨** 안쪽 상태에 붙이게도 됩니다. 그 모양은 [12장](./12-functions.md)에서 한꺼번에 다룹니다.

---

## 더 알고 싶다면

- [레퍼런스: `Observer` / `Effect`](../reference/core/05-observer-effect.md) — 구독 네 진입점, 보류와 재생, cleanup이 도는 네 자리
- [레퍼런스: 생명주기 훅](../reference/sugar/04-lifecycle-hooks.md) — `q.OnCreated`/`q.OnRendered`/`q.OnDestroyed`(`Ref`/`Effect` 위에 얹은 슈거)
- [04. RemoteEvent와 엔진 입력을 상태로 브릿징하기](../how-to/04-network-and-input-bridge.md) — `Effect`의 cleanup으로 엔진 연결을 끊는 실전 배치
