--!strict
-- [2026-10-16] accumulating Spread: the marker gains `:Add(props)` (Modifier-like value) — placement / completion / cost
local L = require("../../../src/Lib")
type ClassMap = { BillboardGui: BillboardGui, Camera: Camera, CanvasGroup: CanvasGroup, Folder: Folder, Frame: Frame, ImageButton: ImageButton, ImageLabel: ImageLabel, ScreenGui: ScreenGui, ScrollingFrame: ScrollingFrame, SurfaceGui: SurfaceGui, TextBox: TextBox, TextButton: TextButton, TextLabel: TextLabel, UIAspectRatioConstraint: UIAspectRatioConstraint, UICorner: UICorner, UIDragDetector: UIDragDetector, UIFlexItem: UIFlexItem, UIGradient: UIGradient, UIGridLayout: UIGridLayout, UIListLayout: UIListLayout, UIPadding: UIPadding, UIPageLayout: UIPageLayout, UIScale: UIScale, UIShadow: UIShadow, UISizeConstraint: UISizeConstraint, UIStroke: UIStroke, UITableLayout: UITableLayout, UITextSizeConstraint: UITextSizeConstraint, VideoFrame: VideoFrame, ViewportFrame: ViewportFrame, WorldModel: WorldModel, GuiObject: GuiObject, GuiButton: GuiButton, GuiBase2d: GuiBase2d }
local NewN = (nil :: any) :: <K>(name: K & keyof<ClassMap>) -> (L.Props<index<ClassMap, K>>) -> index<ClassMap, K>
type SpreadAcc<K, C> = { read __quadSpread: K, Add: (self: SpreadAcc<K, C>, props: L.Props<C>) -> SpreadAcc<K, C> }
local SpreadA = (nil :: any) :: <K>(name: K & keyof<ClassMap>) -> (L.Props<index<ClassMap, K>>) -> SpreadAcc<K, index<ClassMap, K>>
local Frame = NewN "Frame"
local TextButton = NewN "TextButton"
local GuiSpread = SpreadA "GuiObject"
local FrameSpread = SpreadA "Frame"
local s0 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.1 }
local e0 = Frame { s0, Size = UDim2.new() }
local s1 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.2 }
local e1 = Frame { s1, Size = UDim2.new() }
local s2 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.3 }
local e2 = Frame { s2, Size = UDim2.new() }
local s3 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.4 }
local e3 = Frame { s3, Size = UDim2.new() }
local s4 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.5 }
local e4 = Frame { s4, Size = UDim2.new() }
local s5 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.6 }
local e5 = Frame { s5, Size = UDim2.new() }
local s6 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.7 }
local e6 = Frame { s6, Size = UDim2.new() }
local s7 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.8 }
local e7 = Frame { s7, Size = UDim2.new() }
local s8 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.9 }
local e8 = Frame { s8, Size = UDim2.new() }
local s9 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.1 }
local e9 = Frame { s9, Size = UDim2.new() }
local s10 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.2 }
local e10 = Frame { s10, Size = UDim2.new() }
local s11 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.3 }
local e11 = Frame { s11, Size = UDim2.new() }
local s12 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.4 }
local e12 = Frame { s12, Size = UDim2.new() }
local s13 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.5 }
local e13 = Frame { s13, Size = UDim2.new() }
local s14 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.6 }
local e14 = Frame { s14, Size = UDim2.new() }
local s15 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.7 }
local e15 = Frame { s15, Size = UDim2.new() }
local s16 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.8 }
local e16 = Frame { s16, Size = UDim2.new() }
local s17 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.9 }
local e17 = Frame { s17, Size = UDim2.new() }
local s18 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.1 }
local e18 = Frame { s18, Size = UDim2.new() }
local s19 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.2 }
local e19 = Frame { s19, Size = UDim2.new() }
local s20 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.3 }
local e20 = Frame { s20, Size = UDim2.new() }
local s21 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.4 }
local e21 = Frame { s21, Size = UDim2.new() }
local s22 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.5 }
local e22 = Frame { s22, Size = UDim2.new() }
local s23 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.6 }
local e23 = Frame { s23, Size = UDim2.new() }
local s24 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.7 }
local e24 = Frame { s24, Size = UDim2.new() }
local s25 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.8 }
local e25 = Frame { s25, Size = UDim2.new() }
local s26 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.9 }
local e26 = Frame { s26, Size = UDim2.new() }
local s27 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.1 }
local e27 = Frame { s27, Size = UDim2.new() }
local s28 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.2 }
local e28 = Frame { s28, Size = UDim2.new() }
local s29 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.3 }
local e29 = Frame { s29, Size = UDim2.new() }
local s30 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.4 }
local e30 = Frame { s30, Size = UDim2.new() }
local s31 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.5 }
local e31 = Frame { s31, Size = UDim2.new() }
local s32 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.6 }
local e32 = Frame { s32, Size = UDim2.new() }
local s33 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.7 }
local e33 = Frame { s33, Size = UDim2.new() }
local s34 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.8 }
local e34 = Frame { s34, Size = UDim2.new() }
local s35 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.9 }
local e35 = Frame { s35, Size = UDim2.new() }
local s36 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.1 }
local e36 = Frame { s36, Size = UDim2.new() }
local s37 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.2 }
local e37 = Frame { s37, Size = UDim2.new() }
local s38 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.3 }
local e38 = Frame { s38, Size = UDim2.new() }
local s39 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.4 }
local e39 = Frame { s39, Size = UDim2.new() }
local s40 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.5 }
local e40 = Frame { s40, Size = UDim2.new() }
local s41 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.6 }
local e41 = Frame { s41, Size = UDim2.new() }
local s42 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.7 }
local e42 = Frame { s42, Size = UDim2.new() }
local s43 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.8 }
local e43 = Frame { s43, Size = UDim2.new() }
local s44 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.9 }
local e44 = Frame { s44, Size = UDim2.new() }
local s45 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.1 }
local e45 = Frame { s45, Size = UDim2.new() }
local s46 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.2 }
local e46 = Frame { s46, Size = UDim2.new() }
local s47 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.3 }
local e47 = Frame { s47, Size = UDim2.new() }
local s48 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.4 }
local e48 = Frame { s48, Size = UDim2.new() }
local s49 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.5 }
local e49 = Frame { s49, Size = UDim2.new() }
local s50 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.6 }
local e50 = Frame { s50, Size = UDim2.new() }
local s51 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.7 }
local e51 = Frame { s51, Size = UDim2.new() }
local s52 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.8 }
local e52 = Frame { s52, Size = UDim2.new() }
local s53 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.9 }
local e53 = Frame { s53, Size = UDim2.new() }
local s54 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.1 }
local e54 = Frame { s54, Size = UDim2.new() }
local s55 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.2 }
local e55 = Frame { s55, Size = UDim2.new() }
local s56 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.3 }
local e56 = Frame { s56, Size = UDim2.new() }
local s57 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.4 }
local e57 = Frame { s57, Size = UDim2.new() }
local s58 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.5 }
local e58 = Frame { s58, Size = UDim2.new() }
local s59 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.6 }
local e59 = Frame { s59, Size = UDim2.new() }
local s60 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.7 }
local e60 = Frame { s60, Size = UDim2.new() }
local s61 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.8 }
local e61 = Frame { s61, Size = UDim2.new() }
local s62 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.9 }
local e62 = Frame { s62, Size = UDim2.new() }
local s63 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.1 }
local e63 = Frame { s63, Size = UDim2.new() }
local s64 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.2 }
local e64 = Frame { s64, Size = UDim2.new() }
local s65 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.3 }
local e65 = Frame { s65, Size = UDim2.new() }
local s66 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.4 }
local e66 = Frame { s66, Size = UDim2.new() }
local s67 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.5 }
local e67 = Frame { s67, Size = UDim2.new() }
local s68 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.6 }
local e68 = Frame { s68, Size = UDim2.new() }
local s69 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.7 }
local e69 = Frame { s69, Size = UDim2.new() }
local s70 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.8 }
local e70 = Frame { s70, Size = UDim2.new() }
local s71 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.9 }
local e71 = Frame { s71, Size = UDim2.new() }
local s72 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.1 }
local e72 = Frame { s72, Size = UDim2.new() }
local s73 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.2 }
local e73 = Frame { s73, Size = UDim2.new() }
local s74 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.3 }
local e74 = Frame { s74, Size = UDim2.new() }
local s75 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.4 }
local e75 = Frame { s75, Size = UDim2.new() }
local s76 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.5 }
local e76 = Frame { s76, Size = UDim2.new() }
local s77 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.6 }
local e77 = Frame { s77, Size = UDim2.new() }
local s78 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.7 }
local e78 = Frame { s78, Size = UDim2.new() }
local s79 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.8 }
local e79 = Frame { s79, Size = UDim2.new() }
local s80 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.9 }
local e80 = Frame { s80, Size = UDim2.new() }
local s81 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.1 }
local e81 = Frame { s81, Size = UDim2.new() }
local s82 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.2 }
local e82 = Frame { s82, Size = UDim2.new() }
local s83 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.3 }
local e83 = Frame { s83, Size = UDim2.new() }
local s84 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.4 }
local e84 = Frame { s84, Size = UDim2.new() }
local s85 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.5 }
local e85 = Frame { s85, Size = UDim2.new() }
local s86 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.6 }
local e86 = Frame { s86, Size = UDim2.new() }
local s87 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.7 }
local e87 = Frame { s87, Size = UDim2.new() }
local s88 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.8 }
local e88 = Frame { s88, Size = UDim2.new() }
local s89 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.9 }
local e89 = Frame { s89, Size = UDim2.new() }
local s90 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.1 }
local e90 = Frame { s90, Size = UDim2.new() }
local s91 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.2 }
local e91 = Frame { s91, Size = UDim2.new() }
local s92 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.3 }
local e92 = Frame { s92, Size = UDim2.new() }
local s93 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.4 }
local e93 = Frame { s93, Size = UDim2.new() }
local s94 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.5 }
local e94 = Frame { s94, Size = UDim2.new() }
local s95 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.6 }
local e95 = Frame { s95, Size = UDim2.new() }
local s96 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.7 }
local e96 = Frame { s96, Size = UDim2.new() }
local s97 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.8 }
local e97 = Frame { s97, Size = UDim2.new() }
local s98 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.9 }
local e98 = Frame { s98, Size = UDim2.new() }
local s99 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.1 }
local e99 = Frame { s99, Size = UDim2.new() }
local s100 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.2 }
local e100 = Frame { s100, Size = UDim2.new() }
local s101 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.3 }
local e101 = Frame { s101, Size = UDim2.new() }
local s102 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.4 }
local e102 = Frame { s102, Size = UDim2.new() }
local s103 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.5 }
local e103 = Frame { s103, Size = UDim2.new() }
local s104 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.6 }
local e104 = Frame { s104, Size = UDim2.new() }
local s105 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.7 }
local e105 = Frame { s105, Size = UDim2.new() }
local s106 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.8 }
local e106 = Frame { s106, Size = UDim2.new() }
local s107 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.9 }
local e107 = Frame { s107, Size = UDim2.new() }
local s108 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.1 }
local e108 = Frame { s108, Size = UDim2.new() }
local s109 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.2 }
local e109 = Frame { s109, Size = UDim2.new() }
local s110 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.3 }
local e110 = Frame { s110, Size = UDim2.new() }
local s111 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.4 }
local e111 = Frame { s111, Size = UDim2.new() }
local s112 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.5 }
local e112 = Frame { s112, Size = UDim2.new() }
local s113 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.6 }
local e113 = Frame { s113, Size = UDim2.new() }
local s114 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.7 }
local e114 = Frame { s114, Size = UDim2.new() }
local s115 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.8 }
local e115 = Frame { s115, Size = UDim2.new() }
local s116 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.9 }
local e116 = Frame { s116, Size = UDim2.new() }
local s117 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.1 }
local e117 = Frame { s117, Size = UDim2.new() }
local s118 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.2 }
local e118 = Frame { s118, Size = UDim2.new() }
local s119 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.3 }
local e119 = Frame { s119, Size = UDim2.new() }
local s120 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.4 }
local e120 = Frame { s120, Size = UDim2.new() }
local s121 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.5 }
local e121 = Frame { s121, Size = UDim2.new() }
local s122 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.6 }
local e122 = Frame { s122, Size = UDim2.new() }
local s123 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.7 }
local e123 = Frame { s123, Size = UDim2.new() }
local s124 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.8 }
local e124 = Frame { s124, Size = UDim2.new() }
local s125 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.9 }
local e125 = Frame { s125, Size = UDim2.new() }
local s126 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.1 }
local e126 = Frame { s126, Size = UDim2.new() }
local s127 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.2 }
local e127 = Frame { s127, Size = UDim2.new() }
local s128 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.3 }
local e128 = Frame { s128, Size = UDim2.new() }
local s129 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.4 }
local e129 = Frame { s129, Size = UDim2.new() }
local s130 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.5 }
local e130 = Frame { s130, Size = UDim2.new() }
local s131 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.6 }
local e131 = Frame { s131, Size = UDim2.new() }
local s132 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.7 }
local e132 = Frame { s132, Size = UDim2.new() }
local s133 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.8 }
local e133 = Frame { s133, Size = UDim2.new() }
local s134 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.9 }
local e134 = Frame { s134, Size = UDim2.new() }
local s135 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.1 }
local e135 = Frame { s135, Size = UDim2.new() }
local s136 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.2 }
local e136 = Frame { s136, Size = UDim2.new() }
local s137 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.3 }
local e137 = Frame { s137, Size = UDim2.new() }
local s138 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.4 }
local e138 = Frame { s138, Size = UDim2.new() }
local s139 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.5 }
local e139 = Frame { s139, Size = UDim2.new() }
local s140 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.6 }
local e140 = Frame { s140, Size = UDim2.new() }
local s141 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.7 }
local e141 = Frame { s141, Size = UDim2.new() }
local s142 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.8 }
local e142 = Frame { s142, Size = UDim2.new() }
local s143 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.9 }
local e143 = Frame { s143, Size = UDim2.new() }
local s144 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.1 }
local e144 = Frame { s144, Size = UDim2.new() }
local s145 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.2 }
local e145 = Frame { s145, Size = UDim2.new() }
local s146 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.3 }
local e146 = Frame { s146, Size = UDim2.new() }
local s147 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.4 }
local e147 = Frame { s147, Size = UDim2.new() }
local s148 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.5 }
local e148 = Frame { s148, Size = UDim2.new() }
local s149 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.6 }
local e149 = Frame { s149, Size = UDim2.new() }
return {}
