--!nocheck
-- round13 E23 H — :List data State whose value is itself a State (nested data)
local H = require("./round13-e15-probe-setup")
local q, D = H.q, H.D
local function first(err) return (tostring(err):gsub("\n.*", ""):sub(1, 200)) end
local function kids(f) local t = {} for _, c in f:GetChildren() do table.insert(t, c.Name) end return table.concat(t, ",") end
local inner = q.Source({ "x", "y" })
local outer = q.Source(inner)
local sl = q.Slot()
local ok, err = pcall(function() sl:List(outer, function(ctx) return D.Frame { Name = tostring(ctx.Item) } end) end)
print("List(State<State<array>>)", ok, ok and "" or first(err))
local f
local ok2, err2 = pcall(function() f = D.Frame { sl } end)
print("mount", ok2, ok2 and "" or first(err2), f and kids(f))
local ok3, err3 = pcall(function() inner:Set({ "z" }) end)
print("inner:Set", ok3, ok3 and "" or first(err3), f and kids(f))
-- :Single with a State whose value is a State<Instance>
local s2 = q.Slot()
local ok4, err4 = pcall(function() s2:Single(q.Source(q.Source(D.Frame { Name = "single" }))) end)
local f2; pcall(function() f2 = D.Frame { s2 } end)
print("Single(State<State<Frame>>)", ok4, ok4 and "" or first(err4), f2 and kids(f2))
