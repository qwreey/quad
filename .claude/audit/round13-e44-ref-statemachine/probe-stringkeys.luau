--!nocheck
local H = require("./harness")
local q, D = H.q, H.D
local function id(e) local s = tostring(e); return s:match("Quad%d%d%d%d") or ("RAW:" .. H.first(e)) end
local function try(label, f) local ok, e = pcall(f); print(label, ok and "ok (no error)" or (id(e) .. "  | " .. H.first(e))) end
for _, kind in { "Ref", "PreRef", "PostRef" } do
	try(kind .. " at Name:", function() return D.Frame { Name = q[kind](nil) } end)
	try(kind .. " at Size:", function() return D.Frame { Size = q[kind](nil) } end)
	try(kind .. " at Visible:", function() return D.Frame { Visible = q[kind](nil) } end)
	try(kind .. " at Activated (event):", function() return D.TextButton { Activated = q[kind](nil) } end)
	try(kind .. " at Parent:", function() return D.Frame { Parent = q[kind](nil) } end)
	try(kind .. " at Foo:", function() return D.Frame { Foo = q[kind](nil) } end)
end
local p = q.PostRef(nil)
local f = D.Frame { Size = p }
print("PostRef at Size: _fired", p._fired, "Size is the PostRef table", f.Size == p)
