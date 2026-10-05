--!strict
--[[
	Light / Dark palettes of the Classic color picker — the original's `HSVColorPicker.Themes`, same keys and
	values (the two themes differ only in the four text/background keys). A caller may pass its own table of
	this shape as `Theme`. Themes are static (plain values, not States): the original could not switch theme
	at runtime either.
]]

export type Theme = {
	Name: string,
	EditLabelTextColor: Color3,
	EditBoxTextColor: Color3,
	EditorBoxUnderbarColor: Color3,
	EditBoxSizeY: number,
	TitleFramePaddingBottom: number,
	TitleFrameSizeY: number,
	TitleTextColor: Color3,
	CloseButtonBackgroundColor: Color3,
	WindowBackgroundColor: Color3,
	ShadowSizeBottom: number,
	CancelButtonShadowColor: Color3,
	CancelButtonTextColor: Color3,
	CancelButtonColor: Color3,
	SelectButtonColor: Color3,
	SelectButtonShadowColor: Color3,
	SelectButtonTextColor: Color3,
	PreviewShadowColor: Color3,
	ButtonDimColor: Color3,
	CancelButtonText: string,
	SelectButtonText: string,
	ButtonDimTransparencyOn: number,
	ButtonDimTransparencyHover: number,
	ButtonDimTransparencyOff: number,
}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local function make(name: string, labelText: Color3, boxText: Color3, titleText: Color3, window: Color3): Theme
	return {
		Name = name,
		EditLabelTextColor = labelText,
		EditBoxTextColor = boxText,
		EditorBoxUnderbarColor = rgb(106, 0, 255),
		EditBoxSizeY = 24,
		TitleFramePaddingBottom = 4,
		TitleFrameSizeY = 8,
		TitleTextColor = titleText,
		CloseButtonBackgroundColor = rgb(255, 77, 61),
		WindowBackgroundColor = window,
		ShadowSizeBottom = 50,
		CancelButtonShadowColor = rgb(125, 119, 170),
		CancelButtonTextColor = rgb(0, 0, 0),
		CancelButtonColor = rgb(234, 211, 255),
		SelectButtonColor = rgb(106, 0, 255),
		SelectButtonShadowColor = rgb(33, 0, 115),
		SelectButtonTextColor = rgb(255, 255, 255),
		PreviewShadowColor = rgb(112, 112, 112),
		ButtonDimColor = rgb(0, 0, 0),
		CancelButtonText = "Cancel",
		SelectButtonText = "Select",
		ButtonDimTransparencyOn = 0.68,
		ButtonDimTransparencyHover = 0.8,
		ButtonDimTransparencyOff = 1,
	}
end

local Themes = {
	Light = make("Light", rgb(0, 0, 0), rgb(64, 64, 64), rgb(0, 0, 0), rgb(255, 255, 255)),
	Dark = make("Dark", rgb(255, 255, 255), rgb(200, 200, 200), rgb(255, 255, 255), rgb(41, 41, 41)),
}

export type ThemeInput = "Light" | "Dark" | Theme

local function resolve(input: ThemeInput?): Theme
	if input == nil then
		return Themes.Light
	elseif input == "Light" then
		return Themes.Light
	elseif input == "Dark" then
		return Themes.Dark
	end
	return input
end

return {
	Light = Themes.Light,
	Dark = Themes.Dark,
	resolve = resolve,
}
