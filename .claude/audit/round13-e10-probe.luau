--!nocheck
-- round13 E10 probe — Reflection / Property value path / EngineOps (mock). Not a spec.
local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local installProperty = require("../src/Handlers/Property")
local installEvent = require("../src/Handlers/Event")
local mock = require("../../quad-base/test/mock")

local W = { Write = "" }
local REFLECTED = {
	Frame = {
		{ Name = "Name", Permits = W },
		{ Name = "Size", Permits = W },
		{ Name = "Visible", Permits = W },
		{ Name = "BackgroundTransparency", Permits = W },
		{ Name = "Parent", Permits = W },
		{ Name = "AbsoluteSize", Permits = {} },
		{ Name = "Draggable", Permits = W },
	},
	TextLabel = {
		{ Name = "Name", Permits = W },
		{ Name = "Text", Permits = W },
		{ Name = "Font", Permits = W },
		{ Name = "FontFace", Permits = W },
		{ Name = "TextSize", Permits = W },
		{ Name = "FontSize", Permits = W },
	},
	ImageLabel = { { Name = "Name", Permits = W } },
}
local calls = {}
local counted = setmetatable({}, { __index = function(_, c) calls[c] = (calls[c] or 0) + 1; return REFLECTED[c] end })
mock.declareEvents("Frame", { "Changed", "MouseEnter" })
local gameShim = mock.gameShim(counted)
local q = Quad.New():UseProvider(QuadRoblox)
;(getfenv(installProperty)).game = gameShim
;(getfenv(installEvent)).game = gameShim
;(getfenv(installProperty)).TweenInfo = mock.tweenInfoShim
;(getfenv(installProperty)).Enum = { EasingStyle = { Quad = "Quad" }, EasingDirection = { Out = "Out" }, PlaybackState = { Completed = "Completed", Cancelled = "Cancelled" } }
;(getfenv(q.Declaration.New)).Instance = { new = mock.Instance.new }
q.Backend.isInst = mock.isMockInstance
q.errorNamespace.setFuncLevel(require("../luau_packages/quad_types").ERROR_LEVEL_SURFACE, q.Backend.isInst)
local D = q.Declaration

local function try(label, fn)
	local ok, err = pcall(fn)
	print(label, ok and "OK" or ("ERR: " .. tostring(err)))
	return ok, err
end

print("== P1 key surface (Quad0076 hint) ==")
try("lowercase size", function() D.Frame({ size = 1 }) end)
try("readonly AbsoluteSize", function() D.Frame({ AbsoluteSize = 1 }) end)
try("other-class Text on Frame", function() D.Frame({ Text = "x" }) end)
try("Parent string key", function() D.Frame({ Parent = mock.Instance.new("Frame") }) end)
try("Draggable (outside type allowlist, reflection lists it)", function() local f = D.Frame({ Draggable = true }); print("  Draggable=", f.Draggable) end)
try("Font on TextLabel", function() local t = D.TextLabel({ Font = "GothamBold" }); print("  Font=", t.Font) end)
try("method name Destroy as key", function() D.Frame({ Destroy = 1 }) end)
try("event Changed", function() local n = 0; local f = D.Frame({ Changed = function() n += 1 end }); f.Changed:Fire(); print("  Changed fires", n) end)
try("readonly AbsoluteSize via State", function() local s = q.Source(1); D.Frame({ AbsoluteSize = s }) end)

print("== P2 Name with State / None ==")
do
	local s = q.Source("A")
	local f = D.Frame({ Name = s })
	print("name", f.Name)
	s:Set("B"); print("name after B", f.Name)
	try("Name = None", function() s:Set(q.None) end)
	print("name after None", f.Name)
	try("Set C after failed None", function() s:Set("C") end)
	print("name after C", f.Name)
	try("Set D", function() s:Set("D") end)
	print("name after D", f.Name)
end

print("== P3 None -> value -> None, State swap ==")
do
	local s = q.Source(true)
	local f = D.Frame({ Visible = s })
	s:Set(q.None); print("visible after None", f.Visible)
	s:Set(false); print("visible after false", f.Visible)
	s:Set(q.None); print("visible after None2", f.Visible)
	local s2 = q.Source(0.5)
	q.Dispatch.drive(f, { Visible = s2 })
	s:Set(true); print("after old s:Set(true) visible =", f.Visible, "(expect 0.5)")
	s2:Set(0.25); print("after s2:Set visible =", f.Visible)
end

print("== P4 same-value re-set: Changed signal count (mock vs engine) ==")
do
	local s = q.Source(5)
	local f = D.Frame({ Size = s })
	local n = 0
	f:GetPropertyChangedSignal("Size"):Connect(function() n += 1 end)
	s:Set(5) -- State dedup?
	print("State Set same value -> changed", n)
	q.Dispatch.drive(f, { Size = 5 })
	print("plain same value re-drive -> changed", n)
	local t = { 1 } -- table 'value type' stand-in
	q.Dispatch.drive(f, { Size = t }); q.Dispatch.drive(f, { Size = t })
	print("same table twice -> changed", n)
end

print("== P5 tween dedup with value-type stand-ins (mock only) ==")
do
	mock.resetTweenLog()
	local f = D.Frame({ Size = 0 })
	local Tw = q.Tween
	q.Dispatch.drive(f, { Size = Tw({ Value = 10, Time = 1 }) })
	local n1 = #mock.tweenLog
	q.Dispatch.drive(f, { Size = Tw({ Value = 10, Time = 1 }) })
	print("number same target: tweens", n1, #mock.tweenLog)
	-- value-type stand-in with __eq (engine UDim2/Color3 compare by value)
	local mt = { __eq = function(a, b) return a.x == b.x end }
	local function V(x) return setmetatable({ x = x }, mt) end
	local g = D.Frame({ Size = V(0) })
	local c0 = #mock.tweenLog
	q.Dispatch.drive(g, { Size = Tw({ Value = V(3), Time = 1 }) })
	q.Dispatch.drive(g, { Size = Tw({ Value = V(3), Time = 1 }) })
	print("__eq value type same target: new tweens", #mock.tweenLog - c0, "(1 = dedup ok)")
	-- float32 quantization on read-back (engine stores float props as float32): teardown retractor compares inst[k] == slot.Value
	local function f32(x) return (string.unpack("f", string.pack("f", x))) end
	local h = D.Frame({ BackgroundTransparency = 0 })
	local c1 = #mock.tweenLog
	q.Dispatch.drive(h, { BackgroundTransparency = Tw({ Value = 0.1, Time = 1 }) })
	local rec = mock.tweenLog[#mock.tweenLog]
	h.BackgroundTransparency = f32(0.1) -- what the engine leaves after interpolation ends
	rec.tween:simulateCompleted()
	q.Dispatch.retractFrom(h, "BackgroundTransparency", 1)
	q.Dispatch.drive(h, { BackgroundTransparency = Tw({ Value = 0.1, Time = 1 }) })
	print("float32 readback: tweens after teardown+same target", #mock.tweenLog - c1, "(1 = record kept {Value}; 2 = downgraded to true, replays)")
	-- control: exact value
	local h2 = D.Frame({ BackgroundTransparency = 0 })
	local c2 = #mock.tweenLog
	q.Dispatch.drive(h2, { BackgroundTransparency = Tw({ Value = 0.5, Time = 1 }) })
	local rec2 = mock.tweenLog[#mock.tweenLog]
	h2.BackgroundTransparency = f32(0.5)
	rec2.tween:simulateCompleted()
	q.Dispatch.retractFrom(h2, "BackgroundTransparency", 1)
	q.Dispatch.drive(h2, { BackgroundTransparency = Tw({ Value = 0.5, Time = 1 }) })
	print("control exact 0.5: tweens", #mock.tweenLog - c2)
end

print("== P6 Reflection cache vs runtime REFLECTED change ==")
do
	try("Frame.Rotation before add", function() D.Frame({ Rotation = 1 }) end)
	table.insert(REFLECTED.Frame, { Name = "Rotation", Permits = W })
	try("Frame.Rotation after add (cached)", function() D.Frame({ Rotation = 1 }) end)
	try("TextButton unknown class before", function() D.New("TextButton")({ Text = "a" }) end)
	REFLECTED.TextButton = { { Name = "Text", Permits = W } }
	try("TextButton after REFLECTED add (cached empty)", function() D.New("TextButton")({ Text = "a" }) end)
	print("reflection calls Frame", calls.Frame, "TextButton", calls.TextButton)
end

print("== P7 nativeFindChild duplicates / class ==")
do
	local root = mock.Instance.foreign("Frame")
	local a = mock.Instance.foreign("ImageLabel"); a.Name = "Kid"; a.Parent = root
	local b = mock.Instance.foreign("TextLabel"); b.Name = "Kid"; b.Parent = root
	print("find Kid TextLabel ->", q.Backend.nativeFindChild(root, "Kid", "TextLabel"))
	print("find Kid ImageLabel ->", q.Backend.nativeFindChild(root, "Kid", "ImageLabel"))
	local M = D.Mapper
	try("Claim TextLabel Kid with ImageLabel Kid first", function()
		q.Claim(root, M.Frame(M.Root)({ M.TextLabel("Kid")({ Text = "hi" }) }))
		print("  b.Text", b.Text)
	end)
end

print("== P8 Parent read surface via OnChange ==")
try("OnChange Parent", function()
	local seen = {}
	local f = D.Frame({ q.OnChange("Parent", function(v) table.insert(seen, v == nil and "nil" or tostring(v)) end) })
	f.Parent = mock.Instance.new("Frame")
	print("  seen", table.concat(seen, ","))
end)

print("== P9 quad-branded values at a REAL property key (Visible) ==")
do
	local cands = {
		Ref = function() return q.Ref() end,
		Slot = function() return q.Slot() end,
		Tag = function() return q.Tag("x") end,
		Attr = function() return q.Attr({ A = 1 }) end,
		Modifier = function() return q.Modifier({ Visible = true }) end,
		Observer = function() return q.Observer(q.Source(1), function() end) end,
		Context = function() return q.Context(1) end,
		Store = function() return q.Store({ a = 1 }) end,
		PreRef = function() return q.PreRef(function() end) end,
		Blocker = function() return q.Blocker() end,
		Void = function() return q.Void end,
	}
	for name, mk in cands do
		local okMk, v = pcall(mk)
		if not okMk then
			print(name, "ctor failed:", v)
		else
			local ok, err = pcall(function()
				local f = D.Frame({ Visible = v })
				local got = f.Visible
				print(name, "-> accepted, f.Visible is", typeof(got), got == v and "(the quad value itself)" or "")
			end)
			if not ok then print(name, "-> ERR", err) end
		end
	end
end

print("== P10 native* ops on keyed reorder (Slot:List) ==")
do
	local ops = {}
	for _, name in { "nativeInsert", "nativeExtract", "nativeRemove", "nativeMove", "nativeSwap" } do
		local orig = q.Backend[name]
		q.Backend[name] = function(...)
			local args = table.pack(...)
			local function names(t) if type(t) ~= "table" then return tostring(t) end local o = {} for _, e in t do table.insert(o, tostring(e)) end return "[" .. table.concat(o, ",") .. "]" end
			table.insert(ops, name .. " " .. names(args[3]) .. (args[4] ~= nil and (" 4th=" .. names(args[4])) or ""))
			return orig(...)
		end
	end
	local ok2, err2 = pcall(function()
		local items = q.Source({ "x", "y" })
		local made = {}
		local slot = q.Slot()
		local host = D.Frame({ slot })
		slot:List(items, function(ctx)
			if ctx.Item == q.KeyGone then return nil end
			if ctx.Prev ~= nil then return ctx.Prev end
			local e = D.Frame({ Name = ctx.Item }); made[ctx.Item] = e; return e
		end, function(item) return item end)
		local x = made.x
		local xn = 0
		x:GetPropertyChangedSignal("Parent"):Connect(function() if x.Parent == nil then xn += 1 end end)
		items:Set({ "y", "x" })
		items:Set({ "x", "z" })
		print("  list: x nil transitions", xn, "x.Parent==host", x.Parent == host, "y destroyed", mock.isDestroyed(made.y))
	end)
	if not ok2 then print("ERR2", err2) end
	for _, o in ops do print("  ", o) end
end

print("== P11 record vs property divergence (external write) ==")
do
	-- plain path reasserts
	local pos = q.Source(0)
	local f = D.Frame({ Size = pos })
	f.Size = 500 -- engine/user/drag wrote it
	pos:Set(0)
	print("plain: after external write 500 then Set(0): Size =", f.Size)
	-- Animate path
	local pos2 = q.Source(0)
	local g = D.Frame({ Size = pos2:Apply(q.Animate({ Time = 0.2 })) })
	local c0 = #mock.tweenLog
	g.Size = 500 -- e.g. UIDragDetector / user scroll / TextBox typing
	pos2:Set(0)
	print("Animate: after external write 500 then Set(0): Size =", g.Size, "new tweens", #mock.tweenLog - c0)
	-- engine-tween completed then external write
	pos2:Set(40)
	local rec = mock.tweenLog[#mock.tweenLog]; g.Size = 40; rec.tween:simulateCompleted()
	g.Size = 999
	local c1 = #mock.tweenLog
	pos2:Set(40)
	print("Animate after completed tween + external 999, Set(40): Size =", g.Size, "new tweens", #mock.tweenLog - c1)
end

print("== P12 legacy alias pairs in one props table: write order = hash order ==")
do
	local t = D.TextLabel({})
	local order = {}
	for _, k in { "Font", "FontFace", "TextSize", "FontSize" } do
		t:GetPropertyChangedSignal(k):Connect(function() table.insert(order, k) end)
	end
	q.Dispatch.drive(t, { Font = "Legacy", FontFace = "Modern" })
	print("  literal {Font, FontFace}:", table.concat(order, ","))
	table.clear(order)
	q.Dispatch.drive(t, { FontFace = "Modern2", Font = "Legacy2" })
	print("  literal {FontFace, Font}:", table.concat(order, ","))
	table.clear(order)
	q.Dispatch.drive(t, { TextSize = 14, FontSize = "Size24" })
	print("  literal {TextSize, FontSize}:", table.concat(order, ","))
	table.clear(order)
	q.Dispatch.drive(t, { q.Modifier({ FontFace = "M3" }), Font = "L3" })
	print("  Modifier{FontFace} + inline Font:", table.concat(order, ","))
end
