local H = require("./harness")
local q, D = H.q, H.D
local function first(e) return (tostring(e):gsub("\n.*", ""):gsub("^.-(Quad%d%d%d%d)", "%1")) end
local function try(l, f) local ok, e = pcall(f); print(l, ok and "OK" or first(e)) end
local a = q.Source(0)
for _, kind in { "E", "O" } do
	local mk = kind == "E" and function(fn) return q.Effect(fn, a) end or function(fn) return a:Observer(fn) end
	local h = mk(function() end):Subscribe()
	try(kind .. " bind while strong", function() D.Frame { h } end)
	local h2 = mk(function() end):WeakSubscribe()
	try(kind .. " bind while weak", function() D.Frame { h2 } end)
	local h3 = mk(function() end); local f = D.Frame { h3 }
	try(kind .. " bind again while bound", function() D.Frame { h3 } end)
	try(kind .. " Subscribe while bound", function() h3:Subscribe() end)
	try(kind .. " WeakUnsubscribe while bound", function() h3:WeakUnsubscribe() end)
	try(kind .. " Unsubscribe while bound", function() h3:Unsubscribe() end)
	f:Destroy()
	try(kind .. " Subscribe after host destroy", function() h3:Subscribe() end)
	h3:Unsubscribe()
	local f2 = D.Frame {}
	local h4 = mk(function() end); local f3 = D.Frame { h4 }; f3:Destroy()
	try(kind .. " rebind after host destroy", function() D.Frame { h4 } end)
	try(kind .. " WeakSub on weak", function() h2:WeakSubscribe() end)
	try(kind .. " Sub on weak", function() h2:Subscribe() end)
	try(kind .. " WeakUnsub on strong", function() h:WeakUnsubscribe() end)
	try(kind .. " Unsub on weak", function() h2:Unsubscribe() end)
	try(kind .. " Unsub fresh", function() mk(function() end):Unsubscribe() end)
end
