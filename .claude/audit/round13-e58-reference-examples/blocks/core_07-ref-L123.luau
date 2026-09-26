local inputRef = q.PreRef<<TextBox?>>(nil)
local form = D.Frame {
    D.TextBox { inputRef },
    D.TextButton {
        Text = "지우기",
        Activated = function()
            inputRef:Unwrap().Text = "" -- pre-pass가 이미 채웠다
        end,
    },
}
