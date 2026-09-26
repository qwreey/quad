--!nocheck
-- round13 E23 C — failed outer transition leaves the old inner State driving the slot (ghost?)
local H = require("./round13-e15-probe-setup")
local q, D, mock = H.q, H.D, H.mock
local function first(err) return (tostring(err):gsub("\n.*", ""):gsub("^.-(Quad%d%d%d%d)", "%1")) end
local function kids(f) local t = {} for _, c in f:GetChildren() do table.insert(t, c.Name) end return table.concat(t, ",") end
local function sec(name, fn) print("=== " .. name .. " ==="); local ok, err = pcall(fn); if not ok then print("  !! section error:", first(err)) end end

sec("C1 numeric key: outer State<State<Inst>> -> 'text' throws; inner still drives?", function()
	local inner = q.Source(D.Frame { Name = "i1" })
	local outer = q.Source(inner)
	local f = D.Frame { Name = "host", outer }
	print("  kids", kids(f))
	local ok, err = pcall(function() outer:Set("text") end)
	print("  outer:Set('text')", ok, ok and "" or first(err), "kids", kids(f), "outer:Get()", tostring(outer:Get()))
	inner:Set(D.Frame { Name = "i2" })
	print("  inner:Set(i2) after failed outer -> kids", kids(f))
	local ok2, err2 = pcall(function() outer:Set(q.None) end)
	print("  outer:Set(None)", ok2, ok2 and "" or first(err2), "kids", kids(f))
	inner:Set(D.Frame { Name = "i3" })
	print("  inner:Set(i3) after outer None -> kids", kids(f))
end)

sec("C2 string key: outer State<State<string>> at Text -> Slot throws?", function()
	local inner = q.Source("in1")
	local outer = q.Source(inner)
	local l = D.TextLabel { Text = outer }
	local ok, err = pcall(function() outer:Set(q.Slot {}) end)
	print("  outer:Set(Slot)", ok, ok and "" or first(err), "Text", tostring(l.Text))
	inner:Set("in2")
	print("  inner:Set('in2') -> Text", tostring(l.Text))
	local ok3, err3 = pcall(function() outer:Set(q.PreRef()) end)
	print("  outer:Set(PreRef)", ok3, ok3 and "" or first(err3), "Text", tostring(l.Text))
end)

sec("C3 Attr group value State<State<number>>", function()
	local inner = q.Source(1)
	local outer = q.Source(inner)
	local f = D.Frame { q.Attr({ Hp = outer }) }
	print("  Hp", tostring(mock.getAttributes(f).Hp))
	inner:Set(2); print("  inner=2 Hp", tostring(mock.getAttributes(f).Hp))
	local other = q.Source(9); outer:Set(other); print("  outer->other Hp", tostring(mock.getAttributes(f).Hp))
	inner:Set(3); print("  old inner=3 Hp (ghost?)", tostring(mock.getAttributes(f).Hp))
	outer:Set(q.None); print("  outer None Hp", tostring(mock.getAttributes(f).Hp))
	local ok, err = pcall(function() outer:Set({}) end)
	print("  outer:Set({}) table", ok, ok and "" or first(err), "Hp", tostring(mock.getAttributes(f).Hp))
	local ok2, err2 = pcall(function() outer:Set(outer) end)
	print("  outer:Set(outer) cycle", ok2, ok2 and "" or first(err2))
end)

sec("C4 AttrKey single key State<State>", function()
	local inner = q.Source("a")
	local outer = q.Source(inner)
	local f = D.Frame { [q.AttrKey("K")] = outer }
	print("  K", tostring(mock.getAttributes(f).K))
	inner:Set("b"); print("  inner=b K", tostring(mock.getAttributes(f).K))
end)

sec("C5 State<Attr> where the Attr's value is State<State>", function()
	local inner = q.Source(1)
	local mid = q.Source(inner)
	local ga = q.Source(q.Attr({ X = mid }))
	local f = D.Frame { ga }
	print("  X", tostring(mock.getAttributes(f).X))
	inner:Set(5); print("  inner=5 X", tostring(mock.getAttributes(f).X))
	ga:Set(q.Attr({ Y = 1 })); print("  ga->Attr{Y} X,Y", tostring(mock.getAttributes(f).X), tostring(mock.getAttributes(f).Y))
	inner:Set(6); print("  inner=6 after swap X", tostring(mock.getAttributes(f).X))
end)

sec("C6 Modifier field State<State>", function()
	local inner = q.Source("m1")
	local outer = q.Source(inner)
	local mod = q.Modifier({ Text = outer })
	local l = D.TextLabel { mod }
	print("  Text", l.Text)
	inner:Set("m2"); print("  inner=m2 Text", l.Text)
	outer:Set(q.Source("m3")); print("  outer swap Text", l.Text)
	inner:Set("ghost"); print("  old inner Set Text", l.Text)
	local ok, err = pcall(function() return q.Modifier({ Text = q.Source(q.Source(q.Modifier({}))) }) end)
	print("  Modifier{Text=Source(Source(Modifier))}", ok, ok and "" or first(err))
end)

sec("C7 Slot element State<State<Frame>>", function()
	local a = D.Frame { Name = "a" }
	local inner = q.Source(a)
	local outer = q.Source(inner)
	local sl = q.Slot { outer }
	local f = D.Frame { Name = "host", sl }
	print("  kids", kids(f), "Length", sl.Length:Get())
	inner:Set(D.Frame { Name = "b" }); print("  inner->b kids", kids(f), "Length", sl.Length:Get())
	local inner2 = q.Source(D.Frame { Name = "c" })
	outer:Set(inner2); print("  outer->inner2 kids", kids(f), "Length", sl.Length:Get())
	inner:Set(D.Frame { Name = "ghost" }); print("  old inner Set kids", kids(f))
	outer:Set(q.None); print("  outer None kids", kids(f), "Length", sl.Length:Get())
	outer:Set(inner2); print("  outer->inner2 again kids", kids(f), "Length", sl.Length:Get())
	local ok, err = pcall(function() outer:Set(outer) end)
	print("  outer:Set(outer) in Slot", ok, ok and "" or first(err), "kids", kids(f))
	local ok2, err2 = pcall(function() outer:Set(D.Frame { Name = "d" }) end)
	print("  recover outer:Set(d)", ok2, ok2 and "" or first(err2), "kids", kids(f), "Length", sl.Length:Get())
end)

sec("C8 Slot element: outer State -> 'text' (non-mountable)", function()
	local inner = q.Source(D.Frame { Name = "x" })
	local outer = q.Source(inner)
	local sl = q.Slot { outer }
	local f = D.Frame { Name = "host", sl }
	local ok, err = pcall(function() outer:Set("text") end)
	print("  outer:Set('text')", ok, ok and "" or first(err), "kids", kids(f), "Length", sl.Length:Get())
	inner:Set(D.Frame { Name = "y" }); print("  inner->y", kids(f))
	local ok2, err2 = pcall(function() outer:Set(D.Frame { Name = "z" }) end)
	print("  recover", ok2, ok2 and "" or first(err2), kids(f), "Length", sl.Length:Get())
end)

sec("C9 Slot:Add(State) pre-pass with State<State>: value inner is already-held", function()
	local a = D.Frame { Name = "a" }
	local sl = q.Slot { a }
	local f = D.Frame { Name = "host", sl }
	local ok, err = pcall(function() sl:Add(q.Source(q.Source(a))) end)
	print("  Add(Source(Source(a))) where a already in Slot", ok, ok and "" or first(err), "kids", kids(f), "Length", sl.Length:Get())
	local ok2, err2 = pcall(function() sl:Add(q.Source(a)) end)
	print("  Add(Source(a)) (single level)", ok2, ok2 and "" or first(err2))
end)
