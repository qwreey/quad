---
title: "12. 함수로 묶기 — 팩토리·클로저·커링"
description: "지금까지 여러 번 써 온 '함수를 값처럼 다루는' 습관에 이름을 붙이고, 반응형 로직을 함수로 묶어 재사용합니다"
---
> **대상 독자**: [11. 컴포넌트로 쪼개기](/getting-started/11-components/)를 끝낸 개발자
> **목표**: 지금까지 손이 먼저 익힌 모양들에 이름을 붙이고, 반복되는 반응형 로직을 함수 하나로 묶기

새로 배우는 API가 없는 장입니다. 지금까지 여러 번 써 온 것 — `:Compute`에 함수를
넘기고, `Effect`를 만들어 자리에 놓고, 컴포넌트를 부르는 것 — 은 전부 **함수를
값처럼 다루는** 같은 습관이었습니다. 이 장은 그 습관을 정리하고, 그걸로
반복을 줄이는 법을 봅니다.

Lua의 함수는 숫자나 테이블과 똑같은 **값**입니다. 변수에 담을 수도, 인자로 넘길
수도, 함수에서 돌려줄 수도 있습니다. quad의 API가 대부분 그 성질 위에 서 있어서,
이 장을 지나면 앞 장들의 모양이 한꺼번에 정리됩니다.

---

## 1. 함수를 인자로 — 콜백

가장 많이 한 것입니다. **어떻게 할지를 함수로 적어 넘기면, 언제 부를지는 받는 쪽이 정합니다.**

```luau
-- 지금까지 세 번 했습니다
count:Compute(function(c) return `카운트: {c:Get()}` end)   -- 값이 필요할 때 quad가 부른다
count:Observer(function(t) print(t:Get()) end)              -- 값이 바뀔 때 quad가 부른다
D.TextButton { Activated = function() count:Set(1) end }    -- 눌렸을 때 엔진이 부른다
```

셋 다 "지금 실행해서 결과를 넘기는 것"이 아니라 **함수 자체를 넘기는 것**입니다. `count:Compute(f())`처럼 괄호를 붙이면 결과값이 넘어가 버립니다 — 괄호가 없는 것이 핵심입니다.

---

## 2. 바깥을 기억하는 함수 — 클로저

```luau
-- (04장에서 만든 그 버튼입니다)
const count = q.Source(0)

const button = D.TextButton {
    Text = "+ 1",
    Activated = function()
        count:Set(count:Get() + 1)   -- ← 바깥의 count를 기억한다
    end,
}
```

`Activated`에 넘긴 함수는 `count`를 인자로 받지 않았는데도 `count`를 씁니다. **함수가 만들어진 자리의 바깥 변수를 계속 붙들고 있기** 때문이고, 이것을 **클로저**라고 부릅니다.

quad에서 이 성질은 계속 나옵니다 — 컴포넌트 안에서 만든 `Source`를 그 안의 이벤트 핸들러가 쓰는 것([11장](/getting-started/11-components/)), `Effect`가 인자 대신 클로저로 값을 읽는 것([07장](/getting-started/07-observer-effect/))이 전부 클로저입니다. 그래서 **컴포넌트를 두 번 부르면 상태도 둘**입니다. 각 호출이 자기 `Source`를 만들고, 그 호출 안에서 만들어진 함수들이 각자 그것을 붙들기 때문입니다.

---

## 3. 값을 돌려주는 함수 — 팩토리

`q.Ref(...)`·`q.Effect(...)`·`D.Modifier.Frame {...}`·컴포넌트는 전부 **부르면 값이 나오는 함수**입니다. 그렇다면 그 호출을 **내 함수로 한 겹 감싸는** 것도 당연히 됩니다. 그런 함수를 **팩토리**라고 부릅니다.

quad에서 팩토리가 쓰이는 자리는 둘입니다 — **값을 만들어 돌려주는 것**, 그리고 **그 팩토리 자체를 컴포넌트에 넘기는 것**.

### 값을 돌려주는 팩토리

[07장](/getting-started/07-observer-effect/) 3절에서 버튼 색을 만든 파이프는 "기준을 넘으면 노랑, 아니면 파랑"이라는 규칙 하나였습니다. 그 규칙에 이름을 붙입니다.

```luau
-- 새 예시: 별도 스크립트(또는 Counter.luau 위쪽)
-- "이 State가 기준을 넘었는지에 따라 두 색 중 하나를 내놓는다"를 함수 하나로
local function highlightColor(state, threshold)
    return state:Compute(function(c)
        return if c:Get() >= threshold
            then Color3.fromRGB(255, 190, 0)
            else Color3.fromRGB(0, 162, 255)
    end)
end
```

돌려주는 것이 `State`이므로, 쓰는 쪽은 **그 호출을 문자 키의 값 자리에 놓습니다.** 11장으로 옮겨 오면서 색 리터럴로 돌아가 있던 버튼을 다시 파이프로 바꿉니다.

```luau
-- … (Counter.luau) 버튼의 BackgroundColor3을 이렇게 고칩니다
        D.TextButton {
            -- …나머지 프로퍼티 생략…
            BackgroundColor3 = highlightColor(count, 10),   -- ← 문자 키의 값 자리
            Text = "+ 1",
            Activated = function() count:Set(count:Get() + 1) end,
        },
```

**실행하면** 07장과 똑같이 카운트가 10 이상일 때 버튼이 노란색이 됩니다. 달라진 것은 그 규칙이 이제 **이름을 가졌다**는 것뿐입니다 — 버튼이 열 개여도 `highlightColor(...)` 열 줄이면 되고, 여러 화면에서 쓸 것이면 이 함수만 모듈 하나로 빼면 됩니다.
<!-- mock 실측 2026-09-11: gs.polish2.luau "12 §3(a)" — highlightColor(count, 10)을 BackgroundColor3에 꽂은 형태, (0,162,255) → 10에서 (255,190,0) → 3에서 다시 파랑; "12 §3(b)" props.Watch — 왼쪽 카운터: 0 | 정리 | 왼쪽 카운터: 1 | 정리(파괴); "12 §4" Doubled — 0 → count:Set(21) 뒤 42, {}를 넘기면 위 에러 문구 -->

### 컴포넌트에 팩토리를 넘기기

[11장](/getting-started/11-components/)의 `Counter`는 `count`를 **자기 안에 숨깁니다.** 부른 쪽은 그 `Source`를 손에 쥘 수 없습니다. 그런데 바깥에서 "이 카운터가 셀 때마다 로그를 남기고 싶다"처럼 **안쪽 상태에 무언가를 걸고 싶은** 경우가 생깁니다.

이럴 때 상태를 밖으로 내주는 대신 **팩토리를 받습니다.** 컴포넌트가 자기 `count`를 그 함수에 건네고, 돌려받은 것을 자기 숫자 키 자리에 놓습니다.

```luau
-- … (Counter.luau) 돌려주는 D.Frame의 끝, props.Children 뒤에 한 줄을 더합니다
        props.Children or q.None,

        if props.Watch then props.Watch(count) else q.None,
    }
end
```

부르는 쪽은 그 자리에서 `count`를 받아 **무언가를 만들어 돌려줍니다.** 로그처럼 뒤처리가 따라오는 일이면 `Effect`가 됩니다.

```luau
-- … (Main.client.luau) 부르는 쪽
Counter {
    Label = "왼쪽",
    Start = 0,
    Watch = function(count)
        return q.Effect(function()
            print("왼쪽 카운터:", count:Get())
            return function() print("왼쪽 카운터 정리") end
        end, count)
    end,
},
```

**실행하면** 왼쪽 카운터가 만들어질 때 `왼쪽 카운터: 0`이 찍히고, 버튼을 누를 때마다 `왼쪽 카운터 정리` 뒤에 `왼쪽 카운터: 1`이 이어집니다. 그 카운터를 파괴하면 마지막 정리가 한 번 더 찍힙니다. `Watch`를 안 넘긴 카운터는 그대로입니다.
<!-- mock 실측 2026-09-11: gs.handlers9.luau — Start=5에서 run 5 | cleanup | run 6 | cleanup(파괴), Watch 없이 부르면 자식 수 그대로 -->

`if props.Watch then … else q.None`은 [11장](/getting-started/11-components/) 2절의 `props.Children or q.None`과 같은 이유입니다 — 안 넘어왔을 때 그 자리가 **구멍**이 되면 안 되니까요. 더구나 여기서는 `Children` 뒤에 원소가 하나 더 붙었으니, 11장이 "뒤에 원소를 하나라도 더 붙이는 순간"이라고 예고한 상황이 바로 이것입니다.

돌려주는 것이 `Effect`여야 할 이유는 없습니다. `Observer`든 `Modifier`든, 컴포넌트는 받은 것을 자기 숫자 키 자리에 놓기만 합니다 — [07장](/getting-started/07-observer-effect/) 4절의 `Effect`(`Ref`와 파이프를 의존성으로 건 것)도 그대로 이 자리에 넘길 수 있습니다.

컴포넌트도 사실 이 팩토리의 한 종류입니다. 다른 점은 돌려주는 값이 `Effect`가 아니라 **인스턴스**라는 것뿐입니다.

---

## 4. 함수를 돌려주는 함수 — 커링

한 걸음만 더 가 봅니다. 팩토리가 값을 돌려줬다면, **함수를 돌려주는 함수**도 만들 수 있습니다.

`:Compute`에 넘기는 "10을 더한다"를 재사용하고 싶다고 해 봅시다. 더하는 수가 매번 다르니 그 수를 먼저 받고, **그 다음에 콜백을 돌려주면** 됩니다.

```luau
-- 새 예시: 별도 스크립트
-- n을 받아서, "핸들을 받아 n을 더해 돌려주는 함수"를 만든다
local function Sum(n)
    return function(c)
        return c:Get() + n
    end
end

const count = q.Source(0)
const plusTen = count:Compute(Sum(10))

print(plusTen:Get())   --> 10

count:Set(1)
print(plusTen:Get())   --> 11
```

`Sum(10)`이 만들어 낸 것은 값이 아니라 **함수**입니다. 그리고 그 함수는 `10`을 기억하고 있습니다(2절의 클로저입니다). 이렇게 "인자를 나눠서 단계적으로 받는" 모양을 **커링**이라고 부릅니다.
<!-- mock 실측 2026-09-11: gs.gs2probe.luau 7a/7b — 0에서 10, count:Set(1) 뒤 11 -->

같은 모양이 관측 콜백에도 그대로 쓰입니다.

```luau
-- … 위쪽 코드에 이어집니다
local function logWith(prefix)
    return function(t)
        print(prefix, t:Get())
    end
end

const label = D.TextLabel {
    Text = "…",
    count:Observer(logWith("카운트:")),
}
```

**실행하면** `카운트: 0`으로 시작해 값이 바뀔 때마다 같은 접두사로 찍힙니다. 접두사가 다른 관측을 열 개 붙여야 한다면, 열 개의 익명 함수 대신 `logWith(...)` 열 줄이 됩니다.
<!-- mock 실측 2026-09-11: gs.gs2probe.luau 8 — "카운트: 0 | 카운트: 1 | 카운트: 2" -->

### 흔한 연산은 이미 있습니다 — `q.Operator`

방금 손으로 만든 `Sum` 같은 것은 quad에 이미 들어 있습니다. `q.Operator`가 그 모음이고, 붙이는 자리는 `:Compute`가 아니라 **`:Apply`**입니다.

```luau
-- … 위쪽 코드에 이어집니다
const plusTen = count:Apply(q.Operator.Sum(10))   -- 위에서 손으로 만든 것과 같은 결과
```

`:Apply(factory)`는 "이 팩토리가 만들어 낸 연산을 이 State에 붙인다"는 뜻입니다 — 팩토리가 자기 의존성까지 같이 들고 있어서, 한 번 이름 붙인 연산자를 여러 State에 붙여도 의존성이 따라갑니다.
<!-- mock 실측 2026-09-11: gs.gs2probe.luau 7c/7d — 손으로 만든 Sum(10)과 q.Operator.Sum(10)이 같은 값(11, 15) -->

산술·비교·불리언·비트 연산까지 이름 붙은 것이 열넷 있습니다. 전체 목록과 계약은 [레퍼런스: `Operator`](/reference/sugar/02-operator/)에 있습니다.

<details>
<summary><strong><code>--!strict</code>에서는 이 함수들에 뭘 적나요?</strong></summary>

이 문서의 화면 코드는 Roblox 기본 모드(`--!nonstrict`) 기준이라 위 예제들엔 타입 주석이 없습니다. `--!strict`으로 올릴 때 붙는 것은 **넘겨받는 핸들의 타입**뿐입니다 — 전부 [01장](/getting-started/01-setup/)의 설정 모듈이 다시 내보낸 이름입니다.

```luau
--!strict
-- 콜백이 받는 것은 "값"이 아니라 핸들이므로 q.StateData<T>
local function Sum(n: number)
    return function(c: q.StateData<number>): number
        return c:Get() + n
    end
end

local function logWith(prefix: string)
    return function(t: q.StateData<number>)
        print(prefix, t:Get())
    end
end

-- 팩토리는 받는 것과 돌려주는 것에 이름만 붙이면 된다
local function highlightColor(state: q.State<number>, threshold: number): q.State<Color3>
    return state:Compute(function(c: q.StateData<number>): Color3
        return if c:Get() >= threshold
            then Color3.fromRGB(255, 190, 0)
            else Color3.fromRGB(0, 162, 255)
    end)
end

-- :Apply의 결과 타입은 부르는 쪽이 적는다
const total: q.State<number> = count:Apply(q.Operator.Sum(10))
```

`q.StateData<T>`와 `q.State<T>`의 차이는 "핸들로 받는 자리"와 "값이 흐르는 노드"입니다. 콜백 파라미터는 앞의 것, 변수에 담아 프로퍼티로 흘려보내는 것은 뒤의 것을 씁니다.

</details>
<!-- strict 실측 2026-09-11: consumer/P4.luau·P6.luau·P16.luau — 위 네 형태(highlightColor·__apply 객체 포함) 전부 신 솔버 strict exit 0 -->

### `:Apply`에는 테이블도 들어갑니다 — `__apply`

`q.Operator.Sum(10)`이 그랬듯 `:Apply`에 넘기는 것은 대개 함수입니다. 그런데 팔이 하나 더 있습니다 — **`__apply` 메소드를 가진 테이블**도 받습니다. 함수를 넘기면 `factory(state)`로 불리고, 테이블을 넘기면 `factory:__apply(state)`로 불립니다.

```luau
-- … 위쪽 코드에 이어집니다 — __apply 하나면 :Apply에 들어간다
const Doubled = {
    __apply = function(self, state)
        return state:Compute(function(c) return c:Get() * 2 end)
    end,
}

const twice = count:Apply(Doubled)
```

둘 중 어느 쪽도 아닌 것을 넘기면 그 자리에서 던집니다.

```
State: Apply factory must be a function or an object with an __apply method
```

이 팔이 있어서 **자기 상태를 가진 것**도 `:Apply`로 붙습니다. [16장](/getting-started/16-blocker/)에서 만들 `q.Blocker()`가 바로 이런 값이라 `count:Apply(blocker)`로 붙고, 그러고도 그 스위치는 손에 남아 있어 나중에 여닫을 수 있습니다(반대로 `q.Animate { … }`는 함수를 돌려주는 팩토리라 함수 팔입니다). 두 팔의 계약은 [레퍼런스: `state:Apply(factory)`](/reference/core/03-state/#stateapplyfactory)에 있습니다.

---

## 5. 이 함수들에는 규칙이 없습니다

React를 써 봤다면 여기서 한 번 멈칫하게 됩니다. Hook은 컴포넌트 최상단에서만, 조건문 밖에서, 언제나 같은 순서로 불러야 하니까요.

**quad의 이 함수들에는 그런 규칙이 없습니다.** 조건문 안에서도, 루프 안에서도, 이름이 `use`로 시작하지 않아도 됩니다.

```luau
-- (컴포넌트 안이라면 이런 것도 됩니다 — 조건식 안에서 만들어도, 이름이 use로 시작하지 않아도 됩니다)
const extra = if props.Verbose
    then q.Effect(function() print(count:Get()) end, count)
    else q.None
-- …그리고 이 값을 숫자 키 자리에 그대로 놓습니다
```
<!-- mock 실측 2026-09-11: gs.polish3.luau "12 §5" — Verbose면 Effect가 돌고, 아니면 None이 자리를 지킨다 -->

<details>
<summary><strong>왜 Hook 규칙이 없나요?</strong></summary>

Hook 규칙은 **컴포넌트 함수가 몇 번이고 다시 실행된다**는 전제에서 나옵니다. React는 상태를 호출 순서로 짝지어 기억하기 때문에, 두 번째 실행에서 순서가 달라지면 짝이 어긋납니다.

quad의 컴포넌트는 **한 번 실행되는 셋업 함수**입니다. 실행되는 동안 실제 인스턴스와 반응형 그래프를 한 번 만들고, 그다음부터 화면을 갱신하는 것은 그 그래프이지 함수의 재실행이 아닙니다. 다시 실행되지 않으니 "두 번째 실행에서의 순서" 자체가 존재하지 않고, 그래서 지킬 규칙도 없습니다.

같은 이유로 `Effect`나 `Observer`를 만드는 자리도 자유롭습니다 — 만든 것을 숫자 키 자리에 **놓기만** 하면 그때부터 그 인스턴스의 수명을 따릅니다.

"한 번 만든 그래프를 다시 그리지 않는다"가 어떤 성질로 이어지는지는 [17장](/getting-started/17-laziness/)에서 한 번에 봅니다.

</details>

---

## 더 알고 싶다면

- [01. 컴포넌트 경계 규약과 스타일 합성](/how-to/01-component-conventions/) — 재사용 로직을 함수로 빼는 실전 규약과 `--!strict`에서 붙이는 타입 주석
- [레퍼런스: `Operator`](/reference/sugar/02-operator/) — 콤비네이터 열넷의 시그니처, `:Apply`의 계약, 에러가 나는 세 시점
- [레퍼런스: `Observer` / `Effect`](/reference/core/05-observer-effect/) — 팩토리가 돌려주는 그 값들의 전체 계약
