---
title: "06. 다시 위로 올려보내기 — q.Out"
description: "인스턴스에서 상태로 거슬러 올라오는 흐름을 q.Out과 q.OnChange로 배웁니다 — 입력창에 타이핑한 값을 Source로 끌어올리고, 왕복인데도 무한히 돌지 않는 이유를 봅니다"
---
# [시작하기] 06. 다시 위로 올려보내기 — `q.Out`

> **대상 독자**: [05. 이름표와 속성](./05-tag-attr.md)을 끝낸 개발자
> **목표**: 엔진이 스스로 바꾸는 프로퍼티(입력창의 `Text`)를 다시 `Source`로 끌어올리기

01장부터 지금까지 값은 늘 한 방향으로만 흘렀습니다 — 원천에서 인스턴스로 **내려가는**
방향입니다(05장의 태그·속성도 마찬가지로 내려가는 값이었습니다). 그런데 현실의 화면에는 반대
방향도 있습니다. 사용자가 입력창에 타이핑하면, 그 값은 quad가 아니라 **엔진**이 프로퍼티에
씁니다 — 그걸 다시 상태로 끌어올리는 길이 이 장의 주제입니다.

---

## 지금까지의 코드

```luau
-- (Main.client.luau 계속 — 05장에서 더한 태그·속성 자리는 그대로 두고 여기선 생략합니다.
--  card는 02장에서 이미 screen에 붙였습니다: card.Parent = screen)
const count = q.Source(0)
const countText = count:Compute(function(c) return `카운트: {c:Get()}` end)
const active = q.Source(true)

const card = D.Frame {
    -- …05장까지의 Tag/Attr 자리 그대로…

    D.TextLabel { Text = countText },
    D.TextButton { Text = "+ 1", Activated = function() count:Set(count:Get() + 1) end },
}
```

---

## 1. 입력창 하나 놓기

카드 옆에 이름을 적을 입력창과, 그 이름을 보여줄 라벨을 하나씩 놓습니다.

```luau
-- … 위쪽 코드에 이어집니다
const name = q.Source("quad")

const nameLabel = D.TextLabel {
    Size = UDim2.fromOffset(240, 28),
    BackgroundTransparency = 1,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Text = name:Compute(function(n) return `{n:Get()}의 카운터` end),
}
nameLabel.Parent = screen

const nameBox = D.TextBox {
    Size = UDim2.fromOffset(240, 32),
    BackgroundColor3 = Color3.fromRGB(50, 50, 58),
    TextColor3 = Color3.fromRGB(255, 255, 255),
    PlaceholderText = "이름",
    Text = name,
}
nameBox.Parent = screen
```

**실행하면** 입력창에 `quad`가 채워져 뜨고, 라벨엔 `quad의 카운터`가 뜹니다. 그런데 입력창을
지우고 다른 이름을 타이핑해도 라벨은 그대로입니다 — `name:Get()`도 여전히 `"quad"`입니다.
`Text = name`은 03~05장에서 해 온 그대로, 값을 **내려보내기만** 합니다. 인스턴스 쪽에서 일어난
변화는 quad가 알 길이 없습니다.
<!-- mock 실측 2026-09-21: quad-roblox/test/gs.flowingback.luau "06 §1 재검증" — Out 없이 box.Text를 바꿔도 name:Get()은 그대로 -->

---

## 2. `q.Out`으로 올려보내기

숫자 키 자리에 한 줄을 더합니다.

```luau
-- … 위쪽 코드에 이어집니다(nameBox를 이렇게 고칩니다)
const nameBox = D.TextBox {
    q.Out("Text", name),   -- ← 숫자 키: 엔진이 바꾼 Text를 name으로 되쓴다

    Size = UDim2.fromOffset(240, 32),
    BackgroundColor3 = Color3.fromRGB(50, 50, 58),
    TextColor3 = Color3.fromRGB(255, 255, 255),
    PlaceholderText = "이름",
    Text = name,            -- in: 여전히 이 줄도 있습니다
}
nameBox.Parent = screen
```

되돌리는 버튼도 하나 답니다.

```luau
-- (Main.client.luau 계속 — nameBox 뒤에)
const resetButton = D.TextButton {
    Size = UDim2.fromOffset(120, 28),
    Text = "이름 되돌리기",
    Activated = function() name:Set("quad") end,
}
resetButton.Parent = screen
```

**실행하면** 입력창에 타이핑하는 대로 `nameLabel`이 바로 따라오고, "이름 되돌리기"를 누르면
입력창도 `quad`로 되돌아갑니다 — 양쪽 다 됩니다.

한 줄 요약하면 **in 한 줄, out 한 줄**입니다. `Text = name`은 있던 그대로(상태 → 프로퍼티)이고,
`q.Out("Text", name)`이 반대 방향(프로퍼티 → 상태)을 담당합니다. `q.Out`도 05장의 `q.Tag`나
[레퍼런스의 생명주기 훅](../reference/sugar/04-lifecycle-hooks.md)과 같은 부류입니다 —
**숫자 키 자리에 놓는 값**이고, 콜백을 이름 있는 자리(문자 키)에 적는 이벤트와는 다릅니다.
`q.Out(name, src)`은 사실 `q.OnChange(name, fn)` 위에 얹은 슈거일 뿐이라, 뒤에서 직접
`OnChange`를 쓰는 것도 봅니다.

```luau
-- (확인용 — Observer로 name이 몇 번 emit하는지 셉니다. nameBox를 만들기 *전에* 등록해야
--  초기 바인딩의 메아리까지 볼 수 있습니다. 확인이 끝나면 이 블록은 지웁니다)
local emits = 0
name:Observer(function() emits += 1 end):Subscribe()
print(emits)          --> 1   (등록 즉시 한 번)

-- (여기서 §2의 nameBox를 만든다) emits는 여전히 1 — 첫 바인딩의 메아리를 건너뜁니다
-- (입력창에 타이핑한다) emits == 2 — 엔진 변경이 한 번만 올라옵니다
-- (되돌리기 버튼을 누른다) emits == 3 — 추가 메아리 없이 한 번만
```
<!-- mock 실측 2026-09-21: quad-roblox/test/gs.flowingback.luau "06 §2 재검증" — emits 1(baseline) → 1(초기 바인딩, 메아리 없음) → 2(타이핑) → 3(되돌리기), 왕복 모두 확인 -->

---

## 3. 왕복인데 왜 무한히 돌지 않나요

<details>
<summary><strong>Source → 프로퍼티 → 신호 → Source, 이게 왜 안 도나요?</strong></summary>

되쓴 값이 다시 프로퍼티에 쓰이고, 그게 다시 신호를 낼 것처럼 보이지만 거기서 멈춥니다. 이유는
**엔진이 같은 값을 다시 대입해도 변경 신호를 내지 않기 때문**입니다(Studio 실측
2026-09-10) — `Source`가 되쓴 값은 입력창이 이미 갖고 있는 값이라, 그 대입이 신호를 내지
않고 고리가 끊깁니다.
<!-- 2026-09-10 Studio 실측: `.claude/audit/studio-docs-2026-09-10.md` A절, `.claude/base/onchange-plan.md` H-429 -->

그럼 `q.Out`이 "새 값이 `src:Get()`과 같으면 `:Set`을 건너뛴다"는 건 왜 있을까요? 왕복을
끊으려는 게 아니라 **첫 바인딩의 메아리**를 막기 위해서입니다 — 숫자 키가 문자 키보다 먼저
처리되므로 `q.Out`의 연결이 `Text = name`의 첫 쓰기보다 먼저 걸리고, 그 첫 쓰기가 이미 연결된
콜백에 그대로 닿습니다. 값 비교가 없다면 `name`의 모든 구독자가 카드가 만들어질 때마다 한 번씩
더 헛돕니다 — 위 확인용 블록에서 `emits`가 등록 직후와 초기 바인딩 뒤에 똑같이 `1`인 것이
그 증거입니다.

</details>

---

## 4. 콜백이 필요할 때

값을 그대로 되쓰는 게 아니라 가공하거나 다른 상태를 같이 바꾸고 싶다면 `q.Out`이 감싸고 있는
`q.OnChange`를 직접 씁니다.

```luau
const shout = q.Source("")

D.TextBox {
    Text = name,
    q.OnChange("Text", function(v)
        shout:Set(string.upper(v))
    end),
}
```

콜백은 **엔진이 준 새 값 하나만** 받습니다 — 그걸로 뭘 할지는 자유입니다. 다만 그 콜백 안에서
**같은 프로퍼티를 몰아가는 바로 그 `Source`**(`Text = name`의 `name`)에 되쓰려 한다면
`q.Out`을 쓰세요 — 직접 손으로 하면 값 비교를 빠뜨리기 쉽고, 3절에서 본 메아리를 그대로
다시 만들게 됩니다.

---

## 5. 파생 값에는 되쓸 수 없습니다

<details>
<summary><strong><code>:Compute</code> 결과를 <code>q.Out</code>에 넘기면요?</strong></summary>

`q.Out`의 둘째 자리는 **쓸 수 있는 값**(`Source`)만 받습니다. `:Compute` 결과는 읽기 전용
`State`라 `:Set`이 없고, `--!strict`에서 타입 검사가 먼저 막습니다. 타입을 우회해 넘기면
런타임도 거부합니다.

```luau
const derived = name:Compute(function(n) return n:Get() end)
D.TextBox { q.Out("Text", derived) }
-- Out: second argument for "Text" must be a Source to write back into (got a read-only State (a :Compute result?))
```

</details>
<!-- mock 실측 2026-09-21: quad-roblox/test/gs.flowingback.luau "06 §5 재검증" -->

---

## 이해 점검

```quiz
# in만 있고 out이 없을 때

`Text = name`만 있고 `q.Out`이 없을 때, 입력창에 타이핑해도 `name:Get()`이 그대로인 이유는 무엇인가요?

- [ ] `q.OnChange`가 없으면 `TextBox`는 아예 타이핑을 받지 않기 때문입니다
- [x] `Text = name`은 상태에서 프로퍼티로 내려가는 방향뿐이라, 엔진이 프로퍼티를 바꿔도 그 변화를 quad가 알 길이 없기 때문입니다
- [ ] `name`이 `q.Source`가 아니라 `:Compute` 결과라 애초에 값을 받을 수 없기 때문입니다

`Text = name`은 03~05장에서 해 온 것과 같은 내려가는 방향의 바인딩입니다. 인스턴스 쪽에서 엔진이 스스로 바꾼 값을 상태로 끌어올리려면 `q.Out`이나 `q.OnChange`처럼 반대 방향을 맡는 것을 따로 놓아야 합니다.
```

```quiz
# 왕복인데 안 도는 이유

`Text = name`과 `q.Out("Text", name)`을 같이 놓으면 왕복 구조인데도 무한히 돌지 않는 진짜 이유는 무엇인가요?

- [ ] `q.Out`이 값을 되쓸 때 구독을 잠깐 끊어 두기 때문입니다
- [x] 엔진이 같은 값을 다시 대입해도 변경 신호를 내지 않아, 되쓴 값이 프로퍼티에 다시 쓰여도 거기서 신호가 멈추기 때문입니다
- [ ] `q.Out`이 되쓴 값과 새로 오는 값을 매번 깊은 비교로 걸러 신호 자체를 원천 차단하기 때문입니다

되쓴 값은 입력창이 이미 가진 값이고, Roblox 엔진은 같은 값 재대입에 변경 신호를 내지 않습니다. `q.Out`의 값 비교는 이 왕복을 끊는 것이 아니라, 숫자 키가 문자 키보다 먼저 처리되어 생기는 첫 바인딩의 메아리 하나만을 막기 위한 것입니다.
```

```quiz
# :Compute 결과를 q.Out에 넘기면

`q.Out("Text", derived)`에서 `derived`가 `:Compute` 결과라면 어떻게 되나요?

- [ ] 되쓴 값이 그 즉시 다시 파생되어 계산되므로 아무 문제 없이 동작합니다
- [x] `:Compute` 결과는 읽기 전용 `State`라 `Set`이 없어 거부됩니다 — strict에서는 타입 검사가, 우회하면 런타임이 막습니다
- [ ] 파생 값이라는 것을 quad가 알아서 감지해 자동으로 새 `Source`를 만들어 대신 받습니다

`q.Out`의 둘째 자리는 쓸 수 있는 `Source`만 받습니다. `:Compute` 결과는 `Set`이 없는 읽기 전용 `State`라 strict 타입 검사에서부터 걸리고, 우회해서 넘기면 런타임 에러 문구가 그 사실을 그대로 알려줍니다.
```

---

## 더 알고 싶다면

- [레퍼런스: `q.OnChange` / `q.Out`](../reference/roblox/05-onchange.md) — 읽기 표면 `PropTypesRead`, 초기값 발화 계약, `State`로 바꿔 끼우기
- [02. 폼 유효성 검사와 제출 버튼 제어](../how-to/02-form-validation-pattern.md) — 입력창 여럿을 `q.Out`으로 올려 `Store`에 모으는 실제 사용
