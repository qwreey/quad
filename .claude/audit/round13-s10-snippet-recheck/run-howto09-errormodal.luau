--!nocheck
local H = require("./harness")
local q, D = H.q, H.D

local function ErrorModal(props)
	local visible = props.Error:Compute(function(e)
		return e:Get() ~= nil
	end)
	local text = props.Error:Compute(function(e)
		local value = e:Get()
		return if value == nil then "" else tostring(value)
	end)

	return D.Frame {
		Visible = visible,
		D.TextLabel { Text = text },
		D.TextButton {
			Text = "신고",
			Activated = function() props.OnReport(props.Error:Get()) end,
		},
		D.TextButton {
			Text = "확인",
			Activated = function() props.OnConfirm() end,
		},
	}
end

local errorState = q.Source(nil :: any)
local reported, confirmed = nil, false

local modal = ErrorModal {
	Error = errorState,
	OnReport = function(err) reported = err end,
	OnConfirm = function() confirmed = true end,
}

local label, reportBtn, confirmBtn
for _, c in modal:GetChildren() do
	if c.ClassName == "TextLabel" then label = c end
	if c.ClassName == "TextButton" and c.Text == "신고" then reportBtn = c end
	if c.ClassName == "TextButton" and c.Text == "확인" then confirmBtn = c end
end

print("visible before error:", modal.Visible, "text:", label.Text)
errorState:Set("boom")
print("visible after error:", modal.Visible, "text:", label.Text)
reportBtn.Activated:Fire()
print("reported:", reported)
confirmBtn.Activated:Fire()
print("confirmed:", confirmed)
