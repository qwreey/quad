---
title: "02. 첫 화면 — 카드 하나 그리기"
description: "D.Frame 하나와 그 안의 라벨을 만들어, props 테이블의 문자 키와 숫자 키가 각각 무엇인지 봅니다"
---
> **대상 독자**: [01. 프레임워크 설정하기](/getting-started/01-setup/)를 끝낸 개발자
> **목표**: 화면에 카드 하나를 띄우고, 그 안에 글씨를 한 줄 넣기

이 장부터 16장까지는 **하나의 예제**를 조금씩 키웁니다. 마지막에는 클릭할 때마다
숫자와 색이 바뀌는 카운터 여러 개가 되고, 각 장은 그 직전 장의 코드에 몇 줄을
더하는 식으로 진행합니다.

---

## 준비 코드

01장에서 만든 진입점 `Main.client.luau` 안에서 계속 짭니다. 위쪽 두 줄은 이제 이것뿐입니다.

```luau
-- (Main.client.luau 계속 — 01장에서 만든 진입점입니다)
const q = require("@game/ReplicatedStorage/Client/UI/Quad")
const D = q.D
```

---

## 1. 카드 만들기

01장의 `hello` 라벨을 지우고, 그 자리에 어두운 사각형 하나를 만듭니다.

```luau
-- … 위쪽 코드에 이어집니다
const card = D.Frame {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(240, 160),
    BackgroundColor3 = Color3.fromRGB(35, 35, 42),
    UICorner = 12,
}
card.Parent = screen
```

**실행하면** 화면 한가운데에 모서리가 둥근 어두운 사각형이 하나 뜹니다.

<details>
<summary><strong><code>D.Frame { … }</code>이 돌려주는 건 뭔가요?</strong></summary>

**부른 그 순간 만들어진 진짜 Roblox Instance입니다.** 나중에 렌더러가 만들어 줄 "설계도"를 받은 게 아닙니다. 그래서 이렇게 바로 읽힙니다.

```luau
print(card.ClassName) --> "Frame"
```

가상 DOM도, 이전 트리와 새 트리를 비교하는 단계도 없습니다. 넘긴 테이블은 그 자리에서 해석되어 인스턴스에 반영되고 끝납니다. 컴포넌트 함수가 반환되는 시점에 물리 인스턴스가 이미 존재하므로, 반환값을 그대로 쓰거나(`card.Parent = screen`) 나중에 배울 `Ref`로 잡아둘 수 있습니다.

</details>

**중괄호 안의 `이름 = 값`은 그 인스턴스의 프로퍼티입니다.** props 테이블에서 이 부분을 quad 문서에서는 **문자 키**(`이름 = 값`처럼 이름이 붙은 자리)라고 부릅니다 — 뒤에서 나올 **숫자 키**(이름 없이 순서대로 놓이는 자리)와 짝을 이루는 이름입니다. 어떤 이름을 쓸 수 있는지는 quad가 정하는 게 아니라 그 클래스가 정합니다 — `Frame`의 프로퍼티 목록은 [Roblox 공식 레퍼런스](https://create.roblox.com/docs/reference/engine/classes/Frame)가 소스입니다.

같이 끼워 넣은 `UICorner = 12`만은 프로퍼티가 아닙니다. `UICorner`/`UIPadding`/`UIPaddingOffset`/`UIScale` 네 키는 quad가 그 자리에 관리 자식(`UICorner` 인스턴스)을 만들어 붙여 주는 **숏핸드**입니다.

그리고 **`Parent`만은 이 테이블 안에 못 넣습니다.** 만들어진 뒤 밖에서 `.Parent`를 대입해 붙입니다 — 01장의 `screen.Parent = playerGui`가 그랬듯이.

<details>
<summary><strong><code>Parent</code>는 왜 안에 못 쓰나요?</strong></summary>

`Parent`를 문자 키 자리에 적으면 **그 키를 맡는 핸들러가 없어** 디스패치가 그 자리에서 던집니다.

```
Dispatch: no handler matched key Parent (value: Instance, brand: Inst) — check that the provider for this value (e.g. quad-roblox) is initialized
```

일부러 그렇게 두었습니다. `D.…`가 돌려주는 것은 이미 실물 Instance이고, "부모에 붙이는 일"은 만든 쪽이 아니라 **쓰는 쪽**이 정하는 것이기 때문입니다. 그래야 같은 컴포넌트를 어디에 붙일지가 호출 지점에 그대로 보입니다.

</details>

---

## 2. 자식 하나 넣기

라벨을 넣습니다. **자식 전용 키는 따로 없습니다** — 이름 없이 그냥 원소로 놓으면 그게 자식입니다.

`card`의 중괄호 안, 프로퍼티들 아래에 이 블록을 더하세요.

```luau
-- … 위쪽 코드에 이어집니다(방금 만든 card를 이렇게 고칩니다)
const card = D.Frame {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(240, 160),
    BackgroundColor3 = Color3.fromRGB(35, 35, 42),
    UICorner = 12,

    -- 여기부터가 숫자 키 자리: 키 없는 원소는 자식이 된다
    D.TextLabel {
        Position = UDim2.fromOffset(16, 0),
        Size = UDim2.new(1, -32, 0, 48),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextScaled = true,
        Text = "카운트: 0",
    },
}
```

**실행하면** 사각형 가운데에 흰 글씨로 `카운트: 0`이 보입니다.

한 테이블 안에 두 가지가 섞여 있습니다. **이름이 붙은 것(문자 키)은 프로퍼티**, **이름 없는 원소(숫자 키)는 자식**입니다. 숫자 키 자리에는 자식 말고도 여러 가지가 올 수 있는데, 그건 다음 장부터 하나씩 나옵니다.

숫자 키 자리는 `1, 2, 3…`으로 **빈틈없이 이어지는 순서 자리**입니다. 그래서 조심할 것이 하나 있습니다 — **중간이 `nil`로 비면 안 됩니다.** 지금처럼 자식을 직접 적는 동안에는 생길 일이 없지만, 나중에 "있을 수도 없을 수도 있는 것"을 그 자리에 넣기 시작하면 바로 마주칩니다.

<details>
<summary><strong>중간에 <code>nil</code>이 오면 무슨 일이 생기나요?</strong></summary>

Lua 테이블 리터럴에서 `{ a, nil, b }`처럼 중간 원소가 `nil`이면 그 자리는 **구멍**입니다. quad는 숫자 키 자리를 1번부터 순서대로 세다가 구멍을 만나면 그 자리에서 에러를 냅니다.

```luau
-- 새 예시: 별도 스크립트
const maybe = nil
const card = D.Frame {
    D.TextLabel { Text = "a" },
    maybe,                        -- ← 구멍
    D.TextLabel { Text = "b" },
}
```

```
Dispatch.recompute: sourceList[2] is nil — a nil hole in the numeric-key part of props ({ a, nil, b })? fill the optional slot with q.None; if you are writing a handler, bookkeeping is broken (setLength without setOffsetSource? the contract says None)
```

물음표까지가 여러분에게 하는 말입니다 — "2번 자리가 비었다, `q.None`으로 메꿔라". 세미콜론 뒤는 확장을 만드는 사람을 위한 힌트라 지금은 몰라도 됩니다. 맨 끝이 `nil`인 것은 그냥 거기서 끝난 것으로 읽혀 넘어가지만, 뒤에 원소가 하나라도 더 붙는 순간 구멍이 되므로 자리와 무관하게 비우지 않는 습관이 안전합니다.

</details>
<!-- mock 실측 2026-09-11: gs.nilhole.luau — 중간 nil은 위 에러 verbatim, 끝 nil은 자식 1개로 통과, q.None으로 메꾸면 자식 2개 -->

자리를 비워 둬야 할 때를 위한 값이 그래서 하나 있습니다 — `q.None`입니다. 구멍 대신 이것을 놓으면 자리는 차 있되 아무것도 만들지 않습니다. 지금은 숫자 키 자리에 자식만 직접 적고 있으니 쓸 일이 없고, [11장](/getting-started/11-components/)에서 컴포넌트가 바깥에서 뭔가를 넘겨받기 시작하면 실제로 필요해집니다.

---

## 더 알고 싶다면

- [레퍼런스: `D` — Instance 생성](/reference/roblox/02-d/) — 문자 키·숫자 키에 올 수 있는 것 전부, 숏핸드 키 넷, `D`에 별칭이 없는 클래스를 만드는 `D.New`
- [00. 설치](/getting-started/00-installation/) §2 3단계 — 타입 검사 플래그 넷(편집기와 CI에 같은 값을 넣어야 합니다)
