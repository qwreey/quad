---
title: "07. Studio에서 만든 UI에 반응성 붙이기 — `Claim`과 Clone 패턴"
description: "Studio에서 디자인한 UI 트리에 Claim으로 quad의 반응성을 붙이는 방법을 설명합니다"
---
> **대상 독자**: 디자이너가 Studio에서 시각적으로 완성해 둔 UI(StarterGui, 템플릿 모델)에
> quad의 반응성을 연결하려는 개발자
> **다루는 개념**: `q.Claim`, `D.Mapper` 디스크립터, `template:Clone()`, `Slot`

```luau
-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 참고)
local Quad = require(<quad-base 모듈 경로>)
local QuadRoblox = require(<quad-roblox 모듈 경로>).QuadRoblox
local QuadTypes = require(<quad-types 모듈 경로>)
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
local D = q.D
local M = D.Mapper
```

---

## 1. 왜 `q.Claim`인가?

디자이너가 Studio에서 맞춰 둔 폰트·패딩·그라디언트를 코드로 다시 쓰는 것은
낭비이자 디자인 싱크가 깨지는 원인입니다. `q.Claim`은 **이미 존재하는
Instance 트리를 quad 소유로 가져와, quad가 만든 트리와 똑같이 구동**합니다.

```luau
local template = script.Parent:WaitForChild("ItemCard")
local clicks = q.Source(0)
local clickText: QuadTypes.State<string> = clicks:Compute(function(c)
    return `클릭 횟수: {c:Get()}`
end)

q.Claim(template, M.Frame(M.Root)({
    M.TextLabel("ItemName")({ Text = "검" }),
    M.ImageLabel("ItemIcon")({ Image = "rbxassetid://1" }),
    M.TextButton("ActionButton")({
        Text = clickText,
        Activated = function()
            clicks:Set(clicks:Get() + 1)
        end,
    }),
    Visible = true,
}))
```

`Claim`은 넘긴 Instance를 **그대로 돌려줍니다**(`local inst = q.Claim(inst, ...)`).

### 두 번째 인자는 항상 `D.Mapper` 디스크립터입니다

`Claim(inst, { Text = "..." })`처럼 평범한 props 테이블을 넘기면 즉시
`Claim: second argument must be a D.Mapper descriptor` 에러입니다. 모양은
**커링 세 단계**입니다.

```
M.<ClassName>(<키>)(<props 테이블>)
```

- 루트 자리의 키는 센티널 `M.Root`, 자식은 이름으로 찾습니다.
- props 테이블 안은 `D.<Class>`와 똑같습니다: 문자 키에 프로퍼티·이벤트,
  숫자 키 자리에 자식 디스크립터·`Slot`·`Modifier`·`Ref` 같은 값.
- **디스크립터는 1회용입니다.** 두 번 쓰면
  `Claim: mapper descriptor was already used (descriptors are one-shot)` —
  템플릿 사본마다 새로 만드세요.

props에 안 쓴 프로퍼티는 quad가 건드리지 않습니다.

---

## 2. 대량 생성: `template:Clone()` + `Claim`

`Claim`이 Instance를 돌려주므로, 사본은 그대로 `Slot`의 요소가 됩니다.

```luau
local ItemTemplate = ReplicatedStorage:WaitForChild("Templates"):WaitForChild("ItemCard")

local function ItemCard(item: { id: string, label: string }, label: QuadTypes.Source<string>)
    local card = ItemTemplate:Clone()
    return q.Claim(card, M.Frame(M.Root)({
        M.TextLabel("ItemName")({ Text = label }),
        M.ImageLabel("ItemIcon")({ Image = "rbxassetid://2" }),
        M.TextButton("ActionButton")({
            Text = "사용",
            Activated = function()
                print("Selected:", item.id)
            end,
        }),
    }))
end

local rows = q.Slot<<Instance>>():List(itemsState, function(item: any, _index, _offset, prev, ud): (any, any)
    if item == q.KeyGone then
        return nil, ud
    end
    if prev then
        ud.label:Set(item.label) -- 재활용: userdata 안의 Source만 갱신
        return prev, ud
    end
    local label = q.Source(item.label)
    return ItemCard(item, label), { label = label }
end, function(item)
    return item.id
end) -- 생성자의 제네릭은 추론되지 않는다 — `q.Slot<<Instance>>()`처럼 명시 타입 인자로 준다
```

`Slot:List`의 인자 순서는 `(data, updateFn, keyFn?, opts?)`이고 `updateFn`은
`(item, index, offset, prev, ud)`를 받아 `(요소, userdata)`를 돌려줍니다 —
상세는 [03. `Slot:List`로 긴 목록 다루기](/how-to/03-virtualized-infinite-scroll/).

### 템플릿을 코드로 만들어도 됩니다

템플릿이 꼭 Studio에서 와야 하는 것은 아닙니다. **정적 프로퍼티만 심은 트리를
`D`로 한 번 만들어 두고**, 그것을 `:Clone()`한 사본마다 `Claim`으로 동적 바인딩을
얹는 것도 같은 패턴입니다. 만들 원소가 아주 많을 때는 하나하나 `D`로 짓는 것보다
사본을 뜨는 쪽이 훨씬 싸고, 사본은 정적 프로퍼티가 엔진 쪽에서 이미 다 들어간
채로 나옵니다. 템플릿이 코드에 있어 리뷰와 diff가 된다는 것도 이 방식의 이유입니다.

```luau
-- Templates.luau — 정적인 것만. 자식의 `Name`이 나중에 Claim이 찾을 열쇠다
local ItemTemplate = D.Frame {
    Name = "ItemCard",
    Size = UDim2.fromOffset(240, 64),
    BackgroundColor3 = Color3.fromRGB(35, 35, 42),
    BorderSizePixel = 0,
    UICorner = UDim.new(0, 8),

    D.TextLabel { Name = "ItemName", Text = "-", TextSize = 14 },
    D.TextButton { Name = "ActionButton", Text = "사용" },
}
```

이 절 첫머리의 `ItemCard`를 그대로 대체합니다 — 시그니처가 같으니 위의 `Slot:List`
코드는 손댈 것이 없습니다.

```luau
local function ItemCard(item: { id: string, label: string }, label: QuadTypes.Source<string>)
    local card = ItemTemplate:Clone()          -- 정적 프로퍼티는 이미 들어가 있다
    return q.Claim(card, M.Frame(M.Root)({     -- 디스크립터는 사본마다 새로 만든다
        M.TextLabel("ItemName")({ Text = label }),
        M.TextButton("ActionButton")({
            Activated = function()
                print("Selected:", item.id)
            end,
        }),
    }))
end
```

**State·Store 바인딩과 이벤트는 사본으로 따라오지 않습니다.** `:Clone()`이 복사하는
것은 그 순간의 프로퍼티 값과 자식이고, quad가 인스턴스마다 따로 들고 있는 소유·구독
부기는 사본에 없습니다 — 그래서 사본은 quad가 모르는 트리이고, 그래서 `Claim`을 걸
수 있습니다. **바뀌는 값은 전부 `Claim` 쪽 디스크립터에 심으세요.**

지킬 것 셋입니다.

- **원본 템플릿에는 `Claim`을 걸지 마세요.** `D`가 만든 것은 이미 quad 소유라
  `nativeClaim: Instance is already claimed by quad`입니다. 원본은 찍어내는 틀로만
  두고, claim하는 것은 언제나 사본입니다.
- **매핑할 자식에는 `Name`을 주세요.** `D.TextLabel { … }`의 기본 이름은 클래스
  이름이라, 이름을 안 주면 `M.TextLabel("ItemName")`이 찾을 자식이 없습니다. 이름
  부재는 UB라 quad의 안내 문구가 아니라 내부에서 그대로 크래시합니다.
- **템플릿에서 숏핸드 키로 만든 `UI*`는 디스크립터에서 다시 쓰지 마세요.** 위
  템플릿의 `UICorner = UDim.new(0, 8)`이 만든 자식은 사본에도 그대로 있습니다 —
  `Claim` 쪽 props에서 숏핸드 키를 또 쓰면 `UICorner`가 둘이 됩니다.

---

## 3. `Claim`의 계약 세 가지

### 1) 한 번만 Claim한다

한 Instance는 생애 동안 정확히 한 번만 claim됩니다. `D.New`로 만든 Instance도
이미 claim된 상태입니다. 다시 걸면 `nativeClaim: Instance is already claimed by quad`
입니다 — 별도 레지스트리가 아니라 claim 시점에 심는 소유 데이터의 유무로
판정합니다. **여러 quad 인스턴스가 한 트리를 나눠 claim하는 것은 UB**입니다.

### 2) 디스크립터를 쓴 노드마다, 그 노드의 직계 자식은 전부 적는다

quad는 claim한 Instance의 자식 자리를 부기(bookkeeping)합니다. 그리는 직계
자식 중 디스크립터에 안 적힌 것이 남으면 quad의 장부와 실제 자식이 어긋나,
그 노드 아래에 넣는 `Slot`의 삽입 위치와 `Offset`/`Length`가 틀어집니다.

**그렇다고 트리 끝까지 훑어 내려가야 하는 것은 아닙니다.** 이 규칙은 디스크립터를
쓴 노드 하나하나에 대해서만 묻습니다 — "이 노드의 직계 자식을 전부 적었나".
아래로 더 바인딩할 것도, 넣고 뺄 `Slot`도 없는 자식이라면 **props를 비워** 적고
거기서 멈추면 됩니다.

```luau
M.Frame("Footer")({})   -- 자리는 채우되, 이 아래로는 내려가지 않는다
```

빈 매핑도 그 자식을 quad 소유로 만듭니다. 대신 그 안쪽은 quad가 보지도 세지도
않으니, 그 아래에 `Slot`이나 동적 자식을 넣기로 하는 순간 그 노드의 직계 자식도
전부 적어야 합니다.

- **디스크립터 배열의 순서가 정본입니다.** 기존 트리의 순서가 다르면 맞추는
  것은 사용자 책임입니다 — quad는 재정렬하지 않습니다(Roblox에서는 물리
  순서에 의미가 없어 비용이 0입니다).
- **`UICorner` 같은 `UI*`는 부기 대상이 아닙니다** — 그려지지 않고 단순히
  `Parent`로 매달리기 때문입니다. 다만 템플릿의 `UICorner`와 quad의 숏핸드
  키를 같이 쓰면 둘이 생기니 하나만 쓰세요.
- **이름 중복이나 부재는 UB입니다.** 특히 없는 이름을 적으면 quad의 안내 문구
  없이 내부에서 그대로 크래시하니, 템플릿의 자식 이름과 디스크립터의 키를 맞춰
  두세요.

### 3) `PlayerGui`/`CoreGui`는 대상이 아니다

`PlayerGui`/`CoreGui`는 엔진과 여러 스크립트가 자식을 넣고 빼는 공유
컨테이너라 "소유"가 성립하지 않습니다. **이건 런타임 검사가 아니라 설계상
대상 밖이라는 뜻입니다** — quad가 막아주지 않으니 걸지 마세요. 대신 quad
트리의 **루트는 `.Parent`를 밖에서 설정해도 됩니다**(루트의 부모는 어떤
부기에도 속하지 않습니다).

```luau
local screen = q.Claim(existingScreenGui, M.ScreenGui(M.Root)({ rows }))
screen.Parent = player:WaitForChild("PlayerGui") -- 허용: 루트의 Parent는 부기 밖
```

여러 스크립트가 한 목록을 나눠 써야 하면, `ScreenGui` 하나를 만들거나 claim해서
그 안의 `Slot`을 돌려주는 중간 모듈을 두세요.

> `props`에 `Parent`를 넣는 것은 `Claim`에서도 금지입니다 — 붙이는 것은 props가
> 아니라 밖의 한 줄입니다.

---

## 4. 사전 제작된 컨테이너에 `Slot` 꽂기

Studio에서 만든 창 안의 특정 영역에 동적 목록을 마운트하려면, 그 영역을
claim하고 `Slot`을 숫자 키 자리에 넣으면 됩니다.

```luau
local function ShopWindow(isOpen: QuadTypes.Source<boolean>, rows: QuadTypes.Slot<Instance>)
    local window = ReplicatedStorage:WaitForChild("Templates"):WaitForChild("ShopWindow"):Clone()

    q.Claim(window, M.Frame(M.Root)({
        M.TextButton("CloseButton")({
            Activated = function()
                isOpen:Set(false)
            end,
        }),
        -- 그려지는 직계 자식은 전부 적는다. 손댈 것이 없으면 빈 props로
        M.TextLabel("TitleText")({}),
        M.Frame("ContentArea")({ rows }),
        Visible = isOpen,
    }))

    return window
end
```

`ContentArea`를 따로 `Claim`하지 말고 부모 디스크립터 안에서 매핑하세요 —
부모를 claim할 때 매핑된 자식도 함께 claim되므로 뒤에 다시 걸면 이중 claim
에러입니다.

---

## 5. `Claim`에서 달라지는 것 하나

`PreRef`(와 그 위의 `OnCreated` 훅)는 `D.New`에서 *"아직 자식도 프로퍼티도
없다"*를 보장하지만, `Claim` 경로에서는 그렇지 않습니다 — 인스턴스는 이미
템플릿의 자식과 프로퍼티를 갖고 있습니다. 여기서 `PreRef`가 뜻하는 것은
**"quad가 이 인스턴스에 무언가 하기 전"** 뿐입니다.
