---@class quad_module_round
local round = {}

local outlineImage = "http://www.roblox.com/asset/?id=4668565547"
local outlineScaleType = Enum.ScaleType.Slice
local outlineSliceCenter = Rect.new(Vector2.new(516,516),Vector2.new(516,516))
local outlineSliceScale = 0.00208

local roundImage = "http://www.roblox.com/asset/?id=4668069300"
local roundScaleType = Enum.ScaleType.Slice
local roundSliceCenter = Rect.new(Vector2.new(516,516),Vector2.new(516,516))
local roundSliceScale = 0.0019166666666667

game:GetService('ContentProvider'):PreloadAsync({roundImage,outlineImage})

function round.SetRound(ImageFrame,RoundSize)
	ImageFrame.Image = roundImage
	ImageFrame.ScaleType = roundScaleType
	ImageFrame.SliceCenter = roundSliceCenter
	ImageFrame.SliceScale = roundSliceScale * RoundSize
	return ImageFrame
end
function round.SetOutline(ImageFrame,RoundSize)
	ImageFrame.Image = outlineImage
	ImageFrame.ScaleType = outlineScaleType
	ImageFrame.SliceCenter = outlineSliceCenter
	ImageFrame.SliceScale = outlineSliceScale * RoundSize
	return ImageFrame
end
function round.GetRound(ImageFrame)
	return ImageFrame.SliceScale / roundSliceScale
end
function round.GetOutline(ImageFrame)
	return ImageFrame.SliceScale / outlineSliceScale
end

return round
