---
title: "02. 첫 화면 — 카드 하나 그리기"
description: "D.Frame 하나와 그 안의 라벨을 만들어, props 테이블의 해시 부분과 배열 부분이 각각 무엇인지 봅니다"
---
> **대상 독자**: [01. 프레임워크 설정하기](/getting-started/01-setup/)를 끝낸 개발자
> **목표**: 화면에 카드 하나를 띄우고, 그 안에 글씨를 한 줄 넣기

이 장부터 13장까지는 **하나의 예제**를 조금씩 키웁니다. 마지막에는 클릭할 때마다
숫자와 색이 바뀌는 카운터 여러 개가 되고, 각 장은 그 직전 장의 코드에 몇 줄을
더하는 식으로 진행합니다.

---

## 준비 코드

01장에서 만든 진입점 `Main.client.luau` 안에서 계속 짭니다. 위쪽 두 줄은 이제 이것뿐입니다.

```luau
const q = require("@game/ReplicatedStorage/Client/UI/Quad")
const D = q.D
```

---

## 1. 카드 만들기

01장의 `hello` 라벨을 지우고, 그 자리에 어두운 사각형 하나를 만듭니다.

```luau
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

**중괄호 안의 `이름 = 값`은 그 인스턴스의 프로퍼티입니다.** props 테이블에서 이 부분을 **해시 부분**이라고 부릅니다. 어떤 이름을 쓸 수 있는지는 quad가 정하는 게 아니라 그 클래스가 정합니다 — `Frame`의 프로퍼티 목록은 [Roblox 공식 레퍼런스](https://create.roblox.com/docs/reference/engine/classes/Frame)가 소스입니다.

같이 끼워 넣은 `UICorner = 12`만은 프로퍼티가 아닙니다. `UICorner`/`UIPadding`/`UIPaddingOffset`/`UIScale` 네 키는 quad가 그 자리에 관리 자식(`UICorner` 인스턴스)을 만들어 붙여 주는 **숏핸드**입니다.

그리고 **`Parent`만은 이 테이블 안에 못 넣습니다.** 만들어진 뒤 밖에서 `.Parent`를 대입해 붙입니다 — 01장의 `screen.Parent = playerGui`가 그랬듯이.

<details>
<summary><strong><code>Parent</code>는 왜 안에 못 쓰나요?</strong></summary>

`Parent`를 해시 자리에 적으면 **그 키를 맡는 핸들러가 없어** 디스패치가 그 자리에서 던집니다.

```
Dispatch: no handler matched key Parent (value: Instance, brand: Inst)
```

일부러 그렇게 두었습니다. `D.…`가 돌려주는 것은 이미 실물 Instance이고, "부모에 붙이는 일"은 만든 쪽이 아니라 **쓰는 쪽**이 정하는 것이기 때문입니다. 그래야 같은 컴포넌트를 어디에 붙일지가 호출 지점에 그대로 보입니다.

</details>

---

## 2. 자식 하나 넣기

라벨을 넣습니다. **자식 전용 키는 따로 없습니다** — 이름 없이 그냥 원소로 놓으면 그게 자식입니다.

`card`의 중괄호 안, 프로퍼티들 아래에 이 블록을 더하세요.

```luau
const card = D.Frame {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(240, 160),
    BackgroundColor3 = Color3.fromRGB(35, 35, 42),
    UICorner = 12,

    -- 여기부터가 배열 부분: 키 없는 원소는 자식이 된다
    D.TextLabel {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, -32, 0, 48),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextScaled = true,
        Text = "카운트: 0",
    },
}
```

**실행하면** 사각형 가운데에 흰 글씨로 `카운트: 0`이 보입니다.

한 테이블 안에 두 가지가 섞여 있습니다. **이름이 붙은 것(해시 부분)은 프로퍼티**, **이름 없는 원소(배열 부분)는 자식**입니다. 배열 부분에는 자식 말고도 여러 가지가 올 수 있는데, 그건 다음 장부터 하나씩 나옵니다.

<details>
<summary><strong>배열 부분에 넣을 게 없을 때는 뭘 넣나요?</strong></summary>

`q.None`입니다. 배열 리터럴 안의 표현식이 `nil`로 평가되면 그 자리가 **구멍**이 되고, 구멍이 있는 배열은 `#`도 순회 순서도 보장되지 않습니다.

```luau
-- ❌ props.Modifier가 없으면 1번 자리가 구멍이 된다
D.TextButton { props.Modifier, Text = "x" }

-- ✅ None이 자리를 지킨다 — 기여는 0이지만 위치는 그대로
D.TextButton { props.Modifier or q.None, Text = "x" }
```

`q.None`은 "여기에 아무것도 없다"를 뜻하는 명시적 센티널입니다. 지금은 배열 부분에 자식만 넣고 있으니 쓸 일이 없지만, 08장에서 컴포넌트가 바깥에서 뭔가를 넘겨받기 시작하면 이 관용구가 바로 나옵니다. 구멍이 났을 때의 증상은 [01. 컴포넌트 경계 규약과 스타일 합성](/how-to/01-component-conventions/) §2에 있습니다.

</details>

---

## 더 알고 싶다면

- [레퍼런스: `D` — Instance 생성](/reference/roblox/02-d/) — 해시 부분·배열 부분에 올 수 있는 것 전부, 숏핸드 키 넷, `D`에 별칭이 없는 클래스를 만드는 `D.New`
- [00. 설치](/getting-started/00-installation/) §2 3단계 — 타입 검사 플래그 넷(편집기와 CI에 같은 값을 넣어야 합니다)
