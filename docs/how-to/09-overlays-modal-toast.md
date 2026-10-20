---
title: "09. 떠 있는 것 열고 닫기 — 모달과 토스트"
description: "화면 뿌리에 오버레이 자리를 두고, 트리 깊은 곳에서 Context로 열고, Slot:List로 토스트 큐를 굴리고, Fallback으로 던진 에러를 모달에 담고, 화면을 다시 지어도 죽지 않는 기본 레이어·바깥 클릭으로 닫기·Escape 스택을 짜는 법을 다룹니다"
---
# [실전 레시피] 09. 떠 있는 것 열고 닫기 — 모달과 토스트

> **대상 독자**: 확인 대화상자·알림·에러 안내처럼 트리 깊은 곳에서 열리지만 화면 맨 위 한 곳에 그려지는 오버레이를 만들려는 개발자
> **다루는 개념**: `Visible` 바인딩과 조건부 자식(`State<Instance?>`), `q.Context`로 층 건너 열기, `Slot:List`로 토스트 큐, `q.Fallback`으로 던진 에러를 모달에 담기, 죽지 않는 기본 레이어, 바깥 클릭으로 닫기(전체 화면 잡이 대 좌표 판정), Escape 스택

```luau
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
const q = require("@game/ReplicatedStorage/Client/UI/Quad")
const None = q.None
```

---

## 1. 해결하려는 문제

모달과 토스트는 같은 모양의 요구를 셋 가집니다.

1. **열고 닫을 수 있어야 한다** — 지금 열려 있는지가 어딘가에 상태로 있어야 합니다.
2. **트리 어디서든 열 수 있어야 한다** — 열어야 할 필요는 깊은 곳의 버튼 하나에서 생기는데, 오버레이 자신은 화면 맨 위 한 곳에서 그려져야 합니다.
3. **토스트는 잠깐 떠 있다가 스스로 사라진다** — 사용자가 닫지 않아도 시간이 지나면 없어집니다.

겹쳐 그려지는 순서(`ZIndex`·`DisplayOrder`) 자체는 이 문서가 다루지 않습니다 — Roblox 엔진이 정하는 규칙이라 [`GuiObject.ZIndex`](https://create.roblox.com/docs/reference/engine/classes/GuiObject#ZIndex)와 [`ScreenGui.DisplayOrder`](https://create.roblox.com/docs/reference/engine/classes/ScreenGui#DisplayOrder) 공식 문서를 참고하세요. 여기서 다루는 것은 "열고 닫기 → 컴포넌트화 → 실사용" 세 가지뿐입니다.

---

## 2. 열림을 상태로

열림 여부는 컴포넌트 안이 아니라 **밖에서 만든 `Source`**에 둡니다([실전 레시피 02](./02-form-validation-pattern.md)의 체크박스와 같은 이유입니다 — 안에서 만들면 바깥이 열고 닫을 길이 없습니다).

```luau
const open = q.Source(false)
```

이 값을 화면에 잇는 데는 두 갈래가 있습니다.

- **인스턴스를 유지한 채 `Visible`만 토글**([실전 레시피 04](./04-network-and-input-bridge.md) §3에서 이미 본 패턴입니다). 다시 열 때 인스턴스를 새로 만들 필요가 없어 열고 닫기가 잦은 경우에 쌉니다.
- **열릴 때만 만들기** — [시작하기 11 §6](../getting-started/11-slot.md#6-하나만-갈아-끼우기--state를-자리에-놓기)의 조건부 자식 관용구(`State<Instance?>`를 숫자 키 자리에 놓기)로, 콘텐츠가 무겁고 좀처럼 안 열리는 오버레이에 맞습니다.

어느 쪽이든 열림 자체를 나타내는 값은 `open` 하나입니다. 이 장에서는 첫 번째(`Visible` 유지)를 기본으로 삼아 `Modal` 컴포넌트를 만듭니다 — 확인/취소 버튼을 누르면 `open:Set(false)` 뒤 그 결과를 바깥에 알리는 콜백을 부릅니다. [실전 레시피 01](./01-component-conventions.md)의 경계 규약대로 자식은 `Slot`으로 받고, 숫자 키 자리는 `or None`으로 nil-hole을 막습니다.

```luau
local function Modal(props: {
    read Open: q.Source<boolean>,
    read Title: string,
    read OnConfirm: () -> (),
    read OnCancel: () -> (),
    read Children: q.Slot<Instance>?,
}): Frame
    return q.Elem "Frame" {
        Size = UDim2.fromOffset(360, 220),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(30, 30, 35),

        Visible = props.Open,

        q.Elem "TextLabel" {
            Text = props.Title,
            Size = UDim2.new(1, 0, 0, 40),
        },

        props.Children or None, -- ⭐ 숫자 키 자리, or None으로 nil-hole 방지(실전 레시피 01)

        q.Elem "TextButton" {
            Text = "확인",
            Position = UDim2.new(0, 20, 1, -48),
            Size = UDim2.fromOffset(140, 36),
            Activated = function()
                props.Open:Set(false)
                props.OnConfirm()
            end,
        },
        q.Elem "TextButton" {
            Text = "취소",
            Position = UDim2.new(1, -160, 1, -48),
            Size = UDim2.fromOffset(140, 36),
            Activated = function()
                props.Open:Set(false)
                props.OnCancel()
            end,
        },
    }
end
```

:::caution
`read Children: q.Slot<Instance>?`처럼 옵셔널 자리에 놓은 `Slot<T>`는 [2026-09-26 기준] 신 솔버가 타입 인자를 검사하지 않습니다 — 다른 `T`의 `Slot`도 타입 검사를 통과합니다. Luau 쪽 한계이고, 런타임 가드는 그대로 동작합니다.
<!-- 근거: 2026-09-26 신 솔버 실측(저장소 내부 기록) -->
:::

부르는 쪽은 열림 원천과 콜백을 넘기기만 하면 됩니다.

```luau
const open = q.Source(false)

const confirmDialog = Modal {
    Open = open,
    Title = "정말 삭제할까요?",
    OnConfirm = function() print("삭제 확정") end,
    OnCancel = function() print("취소함") end,
}
```

<details>
<summary><strong>조건부 자식으로 바꾸면요?</strong></summary>

`Visible` 자리를 없애고, 화면의 숫자 키 자리에 `State<Instance?>`를 직접 놓는 모양입니다.

```luau
const activeModal = q.Source<<Instance?>>(nil)

local function openConfirmDialog()
    -- 이미 떠 있던 모달이 있으면 새 모달이 앉은 뒤 옛 것이 파괴된다
    activeModal:SetAndDispose(Modal {
        Open = q.Source(true), -- 이 갈래에서는 열림 자체가 "만들어져 있는가"이므로 별도 Open이 꼭 필요하지는 않습니다
        Title = "정말 삭제할까요?",
        OnConfirm = function()
            activeModal:SetAndDispose(nil) -- 자리를 비운 뒤, 다시 쓸 일이 없는 이 모달을 정리
        end,
        OnCancel = function()
            activeModal:SetAndDispose(nil)
        end,
    })
end
```

`activeModal`을 다른 값으로 갈아 끼우면 **옛 인스턴스는 파괴되지 않고 트리에서 떼어지기만 합니다**([시작하기 11 §6](../getting-started/11-slot.md#6-하나만-갈아-끼우기--state를-자리에-놓기)) — 그래서 위 코드는 `:Set` 대신 [`:SetAndDispose`](../reference/core/02-source.md#sourcesetanddisposev)를 씁니다. 새 값을 앉혀 전파가 끝난 뒤 옛 값을 `q.dispose`로 파괴하므로, 닫을 때(`nil`)는 방금 닫힌 모달이, 하나가 떠 있는 동안 `openConfirmDialog`를 다시 부르면 먼저 떠 있던 모달이 정리됩니다(처음 열 때처럼 옛 값이 `nil`이면 지울 것이 없어 그냥 넘어갑니다). `:Set`만 쓰면 열 때마다 떼어진 모달이 하나씩 남습니다 — [2026-09-27 mock 실측]. 그래서 매번 새로 만드는 이 모양은 열 때마다 확실히 버릴 생각이 있을 때 씁니다.

**[2026-10-01 기준]** `:SetAndDispose`는 3.3.0부터 있습니다 — 3.2.0에는 없습니다([변경 이력](../../CHANGELOG.md)의 `[3.3.0]`). 3.2.0에서는 `local old = activeModal:Get(); activeModal:Set(v); if old then q.dispose(old) end`로 읽으세요(같은 일을 합니다).
<!-- mock 실측 2026-10-01: 열기 → 다시 열기(첫 모달 파괴·새 모달이 자리에) → 확인(닫힌 모달 파괴·자리 빔), Activated 안에서 자기 모달을 파괴해도 에러 없음 -->

</details>

---

## 3. 트리거는 깊고, 오버레이는 뿌리

`open`을 만드는 곳(화면 뿌리)과 그걸 켜야 하는 곳(트리 몇 층 아래의 버튼)이 서로 멉니다. `props`로 한 층씩 내리면 중간 컴포넌트들이 자기가 쓰지도 않는 값을 계속 받아 넘겨야 하므로, [시작하기 15](../getting-started/15-context.md)의 `q.Context`로 열쇠 하나만 아래로 흘립니다.

```luau
-- 새 파일: ReplicatedStorage/Client/UI/ModalContext
const q = require("./Quad")

export type ModalBag = { Open: q.Source<boolean> }

return {
    Provider = q.Context.Provider<<ModalBag>>("Modal"),
}
```

진입점에서 가방을 만들어 `open`을 담고, 화면과 함께 내려보냅니다.

```luau
const ModalContext = require("@game/ReplicatedStorage/Client/UI/ModalContext")

const open = q.Source(false)
const ctx = q.Context():Set(ModalContext.Provider, { Open = open })

const screen = q.Elem "ScreenGui" {
    DeepPanel { Ctx = ctx }, -- 이 안 몇 층 아래에 삭제 버튼이 있다

    Modal {
        Open = open,
        Title = "정말 삭제할까요?",
        OnConfirm = function() print("삭제 확정") end,
        OnCancel = function() print("취소함") end,
    },
}
```

중간 컴포넌트(`DeepPanel`)는 `ModalContext`를 require하지도, 그 안에 뭐가 들었는지도 모른 채 `Ctx`를 한 층 더 내려보내기만 합니다([시작하기 15 §2](../getting-started/15-context.md#2-중간-층은-모른-채-넘긴다)와 같은 모양입니다). 말단 버튼만 자기 열쇠로 가방을 엽니다.

```luau
-- 트리 몇 층 아래의 버튼 — 자기 열쇠로 가방을 연다
local function DeleteButton(props: { read Ctx: q.Context }): TextButton
    const modal = props.Ctx:Get(ModalContext.Provider)

    return q.Elem "TextButton" {
        Text = "삭제",
        Activated = function()
            modal.Open:Set(true)
        end,
    }
end
```

가방을 하나 만들어 값 여러 개(예: 여러 종류의 모달을 여는 명령들)를 같이 담아도 됩니다 — 여기서는 `Open` 하나뿐인 가방을 보였을 뿐, 가방 자체는 [Context 레퍼런스](../reference/sugar/01-context.md)의 규칙(명시적 전달, 복제 없음, `Get`은 없으면 에러) 그대로입니다.

가방을 넘기기 싫어 오버레이 자리를 **모듈 변수 하나에 들고 있고** 싶어질 수 있습니다. 그 자리를 모듈을 처음 require할 때 만들어 두면 처음 붙은 화면과 함께 죽습니다 — 그렇게 쓰려면 [§6](#6-화면을-다시-지어도-죽지-않는-기본-레이어)의 모양으로 두세요.

---

## 4. 토스트

토스트는 모달과 달리 **여러 개가 동시에 떠 있을 수 있고**, 각자 시간이 지나면 스스로 사라집니다. 데이터가 배열이라는 점에서 [시작하기 14](../getting-started/14-lists.md)의 `Slot:List`가 그대로 맞습니다 — 항목마다 변하지 않는 신원(`Id`)이 필요하다는 규칙도 같습니다.

```luau
type Toast = { Id: number, Text: string }

const toasts = q.Source<<{ Toast }>>({})

const toastList = q.Slot<<Instance>>()
toastList:List(toasts, function(ctx): (any, nil)
    if ctx.Item == q.KeyGone then
        return nil, ctx.UserData -- 사라진 토스트 → 파괴
    end
    if ctx.Prev then
        return ctx.Prev, ctx.UserData -- 이미 있는 토스트 → 그대로 둔다
    end
    const toast = ctx.Item :: Toast -- KeyGone 팔을 위에서 걸렀으니 좁혀 준다(props 타입이 있는 컴포넌트에 넘길 때 strict가 요구)
    return q.Elem "TextLabel" {
        Text = toast.Text,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = Color3.fromRGB(40, 40, 48),
    }, ctx.UserData
end, function(item)
    return item.Id
end)

local nextToastId = 0

local function pushToast(text: string)
    nextToastId += 1
    const id = nextToastId

    -- 시작하기 14 §3처럼 제자리에서 고치지 않고 새 배열을 만들어 :Set 합니다
    const next = table.clone(toasts:Get())
    table.insert(next, { Id = id, Text = text })
    toasts:Set(next)

    task.delay(3, function()
        const kept = {}
        for _, item in toasts:Get() do
            if item.Id ~= id then
                table.insert(kept, item)
            end
        end
        toasts:Set(kept)
    end)
end

const toastHost = q.Elem "Frame" {
    q.Elem "UIListLayout" { Padding = UDim.new(0, 4) },
    toastList,
}
```

> `updateFn`의 반환 타입 주석 `): (any, nil)`을 빼지 마세요 — 첫 리턴(`return nil, ctx.UserData`)이 `nil`을 먼저 내놓으면 그 뒤 `q.Elem "TextLabel" {...}`을 돌려주는 리턴까지 `nil`로 굳어 strict에서 막힙니다. **strict에서는 반환 타입 주석을 붙이세요 — how-to 08 §7 13행**([시작하기 14](../getting-started/14-lists.md)는 nonstrict 장이라 이 주석 없이도 통과합니다).

`toastList`는 **처음 앉은 호스트에 묶입니다.** 모듈 스코프에 두었으니 화면을 다시 지을 때 `toastHost`가 파괴되면(엔진이 지우는 경우도 포함) 그 Slot은 그 사실을 모릅니다 — `:List`는 조용히 재조정을 멈추고, 보류 중이던 `task.delay`의 `toasts:Set`은 에러 없이 흘러가며, 새 호스트에 다시 앉히면 `Quad0160 … cannot be reused after its parent is destroyed`로 막힙니다([Slot 레퍼런스](../reference/core/06-slot.md)의 "quad 밖에서 파괴된" 캐비엇). 화면을 다시 짓는 앱이면 `toastList`도 화면과 함께 새로 만들거나, 호스트를 파괴하지 말고 숨기세요.

`Id`를 늘어나기만 하는 카운터로 둔 것은 [시작하기 14 §3](../getting-started/14-lists.md#3-데이터를-바꾸면-필요한-것만-바뀝니다)의 경고와 같은 이유입니다 — 배열 길이나 시각처럼 되풀이될 수 있는 값을 신원으로 쓰면 같은 `Id`가 다시 생겨 `Quad0145 Slot:List: duplicate key`로 막힙니다.

---

## 5. 던진 것을 에러 모달이 받는다

컴포넌트 안에서 던진 에러를 화면 어딘가의 "에러 모달"이 받아 보여주고 싶을 때가 있습니다. [Fallback/Traceback 레퍼런스](../reference/sugar/05-fallback-traceback.md)의 계약을 그대로 씁니다 — `q.Fallback(base, onError)`가 돌려주는 함수는 `base`가 던지면 `onError(err)`의 **대체 값을 돌려줘야** 합니다. 그 자리를 채우는 것과, 에러를 모달에 보이는 것은 **다른 일**입니다 — 대체 값은 그 자리를 메우는 빈 값(`q.Elem "Frame" {}`)으로 두고, 에러 자체는 바깥에서 관측할 수 있는 상태에 적습니다.

```luau
-- 예시 컴포넌트 — Text가 비어 있으면 던진다(던지는 쪽은 아무 컴포넌트여도 됩니다)
local function Card(props: { read Text: string }): Frame
    if props.Text == "" then
        error("Card: Text must not be empty")
    end
    return q.Elem "Frame" {
        q.Elem "TextLabel" { Text = props.Text },
    }
end

const errorState = q.Source<<any>>(nil)

local function onError(err: any): Instance
    errorState:Set(err)
    return q.Elem "Frame" {} -- 자리표시 값 — Card가 있어야 할 자리를 채우기만 한다
end

const SafeCard = q.Fallback(Card, onError)
```

`errorState`를 받아 여는 재사용 컴포넌트가 `ErrorModal`입니다.

```luau
local function ErrorModal(props: {
    read Error: q.State<any>,
    read OnReport: (err: any) -> (),
    read OnConfirm: () -> (),
}): Frame
    -- 파생 상태는 props 테이블 밖에서 만들어 둔다(아래 주의 참고)
    const visible: q.State<boolean> = props.Error:Compute(function(e)
        return e:Get() ~= nil
    end)
    const text: q.State<string> = props.Error:Compute(function(e)
        const value = e:Get()
        return if value == nil then "" else tostring(value)
    end)

    return q.Elem "Frame" {
        Visible = visible,

        q.Elem "TextLabel" {
            Text = text,
        },

        q.Elem "TextButton" {
            Text = "신고",
            Activated = function()
                props.OnReport(props.Error:Get())
            end,
        },
        q.Elem "TextButton" {
            Text = "확인",
            Activated = function()
                props.OnConfirm()
            end,
        },
    }
end
```

> [how-to 02 §4](../how-to/02-form-validation-pattern.md#4-ui-조립--컴포넌트는-상태를-받기만-한다)의 캐비엇 그대로입니다 — **`:Compute`를 props 테이블 안에 인라인으로 쓰면 에디터 타입 검사가 깨집니다**(런타임은 정상이지만 편집기에 빨간 줄이 그어집니다), 그래서 위처럼 별도 문장으로 뺐습니다.

부르는 쪽에서 `SafeCard`와 `ErrorModal`을 같은 화면에 놓고, `errorState`를 지우는 쪽(`OnConfirm`)만 정해 주면 됩니다.

```luau
const screen = q.Elem "ScreenGui" {
    SafeCard { Text = someUnsafeText }, -- 던지면 자리표시 값이 대신 앉는다

    ErrorModal {
        Error = errorState,
        OnReport = function(err) print("신고:", err) end,
        OnConfirm = function() errorState:Set(nil) end,
    },
}
```

`err`가 문자열이면 Luau가 붙인 위치 접두와 함께 quad 에러의 `QuadNNNN` 식별자가 그대로 들어 있으니, [에러 코드 색인](../reference/errors/00-index.md)에서 번호로 찾을 수 있습니다. 트레이스백까지 필요하면 `q.Fallback` 대신 `q.Traceback(Card, onError)`을 쓰세요 — `onError`가 `(err, trace)` 두 인자를 받는 것만 다릅니다.

:::caution
[Fallback/Traceback 레퍼런스](../reference/sugar/05-fallback-traceback.md#공통-계약)의 caution 그대로입니다 — **던지기 전에 이미 만들어진 부분 트리는 이 경계가 정리해 주지 않고**, **예외가 지나간 자리의 quad 부기도 복구되지 않습니다**(요소 생성자가 중간에 던지면 배치 게이트가 켜진 채 남는 등). 이 경계 안에서 던진 인스턴스는 계속 쓰지 말고, 대체 UI는 항상 새 인스턴스로 만드세요.
:::

---

## 6. 화면을 다시 지어도 죽지 않는 기본 레이어

메뉴·툴팁·대화상자를 여는 컴포넌트가 많아지면 "아무것도 넘겨받지 않아도 열 수 있는 기본 오버레이 레이어"가 하나 있으면 편합니다. UI 킷이 특히 그렇습니다 — 소비자가 레이어를 넘기지 않아도 메뉴가 열려야 합니다. 그 레이어를 **모듈을 require하는 순간 만들어 모듈 변수에 들고 있으면** 문제가 납니다.

```luau
-- 이렇게 하지 마세요 — require 시점에 만든 레이어를 모듈 변수에 쥔다
const overlaySlot = q.Slot<<Instance>>()
const layer = q.Elem "Frame" {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    overlaySlot,
}
return { Layer = layer, Slot = overlaySlot }
```

앱이 이 `layer`를 자기 `ScreenGui`에 넣었다가 그 화면을 버리고(디버그 창 닫기, 리스폰 때 엔진이 지우는 화면) 다시 지으며 같은 `layer`를 또 넣으면, 레이어는 이미 옛 화면과 함께 파괴된 뒤라 그 자리에서 막힙니다 — [2026-10-20 mock 실측].

```
Quad0219 Dispatch: this Instance is not claimed by quad - build it with q.Elem or take it over with Claim first (an Instance made by another quad module instance also counts as not claimed here, and so does a destroyed one - a destroyed Instance cannot be reused)
```

다시 짓기 전에 연 팝업은 더 조용합니다. 호스트가 죽은 `Slot`은 그 사실을 모르므로 `overlaySlot:Add(…)`가 에러 없이 성공하고, 새 팝업은 죽은 Frame 밑에 붙어 화면에 나오지 않습니다([Slot 레퍼런스](../reference/core/06-slot.md#죽은-slot과-마운트-규칙) — [`q.debug`](../reference/core/01-quad-module.md#qdebug)를 켜면 `Slot: CRUD on a Slot whose host Instance is no longer claimed by quad …` 한 줄이 나옵니다).

고치는 방법은 셋입니다. 두 소비자 킷의 기본 레이어(`quad-roblox-devui`의 `Overlay.getDefault()`, `quad-roblox-material`의 `Overlay.default()`)가 실제로 이렇게 짜여 있습니다.

1. **require 시점에는 아무것도 만들지 않는다** — 레이어는 처음 달라고 할 때 만듭니다.
2. **줄 때마다 살아 있는지 보고, 죽었으면 새로 만든다** — 죽은 레이어는 다시 내주지 않습니다.
3. **화면을 지을 때마다 레이어를 다시 받아 붙인다** — 레이어를 붙이는 줄을 화면을 짓는 함수 안에 둡니다.

```luau
--!strict
-- 새 파일: ReplicatedStorage/Client/UI/OverlayLayer
const q = require("./Quad")

export type Layer = {
    read Frame: Frame,
    read Slot: q.Slot<Instance>,
    read IsDead: () -> boolean,
}

local function new(): Layer
    const slot = q.Slot<<Instance>>()
    local destroyed = false
    local everMounted = false

    const frame = q.Elem "Frame" {
        Name = "OverlayLayer",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 1000,
        slot,
        q.OnDestroyed(function()
            destroyed = true
        end),
    }
    -- 한 번이라도 화면에 붙었는지 기억한다(아래 isDead가 쓴다)
    frame:GetPropertyChangedSignal("Parent"):Connect(function()
        if frame.Parent ~= nil then
            everMounted = true
        end
    end)

    local function isDead(): boolean
        if destroyed then
            return true
        end
        if frame.Parent ~= nil then
            everMounted = true
            return false
        end
        -- 붙은 적이 있는데 지금 부모가 없다 = 파괴됐다(Destroying 처리기가 아직 안 돌았어도)
        return everMounted
    end

    return { Frame = frame, Slot = slot, IsDead = isDead }
end

local current: Layer? = nil

-- 기본 레이어 — 처음 부를 때 만들고, 죽었으면 새로 만든다
local function get(): Layer
    const c = current
    if c ~= nil and not c.IsDead() then
        return c
    end
    const fresh = new()
    current = fresh
    return fresh
end

-- 기본 레이어에 하나를 올리고, 닫는 함수를 돌려준다(두 번 불러도 된다)
local function open(content: Instance): () -> ()
    const layer = get()
    if layer.Frame.Parent == nil then
        warn("OverlayLayer.open: the layer is not mounted - put OverlayLayer.get().Frame into the ScreenGui that shows popups")
    end
    layer.Slot:Add(content)

    local closed = false
    return function()
        if closed then
            return
        end
        closed = true
        -- 레이어가 죽었거나 이 항목이 이미 레이어를 떠났으면 Slot을 건드리지 않는다
        if layer.IsDead() or content.Parent ~= layer.Frame then
            return
        end
        layer.Slot:WhenIdle(function(s)
            const index = s:IndexOf(content)
            if index then
                s:Remove(index)
            end
        end)
    end
end

return { new = new, get = get, open = open }
```

화면을 짓는 쪽은 레이어를 **짓는 함수 안에서** 받아 붙입니다. 다시 지을 때마다 `get()`이 살아 있는 레이어를 주므로 `Quad0219`가 나지 않습니다.

```luau
const OverlayLayer = require("@game/ReplicatedStorage/Client/UI/OverlayLayer")

local function buildUi(): ScreenGui
    return q.Elem "ScreenGui" {
        ResetOnSpawn = false, -- 시작하기 01과 같은 이유
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        App(),
        OverlayLayer.get().Frame, -- 마지막 자식으로 — 매번 다시 받는다
    }
end
```

<!-- mock 실측 2026-10-20: require 시점 레이어를 죽은 뒤 다시 넣으면 Quad0219; get()은 화면이 죽은 뒤 새 레이어를 주고, 옛 레이어의 닫기 함수는 에러 없이 no-op, 새 레이어에서 열고 닫기 정상, 부모만 nil이 된 레이어도 죽은 것으로 판정 -->

몇 가지는 이유가 덜 드러납니다.

- **`q.OnDestroyed` 플래그만으로는 모자랍니다.** Roblox 기본 설정(Deferred 시그널)에서는 `Destroying` 처리기가 `Destroy()`가 돌아온 **뒤에** 돕니다([백엔드 프로바이더 규약](../reference/extend/01-backend-provider-contract.md)의 `onDestroying` 항목). 그래서 `oldGui:Destroy(); buildUi()`를 한 흐름에 하면 플래그가 아직 거짓이라 죽은 레이어를 다시 내줍니다. `Destroy()`는 부모를 그 자리에서 떼므로 "붙은 적이 있는데 지금 부모가 없다"는 즉시 보입니다 — 두 킷이 이 판정을 씁니다. 대신 **레이어를 일부러 떼었다 다시 붙이는 쓰임은 가정하지 않습니다**(떼는 순간 죽은 것으로 칩니다). [2026-10-20 기준] Deferred에서의 순서는 이 문서가 직접 실측하지 않았고 킷 소스의 판단을 옮긴 것입니다 — mock은 시그널을 동기로 배달합니다.
- **닫기도 같은 이유로 두 가지를 봅니다.** Deferred에서는 레이어 아래 항목의 `Destroying`이 레이어 자신의 `OnDestroyed`보다 먼저 돌 수 있어, 닫기 경로가 "레이어가 죽었나" 플래그 하나에 기대면 이미 떨어져 나간 항목으로 Slot을 고치려 듭니다. 그래서 `content.Parent ~= layer.Frame`도 같이 봅니다(devui `Overlay`의 판단).
- **`WhenIdle`로 감싼 이유** — 팝업 안의 요소(메뉴 행 등)가 자기 `OnDestroyed`에서 다른 팝업을 닫는 일이 있습니다. 그 순간 같은 Slot이 원소를 떼는 중이면 CRUD가 `Quad0167`로 거부되므로 [`slot:WhenIdle`](../reference/core/06-slot.md#slotwhenidlefn)로 미룹니다(그 연산이 끝난 직후 실행되고, 한가하면 바로 실행됩니다).
- **레이어는 화면 하나에만 붙습니다.** Instance 하나라 두 `ScreenGui`에 동시에 넣으면 `Quad0160`입니다. 화면마다 레이어가 필요하면 `new()`로 따로 만들어 §3처럼 Context로 넘기세요 — 기본 레이어는 "넘겨받은 게 없을 때"의 대비책입니다.
- **붙지 않은 레이어에 열면 알립니다.** 새로 만든 레이어를 아무도 붙이지 않으면 팝업은 에러 없이 안 보입니다. devui는 이 경고를 `q.debug`와 무관하게 레이어마다 한 번 냅니다(사용자가 실제로 시간을 잃은 자리라서). 위 코드는 열 때마다 내니 자주 열리면 한 번으로 줄이세요.
- **레이어가 죽을 때 열려 있던 것들** — 위 코드는 다루지 않습니다. 두 킷은 레이어가 죽는 순간 열려 있던 팝업을 전부 닫힌 것으로 돌리고 각 `OnClose`를 한 번 불러, 팝업 주인이 Escape 연결 같은 부기를 내려놓게 합니다. 팝업이 바깥에 상태(열림 `Source`, 입력 연결)를 남긴다면 같은 일을 하세요. 그리고 두 킷 모두 **죽은 레이어에 `Open`하면 크게 던집니다** — 조용히 지나가면 "대화상자가 안 뜬다"로만 보이기 때문입니다.

---

## 7. 바깥을 누르면 닫기

메뉴·콤보 목록·팝오버는 바깥을 누르면 닫히는 게 보통입니다. 길은 둘입니다 — 팝업 뒤에 **화면 전체를 덮는 투명 버튼**(잡이)을 깔거나, 전역 입력을 듣다가 **누른 좌표가 팝업 사각형 밖인지** 계산하거나.

**전체 화면 잡이** — 두 킷이 모두 이쪽입니다(devui `Overlay`의 `Catcher`, material `Overlay`의 `Scrim`). 팝업 하나를 "화면을 덮는 투명 Frame 안에 잡이 버튼과 내용"으로 만들어 레이어에 올립니다.

```luau
-- 팝업 하나 = 화면을 덮는 항목 Frame 안에 [잡이, 내용]
local function PopupEntry(props: {
    read Content: Instance,
    read OnDismiss: () -> (),
}): Frame
    return q.Elem "Frame" {
        Name = "PopupEntry",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,

        q.Elem "TextButton" {
            Name = "Catcher",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            Selectable = false, -- 게임패드 선택이 잡이에 앉지 않게
            ZIndex = 0, -- 형제 중 맨 아래 — 내용(기본 1)이 늘 위에 그려진다
            Activated = function()
                props.OnDismiss()
            end,
        },

        props.Content,
    }
end
```

**좌표 판정** — 전역 누름을 듣다가 팝업의 `AbsolutePosition`/`AbsoluteSize` 사각형 밖이면 닫습니다. 연결은 팝업이 사는 동안만 있어야 하므로 [실전 레시피 04 §4](./04-network-and-input-bridge.md#4-컴포넌트-수명에-리스너-묶기)처럼 `q.Effect`의 cleanup으로 팝업 Instance의 수명에 묶습니다. 사각형은 누르는 순간에 읽으면 되므로 `Ref`로 Instance를 받아 둡니다.

```luau
const UserInputService = game:GetService("UserInputService")

-- 숫자 키 자리에 놓는 팩토리 — 이 요소가 사는 동안만 누름을 듣는다
local function closeOnOutsidePress(surface: q.Ref<Frame?>, close: () -> ()): q.Effect
    return q.Effect(function()
        const conn = UserInputService.InputBegan:Connect(function(input: InputObject)
            const kind = input.UserInputType
            if kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.Touch then
                return
            end
            const inst = surface.Value
            if inst == nil then
                return
            end
            const p, s = inst.AbsolutePosition, inst.AbsoluteSize
            const x, y = input.Position.X, input.Position.Y
            if x < p.X or y < p.Y or x >= p.X + s.X or y >= p.Y + s.Y then
                close()
            end
        end)
        return function()
            conn:Disconnect() -- 팝업이 파괴될 때
        end
    end)
end

local function Menu(props: { read OnDismiss: () -> () }): Frame
    const surface = q.Ref<<Frame?>>(nil)
    return q.Elem "Frame" {
        Size = UDim2.fromOffset(200, 160),
        surface,
        closeOnOutsidePress(surface, props.OnDismiss),
        -- …메뉴 항목…
    }
end
```

<!-- mock 실측 2026-10-20: 잡이의 Activated가 OnDismiss를 부름; 좌표 판정은 사각형 안 누름에 침묵·밖 누름에 close, 팝업 dispose 뒤 InputBegan 연결 수가 원래대로 -->

`InputObject.Position`은 `AbsolutePosition`과 같은 좌표계라 그대로 비교합니다(devui가 그렇게 씁니다 — `UserInputService:GetMouseLocation()`은 상단 인셋을 빼야 같은 좌표계가 됩니다). 두 길의 차이는 이렇습니다.

| | 전체 화면 잡이 | 좌표 판정 |
|---|---|---|
| 무엇이 위에 있는지 | 엔진의 히트 테스트가 판정합니다 | 사각형만 봅니다 — 회전·잘림·둥근 모서리, 그리고 팝업 위에 겹친 다른 UI를 모릅니다 |
| 닫는 그 누름 | 잡이가 먹습니다 — 아래 UI에는 가지 않습니다(모달 팝업의 표준 동작). 다른 버튼을 누르려던 사용자는 한 번 더 눌러야 합니다 | 아래로 그대로 갑니다 — 한 번에 닫히고 그 버튼도 눌립니다(그 버튼이 "삭제"여도) |
| 열기 버튼을 다시 눌러 닫기 | 잡이가 열기 버튼도 덮고 있어 그대로 닫힙니다 | 누르는 순간 닫히고, 떼는 순간 열기 버튼의 `Activated`가 다시 열 수 있습니다 — 열기 버튼 영역도 "안쪽"으로 치세요 [2026-10-20 기준 미실측] |
| 팝업 안의 빈 곳 | 평범한 `Frame`은 클릭을 막지 못해 그 누름이 잡이까지 내려가 팝업이 닫힙니다 — 아래 문단 | 사각형 안이라 문제없습니다 |
| 드는 것 | 팝업마다 버튼 하나 | 팝업마다 전역 입력 연결 하나(열린 동안만) |

**잡이를 쓰면 팝업 표면도 클릭을 막아야 합니다.** Roblox에서 GUI 클릭을 막는 것은 `GuiButton`뿐이고, 평범한 `Frame`·`CanvasGroup`은 `Active = true`여도 클릭을 아래 버튼으로 흘립니다(material 킷 Studio 실측 2026-10-08). 그래서 팝업 안의 버튼 아닌 곳을 누르면 그 누름이 잡이에 닿아 팝업이 닫힙니다. material은 표면의 **직속 자식**으로 투명 `TextButton`(`ClickSink` — `Size = UDim2.fromScale(1, 1)`, `ZIndex = 0`, `Selectable = false`, `Text = ""`)을 하나 깔아 막습니다. 표면 자신이 `UIListLayout`·`UIPadding`으로 자식을 늘어놓으면 그 버튼도 줄 하나로 끼므로, 그럴 땐 내용을 안쪽 Frame으로 한 번 감싸세요. 이 자식의 이름을 `InputSink`로 짓지 마세요 — 같은 이름의 엔진 프로퍼티(`GuiObject.InputSink`, Roblox 0.742)가 있어 `surface.InputSink`가 자식 대신 프로퍼티를 돌려줍니다(그 프로퍼티는 2026-10-08 Play 실측에서 효과가 없었다는 것이 킷의 기록입니다).

**어느 쪽이든 가리킴(hover)은 막지 못합니다.** 엔진은 `MouseEnter`/`MouseLeave`를 덮여 있는 요소에도 보냅니다 — 잡이나 버튼이 위에 있어도 아래 요소의 hover 표시가 반응합니다(devui 킷 Studio 확인 2026-10-20). devui는 이걸 "그 점에서 위에 있는 요소 목록을 위에서부터 걸어, 그 요소가 클릭을 받는 것(`GuiButton`·`TextBox`·`Active`인 `GuiObject`)보다 먼저 나오는가"로 다시 판정합니다. 목록은 `PlayerGui:GetGuiObjectsAtPosition(x, y)`가 위에서부터 줍니다 — 사각형 비교보다 정확한 세 번째 좌표 판정이지만 `PlayerGui` 아래의 `ScreenGui`에서만 됩니다(플러그인 위젯처럼 `PlayerGui`가 없는 곳에서는 devui의 hover 재판정은 엔진의 답을 그대로 두고, 창 포커스의 "누른 곳이 팝업 위인가" 판정만 팝업 사각형 목록으로 물러섭니다).

---

## 8. Escape는 맨 위 하나만

팝업이 여럿 겹쳐 열렸을 때(대화상자 위의 콤보 목록) Escape는 **맨 위 하나만** 닫아야 합니다. 팝업마다 자기 `InputBegan` 연결을 걸어 "Escape면 나를 닫는다"로 짜면 열린 것이 전부 한꺼번에 닫힙니다 — 연결마다 같은 키를 받고, 엔진은 연결들이 어떤 순서로 불리는지 정해 두지 않아 처리기끼리 "누가 맨 위인가"를 합의할 수도 없습니다(material 킷 주석의 판단).

두 킷의 현재 모양은 다릅니다.

- **material** — `Overlay`가 모든 오버레이가 함께 쓰는 **스택 하나와 연결 하나**를 둡니다. `DismissOnEscape`(또는 `Scrim`)로 연 항목이 열리며 스택에 오르고, Escape는 맨 위 항목만 닫습니다. 맨 위가 Escape로 닫히지 않는 모달이면 아무것도 닫지 않습니다 — 아래 것을 가립니다. 연결은 스택이 빌 때 끊깁니다. 오버레이 항목이 아닌데 Escape로 닫혀야 하는 것(내비게이션 서랍)은 `Overlay.onEscape(fn)`으로 같은 스택에 오릅니다. 엔진이 이미 처리한 Escape와 `TextBox`에 포커스가 있을 때의 Escape는 무시하고(타이핑 중에 대화상자가 닫히면 안 되므로), 게임패드 `ButtonB`는 늘 받습니다.
- **devui** — 스택이 없습니다. `Combo`의 목록과 `Menu`의 루트 메뉴가 열릴 때마다 자기 `InputBegan` 연결을 걸고, 팝업의 `OnClose`에서 끊습니다. Escape 한 번은 콤보 목록 하나를, 또는 하위 메뉴까지 포함한 메뉴 사슬 전체를 닫습니다(사슬은 루트 하나가 듣습니다). 서로 독립된 팝업 둘이 동시에 열려 있으면 연결마다 Escape를 받으므로 함께 닫힙니다 — [2026-10-20 기준] 킷 소스를 읽은 판단이고 실행으로 확인하지는 않았습니다.

킷 없이 quad만으로 짜는 최소 모양은 material의 모양을 줄인 것입니다.

```luau
--!strict
-- 새 파일: ReplicatedStorage/Client/UI/EscapeStack
const UserInputService = game:GetService("UserInputService")

type Entry = { Dismiss: () -> () }

const stack: { Entry } = {}
local conn: RBXScriptConnection? = nil

local function onInput(input: InputObject, processed: boolean)
    if input.KeyCode ~= Enum.KeyCode.Escape then
        return
    end
    -- 엔진이 이미 처리한 키, 타이핑 중인 Escape는 건드리지 않는다
    if processed or UserInputService:GetFocusedTextBox() ~= nil then
        return
    end
    const top = stack[#stack]
    if top ~= nil then
        top.Dismiss()
    end
end

-- 스택 맨 위에 올리고, 내리는 함수를 돌려준다(두 번 불러도 된다)
local function push(dismiss: () -> ()): () -> ()
    const entry: Entry = { Dismiss = dismiss }
    table.insert(stack, entry)
    if conn == nil then
        conn = UserInputService.InputBegan:Connect(onInput)
    end
    local released = false
    return function()
        if released then
            return
        end
        released = true
        const index = table.find(stack, entry)
        if index ~= nil then
            table.remove(stack, index)
        end
        -- 아무것도 열려 있지 않으면 연결도 없다
        if #stack == 0 then
            const c = conn
            if c ~= nil then
                conn = nil
                c:Disconnect()
            end
        end
    end
end

return { push = push }
```

팝업 쪽에서는 `q.Effect` 안에서 스택에 올리고, `push`가 돌려준 함수를 cleanup에서 부릅니다 — 만들 때 올리고, 그 팝업 Instance가 파괴될 때 내립니다([실전 레시피 04 §4](./04-network-and-input-bridge.md#4-컴포넌트-수명에-리스너-묶기)의 관용구). `q.Effect`는 만드는 그 자리에서 한 번 도는데 그때 호스트가 아직 없어도 상관없습니다 — 스택에 올리는 데는 Instance가 필요 없으니까요.

```luau
const EscapeStack = require("@game/ReplicatedStorage/Client/UI/EscapeStack")

local function openConfirm()
    local close: () -> () = function() end
    close = OverlayLayer.open(q.Elem "Frame" {
        Size = UDim2.fromOffset(320, 160),
        -- 만들 때 스택에 올리고, 이 Frame이 파괴될 때 내린다
        q.Effect(function()
            const release = EscapeStack.push(function()
                close()
            end)
            return function()
                release()
            end
        end),
        -- …내용…
    })
end
```

`release`를 감싸지 않고 `return EscapeStack.push(…)`로 바로 돌려주면 `--!strict`에서 막힙니다 — cleanup의 타입이 `(dying: boolean) -> ()`이라 인자 없는 `() -> ()` 함수 값은 들어가지 않습니다(그 자리에 바로 쓴 `function() … end`는 문맥으로 타입이 잡혀 통과합니다; [2026-10-20 실측, luau-lsp 신 솔버]).

<!-- mock 실측 2026-10-20: 둘을 올리면 연결 하나, processed·TextBox 포커스 중 Escape 무시, Escape가 위에서부터 하나씩 닫고 Effect cleanup이 스택에서 내림, 비면 연결 끊김, 빈 dismiss를 올린 항목이 아래를 가림 -->

- **Escape로 닫히지 않는 모달**이 아래 팝업까지 가리게 하려면 아무것도 하지 않는 함수를 올리세요 — `EscapeStack.push(function() end)`. 맨 위에 있는 동안 Escape가 그 아래로 내려가지 않습니다.
- **닫힘 애니메이션으로 내용을 잠시 남겨 둔다면**, 그동안에도 그 항목이 스택 맨 위에 남아 다음 Escape를 먹습니다. 그럴 땐 `push`가 돌려준 함수를 받아 두었다가 **닫기 시작할 때** 직접 부르세요 — 두 번 불러도 되므로 cleanup이 나중에 다시 불러도 무해합니다(material은 닫기를 시작하는 순간 스택에서 내립니다). Deferred 시그널에서는 `Destroying`이 조금 늦게 오므로, 애니메이션이 없어도 닫는 쪽에서 먼저 내리는 편이 깔끔합니다.
- **게임패드**를 받으려면 `onInput`에서 `Enum.KeyCode.ButtonB`도 받으세요. material은 `ButtonB`를 엔진 처리 여부와 무관하게 받습니다.

---

## 9. 체크리스트

- [ ] 오버레이(모달·토스트)가 화면 뿌리의 자리 하나에 놓여 있는가?
- [ ] 열림 상태를 컴포넌트 밖의 `Source`에 두고, `Visible` 유지와 조건부 자식 중 이 오버레이에 맞는 쪽을 골랐는가?
- [ ] 깊은 트리거는 `q.Context`로 열쇠만 받고, 중간 컴포넌트는 그 안에 뭐가 들었는지 몰라도 되는가?
- [ ] 토스트마다 변하지 않는 `Id`가 있고, 배열은 제자리 수정 대신 새 테이블로 바꿔 `:Set` 하는가?
- [ ] 던질 수 있는 컴포넌트를 `q.Fallback`으로 감쌌고, 그 에러를 받는 자리를 정했는가? → [10. 부록 — quad 에러 읽는 법](./10-debugging-and-troubleshooting.md)
- [ ] 모듈 수준 기본 레이어를 require 시점에 만들지 않고, 줄 때마다 살아 있는지 보며, 화면을 다시 지을 때 다시 받아 붙이는가?
- [ ] 바깥 클릭으로 닫는 방식(잡이 / 좌표)을 골랐고, 잡이라면 팝업 표면이 클릭을 막는가?
- [ ] Escape는 스택 하나·연결 하나로 맨 위만 닫고, 그 등록이 팝업의 수명(`q.Effect` cleanup)에 묶여 있는가?

---

## 이해 점검

```quiz
# 인스턴스를 유지할까, 열릴 때만 만들까

모달을 열고 닫을 때 `Visible` 바인딩과 조건부 자식(`State<Instance?>`) 중 어느 쪽을 쓸지 정하는 기준은 무엇인가요?

- [x] 자주 여닫고 콘텐츠가 가볍다면 `Visible`로 유지하고, 무겁고 좀처럼 안 열린다면 열릴 때만 만드는 쪽이 낫습니다
- [ ] 둘은 결과가 완전히 같으므로 아무 쪽이나 골라도 상관없습니다
- [ ] `Visible` 바인딩은 모달에는 쓸 수 없고 조건부 자식만 가능합니다

`Visible`로 유지하면 다시 열 때 인스턴스를 새로 만들 필요가 없습니다. 조건부 자식 자리는 갈아 끼운 옛 원소를 파괴하지 않으므로(시작하기 11 §6) 닫을 때 `:SetAndDispose`로 옛 모달까지 정리해야 한다는 것도 고려할 점입니다.
```

```quiz
# 트리거는 깊고 오버레이는 뿌리

트리 깊은 곳의 버튼이 뿌리의 모달을 열 때 `q.Context`를 쓰는 이유는 무엇인가요?

- [x] 중간 컴포넌트들이 열쇠 이름도, 안에 뭐가 들었는지도 모른 채 가방만 넘기면 되기 때문입니다
- [ ] `Context`가 트리를 거슬러 올라가 값을 자동으로 찾아 주기 때문입니다
- [ ] props로 내리는 것보다 `Context`가 항상 더 빠르기 때문입니다

quad의 `Context`는 명시적 가방입니다 — 트리 탐색은 없고, 가방도 손으로 넘겨야 합니다. 줄어드는 것은 중간 층이 알아야 할 이름의 수이지, 넘기는 행위 자체가 아닙니다.
```

```quiz
# Fallback의 onError가 하는 일

`q.Fallback(Card, onError)`에서 `onError`가 반드시 해야 하는 일은 무엇인가요?

- [x] 대체 결과(예: 빈 Frame)를 돌려줘야 합니다 — 에러 자체를 다른 컴포넌트가 보게 하려면 `errorState:Set(err)`처럼 별도 상태에 적어야 합니다
- [ ] `err`를 화면에 직접 그려서 돌려주면 되고 별도 상태는 필요 없습니다
- [ ] 아무것도 돌려주지 않아도 quad가 알아서 원래 컴포넌트를 재시도합니다

`Fallback`이 돌려주는 함수는 항상 `Ok | Err` 값 하나를 돌려줘야 하므로 `onError`는 그 자리를 채울 대체 값을 반환해야 합니다. 에러 자체를 에러 모달 같은 다른 컴포넌트가 보게 하려면 `onError` 안에서 그 값을 상태에 적어 두는 것이 정본입니다.
```

```quiz
# 모듈 변수에 쥔 레이어

require 시점에 만든 오버레이 레이어를 모듈 변수에 들고 있으면 무슨 일이 나나요?

- [x] 그 레이어를 붙인 화면이 파괴되면 레이어도 같이 죽고, 다시 지은 화면에 같은 레이어를 넣는 순간 `Quad0219`로 막힙니다
- [ ] quad가 죽은 레이어를 알아서 새로 만들어 줍니다
- [ ] 레이어는 화면과 무관하게 살아 있으므로 아무 문제가 없습니다

quad가 만든 Instance도 엔진 Instance라 부모와 함께 파괴됩니다. 기본 레이어는 처음 달라고 할 때 만들고, 줄 때마다 살아 있는지 보고, 화면을 지을 때마다 다시 받아 붙이세요.
```

```quiz
# 잡이와 좌표 판정

바깥 클릭으로 팝업을 닫을 때, 전체 화면 잡이 버튼이 좌표 판정과 다르게 동작하는 점은 무엇인가요?

- [x] 닫는 그 누름을 잡이가 먹어서 아래 UI에는 가지 않습니다
- [ ] 잡이를 쓰면 팝업 안의 빈 곳을 눌러도 절대 닫히지 않습니다
- [ ] 잡이는 회전한 팝업에서 동작하지 않습니다

잡이는 엔진의 히트 테스트를 그대로 쓰고 닫는 누름을 소비합니다(모달 팝업의 표준 동작). 대신 평범한 Frame은 클릭을 막지 못하므로, 팝업 표면에도 투명 버튼을 깔아야 안쪽 빈 곳의 누름이 잡이까지 내려가지 않습니다.
```

---

## 관련

- [시작하기 11. 자식이 들어갈 자리 — Slot](../getting-started/11-slot.md) — 조건부 자식 관용구와 `Offset`/`Length`
- [시작하기 14. 목록 만들기 — Slot:List](../getting-started/14-lists.md) — `updateFn` 계약, 신원(`Id`), 배열 교체
- [시작하기 15. 층을 건너 값 넘기기 — q.Context](../getting-started/15-context.md) — 가방과 열쇠, 중간 층이 모른 채 넘기는 이유
- [레퍼런스: Slot](../reference/core/06-slot.md) — `:List`/`:Single`의 전체 계약
- [레퍼런스: Context / Provider](../reference/sugar/01-context.md) — 타입을 붙이는 두 방법, 가방의 수명
- [레퍼런스: Fallback / Traceback](../reference/sugar/05-fallback-traceback.md) — `err: any` 계약, 회수되지 않는 부분 트리
- [실전 레시피 01. 컴포넌트 경계 규약과 스타일 합성](./01-component-conventions.md) — `or None`, `Slot`으로 자식 받기
- [실전 레시피 04. RemoteEvent와 엔진 입력을 상태로 브릿징하기](./04-network-and-input-bridge.md) — 입력 연결을 `Effect` cleanup·`OnDestroyed`로 Instance 수명에 묶기
- [실전 레시피 11. quad 위에 라이브러리 얹기](./11-library-on-quad.md) — 킷이 기본 레이어 같은 모듈 수준 값을 둘 때의 나머지 규칙
- [10. 부록 — quad 에러 읽는 법](./10-debugging-and-troubleshooting.md) — 에러가 어느 줄을 blame하는지 읽는 법
