--!strict
-- E37 strict probe: each line labelled T<n>; the analyzer diagnostics are matched back by line number.
local q = require("./s10-config")
local QT = require("../../../quad-types/src")
local D = q.Declaration
type None = QT.None

local _c0 = D.TextLabel { Text = 42 } -- T0 control: must error
local _p1 = D.TextLabel { Text = nil } -- T1 literal nil
local _p2 = D.TextLabel { Text = q.None } -- T2 literal None
local _p3 = D.TextLabel { Text = q.Source(nil :: string?) } -- T3 State<string?>
local _p4 = D.TextLabel { Text = q.Source("a" :: string | None) } -- T4 State<string|None>
local _p5 = D.Frame { NextSelectionUp = q.Source(nil :: GuiObject?) } -- T5 object ref State<GuiObject?>
local _p6 = D.TextLabel { Text = q.Source(1):Compute(function(h) if h:Get() > 1 then return nil end return "x" end) } -- T6 Compute may return nil
local _p7 = D.TextLabel { TextTransparency = q.Source(nil :: number?):Apply(q.Animate { Time = 1 }) } -- T7 Animate over number?
local _p8 = D.TextLabel { TextTransparency = q.Tween { Value = nil } } -- T8 Tween Value nil
local _p9 = D.TextLabel { TextTransparency = q.Tween { Value = q.None } } -- T9 Tween Value None
local _e1 = D.TextButton { Activated = q.None } -- T10 event None
local _e2 = D.TextButton { Activated = q.Source(nil :: (() -> ())?) } -- T11 event State<cb?>
local _s1 = D.Frame { UICorner = q.None } -- T12 shorthand None
local _s2 = D.Frame { UICorner = q.Source(nil :: number?) } -- T13 shorthand State<number?>
local _c1 = D.Frame { q.None, D.Frame {} } -- T14 numeric None
local _c2 = D.Frame { q.Source(nil :: Instance?) } -- T15 numeric State<Instance?>
local _sl1 = q.Slot({ q.None } :: any) -- (runtime-only row, typed any)
local _sl2 = q.Slot<<Instance>>({ q.None }) -- T16 Slot element None
local _sl3 = q.Slot<<Instance>>():Add(nil) -- T17 Slot:Add(nil)
local _sl4 = q.Slot<<Instance>>():Add(q.Source(nil :: Instance?)) -- T18 Slot:Add(State<Instance?>)
local _sl5 = q.Slot<<Instance>>():Single(q.Source(nil :: Instance?)) -- T19 :Single(State<Instance?>)
local _t1 = q.Tag("A", nil, "B") -- T20 Tag nil arg
local _t2 = q.Tag(q.None) -- T21 Tag None
local _t3 = q.Tag("A"):Added(q.None) -- T22 Tag:Added None
local _a1 = q.Attr({ A = q.None }) -- T23 Attr None
local _a2 = q.Attr({ A = q.Source(nil :: number?) }) -- T24 Attr State<number?>
local _a3 = q.StringAttr("L", nil) -- T25 StringAttr nil
local _a4 = q.NumberAttr("N", q.Source(nil :: number?)) -- T26 NumberAttr State<number?>
local _st1 = q.Store({ hp = q.None }) -- T27 Store field None
local _st2 = q.Source(q.None) -- T28 Source(None)
local _m1 = q.Modifier():BackgroundTransparency(q.None) -- T29 Modifier None
local _m2 = q.Modifier():BackgroundTransparency(nil) -- T30 Modifier nil
local P = q.Context.Provider("P") :: q.Provider<number>
local _cx1 = q.Context():Set(P, nil) -- T31 Context nil
local _cx2 = q.Context():Set(P, q.None) -- T32 Context None
local r = q.Ref(nil :: Frame?)
r:Set(nil) -- T33 Ref<Frame?>:Set(nil)
local r2 = q.Ref(D.Frame {})
r2:Set(nil) -- T34 Ref<Frame>:Set(nil)
r2:Set(q.None) -- T35 Ref<Frame>:Set(None)
local _o1 = D.TextBox { q.Out("Text", q.Source(nil :: string?)) } -- T36 Out Source<string?>
local _o2 = D.Frame { q.Out("NextSelectionUp", q.Source(nil :: GuiObject?)) } -- T37 Out object ref Source<GuiObject?>
local _o3 = D.TextBox { q.OnChange("Text", q.None) } -- T38 OnChange None
local store = q.Store({ hp = q.Source(nil :: number?) })
local _p10 = D.TextLabel { TextTransparency = store.hp } -- T39 store field Source<number?> into number prop
local _l1 = q.Slot<<Instance>>():List(q.Source({ "a" }), function(ctx) return nil end) -- T40 :List updateFn returns nil
local _l2 = q.Slot<<Instance>>():List(q.Source({ "a" }), function(ctx) return q.None end) -- T41 :List updateFn returns None
local _dis = q.dispose(q.None) -- T42 dispose None
