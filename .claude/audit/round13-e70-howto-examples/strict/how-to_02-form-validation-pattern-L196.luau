--!strict
-- E70 strict (generated) — how-to_02-form-validation-pattern-L196
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_02-form-validation-pattern-L27) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
-- ==== with how-to/02-form-validation-pattern.md:112 ====
-- 폼 상태만 모아 둔 모듈(예: ReplicatedStorage/Client/UI/RegistrationFormState).
-- 화면을 만들지 않으므로 UI 없이도 require해서 검증할 수 있습니다.
type Submission = { Username: string, Password: string }

local function makeFormState()
    -- [1] 원본 입력값
    local store = q.Store({
        Username = q.Source(""),
        Password = q.Source(""),
    })

    -- [2] 필드별 판정 — 순수 파생 상태
    local isUsernameValid = store.Username:Compute(function(self)
        return #self:Get() >= 4
    end)

    local isPasswordValid = store.Password:Compute(function(self)
        local text = self:Get()
        return #text >= 8 and string.find(text, "%d") ~= nil
    end)

    -- [3] 둘을 하나로 — 후행 의존성으로 노드 하나만 더 만든다
    local canSubmit = isUsernameValid:Compute(function(validUser, _previous, validPass)
        return validUser:Get() and validPass:Get()
    end, isPasswordValid)

    -- [4] 제출 결과가 담기는 자리 — 바깥으로 나가는 하나뿐인 출구
    local submitted = q.Source<<Submission?>>(nil)

    return {
        Store = store,
        IsUsernameValid = isUsernameValid,
        IsPasswordValid = isPasswordValid,
        CanSubmit = canSubmit,
        Submitted = submitted,
    }
end

type FormState = typeof(makeFormState())
-- ==== doc block how-to/02-form-validation-pattern.md:196 ====
local function RegistrationForm(props: { read Form: FormState }): Frame
    local form = props.Form
    local store = form.Store

    -- 파생 상태는 props 테이블 밖에서 만들어 둔다(아래 주의 참고).
    -- 보이는 모양(색·표시 여부)은 폼 상태가 아니라 이 컴포넌트의 것이다.
    local showUsernameError: q.State<boolean> = form.IsUsernameValid:Compute(function(valid)
        return not valid:Get()
    end)
    local submitColor: q.State<Color3> = form.CanSubmit:Compute(function(enabled)
        return if enabled:Get()
            then Color3.fromRGB(0, 170, 255)
            else Color3.fromRGB(80, 80, 90)
    end)

    return D.Frame {
        Size = UDim2.new(0, 320, 0, 240),
        BackgroundColor3 = Color3.fromRGB(30, 30, 35),

        -- 세로로 쌓는다(각 요소의 Size 같은 모양 프로퍼티는 줄이려고 생략했다)
        D.UIListLayout { Padding = UDim.new(0, 8) },

        -- 아이디 입력창
        D.TextBox {
            PlaceholderText = "아이디 (4자 이상)",
            Text = store.Username,          -- in: 상태 → 입력창
            q.Out("Text", store.Username), -- out: 입력창 → 상태 (OnChange 위 슈거)
        },

        -- 아이디 에러 메시지
        D.TextLabel {
            Text = "아이디는 4글자 이상이어야 합니다.",
            TextColor3 = Color3.fromRGB(255, 100, 100),
            Visible = showUsernameError,
        },

        -- 비밀번호 입력창
        D.TextBox {
            PlaceholderText = "비밀번호 (8자 이상, 숫자 포함)",
            Text = store.Password,
            q.Out("Text", store.Password),
        },

        -- 제출 버튼 — 결과를 직접 처리하지 않고 상태에 적기만 한다
        D.TextButton {
            Text = "가입하기",
            Interactable = form.CanSubmit, -- false면 눌리지 않는다
            BackgroundColor3 = submitColor,
            MouseButton1Click = function()
                -- Interactable로 이미 막히지만, 상태 기준으로 한 번 더 확인한다
                if not form.CanSubmit:Get() then
                    return
                end
                form.Submitted:Set({
                    Username = store.Username:Get(),
                    Password = store.Password:Get(),
                })
            end,
        },
    }
end
