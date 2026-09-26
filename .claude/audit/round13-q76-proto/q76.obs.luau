--!nocheck
local mock = require("./mock")
local Instance = mock.Instance
local function kids(p) local t = {} for _, c in p:GetChildren() do t[#t+1] = c.Name end table.sort(t) return table.concat(t, ",") end

-- (1) call order
do
	local q = mock.newQuad()
	local log = {}
	local data = q.Source({ {id="a"},{id="b"},{id="c"},{id="d"} })
	local s = q.Slot()
	s:List(data, function(ctx)
		if ctx.Item == q.KeyGone then log[#log+1] = "gone:" .. ctx.Prev.Name .. "@" .. ctx.Index; return nil end
		log[#log+1] = ctx.Item.id .. "@" .. ctx.Index
		if ctx.Prev then return ctx.Prev end
		local f = Instance.new("Frame"); f.Name = ctx.Item.id; return f
	end, function(it) return it.id end)
	local p = Instance.new("Folder"); q.Dispatch.drive(p, { s })
	table.clear(log)
	data:Set({ {id="x"},{id="b"},{id="y"},{id="d"} })
	print("(1) order:", table.concat(log, " "))
	-- does updateFn for x see a/c still mounted?
end

-- (1b) what a new item's updateFn observes about the tree (children count at call time)
do
	local q = mock.newQuad()
	local obs = {}
	local p = Instance.new("Folder")
	local data = q.Source({ {id="a"},{id="b"} })
	local s = q.Slot()
	s:List(data, function(ctx)
		if ctx.Item == q.KeyGone then obs[#obs+1] = "gone(children=" .. #p:GetChildren() .. ",Len=" .. s.Length:Get() .. ")"; return nil end
		obs[#obs+1] = ctx.Item.id .. "(children=" .. #p:GetChildren() .. ",Len=" .. s.Length:Get() .. ")"
		if ctx.Prev then return ctx.Prev end
		local f = Instance.new("Frame"); f.Name = ctx.Item.id; return f
	end, function(it) return it.id end)
	q.Dispatch.drive(p, { s })
	table.clear(obs)
	data:Set({ {id="x"},{id="y"} })
	print("(1b) observed:", table.concat(obs, " "))
end

-- (2) throws
local function throwCase(label, throwOn)
	local q = mock.newQuad()
	local data = q.Source({ {id="a"},{id="b"},{id="c"} })
	local armed = false
	local asked = {}
	local s = q.Slot()
	s:List(data, function(ctx)
		local id = if ctx.Item == q.KeyGone then "gone:" .. ctx.Prev.Name else ctx.Item.id
		asked[#asked+1] = id
		if armed and id == throwOn then armed = false; error("boom") end
		if ctx.Item == q.KeyGone then return nil end
		if ctx.Prev then return ctx.Prev end
		local f = Instance.new("Frame"); f.Name = ctx.Item.id; return f
	end, function(it) return it.id end)
	local p = Instance.new("Folder"); q.Dispatch.drive(p, { s })
	armed = true; table.clear(asked)
	local ok = pcall(function() data:Set({ {id="x"},{id="b"},{id="y"} }) end)
	local after = kids(p)
	local len = s.Length:Get()
	local blk = q.Bookkeeping.getBlocker(s).Blocking
	table.clear(asked)
	local ok2, e2 = pcall(function() data:Set({ {id="x"},{id="b"},{id="z"} }) end)
	print(`(2) {label}: ok={ok} after={after} Len={len} blockerOn={blk} | next Set ok={ok2} asked={table.concat(asked," ")} final={kids(p)} Len={s.Length:Get()} {if ok2 then "" else tostring(e2)}`)
end
throwCase("throw on new x", "x")
throwCase("throw on new y", "y")
throwCase("throw on gone a", "gone:a")
throwCase("throw on gone c", "gone:c")

-- (3) cross-key reuse: new key returns the element mounted under a gone key
local function reuse(reply)
	local q = mock.newQuad()
	local byName = {}
	local data = q.Source({ {id="a"} })
	local s = q.Slot()
	s:List(data, function(ctx)
		if ctx.Item == q.KeyGone then return reply end
		if ctx.Item.id == "b" then return byName.a end
		local f = Instance.new("Frame"); f.Name = ctx.Item.id; byName[f.Name] = f; return f
	end, function(it) return it.id end)
	local p = Instance.new("Folder"); q.Dispatch.drive(p, { s })
	local ok, e = pcall(function() data:Set({ {id="b"} }) end)
	print(`(3) reuse gone element under new key, KeyGone→{if reply == nil then "nil" else "Detach"}: ok={ok} children={kids(p)} destroyed={mock.isDestroyed(byName.a)} Len={s.Length:Get()} {if ok then "" else tostring(e)}`)
end
reuse(nil)
do local q = mock.newQuad(); reuse(q.Detach) end
