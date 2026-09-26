--!nocheck
-- round13 E24 A — q.Tween option matrix: construction verdict (error id + blame line) and, when it
-- constructs, what reaches the (mock) engine: TweenInfo.new args / Create props / snap vs engine path.
local H = require("./round13-e15-probe-setup")
local q, D, mock = H.q, H.D, H.mock
local log = mock.tweenLog
local NaN = 0 / 0
local function show(x)
	if type(x) == "table" then
		if q.isState(x) then return "State" end
		if q.isTween(x) then return "Tween" end
		if x == q.None then return "None" end
		return "table"
	end
	if type(x) == "function" then return "fn" end
	return tostring(x)
end
local function errline(err)
	local s = tostring(err):gsub("\n.*", "")
	local file, ln = s:match("([%w%-%._/]+%.luau):(%d+):")
	local id = s:match("Quad%d%d%d%d") or "VM"
	return id, (file and (file:match("[^/]+$") .. ":" .. ln) or "?"), s
end
-- try: construct at LINE 30 (the user line for blame) then feed to a Frame whose BackgroundTransparency
-- was first set plain (so the Tween goes down the engine path, not first-set snap)
local function probe(label, opts)
	local ok, tw = pcall(function() return q.Tween(opts) end) -- USERLINE
	if not ok then
		local id, where = errline(tw)
		print(string.format("%-34s CTOR %s @%s", label, id, where))
		return
	end
	mock.resetTweenLog()
	local src = q.Source(0.5)
	local f = D.Frame({ BackgroundTransparency = src })
	local ok2, e2 = pcall(function() src:Set(tw) end)
	local path
	if #log == 0 then
		path = "snap/none prop=" .. show(f.BackgroundTransparency)
	else
		local a = log[#log].info.args
		local info = log[#log].info
		if info.__mockTweenInfo then
			path = string.format("engine TweenInfo(%s,%s,%s,%s,%s,%s) n=%d", show(a[1]), show(a[2]), show(a[3]), show(a[4]), show(a[5]), show(a[6]), a.n)
		else
			path = "engine Info=" .. show(info)
		end
		path ..= " props.BT=" .. show(log[#log].props.BackgroundTransparency)
	end
	print(string.format("%-34s OK   %s%s", label, path, ok2 and "" or (" SETERR " .. select(3, errline(e2)))))
end

local S = q.Source
print("== Value ==")
probe("Value=nil", { Time = 1 })
probe("Value=false", { Value = false })
probe("Value=NaN", { Value = NaN })
probe("Value=inf", { Value = math.huge })
probe("Value='x' (wrong type)", { Value = "x" })
probe("Value=function", { Value = function() end })
probe("Value={} plain table", { Value = {} })
probe("Value=State(1)", { Value = S(1) })
probe("Value=State(nil)", { Value = S(nil) })
probe("Value=None", { Value = q.None })
probe("Value=Tween", { Value = q.Tween({ Value = 1 }) })
probe("Value=Void", { Value = q.Void })
probe("Value=Tag", { Value = q.Tag("x") })
print("== Time ==")
for _, c in { { "nil", nil }, { "0", 0 }, { "-1", -1 }, { "NaN", NaN }, { "inf", math.huge }, { "-0", -0 }, { "'1'", "1" }, { "true", true }, { "State(1)", S(1) }, { "State(nil)", S(nil) } } do
	probe("Time=" .. c[1], { Value = 1, Time = c[2] })
end
print("== RepeatCount ==")
for _, c in { { "0", 0 }, { "-1", -1 }, { "-2", -2 }, { "1.5", 1.5 }, { "NaN", NaN }, { "inf", math.huge }, { "'2'", "2" }, { "State(2)", S(2) } } do
	probe("RepeatCount=" .. c[1], { Value = 1, RepeatCount = c[2] })
end
print("== DelayTime ==")
for _, c in { { "-1", -1 }, { "NaN", NaN }, { "inf", math.huge }, { "'1'", "1" } } do
	probe("DelayTime=" .. c[1], { Value = 1, DelayTime = c[2] })
end
print("== Reverses ==")
for _, c in { { "1", 1 }, { "'true'", "true" }, { "State(true)", S(true) } } do
	probe("Reverses=" .. c[1], { Value = 1, Reverses = c[2] })
end
print("== Style / Direction / Info (unchecked by design) ==")
probe("Style='Quad' string", { Value = 1, Style = "Quad" })
probe("Style=1", { Value = 1, Style = 1 })
probe("Style=State", { Value = 1, Style = S("Quad") })
probe("Direction='In' string", { Value = 1, Direction = "In" })
probe("Direction=Style enum swap", { Value = 1, Direction = "Quad" })
probe("Info='x'", { Value = 1, Info = "x" })
probe("Info={} table", { Value = 1, Info = {} })
probe("Info=State(info)", { Value = 1, Info = S(mock.tweenInfoShim.new(1)) })
probe("Info+Time='x' (ignored field)", { Value = 1, Info = mock.tweenInfoShim.new(2), Time = "x" })
probe("Info+Time=0 (zeroTime?)", { Value = 1, Info = mock.tweenInfoShim.new(2), Time = 0 })
print("== zeroTime gate ==")
probe("Time=0", { Value = 1, Time = 0 })
probe("Time=-0", { Value = 1, Time = -0 })
probe("Time=0 DelayTime=0", { Value = 1, Time = 0, DelayTime = 0 })
probe("Time=0 RepeatCount=-1", { Value = 1, Time = 0, RepeatCount = -1 })
probe("Time=0 Reverses=false", { Value = 1, Time = 0, Reverses = false })
probe("Time=-1 (negative, not zero)", { Value = 1, Time = -1 })
print("== Override ==")
for _, c in { { "'cancel'", "cancel" }, { "'Finish'", "Finish" }, { "false", false }, { "State('Finish')", S("Finish") }, { "Enum-ish 1", 1 } } do
	probe("Override=" .. c[1], { Value = 1, Override = c[2] })
end
print("== Dedup ==")
for _, c in { { "0", 0 }, { "'false'", "false" }, { "State(false)", S(false) } } do
	probe("Dedup=" .. c[1], { Value = 1, Dedup = c[2] })
end
print("== callbacks ==")
local callable = setmetatable({}, { __call = function() end })
for _, name in { "Started", "Completed", "Cancelled" } do
	probe(name .. "=callable table", { Value = 1, [name] = callable })
	probe(name .. "=State(fn)", { Value = 1, [name] = S(function() end) })
	probe(name .. "=true", { Value = 1, [name] = true })
end
print("== opts shape ==")
probe("opts=nil", nil)
probe("opts='x'", "x")
probe("opts=State({Value=1})", S({ Value = 1 }))
probe("opts=Tween (re-wrap)", q.Tween({ Value = 0.3, Time = 2 }))
probe("unknown key Duration", { Value = 1, Duration = 5 })
