--!strict
-- E70 strict (generated) — how-to_09-overlays-modal-toast-L196
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_09-overlays-modal-toast-L10) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
const q = require("./Quad")
const D = q.Declaration
const None = q.None
-- ==== doc block how-to/09-overlays-modal-toast.md:196 ====
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
    return D.TextLabel {
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

const toastHost = D.Frame {
    D.UIListLayout { Padding = UDim.new(0, 4) },
    toastList,
}
