const open = q.Source(false)

const confirmDialog = Modal {
    Open = open,
    Title = "정말 삭제할까요?",
    OnConfirm = function() print("삭제 확정") end,
    OnCancel = function() print("취소함") end,
}
