--!strict
-- E70 strict (generated) — how-to_09-overlays-modal-toast-L174
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_09-overlays-modal-toast-L10) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
const q = require("./Quad")
const D = q.Declaration
const None = q.None
--[[E70 보강 pre2]]
const ModalContext = require("./ModalContext")
-- ==== doc block how-to/09-overlays-modal-toast.md:174 ====
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
