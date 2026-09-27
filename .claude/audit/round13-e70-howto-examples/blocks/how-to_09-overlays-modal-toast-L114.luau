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
