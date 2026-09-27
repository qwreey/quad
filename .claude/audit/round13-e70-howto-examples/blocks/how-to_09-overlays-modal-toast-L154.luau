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
