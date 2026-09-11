---
title: "01. 컴포넌트 경계 규약과 스타일 합성"
description: "props 테이블의 두 부분이 지키는 규칙, or None 경계 관용구, Modifier 우선순위 불변식 셋, Tag/Attr, 재사용 로직 추출을 정리합니다"
---
> **대상 독자**: 재사용 가능한 컴포넌트를 만들어 여러 화면에 나눠 쓰려는 개발자
> **다루는 개념**: props 테이블의 병합 규칙, 숫자 키 자리의 `or None` 관용구, `Modifier` 우선순위, `Tag`/`Attr`, Hook 규칙 없는 팩토리

[시작하기 11. 컴포넌트로 쪼개기](/getting-started/11-components/)에서 컴포넌트가 평범한 함수라는 것을, [09. Modifier](/getting-started/09-modifier/)에서 스타일을 숫자 키 자리에 놓는다는 것을 봤습니다. 이 문서는 그 경계에서 지켜야 하는 규약을 모아 둔 곳입니다.

이 문서의 예제는 모두 아래 준비 코드를 앞에 둔 상태를 가정합니다.

```luau
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("@game/ReplicatedStorage/Client/UI/Quad")
local D = q.D
local None = q.None

-- 값이 아니라 '타입 이름'을 가져오는 모듈
local QuadTypes = require("@game/ReplicatedStorage/roblox_packages/quad_types") -- 설정 모듈이 다시 내보내지 않는 타입(`QuadTypes.StateMarker<T>` 등)
-- 클래스별 Modifier·요소 타입(`TextButtonModifier`/`IntoTextButton`/`FrameElem` 등)은 생성된 D 모듈에서
local DTypes = require(<quad-roblox D 모듈 경로>)
```

아래 예제에서 `DTypes`로 쓰는 클래스별 타입(`TextButtonModifier`, `IntoTextButton`, `FrameElem` …)은 quad-roblox의 **생성 `D` 모듈**에 들어 있습니다 — 가져오는 경로는 설치 구성에 따라 다릅니다(00-installation 참고).

---

## 1. props 테이블의 두 부분이 지키는 규칙 넷

`D.Frame { ... }`에 넘기는 테이블은 단순한 설정 딕셔너리가 아닙니다. **문자 키**와 **숫자 키**가 각각 다른 뜻을 갖습니다.

```luau
local isHovered = q.Source(false)
local CommonButtonModifier = D.Modifier.Frame {
    BorderSizePixel = 0,
}

D.Frame {
    -- [1] 문자 키: 프로퍼티 바인딩 (정적 값 또는 반응형 State/Tween)
    Size = UDim2.new(0, 200, 0, 50),
    BackgroundColor3 = isHovered:Compute(function(h)
        return if h:Get() then Color3.fromRGB(80, 120, 240) else Color3.fromRGB(50, 50, 60)
    end),

    -- [2] 문자 키: 이벤트 리스너 (엔진이 주는 인자만 받는다 — self는 안 온다)
    MouseEnter = function() isHovered:Set(true) end,
    MouseLeave = function() isHovered:Set(false) end,

    -- [3] 숫자 키: 재사용 가능한 스타일 (Modifier)
    CommonButtonModifier,

    -- [4] 숫자 키: 자식 요소
    D.TextLabel {
        Text = "클릭하세요",
    },
}
```

1. **숫자 키**: 자식 인스턴스, `Modifier`, `Ref`/`PreRef`/`PostRef`, `Slot`, `Observer`/`Effect`, `Tag`/`Attr`, `q.OnChange(...)`가 들어가는 자리입니다. **순서가 의미를 갖습니다** — 뒤에 온 `Modifier`가 앞의 것을 필드 단위로 덮습니다. 자식 전용 키는 따로 없습니다 — **이름 없는 자리(숫자 키)가 곧 자식**입니다.
2. **문자 키**: 프로퍼티·이벤트가 각자 전용 핸들러를 통해 인스턴스에 바인딩됩니다. 문자 키에 직접 적은 프로퍼티는 숫자 키의 어떤 `Modifier`보다 우선합니다. 다만 `UICorner`/`UIPadding`/`UIPaddingOffset`/`UIScale` 네 키는 프로퍼티가 아니라 **관리 자식을 만드는 숏핸드**입니다(quad가 그 자리에 `UICorner` 같은 자식을 만들어 붙이고 관리합니다).
3. **한 번에 처리된다**: 숫자 키 자리가 있으면 그 전체가 하나의 배치로 묶여 재계산이 **끝에 한 번** 일어납니다. 그 안에서 어떤 핸들러가 어떤 순서로 매칭되는지는 [Quadnomicon Vol. 8: 디스패치 엔진](/quadnomicon/08-extensible-dispatch-engine/)이 다룹니다.
4. **정리(Teardown)**: 인스턴스를 `Destroy()`하면 거기 묶인 구독과 트윈은 더 이상 실행되지 않습니다. Quad는 인스턴스마다 걸어 둔 엔진 연결이 끊겼는지로 생존을 판정하고, 실제 메모리 회수는 Luau GC에 맡깁니다. 수동으로 disconnect할 것은 없고, **정리해야 할 것들을 담아 들고 다니는 스코프 객체도 없습니다**(Fusion의 `Scope`, Vide의 소유 스코프 자리에 해당하는 것이 quad에는 없습니다).

---

## 2. 컴포넌트 경계 규약: 숫자 키 자리의 `or None`

재사용 가능한 컴포넌트는 호출자가 스타일(`Modifier`)이나 내부 인스턴스 참조(`Ref`)를 주입할 수 있어야 합니다. 이때 지켜야 하는 관용구가 하나 있습니다.

`Ref`는 `q.Ref(nil)`로 만들어 숫자 키 자리에 놓아 두면 **quad가 만들어진 인스턴스를 채워 주는 빈 상자**입니다 — 나중에 `ref.Value`로 꺼내 씁니다.

```luau
local function MaterialButton(props: { read Text: string?, read Modifier: DTypes.TextButtonModifier?, read Ref: q.Ref<TextButton?>? }): TextButton
    return D.TextButton {
        props.Modifier or None, -- ⭐ 숫자 키 자리에서만 의미가 있는 관용구
        props.Ref or None,

        Text = props.Text or "",
    }
end
```

### 왜 `or None`인가, 그리고 왜 하필 숫자 키 자리인가

`Modifier`·`Ref`·`Slot`·`Observer`·`Effect`·`Tag`·`Attr` 같은 값은 **문자 키가 아니라 숫자 키 자리**에 놓습니다. 문자 키의 값 자리에 `Modifier`를 두면 디스패치가 거부합니다.

그런데 배열 리터럴 안의 표현식이 `nil`로 평가되면 그 자리에 **구멍(nil-hole)** 이 생깁니다. 선두나 중간이 구멍이면 quad는 그 자리에서 **에러를 냅니다**(`Dispatch.recompute: sourceList[N] is nil — a nil hole …`). 조용히 넘어가는 것은 **꼬리 구멍뿐**이고, 그마저 뒤에 원소를 하나 더 붙이는 순간 에러가 됩니다.

그래서 구멍 있는 props 테이블은 **계약 밖**입니다 — 꼬리 구멍이 통과하는 것은 우연이지 보장이 아닙니다. 증상과 에러 메시지는 [09. quad 에러 읽는 법과 런타임 디버깅](/how-to/09-debugging-and-troubleshooting/)의 함정 1에 정리돼 있습니다.

```luau
-- ❌ props.Modifier가 없으면 1번 자리가 구멍이 된다 — 그 자리에서 에러
D.TextButton { props.Modifier, props.Ref, Text = "x" }

-- ✅ None이 자리를 지킨다 — 기여는 0이지만 위치는 그대로
D.TextButton { props.Modifier or None, props.Ref or None, Text = "x" }
```

`None`은 "여기에 아무것도 없다"를 뜻하는 명시적 센티널입니다. 자리를 유지하되 아무것도 기여하지 않으므로, 호출자가 `Modifier`만 생략하든 `Ref`만 생략하든 나머지 원소는 원래 위치 그대로 꽂힙니다.

> `props.Modifier` / `props.Ref` / `props.Children`이라는 이름은 이 문서가 따르는 관례이고, 언어나 엔진이 강제하는 것은 아닙니다. 참고로 `Slot`을 반환하는 컴포넌트에는 이 파라미터들이 없습니다 — 꽂을 루트 인스턴스가 없기 때문입니다. `Slot`은 자식이 들어갈 **자리**를 숫자 키 자리에 잡아 두고 그 구간의 요소를 quad가 관리하게 하는 값입니다([시작하기 10. 자식이 들어갈 자리](/getting-started/10-slot/) 참고).

---

## 3. 스타일 합성 및 우선순위 3대 불변식

컴포넌트가 자체 기본 디자인을 가지면서도 호출자의 커스텀 스타일을 수용해야 할 때가 있습니다. 병합 규칙은 셋뿐입니다.

1. **직접 적은 문자 키가 이긴다**:
   `D.TextButton { props.Modifier or None, Text = "확정" }`에서 `Text`는 어떤 `Modifier`가 무엇을 갖고 오든 그대로 유지됩니다. 평탄화는 이미 채워진 키를 건너뛰기 때문입니다.
2. **숫자 키 자리에서는 뒤에 온 `Modifier`가 이긴다**:
   `D.TextButton { BaseMod, props.Modifier or None }`에서 뒤쪽 `Modifier`의 필드가 앞쪽을 덮습니다(역방향 스캔으로 마지막 것이 먼저 기록되고, 이미 기록된 키는 건너뜁니다).
3. **`Modifier.Overridden(A, B)`도 같은 방향**:
   명시적 합성에서도 뒤 인자(`B`)가 앞 인자(`A`)의 같은 필드를 덮습니다. 닷 형태 `q.Modifier.Overridden(a, b)`와 콜론 형태 `a:Overridden(b)` 둘 다 됩니다.

### 클래스 태그가 붙은 Modifier 팩토리

`Modifier`는 단순한 딕셔너리가 아닙니다. 어떤 클래스에 적용 가능한지 타입에 실려 있어서, `TextButton` 전용 `Modifier`를 `Frame`의 숫자 키 자리에 넣으면 타입 검사에서 걸립니다.

> **타입 이름 하나만 먼저**: 아래 `props`처럼 반응형 값을 **받는 입력 자리**에는 `StateMarker<T>`를, 컴포넌트 안에서 만든 지역 변수나 반환 타입처럼 메소드를 실제로 부르는 자리는 `State<T>`를 씁니다. 둘은 같은 `quad-types`에서 오지만, 설정 모듈이 다시 내보내는 아홉에 `State`는 있고 `StateMarker`는 없어서 이 문서에서는 각각 `q.State<T>`·`QuadTypes.StateMarker<T>`로 적힙니다.

```luau
type ButtonProps = {
    read Text: string | QuadTypes.StateMarker<string>,
    read OnClick: () -> (),
    read Modifier: DTypes.TextButtonModifier?,
    read Ref: q.Ref<TextButton?>?,
}

local function CustomButton(props: ButtonProps): TextButton
    -- [1] TextButton 전용으로 태그된 기본 스타일
    local baseStyle = D.Modifier.TextButton {
        Size = UDim2.fromOffset(140, 40),
        BackgroundColor3 = Color3.fromRGB(0, 140, 240),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 16,
    }

    return D.TextButton {
        -- [2] 불변식 2 — 뒤에 온 props.Modifier가 baseStyle을 필드 단위로 덮는다
        baseStyle,
        props.Modifier or None,
        props.Ref or None,

        -- [3] 불변식 1 — 문자 키는 어떤 Modifier도 덮지 못한다
        Text = props.Text,
        MouseButton1Click = props.OnClick,
        UICorner = 8,
    }
end
```

`D.Modifier.<Class>`는 위처럼 테이블을 넘기는 형태와 빌더 체인 형태(`D.Modifier.TextButton():TextSize(16):Text("x")`) 둘 다 지원합니다.

### 사용하는 쪽에서의 유연성

```luau
-- 기본 스타일 그대로
local btn1 = CustomButton { Text = "확인", OnClick = function() print("기본 버튼") end }

-- 크기와 색상만 위험 버튼으로 커스텀
local btn2 = CustomButton {
    Text = "삭제",
    OnClick = function() print("삭제 버튼") end,
    Modifier = D.Modifier.TextButton {
        BackgroundColor3 = Color3.fromRGB(240, 60, 60),
        Size = UDim2.fromOffset(100, 36),
    },
}
```

케이스 B에서 `BackgroundColor3`와 `Size`는 덮어씌워지고, 기본 스타일의 `TextColor3`/`TextSize`는 그대로 남습니다.

> 상위 클래스 `Modifier`(예: `D.Modifier.GuiObject { ... }`)까지 받고 싶다면 `props.Modifier`를 인터페이스 타입 `DTypes.IntoTextButton?`으로 선언하고, 꽂을 때 `if props.Modifier then props.Modifier:AsTextButton() else None`으로 내려받으세요.

---

## 4. 자식을 받는 컴포넌트에 타입 붙이기

호출자가 넣을 자식은 **`Slot` 하나로 받습니다**([시작하기 10. 자식이 들어갈 자리](/getting-started/10-slot/)). 그 자리에 타입을 붙이면 이렇게 됩니다.

```luau
local function ModalDialog(props: { read Title: string, read Children: q.Slot<Instance>? }): Frame
    return D.Frame {
        Size = UDim2.fromOffset(400, 300),
        BackgroundColor3 = Color3.fromRGB(25, 25, 30),

        -- 헤더 타이틀
        D.TextLabel {
            Text = props.Title,
            Size = UDim2.new(1, 0, 0, 40),
        },

        -- 전달받은 Slot을 컨텐츠 영역의 한 자리로 놓는다
        D.Frame {
            Position = UDim2.fromOffset(0, 40),
            Size = UDim2.new(1, 0, 1, -40),
            BackgroundTransparency = 1,

            props.Children or None,
        },
    }
end
```

부르는 쪽은 `ModalDialog { Title = "설정", Children = q.Slot<<Instance>>({ ... }) }`처럼 넘깁니다. `Slot`으로 받으면 호출자가 나중에 `:Add`/`:Remove`로 내용을 갈아 끼울 수 있고, 컴포넌트 쪽은 자리 하나만 잡아 두면 됩니다.

### 자식 **배열**을 그대로 넘기지 않는 이유

props에 `{ DTypes.FrameElem }` 같은 배열을 받아 펼치는 모양도 문법상으로는 가능하지만, 두 가지 제약이 따라옵니다.

- `table.unpack(...)`은 **테이블 리터럴의 마지막 원소일 때만** 전부 펼쳐집니다. 중간에 두면 첫 값 하나만 들어갑니다.
- **자식 배열을 담은 변수를 props 테이블 자리에 그대로 넘길 수는 없습니다** — `D.Frame(children)`은 타입이 맞지 않아 거부됩니다. props 테이블은 리터럴 자리에서만 추론이 살아 있습니다.

그래서 이 문서는 자식 전달을 `Slot`으로 통일합니다. `<Class>Elem` 타입 자체는 여전히 유용합니다 — 그 클래스의 숫자 키 자리에 올 수 있는 것들의 유니언이라, 자식 Instance뿐 아니라 `Modifier`·`Ref`·`Slot` 같은 디스크립터도 들어 있습니다.

---

## 5. 선언적 메타데이터: `Tag`와 `Attr`

Roblox의 `CollectionService` 태그와 인스턴스 어트리뷰트도 숫자 키 자리에서 선언적으로 다룰 수 있습니다(기본은 [시작하기 05. 이름표와 속성](/getting-started/05-tag-attr/)에서 배웁니다 — 여기서는 컴포넌트 경계에서 지킬 규칙만 봅니다).

```luau
local function CharacterBadge(props: { read Name: string, read Level: QuadTypes.StateMarker<number> }): Frame
    return D.Frame {
        -- [1] CollectionService 태그 (여러 자리의 요구를 합집합으로 관리)
        q.Tag("PlayerBadge", "Interactable"),

        -- [2] 어트리뷰트 그룹 — 값은 리터럴이어도 State여도 된다
        q.Attr {
            CharacterName = props.Name,
            Level = props.Level,
            Guild = "Alpha",
        },

        D.TextLabel {
            Text = props.Name,
        },
    }
end
```

### `Tag`와 `Attr`에서 알아둘 규칙

1. **`Tag`는 합집합이다**:
   같은 태그를 여러 자리(컴포넌트, `Modifier`, State로 바뀌는 `Tag` 값 …)에서 요구해도, quad는 참조 카운트로 **한 곳이라도 요구하는 동안 태그가 유지**되도록 관리합니다. 마지막 요구가 사라질 때 비로소 태그가 제거됩니다.
2. **`None`이거나 State의 값이 `nil`이면 어트리뷰트가 삭제된다**:
   - `q.Attr { MyKey = None }` — 즉시 삭제(`inst:SetAttribute(key, nil)`).
   - 바인딩된 `State`의 값이 `nil`이 된 경우도 마찬가지로 **삭제**됩니다. 단일 키 경로는 값을 그대로 엔진에 넘기고, `nil`도 예외가 아닙니다.
   - 반면 그룹 테이블에 `nil`을 직접 적는 것(`q.Attr { MyKey = nil }`)은 애초에 항목이 생기지 않는 것과 같습니다 — 지우려는 뜻이면 `None`을 쓰세요.
3. **다만 '그룹 자체가 교체되어 이름이 사라진' 경우는 값이 남는다**:
   `Attr` 그룹 값을 통째로 다른 그룹으로 바꿔서 어떤 이름이 새 그룹에 없어졌다면, 그 이름의 구독만 끊기고 인스턴스에 이미 찍혀 있던 값은 **그대로 남습니다**. 그룹을 물릴 때 엔진에 지우기를 요청하지는 않기 때문입니다. 지우고 싶으면 새 그룹에서 그 이름을 `None`으로 명시하세요.
4. **한 이름은 한 주인만**: 어떤 이름을 그룹이 잡고 있는데 다른 자리에서 같은 이름을 직접 쓰려 하면 그 자리에서 에러가 납니다.

---

## 6. 재사용 로직 추출: Hook 규칙의 족쇄가 없는 팩토리

React에서는 `use*` Hook을 조건문이나 루프 안에서 호출하면 "Rules of Hooks" 위반으로 런타임 에러가 납니다.

Quad의 컴포넌트는 매 프레임 재실행되지 않는 **1회성 셋업 함수**이므로, 반응형 로직을 담은 함수를 **어떤 조건문이나 루프 안에서도** 자유롭게 부를 수 있습니다. 이름 규칙도 따로 없습니다.

```luau
local function newCounter(initial: number)
    local count = q.Source(initial)
    -- --!strict에서는 :Compute 콜백 파라미터에 주석이 필요하다
    local isEven = count:Compute(function(c: q.StateData<number>): boolean
        return c:Get() % 2 == 0
    end)

    local function increment()
        count:Set(count:Get() + 1)
    end

    return { count = count, isEven = isEven, increment = increment }
end

-- 컴포넌트 안에서, 조건문 안에서, 루프 안에서 아무 제약 없이 호출 가능
local left, right = newCounter(0), newCounter(10)
```

Getting Started의 예제들은 Roblox 기본 모드(`--!nonstrict`)를 가정합니다. `--!strict`로 쓸 때 손이 더 가는 자리는 둘입니다 — **콜백 파라미터**(위 예제의 `q.StateData<number>`처럼 `:Compute`/`:Observer`의 파라미터에 주석)와 **파생 노드를 만드는 줄의 결과 타입**(`local isEven: q.State<boolean> = ...`). 자세한 캐비엇은 [레퍼런스: `State`](/reference/core/03-state/)에 있습니다.

:::tip
상태 위에 얹는 연산 조합자는 `q.Operator` 네임스페이스에 있고, `:Apply`로 붙입니다 — 예: `price:Apply(q.Operator.Sum(tax, shipping))`, `reduceMotion:Apply(q.Operator.Not)`. 인자는 리터럴이어도 State여도 됩니다.
:::

---

## 7. 컴포넌트 작성 체크리스트

- [ ] 컴포넌트는 1회 실행되는 셋업 함수인가?
- [ ] 외부에서 주입받는 `Modifier`/`Ref`를 **숫자 키 자리**에 놓고 `or None`으로 nil-hole을 막았는가?
- [ ] 문자 키 > 후행 `Modifier` > 선행 `Modifier` 우선순위를 알고 설계했는가?
- [ ] `Attr` 값을 지울 때 `None`(또는 State의 `nil`)을 쓰고, 그룹 교체만으로는 값이 안 지워진다는 걸 아는가?
- [ ] 반응형 로직을 담은 헬퍼 함수를 React Hook의 제약 없이 자유롭게 분리했는가?
