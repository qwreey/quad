--!nocheck
-- round13 E18 probe C (2026-09-27) — two quad-roblox-backed instances. Run from repo root: luau .claude/audit/round13-e18-probe-c.luau
local Quad = require("../../quad-roblox/luau_packages/quad_base")
local QuadRoblox = require("../../quad-roblox/src").QuadRoblox
local installProperty = require("../../quad-roblox/src/Handlers/Property")
local installEvent = require("../../quad-roblox/src/Handlers/Event")
local installShorthand = require("../../quad-roblox/src/Handlers/InstanceShorthand")
local installEngineOps = require("../../quad-roblox/src/EngineOps")
local mock = require("../../quad-base/test/mock")
local W = { Write = "" }
local REFLECTED = {
	Frame = { { Name = "Name", Permits = W }, { Name = "Size", Permits = W }, { Name = "Visible", Permits = W } },
	TextLabel = { { Name = "Name", Permits = W }, { Name = "Text", Permits = W } },
}
local gameShim = mock.gameShim(REFLECTED)
getfenv(installProperty).game = gameShim
getfenv(installProperty).TweenInfo = mock.tweenInfoShim
getfenv(installProperty).Enum = { EasingStyle = { Quad = "Quad" }, EasingDirection = { Out = "Out" } }
getfenv(installEvent).game = gameShim
getfenv(installEngineOps).game = gameShim
getfenv(installShorthand).UDim = { new = function(s, o) return { Scale = s, Offset = o } end }
local function E(f)
	local ok, err = pcall(f)
	if ok then return "ok" end
	local s = tostring(err)
	return (s:match("Quad%d+[^\n]*") or s):sub(1, 220)
end
local function T(name, f) print(name .. " => " .. E(f)) end

print("== C1 debug=true BEFORE UseProvider(QuadRoblox): tie lines from the official backend? ==")
local A = Quad.New()
A.debug = true
A:UseProvider(QuadRoblox)
print("   (end of A install)")
local B = Quad.New():UseProvider(QuadRoblox)
for _, q in { A, B } do
	getfenv(q.Declaration.New).Instance = { new = mock.Instance.new }
	q.Backend.isInst = mock.isMockInstance
end
print("== C2 surface sharing between two roblox-backed instances ==")
for _, k in { "Declaration", "OnChange", "Out", "Animate", "Tween", "isTween" } do
	print("  ", k, A[k] == B[k] and "SHARED" or "per-instance")
end
print("   A.isTween(B.Tween{Value=1})", A.isTween(B.Tween({ Value = 1 })))

print("== C3 cross placement ==")
T("A.Frame{ B.TextLabel{} } child", function() A.Declaration.Frame { B.Declaration.TextLabel {} } end)
T("A.Frame{ Size = B.Tween{...} }", function() A.Declaration.Frame { Name = "x", Visible = B.Tween({ Value = true }) } end)
T("A.Frame{ B.OnChange('Name', fn) }", function() A.Declaration.Frame { B.OnChange("Name", function() end) } end)
T("A.Frame{ Name = A.Source('x'):Apply(B.Animate{Time=1}) }", function()
	local s = A.Source("x"):Apply(B.Animate({ Time = 1 }))
	print("   result identity is", s._moduleIdentity == A.moduleIdentity and "A" or (s._moduleIdentity == B.moduleIdentity and "B" or "?"))
	A.Declaration.Frame { Name = s }
end)
T("A.Frame{ B.Out('Name', A.Source) }", function() A.Declaration.Frame { B.Out("Name", A.Source("x")) } end)
T("A.Frame{ A.Out('Name', B.Source) } (write-back into B's Source)", function()
	local bs = B.Source("x")
	A.Declaration.Frame { A.Out("Name", bs) }
	print("   bs after mount:", bs:Get())
end)
T("A.Slot():Add(B.Frame{})", function() A.Slot():Add(B.Declaration.Frame {}) end)
T("B.Dispatch.drive(A-made frame, {Name='y'})", function() B.Dispatch.drive(A.Declaration.Frame {}, { Name = "y" }) end)
T("A.Claim(B-made frame, mapper)", function()
	local f = B.Declaration.Frame {}
	A.Claim(f, A.MapperRoot and nil or nil)
end)
T("A.Declaration.New(B-made frame?)", function() end)
T("A.dispose(B-made frame)", function() A.dispose(B.Declaration.Frame {}) end)
T("B.Frame{ Visible = A.Source(true):Apply(A.Animate{Time=1}) }", function()
	B.Declaration.Frame { Visible = A.Source(true):Apply(A.Animate({ Time = 1 })) }
end)

print("== C4 version gate / Version field ==")
T("Version overwritten then UseProvider", function() local m = Quad.New(); m.Version = "2.0.0"; m:UseProvider(QuadRoblox) end)
T("same module, Version fixed, retry", function() local m = Quad.New(); m.Version = "2.0.0"; pcall(function() m:UseProvider(QuadRoblox) end); m.Version = "3.2.0"; m:UseProvider(QuadRoblox); print("   Declaration after retry", m.Declaration ~= nil) end)
T("QuadRoblox via AddPlugin (UB per doc)", function() local m = Quad.New(); m:AddPlugin(QuadRoblox); print("   then UseProvider(QuadRoblox):", E(function() m:UseProvider(QuadRoblox) end)); print("   handlers", #m.Dispatch.listHandlers()) end)
T("handler count single install", function() print("   handlers", #Quad.New():UseProvider(QuadRoblox).Dispatch.listHandlers()) end)

print("== C5 user isX helper vs Declaration ==")
T("q.isArray helper then D.Frame{ child }", function()
	local m = Quad.New():UseProvider(QuadRoblox)
	getfenv(m.Declaration.New).Instance = { new = mock.Instance.new }
	m.Backend.isInst = mock.isMockInstance
	m.isNonEmptyList = function(t) return type(t) == "table" and #t > 0 end
	m.Declaration.Frame { m.Declaration.TextLabel {} }
end)
T("plugin-added isX via AddPlugin then D.Frame{Name='x'}", function()
	local m = Quad.New():UseProvider(QuadRoblox)
	getfenv(m.Declaration.New).Instance = { new = mock.Instance.new }
	m.Backend.isInst = mock.isMockInstance
	m:AddPlugin(function() return { isConfig = function(t) return type(t) == "table" and next(t) ~= nil end } end)
	m.Declaration.Frame { Name = "x" }
end)

print("== C6 Claim across instances ==")
T("A.Claim(B-made frame, A mapper) — double ownership", function()
	local f = B.Declaration.Frame { Name = "b" }
	local M = A.Declaration.Mapper
	A.Claim(f, M.Frame(M.Root)({ Name = "claimedByA" }))
	print("   A.isClaimed", A.Backend.isClaimed(f), "B.isClaimed", B.Backend.isClaimed(f), "Name", f.Name)
	B.Dispatch.drive(f, { Name = "B-again" })
	print("   after B drive Name", f.Name)
end)
T("A.Claim(f, B mapper descriptor)", function()
	local f = mock.Instance.new("Frame")
	local MB = B.Declaration.Mapper
	A.Claim(f, MB.Frame(MB.Root)({ Name = "x" }))
	print("   claimed by A with B descriptor: Name", f.Name)
end)
