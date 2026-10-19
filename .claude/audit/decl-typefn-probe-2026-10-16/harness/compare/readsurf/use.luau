--!strict
-- [2026-10-19 M2] read surface incl. ReadOnly (Lib2 readmap, forRead) vs write surface (props/Modifier/Spread, DenyWrite kept).
-- Kit reference cases: devui Plot `q.Out("AbsoluteSize", pixels)` (pixels: Source<Vector2>), TextField/InputText `q.Out("Text", value)`,
-- material YearView `q.OnChange("CanvasPosition", function(pos: Vector2) … end)`, TextField `q.OnChange("Text", writeBack)`.
local QT = require("../../../../../../quad-types/src")
local L = require("../../../src/Lib2")
type CM<K> = index<L.ModClassMap, K>
type EM<K> = index<L.CreatableMap, K>
local Elem = (nil :: any) :: <K>(name: K & keyof<L.CreatableMap>) -> (L.Props<EM<K>>) -> EM<K>
local Spread = (nil :: any) :: <K>(name: K & keyof<L.ModClassMap>) -> (L.Props<CM<K>>) -> L.Spread<CM<K>>
local Modifier = (nil :: any) :: <K>(name: K & keyof<L.ModClassMap>) -> (...any) -> L.Modifier<CM<K>>
local OnChange = (nil :: any) :: <C0>(class: C0 & keyof<L.ModClassMap>) -> <K>(name: K & keyof<L.ReadMap<CM<C0>>>) -> (fn: (index<L.ReadMap<CM<C0>>, K>) -> ()) -> L.OnChangeDescriptor<K>
local Out = (nil :: any) :: <C0>(class: C0 & keyof<L.ModClassMap>) -> <K>(name: K & keyof<L.ReadMap<CM<C0>>>) -> (src: QT.Source<index<L.ReadMap<CM<C0>>, K>>) -> L.OnChangeDescriptor<K>
local Source = (nil :: any) :: <T>(v: T) -> QT.Source<T>

-- how the checker exposes read/write halves (printed by the type function)
type _RW = L.RWReport<Frame | TextLabel | ScrollingFrame | TextBox>

local Frame = Elem "Frame"
local TextBox = Elem "TextBox"
local TextLabel = Elem "TextLabel"
local pixels: QT.Source<Vector2> = Source(Vector2.new(0, 0))
local value: QT.Source<string> = Source("")

-- read surface: ReadOnly props accepted
local r1 = Out "Frame" "AbsoluteSize" (pixels) -- OK
local r2 = Out "TextLabel" "TextBounds" (Source(Vector2.zero)) -- OK
local r3 = Out "TextBox" "Text" (value) -- OK writable props stay readable
local r4 = Out "Frame" "AbsolutePosition" (Source(Vector2.zero)) -- OK
local r5 = Out "TextLabel" "TextFits" (Source(true)) -- OK
local r6 = Out "ScrollingFrame" "AbsoluteCanvasSize" (Source(Vector2.zero)) -- OK
local r7 = Out "Frame" "Parent" (Source(nil :: Instance?)) -- OK Parent on read surface (Instance?)
local c1 = OnChange "Frame" "AbsoluteSize" (function(v) local n: number = v.X end) -- @h(m2-v) at='v)' OK
local c2 = OnChange "ScrollingFrame" "CanvasPosition" (function(pos: Vector2) end) -- OK kit form (annotated)
local function writeBack(text: string) end
local c3 = OnChange "TextBox" "Text" (writeBack) -- OK kit form (named fn)
local c4 = OnChange "TextLabel" "TextBounds" (function(v) local _ = v.X end) -- @c(m2-dot) at='v.' ins='Mag'
local c5 = OnChange "Frame" "Abs" (function(v) end) -- @c(m2-name) at='OnChange "Frame" "' ins='Abs'
-- read surface: wrong types / names rejected
local n1 = Out "Frame" "AbsoluteSize" (Source(UDim2.new())) -- NEG wrong Source type
local n2 = Out "TextLabel" "TextBounds" (Source(5)) -- NEG
local n3 = OnChange "Frame" "AbsoluteSize" (function(v) local s: string = v end) -- NEG body misuse
local n4 = OnChange "ScrollingFrame" "CanvasPosition" (function(pos: UDim2) end) -- NEG wrong annotation
local n5 = Out "Frame" "TextBounds" (Source(Vector2.zero)) -- NEG not a Frame prop
local n6 = Out "Frame" "DataCost" (Source(0)) -- NEG Deny (both surfaces) still applies to reads
local n7 = OnChange "TextBox" "Text" (function(n: number) end) -- NEG
-- write surface: ReadOnly still rejected
local w1 = Frame { AbsoluteSize = Vector2.zero } -- NEG write surface
local w2 = TextLabel { TextBounds = Vector2.zero } -- NEG write surface
local w3 = Frame { Parent = workspace } -- NEG Parent (write deny)
local w4 = Modifier "Frame" ():AbsoluteSize(Vector2.zero) -- NEG Modifier setter
local w5 = Spread "Frame" { AbsolutePosition = Vector2.zero } -- NEG Spread
local w6 = Frame { Size = UDim2.new(), Visible = true } -- OK
-- Q127 (a) on the read surface
local q1 = Out "Frame" "NextSelectionUp" (Source(nil :: GuiObject?)) -- OK
local q2 = Out "Frame" "NextSelectionUp" (Source((nil :: any) :: GuiObject)) -- NEG non-nil Source for a T? read (invariance)
local q3 = OnChange "Frame" "NextSelectionUp" (function(v) local g: GuiObject = v end) -- NEG v is GuiObject?
local q4 = OnChange "Frame" "NextSelectionUp" (function(v) local g: GuiObject? = v end) -- OK
local q5 = OnChange "Frame" "Parent" (function(v) local p: Instance? = v end) -- OK
-- descriptors placed in the element (array part checks the name against the class's read surface)
local e1 = Frame { Out "Frame" "AbsoluteSize" (pixels), OnChange "Frame" "AbsoluteSize" (function(v) end) } -- OK
local e2 = TextBox { Out "TextBox" "Text" (value), Text = value } -- OK kit form
local e3 = Frame { Out "TextBox" "Text" (value) } -- NEG Text is not readable on Frame
local e4 = Frame { Out "TextLabel" "TextBounds" (Source(Vector2.zero)) } -- NEG
return { r1, r2, r3, r4, r5, r6, r7, c1, c2, c3, c4, c5, n1, n2, n3, n4, n5, n6, n7, w1, w2, w3, w4, w5, w6, q1, q2, q3, q4, q5, e1, e2, e3, e4 }
