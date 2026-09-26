local btnRef = q.PreRef<<TextButton?>>(nil)
local button = D.TextButton {
    btnRef,
    Text = "보내기",
    Activated = function()
        btnRef:Unwrap().BackgroundTransparency = 0.5 -- 가드 없이
    end,
}
