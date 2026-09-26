--!nocheck
local G = require("./gclib")
local H = require("./harness")
local q, D = H.q, H.D
local mock = require("../../../quad-base/test/mock")
local function scen(withCb, finish, destroyKind, useAnimate)
	return function(N, track)
		mock.resetTweenLog()
		for i = 1, N do
			local src = q.Source(0)
			local seat = useAnimate and src:Apply(q.Animate { Time = 0.3 }) or src:Compute(function(s)
				local v = s:Get()
				if withCb then
					return q.Tween { Value = v, Time = 0.3, Completed = function() end, Cancelled = function() end, Started = function() end }
				end
				return q.Tween { Value = v, Time = 0.3 }
			end)
			local f = D.Frame { BackgroundTransparency = seat }
			src:Set(1) -- second write: engine tween (first set snaps)
			local rec = mock.tweenLog[#mock.tweenLog]
			track(f, "inst"); track(src, "src"); track(seat, "seat"); if rec then track(rec.tween, "tween") end
			if finish then rec.tween:simulateCompleted() end
			if destroyKind == "destroy" then f:Destroy() else q.dispose(f) end
		end
		mock.resetTweenLog() -- mock-held: tweenLog pins tween records (mock limit)
	end
end
G.measure("f1 running Tween, inst:Destroy()", scen(false, false, "destroy"))
G.measure("f2 running Tween w/ callbacks, inst:Destroy()", scen(true, false, "destroy"))
G.measure("f3 completed Tween w/ callbacks, Destroy", scen(true, true, "destroy"))
G.measure("f4 running Tween w/ callbacks, q.dispose", scen(true, false, "dispose"))
G.measure("f5 Animate running, Destroy", scen(false, false, "destroy", true))
G.rounds("f2 rounds", scen(true, false, "destroy"), 1000, 4)
-- f6: tweenLog NOT reset (mock limit demonstration)
G.measure("f6 running Tween, Destroy, mock tweenLog kept", function(N, track)
	mock.resetTweenLog()
	for i = 1, N do
		local src = q.Source(0)
		local f = D.Frame { BackgroundTransparency = src:Compute(function(s) return q.Tween { Value = s:Get(), Time = 0.3, Completed = function() end } end) }
		src:Set(1); track(f, "inst"); f:Destroy()
	end
end)
mock.resetTweenLog()
-- f7: long-lived inst, tweens replaced many times (records must not accumulate)
G.measure("f7 live inst, 1000 tween replacements w/ callbacks", function(N, track)
	mock.resetTweenLog()
	local src = q.Source(0)
	local f = D.Frame { BackgroundTransparency = src:Compute(function(s) return q.Tween { Value = s:Get(), Time = 0.3, Completed = function() end, Cancelled = function() end } end) }
	for i = 1, N do src:Set(i); track(mock.tweenLog[#mock.tweenLog].tween, "tween") end
	mock.resetTweenLog()
	KEEP = { f = f }
end)
KEEP.f:Destroy(); KEEP = nil
