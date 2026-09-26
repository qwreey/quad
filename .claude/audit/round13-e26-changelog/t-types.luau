--!strict
-- E26 type probe. `-- E:` expect an error, `-- OK:` expect none. One BREAKING line per block.
local q = require("./t-settings")
local QuadTypes = require("../../../quad-roblox/luau_packages/quad_types")
local D = q.Declaration

type Row = { id: string, label: string }

local function _legacy()
	local _a = D.Frame { Draggable = true } -- E:L1 legacy Draggable removed
	local _b = D.TextLabel { FontSize = Enum.FontSize.Size14 } -- OK:L2 allowlisted
	local _c = D.New("Frame")({ Draggable = true }) -- OK:L3 migration via D.New (props: any)
	local _d = q.Dispatch.drive(D.Frame {}, { Draggable = true } :: any) -- OK:L4 migration via drive + any
end

local function _parent()
	local _a = D.Frame { q.OnChange("Parent", function(p: Instance) print(p.Name) end) } -- E:P1 old annotation
	local _b = D.Frame { q.OnChange("Parent", function(p: Instance?) if p then print(p.Name) end end) } -- OK:P2
	local _c = D.Frame { q.OnChange("Parent", function(p) if p then print(p.Name) end end) } -- OK:P3 unannotated
	local _d = D.Frame { q.OnChange("Parent", function(p) print(p.Name) end) } -- E?:P4 unannotated, no nil check
	local _e = D.Frame { AncestryChanged = function(child: Instance, parent: Instance) print(parent.Name) end } -- E:P5 old event annotation
	local _f = D.Frame { AncestryChanged = function(child: Instance, parent: Instance?) end } -- OK:P6
end

local function _effect()
	local _a: QuadTypes.EffectHandle = q.Effect(function() end) -- E:F1 old type name
	local _b: q.Effect = q.Effect(function() end) -- OK:F2
	local _c: QuadTypes.EffectHandleMarker? = nil -- E:F3 old marker name
	local cleanup: () -> () = function() end
	local _d = q.Effect(function() return cleanup end) -- OK:F4 zero-arg cleanup still accepted
	local _e = q.Effect(function() return function(dying: boolean) end end) -- OK:F5
end

local function _slotLenOff()
	local s = q.Slot()
	local _a: q.Source<number> = s.Length -- E:S1 old annotation
	local _b: q.State<number> = s.Length -- OK:S2
	s.Offset:Set(3) -- E:S3 Set on read-only
	local _c = s.Length:Get() + s.Offset:Compute(function(o) return o:Get() * 2 end):Get() -- OK:S4
end

local function _updateFn(rows: q.State<{ Row }>)
	local s = q.Slot()
	s:List(rows, function(item: Row, index: number) return D.TextLabel { Text = item.label } end, function(r: Row) return r.id end) -- E:U1 old annotated positional
	s:List(rows, function(item, index, offset, prev, ud) return D.TextLabel { Text = item.label } end, function(r) return r.id end) -- E?:U2 old unannotated positional
	s:List(rows, function(ctx) if ctx.Item == q.KeyGone then return nil end return D.TextLabel { Text = ctx.Item.label, LayoutOrder = ctx.Index } end, function(r) return r.id end) -- OK:U3
	local cur = q.Source({ id = "x", label = "X" } :: Row?)
	local s2 = q.Slot()
	s2:Single(cur, function(item, offset, prev, ud) return D.TextLabel { Text = item.label } end) -- E?:U4 old Single positional
	s2:Single(cur, function(ctx) if ctx.Item == q.KeyGone then return nil end return D.TextLabel { Text = ctx.Item.label } end) -- OK:U5
	local _off: q.Source<number>? = nil
	s:List(rows, function(ctx) local o: q.Source<number> = ctx.Offset return nil end, function(r) return r.id end) -- E:U6 ctx.Offset as Source
end

local function _owned(rows: q.State<{ Row }>)
	local s = q.Slot()
	s:List(rows, function(ctx) return nil end, function(r) return r.id end, { Owned = false }) -- E?:O1 old key in strict
	s:List(rows, function(ctx) return nil end, function(r) return r.id end, { OwnsElements = false }) -- OK:O2
	local opts = { Owned = false }
	s:List(rows, function(ctx) return nil end, function(r) return r.id end, opts) -- E?:O3 old key via variable
end

local function _misc()
	local src = q.Source(1)
	local _w = src:With(q.Source(2)) -- E:M1 With
	local _d = src:Depend(q.Source(2)) -- OK:M2
	local b = q.Blocker()
	local _x = b:IsOn() -- E:M3
	local _y = b.IsBlocked -- E:M4
	local _z: boolean = b.Blocking -- OK:M5
	local t = q.Tag("a")
	for n in t:Names() do end -- E:M6
	for n in t do local _s: string = n end -- OK:M7
	local br = QuadTypes.Brand()
	br:register({}) -- E:M8
	br:Register({}) -- OK:M9
	local _st = q.Store({ __meta = q.Source(1) }) -- E:M10 reserved
	q.Dispatch.setLength({}, 1, 1) -- E:M11 moved
	q.Bookkeeping.setLength({}, 1, 1) -- OK:M12
	q.bindLifetime({}, {}) -- E:M13 moved
	q.Backend.bindLifetime({}, {}) -- OK:M14
end

local function _readFields()
	local r = q.Ref() :: q.Ref<number?>
	r.Value = 5 -- E:R1
	r:Set(5) -- OK:R2
	local e = q.Effect(function() end)
	e.Subscribed = false -- E:R3
	local b = q.Blocker()
	b.Blocking = true -- E:R4
	local s = q.Source(1)
	s.Revision = 3 -- E:R5
end

local function _provider()
	local pf = q.Context.Provider("F") :: q.Provider<Frame>
	local pn = q.Context.Provider("N") :: q.Provider<number>
	local _pi: q.Provider<Instance> = pf -- E:V1 invariance
	local _c = q.Context():Set(pn, "str") -- E:V2 wrong value type
	local _c2 = q.Context():Set(pn, 1) -- OK:V3
	local function takes(p: q.Provider<Instance>) end
	takes(pf) -- E:V4
end

local function _debounceTime()
	local _g = q.Debounce({ Time = "x" }) -- E:X1 (Fixed section — newly caught)
end
