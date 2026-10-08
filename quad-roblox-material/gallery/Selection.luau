--!strict
--[[
	Gallery section "Selection": first the "Slider / Switch — M3 vs M2" comparison (two columns, the M3 default and the
	`Material.M2` look side by side; each pair shares ONE Source, so moving either moves both — the behaviour is shared,
	only the drawing differs), then "Slider variants" (the M3 configurations M2 does not have: the five sizes XS..XL on
	one Source, centered sliders, inset icons, vertical sliders — Min at the bottom, TopToBottom, centered, a range),
	then Checkbox (plain, tri-state parent, error, disabled), Radio / RadioGroup, Switch (plain,
	icons, disabled), Slider (continuous, discrete with ticks, formatted, disabled), RangeSlider (continuous, discrete,
	disabled). Every control is bound to a Source in the Memo and a caption reads it back, so a click is visibly a round
	trip (Source in -> UI -> user input -> Source out).
]]

local q = require("./Quad")
local Common = require("./Common")
local Material = require("../src")
local D = q.Declaration

type Ctx = Common.Ctx

local function readout<T>(ctx: Ctx, prefix: string, source: q.State<T>, fmt: (T) -> string): TextLabel
	return Common.Caption(ctx, Common.text<<T>>(source, function(v: T)
		return prefix .. fmt(v)
	end), false)
end

local function show(v: any): string
	return tostring(v)
end

return function(ctx: Ctx): Instance
	local theme = ctx.Theme

	-- checkboxes
	local agreed = ctx.Memo("sel.agreed", function()
		return q.Source(true)
	end)
	local plain = ctx.Memo("sel.plain", function()
		return q.Source(false)
	end)
	local erroring = ctx.Memo("sel.error", function()
		return q.Source(false)
	end)
	local childA = ctx.Memo("sel.childA", function()
		return q.Source(true)
	end)
	local childB = ctx.Memo("sel.childB", function()
		return q.Source(false)
	end)
	local parent = ctx.Memo("sel.parent", function()
		return q.Source(false)
	end)
	local mixed: q.State<boolean> = childA:Compute(function(self, _prev, b)
		return self:Get() ~= b:Get()
	end, childB)
	local function syncParent()
		parent:Set(childA:Get() and childB:Get())
	end

	local checkboxes: { Instance } = {
		-- `Label`: the text belongs to the checkbox (hover / click on it act on the box — HTML label-for)
		Material.Checkbox({ Theme = theme, Value = agreed, Label = "Checked" }),
		Material.Checkbox({ Theme = theme, Value = plain, Label = "Unchecked" }),
		Material.Checkbox({ Theme = theme, Value = erroring, Error = true, Label = "Error" }),
		Material.Checkbox({ Theme = theme, Value = q.Source(true), Disabled = true, Label = "Disabled, checked" }),
		Material.Checkbox({ Theme = theme, Value = q.Source(false), Disabled = true, Label = "Disabled" }),
	}
	local triState: { Instance } = {
		Material.Checkbox({
			Theme = theme,
			Value = parent,
			Indeterminate = mixed,
			Label = "Both",
			OnChange = function(v)
				childA:Set(v)
				childB:Set(v)
			end,
		}),
		Material.Checkbox({ Theme = theme, Value = childA, OnChange = syncParent, Label = "First" }),
		Material.Checkbox({ Theme = theme, Value = childB, OnChange = syncParent, Label = "Second" }),
	}

	-- radios
	local fruit = ctx.Memo("sel.fruit", function()
		return q.Source("pear")
	end)
	local size = ctx.Memo("sel.size", function()
		return q.Source("m")
	end)
	local radios: { Instance } = {
		Material.RadioGroup({
			Theme = theme,
			Value = fruit,
			Options = {
				{ Option = "apple", Label = "Apple" },
				{ Option = "pear", Label = "Pear" },
				{ Option = "plum", Label = "Plum (disabled)", Disabled = true },
			},
		}),
		Material.RadioGroup({
			Theme = theme,
			Value = size,
			Direction = "Horizontal",
			Error = true,
			Options = {
				{ Option = "s", Label = "S" },
				{ Option = "m", Label = "M" },
				{ Option = "l", Label = "L" },
			},
		}),
		Material.Radio({ Theme = theme, Value = q.Source("a"), Option = "a", Disabled = true, Label = "Disabled, selected" }),
	}

	-- switches
	local wifi = ctx.Memo("sel.wifi", function()
		return q.Source(true)
	end)
	local sound = ctx.Memo("sel.sound", function()
		return q.Source(false)
	end)
	local switches: { Instance } = {
		Common.Labeled(ctx, Material.Switch({ Theme = theme, Value = wifi }), "Plain"),
		Common.Labeled(ctx, Material.Switch({ Theme = theme, Value = sound, IconOn = ctx.Icon, IconOff = ctx.Icon }), "With icons"),
		Common.Labeled(ctx, Material.Switch({ Theme = theme, Value = q.Source(true), Disabled = true }), "Disabled, on"),
		Common.Labeled(ctx, Material.Switch({ Theme = theme, Value = q.Source(false), Disabled = true }), "Disabled, off"),
	}

	-- sliders
	local volume = ctx.Memo("sel.volume", function()
		return q.Source(30)
	end)
	local level = ctx.Memo("sel.level", function()
		return q.Source(4)
	end)
	local percent = ctx.Memo("sel.percent", function()
		return q.Source(0.5)
	end)
	local sliders: { Instance } = {
		Common.Column({
			Material.Slider({ Theme = theme, Value = volume, Min = 0, Max = 100 }),
			readout<<number>>(ctx, "Continuous: ", volume, function(v: number)
				return string.format("%.1f", v)
			end),
			Material.Slider({ Theme = theme, Value = level, Min = 0, Max = 10, Step = 1 }),
			readout<<number>>(ctx, "Discrete (ticks): ", level, show),
			Material.Slider({
				Theme = theme,
				Value = percent,
				Min = 0,
				Max = 1,
				Format = function(v: number)
					return string.format("%d%%", math.floor(v * 100 + 0.5))
				end,
			}),
			readout<<number>>(ctx, "Formatted label: ", percent, function(v: number)
				return string.format("%.2f", v)
			end),
			Material.Slider({ Theme = theme, Value = q.Source(60), Min = 0, Max = 100, Disabled = true }),
		}, 320, 8),
	}

	-- range sliders
	local rangeLo = ctx.Memo("sel.rangeLo", function()
		return q.Source(20)
	end)
	local rangeHi = ctx.Memo("sel.rangeHi", function()
		return q.Source(70)
	end)
	local stepLo = ctx.Memo("sel.stepLo", function()
		return q.Source(2)
	end)
	local stepHi = ctx.Memo("sel.stepHi", function()
		return q.Source(6)
	end)
	local function pair(lo: q.State<number>, hi: q.State<number>, fmt: string): q.State<string>
		return lo:Compute(function(self, _prev, h)
			return string.format(fmt, self:Get(), h:Get())
		end, hi)
	end
	local rangeSliders: { Instance } = {
		Common.Column({
			Material.RangeSlider({ Theme = theme, Start = rangeLo, End = rangeHi, Min = 0, Max = 100 }),
			readout<<string>>(ctx, "Continuous: ", pair(rangeLo, rangeHi, "%.1f .. %.1f"), show),
			Material.RangeSlider({ Theme = theme, Start = stepLo, End = stepHi, Min = 0, Max = 10, Step = 1 }),
			readout<<string>>(ctx, "Discrete (ticks): ", pair(stepLo, stepHi, "%d .. %d"), show),
			Material.RangeSlider({ Theme = theme, Start = q.Source(30), End = q.Source(60), Min = 0, Max = 100, Disabled = true }),
		}, 320, 8),
	}

	-- M3 vs M2: one Source per pair, two columns
	local cmpVolume = ctx.Memo("cmp.volume", function()
		return q.Source(40)
	end)
	local cmpLevel = ctx.Memo("cmp.level", function()
		return q.Source(3)
	end)
	local cmpLo = ctx.Memo("cmp.lo", function()
		return q.Source(25)
	end)
	local cmpHi = ctx.Memo("cmp.hi", function()
		return q.Source(70)
	end)
	local cmpStepLo = ctx.Memo("cmp.stepLo", function()
		return q.Source(2)
	end)
	local cmpStepHi = ctx.Memo("cmp.stepHi", function()
		return q.Source(7)
	end)
	local cmpOn = ctx.Memo("cmp.on", function()
		return q.Source(true)
	end)
	type Looks = { Slider: typeof(Material.Slider), RangeSlider: typeof(Material.RangeSlider), Switch: typeof(Material.Switch) }
	local function column(title: string, L: Looks): Frame
		return Common.Column({
			Common.Caption(ctx, title, false),
			L.Slider({ Theme = theme, Value = cmpVolume, Min = 0, Max = 100 }),
			L.Slider({ Theme = theme, Value = cmpLevel, Min = 0, Max = 10, Step = 1 }),
			L.Slider({ Theme = theme, Value = q.Source(60), Min = 0, Max = 100, Disabled = true }),
			L.RangeSlider({ Theme = theme, Start = cmpLo, End = cmpHi, Min = 0, Max = 100 }),
			L.RangeSlider({ Theme = theme, Start = cmpStepLo, End = cmpStepHi, Min = 0, Max = 10, Step = 1 }),
			L.RangeSlider({ Theme = theme, Start = q.Source(30), End = q.Source(60), Min = 0, Max = 100, Disabled = true }),
			Common.Flow({
				Common.Labeled(ctx, L.Switch({ Theme = theme, Value = cmpOn }), "Drag or tap"),
				Common.Labeled(ctx, L.Switch({ Theme = theme, Value = q.Source(true), Disabled = true }), "Disabled"),
			}),
		}, 300, 16)
	end
	-- M3 slider variants (sizes, centered, inset icons, vertical)
	local sized = ctx.Memo("var.sized", function()
		return q.Source(60)
	end)
	local pan = ctx.Memo("var.pan", function()
		return q.Source(20)
	end)
	local panStep = ctx.Memo("var.panStep", function()
		return q.Source(-20)
	end)
	local loud = ctx.Memo("var.loud", function()
		return q.Source(50)
	end)
	local vUp = ctx.Memo("var.vUp", function()
		return q.Source(30)
	end)
	local vDown = ctx.Memo("var.vDown", function()
		return q.Source(30)
	end)
	local vPan = ctx.Memo("var.vPan", function()
		return q.Source(-10)
	end)
	local vLo = ctx.Memo("var.vLo", function()
		return q.Source(20)
	end)
	local vHi = ctx.Memo("var.vHi", function()
		return q.Source(70)
	end)
	type SizeName = "XS" | "S" | "M" | "L" | "XL"
	local sizeRows: { Instance } = {}
	for _, name in { "XS", "S", "M", "L", "XL" } :: { SizeName } do
		table.insert(sizeRows, Common.Caption(ctx, name, false))
		table.insert(sizeRows, Material.Slider({ Theme = theme, Value = sized, Min = 0, Max = 100, Size = name }))
	end
	-- a vertical slider in a fixed box: room on the left for the value label
	local function tall(caption: string, control: Instance): Frame
		return Common.Column({
			Common.Caption(ctx, caption, false),
			D.Frame {
				Name = "Tall",
				Size = UDim2.fromOffset(120, 200),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				control,
			},
		}, 120, 4)
	end
	local function vModifier(width: number): q.FrameModifier
		return D.Modifier.Frame():Position(UDim2.fromOffset(120 - width, 0)):Size(UDim2.fromOffset(width, 200))
	end
	local variants: { Instance } = {
		Common.Column(sizeRows, 320, 8),
		Common.Column({
			Common.Caption(ctx, "Centered (Min -50, Max 50)", false),
			Material.Slider({ Theme = theme, Value = pan, Min = -50, Max = 50, Centered = true }),
			readout<<number>>(ctx, "Centered: ", pan, function(v: number)
				return string.format("%.1f", v)
			end),
			Material.Slider({ Theme = theme, Value = panStep, Min = -50, Max = 50, Step = 10, Centered = true }),
			readout<<number>>(ctx, "Centered, Step 10: ", panStep, show),
			Common.Caption(ctx, "Inset icons (L: active start / inactive end)", false),
			Material.Slider({
				Theme = theme,
				Value = loud,
				Min = 0,
				Max = 100,
				Size = "L",
				TrackIconActiveStart = "check",
				TrackIconInactiveEnd = "close",
			}),
			Material.Slider({ Theme = theme, Value = loud, Min = 0, Max = 100, Size = "M", TrackIconActiveStart = "\u{266A}", Disabled = true }),
		}, 320, 8),
		Common.Flow({
			tall("Vertical", Material.Slider({ Theme = theme, Value = vUp, Min = 0, Max = 100, Orientation = "Vertical", Modifier = vModifier(44) })),
			tall(
				"TopToBottom",
				Material.Slider({ Theme = theme, Value = vDown, Min = 0, Max = 100, Orientation = "Vertical", TopToBottom = true, Modifier = vModifier(44) })
			),
			tall(
				"Centered, M",
				Material.Slider({ Theme = theme, Value = vPan, Min = -50, Max = 50, Orientation = "Vertical", Centered = true, Size = "M", Modifier = vModifier(44) })
			),
			tall(
				"Range, S",
				Material.RangeSlider({ Theme = theme, Start = vLo, End = vHi, Min = 0, Max = 100, Orientation = "Vertical", Size = "S", Modifier = vModifier(44) })
			),
		}, 8),
	}

	local comparison: { Instance } = {
		column("M3 (Material.Slider / RangeSlider / Switch)", { Slider = Material.Slider, RangeSlider = Material.RangeSlider, Switch = Material.Switch }),
		column("M2 (Material.M2.*)", { Slider = Material.M2.Slider, RangeSlider = Material.M2.RangeSlider, Switch = Material.M2.Switch }),
	}

	return Common.Section(ctx, "Selection", "Selection controls", {
		Common.Group(
			ctx,
			"Slider / Switch — M3 vs M2",
			comparison,
			"Same props, same behaviour, two looks; each row pair shares one value (move either). Rows: continuous, discrete (ticks), disabled; range continuous, discrete, disabled; switches — drag the handle past the half or tap."
		),
		Common.Group(
			ctx,
			"Slider variants (M3)",
			variants,
			"Sizes XS / S / M / L / XL share one value. Centered: the active track runs from the middle. Inset icons (M and up): hidden when their track piece gets shorter than icon + 20. Vertical: Min at the bottom (TopToBottom flips it), Up / Down keys; the label shows on the left."
		),
		Common.Group(ctx, "Checkbox", checkboxes),
		Common.Group(ctx, "Checkbox: tri-state parent", triState, "The parent shows the dash while the children differ; a click sets both children."),
		Common.Group(ctx, "Radio / RadioGroup", radios),
		Common.Group(ctx, "Switch", switches),
		Common.Group(ctx, "Slider", sliders, "Drag, or focus and use the arrow keys / D-pad. The label bubble appears while dragging."),
		Common.Group(
			ctx,
			"Range slider",
			rangeSliders,
			"Two handles: a press grabs the nearest. Keys move one handle; Return / gamepad X switches to the other."
		),
		Common.Group(ctx, "Current values", {
			readout<<boolean>>(ctx, "Checked: ", agreed, show),
			readout<<string>>(ctx, "Fruit: ", fruit, show),
			readout<<string>>(ctx, "Size: ", size, show),
			readout<<boolean>>(ctx, "Wi-Fi: ", wifi, show),
			readout<<number>>(ctx, "M3/M2 volume: ", cmpVolume, function(v: number)
				return string.format("%.1f", v)
			end),
			readout<<boolean>>(ctx, "M3/M2 switch: ", cmpOn, show),
		}),
	})
end
