--!nocheck
-- round13 E20 probe H — Immediate Destroy wave: a dying cleanup / OnDestroyed Sets a Source; does an Observer bound to the
-- same dying host (or a descendant) still run? Effect sibling holds via _dying. Run from repo root.
local mock = require("../../quad-base/test/mock")
local Instance = mock.Instance
local q = mock.newQuad()
for _, trig in { "EffectCleanup", "OnDestroyed" } do
	local isOpen = q.Source(true)
	local log = {}
	local host = Instance.new("Frame")
	local child = Instance.new("Frame"); child.Parent = host
	local obsHost = isOpen:Observer(function(t, _, from) if from then table.insert(log, "obsHost(parent=" .. tostring(host.Parent) .. ")") end end)
	local obsChild = isOpen:Observer(function(t, _, from) if from then table.insert(log, "obsChild") end end)
	local effSib = q.Effect(function() if not isOpen:Get() then table.insert(log, "effSib-fn") end end, isOpen)
	local trigger
	if trig == "EffectCleanup" then
		trigger = q.Effect(function() return function(dying) if dying then isOpen:Set(false) end end end)
	else
		trigger = q.OnDestroyed(function() isOpen:Set(false) end)
	end
	-- bind the trigger FIRST so its Destroying callback fires LAST? mock fires newest-first → bind trigger last to fire first
	q.Dispatch.drive(host, { obsHost, effSib, trigger })
	q.Dispatch.drive(child, { obsChild })
	host:Destroy()
	print(trig, "→", table.concat(log, ", "))
end
