--!strict
local q = require("./s10-config")
local D = q.Declaration

type Submission = { Username: string, Password: string }

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

local function RegistrationForm(props: { read Form: FormState }): Frame
	local form = props.Form
	local store = form.Store

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

		D.UIListLayout { Padding = UDim.new(0, 8) },

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

local screen = D.ScreenGui {
	RegistrationForm { Form = form },

	form.Submitted:Observer(function(target: q.StateData<Submission?>)
		local payload = target:Get()
		if payload == nil then
			return
		end
		print("가입 요청:", payload.Username)
	end),
}
print(screen)
