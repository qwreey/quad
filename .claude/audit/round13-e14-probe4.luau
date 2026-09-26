--!nocheck
-- round13 E14 probe (scratch) — Modifier factory / setter chain / __apply / typed factory.
-- Run from repo root: `luau .claude/audit/round13-e14-probe.luau` (after ./scripts/relink.sh).
local Quad = require("../../quad-roblox/luau_packages/quad_base")
local QuadRoblox = require("../../quad-roblox/src").QuadRoblox
local installProperty = require("../../quad-roblox/src/Handlers/Property")
local installEvent = require("../../quad-roblox/src/Handlers/Event")
local installShorthand = require("../../quad-roblox/src/Handlers/InstanceShorthand")
local installEngineOps = require("../../quad-roblox/src/EngineOps")
local mock = require("../../quad-base/test/mock")

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
;(getfenv(installShorthand)).UDim = UDim

local function first(err) return (tostring(err):gsub("\n.*", "")) end
local function try(label, fn)
	local ok, err = pcall(fn)
	print(label, ok and "OK" or ("ERR: " .. first(err)))
	return ok, err
end
local FK = require("../../quad-roblox/luau_packages/.pesde/qwreey+quad_base/3.2.0/quad_base/src/Dispatch/Modifier")._FieldsKey
local function fields(m)
	local out = {}
	for k, v in m[FK] do table.insert(out, k .. "=" .. (if q.isState(v) then "<State>" elseif v == q.None then "None" else tostring(v))) end
	table.sort(out)
	return table.concat(out, ",")
end
try("Modifier{ X = Source(Tag) }", function() local f = D.Frame({ q.Modifier({ X = q.Source(q.Tag("a")) }) }); print("  tags", table.concat(mock.getTags(f), ",")) end)
try("inline { X = Source(Tag) }", function() local f = D.Frame({ X = q.Source(q.Tag("a")) }); print("  tags", table.concat(mock.getTags(f), ",")) end)
try("array { Source(Tag) }", function() local f = D.Frame({ q.Source(q.Tag("a")) }); print("  tags", table.concat(mock.getTags(f), ",")) end)
