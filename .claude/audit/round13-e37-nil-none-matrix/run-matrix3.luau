--!nocheck
local H = require("./harness")
local q, D, None = H.q, H.D, H.None
local function show(v) if v == nil then return "nil" elseif v == None then return "None" end return tostring(v) end
local function try(label, fn)
	local ok, err = pcall(fn)
	if ok then print(label .. " | ok" .. (err ~= nil and (" -> " .. tostring(err)) or ""))
	else print(label .. " | THROW " .. H.first(err)) end
end
try("L1 :List data {a,b,c} -> {a,nil,c}: c destroyed?", function()
	local data = q.Source({ "a", "b", "c" }); local sl = q.Slot(); local made = {}
	sl:List(data, function(ctx) if ctx.Item == q.KeyGone then return nil end local e = ctx.Prev or D.TextLabel { Text = ctx.Item }; made[ctx.Item] = e; return e end)
	D.Frame { sl }; data:Set({ "a", nil, "c" }); return "len=" .. sl.Length:Get() .. " c.claimed=" .. tostring(q.Backend.isClaimed(made.c)) end)
try("OC1 State<OnChange desc> -> None / nil", function()
	local n = 0; local desc = q.OnChange("Text", function() n += 1 end); local s = q.Source(desc)
	local tb = D.TextBox { s }; tb.Text = "1"; s:Set(None); tb.Text = "2"; s:Set(desc); tb.Text = "3"; s:Set(nil); tb.Text = "4"; return "calls=" .. n end)
try("OB1 State<Observer?> -> nil stops", function()
	local src = q.Source(0); local n = 0; local ob = src:Observer(function() n += 1 end); local s = q.Source(ob)
	D.Frame { s }; local a = n; src:Set(1); local b = n; s:Set(nil); src:Set(2); return a .. "," .. b .. "," .. n end)
try("EF1 State<Effect?> -> nil cleanup once", function()
	local src = q.Source(0); local cl = 0; local ef = q.Effect(function() src:Get(); return function() cl += 1 end end, src); local s = q.Source(ef)
	D.Frame { s }; s:Set(nil); src:Set(1); return "cleanups=" .. cl end)
try("TW1 State<Tween> -> None writes nil & cancels", function()
	H.task.spawn(function() end)
	local s = q.Source(q.Tween { Value = 0.5, Time = 1 }); local l = D.TextLabel { TextTransparency = s }; s:Set(q.Tween { Value = 0.9, Time = 1 }); s:Set(None); return "val=" .. show(l.TextTransparency) end)
try("IX1 Indexed missing key into Text (Apply unchecked) runtime", function()
	local t = q.Source({ A = "x" }); local l = D.TextLabel { Text = t:Apply(q.Operator.Indexed("B")) }; return "Text=" .. show(l.Text) end)
try("AN1 Animate running tween then nil: Cancelled fires?", function()
	local s = q.Source(0.5); local st, co, ca = 0, 0, 0
	local l = D.TextLabel { TextTransparency = s:Apply(q.Animate { Time = 1, Started = function() st += 1 end, Completed = function() co += 1 end, Cancelled = function() ca += 1 end }) }
	s:Set(0.9); local a = `after 0.9: S{st} C{co} X{ca}`; s:Set(nil); return a .. ` | after nil: S{st} C{co} X{ca} val={show(l.TextTransparency)}` end)
try("AN2 Tween-in-State running then None: Cancelled fires?", function()
	local ca = 0; local s = q.Source(q.Tween { Value = 0.5 }); local l = D.TextLabel { TextTransparency = s }
	s:Set(q.Tween { Value = 0.9, Time = 1, Cancelled = function() ca += 1 end }); s:Set(None); return "X=" .. ca end)
