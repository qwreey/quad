--!strict
local L = require("../../../../src/Lib")
type ClassMap = { Frame: Frame, GuiObject: GuiObject, ImageLabel: ImageLabel, ScrollingFrame: ScrollingFrame, TextButton: TextButton, TextLabel: TextLabel, UICorner: UICorner, UIListLayout: UIListLayout, UIPadding: UIPadding }
local Elem = (nil :: any) :: <K>(name: K & keyof<ClassMap>) -> (L.Props<index<ClassMap, K>>) -> index<ClassMap, K>
local Modifier = (nil :: any) :: <K>(name: K & keyof<ClassMap>) -> (...any) -> L.Modifier<index<ClassMap, K>>
local Frame = Elem "Frame"
local TextLabel = Elem "TextLabel"
local TextButton = Elem "TextButton"
local ImageLabel = Elem "ImageLabel"
local UICorner = Elem "UICorner"
local UIListLayout = Elem "UIListLayout"
local UIPadding = Elem "UIPadding"
local ScrollingFrame = Elem "ScrollingFrame"
local GuiObjectModifier = Modifier "GuiObject"
local FrameModifier = Modifier "Frame"
local TextButtonModifier = Modifier "TextButton"
local TextLabelModifier = Modifier "TextLabel"
return { Frame = Frame, TextLabel = TextLabel, TextButton = TextButton, ImageLabel = ImageLabel, UICorner = UICorner, UIListLayout = UIListLayout, UIPadding = UIPadding, ScrollingFrame = ScrollingFrame, GuiObjectModifier = GuiObjectModifier, FrameModifier = FrameModifier, TextButtonModifier = TextButtonModifier, TextLabelModifier = TextLabelModifier }
