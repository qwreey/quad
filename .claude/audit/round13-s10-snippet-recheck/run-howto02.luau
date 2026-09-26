--!nocheck
local H = require("./harness")
local q, D = H.q, H.D
UDim2 = H.EG.UDim2
UDim = H.EG.UDim
Color3 = H.EG.Color3

local function makeFormState()
	local store = q.Store({
		Username = q.Source(""),
		Password = q.Source(""),
	})

	local isUsernameValid = store.Username:Compute(function(self) return #self:Get() >= 4 end)
	local isPasswordValid = store.Password:Compute(function(self)
		local text = self:Get()
		return #text >= 8 and string.find(text, "%d") ~= nil
	end)
	local canSubmit = isUsernameValid:Compute(function(validUser, _previous, validPass)
		return validUser:Get() and validPass:Get()
	end, isPasswordValid)

	local submitted = q.Source(nil :: any)

	return {
		Store = store,
		IsUsernameValid = isUsernameValid,
		IsPasswordValid = isPasswordValid,
		CanSubmit = canSubmit,
		Submitted = submitted,
	}
end

local function RegistrationForm(props)
	local form = props.Form
	local store = form.Store

	local showUsernameError = form.IsUsernameValid:Compute(function(valid) return not valid:Get() end)
	local submitColor = form.CanSubmit:Compute(function(enabled)
		return if enabled:Get() then Color3.fromRGB(0, 170, 255) else Color3.fromRGB(80, 80, 90)
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

	-- TARGET: typed Observer callback in numeric key
	form.Submitted:Observer(function(target: q.StateData<any>)
		local payload = target:Get()
		if payload == nil then
			return
		end
		print("가입 요청:", payload.Username)
	end),
}

-- drive the form: username 4+ chars, password 8+ chars with a digit, then click submit
form.Store.Username:Set("abcd")
form.Store.Password:Set("password1")
print("CanSubmit:", form.CanSubmit:Get())

local panel = screen:GetChildren()[1]
local button
for _, child in panel:GetChildren() do
	if child.ClassName == "TextButton" then button = child end
end
print("button class:", button.ClassName, button.Text)
button.MouseButton1Click:Fire()
