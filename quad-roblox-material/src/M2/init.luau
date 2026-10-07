--!strict
--[[
	`Material.M2` — Material 2 looks of components whose default (`Material.X`) is the M3 look. Same props and the same
	behaviour as the default: each pair shares one behaviour module and only the drawing differs.

	    Material.M2.Slider({ Value = v, Min = 0, Max = 100 })        -- thin track + round handle (../Slider/Behavior.luau)
	    Material.M2.RangeSlider({ Start = lo, End = hi })             -- two round handles          (../Slider/Behavior.luau)
	    Material.M2.Switch({ Value = on })                            -- thin track + overhanging thumb (../Switch/Behavior.luau)

	  Slider        `./Slider.luau`        (+ `./SliderTicks.luau`)
	  RangeSlider   `./RangeSlider.luau`
	  Switch        `./Switch.luau`
	Not a theme switch: pick the look per call site. There is no `Style = "M2"` prop on purpose — the M3 components
	carry no M2 branch.
]]

local Slider = require("@self/Slider")
local RangeSlider = require("@self/RangeSlider")
local Switch = require("@self/Switch")

export type SliderProps = Slider.Props
export type RangeSliderProps = RangeSlider.Props
export type SwitchProps = Switch.Props

return {
	Slider = Slider,
	RangeSlider = RangeSlider,
	Switch = Switch,
}
