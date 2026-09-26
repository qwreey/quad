--!strict
-- E15 (e) — S1 composite in strict: how-to 02 §2/§3/§4/§5 verbatim + how-to 05 §1 Context + sugar/03 Debounce + GS 09 hooks.
local q = require("./round13-e15-probe-types-settings")
local D = q.Declaration

type Submission = { Username: string, Password: string }
type Theme = { Accent: Color3 }
local ThemeProvider = q.Context.Provider<<Theme>>("Theme")

local function makeFormState()
    local store = q.Store({
        Username = q.Source(""),
        Password = q.Source(""),
    })
    local isUsernameValid = store.Username:Compute(function(self)
        return #self:Get() >= 4
    end)
    local isPasswordValid = store.Password:Compute(function(self)
        local text = self:Get()
        return #text >= 8 and string.find(text, "%d") ~= nil
    end)
    local canSubmit = isUsernameValid:Compute(function(validUser, _previous, validPass)
        return validUser:Get() and validPass:Get()
    end, isPasswordValid)
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

local function RegistrationForm(props: { read Form: FormState, read Ctx: q.Context }): Frame
    local form = props.Form
    local store = form.Store
    local theme = props.Ctx:Get(ThemeProvider)
    local showUsernameError: q.State<boolean> = form.IsUsernameValid:Compute(function(valid)
        return not valid:Get()
    end)
    local submitColor: q.State<Color3> = form.CanSubmit:Compute(function(enabled)
        return if enabled:Get() then theme.Accent else Color3.fromRGB(80, 80, 90)
    end)
    -- debounced availability search (sugar/03 example shape)
    local debounced: q.State<string> = store.Username:Apply(q.Debounce { Time = 0.3 })
    local availability = q.Source("idle")
    return D.Frame {
        Size = UDim2.new(0, 320, 0, 240),
        D.UIListLayout { Padding = UDim.new(0, 8) },
        q.OnCreated<<Frame>>(function(inst) print(inst.ClassName) end),
        q.OnRendered<<Frame>>(function(inst) print(#inst:GetChildren()) end),
        q.OnDestroyed(function() print("gone") end),
        debounced:Observer(function(t)
            local v = t:Get()
            availability:Set(if #v >= 4 then "checking " .. v else "idle")
        end),
        D.TextBox {
            PlaceholderText = "아이디 (4자 이상)",
            Text = store.Username,
            q.Out("Text", store.Username),
        },
        D.TextLabel {
            Text = "아이디는 4글자 이상이어야 합니다.",
            TextColor3 = Color3.fromRGB(255, 100, 100),
            Visible = showUsernameError,
        },
        D.TextLabel { Text = availability },
        D.TextBox {
            PlaceholderText = "비밀번호 (8자 이상, 숫자 포함)",
            Text = store.Password,
            q.Out("Text", store.Password),
        },
        D.TextButton {
            Text = "가입하기",
            Interactable = form.CanSubmit,
            BackgroundColor3 = submitColor,
            MouseButton1Click = function()
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

local form = makeFormState()
local ctx = q.Context():Set(ThemeProvider, { Accent = Color3.fromRGB(0, 170, 255) })
local blocker = q.Blocker()
local gatedCan: q.State<boolean> = form.CanSubmit:Apply(blocker)
local screen = D.ScreenGui {
    RegistrationForm { Form = form, Ctx = ctx },
    form.Submitted:Observer(function(target)
        local payload = target:Get()
        if payload == nil then
            return
        end
        print("가입 요청:", payload.Username)
    end),
    gatedCan:Observer(function(t) print(t:Get()) end),
}
blocker:On()
form.Store.Username:Set("")
form.Store.Password:Set("")
blocker:Off()
local _ = screen
