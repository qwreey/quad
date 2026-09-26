--!nocheck
-- round13 Q91/Q92 prototype probe (scratch). To rerun: cp -rL quad-base quad-roblox quad-types quad-error to a scratch dir, apply the two diffs in this folder, copy this file to <scratch>/quad-roblox/test/probe.q91cascade.luau and run `luau test/probe.q91cascade.luau` from <scratch>/quad-roblox. Header lines 1-45 are copied from ../round13-e2b-probe.luau.
-- Moved from quad-roblox/test/probe.e2b.luau; to rerun copy back there after ./scripts/relink.sh and run `luau quad-roblox/test/probe.e2b.luau`.
-- round13 E2-2 probe (scratch) — InstanceShorthand / Modifier+StoreBind / Event
local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local installProperty = require("../src/Handlers/Property")
local installEvent = require("../src/Handlers/Event")
local installShorthand = require("../src/Handlers/InstanceShorthand")
local mock = require("../../quad-base/test/mock")
local Instance = mock.Instance

local W = { Write = "" }
local REFLECTED = {
	Frame = { { Name = "Name", Permits = W }, { Name = "Size", Permits = W }, { Name = "Visible", Permits = W }, { Name = "Parent", Permits = W }, { Name = "BackgroundTransparency", Permits = W } },
	TextButton = { { Name = "Name", Permits = W }, { Name = "Text", Permits = W }, { Name = "Visible", Permits = W }, { Name = "Size", Permits = W } },
	UICorner = { { Name = "Name", Permits = W }, { Name = "CornerRadius", Permits = W } },
	UIPadding = { { Name = "Name", Permits = W }, { Name = "PaddingLeft", Permits = W }, { Name = "PaddingRight", Permits = W }, { Name = "PaddingTop", Permits = W }, { Name = "PaddingBottom", Permits = W } },
	UIScale = { { Name = "Name", Permits = W }, { Name = "Scale", Permits = W } },
}
mock.declareEvents("TextButton", { "Activated", "MouseEnter" })
mock.declareEvents("Frame", { "Changed", "MouseEnter" })
local gameShim = mock.gameShim(REFLECTED)
local q = Quad.New():UseProvider(QuadRoblox)
;(getfenv(installProperty)).game = gameShim
;(getfenv(installProperty)).TweenInfo = mock.tweenInfoShim
;(getfenv(installProperty)).Enum = { EasingStyle = { Quad = "Quad" }, EasingDirection = { Out = "Out" }, PlaybackState = { Completed = "Completed", Cancelled = "Cancelled" } }
;(getfenv(installEvent)).game = gameShim
;(getfenv(require("../src/EngineOps"))).game = gameShim
;(getfenv(q.Declaration.New)).Instance = { new = mock.Instance.new }
q.Backend.isInst = mock.isMockInstance
q.errorNamespace.setFuncLevel(require("../luau_packages/quad_types").ERROR_LEVEL_SURFACE, q.Backend.isInst)
local D = q.Declaration
local function first(err) return (tostring(err):gsub("\n.*", "")) end
local UDIM_MT = { __eq = function(a, b) return a.Scale == b.Scale and a.Offset == b.Offset end,
	__tostring = function(a) return ("UDim(%s,%s)"):format(a.Scale, a.Offset) end }
UDim = { new = function(s, o) return setmetatable({ Scale = s, Offset = o }, UDIM_MT) end }
;(getfenv(installShorthand)).UDim = UDim
local function sec(name, fn)
	print("=== " .. name .. " ===")
	local ok, err = pcall(fn)
	if not ok then print("  !! section error:", first(err)) end
end
local function kids(f) local t = {} for _, c in f:GetChildren() do table.insert(t, c.ClassName .. ":" .. c.Name) end return table.concat(t, ",") end
local function nsubs(s) collectgarbage("collect"); collectgarbage("collect"); local n = 0 for _ in s._subs do n += 1 end return n end
local function named(f, n) for _, c in f:GetChildren() do if c.Name == n then return c end end end
local function cascade(key, reverseDelivery)
	local s = q.Source(0)
	local f = D.Frame({ [key] = s })
	local step, completes, starts, cancels = 0, 0, 0, 0
	local function mk(v)
		return q.Tween({ Value = v, Time = 1,
			Started = function() starts += 1 end,
			Cancelled = function() cancels += 1 end,
			Completed = function() completes += 1; if step < 3 then step += 1; s:Set(mk(100 + step)) end end })
	end
	s:Set(mk(10))
	local n0 = #mock.tweenLog
	local rounds = 0
	while rounds < 6 do
		rounds += 1
		local batch = {}
		for i = 1, #mock.tweenLog do local e = mock.tweenLog[i]; if e.tween.PlaybackState == "Playing" then table.insert(batch, e.tween) end end
		if #batch == 0 then break end
		for _, t in batch do t.PlaybackState = "Completed"; for pk, pv in t.PropertyTable do (t.Instance :: any)[pk] = pv end end -- same frame; engine wrote targets
		if reverseDelivery then for i = #batch, 1, -1 do batch[i].Completed:Fire("Completed") end
		else for _, t in batch do t.Completed:Fire("Completed") end end
	end
	local c = named(f, "_quad_padding")
	local vals = {}
	for _, p in { "PaddingLeft", "PaddingRight", "PaddingTop", "PaddingBottom" } do table.insert(vals, tostring((c :: any)[p].Offset)) end
	local created = #mock.tweenLog - n0
	print(("  %s%s: steps %d, Completed %d, Started %d, Cancelled %d, engine tweens created %d, rounds %d, final L/R/T/B = %s"):format(
		key, reverseDelivery and " (reverse delivery)" or "", step, completes, starts, cancels, created, rounds - 1, table.concat(vals, "/")))
end
sec("FULL cascade 10→101→102→103 (each batch completes same frame)", function()
	-- mock does not write the property on completion: emulate by reading records? write target on Completed
	cascade("UIPaddingOffset", false)
	cascade("UIPaddingOffset", true)
end)
