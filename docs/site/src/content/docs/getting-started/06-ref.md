---
title: "06. 인스턴스를 손에 쥐기 — Ref"
description: "만들어진 인스턴스를 Ref 상자에 담아 쓰고, 같은 props 안에서 먼저 채워지는 PreRef와 채워질 때를 기다리는 :Callback/:Wait까지 봅니다"
---
> **대상 독자**: [05. 이름표와 속성](/getting-started/05-tag-attr/)을 끝낸 개발자
> **목표**: 만들어진 인스턴스를 변수로 잡아 두고, 그것이 언제 손에 들어오는지 알기

지금까지 화면에 무언가를 반영하는 길은 프로퍼티와 표시(태그·속성)였습니다.
그런데 만들어진 **실물 인스턴스 자신**이 필요할 때가 있습니다 — 크기를 재거나,
이벤트 안에서 그 인스턴스를 직접 만지거나, 밖으로 꺼내 다른 코드에 넘길 때입니다.
`Ref`는 그 인스턴스를 담아 두는 **빈 상자**입니다.

---

## 1. 상자 하나 놓기 — `q.Ref`

`Ref`를 props의 숫자 키 자리에 놓아 두면 quad가 만들어진 인스턴스를 그 상자에 넣어 줍니다.

카드의 버튼에 상자를 하나 놓습니다.

```luau
-- … 위쪽 코드에 이어집니다(card의 버튼을 이렇게 고칩니다)
const buttonRef = q.Ref<<TextButton?>>(nil)

const card = D.Frame {
    -- …생략…
    D.TextButton {
        buttonRef,                  -- ← 숫자 키: 만들어진 버튼이 여기 담긴다
        Text = "+ 1",
        Activated = function()
            count:Set(count:Get() + 1)
        end,
    },
}

print(buttonRef.Value.ClassName) --> "TextButton"
```

**실행하면** 출력 창에 `TextButton`이 찍힙니다.
<!-- mock 실측 2026-09-11: gs.refprobe.luau A1 — Ref가 채워지고 ClassName이 나온다 -->

`q.Ref<<TextButton?>>(nil)`의 꺾쇠 둘이 낯설 수 있습니다.

<details>
<summary><strong>꺾쇠가 왜 둘인가요?</strong></summary>

`<<...>>`는 **Luau에서 타입 인자를 직접 지정하는 문법**입니다. 홑화살괄호 하나(`f<T>(x)`)는 비교 연산(`f < T > (x)`)으로 파싱돼 버려서, Luau는 명시적 타입 인자를 두 겹으로 적습니다.

`Ref`에서 이 표기가 필요한 이유는 **타입 파라미터가 초깃값에서 추론되기** 때문입니다. `q.Ref(nil)`이라고만 쓰면 그 상자는 `Ref<nil>` — 영원히 `nil`만 담을 수 있는 상자가 됩니다. 그래서 담길 것을 직접 적어 넓힙니다.

```luau
const a = q.Ref(nil)                    -- Ref<nil> — 인스턴스를 담을 수 없다
const b = q.Ref<<TextButton?>>(nil)     -- Ref<TextButton?> — 비어 있다가 버튼이 담긴다
```

`Ref<nil>`을 그대로 숫자 키 자리에 놓으면 타입 검사가 그 자리에서 막습니다(`--!strict` 기준). `?`가 붙는 것은 **처음엔 비어 있기** 때문입니다. 숫자 키 자리에 놓은 `Ref`는 그 자리가 처리되기 전까지 `nil`이라, 사실상 항상 `T?` 모양입니다.

같은 표기가 뒤 장들에서도 계속 나옵니다 — 예를 들어 `q.Slot<<Instance>>()`.
<!-- strict 실측 2026-09-11: consumer/P5.luau — D.Frame { q.Ref(nil) }은 'Expected this to be … but got Ref<nil>'로 거부됨 -->

</details>

**채워지는 시점은 "그 숫자 키 자리가 처리될 때"입니다.** 위 예제에서는 `D.TextButton { ... }`이 만들어지는 그 순간이고, 그래서 `card`가 완성된 뒤에는 이미 들어 있습니다. 반대로 말하면 **그 앞줄에서는 아직 비어 있습니다** — 상자를 만든 직후부터 그 자리가 처리되기 전까지는 `ref.Value`가 `nil`입니다.

---

## 2. 먼저 채워지는 상자 — `q.PreRef`와 `:Unwrap()`

가장 자주 만나는 자리는 **같은 props 안에서 자기 인스턴스를 만지는** 경우입니다. 버튼의 `Activated` 안에서 그 버튼 자신의 색을 바꾸는 것처럼요.

이 자리에서 평범한 `Ref`를 쓰면 "버튼을 만드는 중에 그 버튼을 참조한다"는 순서 문제가 생깁니다. `q.PreRef`가 그 문제를 없앱니다 — **그 인스턴스에 아무 일도 일어나기 전에** 먼저 채워지기 때문입니다.

```luau
-- … 위쪽 코드에 이어집니다(1절의 buttonRef를 PreRef로 바꿉니다)
const buttonRef = q.PreRef<<TextButton?>>(nil)

    -- … 그리고 card의 숫자 키 자리, 버튼을 이렇게 고칩니다
    D.TextButton {
        buttonRef,
        Text = "+ 1",
        BackgroundTransparency = 0,
        Activated = function()
            count:Set(count:Get() + 1)
            buttonRef:Unwrap().BackgroundTransparency = 0.5   -- 가드 없이
        end,
    },
```

**실행하면** 버튼을 누를 때 숫자가 오르면서 버튼이 반투명해집니다 — `BackgroundTransparency`가 `0`에서 `0.5`로 바뀝니다.
<!-- mock 실측 2026-09-11: gs.gs2probe.luau 3a/3b — 클릭 전 0, 클릭 후 0.5 -->

**같은 props 안에서 자기 인스턴스를 쓸 때는 `PreRef`를 권합니다.** 숫자 키 자리의 위치와 무관하게 먼저 채워지므로, 이벤트 핸들러든 프로퍼티 계산이든 그 상자가 비어 있는 것을 볼 일이 없습니다.

`:Unwrap()`은 그 확신을 코드로 적는 방법입니다. 담긴 값을 그대로 돌려주되 **타입에서 `nil`만 벗겨** 주고, 정말 비어 있으면 부른 줄을 blame하며 던집니다.

```
Ref:Unwrap: the Ref is empty (Value is nil) — not filled yet, or never placed
```
<!-- mock 실측 2026-09-11: gs.gs2probe.luau 3c — 빈 Ref에 :Unwrap() -->

**규약이지 강제가 아닙니다.** `:Unwrap()`은 "여기서는 반드시 차 있다"를 아는 자리에서만 쓰고, 확신이 없으면 `if ref.Value then`으로 가드하세요.

`PreRef`는 **일회용**입니다. 한 번 채워진 `PreRef`를 다른 인스턴스에 다시 놓으면 그 자리에서 던집니다 — 인스턴스마다 새로 만드세요(3절의 접힘 "쓰던 `Ref`를 다른 인스턴스에 다시 써도 되나요?"가 그 이야기입니다).

---

## 3. 채워질 때 반응하기 — `:Callback`과 `:Wait`

상자가 **언제** 차는지를 신경 써야 할 때가 있습니다. 대개는 그 상자를 만든 쪽과 채우는 쪽이 다를 때입니다.

`ref:Callback(fn)`은 값이 담길 때 부를 함수를 등록합니다. **등록하는 그 자리에서 지금 값으로 한 번 즉시 불리고**, 그 뒤로 채워질 때마다 다시 불립니다.

```luau
-- … 위쪽 코드에 이어집니다(여기서는 다시 평범한 Ref로 두고, 카드를 만들기 전에 등록합니다)
const buttonRef = q.Ref<<TextButton?>>(nil)

buttonRef:Callback(function(inst)
    print("상자:", if inst then inst.ClassName else "nil")
end)

const card = D.Frame {
    -- …생략…
    D.TextButton { buttonRef, Text = "+ 1", Activated = function() count:Set(count:Get() + 1) end },
}
```

**실행하면** `상자: nil`이 먼저 찍히고(등록 시점엔 비어 있으니까), 카드가 만들어지면서 `상자: TextButton`이 이어서 찍힙니다.
<!-- mock 실측 2026-09-11: gs.gs2probe.luau 4 — 호출 순서 nil → TextButton -->

기다렸다가 **그 줄에서 이어서 쓰고 싶다면** `ref:Wait()`이 있습니다. 다만 성질이 하나 있습니다 — **`:Wait()`은 언제나 다음번 채워짐을 기다립니다.** 이미 차 있어도 기다립니다. 그래서 관용구는 둘을 합친 모양입니다.

```luau
-- … 위쪽 코드에 이어집니다
task.spawn(function()
    const inst = if buttonRef.Value then buttonRef.Value else buttonRef:Wait().Value
    print("버튼 준비됨:", inst.ClassName)
end)
```

**실행하면** 상자가 이미 차 있으면 그 줄에서 곧바로 찍히고, 아직이면 채워지는 순간 찍힙니다. `:Wait()`을 인자 없이 부르려면 **yield 할 수 있는 코루틴 안**이어야 해서 `task.spawn`으로 감쌌습니다.
<!-- mock 실측 2026-09-11: gs.gs2probe.luau 5a/5b/5c, gs.gs4probe.luau W1~W3 — coroutine.create/resume로 확인(task는 CLI에 없음). 빈 상자면 suspended로 대기하다 채워질 때 진행, 이미 차 있으면 즉시 통과. :Wait():Unwrap() 형태는 consumer/P5.luau에서 신 솔버 strict exit 0 -->

<details>
<summary><strong>왜 이미 차 있어도 기다리나요?</strong></summary>

`Ref<T?>`에서는 `nil`도 정당한 값이라 "차 있는가"를 `:Wait` 쪽에서 판정할 수 없기 때문입니다.

`--!strict`으로 올릴 때는 위 관용구의 마지막 `.Value` 대신 `:Wait():Unwrap()`을 쓰면 `nil`까지 벗겨집니다.

</details>

컴포넌트([11장](/getting-started/11-components/))에서는 **부모가 만든 `Ref`를 자식이 채우고, 부모가 이 두 방법으로 기다리는** 모양이 흔합니다.

<details>
<summary><strong>쓰던 <code>Ref</code>를 다른 인스턴스에 다시 써도 되나요?</strong></summary>

**하나의 `Ref`는 한 자리에만 놓습니다.** 앞 인스턴스가 살아 있는 채로 같은 `Ref`를 둘째 자리에 놓으면 그 자리에서 던집니다.

```
bindLifetime: value is already bound to another Instance
```

문제는 앞 인스턴스를 `Destroy()`한 뒤입니다. 그때는 **에러 없이 다시 놓입니다.** 그래서 "재사용해도 되나 보다" 하고 넘어가기 쉬운데, 그 사이가 함정입니다.

**`Ref`는 담긴 인스턴스가 `Destroy()`돼도 스스로 비워지지 않습니다.** `Ref`는 대상의 파괴를 감지하지도, 반응하지도 않습니다 — 마지막으로 담긴 것을 그대로 계속 가리킵니다. 그래서 새 인스턴스가 아직 안 만들어진 구간에서 `if ref.Value then`을 쓰면 **죽은 옛 인스턴스를 잡습니다.** 가드가 통과하는데 값은 쓰레기인, 가장 찾기 어려운 종류의 버그입니다.

`PreRef`/`PostRef`는 아예 일회용이라 그 시도 자체를 막습니다.

```
PreRef: already fired — a PreRef is one-shot, make a new one for each instance
```

**결론은 하나입니다 — `Ref`는 인스턴스마다 새로 만듭니다.** 목록처럼 인스턴스가 계속 갈리는 자리라면 `Ref`를 돌려 쓰지 말고, 항목을 만드는 그 자리에서 하나씩 만드세요.

</details>
<!-- mock 실측 2026-09-11: gs.refprobe.luau B1(살아 있을 때 에러)·B2(Destroy 뒤 재사용은 통과, .Value는 죽은 옛 인스턴스)·A2(Destroy해도 안 비워짐)·C1(PreRef 일회용) -->

---

## 4. 전부 끝난 뒤에 받는 상자 — `q.PostRef`

`PreRef`의 거울이 하나 더 있습니다. `q.PostRef`는 그 인스턴스의 **자식과 프로퍼티가 전부 끝난 뒤** 채워집니다 — **자기 아래**의 완성된 서브트리를 재는 코드(레이아웃 측정 등)가 그 자리입니다. 채워지는 기준은 그 인스턴스의 숫자 키·문자 키 처리가 끝난 시점이지 **부모에 붙는 시점이 아닙니다.**

`q.PostRef`를 `PreRef`와 같은 자리(숫자 키)에 놓고 `:Callback`으로 받으면 됩니다.

```luau
-- 새 예시: 별도 스크립트
const doneRef = q.PostRef<<Frame?>>(nil)

doneRef:Callback(function(inst)
    if inst then
        print("자식 수:", #inst:GetChildren())
    end
end)

const card = D.Frame {
    doneRef,
    D.TextLabel { Text = "A" },
    D.TextLabel { Text = "B" },
}
```

**실행하면** `자식 수: 2`가 찍힙니다(등록 시점의 `nil` 한 번은 위 가드가 걸러 냅니다).
<!-- mock 실측 2026-09-11: gs.gs3probe.luau P1 — 자식 둘이 이미 붙은 채로, Parent는 아직 nil인 시점에 불린다 -->

<details>
<summary><strong>그때 <code>Parent</code>도 정해져 있나요?</strong></summary>

계약은 **"자식이 전부 붙었다"까지입니다** — 이 인스턴스가 **부모에 붙었는지는 계약이 아닙니다.** 불리는 그 순간 `Parent`는 **아직 모르는 상태**입니다: 위처럼 리터럴로 중첩해 만들었다면 대개 `nil`이지만, 이미 트리에 있던 인스턴스를 넘겨받았다면 처음부터 차 있습니다. 게다가 **그 뒤로 `Parent`가 영영 바뀌지 않을 수도 있으므로**, "나중에 `Parent`가 설정되면 그때 하자"고 기다리는 코드는 한 번도 안 돌 수 있습니다. 그러니 화면에 실제로 올라간 뒤라야 나오는 값(`AbsoluteSize` 등)을 여기서 읽지 마세요. 그건 `Ref` 쪽 이야기가 아니라 엔진 프로퍼티를 관측하는 쪽 이야기입니다.

`PreRef`와 마찬가지로 일회용이고, 숫자 키 자리에 **리터럴로** 놓아야 합니다.

</details>

---

## 더 알고 싶다면

- [레퍼런스: `Ref`](/reference/core/07-ref/) — `Ref`/`PreRef`/`PostRef` 셋의 발화 시점, `:Callback`/`:WeakCallback`/`:Wait`/`:Unwrap`의 전체 계약과 에러 문구
- [01. 컴포넌트 경계 규약과 스타일 합성](/how-to/01-component-conventions/) — 바깥에서 `Ref`를 받는 컴포넌트의 `or None` 관용구
