--!nocheck
-- round13 E15 S1 — how-to 02 registration form + how-to 05/GS15 theme Context + Debounce'd availability
-- search + lifecycle hooks. Sections a (normal) / b (teardown) / c (re-entrancy) / d (batch+time).
local H = require("./round13-e15-probe-setup")
local q, D, mock, try, track, alive = H.q, H.D, H.mock, H.try, H.track, H.alive
local C3 = function(r, g, b) return { r = r, g = g, b = b } end

-- how-to 02 makeFormState verbatim (types stripped)
local function makeFormState()
	local store = q.Store({ Username = q.Source(""), Password = q.Source("") })
	local isUsernameValid = store.Username:Compute(function(self) return #self:Get() >= 4 end)
	local isPasswordValid = store.Password:Compute(function(self)
		local text = self:Get()
		return #text >= 8 and string.find(text, "%d") ~= nil
	end)
	local canSubmit = isUsernameValid:Compute(function(validUser, _previous, validPass)
		return validUser:Get() and validPass:Get()
	end, isPasswordValid)
	local submitted = q.Source(nil)
	return { Store = store, IsUsernameValid = isUsernameValid, IsPasswordValid = isPasswordValid, CanSubmit = canSubmit, Submitted = submitted }
end

local ThemeProvider = q.Context.Provider("Theme")
local log = {}
local function L(s) table.insert(log, s) end

local function RegistrationForm(props)
	local form, store = props.Form, props.Form.Store
	local theme = props.Ctx:Get(ThemeProvider)
	local showUsernameError = form.IsUsernameValid:Compute(function(valid) return not valid:Get() end)
	local submitColor = form.CanSubmit:Compute(function(enabled) return if enabled:Get() then theme.Accent else C3(80, 80, 90) end)
	-- Debounced availability check ("search") — sugar/03 + how-to 03 §5 shape
	local debounced = store.Username:Apply(q.Debounce { Time = 0.3 })
	local availability = q.Source("idle")
	track("S1.debounced", debounced); track("S1.submitColor", submitColor)
	local root = D.Frame {
		D.UIListLayout { Padding = H.UDim.new(0, 8) },
		q.OnCreated(function(inst) L("created " .. inst.ClassName) end),
		q.OnRendered(function(inst) L("rendered kids=" .. #inst:GetChildren()) end),
		q.OnDestroyed(function() L("form destroyed") end),
		debounced:Observer(function(t)
			local v = t:Get()
			L("debounced -> '" .. v .. "' @" .. H.now())
			availability:Set(if #v >= 4 then "checking " .. v else "idle")
		end),
		D.TextBox { Name = "User", PlaceholderText = "id", Text = store.Username, q.Out("Text", store.Username) },
		D.TextLabel { Name = "UserErr", Text = "id>=4", Visible = showUsernameError },
		D.TextLabel { Name = "Avail", Text = availability },
		D.TextBox { Name = "Pass", Text = store.Password, q.Out("Text", store.Password) },
		D.TextButton {
			Name = "Submit", Text = "go", Interactable = form.CanSubmit, BackgroundColor3 = submitColor,
			MouseButton1Click = function()
				if not form.CanSubmit:Get() then return end
				form.Submitted:Set({ Username = store.Username:Get(), Password = store.Password:Get() })
			end,
		},
	}
	track("S1.formRoot", root)
	return root
end

local function child(inst, name) return inst:FindFirstChild(name) end

print("== S1a normal flow ==")
local form = makeFormState()
local ctx = q.Context():Set(ThemeProvider, { Accent = C3(0, 170, 255) })
local submits = {}
local screen = D.ScreenGui {
	RegistrationForm { Form = form, Ctx = ctx },
	form.Submitted:Observer(function(t)
		local p = t:Get()
		if p == nil then return end
		table.insert(submits, p.Username)
	end),
}
local root = screen:GetChildren()[1]
print("log", table.concat(log, " | ")); table.clear(log)
local user, pass, btn = child(root, "User"), child(root, "Pass"), child(root, "Submit")
print("initial Interactable", btn.Interactable, "UserErr.Visible", child(root, "UserErr").Visible, "color r", btn.BackgroundColor3.r)
user.Text = "ab"; H.run(0.1); user.Text = "abcd"; H.run(0.1); user.Text = "abcde"
print("store", form.Store.Username:Get(), "UserErr.Visible", child(root, "UserErr").Visible, "Avail", child(root, "Avail").Text)
H.run(0.31)
print("after debounce Avail", child(root, "Avail").Text, "log", table.concat(log, " | ")); table.clear(log)
pass.Text = "secret123"
print("canSubmit", form.CanSubmit:Get(), "Interactable", btn.Interactable, "color r", btn.BackgroundColor3.r)
btn.MouseButton1Click:Fire()
print("submits", table.concat(submits, ","))

print("== S1c re-entrancy: reset inside Submitted observer (writes back through Text binding + Out) ==")
local resetObs = form.Submitted:Observer(function(t)
	if t:Get() == nil then return end
	form.Store.Username:Set(""); form.Store.Password:Set("")
	form.Submitted:Set(nil)
end)
resetObs:Subscribe()
btn.MouseButton1Click:Fire() -- CanSubmit true still
print("after reset: store", "'" .. form.Store.Username:Get() .. "'", "TextBox", "'" .. user.Text .. "'", "submits", table.concat(submits, ","), "Submitted", tostring(form.Submitted:Get()))
print("Interactable", btn.Interactable, "UserErr.Visible", child(root, "UserErr").Visible)
H.run(0.31); print("debounce after reset log", table.concat(log, " | ")); table.clear(log)
resetObs:Unsubscribe()

print("== S1c2 re-entrancy: click handler destroys the form mid-handler, then Submitted fires ==")
do
	local f2 = makeFormState()
	local killed
	local host = D.Frame {}
	local r2 = RegistrationForm { Form = f2, Ctx = ctx }
	r2.Parent = host
	local b2 = child(r2, "Submit")
	f2.Store.Username:Set("abcd"); f2.Store.Password:Set("secret123")
	local obs = f2.Submitted:Observer(function(t)
		if t:Get() == nil then return end
		r2:Destroy() -- destroy the form (including the button whose handler is on the stack)
		killed = true
	end)
	obs:Subscribe()
	try("fire click that destroys", function() b2.MouseButton1Click:Fire() end)
	print("killed", killed, "log", table.concat(log, " | ")); table.clear(log)
	try("store write after destroy", function() f2.Store.Username:Set("zzzz") end)
	H.run(0.5)
	print("log after timers", table.concat(log, " | ")); table.clear(log)
	obs:Unsubscribe()
end

print("== S1d batch: Blocker over Username+Password reset while Debounce window is open ==")
do
	local blocker = q.Blocker()
	local f3 = makeFormState()
	local gated = f3.CanSubmit:Apply(blocker)
	local seen = {}
	local o = gated:Observer(function(t) table.insert(seen, tostring(t:Get())) end)
	local r3 = RegistrationForm { Form = f3, Ctx = ctx }
	o:Subscribe()
	f3.Store.Username:Set("abcd"); f3.Store.Password:Set("secret123")
	print("seen before", table.concat(seen, ","))
	f3.Store.Username:Set("abcde") -- opens debounce window
	blocker:On()
	f3.Store.Username:Set("x"); f3.Store.Password:Set("y")
	H.run(0.31) -- debounce expires INSIDE blocker window (timer callback runs user Observer)
	f3.Store.Username:Set("wxyz"); f3.Store.Password:Set("secret999")
	blocker:Off()
	print("seen", table.concat(seen, ","), "log", table.concat(log, " | ")); table.clear(log)
	print("Avail", child(r3, "Avail").Text)
	r3:Destroy(); o:Unsubscribe()
end

print("== S1b teardown: destroy screen, provider replace, pending debounce, leak count ==")
user.Text = "qqqqq" -- debounce pending
print("pending timers", H.pending())
ctx:Set(ThemeProvider, { Accent = C3(1, 2, 3) }) -- provider value replaced (built tree read it once)
print("color r after provider replace (read-once expected)", btn.BackgroundColor3.r)
screen:Destroy()
print("log", table.concat(log, " | ")); table.clear(log)
H.run(0.5)
print("after timer on dead tree log", table.concat(log, " | "), "Avail.Text", child(root, "Avail") and child(root, "Avail").Text)
try("store write after destroy", function() form.Store.Username:Set("after") end)
print("user.Text after (dead inst must not be written)", user.Text)
screen, root, user, pass, btn = nil, nil, nil, nil, nil
print("alive (form state still referenced):", alive("S1."))
form = nil
print("alive (form dropped):", alive("S1."))
