--!nocheck
local H = require("./harness")
local q, D = H.q, H.D
local function try(label, f)
	local ok, r = pcall(f)
	print(label, ok and "ok" or "ERR", ok and tostring(r) or H.first(r))
end
q.Modifier.DefineSubtype("E46Clickable", "E46Card") -- before TypedFactory: order-free
q.Modifier.DefineSubtype("GuiObject", "E46Card")    -- second parent
local Card = q.Modifier.TypedFactory("E46Card")
local Clickable = q.Modifier.TypedFactory("E46Clickable")
try("R1 Clickable:AsE46Card", function() return tostring(Clickable():AsE46Card()) end)
try("R2 GuiObject:AsE46Card (2nd parent)", function() return tostring(D.Modifier.GuiObject():AsE46Card()) end)
try("R3 Instance:AsE46Card (via GuiObject path)", function() return tostring(D.Modifier.Instance():AsE46Card()) end)
try("R4 Frame:AsE46Card (sibling)", function() return tostring(D.Modifier.Frame():AsE46Card()) end)
try("R5 Card:AsE46Clickable (upcast)", function() return tostring(Card():AsE46Clickable()) end)
try("R6 cycle", function() q.Modifier.DefineSubtype("E46Card", "E46Clickable") end)
try("R7 self edge", function() q.Modifier.DefineSubtype("E46Card", "E46Card") end)
try("R8 dup edge no-op", function() q.Modifier.DefineSubtype("E46Clickable", "E46Card"); return "ok" end)
try("R9 dedup ctor", function() return rawequal(Card, q.Modifier.TypedFactory("E46Card")) end)
try("R10 DefineSubtype-only name then As(name)", function() q.Modifier.DefineSubtype("E46X", "E46Y"); return tostring(q.Modifier():As("E46Y")) end)
try("R11 DefineSubtype-only name then TypedFactory", function() return tostring(q.Modifier.TypedFactory("E46Y")()) end)
