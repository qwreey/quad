--!nocheck
local G = require("./gclib")
local H = require("./harness")
local q, D = H.q, H.D
local shared = q.Source("s")
G.measure("j1 Out(Text, src) + Text=src, inst:Destroy()", function(N, track)
	for i = 1, N do
		local src = q.Source("a")
		local d = q.Out("Text", src)
		local f = D.TextBox { Text = src, d }
		f.Text = "typed"
		track(src, "src"); track(d, "desc"); track(f, "inst")
		f:Destroy()
	end
end)
G.measure("j2 OnChange capturing a long-lived Source, inst:Destroy()", function(N, track)
	for i = 1, N do
		local cb = function(v) shared:Set(v) end
		local d = q.OnChange("Name", cb)
		local f = D.Frame { d }
		f.Name = "n" .. i
		track(d, "desc"); track(cb, "cb"); track(f, "inst")
		f:Destroy()
	end
end)
G.measure("j3 OnChange descriptor made, never used", function(N, track)
	for i = 1, N do local d = q.OnChange("Name", function() end); track(d, "desc") end
end)
local host = D.TextBox {}
local seat = q.Source(nil)
local host2 = D.TextBox { seat }
G.measure("j4 State<OnChange?> seat swapped N times on a live inst (connections must drop)", function(N, track)
	for i = 1, N do local cb = function() end; local d = q.OnChange("Text", cb); track(d, "desc"); track(cb, "cb"); seat:Set(d) end
	seat:Set(nil)
end)
local n = 0 host2.Text = "zz"
G.measure("j5 Event handler key (Activated) closure, inst Destroy", function(N, track)
	for i = 1, N do local cb = function() end; local f = D.TextButton { Activated = cb }; track(cb, "cb"); track(f, "inst"); f:Destroy() end
end)
