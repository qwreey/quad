--!strict
--[[
	TextField supporting row: the supporting text (swapped for `ErrorText` while in the error state) and, with `MaxLength`,
	the `n/max` counter as a child on the right. 20 px high, BodySmall.
]]

local q = require("../Quad")
local Util = require("../Util")
local Text = require("../Text")
local Ctx = require("./Ctx")
local D = q.Declaration

local SupportHeight = 20
local bodySmall = Text.Label("BodySmall")

local function charCount(s: string): number
	return utf8.len(s) or #s
end

-- nil when the field has no supporting text, error text or counter
local function build(c: Ctx.Ctx): Instance?
	local props = c.Props
	local maxLength = c.MaxLength
	if not (props.SupportingText ~= nil or props.ErrorText ~= nil or maxLength ~= nil) then
		return nil
	end
	local errText = Util.asStringState(props.ErrorText)
	local supText = Util.asStringState(props.SupportingText)
	local supportText: q.State<string> = c.Error:Compute(function(self, _prev, e, s)
		if self:Get() and #e:Get() > 0 then
			return e:Get()
		end
		return s:Get()
	end, errText, supText)
	local counter: Instance? = nil
	if maxLength ~= nil then
		local max = maxLength
		local counterText: q.State<string> = c.Value:Compute(function(self)
			return `{charCount(self:Get())}/{max}`
		end)
		counter = D.TextLabel {
			Name = "Counter",
			bodySmall,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = counterText,
			TextColor3 = c.Colors.Support,
			TextTransparency = c.ContentTransparency,
			TextXAlignment = Enum.TextXAlignment.Right,
		}
	end
	return D.TextLabel {
		Name = "Supporting",
		bodySmall,
		Size = UDim2.new(1, 0, 0, SupportHeight),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = supportText,
		TextColor3 = c.Colors.Support,
		TextTransparency = c.ContentTransparency,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		LayoutOrder = 2,
		D.UIPadding {
			PaddingLeft = UDim.new(0, 16),
			PaddingRight = UDim.new(0, 16),
			PaddingTop = UDim.new(0, 4),
		},
		counter or q.None,
	}
end

return { build = build }
