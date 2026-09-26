---
title: "09. 떠 있는 것 열고 닫기 — 모달과 토스트"
description: "화면 뿌리에 오버레이 자리를 두고, 트리 깊은 곳에서 Context로 열고, Slot:List로 토스트 큐를 굴리고, Fallback으로 던진 에러를 모달에 담는 법을 다룹니다"
---
# [실전 레시피] 09. 떠 있는 것 열고 닫기 — 모달과 토스트

> **대상 독자**: 확인 대화상자·알림·에러 안내처럼 트리 깊은 곳에서 열리지만 화면 맨 위 한 곳에 그려지는 오버레이를 만들려는 개발자
> **다루는 개념**: `Visible` 바인딩과 조건부 자식(`State<Instance?>`), `q.Context`로 층 건너 열기, `Slot:List`로 토스트 큐, `q.Fallback`으로 던진 에러를 모달에 담기

```luau
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
const q = require("@game/ReplicatedStorage/Client/UI/Quad")
const D = q.Declaration
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
    return D.Frame {
        Size = UDim2.fromOffset(360, 220),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(30, 30, 35),

        Visible = props.Open,

        D.TextLabel {
            Text = props.Title,
            Size = UDim2.new(1, 0, 0, 40),
        },

        props.Children or None, -- ⭐ 숫자 키 자리, or None으로 nil-hole 방지(실전 레시피 01)

        D.TextButton {
            Text = "확인",
            Position = UDim2.new(0, 20, 1, -48),
            Size = UDim2.fromOffset(140, 36),
            Activated = function()
                props.Open:Set(false)
                props.OnConfirm()
            end,
        },
        D.TextButton {
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
    activeModal:Set(Modal {
        Open = q.Source(true), -- 이 갈래에서는 열림 자체가 "만들어져 있는가"이므로 별도 Open이 꼭 필요하지는 않습니다
        Title = "정말 삭제할까요?",
        OnConfirm = function()
            activeModal:Set(nil)
        end,
        OnCancel = function()
            activeModal:Set(nil)
        end,
    })
end
```

`activeModal`을 다른 값으로 갈아 끼우면 **옛 인스턴스는 파괴되지 않고 트리에서 떼어지기만 합니다**([시작하기 11 §6](../getting-started/11-slot.md#6-하나만-갈아-끼우기--state를-자리에-놓기)) — 다시 쓸 일이 없으면 `q.dispose`로 직접 정리하세요. 그래서 매번 새로 만드는 이 모양은 열 때마다 확실히 버릴 생각이 있을 때 씁니다.

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

const screen = D.ScreenGui {
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

    return D.TextButton {
        Text = "삭제",
        Activated = function()
            modal.Open:Set(true)
        end,
    }
end
```

가방을 하나 만들어 값 여러 개(예: 여러 종류의 모달을 여는 명령들)를 같이 담아도 됩니다 — 여기서는 `Open` 하나뿐인 가방을 보였을 뿐, 가방 자체는 [Context 레퍼런스](../reference/sugar/01-context.md)의 규칙(명시적 전달, 복제 없음, `Get`은 없으면 에러) 그대로입니다.

---

## 4. 토스트

토스트는 모달과 달리 **여러 개가 동시에 떠 있을 수 있고**, 각자 시간이 지나면 스스로 사라집니다. 데이터가 배열이라는 점에서 [시작하기 14](../getting-started/14-lists.md)의 `Slot:List`가 그대로 맞습니다 — 항목마다 변하지 않는 신원(`Id`)이 필요하다는 규칙도 같습니다.

```luau
type Toast = { Id: number, Text: string }

const toasts = q.Source<<{ Toast }>>({})

const toastList = q.Slot()
toastList:List(toasts, function(ctx)
    if ctx.Item == q.KeyGone then
        return nil, ctx.UserData -- 사라진 토스트 → 파괴
    end
    if ctx.Prev then
        return ctx.Prev, ctx.UserData -- 이미 있는 토스트 → 그대로 둔다
    end
    return D.TextLabel {
        Text = ctx.Item.Text,
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

const toastHost = D.Frame {
    D.UIListLayout { Padding = UDim.new(0, 4) },
    toastList,
}
```

`Id`를 늘어나기만 하는 카운터로 둔 것은 [시작하기 14 §3](../getting-started/14-lists.md#3-데이터를-바꾸면-필요한-것만-바뀝니다)의 경고와 같은 이유입니다 — 배열 길이나 시각처럼 되풀이될 수 있는 값을 신원으로 쓰면 같은 `Id`가 다시 생겨 `Quad0145 Slot:List: duplicate key`로 막힙니다.

---

## 5. 던진 것을 에러 모달이 받는다

컴포넌트 안에서 던진 에러를 화면 어딘가의 "에러 모달"이 받아 보여주고 싶을 때가 있습니다. [Fallback/Traceback 레퍼런스](../reference/sugar/05-fallback-traceback.md)의 계약을 그대로 씁니다 — `q.Fallback(base, onError)`가 돌려주는 함수는 `base`가 던지면 `onError(err)`의 **대체 값을 돌려줘야** 합니다. 그 자리를 채우는 것과, 에러를 모달에 보이는 것은 **다른 일**입니다 — 대체 값은 그 자리를 메우는 빈 값(`D.Frame {}`)으로 두고, 에러 자체는 바깥에서 관측할 수 있는 상태에 적습니다.

```luau
-- 예시 컴포넌트 — Text가 비어 있으면 던진다(던지는 쪽은 아무 컴포넌트여도 됩니다)
local function Card(props: { read Text: string }): Frame
    if props.Text == "" then
        error("Card: Text must not be empty")
    end
    return D.Frame {
        D.TextLabel { Text = props.Text },
    }
end

const errorState = q.Source<<any>>(nil)

local function onError(err: any): Instance
    errorState:Set(err)
    return D.Frame {} -- 자리표시 값 — Card가 있어야 할 자리를 채우기만 한다
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
    return D.Frame {
        Visible = props.Error:Compute(function(e)
            return e:Get() ~= nil
        end),

        D.TextLabel {
            Text = props.Error:Compute(function(e)
                const value = e:Get()
                return if value == nil then "" else tostring(value)
            end),
        },

        D.TextButton {
            Text = "신고",
            Activated = function()
                props.OnReport(props.Error:Get())
            end,
        },
        D.TextButton {
            Text = "확인",
            Activated = function()
                props.OnConfirm()
            end,
        },
    }
end
```

부르는 쪽에서 `SafeCard`와 `ErrorModal`을 같은 화면에 놓고, `errorState`를 지우는 쪽(`OnConfirm`)만 정해 주면 됩니다.

```luau
const screen = D.ScreenGui {
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
[Fallback/Traceback 레퍼런스](../reference/sugar/05-fallback-traceback.md#공통-계약)의 caution 그대로입니다 — **던지기 전에 이미 만들어진 부분 트리는 이 경계가 정리해 주지 않고**, **예외가 지나간 자리의 quad 부기도 복구되지 않습니다**(`Declaration`이 중간에 던지면 배치 게이트가 켜진 채 남는 등). 이 경계 안에서 던진 인스턴스는 계속 쓰지 말고, 대체 UI는 항상 새 인스턴스로 만드세요.
:::

---

## 6. 체크리스트

- [ ] 오버레이(모달·토스트)가 화면 뿌리의 자리 하나에 놓여 있는가?
- [ ] 열림 상태를 컴포넌트 밖의 `Source`에 두고, `Visible` 유지와 조건부 자식 중 이 오버레이에 맞는 쪽을 골랐는가?
- [ ] 깊은 트리거는 `q.Context`로 열쇠만 받고, 중간 컴포넌트는 그 안에 뭐가 들었는지 몰라도 되는가?
- [ ] 토스트마다 변하지 않는 `Id`가 있고, 배열은 제자리 수정 대신 새 테이블로 바꿔 `:Set` 하는가?
- [ ] 던질 수 있는 컴포넌트를 `q.Fallback`으로 감쌌고, 그 에러를 받는 자리를 정했는가? → [10. 부록 — quad 에러 읽는 법](./10-debugging-and-troubleshooting.md)

---

## 이해 점검

```quiz
# 인스턴스를 유지할까, 열릴 때만 만들까

모달을 열고 닫을 때 `Visible` 바인딩과 조건부 자식(`State<Instance?>`) 중 어느 쪽을 쓸지 정하는 기준은 무엇인가요?

- [x] 자주 여닫고 콘텐츠가 가볍다면 `Visible`로 유지하고, 무겁고 좀처럼 안 열린다면 열릴 때만 만드는 쪽이 낫습니다
- [ ] 둘은 결과가 완전히 같으므로 아무 쪽이나 골라도 상관없습니다
- [ ] `Visible` 바인딩은 모달에는 쓸 수 없고 조건부 자식만 가능합니다

`Visible`로 유지하면 다시 열 때 인스턴스를 새로 만들 필요가 없습니다. 조건부 자식 자리는 갈아 끼운 옛 원소를 파괴하지 않으므로(시작하기 11 §6) 닫을 때 직접 `q.dispose`로 정리해야 한다는 것도 고려할 점입니다.
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

---

## 관련

- [시작하기 11. 자식이 들어갈 자리 — Slot](../getting-started/11-slot.md) — 조건부 자식 관용구와 `Offset`/`Length`
- [시작하기 14. 목록 만들기 — Slot:List](../getting-started/14-lists.md) — `updateFn` 계약, 신원(`Id`), 배열 교체
- [시작하기 15. 층을 건너 값 넘기기 — q.Context](../getting-started/15-context.md) — 가방과 열쇠, 중간 층이 모른 채 넘기는 이유
- [레퍼런스: Slot](../reference/core/06-slot.md) — `:List`/`:Single`의 전체 계약
- [레퍼런스: Context / Provider](../reference/sugar/01-context.md) — 타입을 붙이는 두 방법, 가방의 수명
- [레퍼런스: Fallback / Traceback](../reference/sugar/05-fallback-traceback.md) — `err: any` 계약, 회수되지 않는 부분 트리
- [실전 레시피 01. 컴포넌트 경계 규약과 스타일 합성](./01-component-conventions.md) — `or None`, `Slot`으로 자식 받기
- [10. 부록 — quad 에러 읽는 법](./10-debugging-and-troubleshooting.md) — 에러가 어느 줄을 blame하는지 읽는 법
