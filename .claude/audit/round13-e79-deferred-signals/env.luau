--!nocheck
-- E79 environment: ONE install (quad-roblox/luau_packages — typing-limits 8.34) + real quad-roblox
-- provider on mock shims (copied from round13-e66-handlers-fuzz/env.luau) + a DEFERRED-DELIVERY SHIM.
--
-- The shim is a runtime patch of the mock Signal metatable and of each mock Instance proxy's
-- __newindex; quad-base/test/mock.luau itself is NOT edited. It is a SHIM of Roblox
-- `Workspace.SignalBehavior = Deferred`, not Roblox.
--
-- Modes (S.mode):
--   "mock" — the mock as-is: synchronous Fire, fires on same-value writes.
--   "imm"  — Immediate analogue: synchronous Fire + engine same-value suppression (Studio 2026-09-10:
--            same-value assignment fires no changed signal).
--   "def"  — Deferred analogue: same-value suppression + every Fire enqueues one entry per connection
--            live at fire time (listener snapshot + packed args); S.flush() drains FIFO ("end of the
--            resumption point"); fires made during flush go to the back of the queue and are drained in
--            the same flush. Delivery rules: an entry whose connection was explicitly :Disconnect()ed is
--            dropped (Studio m10-events-studio-2026-09-03 1절 3번); an entry whose connection was cut by
--            Destroy (DisconnectAll) is still delivered once (H-291) — toggle S.deliverAfterDestroy.
--            Listener errors are isolated (pcall, recorded in S.errors) — the engine logs them.
--            Timer callbacks (q.Backend.setTimeout) are resumption points: flush after each.
local Quad = require("../../../quad-roblox/luau_packages/quad_base")
local QuadRoblox = require("../../../quad-roblox/src").QuadRoblox
local installProperty = require("../../../quad-roblox/src/Handlers/Property")
local installEvent = require("../../../quad-roblox/src/Handlers/Event")
local installShorthand = require("../../../quad-roblox/src/Handlers/InstanceShorthand")
local installEngineOps = require("../../../quad-roblox/src/EngineOps")
local mock = require("../../../quad-base/test/mock")
local EG = require("../round13-e44-ref-statemachine/engine-globals")

local W = { Write = "" }
local function props(...)
	local t = {}
	for _, n in { ... } do table.insert(t, { Name = n, Permits = W }) end
	return t
end
local REFLECTED = {
	Frame = props("Name", "Size", "Visible", "ZIndex", "Parent", "Position", "LayoutOrder"),
	TextButton = props("Name", "Size", "Visible", "ZIndex", "Parent", "Text"),
	TextBox = props("Name", "Size", "Visible", "Parent", "Text", "PlaceholderText"),
	TextLabel = props("Name", "Size", "Visible", "Parent", "Text", "LayoutOrder"),
}
mock.declareEvents("Frame", { "MouseEnter" })
mock.declareEvents("TextButton", { "Activated", "MouseButton1Click" })
mock.declareEvents("TextBox", { "FocusLost", "Focused" })
local gameShim = mock.gameShim(REFLECTED)
;(getfenv(installProperty)).game = gameShim
;(getfenv(installProperty)).TweenInfo = mock.tweenInfoShim
;(getfenv(installProperty)).Enum = EG.Enum
;(getfenv(installEvent)).game = gameShim
;(getfenv(installEngineOps)).game = gameShim
;(getfenv(installShorthand)).UDim = EG.UDim

------------------------------------------------------------------ shim
local S = {
	mode = "mock",
	queue = {} :: { any },
	head = 1,
	suppress = false,
	deliverAfterDestroy = true,
	errors = {} :: { string },
	delivered = 0, -- total deliveries (all flushes)
	lastFlush = 0, -- deliveries in the last flush
	maxQueue = 0,
	cap = 5000,
	capped = false,
}

local SigMT = getmetatable(mock.newSignal())
local origFire, origConnect = SigMT.Fire, SigMT.Connect

SigMT.Connect = function(self, fn)
	local conn = origConnect(self, fn)
	local od = conn.Disconnect
	conn.Disconnect = function(c)
		c._userDisc = true
		od(c)
	end
	return conn
end

SigMT.Fire = function(self, ...)
	if S.suppress then
		return
	end
	if S.mode ~= "def" then
		return origFire(self, ...)
	end
	local snap = table.clone(self.connections)
	local args = table.pack(...)
	for i = #snap, 1, -1 do -- same listener order as the mock's synchronous Fire (one variable changed)
		local c = snap[i]
		if c.Connected then
			table.insert(S.queue, { c = c, args = args })
		end
	end
	if #S.queue - S.head + 1 > S.maxQueue then
		S.maxQueue = #S.queue - S.head + 1
	end
end

local function idOf(err)
	local s = tostring(err)
	return s:match("Quad%d%d%d%d") or ("RAW:" .. (s:gsub("\n.*", "")))
end

function S.flush()
	if S.mode ~= "def" then
		return 0
	end
	local n = 0
	while S.head <= #S.queue do
		local e = S.queue[S.head]
		S.queue[S.head] = false
		S.head += 1
		if not e.c._userDisc and (e.c.Connected or S.deliverAfterDestroy) then
			n += 1
			S.delivered += 1
			local ok, err = pcall(e.c.fn, table.unpack(e.args, 1, e.args.n))
			if not ok then
				table.insert(S.errors, idOf(err) .. " :: " .. tostring(err):sub(1, 160))
			end
			if n >= S.cap then
				S.capped = true
				break
			end
		end
	end
	S.queue = {}
	S.head = 1
	S.lastFlush = n
	return n
end

function S.reset(mode)
	S.mode = mode
	S.queue = {}
	S.head = 1
	S.suppress = false
	S.deliverAfterDestroy = true
	S.errors = {}
	S.delivered = 0
	S.lastFlush = 0
	S.maxQueue = 0
	S.capped = false
	mock.resetTimers()
	mock.resetTweenLog()
end

-- same-value suppression on a mock proxy (engine: same-value assignment fires nothing)
local function patchInst(inst)
	local mt = getmetatable(inst)
	if mt == nil or mt.__e79 then
		return inst
	end
	local orig = mt.__newindex
	mt.__newindex = function(p, k, v)
		if S.mode ~= "mock" then
			local okOld, old = pcall(function() return p[k] end)
			if okOld and old == v then
				S.suppress = true
				local ok, e = pcall(orig, p, k, v)
				S.suppress = false
				if not ok then error(e, 2) end
				return
			end
		end
		orig(p, k, v)
	end
	mt.__e79 = true
	return inst
end

local function newInst(className)
	return patchInst(mock.Instance.new(className))
end

------------------------------------------------------------------ quad
local E = { Quad = Quad, mock = mock, EG = EG, S = S, patchInst = patchInst }

local timerQuad = Quad.New()
timerQuad:UseProvider(mock.mockProvider)

function E.newProv()
	local q = Quad.New()
	q:UseProvider(QuadRoblox)
	;(getfenv(q.Declaration.New)).Instance = { new = newInst }
	q.Backend.isInst = mock.isMockInstance
	-- virtual-clock timers (mock) instead of task.delay; each timer callback is a resumption point
	local st, ct = timerQuad.Backend.setTimeout, timerQuad.Backend.clearTimeout
	q.Backend.setTimeout = function(fn, d)
		return st(function()
			fn()
			S.flush()
		end, d)
	end
	q.Backend.clearTimeout = ct
	return q
end

-- "engine" writes (user typing etc.) — go through the patched proxy
function E.engineWrite(inst, k, v)
	inst[k] = v
end

-- "engine" event (input) — fire the instance's declared event
function E.engineEvent(inst, name, ...)
	inst[name]:Fire(...)
end

E.idOf = idOf
return E
