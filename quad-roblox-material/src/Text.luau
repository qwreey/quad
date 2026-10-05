--!strict
--[[
	Text style modifiers from the M3 type scale. Each returns a reusable `Modifier` (immutable — safe to keep
	in a module-level local) carrying FontFace (Roboto), TextSize and LineHeight for one type role. Color is
	NOT included (it comes from the theme role the component uses).

	    D.TextLabel { Text = "Hello", Text_.Label("BodyLarge"), TextColor3 = theme.Color.OnSurface }
	  Text.Label(role)   -> D.Modifier.TextLabel()    for TextLabel
	  Text.Button(role)  -> D.Modifier.TextButton()   for TextButton
	  Text.Box(role)     -> D.Modifier.TextBox()      for TextBox
	`role` is a `Tokens.Typography` role name ("LabelLarge", "BodyMedium", ...). `family` (optional) replaces
	the Roboto family (`Typography.FallbackFamily` is the documented fallback).
	Roblox `LineHeight` is a multiplier, so the spec line height (e.g. 20 px at 14 px) becomes 20/14.
]]

local q = require("./Quad")
local Typography = require("./Tokens/Typography")
local D = q.Declaration

export type Role = Typography.Role

local function Label(role: Role, family: string?)
	local e = Typography.Scale[role]
	return D.Modifier.TextLabel():FontFace(Typography.font(role, family)):TextSize(e.Size):LineHeight(Typography.lineHeightScale(role))
end

local function Button(role: Role, family: string?)
	local e = Typography.Scale[role]
	return D.Modifier.TextButton():FontFace(Typography.font(role, family)):TextSize(e.Size):LineHeight(Typography.lineHeightScale(role))
end

local function Box(role: Role, family: string?)
	local e = Typography.Scale[role]
	return D.Modifier.TextBox():FontFace(Typography.font(role, family)):TextSize(e.Size):LineHeight(Typography.lineHeightScale(role))
end

return {
	Label = Label,
	Button = Button,
	Box = Box,
}
