--!nocheck
-- round13 E25 probe — generated Declaration surface × runtime Reflection match (mock).
-- Run from repo root: luau .claude/audit/round13-e25-probe.luau   (after ./scripts/relink.sh)
-- The shim is built FROM api-surface.json (props → Permits.Write, readProps → no Write, + Parent with Write,
-- events declared) — i.e. it models "ReflectionService == pinned dump surface". What the REAL
-- ReflectionService returns for dropped members is engine-side and not measured here.
local Quad = require("../../quad-roblox/luau_packages/quad_base")
local QuadRoblox = require("../../quad-roblox/src").QuadRoblox
local installProperty = require("../../quad-roblox/src/Handlers/Property")
local installEvent = require("../../quad-roblox/src/Handlers/Event")
local installShorthand = require("../../quad-roblox/src/Handlers/InstanceShorthand")
local mock = require("../../quad-base/test/mock")
local DATA = require("./round13-e25-probe-data")

local W = { Write = "Edit" }
local REFLECTED = {}
for cls, c in DATA do
	local list = { { Name = "Parent", Permits = W } }
	for _, p in c.props do table.insert(list, { Name = p.n, Permits = W }) end
	for _, p in c.readProps do if p.n ~= "Parent" then table.insert(list, { Name = p.n, Permits = {} }) end end
	REFLECTED[cls] = list
	mock.declareEvents(cls, c.events)
end
-- extra classes for the D.New / abstract-class axis
REFLECTED.GuiObject = { { Name = "Size", Permits = W } }
local gameShim = mock.gameShim(REFLECTED)
local q = Quad.New():UseProvider(QuadRoblox)
;(getfenv(installProperty)).game = gameShim
;(getfenv(installProperty)).TweenInfo = mock.tweenInfoShim
;(getfenv(installProperty)).Enum = { EasingStyle = { Quad = "Quad" }, EasingDirection = { Out = "Out" }, PlaybackState = { Completed = "Completed", Cancelled = "Cancelled" } }
;(getfenv(installEvent)).game = gameShim
;(getfenv(require("../../quad-roblox/src/EngineOps"))).game = gameShim
;(getfenv(q.Declaration.New)).Instance = { new = mock.Instance.new }
local UDim = { new = function(s, o) return { Scale = s, Offset = o } end }
;(getfenv(installShorthand)).UDim = UDim
q.Backend.isInst = mock.isMockInstance
q.errorNamespace.setFuncLevel(require("../../quad-roblox/luau_packages/quad_types").ERROR_LEVEL_SURFACE, q.Backend.isInst)
local D = q.Declaration
local function first(err) return (tostring(err):gsub("\n.*", "")) end
local function code(err) return string.match(tostring(err), "Quad%d%d%d%d") or ("<no id> " .. first(err)) end

local SH = { UICorner = 8, UIPadding = UDim.new(0, 4), UIPaddingOffset = 4, UIScale = 1 }

-- A. every write key the generated Param type advertises must be accepted at runtime
local classes = {}
for cls in DATA do table.insert(classes, cls) end
table.sort(classes)
local totals = { accepted = 0, rejected = 0, readRejected = 0, readAccepted = 0, evAccepted = 0, evRejected = 0, shAccepted = 0, shRejected = 0 }
for _, cls in classes do
	local c = DATA[cls]
	local ctor = D[cls]
	assert(ctor, "no D." .. cls)
	for _, p in c.props do
		local ok, err = pcall(function() ctor({ [p.n] = 0 }) end)
		if ok then totals.accepted += 1 else totals.rejected += 1; print("  A-REJ", cls, p.n, code(err)) end
	end
	for _, e in c.events do
		local ok, err = pcall(function() ctor({ [e] = function() end }) end)
		if ok then totals.evAccepted += 1 else totals.evRejected += 1; print("  EV-REJ", cls, e, code(err)) end
	end
	for k, v in SH do
		local ok, err = pcall(function() ctor({ [k] = v }) end)
		if ok then
			totals.shAccepted += 1
			if not c.gui then print("  SH-ACCEPT-nonGui", cls, k) end
		else
			totals.shRejected += 1
			print("  SH-REJ", cls, k, c.gui, code(err))
		end
	end
	-- B. read-only surface must NOT match (types exclude it too)
	for _, p in c.readProps do
		local ok, err = pcall(function() ctor({ [p.n] = 0 }) end)
		if ok then totals.readAccepted += 1; print("  READ-ACCEPT", cls, p.n) else totals.readRejected += 1
			if cls == "Frame" then print("  read-rej sample", cls, p.n, code(err)) end
		end
	end
end
print("A/B totals:", totals.accepted, totals.rejected, "read rej/acc", totals.readRejected, totals.readAccepted,
	"ev acc/rej", totals.evAccepted, totals.evRejected, "sh acc/rej", totals.shAccepted, totals.shRejected)

-- C. special keys
local function try(label, fn)
	local ok, err = pcall(fn)
	print("  C", label, ok and "OK" or code(err), ok and "" or first(err))
end
try("Frame Parent", function() D.Frame({ Parent = mock.Instance.new("Folder") }) end)
try("Frame Name", function() D.Frame({ Name = "x" }) end)
try("Frame Archivable", function() D.Frame({ Archivable = false }) end)
try("Frame ClassName", function() D.Frame({ ClassName = "x" }) end)
try("Frame size (lowercase)", function() D.Frame({ size = 1 }) end)
try("Frame archivable (lowercase, dump Deprecated+Hidden)", function() D.Frame({ archivable = false }) end)
try("Frame Draggable (dump Deprecated, dropped)", function() D.Frame({ Draggable = true }) end)
try("TextLabel FontSize (legacy kept)", function() D.TextLabel({ FontSize = 1 }) end)
try("TextLabel Font+FontFace", function() D.TextLabel({ Font = 1, FontFace = 2 }) end)
try("Frame DragBegin (dump Deprecated event, dropped)", function() D.Frame({ DragBegin = function() end }) end)
try("Frame Changed event fn", function() D.Frame({ Changed = function() end }) end)
try("Frame Changed = 5", function() D.Frame({ Changed = 5 }) end)
try("Frame MouseEnter = State<fn>", function() D.Frame({ MouseEnter = q.Source(function() end) }) end)
try("Frame MouseEnter = State<5>", function() D.Frame({ MouseEnter = q.Source(5) }) end)
try("Frame MouseEnter = None", function() D.Frame({ MouseEnter = q.None }) end)
try("Frame MouseEnter = Tween", function() D.Frame({ MouseEnter = q.Tween({ Value = 1 }) }) end)
do
	local s = q.Source(function() end)
	local ok, err = pcall(function() D.Frame({ MouseEnter = s }) end)
	local ok2, err2 = pcall(function() s:Set(5) end)
	print("  C State<fn> → Set(5):", ok, ok2 and "OK" or code(err2))
end
try("Folder UICorner (non-GuiObject shorthand)", function() D.Folder({ UICorner = 8 }) end)
try("UIScale UIScale (shorthand key = own class name)", function() D.UIScale({ UIScale = 2 }) end)
try("D.New GuiObject (abstract)", function() D.New("GuiObject")({ Size = 1 }) end)
try("Frame AbsoluteSize (read-only)", function() D.Frame({ AbsoluteSize = 1 }) end)
try("Frame [AttrKey-like string] Hp", function() D.Frame({ Hp = 1 }) end)
-- D. read-only via Modifier setter
try("Modifier Frame():AbsoluteSize", function() D.Frame({ D.Modifier.Frame():AbsoluteSize(1) }) end)
try("Modifier Frame():Parent", function() D.Frame({ D.Modifier.Frame():Parent(mock.Instance.new("Folder")) }) end)
try("Modifier Frame():UICorner", function() D.Frame({ D.Modifier.Frame():UICorner(4) }) end)
-- E. which name does the engine (mock) get written under?
do
	local t = D.TextLabel({ Font = "legacy" })
	print("  E TextLabel Font write -> Font:", t.Font, "FontFace:", t.FontFace)
	local f = D.Frame({ Transparency = 0.5 })
	print("  E Frame Transparency -> Transparency:", f.Transparency, "BackgroundTransparency:", f.BackgroundTransparency)
end
