--!strict
--[[
	Gallery section "Selection": Checkbox (plain, tri-state parent, error, disabled), Radio / RadioGroup, Switch (plain,
	icons, disabled), Slider (continuous, discrete with ticks, formatted, disabled). Every control is bound to a Source in
	the Memo and a caption reads it back, so a click is visibly a round trip (Source in -> UI -> user input -> Source out).
]]

local q = require("../Quad")
local Common = require("./Common")
local Checkbox = require("../Checkbox")
local RadioModule = require("../Radio")
local Switch = require("../Switch")
local Slider = require("../Slider")

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
		Common.Labeled(ctx, Checkbox({ Theme = theme, Value = agreed }), "Checked"),
		Common.Labeled(ctx, Checkbox({ Theme = theme, Value = plain }), "Unchecked"),
		Common.Labeled(ctx, Checkbox({ Theme = theme, Value = erroring, Error = true }), "Error"),
		Common.Labeled(ctx, Checkbox({ Theme = theme, Value = q.Source(true), Disabled = true }), "Disabled, checked"),
		Common.Labeled(ctx, Checkbox({ Theme = theme, Value = q.Source(false), Disabled = true }), "Disabled"),
	}
	local triState: { Instance } = {
		Common.Labeled(
			ctx,
			Checkbox({
				Theme = theme,
				Value = parent,
				Indeterminate = mixed,
				OnChange = function(v)
					childA:Set(v)
					childB:Set(v)
				end,
			}),
			"Both"
		),
		Common.Labeled(ctx, Checkbox({ Theme = theme, Value = childA, OnChange = syncParent }), "First"),
		Common.Labeled(ctx, Checkbox({ Theme = theme, Value = childB, OnChange = syncParent }), "Second"),
	}

	-- radios
	local fruit = ctx.Memo("sel.fruit", function()
		return q.Source("pear")
	end)
	local size = ctx.Memo("sel.size", function()
		return q.Source("m")
	end)
	local radios: { Instance } = {
		RadioModule.RadioGroup({
			Theme = theme,
			Value = fruit,
			Options = {
				{ Option = "apple", Label = "Apple" },
				{ Option = "pear", Label = "Pear" },
				{ Option = "plum", Label = "Plum (disabled)", Disabled = true },
			},
		}),
		RadioModule.RadioGroup({
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
		Common.Labeled(ctx, RadioModule.Radio({ Theme = theme, Value = q.Source("a"), Option = "a", Disabled = true }), "Disabled, selected"),
	}

	-- switches
	local wifi = ctx.Memo("sel.wifi", function()
		return q.Source(true)
	end)
	local sound = ctx.Memo("sel.sound", function()
		return q.Source(false)
	end)
	local switches: { Instance } = {
		Common.Labeled(ctx, Switch({ Theme = theme, Value = wifi }), "Plain"),
		Common.Labeled(ctx, Switch({ Theme = theme, Value = sound, IconOn = ctx.Icon, IconOff = ctx.Icon }), "With icons"),
		Common.Labeled(ctx, Switch({ Theme = theme, Value = q.Source(true), Disabled = true }), "Disabled, on"),
		Common.Labeled(ctx, Switch({ Theme = theme, Value = q.Source(false), Disabled = true }), "Disabled, off"),
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
			Slider({ Theme = theme, Value = volume, Min = 0, Max = 100 }),
			readout<<number>>(ctx, "Continuous: ", volume, function(v: number)
				return string.format("%.1f", v)
			end),
			Slider({ Theme = theme, Value = level, Min = 0, Max = 10, Step = 1 }),
			readout<<number>>(ctx, "Discrete (ticks): ", level, show),
			Slider({
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
			Slider({ Theme = theme, Value = q.Source(60), Min = 0, Max = 100, Disabled = true }),
		}, 320, 8),
	}

	return Common.Section(ctx, "Selection", "Selection controls", {
		Common.Group(ctx, "Checkbox", checkboxes),
		Common.Group(ctx, "Checkbox: tri-state parent", triState, "The parent shows the dash while the children differ; a click sets both children."),
		Common.Group(ctx, "Radio / RadioGroup", radios),
		Common.Group(ctx, "Switch", switches),
		Common.Group(ctx, "Slider", sliders, "Drag, or focus and use the arrow keys / D-pad. The label bubble appears while dragging."),
		Common.Group(ctx, "Current values", {
			readout<<boolean>>(ctx, "Checked: ", agreed, show),
			readout<<string>>(ctx, "Fruit: ", fruit, show),
			readout<<string>>(ctx, "Size: ", size, show),
			readout<<boolean>>(ctx, "Wi-Fi: ", wifi, show),
		}),
	})
end
