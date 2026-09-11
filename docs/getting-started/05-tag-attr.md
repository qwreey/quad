---
title: "05. 이름표와 속성 — Tag와 Attr"
description: "인스턴스에 CollectionService 태그와 Attribute를 숫자 키 자리의 값으로 선언하고, 붙인 것을 기준으로 화면 밖에서 찾아봅니다"
---
# [시작하기] 05. 이름표와 속성 — `Tag`와 `Attr`

> **대상 독자**: [04. 반응하기](./04-reacting.md)를 끝낸 개발자
> **목표**: 만든 인스턴스에 이름표와 값을 달고, 화면 밖의 코드가 그걸 기준으로 찾아 쓰게 하기

지금까지 숫자 키 자리에 넣은 것은 **자식**이었습니다. 다른 것도 올 수 있습니다 — 인스턴스
자신에 붙는 **표시**입니다. Roblox에는 그런 채널이 둘 있고(`CollectionService`의 **태그**와
인스턴스의 **Attribute**), quad에서는 둘 다 숫자 키 자리에 **값**으로 놓습니다.

---

## 지금까지의 코드

```luau
-- (Main.client.luau 계속 — 배치 프로퍼티는 생략합니다)
const count = q.Source(0)

const card = D.Frame {
    Size = UDim2.fromOffset(240, 160),
    BackgroundColor3 = Color3.fromRGB(35, 35, 42),
    UICorner = 12,

    -- 라벨과 버튼(크기·색 같은 프로퍼티는 04장 그대로라 여기선 줄였습니다)
    D.TextLabel { Text = count:Compute(function(c) return `카운트: {c:Get()}` end) },
    D.TextButton { Text = "+ 1", Activated = function() count:Set(count:Get() + 1) end },
}
```

---

## 1. 이름표 붙이기 — `q.Tag`

`card`의 **숫자 키** 자리 맨 앞에 한 줄을 더합니다.

```luau
-- … 위쪽 코드에 이어집니다
const card = D.Frame {
    q.Tag("Card"),          -- ← 숫자 키

    Size = UDim2.fromOffset(240, 160),
    -- …나머지 그대로…
}
```

**실행하면** 이 `Frame`이 `CollectionService`에 태그 `Card`로 잡힙니다.
<!-- 2026-09-10 Studio 실측 -->

```luau
-- (확인용 — 화면 밖 아무 스크립트에서)
const CollectionService = game:GetService("CollectionService")
print(#CollectionService:GetTagged("Card"))  --> 1
```

<details>
<summary><strong>quad-base가 태그를 어떻게 처리하나요?</strong></summary>

quad-base는 태그 채널을 직접 건드리지 않습니다. 이름 집합을 계산해 백엔드가 심어 둔
`addTag`/`removeTag`에 넘기고, quad-roblox가 그것을 `CollectionService`로 잇습니다.

</details>

<details>
<summary><strong>같은 이름의 <code>Tag</code>를 두 곳에서 붙이면요?</strong></summary>

태그는 **집합**이라 두 자리의 요구가 합집합이 됩니다. 다만 quad는 자리마다 따로 세어 두었다가
**마지막 자리가 물러날 때** 비로소 엔진에서 뗍니다.

```luau
const inst = D.Frame { q.Source(q.Tag("Card")), q.Source(q.Tag("Card", "Panel")) }
-- 태그 {Card, Panel} — 엔진 호출은 addTag:Card, addTag:Panel 둘뿐(Card는 한 번만)
```

두 번째 자리가 둘 다 놓아도(`:Set(q.Tag())`) 나가는 것은 `removeTag:Panel` 하나입니다 — `Card`는
첫 자리가 아직 잡고 있습니다. 그래서 컴포넌트 여럿이 같은 인스턴스에 같은 이름을 요구해도
서로를 지우지 않습니다. 같은 불변 `Tag` 객체를 두 자리에 놓아도 두 자리로 셉니다.

</details>

---

## 2. 이름표도 값에서 나올 수 있습니다

태그 자리에 `State`를 놓으면 그 파이프가 내놓는 `Tag`가 그대로 이름표가 됩니다.

```luau
const card = D.Frame {
    q.Tag("Card"),
    count:Compute(function(c)
        return q.Tag(if c:Get() % 2 == 0 then "Even" else "Odd")
    end),

    -- …나머지 그대로…
}
```

**실행하면** 버튼을 누를 때마다 이름표가 갈아 끼워집니다 — `{Card, Even}` → `{Card, Odd}` →
`{Card, Even}`. 정적으로 적은 `Card`는 교체 내내 남습니다(1절의 자리별 셈 그대로).
엔진 호출도 **진짜 바뀐 이름에만** 나갑니다 — 클릭 한 번이 만드는 것은 `removeTag:Even`과
`addTag:Odd` 둘뿐입니다.
<!-- 2026-09-10 Studio 실측 -->

---

## 3. 값 심기 — `q.Attr`

이름표가 "무엇인가"라면 Attribute는 "얼마인가"입니다. 여러 개는 그룹 하나로, 하나씩은
타입별 슈가로 놓습니다.

```luau
-- … 위쪽 코드에 이어집니다
const active = q.Source(true)

const card = D.Frame {
    q.Tag("Card"),

    q.Attr { Kind = "counter", Step = 1 },   -- 그룹 하나
    q.BooleanAttr("Active", active),         -- 값 하나(State도 된다)

    -- …나머지 그대로…
}
```

**실행하면** 셋이 그 인스턴스의 Attribute로 심깁니다(Studio 속성 창 아래쪽 **Attributes** 칸).
값 타입도 그대로 보존됩니다 — 문자열은 문자열로, 숫자는 숫자로, 불리언은 불리언으로.

```luau
print(card:GetAttributes())  --> {Active = true, Kind = "counter", Step = 1}

active:Set(false)            --> {Active = false, Kind = "counter", Step = 1}
active:Set(q.None)           --> {Kind = "counter", Step = 1}   -- Active가 사라진다
```
<!-- 2026-09-10 Studio 실측 -->

<details>
<summary><strong><code>Attr</code> 값을 지우려면요?</strong></summary>

지우기의 유일한 표현은 **`q.None`**입니다. 셋을 구별하세요.

| 한 일 | 결과 |
|---|---|
| 값에 `q.None`을 둔다 | 엔진에서 그 속성이 **삭제**됩니다 |
| 바인딩된 `State`가 `q.None`이 된다 | 같습니다 — 삭제됩니다 |
| 그 `Attr` 값 객체를 다른 것으로 **교체**한다 | 옛 속성 값이 엔진에 **그대로 남습니다** |

세 번째가 함정입니다. 자리에서 물러나는 `Attr`은 구독을 끊고 이름을 반납할 뿐 엔진 쪽 값에는
손대지 않습니다. `nil`은 애초에 거부됩니다 — 평범한 테이블은 `nil`을 담을 수 없어 항목이
조용히 사라지기 때문입니다.

</details>

지우기 말고 하나가 더 있습니다 — 한 인스턴스의 **두 자리가 같은 이름**을 요구하는 경우입니다.

<details>
<summary><strong>이름이 겹치는 <code>Attr</code>을 한 인스턴스의 두 자리에 놓으면요?</strong></summary>

**이기는 쪽이 없습니다 — 그 자리에서 에러가 납니다.**

```luau
D.Frame { q.Attr { Kind = "counter" }, q.Attr { Kind = "other" } }
-- AttrKey: attribute "Kind" is already bound by another owner
```

이름 하나의 주인은 하나여야 한다는 규칙이라, 겹칠 수 있으면 **먼저 합쳐서 하나로** 넘깁니다.
겹침을 사고로 볼 자리에는 `q.Attr.Merged(a, b)`(겹치면 에러), 의도된 덮어쓰기에는
`q.Attr.Overridden(a, b)`(뒤 인자가 조용히 이김)를 씁니다.

</details>

---

## 4. 붙인 것으로 찾기 — `QueryDescendants`

이름표와 속성이 붙었으니 화면 밖의 코드가 그걸 기준으로 인스턴스를 고를 수 있습니다.
`Instance:QueryDescendants(selector)`는 선택자에 맞는 **자손 전부**를 배열로 돌려줍니다.
01장에서 만든 `screen`(ScreenGui)에 대고 부릅니다.

```luau
print(#screen:QueryDescendants(".Card"))            --> 1   태그가 Card인 것
print(#screen:QueryDescendants("[$Kind=counter]"))  --> 1   Attribute Kind가 counter인 것
```

**실행하면** 둘 다 `1`이 찍힙니다 — 태그로 고른 것도 속성으로 고른 것도 방금 만든 그 카드 하나입니다.

<details>
<summary><strong>선택자 문법은 뭐가 더 있나요?</strong></summary>

| 선택자 | 뜻 | 예 |
|---|---|---|
| `ClassName` | 클래스(`IsA` 기준이라 상위 클래스도 맞습니다) | `Frame`, `GuiObject` |
| `.Tag` | `CollectionService` 태그 | `.Card` |
| `#Name` | 인스턴스의 `Name` | `#Card` |
| `[$Attr]` / `[$Attr=값]` | Attribute가 있는가 / 값이 같은가 | `[$Kind]`, `[$Step=1]` |
| `[속성=값]` | 프로퍼티 값이 같은가 | `[Visible=true]` |
| `A > B` / `A >> B` | 직계 자식 / 자손 | `.Card >> TextLabel` |
| `A, B` | 합집합 | `Frame, TextLabel` |

<!-- 2026-09-10 Studio 실측(Studio 버전 0.738) -->

</details>

<details>
<summary><strong>선택자가 조용히 0개를 돌려주는데요?</strong></summary>

에러 없이 빈 배열이 오는 경우가 둘 있고, 둘 다 CSS 습관에서 옵니다.

1. **공백은 자손이 아니라 AND입니다.** `.Card TextLabel`은 "`Card` 태그가 붙은 **동시에**
   `TextLabel`인 것"으로 읽혀 대개 0개가 됩니다. 자손은 `>>`입니다.
2. **Attribute에 `$`를 빠뜨리면 에러가 아니라 0개입니다.** `[Kind=counter]`는 `Kind`라는
   **프로퍼티**를 찾으므로 아무것도 안 걸립니다.

값에 공백이 있으면 큰따옴표로 감쌉니다(`[$Label="two words"]`). 작은따옴표는 에러이고, 값 없는
존재 검사는 Attribute에만 됩니다 — `[Visible]`은 `'=' expected after property name`이 납니다.

</details>

여기서 붙인 태그는 **UI 스타일시트**가 고르는 기준이기도 합니다. `StyleRule`의 선택자에서
`.Card`는 지금 붙인 그 태그를 가리키므로, quad로 선언한 태그 위에 스타일시트를 얹어 바깥에서
모양을 갈아 끼우는 구성이 가능합니다. 구성법 자체는 Roblox 쪽 기능이라 아래 공식 문서로 넘깁니다.

<details>
<summary><strong>백엔드 없이도 되나요?</strong></summary>

**값을 만들고 합성하는 것까지는 됩니다.** 실제로 인스턴스에 **적용**하는 것만 백엔드의 몫이라,
백엔드 없이 거기까지 가면 안내 에러가 납니다 — `quad: addTag is not available — no backend has
installed the tag ops`. 01장에서 `Quad:UseProvider(QuadRoblox)`를 이미 했다면 신경 쓸 일이 없습니다.

</details>

---

## 더 알고 싶다면

- [레퍼런스: `Tag` / `Attr`](../reference/core/09-tag-attr.md) — 전체 표면(`tag:Added`/`:Contains`/`:Names`, `q.AttrKey`, `StringAttr`/`NumberAttr`, 에러 문구)
- [Roblox: `CollectionService`](https://create.roblox.com/docs/reference/engine/classes/CollectionService) · [인스턴스 Attribute](https://create.roblox.com/docs/studio/properties#instance-attributes)
- [Roblox: `Instance:QueryDescendants`](https://create.roblox.com/docs/reference/engine/classes/Instance#QueryDescendants)
- [Roblox: UI 스타일링](https://create.roblox.com/docs/ui/styling) · [`StyleRule.Selector`](https://create.roblox.com/docs/reference/engine/classes/StyleRule#Selector) — 태그를 선택자로 삼는 스타일시트 구성
