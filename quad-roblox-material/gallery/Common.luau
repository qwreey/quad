--!strict
--[[
	Gallery helpers shared by the section files: the context every section receives, plus the small layout
	pieces (a titled group of components that wraps like a flow row, a caption, a fixed-width column).

	Ctx (built once by `Gallery.GalleryPanel`):
	  Theme     the Theme every demo component gets (`Theme.default` unless the host passes one)
	  Overlay   the overlay layer for menus / dialogs / tooltips / selects — owned by the panel (or by the ScreenGui
	            `Gallery.mount` creates); components get it explicitly, never `Overlay.default()`
	  Snackbar  the Snackbar host bound to that Overlay
	  Icon      placeholder icon asset id for the icon demos (`props.Icon` of the panel overrides it)
	  Memo      `Memo(key, make)`: values (Sources) that must survive a section being left and re-entered. Sections are
	            built lazily when their tab is selected and destroyed when it is left, so anything the user typed
	            or toggled lives in the Memo, not in the section function's locals.

	Layout notes: every container uses `SortOrder = LayoutOrder` (UIListLayout's default is Name) and
	`AutomaticSize = Y`, so a section is as tall as its content and the ScrollingFrame's AutomaticCanvasSize
	follows it. A group's children are held in a `Slot` (the quad boundary form for a list of children).
]]

local q = require("./Quad")
local Material = require("../src")
local D = q.Declaration

export type Ctx = {
	read Theme: Material.Theme,
	read Overlay: Material.OverlayType,
	read Snackbar: Material.SnackbarHost,
	read Memo: <T>(key: string, make: () -> T) -> T,
	read Icon: string, -- the image asset id used wherever a demo needs an icon (the kit ships none)
}

local function newMemo(): <T>(key: string, make: () -> T) -> T
	local cache: { [string]: any } = {}
	return function<T>(key: string, make: () -> T): T
		local v = cache[key]
		if v == nil then
			v = make()
			cache[key] = v
		end
		return v :: T
	end
end

local Common = {}
Common.newMemo = newMemo

local titleStyle = Material.Text.Label("TitleSmall")
local captionStyle = Material.Text.Label("BodySmall")
local bodyStyle = Material.Text.Label("BodyMedium")
local headingStyle = Material.Text.Label("TitleLarge")

-- `State<T>` -> `State<string>` through `fn` (the annotated local is what lets strict infer the Compute callback).
function Common.text<T>(source: q.State<T>, fn: (value: T) -> string): q.State<string>
	local out: q.State<string> = source:Compute(function(self)
		return fn(self:Get())
	end)
	return out
end

-- Small OnSurfaceVariant text: full width and wrapped by default; `wrap = false` shrink-wraps it (one line, sits
-- beside controls in a flow row and works inside a shrink-wrapping Card).
function Common.Caption(ctx: Ctx, text: string | q.State<string>, wrap: boolean?): TextLabel
	return D.TextLabel {
		Name = "Caption",
		captionStyle,
		Size = if wrap == false then UDim2.fromOffset(0, 0) else UDim2.fromScale(1, 0),
		AutomaticSize = if wrap == false then Enum.AutomaticSize.XY else Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = wrap ~= false,
		TextColor3 = ctx.Theme.Color.OnSurfaceVariant,
		Text = text,
	}
end

-- A control with a text label to its right (Checkbox / Radio / Switch have none of their own).
function Common.Labeled(ctx: Ctx, control: Instance, text: string | q.State<string>): Frame
	return D.Frame {
		Name = "Labeled",
		Size = UDim2.fromOffset(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		D.UIListLayout {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 4),
		},
		control,
		D.TextLabel {
			Name = "Label",
			bodyStyle,
			Size = UDim2.fromOffset(0, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			TextColor3 = ctx.Theme.Color.OnSurface,
			Text = text,
		},
	}
end

-- A flow row: its children wrap onto new lines at the available width.
function Common.Flow(children: { Instance }, gap: number?): Frame
	return D.Frame {
		Name = "Flow",
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		D.UIListLayout {
			FillDirection = Enum.FillDirection.Horizontal,
			Wraps = true,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, gap or 12),
		},
		q.Slot<<Instance>>(children),
	}
end

-- A vertical stack with a fixed width (text fields and sliders want a width; the host stack shrink-wraps its height).
function Common.Column(children: { Instance }, width: number?, gap: number?): Frame
	return D.Frame {
		Name = "Column",
		Size = if width then UDim2.fromOffset(width, 0) else UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		D.UIListLayout {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, gap or 12),
		},
		q.Slot<<Instance>>(children),
	}
end

-- A titled group: title (TitleSmall, primary) + optional note + a flow row of the components.
function Common.Group(ctx: Ctx, title: string, children: { Instance }, note: string?): Frame
	local parts: { Instance } = {
		D.TextLabel {
			Name = "GroupTitle",
			titleStyle,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = ctx.Theme.Color.Primary,
			Text = title,
		},
	}
	if note then
		table.insert(parts, Common.Caption(ctx, note))
	end
	table.insert(parts, Common.Flow(children))
	return D.Frame {
		Name = "Group",
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		D.UIListLayout {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		},
		q.Slot<<Instance>>(parts),
	}
end

-- A section: a heading and the groups under it, 16 px inset, 24 px between groups.
function Common.Section(ctx: Ctx, name: string, heading: string, groups: { Instance }): Frame
	local parts: { Instance } = {
		D.TextLabel {
			Name = "Heading",
			headingStyle,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = ctx.Theme.Color.OnSurface,
			Text = heading,
		},
	}
	for _, g in groups do
		table.insert(parts, g)
	end
	return D.Frame {
		Name = name,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		UIPaddingOffset = 16,
		D.UIListLayout {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 24),
		},
		q.Slot<<Instance>>(parts),
	}
end

return Common
