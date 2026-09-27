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
