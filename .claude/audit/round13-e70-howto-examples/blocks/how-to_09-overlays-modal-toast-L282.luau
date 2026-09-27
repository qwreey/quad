local function ErrorModal(props: {
    read Error: q.State<any>,
    read OnReport: (err: any) -> (),
    read OnConfirm: () -> (),
}): Frame
    -- 파생 상태는 props 테이블 밖에서 만들어 둔다(아래 주의 참고)
    const visible: q.State<boolean> = props.Error:Compute(function(e)
        return e:Get() ~= nil
    end)
    const text: q.State<string> = props.Error:Compute(function(e)
        const value = e:Get()
        return if value == nil then "" else tostring(value)
    end)

    return D.Frame {
        Visible = visible,

        D.TextLabel {
            Text = text,
        },

        D.TextButton {
            Text = "신고",
            Activated = function()
                props.OnReport(props.Error:Get())
            end,
        },
        D.TextButton {
            Text = "확인",
            Activated = function()
                props.OnConfirm()
            end,
        },
    }
end
