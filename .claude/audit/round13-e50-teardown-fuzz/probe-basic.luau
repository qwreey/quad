--!nocheck
local H = require("./harness")
local q, D = H.q, H.D
local CS = H.CollectionService
local rmLog = {}
local origRm = CS.RemoveTag
CS.RemoveTag = function(self, inst, name) table.insert(rmLog, name) return origRm(self, inst, name) end

local log = {}
local function L(s) table.insert(log, s) end
local up = q.Source(0)
local deb = up:Apply(q.Debounce({ Time = 1 }))
local sizeSrc = q.Source(1)
local r = q.Ref(nil)
local child = D.Frame {
	Name = "child",
	q.Effect(function() return function(d) L("childCleanup:" .. tostring(d)) end end),
	q.OnDestroyed(function() L("childOnDestroyed") end),
}
local s = q.Slot({ child })
local listData = q.Source({ "a", "b" })
local ls = q.Slot():List(listData, function(ctx)
	if ctx.Item == q.KeyGone then L("keygone") return nil end
	if ctx.Prev then return ctx.Prev end
	return D.Frame { Name = "li" .. ctx.Item, q.Effect(function() return function(d) L("li" .. ctx.Item .. "Cleanup:" .. tostring(d)) end end) }
end, function(it) return it end)
local root = D.Frame {
	Name = "root",
	Size = sizeSrc,
	r,
	q.Tag("T1"),
	q.Attr({ A = 5 }),
	q.Effect(function() return function(d) L("rootCleanup:" .. tostring(d)) end end),
	q.OnDestroyed(function() L("rootOnDestroyed") end),
	up:Observer(function() L("rootObs") end),
	deb:Observer(function() L("rootDeb") end),
	s,
	ls,
}
sizeSrc:Set(q.Tween({ Value = 5, Time = 1, Started = function() L("started") end, Completed = function() L("completed") end, Cancelled = function() L("cancelled") end }))
local tw = H.gameShim and require("../../../quad-base/test/mock").tweenLog
print("tweens", #tw)
up:Set(1) -- leading? debounce
print("pre", table.concat(log, ","))
table.clear(log)
listData:Set({ "a" })
print("after keygone", table.concat(log, ","))
table.clear(log)
root:Destroy()
print("destroy", table.concat(log, ","))
print("rmLog", table.concat(rmLog, ","), "attr", root:GetAttribute("A"), "ref", r.Value == root)
table.clear(log)
tw[#tw].tween:simulateCompleted()
up:Set(2)
H.runTask(5)
print("post", table.concat(log, ","))
