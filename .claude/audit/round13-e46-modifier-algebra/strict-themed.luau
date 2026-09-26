--!strict
-- roblox/03:243-253 Themed with the :As("TextButton") replacement roblox/03:266 recommends
local q = require("./s10-config")
local R = require("../../../quad-roblox/src")
local D = q.Declaration
type ThemedProps = { read Modifier: R.IntoTextButton?, read Text: string? }
local function Themed(props: ThemedProps): TextButton
	return D.TextButton({
		if props.Modifier then props.Modifier:As("TextButton") else q.None, -- L9 recommended unchecked form
		Text = props.Text or "",
	})
end
local function Themed2(props: ThemedProps): TextButton
	return D.TextButton({
		if props.Modifier then props.Modifier:AsTextButton() else q.None, -- L15 original
		Text = props.Text or "",
	})
end
local _ = Themed; local _ = Themed2
