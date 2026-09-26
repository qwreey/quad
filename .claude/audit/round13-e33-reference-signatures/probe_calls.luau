--!strict
-- E33 call-shape probe: the generic-function items whose bidirectional assignment the new solver
-- cannot decide (expected/got print identically — generic function subtyping limit) are exercised
-- by calling them the way the doc signature says. Lines tagged EXPECT-ERR must produce a diagnostic;
-- every other line must be clean.
local QT = require("../../../quad-roblox/luau_packages/quad_types")
local QRmod = require("../../../quad-roblox/src")
type Source<T> = QT.Source<T>
type State<T> = QT.State<T>
local q: QT.Quad & QRmod.RobloxExtension = nil :: any
local frame: Frame = nil :: any

-- [2][3] AddPlugin/UseProvider: Self & P
local q2 = q:AddPlugin(function(_self) return { Foo = 1 } end)
local _p1: number = q2.Foo
local _p2: Source<number> = q2.Source(1)
local q3 = q:UseProvider(function(_self) return { Bar = "x" } end)
local _p3: string = q3.Bar
-- [9] Source
local s1: Source<number> = q.Source(1)
local s2: Source<number?> = q.Source(nil :: number?)
local _s3: Source<string> = q.Source(1) -- EXPECT-ERR
-- [19] Store overloads
local st0: QT.Store<{}> = q.Store()
local st1 = q.Store({ hp = q.Source(100) })
local _st2: Source<number> = st1.hp
local _st3: Source<string> = st1:Of("name")
local _st4: { string } = st0:Names()
-- [33] Slot
local sl: QT.Slot<Instance> = q.Slot({ frame :: Instance })
local _sl2: QT.Slot<Instance> = q.Slot({ q.Source(frame) :: any })
local _sl3: QT.Slot<Instance> = q.Slot()
local _sl4 = q.Slot({ 1 :: any })
-- [48] Single with updateFn(ctx)
sl:Single(s1, function(ctx)
	local _i: number | QT.KeyGone = ctx.Item
	local _o: State<number> = ctx.Offset
	return frame, nil
end)
sl:Single(frame) -- identity form
-- [47] List with keyFn/opts
sl:List({ 1, 2 }, function(ctx) return frame, ctx.UserData end, function(item, i) return item end, { OwnsElements = false })
-- [52][53][54] Ref / Unwrap(StripNil)
local r1: QT.Ref<Frame?> = q.Ref(nil :: Frame?)
local _u: Frame = r1:Unwrap()
local _pr: QT.PreRef<number> = q.PreRef(1)
local _po: QT.PostRef<number> = q.PostRef(1)
-- [66] Peek
local md = q.Modifier({ X = 1 })
local _pk: QT.FieldOut<number>? = md:Peek("X")
-- [151] Alternative / [152] Indexed
local maybe: Source<number?> = q.Source(nil :: number?)
local _alt: State<number> = maybe:Apply(q.Operator.Alternative(0))
local tbl: Source<{ k: number }> = q.Source({ k = 1 })
local _ix: State<number> = tbl:Apply(q.Operator.Indexed("k"))
-- [157][158] hooks
local _oc: QT.PreRef<Frame?> = q.OnCreated(function(inst: Frame, ref) local _: QT.PreRef<Frame?> = ref end)
local _or: QT.PostRef<Frame?> = q.OnRendered(function(inst: Frame, ref) local _: QT.PostRef<Frame?> = ref end)
-- [160][161] Fallback/Traceback
local fb = q.Fallback(function(a: number): string return tostring(a) end, function(_err) return 0 end)
local _fbr: string | number = fb(1)
local tb = q.Traceback(function(a: number): string return tostring(a) end, function(_err, trace: string) return trace end)
local _tbr: string = tb(1)
-- [127][128] OnChange / Out
local _oc2 = q.OnChange("Size", function(v: UDim2) end)
local _out = q.Out("Size", q.Source(UDim2.new()))
local _outBad = q.Out("Size", q.Source(1):Compute(function() return UDim2.new() end)) -- EXPECT-ERR (doc: :Compute State rejected)
-- [74] Tag: doc `...TagNames` (no nil) vs prose "nil 인자는 없음"
local _t1 = q.Tag("Card", nil)
local tg = q.Tag("A")
local _t2 = q.Tag.Merged(tg, nil)
-- [85] AttrKeyObject: doc `{ Name: string }` (writable) vs real `{ read Name: string }`
local k = q.AttrKey("Hp")
k.Name = "Mp" -- EXPECT-ERR per real type; doc type would allow it
-- [133] q.Context() takes no args
local _cx = q.Context()
local _cx2 = q.Context("name") -- EXPECT-ERR
-- [155] handle is GateHandle (Ref<GateHandle?>)
local h: QT.Ref<QT.GateHandle?> = q.Ref(nil :: QT.GateHandle?)
local _db = q.Debounce({ Time = 0.1, Handle = h })
local _dbBad = q.Debounce({ Time = "x" }) -- EXPECT-ERR (doc: Time number | State<number>)
-- [120] D.New
local _nw: Frame = q.Declaration.New("Frame")({ Size = UDim2.new() })
-- [124] Claim returns T
local _cl: Frame = q.Claim(frame, q.Declaration.Mapper.Frame(q.MapperRoot)({}))
return nil
