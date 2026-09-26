-- round13 E7 type-surface probe (2026-09-26). Concatenation of scratch files that lived in quad-roblox/test/ —
-- split at '-- ==== FILE' markers back into quad-roblox/test/<name> to re-run (settings module must be probe.e7settings.luau).
-- command: luau-lsp 1.69.0 analyze --flag:LuauSolverV2=true --flag:LuauTarjanChildLimit=160000 --flag:LuauSubtypingIterationLimit=100000 --flag:LuauTypeInferIterationLimit=1000000 --definitions=scripts/roblox-defs/globalTypes.d.luau --ignore '**/luau_packages/**' <file>

-- ==== FILE probe.e7b.luau
--!strict
local q = require("./probe.e7settings")
local QuadTypes = require("../luau_packages/quad_types")
local D = q.Declaration

local function _A()
	local count = q.Source(0)
	local c1 = count:Compute(function(c: q.StateData<number>): boolean return true end)
	local g: string = c1:Get() -- expect-error A2 Get boolean
	local bad1: QuadTypes.State<string> = c1 -- expect-error A3 State<boolean> -> State<string>
	local bad2: QuadTypes.State<string> = q.Source(true) -- expect-error A4 Source<boolean> -> State<string>
	local bad3: QuadTypes.Source<string> = q.Source(true) -- expect-error A5 Source<boolean> -> Source<string>
	local bad4: q.State<string> = count:Compute(function(c: q.StateData<number>): boolean return true end) -- expect-error A6
	local bad5: QuadTypes.StateData<string> = q.Source(true) -- expect-error A7 StateData
	return g, bad1, bad2, bad3, bad4, bad5
end

local function _B()
	local s1: q.Slot<Frame> = q.Slot<<TextLabel>>() -- expect-error B5 sibling Slot
	local s2: q.Slot<Instance> = q.Slot<<TextLabel>>() -- B6 Slot<TextLabel> -> Slot<Instance> (invariant expected?)
	local s3: q.Slot<number> = q.Slot<<string>>() -- expect-error B7 Slot<string> -> Slot<number>
	s2:Add(D.Frame({})) -- B6 consequence: Frame into what is actually Slot<TextLabel>
	return s1, s3
end

local function _C()
	local data = q.Source({ "a", "b" })
	local s = q.Slot<<TextLabel>>():List(data, function(ctx)
		return nil
	end)
	local s2 = q.Slot<<TextLabel>>():List(data, function(ctx)
		return D.Frame({}) -- C3 wrong element class
	end)
	local s3 = q.Slot<<TextLabel>>():List(data, function(ctx)
		return D.TextLabel({ Text = ctx.Item }) -- C4 Item is string|KeyGone into Text
	end)
	return s, s2, s3
end

-- ==== FILE probe.e7c.luau
--!strict
local Quad = require("../luau_packages/quad_base")
local QuadTypes = require("../luau_packages/quad_types")
local q0 = Quad.New()
local qs = require("./probe.e7settings")

local function _A()
	local count = q0.Source(0)
	local c1 = count:Compute(function(c: QuadTypes.StateData<number>): boolean return true end)
	local z1: nil = c1 -- show type
	local c2 = count:Compute(function(c: QuadTypes.StateData<number>) return true end)
	local z2: nil = c2 -- show type
	local c3 = count:Compute(function(c) return true end)
	local z3: nil = c3
	local cnt2 = qs.Source(0)
	local c4 = cnt2:Compute(function(c: QuadTypes.StateData<number>): boolean return true end)
	local z4: nil = c4
	local g: string = c4:Get()
	local c5: QuadTypes.State<boolean> = count:Compute(function(c: QuadTypes.StateData<number>): boolean return true end)
	local g5: string = c5:Get() -- expect-error
	return z1, z2, z3, z4, g, g5
end

-- ==== FILE probe.e7d.luau
--!strict
local q = require("./probe.e7settings")
local D = q.Declaration
local None = q.None

local function ModalDialog(props: { read Title: string, read Children: q.Slot<Instance>? }): Frame
	return D.Frame({ props.Children or None })
end
local function Plain(props: { Children: q.Slot<Instance>? }) end
local function Req(props: { read Children: q.Slot<Instance> }) end
local function Direct(s: q.Slot<Instance>) end
local function _B()
	local st = q.Slot<<TextLabel>>()
	local _a = ModalDialog({ Title = "t", Children = q.Slot<<TextLabel>>() }) -- probe B1a literal
	local _b = ModalDialog({ Title = "t", Children = st }) -- probe B1b via local
	Plain({ Children = st }) -- probe B1c mutable field
	Req({ Children = st }) -- probe B1d non-optional read
	Direct(st) -- probe B1e direct param
	local n = q.Slot<<number>>()
	local _c = ModalDialog({ Title = "t", Children = n }) -- expect-error B1f Slot<number>
	Direct(n) -- expect-error B1g
	local tb: { read Children: q.Slot<Instance>? } = { Children = st } -- probe B1h annotated local
end

local function _Cinline()
	local count = q.Source(0)
	local _f = D.Frame({ Size = count:Compute(function(c: q.StateData<number>): number return c:Get() end) }) -- probe inline Compute number into UDim2 (typing-limits §1 hole)
end

-- ==== FILE probe.e7e.luau
--!strict
local q = require("./probe.e7settings")
local QuadTypes = require("../luau_packages/quad_types")

local function F1(p: { read X: number? }) end
local function F2(p: { read X: q.Slot<Instance>? }) end
local function F3(s: q.Slot<Instance>?) end
local function F4(p: { read X: q.State<number>? }) end
local function F5(p: { read X: q.Ref<Frame?>? }) end
local function F6(p: { read X: q.Source<number>? }) end
local function F7(p: { X: q.Slot<Instance>? }) end
local function F8(p: { read X: (q.Slot<Instance> | false) }) end
local function _()
	F1({ X = "s" }) -- expect-error primitive optional
	F2({ X = q.Slot<<number>>() }) -- expect-error Slot<number> into Slot<Instance>? field
	F3(q.Slot<<number>>()) -- expect-error Slot<number> into Slot<Instance>? param
	F4({ X = q.Source("s") }) -- expect-error State<string> into State<number>? field
	F5({ X = q.Ref<<TextLabel?>>(nil) }) -- expect-error Ref sibling
	F6({ X = q.Source("s") }) -- expect-error Source<string> into Source<number>? field
	F7({ X = q.Slot<<number>>() }) -- expect-error mutable optional field
	F8({ X = q.Slot<<number>>() }) -- expect-error union with false
	local s: q.Slot<Instance>? = q.Slot<<number>>() -- expect-error local optional
	local t: q.State<number>? = q.Source("s") -- expect-error local optional state
	return s, t
end

-- ==== FILE probe.e7f.luau
--!strict
local q = require("./probe.e7settings")
type Box<T> = { read V: T, Put: (self: Box<T>, v: T) -> () }
type Box2<T> = { read V: T }
type Box3<T> = { Put: (self: Box3<T>, v: T) -> () }
type Box4<T> = { Put: (v: T) -> () }
local function G1(b: Box<number>?) end
local function G2(b: Box2<number>?) end
local function G3(b: Box3<number>?) end
local function G4(b: Box4<number>?) end
local function R1(r: q.Ref<Frame?>) end
local function _()
	G1((nil :: any) :: Box<string>) -- expect-error Box
	G2((nil :: any) :: Box2<string>) -- expect-error Box2
	G3((nil :: any) :: Box3<string>) -- expect-error Box3 self-recursive method
	G4((nil :: any) :: Box4<string>) -- expect-error Box4 non-recursive method
	R1(q.Ref<<TextLabel?>>(nil)) -- expect-error Ref sibling non-optional
end

-- ==== FILE probe.e7g.luau
--!strict
local q = require("./probe.e7settings")
local D = q.Declaration
local M = D.Modifier

local function _()
	local _d1 = q.Debounce({ Time = "x" }) -- expect-error Debounce Time string (32)
	local _d2 = q.Debounce({ Time = q.Source(0.2) })
	local _d3 = q.Throttle({ Time = q.Source("x") }) -- expect-error Throttle Time State<string>
	local _e1 = q.Effect(function() return 1 end) -- expect-error Effect returns number
	local _e2 = q.Effect(function() return function(dying: boolean) end end)
	local _e3 = q.Effect(function() return function(dying: string) end end) -- expect-error cleanup param type
	local _a1 = D.Frame({ [q.AttrKey("Hp")] = 3 }) -- 8.17 documented strict error
	local _v1 = D.TextButton({ Activated = function(input: string) end }) -- expect-error wrong param type
	local _v2 = D.TextButton({ Activated = function() end })
	local _v3 = D.Frame({ MouseEnter = function(x: number, y: number, z: number) end }) -- expect-error extra param (8.23)
	local _o1 = q.OnChange("Size", function(v: number) end) -- expect-error OnChange wrong annotation
	local _o2 = q.OnChange("Nope", function(v) end) -- expect-error OnChange unknown name
	local _t1 = q.Tag(1) -- expect-error Tag number (8.6 __call hole?)
	local _t2 = D.Frame({ q.Tag("a", nil, "b") })
	local _n1 = q.NumberAttr("Hp", "x") -- expect-error NumberAttr string
	local _n2 = q.StringAttr("T", q.Source(1)) -- expect-error StringAttr State<number>
	local _h1 = q.OnCreated<<Frame>>(function(inst)
		local s: UDim2 = inst.Size
		local t: string = inst.Size -- expect-error inst typed Frame
	end)
	local _h2 = D.Frame({ _h1 })
	local _h3 = D.TextLabel({ _h1 }) -- expect-error Frame PreRef in TextLabel
	local src = q.Source(1)
	local sum: q.State<number> = src:Apply(q.Operator.Sum(2))
	local sumBad: q.State<string> = src:Apply(q.Operator.Sum(2)) -- expect-error Operator result number
	local _x1 = M.Frame():AsTextButton() -- expect-error Frame is not ancestor of TextButton
	local anim = q.Source(UDim2.new()):Apply(q.Animate({ Time = 0.3 }))
	local _an1 = D.Frame({ Size = anim })
	local _an2 = D.Frame({ Size = q.Source(1):Apply(q.Animate({ Time = 0.3 })) }) -- known loss (types.luau H-334): cross-T Animate
	local _an3 = q.Animate({ Time = "x" }) -- expect-error Animate Time string
	local nilable = q.Source(nil :: string?)
	local _out1 = D.TextBox({ q.Out("Text", nilable) }) -- Out with Source<string?> (doc?)
	local abs = q.Source(Vector2.zero)
	local _out2 = D.Frame({ q.Out("AbsoluteSize", abs) }) -- read-only prop write-back (PropTypesRead)
	local _out3 = D.Frame({ q.Out("Size", abs) }) -- expect-error Vector2 source for Size
	local cur = q.Source(nil :: Instance?)
	local _s1 = q.Slot<<Instance>>():Single(cur)
	local _s2 = q.Slot<<Frame>>():Single(q.Source(nil :: TextLabel?)) -- identity arm, wrong class (runtime guard only per quad-types comment)
	local st = q.Store({ hp = q.Source(1) })
	local _of: q.Source<string> = st:Of("hp") -- 8.23 unchecked cast
	local _p = M.Frame():Size(UDim2.new()):Peek<<string>>("Size") -- 8.23 unchecked
	local b = q.Blocker()
	local gated: q.State<number> = src:Apply(b)
	local _ns1 = D.Frame({ Size = q.None, Name = q.None })
	return sum, sumBad, gated
end

-- ==== FILE probe.e7h.luau
--!strict
local q = require("./probe.e7settings")
local QuadTypes = require("../luau_packages/quad_types")
local D = q.Declaration
local M = D.Modifier
local None = q.None

local function Rows(props: { read Items: { string } })
	local rows = q.Slot<<Instance>>()
	for _, text in props.Items do
		rows:Add(D.TextLabel({ Text = text }))
	end
	return rows
end
local function Card(props: { Children: q.Slot<Instance>? })
	return D.Frame({ props.Children or None })
end

local function _()
	local _l = D.Frame({ D.TextLabel({ Text = "h" }), Rows({ Items = { "a" } }) })
	local _c = Card({ Children = q.Slot<<Instance>>() })
	local slot = q.Slot<<Instance>>()
	slot.Length = q.Source(1) -- expect-error Length read-only
	slot.Length:Set(1) -- expect-error Length is State (no Set)
	local st = q.Store({ hp = q.Source(1) })
	local _n = st.Nope -- expect-error unknown store key
	local b = q.Blocker()
	b.Blocking = true -- expect-error Blocking read-only
	local _g = D.Frame({ M.GuiObject():Visible(true) })
	local _s = D.Frame({ q.Source(D.TextLabel({})) })
	local _s2 = D.Frame({ q.Source(1) }) -- expect-error State<number> in children
	local _nw = D.New<<Frame>>("Frame")({ Size = "x" }) -- D.New props any?
	local okc: QuadTypes.CheckedQuad<typeof(q), "3.*.*"> = q :: any
	local _ok = okc.__versionCheck
	local badc: QuadTypes.CheckedQuad<typeof(q), "4.*.*"> = q :: any
	local _bad = badc.__versionCheck -- expect-error version mismatch
	local mapper = D.Mapper.Frame("Body")({ Size = UDim2.new() })
	local _cl = q.Claim((nil :: any) :: Frame, mapper)
	local _mb = D.Mapper.Frame("Body")({ Size = "x" }) -- expect-error mapper prop type
	local ep = q.Epoch
	return ep
end

-- ==== FILE probe.e7i.luau
--!strict
local q = require("./probe.e7settings")
local QuadTypes = require("../luau_packages/quad_types")
local function _()
	local badc: QuadTypes.CheckedQuad<typeof(q), "4.*.*"> = q :: any
	return badc
end

-- ==== FILE probe.e7j.luau
--!strict
local Quad = require("../luau_packages/quad_base")
local QuadTypes = require("../luau_packages/quad_types")
local q = Quad.New()
local badc: QuadTypes.CheckedQuad<typeof(q), "4.*.*"> = q :: any
return badc

-- ==== FILE probe.e7k.luau
--!strict
local q = require("./probe.e7settings")
local Root = require("../src")
local QuadTypes = require("../luau_packages/quad_types")
local D = q.Declaration

local function MaterialButton(props: { read Text: string?, read Modifier: Root.TextButtonModifier?, read Ref: q.Ref<TextButton?>? }) end
local function NonOpt(props: { read Modifier: Root.TextButtonModifier }) end
local function _()
	local _d = q.Debounce({ Time = 0.1, Handle = q.Ref<<QuadTypes.GateHandle?>>(nil) })
	local _d2 = q.Debounce({ Time = 0.1, Handle = q.Ref<<Frame?>>(nil) }) -- expect-error Handle wrong Ref type
	local _t2 = q.Throttle({ Time = 0.1, Handle = q.Ref<<number>>(0) }) -- expect-error Handle wrong Ref type
	MaterialButton({ Modifier = D.Modifier.Frame() }) -- expect-error FrameModifier into TextButtonModifier?
	NonOpt({ Modifier = D.Modifier.Frame() }) -- expect-error FrameModifier into TextButtonModifier
	MaterialButton({ Ref = q.Ref<<Frame?>>(nil) }) -- expect-error Ref<Frame?> into Ref<TextButton?>?
	MaterialButton({ Modifier = D.Modifier.GuiObject() }) -- expect-error ancestor modifier into TextButtonModifier? (doc?)
end

-- ==== FILE probe.e7l.luau
--!strict
local q = require("./probe.e7settings")
local D = q.Declaration
local function F2(p: { read X: q.Slot<Instance>? }) end
local function _()
	F2({ X = q.Source(1) }) -- expect-error Source into Slot?
	F2({ X = D.Modifier.Frame() }) -- expect-error Modifier into Slot?
	F2({ X = q.Ref<<Frame?>>(nil) }) -- expect-error Ref into Slot?
	F2({ X = q.Context() }) -- expect-error Context into Slot?
	F2({ X = { Add = 1 } }) -- expect-error plain table
end

-- ==== FILE probe.e7m.luau
--!strict
local q = require("./probe.e7settings")
local D = q.Declaration
local function _()
	local _a = D.UIStroke({ q.Out("Color", q.Source(Color3.new())) }) -- positive? conflict name
	local _b = D.UIStroke({ q.Out("Transparency", q.Source(0)) }) -- positive? conflict name
	local _c = D.ScrollingFrame({ q.Out("CanvasSize", q.Source(UDim2.new())) }) -- positive? conflict name
	local _d = D.UIPadding({ q.Out("PaddingTop", q.Source(UDim.new())) }) -- positive non-conflict
	local _e = D.UIStroke({ q.OnChange("Color", function(v: Color3) end) }) -- positive
end

-- ==== FILE probe.e7n.luau
--!strict
local q = require("./probe.e7settings")
local QuadTypes = require("../luau_packages/quad_types")
type P = { A: any, B: number }
local function out<K>(name: K & keyof<P>, src: QuadTypes.Source<index<P, K>>) end
local function _()
	local s: QuadTypes.Source<any> = q.Source(Color3.new()) -- L7 direct Source<any>
	out("A", q.Source(Color3.new())) -- L8 index -> any
	out("B", q.Source(1)) -- L9 ok
	return s
end

-- ==== FILE probe.e7ns.luau
--!nonstrict
local q = require("./probe.e7settings")
local D = q.Declaration
local M = D.Modifier

local function _()
	local computed = q.Source(1):Compute(function(s) return tostring(s:Get()) end)
	local _1 = D.TextBox({ q.Out("Text", computed) }) -- NS1 Out read-only
	local _2 = D.Frame({ Size = "x" }) -- NS2 Size string
	local _3 = D.Frame({ Size = q.Source(1) }) -- NS3 number State into UDim2
	local _4 = D.TextButton({ Activated = 1 }) -- NS4 Activated number
	local _5 = D.Frame({ Sizee = UDim2.new() }) -- NS5 unknown prop
	local _6 = D.TextBox({ q.Out("Text", q.Source(1)) }) -- NS6 Out number
	local _7 = M.Frame():Text("x") -- NS7 Frame has no Text
	local _8 = q.Store({ Of = 1 }) -- NS8 reserved key
	local _9 = D.TextLabel({ Text = q.Tween({ Value = "hi" }) }) -- NS9 tween string
	local r = q.Ref(nil)
	local _10 = r:Unwrap():Foo() -- NS10
	local P = q.Context.Provider("n")
	local c = q.Context()
	c:Set(P, "str")
	local _11 = q.Debounce({ Time = "x" }) -- NS11
	local _12 = q.NumberAttr("Hp", "x") -- NS12
	local _13 = D.Frame({ Size = UDim2.new(), Visible = true, D.TextLabel({ Text = "a" }) }) -- NS13 positive
	local _14 = q.Slot<<Frame>>({ D.TextLabel({}) }) -- NS14 slot class
	local _15 = q.OnChange("Size", function(v: number) end) -- NS15
	local _16 = D.Frame({ BackgroundColor3 = q.Source(1):Compute(function(h) return Color3.new() end) }) -- NS16 positive nonstrict GS style
end

-- ==== FILE probe.e7o.luau
--!strict
local q = require("./probe.e7settings")
local D = q.Declaration
local function _()
	local _a = D.Frame({ Rotation = q.Tween({ Value = 1 }), BackgroundColor3 = q.Tween({ Value = Color3.new() }), Position = q.Tween({ Value = UDim2.new() }) })
	local _b = D.ImageLabel({ ImageRectOffset = q.Tween({ Value = Vector2.zero }), ImageColor3 = q.Tween({ Value = Color3.new() }) })
	local _c = D.TextLabel({ FontFace = q.Tween({ Value = Font.new("x") }) }) -- expect-error Font not tweenable
	local _d = D.Frame({ ZIndex = q.Tween({ Value = 1 }) }) -- ZIndex number (int) tweenable per list
	local _e = D.Frame({ AutomaticSize = q.Tween({ Value = Enum.AutomaticSize.X }) }) -- expect-error enum not tweenable
	local store = q.Store({ Username = q.Source("") })
	local _f = D.TextBox({ Text = store.Username, q.Out("Text", store.Username) })
	local valid: q.State<boolean> = store.Username:Compute(function(self: q.StateData<string>): boolean return #self:Get() > 0 end)
	local _g = D.TextButton({ Interactable = valid })
	local _h = D.Frame({ Size = q.Source(UDim2.new()):Apply(q.Animate({ Time = 0.2 })) })
end

-- ==== FILE probe.e7settings.luau
--!strict
-- simulates docs/getting-started/01-setup.md settings module (require paths relative for CLI)
local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local QuadTypes = require("../luau_packages/quad_types")
export type State<T> = QuadTypes.State<T>
export type Source<T> = QuadTypes.Source<T>
export type Slot<T> = QuadTypes.Slot<T>
export type StateData<T> = QuadTypes.StateData<T>
export type Provider<T> = QuadTypes.Provider<T>
export type Context = QuadTypes.Context
export type Ref<T> = QuadTypes.Ref<T>
export type Observer = QuadTypes.Observer
export type Effect = QuadTypes.Effect
return Quad:UseProvider(QuadRoblox)

-- ==== FILE probe.e7types.luau
--!strict
local q = require("./probe.e7settings")
local D = q.Declaration
local None = q.None

-- A: settings-module re-exports used by consumer code
local function _A()
	local count: q.Source<number> = q.Source(0)
	local isEven: q.State<boolean> = count:Compute(function(c: q.StateData<number>): boolean
		return c:Get() % 2 == 0
	end)
	local slot: q.Slot<Instance> = q.Slot<<Instance>>()
	local P: q.Provider<number> = q.Context.Provider<<number>>("n")
	local ctx: q.Context = q.Context():Set(P, 3)
	local r: q.Ref<Frame?> = q.Ref<<Frame?>>(nil)
	local o: q.Observer = count:Observer()
	local e: q.Effect = q.Effect(function() end, count)
	local bad: q.State<string> = count:Compute(function(c: q.StateData<number>): boolean return true end) -- expect-error A1 wrong derived type
	return isEven, slot, ctx, r, o, e, bad
end

-- B: how-to 01 §4 ModalDialog verbatim + covariance
local function ModalDialog(props: { read Title: string, read Children: q.Slot<Instance>? }): Frame
	return D.Frame({
		Size = UDim2.fromOffset(400, 300),
		D.TextLabel({ Text = props.Title }),
		D.Frame({ props.Children or None }),
	})
end
local function _B()
	local _a = ModalDialog({ Title = "t", Children = q.Slot<<Instance>>({ D.TextLabel({}) }) })
	local _b = ModalDialog({ Title = "t", Children = q.Slot<<TextLabel>>() }) -- B1 Slot<TextLabel> into Slot<Instance>? (doc silent)
	local _c = q.Slot<<Frame>>({ D.TextLabel({}) }) -- expect-error B2 TextLabel into Slot<Frame>
	local _d = D.Frame({ q.Slot<<TextLabel>>() }) -- B3 Slot<TextLabel> in children (covariant marker, should pass)
	local kids = { D.TextLabel({}) }
	local _e = D.Frame(kids) -- expect-error B4 doc: variable children table rejected
end

-- C: Slot:List updateFn return type
local function _C()
	local data = q.Source({ "a", "b" })
	local s = q.Slot<<TextLabel>>():List(data, function(ctx)
		return 42 -- C1 updateFn returns number into Slot<TextLabel> (any hole?)
	end)
	local s2 = q.Slot<<TextLabel>>():List(data, function(ctx)
		local x: number = ctx.Item -- expect-error C2 Item is string|KeyGone
		return nil
	end)
	return s, s2
end

-- E: Context
local function _E()
	local P = q.Context.Provider<<number>>("n")
	local c = q.Context()
	c:Set(P, "str") -- expect-error E1 wrong value type
	local v: number = c:Get(P)
	local w: string = c:Get(P) -- expect-error E2 Get infers number
	local p = c:Peek(P)
	local u: number = p -- expect-error E3 Peek is number?
	return v, w, u
end

-- F: Store reserved keys
local function _F()
	local s = q.Store({ hp = q.Source(1) })
	s.hp:Set("x") -- expect-error F1 Source<number>:Set string
	local _r = q.Store({ Of = 1 }) -- expect-error F2 reserved Of
	local _r2 = q.Store({ __x = 1 }) -- expect-error F3 reserved __ prefix
	local _r3 = q.Store({ Names = 1 }) -- expect-error F4 reserved Names
	local _ok = q.Store()
	return s
end

-- G: Tween arm only on interpolable types (Q34)
local function _G()
	local _a = D.Frame({ Size = q.Tween({ Value = UDim2.new(), Time = 0.3 }) })
	local _b = D.TextLabel({ Text = q.Tween({ Value = "hi" }) }) -- expect-error G1 string not tweenable
	local _c = D.Frame({ Name = q.Tween({ Value = "hi" }) }) -- expect-error G2 Name not tweenable
	local _d = D.Frame({ Size = q.Tween({ Value = 1 }) }) -- expect-error G3 Tween<number> into UDim2
	local _e = D.Frame({ Visible = q.Tween({ Value = true }) }) -- boolean tweenable per official list
end

-- H: Modifier setters and As cast
local function _H()
	local M = D.Modifier
	local _a = M.GuiObject():AsTextButton():Text("x")
	local _b = M.Frame():Text("x") -- expect-error H1 Frame has no Text
	local _c = M.Frame():Size("x") -- expect-error H2 Size string
	local _d = M.Frame():Size(q.Source(1)) -- expect-error H3 number State
	local _e = M.TextLabel():Text(q.Tween({ Value = "x" })) -- expect-error H4 tween on string setter
	local _f = D.TextLabel({ M.Frame():Visible(true) }) -- expect-error H5 Frame modifier onto TextLabel
end

-- I: Ref
local function _I()
	local r = q.Ref<<Frame?>>(nil)
	local f: Frame = r:Unwrap()
	local t: TextLabel = r:Unwrap() -- expect-error I1 Unwrap is Frame
	local _a = D.Frame({ r })
	local _b = D.TextLabel({ r }) -- expect-error I2 Ref<Frame?> in TextLabel children
	local pr = q.PreRef<<Frame?>>(nil)
	local _c = D.Frame({ pr })
	r:Set(D.TextLabel({})) -- expect-error I3 Set TextLabel
	return f, t
end

-- ==== FILE box2.luau (upstream minimal repro, no quad; luau-analyze 0.734 and luau-lsp 1.69.0 both flag only L8/L9)
--!strict
type Box<T> = { read V: T, Put: (self: Box<T>, v: T) -> () }
type Other = { Put: (self: Other, v: boolean) -> () }
local function G1(b: Box<number>?) end
local function G2(b: Box<number> | string) end
local x = (nil :: any) :: Box<string>
G1(x)        -- L7 Box<string>
G1(5)        -- L8 number
G1({})       -- L9 empty table
G1((nil :: any) :: Other) -- L10 unrelated recursive-method table
G2(x)        -- L11 union with string
local z: Box<number>? = x -- L12
return z
