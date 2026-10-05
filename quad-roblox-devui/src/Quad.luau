--!strict
--[[
	The kit's setup module — the same shape the quad docs recommend for a game (getting-started/01-setup):
	install the Roblox provider once on the shared quad-base singleton and re-export the types the kit uses.
	`UseProvider` is idempotent for the same provider, so a game that already ran its own setup module on the
	SAME install copy shares this instance (States mix freely between the game and the kit).

	These three requires are the ONLY place that knows where quad lives. In-repo they point at the
	workspace copies the quad-roblox specs use; a consumer project replaces them with its package paths
	(e.g. `@game/ReplicatedStorage/Packages/quad_base`).
]]

local Quad = require("../../quad-roblox/luau_packages/quad_base")
local RobloxModule = require("../../quad-roblox/src")
local QuadTypes = require("../../quad-roblox/luau_packages/quad_types")

local q = Quad:UseProvider(RobloxModule.QuadRoblox)

-- core value types (quad-types)
export type State<T> = QuadTypes.State<T>
export type Source<T> = QuadTypes.Source<T>
export type StateData<T> = QuadTypes.StateData<T>
export type Slot<T> = QuadTypes.Slot<T>
export type SlotItem<T> = QuadTypes.SlotItem<T>
export type Ref<T> = QuadTypes.Ref<T>
export type PreRef<T> = QuadTypes.PreRef<T>
export type PostRef<T> = QuadTypes.PostRef<T>
export type Observer = QuadTypes.Observer
export type Effect = QuadTypes.Effect
export type Store<T> = QuadTypes.Store<T>
export type Context = QuadTypes.Context
export type Provider<T> = QuadTypes.Provider<T>
export type KeyGone = QuadTypes.KeyGone

-- generated Declaration types (quad-roblox module root — the only public path to them)
export type Field<T> = RobloxModule.Field<T>
export type FieldOut<T> = RobloxModule.FieldOut<T>
export type Tween<T> = RobloxModule.Tween<T>
export type TweenOptions<T> = RobloxModule.TweenOptions<T>
export type AnimateInfo = RobloxModule.AnimateInfo
export type OnChangeFn = RobloxModule.OnChangeFn
export type GuiObjectModifier = RobloxModule.GuiObjectModifier
export type IntoGuiObject = RobloxModule.IntoGuiObject
export type GuiButtonModifier = RobloxModule.GuiButtonModifier
export type IntoGuiButton = RobloxModule.IntoGuiButton
export type FrameModifier = RobloxModule.FrameModifier
export type IntoFrame = RobloxModule.IntoFrame
export type TextLabelModifier = RobloxModule.TextLabelModifier
export type IntoTextLabel = RobloxModule.IntoTextLabel
export type TextButtonModifier = RobloxModule.TextButtonModifier
export type IntoTextButton = RobloxModule.IntoTextButton
export type TextBoxModifier = RobloxModule.TextBoxModifier
export type IntoTextBox = RobloxModule.IntoTextBox
export type ImageLabelModifier = RobloxModule.ImageLabelModifier
export type IntoImageLabel = RobloxModule.IntoImageLabel
export type ImageButtonModifier = RobloxModule.ImageButtonModifier
export type IntoImageButton = RobloxModule.IntoImageButton
export type ScrollingFrameModifier = RobloxModule.ScrollingFrameModifier
export type IntoScrollingFrame = RobloxModule.IntoScrollingFrame
export type CanvasGroupModifier = RobloxModule.CanvasGroupModifier
export type IntoCanvasGroup = RobloxModule.IntoCanvasGroup
export type ScreenGuiModifier = RobloxModule.ScreenGuiModifier
export type IntoScreenGui = RobloxModule.IntoScreenGui

return q
