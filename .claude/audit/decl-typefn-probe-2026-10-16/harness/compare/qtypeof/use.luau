--!strict
-- [2026-10-19 M1] typeof(q.X) extraction: alias, alias-typed locals, wrapper params, partial application, generic pass-through.
-- Markers: `-- OK` = must be clean, `-- NEG` = must error ON THIS LINE (one-line cases only).
local QT = require("../../../../../../quad-types/src")
local Ext = require("./Ext2")
local L = require("../../../src/Lib2")
local q = (nil :: any) :: Ext.Q

-- (a) local aliases
type OnChangeT = typeof(q.OnChange)
type OnEventT = typeof(q.OnEvent)
type OutT = typeof(q.Out)
type ElemT = typeof(q.Elem)
local OnChange: OnChangeT = q.OnChange -- @h(a-onchange) at='OnChange:'
local OnEvent: OnEventT = q.OnEvent
local Out: OutT = q.Out -- @h(a-out) at='Out:'
local Elem: ElemT = q.Elem -- @h(a-elem) at='Elem:'

-- (a1) direct calls through the alias-typed locals
local c1 = OnChange "Frame" "Visible" (function(v) local b: boolean = v end) -- @h(a1-v) at='v)' OK
local c2 = OnChange "Frame" "Visible" (function(v) local s: string = v end) -- NEG body misuse
local c3 = OnChange "Frame" "Visibel" (function(v) end) -- NEG wrong name
local c4 = OnChange "Fraem" "Visible" (function(v) end) -- NEG wrong class
local c5 = OnChange "Frame" "Visible" (function(v) end) -- @c(a1-name) at='OnChange "Frame" "' ins='Vis'
local c6 = OnChange "Frame" "Visible" (function(v) end) -- @c(a1-class) at='OnChange "' ins='Fr'
local e1 = OnEvent "Frame" "MouseEnter" (function(x, y) local n: number = x end) -- @h(a1-x) at='x, y' OK
local e2 = OnEvent "Frame" "MouseEnter" (function(x, y) local s: string = x end) -- NEG
local e3 = OnEvent "Frame" "Activated" (function() end) -- NEG not a Frame event
local e4 = OnEvent "TextButton" "Activated" (function(input, count) local _ = input.UserInputType end) -- @c(a1-input) at='input.' ins='User'
local o1 = Out "Frame" "Size" (q.Source(UDim2.new())) -- OK
local o2 = Out "Frame" "Size" (q.Source(5)) -- NEG wrong Source type
local o3 = Out "Frame" "Siz" (q.Source(UDim2.new())) -- NEG wrong name
local Frame = Elem "Frame" -- @h(a1-frame) at='Frame ='
local f1 = Frame { Visible = true } -- OK
local f2 = Frame { Visible = 5 } -- NEG
local f3 = Frame { Vis = true } -- @c(a1-props) at='Frame { ' ins='Back'
local f4 = Elem "Fraem" -- NEG

-- (b) wrapper functions whose PARAMETER is the alias
local function withChange(oc: OnChangeT) return oc "TextLabel" "Text" (function(v) local s: string = v end) end -- OK
local function withChangeBad(oc: OnChangeT) return oc "TextLabel" "Text" (function(v) local n: number = v end) end -- NEG
local function withChangeName(oc: OnChangeT) return oc "TextLabel" "Txet" (function(v) end) end -- NEG
local function withEvent(oe: OnEventT) return oe "TextButton" "Activated" (function(input, count) local n: number = count end) end -- @h(b-count) at='count)' OK
local function withEventBad(oe: OnEventT) return oe "TextButton" "Activated" (function(input, count) local s: string = count end) end -- NEG
local function withOut(o: OutT, s: QT.Source<UDim2>) return o "Frame" "Size" (s) end -- OK
local function withOutBad(o: OutT, s: QT.Source<number>) return o "Frame" "Size" (s) end -- NEG
local function withElem(e: ElemT) return (e "TextLabel") { Text = "x" } end -- OK
local function withElemBad(e: ElemT) return (e "TextLabel") { Text = 5 } end -- NEG
local function complParam(oc: OnChangeT) return oc "Frame" "Visible" (function(v) end) end -- @c(b-name) at='oc "Frame" "' ins='Abs'
local function complParamEv(oe: OnEventT) return oe "Frame" "MouseEnter" (function(x, y) end) end -- @c(b-evname) at='oe "Frame" "' ins='Mouse'
local w1 = withChange(q.OnChange) -- OK
local w2 = withChange(function() end) -- NEG not an OnChange
local w3 = withOut(q.Out, q.Source(UDim2.new())) -- OK
local w4 = withOut(q.Out, q.Source(5)) -- NEG

-- (c) typeof of a PARTIAL application (class already chosen)
type FrameChange = typeof(q.OnChange "Frame")
type FrameCtor = typeof(q.Elem "Frame")
type FrameOut = typeof(q.Out "Frame")
local function useFrameChange(fc: FrameChange) return fc "Visible" (function(v) local b: boolean = v end) end -- @h(c-v) at='v)' OK
local function useFrameChangeBad(fc: FrameChange) return fc "Visible" (function(v) local s: string = v end) end -- NEG
local function useFrameChangeName(fc: FrameChange) return fc "Text" (function(v) end) end -- NEG Text is not Frame
local function useFrameChangeCompl(fc: FrameChange) return fc "Visible" (function(v) end) end -- @c(c-name) at='fc "' ins='Abs'
local fcOk: FrameChange = q.OnChange "Frame" -- OK
local fcOther: FrameChange = q.OnChange "TextLabel" -- NEG? another class's curried fn
local function mk(ctor: FrameCtor) return ctor { Visible = true } end -- OK
local function mkBad(ctor: FrameCtor) return ctor { Visible = 5 } end -- NEG
local m1 = mk(q.Elem "Frame") -- OK
local m2 = mk(q.Elem "TextLabel") -- NEG wrong ctor
local function mkCtor(ctor: L.ElemCtor<Frame>) return ctor { Visible = true } end -- OK
local m3 = mkCtor(q.Elem "Frame") -- OK
local m4 = mkCtor(q.Elem "TextLabel") -- NEG
local function useFrameOut(fo: FrameOut, s: QT.Source<boolean>) return fo "Visible" (s) end -- OK
local function useFrameOutBad(fo: FrameOut, s: QT.Source<number>) return fo "Visible" (s) end -- NEG

-- (d) pass-through generic / table field
local function id<T>(x: T): T return x end
local oc2 = id(q.OnChange) -- @h(d-oc2) at='oc2 ='
local fcPartial = q.OnChange "Frame" -- @h(c-partial) at='fcPartial ='
local ctorPartial = q.Elem "Frame" -- @h(c-ctor) at='ctorPartial ='
local withChangeType = withChange -- @h(b-wrap) at='withChangeType ='
local abs1 = OnChange "Frame" "AbsoluteSize" (function(v) local n: number = v.X end) -- @h(c-abs) at='v)' OK
local abs2 = OnChange "Frame" "AbsoluteSize" (function(v) local _ = v.X end) -- @c(c-absdot) at='v.' ins='Mag' 
local g1 = oc2 "Frame" "Visible" (function(v) local s: string = v end) -- NEG via generic pass-through
local api: { OnChange: OnChangeT, Elem: ElemT } = { OnChange = q.OnChange, Elem = q.Elem } -- OK
local t1 = api.OnChange "Frame" "Visible" (function(v) local s: string = v end) -- NEG via table field
local t2 = (api.Elem "Frame") { Visible = 5 } -- NEG via table field

return { c1, c2, c3, c4, c5, c6, e1, e2, e3, e4, o1, o2, o3, f1, f2, f3, f4, withChange, withChangeBad, withChangeName,
	withEvent, withEventBad, withOut, withOutBad, withElem, withElemBad, w1, w2, w3, w4, useFrameChange, useFrameChangeBad,
	useFrameChangeName, useFrameChangeCompl, fcOk, fcOther, mk, mkBad, m1, m2, mkCtor, m3, m4, useFrameOut, useFrameOutBad,
	g1, t1, t2, complParam, complParamEv, fcPartial, ctorPartial, withChangeType, abs1, abs2 }
