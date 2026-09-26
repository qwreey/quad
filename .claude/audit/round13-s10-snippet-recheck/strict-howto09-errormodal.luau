--!strict
local q = require("./s10-config")
local D = q.Declaration

local function ErrorModal(props: {
	read Error: q.State<any>,
	read OnReport: (err: any) -> (),
	read OnConfirm: () -> (),
}): Frame
	local visible: q.State<boolean> = props.Error:Compute(function(e)
		return e:Get() ~= nil
	end)
	local text: q.State<string> = props.Error:Compute(function(e)
		local value = e:Get()
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
print(ErrorModal)
