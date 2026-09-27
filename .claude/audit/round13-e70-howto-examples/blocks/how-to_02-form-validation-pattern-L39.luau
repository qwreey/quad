-- 재사용 컴포넌트(예: ReplicatedStorage/Client/UI/Checkbox)
local function Checkbox(props: { read Value: q.Source<boolean>, read Label: string }): TextButton
    local checked = props.Value

    -- 파생은 props 테이블 밖에서 만들어 둔다(§4의 주의 참고)
    local labelText: q.State<string> = checked:Compute(function(c)
        return `{if c:Get() then "☑" else "☐"} {props.Label}`
    end)

    return D.TextButton {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Text = labelText,

        Activated = function()
            checked:Set(not checked:Get())
        end,
    }
end
