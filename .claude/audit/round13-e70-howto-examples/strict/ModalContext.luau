--!strict
-- E70 strict (generated) — how-to_09-overlays-modal-toast-L141
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_09-overlays-modal-toast-L10) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
const q = require("./Quad")
const D = q.Declaration
const None = q.None
-- ==== doc block how-to/09-overlays-modal-toast.md:141 ====
-- 새 파일: ReplicatedStorage/Client/UI/ModalContext
const q = require("./Quad")

export type ModalBag = { Open: q.Source<boolean> }

return {
    Provider = q.Context.Provider<<ModalBag>>("Modal"),
}
