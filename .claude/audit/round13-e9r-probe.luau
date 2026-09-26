-- round13 E9 probe (quad-roblox side). Run: copy to quad-roblox/test/probe.e9r.luau, ./scripts/relink.sh, luau quad-roblox/test/probe.e9r.luau
local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local mock = require("../../quad-base/test/mock")
local collectgarbage = (_G :: any).collectgarbage
local Instance = mock.Instance
local q: any = Quad.New():UseProvider(QuadRoblox)
q.Backend.isInst = mock.isMockInstance
local B = q.Backend
local function T(name, f)
	local ok, err = pcall(f)
	print(`--- {name}: {ok and "ok" or ("ERR " .. tostring(err))}`)
end
local function E(f, ...)
	local ok, err = pcall(f, ...)
	return ok and "ok" or tostring(err):match("Quad%d+[^\n]*") or tostring(err)
end
local function gc() for _ = 1, 3 do collectgarbage("collect") end end
local function claimed(cls) local i = Instance.foreign(cls or "Frame"); B.nativeClaim(i); return i end

T("R1 foreign / claimed / double claim", function()
	local f = Instance.foreign("Frame")
	print(" bind foreign:", E(B.bindLifetime, f, {}), "isClaimed", B.isClaimed(f))
	B.nativeClaim(f)
	print(" after claim bind:", E(B.bindLifetime, f, {}), "double claim:", E(B.nativeClaim, f))
end)

T("R2 destroyed claimed inst: bind before GC vs after GC (Q20 known)", function()
	local a = claimed()
	a:Destroy()
	local v = {}
	print(" pre-GC bind:", E(B.bindLifetime, a, v), "canExecute", B.canExecute(v), "isClaimed", B.isClaimed(a))
	gc()
	print(" post-GC bind:", E(B.bindLifetime, a, {}))
end)

T("R3 during Destroying: isClaimed/bind/Effect", function()
	local a = claimed()
	local log = {}
	local eff = q.Effect(function() log[#log + 1] = "fn"; return function(d) log[#log + 1] = "c:" .. tostring(d) end end)
	local r
	a.Destroying:Connect(function()
		r = "isClaimed=" .. tostring(B.isClaimed(a)) .. " bindEff=" .. E(B.bindLifetime, a, eff) .. " canExecute=" .. tostring(B.canExecute(eff))
	end)
	a:Destroy()
	print(" during:", r)
	print(" after: log", table.concat(log, ","), "cleanup pending", eff._cleanup ~= nil, "canBound", B.canBound(eff))
end)

T("R4 nativeDispose then GC: value bound, Effect cleanup, hold remnant", function()
	local weak = setmetatable({}, { __mode = "v" })
	local log = {}
	do
		local a = claimed()
		local v = {}
		weak.v = v
		local eff = q.Effect(function() return function(d) log[#log + 1] = "c:" .. tostring(d) end end)
		weak.eff = eff
		B.bindLifetime(a, v); B.bindLifetime(a, eff)
		B.nativeDispose(a)
	end
	gc()
	print(" log", table.concat(log, ","), "v", weak.v == nil and "collected" or "ALIVE", "eff", weak.eff == nil and "collected" or "ALIVE")
end)

-- engine-shaped fake: the connection object is referenced by nobody but Lua callers
-- (the engine pins the CALLBACK, not the RBXScriptConnection userdata) — emulates Roblox
local pinnedCallbacks = {}
local function fakeInst()
	local inst = {}
	function inst.GetPropertyChangedSignal(_self, _p)
		return {
			Connect = function(_s, fn)
				pinnedCallbacks[fn] = true
				return { Connected = true, Disconnect = function(c) c.Connected = false; pinnedCallbacks[fn] = nil end }
			end,
		}
	end
	return inst
end

T("R5 bind the number 1 — gchold[1] is the reserved gcconn slot", function()
	local a = fakeInst()
	B.nativeClaim(a)
	local v = {}
	B.bindLifetime(a, v)
	gc()
	print(" baseline after GC: isHeld(v)", B.isHeld(v), "isClaimed(a)", B.isClaimed(a))
	B.bindLifetime(a, 1)
	gc()
	print(" after bindLifetime(a, 1)+GC: isHeld(v)", B.isHeld(v), "canExecute(v)", B.canExecute(v), "isClaimed(a)", B.isClaimed(a), "canBound(v)", B.canBound(v))
	print(" double claim now:", E(B.nativeClaim, a), "rebind v to same a:", E(B.bindLifetime, a, v))
	local b = fakeInst(); B.nativeClaim(b)
	local w = {}
	B.bindLifetime(b, w); B.bindLifetime(b, 1 == 1 and 2 or 0)
	B.unbindLifetime(2)
	gc()
	print(" control (number 2 bind/unbind): isHeld(w)", B.isHeld(w))
	local c = fakeInst(); B.nativeClaim(c)
	local x = {}
	B.bindLifetime(c, x)
	print(" bind 1 on c:", E(B.bindLifetime, c, 1))
end)
