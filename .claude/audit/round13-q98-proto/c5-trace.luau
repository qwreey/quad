local mock = require("./mock")
local q = mock.newQuad()
local Source = q.Source
local f = q.Debounce({ Time = 1 })
local a, b = Source(0), Source(0)
local ga, gb = a:Apply(f), b:Apply(f)
local depth = 0
for name, n in { ga = ga, gb = gb } do
	local orig = n._recompute
	n._recompute = function(self)
		depth += 1
		local gen = self._cacheTargetCount
		print(string.rep("  ", depth) .. `{name} recompute enter gen={gen} curr={self._cacheCurrCount} cache={self._cache}`)
		orig(self)
		print(string.rep("  ", depth) .. `{name} recompute exit gen={gen} target={self._cacheTargetCount} curr={self._cacheCurrCount} cache={self._cache}`)
		depth -= 1
	end
end
local sa, sb = {}, {}
local oa = ga:Observer(function(st, _, from) if from ~= nil then print("oa fire"); sa[#sa + 1] = st:Get(); b:Set(b:Get() + 1); print("oa done") end end):Subscribe()
local ob = gb:Observer(function(st, _, from) if from ~= nil then print("ob fire"); sb[#sb + 1] = st:Get(); print("ob read", sb[#sb]) end end):Subscribe()
a:Set(1); b:Set(5)
print("FLUSH")
f:Flush()
print(" after Flush a", table.concat(sa, ","), "b", table.concat(sb, ","), "b now", b:Get(), "timers", mock.pendingTimers())
mock.advanceTime(3)
print(" after adv a", table.concat(sa, ","), "b", table.concat(sb, ","))
local _ = { oa, ob }
