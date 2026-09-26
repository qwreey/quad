-- 자기 하위 클래스마다 하나씩 생성된다. GuiObjectModifier라면:
AsFrame: (self: GuiObjectModifier) -> FrameModifier
AsTextLabel: (self: GuiObjectModifier) -> TextLabelModifier
-- … 그리고 항등 캐스트
AsGuiObject: (self: GuiObjectModifier) -> GuiObjectModifier
