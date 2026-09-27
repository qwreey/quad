--!strict
-- E70 strict (generated) — how-to_09-overlays-modal-toast-L46
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_09-overlays-modal-toast-L10) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
const q = require("./Quad")
const D = q.Declaration
const None = q.None
-- ==== doc block how-to/09-overlays-modal-toast.md:46 ====
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
