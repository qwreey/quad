--!strict
--[[
	Input widgets (Iris: InputText / InputNum / DragNum / SliderNum / InputVector2 / InputUDim2 / InputColor3).
	Every widget takes its value as a two-way `Source` (an internal one when omitted), `Disabled`, `Style` and a row
	`Modifier`, and returns one row Frame. See the header of each file. Internal helpers (NumberField, the root Common module) are not
	re-exported; NumberFormat is (pure number/colour text helpers).
]]

local InputText = require("@self/InputText")
local InputNum = require("@self/InputNum")
local DragNum = require("@self/DragNum")
local SliderNum = require("@self/SliderNum")
local InputVector = require("@self/InputVector")
local InputColor3 = require("@self/InputColor3")
local NumberFormat = require("@self/NumberFormat")

export type InputTextProps = InputText.InputTextProps
export type InputNumProps = InputNum.InputNumProps
export type DragNumProps = DragNum.DragNumProps
export type SliderNumProps = SliderNum.SliderNumProps
export type InputVector2Props = InputVector.InputVector2Props
export type InputUDim2Props = InputVector.InputUDim2Props
export type InputColor3Props = InputColor3.InputColor3Props

return {
	InputText = InputText,
	InputNum = InputNum,
	DragNum = DragNum,
	SliderNum = SliderNum,
	InputVector2 = InputVector.InputVector2,
	InputUDim2 = InputVector.InputUDim2,
	InputColor3 = InputColor3,
	NumberFormat = NumberFormat,
}
