local mock = require("./mock")
local q = mock.newQuad()
local Instance = mock.Instance
local dispatch = q.Dispatch
local function try(label, f) local ok, e = pcall(f) print(label, ok and "ok" or ("ERR " .. tostring(e))) return ok, e end

print("--- R1 Rerun on a subscribed Effect: cleanup first, then fn, returns self")
do
	local log = {}
	local e = q.Effect(function() table.insert(log, "fn") return function() table.insert(log, "cl") end end)
	e:Subscribe(); table.clear(log)
	local r = e:Rerun()
	print("log", table.concat(log, " "), "returns self", r == e)
end
print("--- R2 Rerun on a created-but-not-subscribed Effect: held, replayed once on Subscribe")
do
	local n = 0
	local e = q.Effect(function() n += 1 end)
	print("after construct n", n, "Subscribed", e.Subscribed)
	e:Rerun(); e:Rerun()
	print("after two Rerun unsubscribed n", n)
	e:Subscribe(); print("after Subscribe n", n)
end
print("--- R3 Rerun inside fn: deferred after the run (once)")
do
	local n, inside = 0, false
	local e; e = q.Effect(function(self) n += 1; if n == 2 then self:Rerun(); self:Rerun() end end)
	e:Subscribe(); print("n after subscribe", n)
	e:Rerun(); print("n after Rerun that re-requests twice inside", n)
end
print("--- R4 Rerun inside cleanup: held → replayed when?")
do
	local n, ncl = 0, 0
	local e; e = q.Effect(function(self) n += 1; return function() ncl += 1; if ncl == 1 then self:Rerun() end end end)
	e:Subscribe(); local n0 = n
	e:Rerun(); print("fn runs", n - n0, "cleanups", ncl)
	e:Rerun(); print("fn runs total", n - n0, "cleanups", ncl)
end
print("--- R5 Rerun after Unsubscribe: held? replayed on re-Subscribe?")
do
	local n = 0
	local e = q.Effect(function() n += 1 end)
	e:Subscribe(); e:Unsubscribe(); local n0 = n
	e:Rerun(); print("after Rerun on unsubscribed", n - n0)
	e:Subscribe(); print("after re-Subscribe", n - n0)
end
print("--- R6 Rerun on a bound (props seat) Effect after instance destroyed")
do
	local n = 0
	local e = q.Effect(function() n += 1 end)
	local inst = Instance.new("Frame"); dispatch.drive(inst, { e }); local n0 = n
	e:Rerun(); print("bound Rerun runs", n - n0)
	try("Subscribe on bound (Quad0231)", function() e:Subscribe() end)
	try("WeakSubscribe on bound (Quad0230)", function() e:WeakSubscribe() end)
	inst:Destroy(); local n1 = n
	e:Rerun(); print("Rerun after destroy runs", n - n1)
end
print("--- O1 Observer bound then Subscribe")
do
	local s = q.Source(1)
	local o = s:Observer(function() end)
	local inst = Instance.new("Frame"); dispatch.drive(inst, { o })
	try("obs Subscribe on bound (Quad0235)", function() o:Subscribe() end)
	try("obs WeakSubscribe on bound (Quad0234)", function() o:WeakSubscribe() end)
	local e = q.Effect(function() end); e:WeakSubscribe()
	try("Effect WeakSubscribe twice (Quad0089)", function() e:WeakSubscribe() end)
end
print("--- misc NONE error IDs")
try("Quad0134 Wait inside table.sort comparator", function() table.sort({ 1, 2, 3 }, function(a, b) q.Ref(nil):Wait(); return a < b end) end)
try("Quad0134 Wait inside __index", function() local t = setmetatable({}, { __index = function() q.Ref(nil):Wait() end }); local _ = t.x end)
try("Quad0045 Debounce()", function() (q.Debounce :: any)() end)
try("Quad0012 Overridden(5)", function() (q.Attr :: any).Overridden(5) end)
try("Quad0190 Observer(5)", function() q.Source(1):Observer(5 :: any) end)
try("Quad0180 dispose({})", function() q.dispose({} :: any) end)
-- (Store/Slot NONE-id probes moved to e38probe_misc.luau)
