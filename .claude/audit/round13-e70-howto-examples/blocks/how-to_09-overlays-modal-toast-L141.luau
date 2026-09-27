-- 새 파일: ReplicatedStorage/Client/UI/ModalContext
const q = require("./Quad")

export type ModalBag = { Open: q.Source<boolean> }

return {
    Provider = q.Context.Provider<<ModalBag>>("Modal"),
}
