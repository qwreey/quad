--!nocheck
-- round13 E14 probe (scratch) — Modifier factory / setter chain / __apply / typed factory.
-- Run from repo root: `luau .claude/audit/round13-e14-probe.luau` (after ./scripts/relink.sh).
local Quad = require("../quad-roblox/luau_packages/quad_base")
local QuadRoblox = require("../quad-roblox/src").QuadRoblox
local installProperty = require("../quad-roblox/src/Handlers/Property")
local installEvent = require("../quad-roblox/src/Handlers/Event")
local installShorthand = require("../quad-roblox/src/Handlers/InstanceShorthand")
local installEngineOps = require("../quad-roblox/src/EngineOps")
local mock = require("../quad-base/test/mock")

local W = { Write = "" }
local function props(...)
	local t = {}
	for _, n in { ... } do table.insert(t, { Name = n, Permits = W }) end
	return t
end
local REFLECTED = {
	Frame = props("Name", "Size", "Visible", "BackgroundTransparency", "LayoutOrder", "ZIndex", "BackgroundColor3", "BorderSizePixel", "Style", "Position"),
	TextButton = props("Name", "Text", "Visible", "Size", "TextSize", "BackgroundColor3", "TextColor3", "BorderSizePixel", "ZIndex", "Position", "FontFace", "BackgroundTransparency"),
	TextLabel = props("Name", "Text", "Visible", "Size", "TextSize", "TextColor3", "BackgroundTransparency", "ZIndex"),
	UICorner = props("Name", "CornerRadius"),
}
mock.declareEvents("TextButton", { "Activated", "MouseEnter", "MouseButton1Click" })
mock.declareEvents("Frame", { "Changed", "MouseEnter" })
local gameShim = mock.gameShim(REFLECTED)
local q = Quad.New():UseProvider(QuadRoblox)
;(getfenv(installProperty)).game = gameShim
;(getfenv(installProperty)).TweenInfo = mock.tweenInfoShim
;(getfenv(installProperty)).Enum = { EasingStyle = { Quad = "Quad" }, EasingDirection = { Out = "Out" }, PlaybackState = { Completed = "Completed", Cancelled = "Cancelled" } }
;(getfenv(installEvent)).game = gameShim
;(getfenv(installEngineOps)).game = gameShim
;(getfenv(q.Declaration.New)).Instance = { new = mock.Instance.new }
q.Backend.isInst = mock.isMockInstance
local D = q.Declaration
local UDIM_MT = { __eq = function(a, b) return a.Scale == b.Scale and a.Offset == b.Offset end }
UDim = { new = function(s, o) return setmetatable({ Scale = s, Offset = o }, UDIM_MT) end }
local function first(err) return (tostring(err):gsub("\n.*", ""):gsub("^.-/p%-gates2[^/]*/", "")) end
local function try(label, fn) local ok, err = pcall(fn); print(label, ok and "OK" or ("ERR: " .. first(err))) end
local Op = q.Operator
print("== Q104 mod:Apply(State-only factory) ==")
try("M1 mod:Apply(q.Animate{Time=0.3})", function() q.Modifier({ BackgroundTransparency = 0 }):Apply(q.Animate({ Time = 0.3 })) end)
try("M2 mod:Apply(Op.Not)", function() q.Modifier():Apply(Op.Not) end)
try("M3 mod:Apply(Op.Sum(1))", function() q.Modifier():Apply(Op.Sum(1)) end)
try("M4 mod:Apply(forgot return)", function() q.Modifier():Apply(function(m) m:BackgroundTransparency(1) end) end)
try("M5 mod:Apply(returns props table)", function() q.Modifier():Apply(function(m) return { m } end) end)
try("M6 mod:Apply(ok factory)", function() local r = q.Modifier():Apply(function(m) return m:BackgroundTransparency(1) end); assert(q.isModifier(r)) end)
try("M7 mod:Apply(returns a State)", function() q.Modifier():Apply(function(_m) return q.Source(1) end) end)
print("== Q104 setter transform arm ==")
try("S1 Modifier():BT(Animate) old nil", function() q.Modifier():BackgroundTransparency(q.Animate({ Time = 0.3 })) end)
try("S2 Modifier({BT=0.5}):BT(Animate)", function() q.Modifier({ BackgroundTransparency = 0.5 }):BackgroundTransparency(q.Animate({ Time = 0.3 })) end)
try("S3 Modifier():BT(Op.Not) old nil", function() q.Modifier():BackgroundTransparency(Op.Not) end)
try("S4 state old: Modifier({BT=src}):BT(Animate) (legit)", function() local s = q.Source(0.2); local m = q.Modifier({ BackgroundTransparency = s }):BackgroundTransparency(q.Animate({ Time = 0.3 })); assert(q.isState(m:Peek("BackgroundTransparency"))) end)
print("== Q104 boost: Tag:Apply ==")
try("T1 tag:Apply(q.Animate{})", function() q.Tag("a"):Apply(q.Animate({ Time = 0.3 })) end)
try("T2 tag:Apply(Op.Not)", function() q.Tag("a"):Apply(Op.Not) end)
print("== reference: state:Apply ==")
try("R1 src:Apply(Animate) ok", function() local s = q.Source(1); assert(q.isState(s:Apply(q.Animate({ Time = 0.3 })))) end)
try("R2 Animate factory called with a number", function() q.Animate({ Time = 0.3 })(5) end)
print("done")
