--!nocheck
local mock = require("./mock")
local q = mock.newQuad()
local s = q.Source(0)
local calls = 0
local ok, err = pcall(function() return s:Observer(function() calls += 1; error("boom") end) end)
local o = next(s._subs)
print("ok", ok, tostring(err):sub(1, 40), "in _subs", o ~= nil, "calls", calls)
s:Set(1); s:Set(2)
if o then print("after Sets calls", calls, "rerunReq", o._rerunRequired, "installing", o._installing, "emitted", o._installEmitted, "running", o._running) end
