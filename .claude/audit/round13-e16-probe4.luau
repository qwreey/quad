--!nocheck
-- round13 E16 probe 4 (2026-09-27) — reference core/07·core/09 + GS 05·07·09 examples under mock. Run from repo root: luau .claude/audit/round13-e16-probe4.luau
local Quad = require("../../quad-roblox/luau_packages/quad_base")
local QuadRoblox = require("../../quad-roblox/src").QuadRoblox
local installProperty = require("../../quad-roblox/src/Handlers/Property")
local installEvent = require("../../quad-roblox/src/Handlers/Event")
local installEngineOps = require("../../quad-roblox/src/EngineOps")
local mock = require("../../quad-base/test/mock")
local Instance = mock.Instance
local W = { Write = "" }
local REFLECTED = {
	Frame = { { Name = "Name", Permits = W }, { Name = "Size", Permits = W }, { Name = "Visible", Permits = W } },
	TextLabel = { { Name = "Name", Permits = W }, { Name = "Text", Permits = W } },
}
local gameShim = mock.gameShim(REFLECTED)
local q: any = Quad.New():UseProvider(QuadRoblox)
getfenv(installProperty).game = gameShim
getfenv(installProperty).TweenInfo = mock.tweenInfoShim
getfenv(installProperty).Enum = { EasingStyle = { Quad = "Quad" }, EasingDirection = { Out = "Out" } }
getfenv(installEvent).game = gameShim
getfenv(installEngineOps).game = gameShim
getfenv(q.Declaration.New).Instance = { new = mock.Instance.new }
q.Backend.isInst = mock.isMockInstance
local D, None = q.Declaration, q.None
local log = {}
local osa = q.Backend.setAttr
q.Backend.setAttr = function(i, k, v) table.insert(log, k .. "=" .. tostring(v)); return osa(i, k, v) end
local function L() local s = table.concat(log, " "); table.clear(log); return s end
local function attrs(i) local t = {} for k, v in mock.getAttributes(i) do table.insert(t, k .. "=" .. tostring(v)) end table.sort(t) return table.concat(t, ",") end
local function first(e) return (tostring(e):gsub("\n.*", "")) end
local function sec(name, f) print("=== " .. name .. " ==="); local ok, e = pcall(f); if not ok then print("  !! ERR:", first(e)) end end
local function try(label, f) local ok, e = pcall(f); print("  " .. label, ok and "ok" or ("ERR " .. first(e))); return ok end
local QuadTypes = { None = None }
local task = { spawn = function(f, ...) local co = coroutine.create(f); assert(coroutine.resume(co, ...)) end }
getfenv(installProperty).Enum = getfenv(installProperty).Enum
REFLECTED.TextButton = { { Name = "Name", Permits = W }, { Name = "Text", Permits = W }, { Name = "BackgroundTransparency", Permits = W } }
REFLECTED.TextBox = { { Name = "Name", Permits = W }, { Name = "Text", Permits = W } }
mock.declareEvents("TextButton", { "Activated" })
local function fire(inst, ev) inst[ev]:Fire() end

sec("core/07 boxRef", function()
	local boxRef = q.Ref(nil)
	local panel = D.Frame { boxRef, D.TextLabel { Text = "제목" } }
	print("  boxRef==panel", boxRef.Value == panel)
end)
sec("core/07 PreRef inputRef + Activated Unwrap", function()
	local inputRef = q.PreRef(nil)
	local btn
	local form = D.Frame { D.TextBox { inputRef }, D.TextButton { Text = "지우기", Activated = function() inputRef:Unwrap().Text = "" end } }
	for _, c in form:GetChildren() do if c.ClassName == "TextButton" then btn = c end end
	inputRef.Value.Text = "abc"; fire(btn, "Activated"); print("  text after click [", inputRef.Value.Text, "]")
end)
sec("core/07 PostRef doneRef registered after build", function()
	local doneRef = q.PostRef(nil)
	local card = D.Frame { doneRef, D.TextLabel { Text = "A" }, D.TextLabel { Text = "B" } }
	doneRef:Callback(function(inst) if inst then print("  kids", #inst:GetChildren()) end end)
end)
sec("core/07 Set chain / Wait", function()
	local ref = q.Ref(0)
	ref:Callback(function(v) print("  값", v) end)
	ref:Set(1):Set(2)
	local r2 = q.Ref(nil)
	task.spawn(function() local value = r2:Wait().Value; print("  도착", value) end)
	r2:Set("hello")
end)
sec("core/07 btnRef Unwrap", function()
	local btnRef = q.PreRef(nil)
	local button = D.TextButton { btnRef, Text = "보내기", Activated = function() btnRef:Unwrap().BackgroundTransparency = 0.5 end }
	fire(button, "Activated"); print("  BT", button.BackgroundTransparency)
end)
sec("core/09 Tag examples", function()
	local interactive = q.Tag("clickable", "focusable")
	local button = D.TextButton { interactive, q.Tag("primary"), Text = "확인" }
	print("  tags", table.concat(mock.getTags(button), ","))
	local base = q.Tag("card"); local isSelected = true
	print("  ", tostring(base:Added("selected")), tostring(base:Added({ "selected", "hovered" })), tostring(base:Added(if isSelected then "selected" else nil)))
	local tag = q.Tag("card", "selected")
	print("  contains", tag:Contains("card"), tag:Contains("card", "selected"), tag:Contains("card", "missing"))
	local a, b = q.Tag("x"), q.Tag("y")
	print("  merged", tostring(q.Tag.Merged(a, b)), tostring(q.Tag(a, b)))
end)
sec("core/09 Attr examples", function()
	local hp = q.Source(100)
	local stats = D.Frame { q.Attr({ Hp = hp, Name = "hero" }), D.TextLabel { Text = "체력" } }
	hp:Set(80); print("  ", attrs(stats)); hp:Set(q.None); print("  ", attrs(stats))
	local attr = q.Attr({ A = 1, B = q.Source("x"), C = q.None }); local map = attr:NameMap(); print("  map.A", map.A, map.C == q.None)
	local theme = q.Attr({ Accent = "blue", Size = 1 }); local override = q.Attr({ Accent = "red" })
	print("  overridden", q.Attr.Overridden(theme, override):NameMap().Accent)
	try("merged overlap", function() q.Attr.Merged(theme, override) end)
	local marker = D.Frame { [q.AttrKey("SpawnColor")] = "Color3(1,0,0)-stand-in" }; print("  ", attrs(marker))
	local label = q.Source("hero")
	local card = D.Frame { q.StringAttr("Label", label), q.StringAttr("Kind", "unit") }
	label:Set("villain"); print("  ", attrs(card))
	local blank = D.Frame { q.StringAttr("Label", q.None) }; print("  blank [", attrs(blank), "]")
	local hp2 = q.Source(100); local alive = D.Frame { q.NumberAttr("Hp", hp2), q.BooleanAttr("Friendly", true) }; print("  ", attrs(alive))
end)
sec("GS 05 §1 details: two positions Card", function()
	local st = q.Source(q.Tag("Card", "Panel"))
	local inst = D.Frame { q.Tag("Card"), st }
	print("  tags", table.concat(mock.getTags(inst), ","), L())
	st:Set(q.Tag()); print("  after 2nd empty", table.concat(mock.getTags(inst), ","), L())
end)
sec("GS 09 §1 vs §2 output identity incl. UICorner child count (UICorner omitted here)", function()
	local created = q.PreRef(nil); created:Callback(function(inst) if inst then print("  만들어짐:", inst.ClassName) end end)
	local rendered = q.PostRef(nil); rendered:Callback(function(inst) if inst then print("  다 그려짐: 자식", #inst:GetChildren(), "개") end end)
	local card = D.Frame { created, rendered, q.Effect(function() return function() print("  없어짐") end end), D.TextLabel {}, D.TextButton {} }
	card:Destroy()
	local card2 = D.Frame { q.OnCreated(function(inst) print("  만들어짐:", inst.ClassName) end), q.OnRendered(function(inst) print("  다 그려짐: 자식", #inst:GetChildren(), "개") end), q.OnDestroyed(function() print("  없어짐") end), D.TextLabel {}, D.TextButton {} }
	card2:Destroy()
end)
sec("sugar/04 example AnimatedBox", function()
	local function AnimatedBox()
		return D.Frame { Size = "UDim2(100,100)", q.OnCreated(function(inst) print("  생성됨:", inst.ClassName) end), q.OnRendered(function(inst) print("  자기 서브트리 완성:", inst.Size) end), q.OnDestroyed(function() print("  파괴 및 정리됨") end) }
	end
	AnimatedBox():Destroy()
end)
