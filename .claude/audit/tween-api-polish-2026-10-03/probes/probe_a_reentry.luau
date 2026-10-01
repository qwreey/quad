local H = require("./probe_h")
local q, mock = H.q, H.mock
local Tween = q.Tween

local function report(name: string, f: any, src: any, prop: string)
	local cur = src:Get()
	local curV = if q.isTween(cur) then cur.Value else cur
	print(`{name}: prop={tostring(f[prop])} src={tostring(curV)} playing=[{H.playingStr()}] seen=[{H.take()}]`)
end

-- A1 engine Completed (async, outside process)
do
	mock.resetTweenLog()
	local src = q.Source(0 :: any)
	local f = q.Declaration.Frame({ Name = "F", Size = src }) :: any
	local once = false
	src:Set(Tween({ Value = 10, Time = 0.3, Completed = function(_, _, v) H.mk("a","C")(f,"Size",v); if not once then once = true; src:Set(Tween({ Value = 77, Time = 0.3, Started = H.mk("in","S") })) end end }))
	H.finish(H.last())
	report("A1 engine Completed -> Set(77)", f, src, "Size")
end

-- A2 window Completed (sync inside process of the replacing value)
do
	mock.resetTweenLog()
	local src = q.Source(0 :: any)
	local f = q.Declaration.Frame({ Name = "F", Size = src }) :: any
	local once = false
	src:Set(Tween({ Value = 10, Time = 0.3, Completed = function(_, _, v) H.mk("a","C")(f,"Size",v); if not once then once = true; src:Set(Tween({ Value = 77, Time = 0.3, Started = H.mk("in","S") })) end end }))
	H.last().PlaybackState = "Completed" -- reached target, notice pending
	src:Set(H.tw("b", 20))
	report("A2 window Completed -> Set(77) while b(20) replaces", f, src, "Size")
end

-- A3 engine Started -> Set
do
	mock.resetTweenLog()
	local src = q.Source(0 :: any)
	local f = q.Declaration.Frame({ Name = "F", Size = src }) :: any
	local once = false
	src:Set(Tween({ Value = 10, Time = 0.3, Started = function(_, _, v) H.mk("a","S")(f,"Size",v); if not once then once = true; src:Set(H.tw("in", 77)) end end, Cancelled = H.mk("a","X") }))
	report("A3 engine Started -> Set(77)", f, src, "Size")
end

-- A4 replacement Cancelled -> Set
do
	mock.resetTweenLog()
	local src = q.Source(0 :: any)
	local f = q.Declaration.Frame({ Name = "F", Size = src }) :: any
	local once = false
	src:Set(Tween({ Value = 10, Time = 0.3, Cancelled = function(_, _, v) H.mk("a","X")(f,"Size",v); if not once then once = true; src:Set(H.tw("in", 77)) end end }))
	src:Set(H.tw("b", 20))
	report("A4 replacement Cancelled -> Set(77) while b(20) replaces", f, src, "Size")
end

-- A5 zero-time snap after mount: Started -> Set / Completed -> Set
for _, ev in { "Started", "Completed" } do
	mock.resetTweenLog()
	local src = q.Source(0 :: any)
	local f = q.Declaration.Frame({ Name = "F", Size = src }) :: any
	local once = false
	local opts: any = { Value = 10, Time = 0 }
	opts[ev] = function(_, _, v) table.insert(H.seen, "a:" .. ev); if not once then once = true; src:Set(H.tw("in", 77)) end end
	src:Set(Tween(opts))
	report(`A5 zero-time snap {ev} -> Set(77)`, f, src, "Size")
end

-- A6/A7 mount first-snap Started / Completed -> Set
for _, ev in { "Started", "Completed" } do
	mock.resetTweenLog()
	local src: any
	local once = false
	local opts: any = { Value = 10, Time = 0.3 }
	opts[ev] = function(_, _, v) table.insert(H.seen, "a:" .. ev); if not once then once = true; src:Set(H.tw("in", 77)) end end
	src = q.Source(Tween(opts))
	local ok, err = pcall(function()
		local f = q.Declaration.Frame({ Name = "F", Size = src }) :: any
		report(`A6/7 mount first-snap {ev} -> Set(77)`, f, src, "Size")
		-- next emit: does the binding still follow?
		src:Set(Tween({ Value = 5, Time = 0.3 }))
		report(`   ... then Set(5)`, f, src, "Size")
	end)
	if not ok then print(`A6/7 {ev} raised: {err}`) end
end

-- A8 teardown Cancelled -> Set (retractFrom) and None-switch Cancelled -> Set
do
	mock.resetTweenLog()
	local src = q.Source(0 :: any)
	local f = q.Declaration.Frame({ Name = "F", Size = src }) :: any
	local once = false
	src:Set(Tween({ Value = 10, Time = 0.3, Cancelled = function() table.insert(H.seen, "a:X"); if not once then once = true; src:Set(H.tw("in", 77)) end end }))
	local ok, err = pcall(function() q.Dispatch.retractFrom(f, "Size", 1) end)
	print("A8a retractFrom ok=", ok, err)
	report("A8a teardown(retractFrom) Cancelled -> Set(77)", f, src, "Size")
end
do
	mock.resetTweenLog()
	local src = q.Source(0 :: any)
	local f = q.Declaration.Frame({ Name = "F", Size = src }) :: any
	local once = false
	src:Set(Tween({ Value = 10, Time = 0.3, Cancelled = function() table.insert(H.seen, "a:X"); if not once then once = true; src:Set(H.tw("in", 77)) end end }))
	local ok, err = pcall(function() src:Set(q.None) end)
	print("A8b None ok=", ok, err)
	report("A8b None-switch Cancelled -> Set(77)", f, src, "Size")
	src:Set(H.tw("after", 5))
	report("   ... then Set(5)", f, src, "Size")
end
print("done")
