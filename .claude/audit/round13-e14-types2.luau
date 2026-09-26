--!strict
-- round13 E14 type probe 2 — documented Modifier snippets under strict (GS 10, core/08, roblox/03, how-to 01/05)
local q = require("./round13-e14-types-settings")
local R = require("../../quad-roblox/src")
local QuadTypes = require("../../quad-roblox/luau_packages/quad_types")
local D = q.Declaration
local None = q.None

-- GS 10 §1–§4
local function _gs10()
	const CardStyle = D.Modifier.Frame {
		BackgroundColor3 = Color3.fromRGB(35, 35, 42),
		BorderSizePixel = 0,
	}
	const card = D.Frame { CardStyle, Size = UDim2.fromOffset(240, 160), UICorner = 12 }
	const hot = q.Source(false)
	const CardStyle2 = D.Modifier.Frame {
		BackgroundColor3 = hot:Compute(function(h)
			return if h:Get() then Color3.fromRGB(240, 60, 60) else Color3.fromRGB(35, 35, 42)
		end),
		BorderSizePixel = 0,
	}
	const base = D.Modifier.TextButton { TextSize = 16 }
	const big = base:TextSize(24)
	local function accent(color)
		return D.Modifier.TextButton {
			BackgroundColor3 = color,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
		}
	end
	const button = D.TextButton { accent(Color3.fromRGB(0, 162, 255)), Text = "+ 1" }
	const accentColor = q.Source(Color3.fromRGB(0, 162, 255))
	const button2 = D.TextButton { accent(accentColor), Text = "+ 1" }
	local function emphasis(size)
		return function(mod)
			return mod:TextSize(size):TextColor3(Color3.fromRGB(255, 230, 120))
		end
	end
	const title = D.Modifier.TextLabel { BackgroundTransparency = 1 }:Apply(emphasis(24))
	const label = D.TextLabel { title, Text = "카운터" }
	-- typo in table form (GS 10 shape) — does strict catch it?
	const typo = D.Modifier.Frame { BorderSizePixle = 0 } -- E?:G1
	return card, CardStyle2, big, button, button2, label, typo
end

-- core/08
type CardModifier = {
	read __quadModifier: "Card",
	Elevation: (self: CardModifier, value: number) -> CardModifier,
	Peek: <T>(self: CardModifier, key: string) -> QuadTypes.FieldOut<T>?,
	As: <T>(self: CardModifier, name: string?) -> T,
}
local function _core08()
	local scale = q.Source(1)
	local base = D.Modifier.Frame { BackgroundTransparency = 0.5, LayoutOrder = 1 }
	local dimmed = base:BackgroundTransparency(0.9)
	local live = base:LayoutOrder(scale)
	local cleared = base:BackgroundTransparency(q.None)
	local bumped = base:LayoutOrder(function(old) return (old :: number) + 1 end)
	local doubled = live:LayoutOrder(function(old)
		return (old :: q.StateData<number>):Get() * 2
	end)
	local function rounded(mod: any)
		return mod:BorderSizePixel(0):BackgroundTransparency(0.1)
	end
	local styled = q.Modifier():Apply(rounded)
	local Card = q.Modifier.TypedFactory<<CardModifier>>("Card")
	local raised = Card({ Elevation = 2 })
	local r2 = raised:Elevation(3)
	local onFrame = D.Frame { raised } -- E?:K1 custom tag onto Frame (plan: type rejects)
	local size = q.Source(UDim2.fromOffset(100, 40))
	local mod = q.Modifier { Size = size, Visible = true }
	local storedSize = mod:Peek<<UDim2>>("Size")
	local common = D.Modifier.GuiObject():Visible(true)
	local button = common:AsTextButton()
	local nilSetter = base:LayoutOrder(nil) -- E?:K2 documented nil arm
	local maybe: number? = nil
	local nilSetter2 = base:LayoutOrder(maybe) -- E?:K3 optional value
	return dimmed, cleared, bumped, doubled, styled, r2, onFrame, storedSize, button, nilSetter, nilSetter2
end

-- roblox/03
local function _r03()
	local forced: R.TextLabelModifier = D.Modifier.GuiObject():As<<R.TextLabelModifier>>()
	local retagged = D.Modifier.TextLabel():As("Frame")
	local onFrame = D.Frame { retagged } -- E?:X1 As(name) without T → unknown
	type ThemedProps = { read Modifier: R.IntoTextButton?, read Text: string? }
	local function Themed(props: ThemedProps): TextButton
		return D.TextButton({
			if props.Modifier then props.Modifier:AsTextButton() else q.None,
			Text = props.Text or "",
		})
	end
	Themed({ Modifier = D.Modifier.GuiObject():ZIndex(2), Text = "a" })
	Themed({ Modifier = D.Modifier.TextButton():TextSize(18) })
	local Boldify = function(mod: R.TextButtonModifier): R.TextButtonModifier
		return mod:TextSize(20)
	end
	local bold = D.Modifier.TextButton():Text("go"):Apply(Boldify)
	local boldWrong = D.Modifier.Frame():Apply(Boldify) -- E?:X2 annotated factory on wrong class
	return forced, onFrame, bold, boldWrong
end

-- how-to 01 / 05
local function _howto()
	type ButtonProps = {
		read Text: string | QuadTypes.StateMarker<string>,
		read OnClick: () -> (),
		read Modifier: R.TextButtonModifier?,
		read Ref: q.Ref<TextButton?>?,
	}
	local function CustomButton(props: ButtonProps): TextButton
		local baseStyle = D.Modifier.TextButton {
			Size = UDim2.fromOffset(140, 40),
			BackgroundColor3 = Color3.fromRGB(0, 140, 240),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
		}
		return D.TextButton {
			baseStyle,
			props.Modifier or None,
			props.Ref or None,
			Text = props.Text,
			MouseButton1Click = props.OnClick,
			UICorner = 8,
		}
	end
	local b2 = CustomButton {
		Text = "삭제",
		OnClick = function() end,
		Modifier = D.Modifier.TextButton {
			BackgroundColor3 = Color3.fromRGB(240, 60, 60),
			Size = UDim2.fromOffset(100, 36),
		},
	}
	local b3 = CustomButton { Text = "x", OnClick = function() end, Modifier = D.Modifier.GuiObject():ZIndex(2) } -- E:H1 ancestor into TextButtonModifier? param
	local Styles = { Button = D.Modifier.TextButton():Size(UDim2.new(0, 120, 0, 40)):BorderSizePixel(0) }
	local function ThemedButton(props: { read Text: string?, read OnClick: () -> (), read Modifier: R.IntoTextButton? })
		local effective = if props.Modifier
			then q.Modifier.Overridden(Styles.Button, props.Modifier:AsTextButton())
			else Styles.Button
		return D.TextButton {
			effective,
			Text = props.Text or "",
			Activated = function() props.OnClick() end,
		}
	end
	local t = ThemedButton { Text = "a", OnClick = function() end, Modifier = D.Modifier.TextButton():Position(UDim2.new(0, 20, 1, -60)) }
	return b2, b3, t
end

return { _gs10, _core08, _r03, _howto }
