--!nocheck
-- round13 E15 S2 — how-to 03 VirtualList (+ §5 Throttle) + Animate on row Position + Blocker batch + items State.
local H = require("./round13-e15-probe-setup")
local q, D, mock, try, track, alive = H.q, H.D, H.mock, H.try, H.track, H.alive
local UDim2 = { new = function(a, b, c, d) return { a, b, c, d } end, fromScale = function(a, b) return { a, 0, b, 0 } end }
local ROW, BUFFER = 50, 3
local creates, destroyedRows = 0, 0
local tweenDone = {}

local function VirtualList(props)
	local items = props.Items -- State<{...}> variant (doc: plain table)
	local scrollY = q.Source(0)
	local viewportHeight = q.Source(200)
	local gatedScrollY = if props.Throttle then scrollY:Apply(q.Throttle { Time = 0.1 }) else scrollY
	local blocker = props.Blocker
	local window = gatedScrollY:Compute(function(y, _previous, height, its)
		local list = its:Get()
		local first = math.floor(y:Get() / ROW) + 1
		local count = math.ceil(height:Get() / ROW) + 1
		local s, e = math.max(1, first - BUFFER), math.min(#list, first + count + BUFFER)
		local slice = {}
		for i = s, e do table.insert(slice, { item = list[i], absIndex = i }) end
		return slice
	end, viewportHeight, items)
	if blocker then window = window:Apply(blocker) end
	local rows = q.Slot():List(window, function(ctx)
		local entry, prev, ud = ctx.Item, ctx.Prev, ctx.UserData
		if entry == q.KeyGone then return nil, ud end
		if prev then
			if ud.abs:Get() ~= entry.absIndex then ud.abs:Set(entry.absIndex) end
			return prev, ud
		end
		creates += 1
		local abs = q.Source(entry.absIndex)
		local position = abs:Compute(function(a) return (a:Get() - 1) * ROW end)
			:Apply(q.Animate { Time = 0.2, CanAnimate = props.CanAnimate, Completed = function() table.insert(tweenDone, entry.item.id) end })
		local row = D.Frame {
			Name = entry.item.id,
			Position = position,
			q.OnDestroyed(function() destroyedRows += 1 end),
			D.TextButton { Name = "Del", Text = entry.item.label,
				Activated = function() -- (c) the row deletes its own item from inside its handler
					local next = {}
					for _, it in items:Get() do if it.id ~= entry.item.id then table.insert(next, it) end end
					items:Set(next)
				end },
		}
		track("S2.row", row)
		return row, { abs = abs }
	end, function(entry) return entry.item.id end)
	local sf = D.ScrollingFrame {
		q.OnChange("CanvasPosition", function(pos) scrollY:Set(pos.Y) end),
		q.OnChange("AbsoluteWindowSize", function(size) viewportHeight:Set(size.Y) end),
		rows,
	}
	track("S2.sf", sf)
	return sf, rows, window
end

local function mkItems(n, prefix)
	local t = {}
	for i = 1, n do t[i] = { id = (prefix or "i") .. i, label = "L" .. i } end
	return t
end
local function names(sf)
	local out = {}
	for _, c in sf:GetChildren() do table.insert(out, c.Name) end
	table.sort(out)
	return #out .. ":" .. table.concat(out, ",")
end
local function consistent(sf, window)
	-- children set == window keys ; each row's tween target matches absIndex
	local want = {}
	for _, e in window:Get() do want[e.item.id] = e.absIndex end
	local ok, n = true, 0
	for _, c in sf:GetChildren() do
		n += 1
		if want[c.Name] == nil then ok = false end
	end
	local wn = 0
	for _ in want do wn += 1 end
	return ok and n == wn
end

print("== S2a normal: doc flow ==")
local items = q.Source(mkItems(100))
local sf, rows, window = VirtualList { Items = items }
print("rows", names(sf), "creates", creates, "tweens", #H.tweenLog)
sf.CanvasPosition = { X = 0, Y = 500 }
print("after scroll 500: rows", #sf:GetChildren(), "creates", creates, "destroyed", destroyedRows, "consistent", consistent(sf, window), "tweens", #H.tweenLog)

print("== S2c: row deletes its own item inside Activated (KeyGone destroys the row whose handler is on the stack) ==")
local target = sf:FindFirstChild("i12")
local btn = target:FindFirstChild("Del")
try("click Del on i12", function() btn.Activated:Fire() end)
print("i12 still child?", sf:FindFirstChild("i12") ~= nil, "destroyed", mock.isDestroyed(target), "consistent", consistent(sf, window), "#items", #items:Get())
-- the row after i12 shifted absIndex -> tween created for reused rows
print("tweens so far", #H.tweenLog)
try("click Del again on the dead button", function() btn.Activated:Fire() end)

print("== S2d: Blocker batch + Throttle + CanAnimate=false snap(Completed sync) + tween Completed inside window ==")
do
	H.mock.resetTweenLog(); table.clear(tweenDone)
	local blocker = q.Blocker()
	local its = q.Source(mkItems(30, "b"))
	local sf2, rows2, win2 = VirtualList { Items = its, Throttle = true, Blocker = blocker, CanAnimate = false }
	local order = {}
	local obs = win2:Observer(function(t) table.insert(order, "win#" .. #t:Get()) end)
	obs:Subscribe()
	print("mounted", names(sf2):sub(1, 40))
	blocker:On()
	sf2.CanvasPosition = { X = 0, Y = 300 } -- throttle leading passes -> window recompute but blocker holds
	its:Set(mkItems(12, "b")) -- data shrinks inside window
	H.run(0.15) -- throttle trailing fires INSIDE blocker window
	sf2.CanvasPosition = { X = 0, Y = 100 }
	table.insert(order, "before Off: children=" .. #sf2:GetChildren())
	blocker:Off()
	table.insert(order, "after Off: children=" .. #sf2:GetChildren())
	H.run(0.2)
	print("order", table.concat(order, " | "))
	print("final consistent", consistent(sf2, win2), names(sf2):sub(1, 60), "window#", #win2:Get(), "tweenDone(sync snaps)", #tweenDone)
	obs:Unsubscribe()
	sf2:Destroy()
end

print("== S2d2: in-flight tween completes on a row that KeyGone destroyed in the same Blocker window ==")
do
	H.mock.resetTweenLog(); table.clear(tweenDone)
	local blocker = q.Blocker()
	local its = q.Source(mkItems(10, "c"))
	local sf3, rows3, win3 = VirtualList { Items = its, Blocker = blocker }
	sf3.CanvasPosition = { X = 0, Y = 0 }
	-- delete c1 -> c2..c10 shift (tweens start on reused rows)
	its:Set({ table.unpack(its:Get(), 2) })
	local n = #H.tweenLog
	print("tweens started by shift", n)
	blocker:On()
	its:Set({}) -- all rows KeyGone (destroyed) — held by blocker
	for _, rec in H.tweenLog do if rec.tween.PlaybackState == "Playing" then rec.tween:simulateCompleted() end end
	blocker:Off()
	print("tweenDone callbacks", #tweenDone, "children", #sf3:GetChildren())
	for _, rec in H.tweenLog do if rec.tween.PlaybackState == "Playing" then rec.tween:simulateCompleted() end end
	print("tweenDone after late completes", #tweenDone, "cancels", (function() local c = 0 for _, r in H.tweenLog do c += r.tween.cancels end return c end)())
	sf3:Destroy()
end

print("== S2b teardown: destroy ScrollingFrame with throttle pending + tweens in flight; leak count ==")
do
	H.mock.resetTweenLog()
	local its = q.Source(mkItems(50, "d"))
	local sf4 = VirtualList { Items = its, Throttle = true }
	sf4.CanvasPosition = { X = 0, Y = 50 }
	sf4.CanvasPosition = { X = 0, Y = 150 } -- held by throttle
	print("pending timers", H.pending(), "tweens", #H.tweenLog)
	sf4:Destroy()
	H.run(0.5)
	for _, rec in H.tweenLog do if rec.tween.PlaybackState == "Playing" then rec.tween:simulateCompleted() end end
	try("data write after destroy", function() its:Set(mkItems(5, "d")) end)
end
H.mock.resetTweenLog()
sf, rows, window, target, btn, items = nil, nil, nil, nil, nil, nil
print("alive", alive("S2."))
