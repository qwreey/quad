--!strict
--[[
	Style — the theme of the kit: reactive design tokens (State<Color3> / State<number> / ...) switchable at runtime.

	Values are taken from the Dear ImGui default dark/light palettes and the default/"clear" metrics as shipped by
	Iris (https://github.com/SirMallard/Iris, MIT (c) 2024 Michael_48 — this kit is inspired by it and copies no
	code, only the published colour/metric numbers so the LOOK matches).

	USAGE
		local Style = require("./Style")
		local s = Style.default                 -- or Style.new({ Scheme = "Light", Dark = { ButtonColor = Color3.new(1, 0, 0) } })
		s.Color.Button                          -- State<Color3>       (token names = Iris config names without the "Color" suffix)
		s.Transparency.Button                   -- State<number>
		s.Metrics.TextSize                      -- State<number>       (Iris "size" config names)
		s.FrameHeight                           -- State<number>       TextSize + 2 * FramePadding.Y
		s:SetScheme("Light")                    -- every widget bound to those tokens repaints
		s:SetDensity("Clear")                   -- "Default" (13px Code font, flat) or "Clear" (15px Ubuntu, rounded)
		s:ColorOf("Button") / s:AlphaOf("Button")   -- dynamic-name lookup (errors on an unknown token)
		Style.interactive(s, "Button", hovered, pressed)   -- { Color, Transparency }: base / base.."Hovered" / base.."Active"

	A widget takes an optional `props.Style` and falls back to `Style.default`:
		local style = props.Style or Style.default

	Tokens are created lazily on first access (one Compute node each) — a widget pays only for what it reads.
	Unknown overrides / token names raise (typo guard).
]]

local Quad = require("./Quad")
local Util = require("./Util")
local q = Quad
type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>

export type SchemeName = "Dark" | "Light"
export type DensityName = "Default" | "Clear"
export type MetricValue = UDim | Vector2 | number | Font | Enum.LeftRight

export type ColorTokens = {
	read Text: State<Color3>,
	read TextDisabled: State<Color3>,
	read Border: State<Color3>,
	read BorderActive: State<Color3>,
	read WindowBg: State<Color3>,
	read PopupBg: State<Color3>,
	read ScrollbarGrab: State<Color3>,
	read TitleBg: State<Color3>,
	read TitleBgActive: State<Color3>,
	read TitleBgCollapsed: State<Color3>,
	read MenubarBg: State<Color3>,
	read FrameBg: State<Color3>,
	read FrameBgHovered: State<Color3>,
	read FrameBgActive: State<Color3>,
	read Button: State<Color3>,
	read ButtonHovered: State<Color3>,
	read ButtonActive: State<Color3>,
	read Image: State<Color3>,
	read SliderGrab: State<Color3>,
	read SliderGrabActive: State<Color3>,
	read Header: State<Color3>,
	read HeaderHovered: State<Color3>,
	read HeaderActive: State<Color3>,
	read Tab: State<Color3>,
	read TabHovered: State<Color3>,
	read TabActive: State<Color3>,
	read SelectionImageObject: State<Color3>,
	read SelectionImageObjectBorder: State<Color3>,
	read TableBorderStrong: State<Color3>,
	read TableBorderLight: State<Color3>,
	read TableRowBg: State<Color3>,
	read TableRowBgAlt: State<Color3>,
	read TableHeader: State<Color3>,
	read NavWindowingHighlight: State<Color3>,
	read NavWindowingDimBg: State<Color3>,
	read Separator: State<Color3>,
	read CheckMark: State<Color3>,
	read PlotLines: State<Color3>,
	read PlotLinesHovered: State<Color3>,
	read PlotHistogram: State<Color3>,
	read PlotHistogramHovered: State<Color3>,
	read ResizeGrip: State<Color3>,
	read ResizeGripHovered: State<Color3>,
	read ResizeGripActive: State<Color3>,
}

export type TransparencyTokens = {
	read Text: State<number>,
	read TextDisabled: State<number>,
	read Border: State<number>,
	read BorderActive: State<number>,
	read WindowBg: State<number>,
	read PopupBg: State<number>,
	read ScrollbarGrab: State<number>,
	read TitleBg: State<number>,
	read TitleBgActive: State<number>,
	read TitleBgCollapsed: State<number>,
	read MenubarBg: State<number>,
	read FrameBg: State<number>,
	read FrameBgHovered: State<number>,
	read FrameBgActive: State<number>,
	read Button: State<number>,
	read ButtonHovered: State<number>,
	read ButtonActive: State<number>,
	read Image: State<number>,
	read SliderGrab: State<number>,
	read SliderGrabActive: State<number>,
	read Header: State<number>,
	read HeaderHovered: State<number>,
	read HeaderActive: State<number>,
	read Tab: State<number>,
	read TabHovered: State<number>,
	read TabActive: State<number>,
	read SelectionImageObject: State<number>,
	read SelectionImageObjectBorder: State<number>,
	read TableBorderStrong: State<number>,
	read TableBorderLight: State<number>,
	read TableRowBg: State<number>,
	read TableRowBgAlt: State<number>,
	read TableHeader: State<number>,
	read NavWindowingHighlight: State<number>,
	read NavWindowingDimBg: State<number>,
	read Separator: State<number>,
	read CheckMark: State<number>,
	read PlotLines: State<number>,
	read PlotLinesHovered: State<number>,
	read PlotHistogram: State<number>,
	read PlotHistogramHovered: State<number>,
	read ResizeGrip: State<number>,
	read ResizeGripHovered: State<number>,
	read ResizeGripActive: State<number>,
}

export type MetricTokens = {
	read ItemWidth: State<UDim>,
	read ContentWidth: State<UDim>,
	read ContentHeight: State<UDim>,
	read WindowPadding: State<Vector2>,
	read WindowResizePadding: State<Vector2>,
	read FramePadding: State<Vector2>,
	read ItemSpacing: State<Vector2>,
	read ItemInnerSpacing: State<Vector2>,
	read CellPadding: State<Vector2>,
	read DisplaySafeAreaPadding: State<Vector2>,
	read SeparatorTextPadding: State<Vector2>,
	read IndentSpacing: State<number>,
	read TextFont: State<Font>,
	read TextSize: State<number>,
	read FrameBorderSize: State<number>,
	read FrameRounding: State<number>,
	read GrabRounding: State<number>,
	read WindowRounding: State<number>,
	read WindowBorderSize: State<number>,
	read WindowTitleAlign: State<Enum.LeftRight>,
	read PopupBorderSize: State<number>,
	read PopupRounding: State<number>,
	read TabRounding: State<number>,
	read ScrollbarSize: State<number>,
	read GrabMinSize: State<number>,
	read SeparatorTextBorderSize: State<number>,
	read ImageBorderSize: State<number>,
}

export type Icons = {
	RightTriangle: string,
	DownTriangle: string,
	Close: string,
	ResizeGrip: string,
	CheckMark: string,
	BlankSquare: string,
}

export type Interactive = { Color: State<Color3>, Transparency: State<number> }

export type StyleOverrides = {
	Scheme: SchemeName?,
	Density: DensityName?,
	-- Iris-named overrides: "<Token>Color" -> Color3, "<Token>Transparency" -> number
	Dark: { [string]: Color3 | number }?,
	Light: { [string]: Color3 | number }?,
	-- metric overrides (Iris size names), applied to BOTH densities
	Metrics: { [string]: MetricValue }?,
	Icons: { [string]: string }?,
}

export type Style = {
	Scheme: Source<SchemeName>,
	Density: Source<DensityName>,
	Color: ColorTokens,
	Transparency: TransparencyTokens,
	Metrics: MetricTokens,
	Icons: Icons,
	FrameHeight: State<number>,
	SetScheme: (self: Style, name: SchemeName) -> (),
	SetDensity: (self: Style, name: DensityName) -> (),
	ColorOf: (self: Style, token: string) -> State<Color3>,
	AlphaOf: (self: Style, token: string) -> State<number>,
	MetricOf: (self: Style, token: string) -> State<MetricValue>,
	HasToken: (self: Style, token: string) -> boolean,
}

-- ── data ───────────────────────────────────────────────────────────────────

local DARK_COLORS: { [string]: Color3 } = {
	Text = Color3.fromRGB(255, 255, 255),
	TextDisabled = Color3.fromRGB(128, 128, 128),
	Border = Color3.fromRGB(110, 110, 125),
	BorderActive = Color3.fromRGB(160, 160, 175),
	WindowBg = Color3.fromRGB(15, 15, 15),
	PopupBg = Color3.fromRGB(20, 20, 20),
	ScrollbarGrab = Color3.fromRGB(79, 79, 79),
	TitleBg = Color3.fromRGB(10, 10, 10),
	TitleBgActive = Color3.fromRGB(41, 74, 122),
	TitleBgCollapsed = Color3.fromRGB(0, 0, 0),
	MenubarBg = Color3.fromRGB(36, 36, 36),
	FrameBg = Color3.fromRGB(41, 74, 122),
	FrameBgHovered = Color3.fromRGB(66, 150, 250),
	FrameBgActive = Color3.fromRGB(66, 150, 250),
	Button = Color3.fromRGB(66, 150, 250),
	ButtonHovered = Color3.fromRGB(66, 150, 250),
	ButtonActive = Color3.fromRGB(15, 135, 250),
	Image = Color3.fromRGB(255, 255, 255),
	SliderGrab = Color3.fromRGB(66, 150, 250),
	SliderGrabActive = Color3.fromRGB(66, 150, 250),
	Header = Color3.fromRGB(66, 150, 250),
	HeaderHovered = Color3.fromRGB(66, 150, 250),
	HeaderActive = Color3.fromRGB(66, 150, 250),
	Tab = Color3.fromRGB(46, 89, 148),
	TabHovered = Color3.fromRGB(66, 150, 250),
	TabActive = Color3.fromRGB(51, 105, 173),
	SelectionImageObject = Color3.fromRGB(255, 255, 255),
	SelectionImageObjectBorder = Color3.fromRGB(255, 255, 255),
	TableBorderStrong = Color3.fromRGB(79, 79, 89),
	TableBorderLight = Color3.fromRGB(59, 59, 64),
	TableRowBg = Color3.fromRGB(0, 0, 0),
	TableRowBgAlt = Color3.fromRGB(255, 255, 255),
	TableHeader = Color3.fromRGB(48, 48, 51),
	NavWindowingHighlight = Color3.fromRGB(255, 255, 255),
	NavWindowingDimBg = Color3.fromRGB(204, 204, 204),
	Separator = Color3.fromRGB(110, 110, 128),
	CheckMark = Color3.fromRGB(66, 150, 250),
	PlotLines = Color3.fromRGB(156, 156, 156),
	PlotLinesHovered = Color3.fromRGB(255, 110, 89),
	PlotHistogram = Color3.fromRGB(230, 179, 0),
	PlotHistogramHovered = Color3.fromRGB(255, 153, 0),
	ResizeGrip = Color3.fromRGB(66, 150, 250),
	ResizeGripHovered = Color3.fromRGB(66, 150, 250),
	ResizeGripActive = Color3.fromRGB(66, 150, 250),
}
local DARK_ALPHAS: { [string]: number } = {
	Text = 0,
	TextDisabled = 0,
	Border = 0.5,
	BorderActive = 0.3,
	WindowBg = 0.06,
	PopupBg = 0.06,
	ScrollbarGrab = 0,
	TitleBg = 0,
	TitleBgActive = 0,
	TitleBgCollapsed = 0.5,
	MenubarBg = 0,
	FrameBg = 0.46,
	FrameBgHovered = 0.46,
	FrameBgActive = 0.33,
	Button = 0.6,
	ButtonHovered = 0,
	ButtonActive = 0,
	Image = 0,
	SliderGrab = 0,
	SliderGrabActive = 0,
	Header = 0.69,
	HeaderHovered = 0.2,
	HeaderActive = 0,
	Tab = 0.14,
	TabHovered = 0.2,
	TabActive = 0,
	SelectionImageObject = 0.8,
	SelectionImageObjectBorder = 0,
	TableBorderStrong = 0,
	TableBorderLight = 0,
	TableRowBg = 1,
	TableRowBgAlt = 0.94,
	TableHeader = 0,
	NavWindowingHighlight = 0.3,
	NavWindowingDimBg = 0.65,
	Separator = 0.5,
	CheckMark = 0,
	PlotLines = 0,
	PlotLinesHovered = 0,
	PlotHistogram = 0,
	PlotHistogramHovered = 0,
	ResizeGrip = 0.8,
	ResizeGripHovered = 0.33,
	ResizeGripActive = 0.05,
}
local LIGHT_COLORS: { [string]: Color3 } = {
	Text = Color3.fromRGB(0, 0, 0),
	TextDisabled = Color3.fromRGB(153, 153, 153),
	Border = Color3.fromRGB(64, 64, 64),
	BorderActive = Color3.fromRGB(64, 64, 64),
	WindowBg = Color3.fromRGB(240, 240, 240),
	PopupBg = Color3.fromRGB(255, 255, 255),
	ScrollbarGrab = Color3.fromRGB(176, 176, 176),
	TitleBg = Color3.fromRGB(245, 245, 245),
	TitleBgActive = Color3.fromRGB(209, 209, 209),
	TitleBgCollapsed = Color3.fromRGB(255, 255, 255),
	MenubarBg = Color3.fromRGB(219, 219, 219),
	FrameBg = Color3.fromRGB(255, 255, 255),
	FrameBgHovered = Color3.fromRGB(66, 150, 250),
	FrameBgActive = Color3.fromRGB(66, 150, 250),
	Button = Color3.fromRGB(66, 150, 250),
	ButtonHovered = Color3.fromRGB(66, 150, 250),
	ButtonActive = Color3.fromRGB(15, 135, 250),
	Image = Color3.fromRGB(255, 255, 255),
	SliderGrab = Color3.fromRGB(61, 133, 224),
	SliderGrabActive = Color3.fromRGB(117, 138, 204),
	Header = Color3.fromRGB(66, 150, 250),
	HeaderHovered = Color3.fromRGB(66, 150, 250),
	HeaderActive = Color3.fromRGB(66, 150, 250),
	Tab = Color3.fromRGB(195, 203, 213),
	TabHovered = Color3.fromRGB(66, 150, 250),
	TabActive = Color3.fromRGB(152, 186, 255),
	SelectionImageObject = Color3.fromRGB(0, 0, 0),
	SelectionImageObjectBorder = Color3.fromRGB(0, 0, 0),
	TableBorderStrong = Color3.fromRGB(145, 145, 163),
	TableBorderLight = Color3.fromRGB(173, 173, 189),
	TableRowBg = Color3.fromRGB(0, 0, 0),
	TableRowBgAlt = Color3.fromRGB(77, 77, 77),
	TableHeader = Color3.fromRGB(199, 222, 250),
	NavWindowingHighlight = Color3.fromRGB(179, 179, 179),
	NavWindowingDimBg = Color3.fromRGB(51, 51, 51),
	Separator = Color3.fromRGB(99, 99, 99),
	CheckMark = Color3.fromRGB(66, 150, 250),
	PlotLines = Color3.fromRGB(99, 99, 99),
	PlotLinesHovered = Color3.fromRGB(255, 110, 89),
	PlotHistogram = Color3.fromRGB(230, 179, 0),
	PlotHistogramHovered = Color3.fromRGB(255, 153, 0),
	ResizeGrip = Color3.fromRGB(89, 89, 89),
	ResizeGripHovered = Color3.fromRGB(66, 150, 250),
	ResizeGripActive = Color3.fromRGB(66, 150, 250),
}
local LIGHT_ALPHAS: { [string]: number } = {
	Text = 0,
	TextDisabled = 0,
	Border = 0.5,
	BorderActive = 0.2,
	WindowBg = 0,
	PopupBg = 0.02,
	ScrollbarGrab = 0.2,
	TitleBg = 0,
	TitleBgActive = 0,
	TitleBgCollapsed = 0.5,
	MenubarBg = 0,
	FrameBg = 0.6,
	FrameBgHovered = 0.6,
	FrameBgActive = 0.33,
	Button = 0.6,
	ButtonHovered = 0,
	ButtonActive = 0,
	Image = 0,
	SliderGrab = 0,
	SliderGrabActive = 0,
	Header = 0.31,
	HeaderHovered = 0.2,
	HeaderActive = 0,
	Tab = 0.07,
	TabHovered = 0.2,
	TabActive = 0,
	SelectionImageObject = 0.8,
	SelectionImageObjectBorder = 0,
	TableBorderStrong = 0,
	TableBorderLight = 0,
	TableRowBg = 1,
	TableRowBgAlt = 0.91,
	TableHeader = 0,
	NavWindowingHighlight = 0.3,
	NavWindowingDimBg = 0.8,
	Separator = 0.38,
	CheckMark = 0,
	PlotLines = 0,
	PlotLinesHovered = 0,
	PlotHistogram = 0,
	PlotHistogramHovered = 0,
	ResizeGrip = 0.83,
	ResizeGripHovered = 0.33,
	ResizeGripActive = 0.05,
}

local DEFAULT_METRICS: { [string]: MetricValue } = {
	ItemWidth = UDim.new(1, 0),
	ContentWidth = UDim.new(0.65, 0),
	ContentHeight = UDim.new(0, 0),
	WindowPadding = Vector2.new(8, 8),
	WindowResizePadding = Vector2.new(6, 6),
	FramePadding = Vector2.new(4, 3),
	ItemSpacing = Vector2.new(8, 4),
	ItemInnerSpacing = Vector2.new(4, 4),
	CellPadding = Vector2.new(4, 2),
	DisplaySafeAreaPadding = Vector2.new(0, 0),
	SeparatorTextPadding = Vector2.new(20, 3),
	IndentSpacing = 21,
	TextFont = Font.fromEnum(Enum.Font.Code),
	TextSize = 13,
	FrameBorderSize = 0,
	FrameRounding = 0,
	TabRounding = 0, -- [2026-10-20] tab buttons (ImGui TabRounding); same as FrameRounding
	GrabRounding = 0,
	WindowRounding = 0,
	WindowBorderSize = 1,
	WindowTitleAlign = Enum.LeftRight.Left,
	PopupBorderSize = 1,
	PopupRounding = 0,
	ScrollbarSize = 7,
	GrabMinSize = 10,
	SeparatorTextBorderSize = 3,
	ImageBorderSize = 2,
}

local CLEAR_METRICS: { [string]: MetricValue } = {
	ItemWidth = UDim.new(1, 0),
	ContentWidth = UDim.new(0.65, 0),
	ContentHeight = UDim.new(0, 0),
	WindowPadding = Vector2.new(12, 8),
	WindowResizePadding = Vector2.new(8, 8),
	FramePadding = Vector2.new(6, 4),
	ItemSpacing = Vector2.new(8, 8),
	ItemInnerSpacing = Vector2.new(8, 8),
	CellPadding = Vector2.new(4, 4),
	DisplaySafeAreaPadding = Vector2.new(8, 8),
	SeparatorTextPadding = Vector2.new(24, 6),
	IndentSpacing = 25,
	TextFont = Font.fromEnum(Enum.Font.Ubuntu),
	TextSize = 15,
	FrameBorderSize = 1,
	FrameRounding = 4,
	TabRounding = 4, -- [2026-10-20] tab buttons (ImGui TabRounding); same as FrameRounding
	GrabRounding = 4,
	WindowRounding = 4,
	WindowBorderSize = 1,
	WindowTitleAlign = Enum.LeftRight.Center,
	PopupBorderSize = 1,
	PopupRounding = 4,
	ScrollbarSize = 9,
	GrabMinSize = 14,
	SeparatorTextBorderSize = 4,
	ImageBorderSize = 4,
}

local DEFAULT_ICONS: Icons = {
	RightTriangle = "rbxassetid://105541346271951",
	DownTriangle = "rbxassetid://95465797476827",
	Close = "rbxassetid://133890060015237",
	ResizeGrip = "rbxassetid://125737344915000",
	CheckMark = "rbxassetid://109638815494221",
	BlankSquare = "rbxassetid://83265623867126",
}

-- ── helpers ────────────────────────────────────────────────────────────────

local function copyMap<V>(src: { [string]: V }): { [string]: V }
	local out: { [string]: V } = {}
	for k, v in src do
		out[k] = v
	end
	return out
end

-- Lazy token table: `tokens.Name` derives (and caches) one State per name; unknown names raise.
local function lazyTokens(isValid: (key: string) -> boolean, what: string, derive: (key: string) -> unknown): any
	local cache: { [string]: unknown } = {}
	local mt = {
		__index = function(t, key: any)
			if type(key) ~= "string" or not isValid(key) then
				Util.fail("Style", `unknown {what} token "{tostring(key)}"`)
			end
			local v = derive(key)
			rawset(t, key, v)
			return v
		end,
	}
	Util.tagSurface(mt) -- the reading line (`style.Color.Nope`) is blamed, not this metamethod
	return setmetatable(cache, mt)
end

local function applyPaletteOverrides(
	colors: { [string]: Color3 },
	alphas: { [string]: number },
	overrides: { [string]: Color3 | number }?,
	scheme: string
)
	if overrides == nil then
		return
	end
	for key, value in overrides do
		local isColor = string.sub(key, -5) == "Color"
		if not isColor and string.sub(key, -12) ~= "Transparency" then
			Util.fail("Style.new", `{scheme} override "{key}" must end in "Color" or "Transparency"`)
		end
		local name = string.sub(key, 1, if isColor then -6 else -13)
		if colors[name] == nil then
			Util.fail("Style.new", `{scheme} override "{key}" names an unknown token "{name}"`)
		end
		if isColor then
			if typeof(value) ~= "Color3" then
				Util.fail("Style.new", `{scheme} override "{key}" must be a Color3`)
			end
			colors[name] = value :: Color3
		else
			if type(value) ~= "number" then
				Util.fail("Style.new", `{scheme} override "{key}" must be a number`)
			end
			alphas[name] = value :: number
		end
	end
end

local Style = {}

function Style.new(overrides: StyleOverrides?): Style
	local o: StyleOverrides = overrides or {}

	local dark, darkA = copyMap(DARK_COLORS), copyMap(DARK_ALPHAS)
	local light, lightA = copyMap(LIGHT_COLORS), copyMap(LIGHT_ALPHAS)
	applyPaletteOverrides(dark, darkA, o.Dark, "Dark")
	applyPaletteOverrides(light, lightA, o.Light, "Light")

	local defaultMetrics, clearMetrics = copyMap(DEFAULT_METRICS), copyMap(CLEAR_METRICS)
	if o.Metrics then
		for key, value in o.Metrics do
			if DEFAULT_METRICS[key] == nil then
				Util.fail("Style.new", `unknown metric "{key}"`)
			end
			defaultMetrics[key] = value
			clearMetrics[key] = value
		end
	end

	local icons: { [string]: string } = {}
	for key, value in DEFAULT_ICONS :: { [string]: string } do
		icons[key] = value
	end
	if o.Icons then
		for key, value in o.Icons do
			if icons[key] == nil then
				Util.fail("Style.new", `unknown icon "{key}"`)
			end
			icons[key] = value
		end
	end

	local scheme: Source<SchemeName> = q.Source((o.Scheme or "Dark") :: SchemeName)
	local density: Source<DensityName> = q.Source((o.Density or "Default") :: DensityName)

	local colorsNow: State<{ [string]: Color3 }> = scheme:Compute(function(self)
		return if self:Get() == "Dark" then dark else light
	end)
	local alphasNow: State<{ [string]: number }> = scheme:Compute(function(self)
		return if self:Get() == "Dark" then darkA else lightA
	end)
	local metricsNow: State<{ [string]: MetricValue }> = density:Compute(function(self)
		return if self:Get() == "Default" then defaultMetrics else clearMetrics
	end)

	local colorTokens: any = lazyTokens(function(key)
		return DARK_COLORS[key] ~= nil
	end, "colour", function(key)
		local s: State<Color3> = colorsNow:Compute(function(self)
			return self:Get()[key]
		end)
		return s
	end)
	local alphaTokens: any = lazyTokens(function(key)
		return DARK_ALPHAS[key] ~= nil
	end, "transparency", function(key)
		local s: State<number> = alphasNow:Compute(function(self)
			return self:Get()[key]
		end)
		return s
	end)
	local metricTokens: any = lazyTokens(function(key)
		return DEFAULT_METRICS[key] ~= nil
	end, "metric", function(key)
		local s: State<MetricValue> = metricsNow:Compute(function(self)
			return self:Get()[key]
		end)
		return s
	end)

	local style: Style
	style = {
		Scheme = scheme,
		Density = density,
		Color = colorTokens,
		Transparency = alphaTokens,
		Metrics = metricTokens,
		Icons = icons :: any,
		FrameHeight = (nil :: any) :: State<number>,
		SetScheme = function(_self: Style, name: SchemeName)
			if name ~= "Dark" and name ~= "Light" then
				Util.fail("Style:SetScheme", `expected "Dark" or "Light" (got {tostring(name)})`)
			end
			scheme:SetIfChanged(name)
		end,
		SetDensity = function(_self: Style, name: DensityName)
			if name ~= "Default" and name ~= "Clear" then
				Util.fail("Style:SetDensity", `expected "Default" or "Clear" (got {tostring(name)})`)
			end
			density:SetIfChanged(name)
		end,
		ColorOf = function(self: Style, token: string): State<Color3>
			return (self.Color :: any)[token]
		end,
		AlphaOf = function(self: Style, token: string): State<number>
			return (self.Transparency :: any)[token]
		end,
		MetricOf = function(self: Style, token: string): State<MetricValue>
			return (self.Metrics :: any)[token]
		end,
		HasToken = function(_self: Style, token: string): boolean
			return DARK_COLORS[token] ~= nil
		end,
	}
	local frameHeight: State<number> = metricTokens.TextSize:Compute(function(self, _prev, padding)
		return (self:Get() :: number) + 2 * (padding:Get() :: Vector2).Y
	end, metricTokens.FramePadding)
	style.FrameHeight = frameHeight
	Util.tagSurface(style) -- `:SetScheme` & co. are public surface (a usage error blames the caller)
	return style
end

-- Hover/active colouring shared by every Dear-ImGui-style widget: `base`, `base.."Hovered"`, `base.."Active"`
-- (a missing variant falls back to the base token). `hovered`/`pressed` come from Interaction.hover().
function Style.interactive(style: Style, base: string, hovered: State<boolean>, pressed: State<boolean>): Interactive
	local function variant(suffix: string): string
		local name = base .. suffix
		return if style:HasToken(name) then name else base
	end
	local color: State<Color3> = hovered:Compute(function(self, _prev, isPressed, normal, hover, active)
		if isPressed:Get() then
			return active:Get()
		elseif self:Get() then
			return hover:Get()
		end
		return normal:Get()
	end, pressed, style:ColorOf(base), style:ColorOf(variant("Hovered")), style:ColorOf(variant("Active")))
	local alpha: State<number> = hovered:Compute(function(self, _prev, isPressed, normal, hover, active)
		if isPressed:Get() then
			return active:Get()
		elseif self:Get() then
			return hover:Get()
		end
		return normal:Get()
	end, pressed, style:AlphaOf(base), style:AlphaOf(variant("Hovered")), style:AlphaOf(variant("Active")))
	return { Color = color, Transparency = alpha }
end

Style.default = Style.new()

return Style
