--!strict
-- E70 strict (generated) — how-to_02-form-validation-pattern-L39
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_02-form-validation-pattern-L27) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
-- ==== doc block how-to/02-form-validation-pattern.md:39 ====
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
