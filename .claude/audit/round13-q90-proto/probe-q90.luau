-- P-Q90 probe (scratch copy only): subject per call surface + new tails + Quad0076 hint arms
local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local installProperty = require("../src/Handlers/Property")
local installEvent = require("../src/Handlers/Event")
local mock = require("../../quad-base/test/mock")
local Instance = mock.Instance
local W = { Write = "" }
local REFLECTED = {
	Frame = { { Name = "Name", Permits = W }, { Name = "Size", Permits = W }, { Name = "Visible", Permits = W }, { Name = "Parent", Permits = W }, { Name = "AbsoluteSize", Permits = {} } },
	TextLabel = { { Name = "Name", Permits = W }, { Name = "Text", Permits = W } },
}
local gameShim = mock.gameShim(REFLECTED)
local q: any = Quad.New():UseProvider(QuadRoblox)
;(getfenv(installProperty) :: any).game = gameShim
;(getfenv(installEvent) :: any).game = gameShim
;(getfenv(q.Declaration.New) :: any).Instance = { new = mock.Instance.new }
q.Backend.isInst = mock.isMockInstance
local D, M = q.Declaration, q.Declaration.Mapper

local function show(label: string, fn: () -> ())
	local ok, err = pcall(fn)
	if ok then print(`[{label}] NO ERROR`); return end
	local s = tostring(err)
	local id, subj = string.match(s, "(Quad%d%d%d%d) ([^:]+:?[^:]*):")
	local head = string.match(s, "(Quad%d%d%d%d .-)$") or s
	local blame = string.match(s, "^([^:]+:%d+):") or "?"
	print(`[{label}] blame={blame} | {string.sub(head, 1, 150)}`)
end
local function claimed(cls: string) local i = Instance.new(cls); q.Backend.nativeClaim(i); return i end

print("--- Quad0160 (already mounted elsewhere)")
do
	local c = D.TextLabel({}); D.Frame({ c })
	show("160 D.Frame{c} again", function() D.Frame({ c }) end)
	local c2 = D.TextLabel({})
	show("160 D.Frame{c2,c2}", function() D.Frame({ c2, c2 }) end)
	local e = D.TextLabel({}); local _s = q.Slot({ e })
	show("160 Slot element into D.Frame", function() D.Frame({ e }) end)
	local s = q.Slot(); D.Frame({ s })
	show("160 same Slot mounted twice (D.Frame{s})", function() D.Frame({ s }) end)
	local f = D.Frame({})
	show("160 Dispatch.drive(f,{c})", function() q.Dispatch.drive(f, { c }) end)
	local root = Instance.new("Frame")
	show("160 Claim(root, M.Frame(M.Root)({c}))", function() q.Claim(root, M.Frame(M.Root)({ c })) end)
	local seat = q.Source(nil :: any); D.Frame({ seat })
	show("160 seat:Set(c) (State swap)", function() seat:Set(c) end)
	show("160 q.Bookkeeping.claimOwnerAt direct", function() q.Bookkeeping.claimOwnerAt(c, D.Frame({}), 1) end)
	local st = q.Source(s)
	show("160 State<Slot> into second host", function() D.Frame({ st }) end)
end
print("--- Quad0219 (not claimed)")
do
	show("219 D.Frame{foreign}", function() D.Frame({ Instance.new("TextLabel") }) end)
	show("219 Dispatch.drive(f,{foreign})", function() q.Dispatch.drive(D.Frame({}), { Instance.new("TextLabel") }) end)
	local seat = q.Source(nil :: any); D.Frame({ seat })
	show("219 seat:Set(foreign)", function() seat:Set(Instance.new("TextLabel")) end)
	show("219 Claim children foreign", function() q.Claim(Instance.new("Frame"), M.Frame(M.Root)({ Instance.new("TextLabel") })) end)
end
print("--- Quad0220 (cycle)")
do
	local host = D.Frame({}); local seat = q.Source(nil :: any); local f = D.Frame({ seat }); f.Parent = host
	show("220 seat:Set(f) self", function() seat:Set(f) end)
	show("220 seat:Set(host) ancestor", function() seat:Set(host) end)
	show("220 Dispatch.drive(f,{host})", function() q.Dispatch.drive(f, { host }) end)
end
print("--- Quad0165~0167 (Slot gates)")
do
	local parent = q.Slot(); local child = q.Slot(); parent:Add(child); parent:Remove(1) -- destroys child
	for _, m in { "Add", "Clear", "Move", "ExtractAll" } do
		show(`165 destroyed :{m}`, function() if m == "Add" then child:Add(D.TextLabel({})) elseif m == "Move" then child:Move(1, 1) else (child :: any)[m](child) end end)
	end
	show("165 destroyed :List", function() child:List({}, function(x) return x end) end)
	show("165 destroyed :Single", function() child:Single(q.Source(1), function(x) return D.TextLabel({}) end) end)
	local listed = q.Slot(); listed:List({}, function(x) return x end)
	show("166 :Add after :List", function() listed:Add(D.TextLabel({})) end)
	show("166 :Swap after :List", function() listed:Swap(1, 1) end)
	-- 167: an updateFn that CRUDs the ancestor mid-mount
	local outer = q.Slot()
	local inner = q.Slot()
	inner:List({ 1 }, function(_x) outer:Add(D.TextLabel({})); return D.TextLabel({}) end)
	outer:Add(inner)
	show("167 ancestor :Add mid-mount", function() D.Frame({ outer }) end)
	local outer2 = q.Slot(); local inner2 = q.Slot(); outer2:Add(inner2)
	inner2:List({ 1 }, function(_x) outer2:Clear(); return D.TextLabel({}) end)
	show("167 ancestor :Clear mid-mount", function() D.Frame({ outer2 }) end)
end
print("--- ⑤⑥ tails")
show("094 Effect(5)", function() q.Effect(5) end)
show("187 :Compute(5)", function() q.Source(1):Compute(5) end)
show("188 :Gate(5)", function() q.Source(1):Gate(5) end)
show("190 :Observer(5)", function() q.Source(1):Observer(5) end)
show("191 :Apply({})", function() q.Source(1):Apply({}) end)
show("243 Tween Time='x'", function() q.Tween({ Value = 1, Time = "x" }) end)
show("244 Tween Reverses=1", function() q.Tween({ Value = 1, Reverses = 1 }) end)
show("245 Tween Dedup='x'", function() q.Tween({ Value = 1, Dedup = "x" }) end)
show("246 Tween Completed=1", function() q.Tween({ Value = 1, Completed = 1 }) end)
show("041 Debounce Time=-1", function() q.Debounce({ Time = -1 }) end)
show("041 Debounce Time=0/0", function() q.Debounce({ Time = 0 / 0 }) end)
show("041 Debounce Time='x'", function() q.Debounce({ Time = "x" }) end)
do
	local t = q.Source(0.1); local src = q.Source(0)
	local d = src:Apply(q.Debounce({ Time = t })); d:Observer(function() end)
	t:Set(-2)
	show("039 Debounce State Time -2 at emit", function() src:Set(1) end)
end
show("216 setTimeout(-1)", function() q.Backend.setTimeout(function() end, -1) end)
show("216 setTimeout('x')", function() q.Backend.setTimeout(function() end, "x" :: any) end)
print("--- Quad0076 hint arms")
show("076 size=5 (case typo)", function() D.Frame({ size = 5 } :: any) end)
show("076 AbsoluteSize (read-only)", function() D.Frame({ AbsoluteSize = 5 } :: any) end)
show("076 Text on Frame (other class)", function() D.Frame({ Text = "x" } :: any) end)
show("076 Parent", function() D.Frame({ Parent = D.Frame({}) } :: any) end)
show("076 method name Destroy", function() D.Frame({ Destroy = function() end } :: any) end)
show("076 numeric key unbranded 5", function() D.Frame({ 5 } :: any) end)
show("076 Tag at string key (base brand)", function() D.Frame({ X = q.Tag("a") } :: any) end)
show("076 Modifier setter typo", function() D.Frame({ q.Modifier():size(5) } :: any) end)
do
	local qb: any = mock.newQuad()
	local f = Instance.new("Frame")
	show("076 base-only quad Size=5 (no provider handlers)", function() qb.Dispatch.drive(f, { Size = 5 }) end)
end
show("076 base-only Dispatch.process(f,'Size',5)", function() local qb: any = mock.newQuad(); qb.Dispatch.process(Instance.new("Frame"), "Size", 5, 1) end)
show("076 Ref at key Ref (doc core/07:61, how-to 10:105)", function() D.Frame({ Ref = q.Ref() } :: any) end)
show("076 Parent=Instance (GS 02:72)", function() D.TextLabel({ Parent = Instance.new("Frame") } :: any) end)
show("076 key 1 boolean (how-to 08:229)", function() D.Frame({ true } :: any) end)
show("076? Ref at key X", function() D.Frame({ X = q.Ref() } :: any) end)
