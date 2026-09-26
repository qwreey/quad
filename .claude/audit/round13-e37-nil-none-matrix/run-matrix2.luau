--!nocheck
-- E37 follow-up probe: mounted variants + corrected call shapes
local H = require("./harness")
local q, D, None = H.q, H.D, H.None
UDim2 = H.EG.UDim2; Color3 = H.EG.Color3; Enum = H.EG.Enum; UDim = H.EG.UDim
local CS = H.CollectionService
local function show(v) if v == nil then return "nil" elseif v == None then return "None" end return tostring(v) end
local function try(label, fn)
	local ok, err = pcall(fn)
	if ok then print(label .. " | ok" .. (err ~= nil and (" -> " .. tostring(err)) or ""))
	else print(label .. " | THROW " .. H.first(err)) end
end
local function kids(inst) local t = {}; for _, c in inst:GetChildren() do table.insert(t, c.ClassName) end return "[" .. table.concat(t, ",") .. "]" end
local function tags(inst) local t = CS:GetTags(inst); table.sort(t); return "{" .. table.concat(t, ",") .. "}" end
local function attrs(inst) local t = {}; for k, v in inst:GetAttributes() do table.insert(t, k .. "=" .. show(v)) end table.sort(t) return "{" .. table.concat(t, ",") .. "}" end

try("SL4m q.Slot{a,nil,b} mounted", function() local a, b = D.Frame{}, D.TextLabel{}; local sl = q.Slot { a, nil, b }; local f = D.Frame { sl }; return "Length=" .. show(sl.Length:Get()) .. kids(f) .. " b.Parent=" .. show(b.Parent) end)
try("SL4u q.Slot{a} unmounted Length", function() local sl = q.Slot { D.Frame{} }; return "Length=" .. show(sl.Length:Get()) end)
try("SL7d :List data nil mounted", function() local data = q.Source(nil); local sl = q.Slot(); sl:List(data, function(ctx) return D.Frame{} end); D.Frame { sl }; return "len=" .. sl.Length:Get() end)
try("SL7e :List data None mounted", function() local data = q.Source(None); local sl = q.Slot(); sl:List(data, function(ctx) return D.Frame{} end); D.Frame { sl }; return "len=" .. sl.Length:Get() end)
try("SL7f :List data {a} -> nil mounted", function() local data = q.Source({"a"}); local sl = q.Slot(); sl:List(data, function(ctx) return ctx.Prev or D.Frame{} end); D.Frame { sl }; data:Set(nil); return "len=" .. sl.Length:Get() end)
try("SL7g :List keyFn returns nil", function() local data = q.Source({"a"}); local sl = q.Slot(); sl:List(data, function(ctx) return D.Frame{} end, function() return nil end); D.Frame { sl } end)
try("SL7h :List item nil hole in data", function() local data = q.Source({"a", nil, "c"}); local sl = q.Slot(); sl:List(data, function(ctx) return ctx.Prev or D.Frame{} end); D.Frame { sl }; return "len=" .. sl.Length:Get() end)
try("SL7i :List item None in data", function() local data = q.Source({"a", None}); local seen = {}; local sl = q.Slot(); sl:List(data, function(ctx) table.insert(seen, show(ctx.Item)); return ctx.Prev or D.Frame{} end); D.Frame { sl }; return "len=" .. sl.Length:Get() .. " items=" .. table.concat(seen, ",") end)
try("SL6m :Single data None initially mounted", function() local s = q.Source(None); local sl = q.Slot(); sl:Single(s); local f = D.Frame { sl }; return "len=" .. sl.Length:Get() end)
try("SL5m slot:Add(State<Instance?>) nil->c->nil (mounted, check destroy)", function()
	local s = q.Source(nil); local sl = q.Slot{}; local f = D.Frame { sl }; sl:Add(s); local c = D.TextLabel{}; s:Set(c); local a = kids(f); s:Set(nil); return a .. " -> " .. kids(f) .. " claimed=" .. tostring(q.Backend.isClaimed(c)) end)
try("M3 transform returns nil (same modifier, plain)", function() local l = D.TextLabel { q.Modifier():Text("a"):Text(function(old) return nil end) }; return "Text=" .. show(l.Text) end)
try("M3a earlier modifier + transform nil in later", function() local l = D.TextLabel { q.Modifier():Text("prev"), q.Modifier():Text("a"):Text(function(old) return nil end) }; return "Text=" .. show(l.Text) end)
try("M3b transform returns nil (same modifier, State old)", function() local l = D.TextLabel { q.Modifier():Text("prev"), q.Modifier():Text(q.Source("a")):Text(function(old) return nil end) }; return "Text=" .. show(l.Text) end)
try("M3c transform returns None", function() local l = D.TextLabel { q.Modifier():Text("prev"), q.Modifier():Text("a"):Text(function(old) return None end) }; return "Text=" .. show(l.Text) end)
try("M4 mod field State -> nil / None", function() local s = q.Source("a"); local l = D.TextLabel { q.Modifier():Text(s) }; s:Set(nil); local a = show(l.Text); s:Set(None); return a .. " / " .. show(l.Text) end)
try("M5 two mods, later field State -> nil: falls back to earlier?", function() local s = q.Source("b"); local l = D.TextLabel { q.Modifier():Text("a"), q.Modifier():Text(s) }; s:Set(nil); return "Text=" .. show(l.Text) end)
try("M6 mod state:Apply(Animate) emits nil", function() local s = q.Source(0.2); local l = D.TextLabel { q.Modifier():TextTransparency(s:Apply(q.Animate{Time=1})) }; s:Set(nil); return show(l.TextTransparency) end)
local Op = q.Operator
try("OP3 Not None", function() local s = q.Source(None); return show(s:Apply(Op.Not):Get()) end)
try("OP4 Not nil", function() local s = q.Source(nil); return show(s:Apply(Op.Not):Get()) end)
try("OP5 Indexed None", function() local s = q.Source(None); return show(s:Apply(Op.Indexed("x")):Get()) end)
try("OP6 Sum None", function() local s = q.Source(None); return show(s:Apply(Op.Sum(1)):Get()) end)
try("P12 Animate first value then None then value (snap vs animate)", function()
	local s = q.Source(0.5); local l = D.TextLabel { TextTransparency = s:Apply(q.Animate{Time=1}) }; s:Set(None); s:Set(0.1); local a = show(l.TextTransparency); H.runTask(2); return "immediately=" .. a .. " after=" .. show(l.TextTransparency) end)
try("P10d' Animate initially nil then 0.3 after runTask", function()
	local s = q.Source(nil); local l = D.TextLabel { TextTransparency = s:Apply(q.Animate { Time = 1 }) }; s:Set(0.3); H.runTask(2); return show(l.TextTransparency) end)
try("P13 Source initially nil non-Animate then value (snap)", function()
	local s = q.Source(nil); local l = D.TextLabel { TextTransparency = s }; s:Set(q.Tween{Value=0.3, Time=1}); return "immediately=" .. show(l.TextTransparency) end)
try("P14 Text literal nil + later State seat? (literal nil: handler never runs)", function() local l = D.TextLabel { Text = nil }; return "Text raw=" .. show(l.Text) end)
try("C5b State<Tag> initially nil", function() local s = q.Source(nil); local f = D.Frame { s }; s:Set(q.Tag("A")); return tags(f) end)
try("C6b State<Attr> -> None", function() local s = q.Source(q.Attr { A = 1 }); local f = D.Frame { s }; s:Set(None); return attrs(f) end)
try("C6c q.Attr State -> Attr swap: old name left?", function() local s = q.Source(q.Attr { A = 1 }); local f = D.Frame { s }; s:Set(q.Attr { B = 2 }); return attrs(f) end)
try("C5c State<Tag> swap A -> B", function() local s = q.Source(q.Tag("A")); local f = D.Frame { s }; s:Set(q.Tag("B")); return tags(f) end)
try("C8 seat State<Instance> None->c: destroy on replace?", function() local c1 = D.TextLabel{}; local s = q.Source(c1); local f = D.Frame { s }; s:Set(D.Frame{}); return "c1 claimed=" .. tostring(q.Backend.isClaimed(c1)) .. " c1.Parent=" .. show(c1.Parent) end)
try("CX5 ctx:Set(p, None) then Get in consumer", function() local P = q.Context.Provider("P"); local c = q.Context():Set(P, None); return show(c:Get(P)) .. " peek=" .. show(c:Peek(P)) end)
try("R4 PreRef in seat retract -> Set(nil)?", function() local r = q.PreRef(nil); local s = q.Source(r); local f = D.Frame { s }; local a = show(r.Value); s:Set(nil); return a .. " -> " .. show(r.Value) end)
try("E4 Event literal nil", function() local b = D.TextButton { Activated = nil }; return "ok" end)
try("S7 UIPadding None", function() local f = D.Frame { UIPadding = None }; return kids(f) end)
try("S8 UIScale State nil", function() local s = q.Source(2); local f = D.Frame { UIScale = s }; s:Set(nil); return kids(f) end)
