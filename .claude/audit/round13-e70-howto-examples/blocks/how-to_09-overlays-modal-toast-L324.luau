const screen = D.ScreenGui {
    SafeCard { Text = someUnsafeText }, -- 던지면 자리표시 값이 대신 앉는다

    ErrorModal {
        Error = errorState,
        OnReport = function(err) print("신고:", err) end,
        OnConfirm = function() errorState:Set(nil) end,
    },
}
