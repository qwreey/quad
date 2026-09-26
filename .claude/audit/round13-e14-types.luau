--!strict
-- round13 E14 type probe. Lines tagged `-- E:` expect an error, `-- OK:` expect none.
local q = require("./round13-e14-types-settings")
local R = require("../../quad-roblox/src")
local QuadTypes = require("../../quad-roblox/luau_packages/quad_types")
local D = q.Declaration
local None = q.None

local function _T()
	local f = D.Modifier.Frame()
	local _t1 = f:Parent(Instance.new("Frame")) -- E:T1 Parent not a setter
	local _t2 = f:Size("x") -- E:T2 wrong value type
	local _t3 = D.Modifier.TextButton():Activated(function() end) -- E:T3 event not a setter
	local _t4 = f:Size(function(_old) return function() end end) -- E:T4 transform returns function (Q79 type side)
	local _t5 = f:Size(q.Source("x")) -- E:T5 State of wrong type
	local _t6 = f:Size(q.Source(UDim2.new())) -- OK:T6
	local _t7 = f:Visible(q.Source(true):Compute(function(s: q.StateData<boolean>): boolean return not s:Get() end)) -- OK:T7 Compute state
	local _t8 = f:Size(q.Slot()) -- E:T8 Slot as field
	local _t9 = f:Size(q.Ref()) -- E:T9 Ref as field
	local _t10 = f:Name(q.Tag("a")) -- E:T10 Tag as field
	local _t11 = f:Size(q.None) -- OK:T11
	local _t12 = f:Size(nil) -- OK:T12 nil absent
	local _t13 = f:Size(function(_old) return nil end) -- OK:T13
	local _t14 = f:Style(q.Tween({ Value = Enum.FrameStyle.Custom, Time = 1 })) -- E:T14 Tween on non-interpolable
end

local function _C()
	-- constructor table form
	local _c1 = D.Modifier.Frame({ Size = "x" }) -- E?:C1 wrong type in table form
	local _c2 = D.Modifier.Frame({ Sise = UDim2.new() }) -- E?:C2 typo field in table form
	local _c3 = D.Modifier.Frame({ Parent = Instance.new("Frame") }) -- E?:C3 Parent in table form
	local _c4 = D.Modifier.Frame({ Activated = function() end }) -- E?:C4 function (runtime Quad0063)
	-- constructor merging a foreign-class Modifier
	local _c5 = D.Modifier.Frame(D.Modifier.TextLabel():Text("x")) -- E?:C5 sibling class merged + retagged
	local _c6 = D.Modifier.GuiObject(D.Modifier.Frame():Style(Enum.FrameStyle.Custom)) -- E?:C6 subclass merged into ancestor tag
	local _c7 = D.Frame({ D.Modifier.Frame(D.Modifier.TextLabel():Text("x")) }) -- OK?:C7 then onto Frame passes type
	local _c8 = q.Modifier({ Size = "x" }) -- (untyped — any expected)
	local _c9 = D.Modifier.Frame(q.Source(1)) -- E?:C9 non-plain arg (runtime Quad0065)
	local _c10 = D.Modifier.Frame(q.Tag("a")) -- E?:C10 Tag arg (runtime Quad0065)
end

local function _I()
	local function Into(m: R.IntoTextButton): R.TextButtonModifier return m:AsTextButton() end
	local _i1 = Into(D.Modifier.GuiObject()) -- OK:I1 ancestor
	local _i2 = Into(D.Modifier.TextButton()) -- OK:I2 self
	local _i3 = Into(D.Modifier.Frame()) -- E:I3 sibling
	local _i4 = Into(q.Modifier()) -- E:I4 untyped base
	local _i5 = Into(q.Modifier.Overridden(D.Modifier.Frame(), D.Modifier.Frame())) -- E?:I5 Overridden returns any
	local _i6 = Into(D.Modifier.TextLabel()) -- E:I6 sibling
	local _i7 = Into(D.Modifier.GuiButton()) -- OK:I7
	local _i8 = Into(D.Modifier.Instance()) -- OK:I8 root
end

local function _E()
	local _e1 = D.Frame({ D.Modifier.TextLabel() }) -- E:E1 sibling tag
	local _e2 = D.Frame({ D.Modifier.GuiObject() }) -- OK:E2
	local _e3 = D.Frame({ q.Modifier() }) -- OK:E3 untyped
	local _e4 = D.Frame({ q.Modifier.Overridden(D.Modifier.TextLabel(), D.Modifier.TextLabel()) }) -- E?:E4 any leaks
	local _e5 = D.Frame({ D.Modifier.TextLabel():As("Frame") }) -- E?:E5 unchecked retag keeps type? (As<T> returns T — inferred?)
	local _e6 = D.Frame({ D.Modifier.TextLabel():Apply(function(m) return m end) }) -- E?:E6 Apply any leaks
	local _e7 = D.TextButton({ if math.random() > 0.5 then D.Modifier.TextButton() else None, Text = "" }) -- OK:E7 or None idiom
	local _e8 = D.TextLabel({ D.Modifier.Frame():AsTextLabel() }) -- E:E8 AsTextLabel absent on Frame type
	local _e9 = D.Frame({ D.Modifier.Frame():Size(UDim2.new()):AsFrame() }) -- OK:E9
end

local function _P()
	local m = D.Modifier.Frame():Size(UDim2.new())
	local p1: QuadTypes.FieldOut<UDim2>? = m:Peek<<UDim2>>("Size") -- OK:P1
	local p2 = m:Peek<<UDim2>>("Sise") -- OK?:P2 key is just string
	local _p3: number = m:Peek<<UDim2>>("Size") -- E:P3
	return p1, p2
end

return { _T, _C, _I, _E, _P }
