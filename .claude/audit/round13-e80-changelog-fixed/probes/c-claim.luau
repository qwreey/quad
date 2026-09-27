--!nocheck
-- E80 group C: Claim Fixed bullets (F8 F9 F35 F41) + Changed C28
local H = require("../harness")
local L = require("../lib")
local q, D, mock = H.q, H.D, H.mock
local M = D.Mapper
local Instance = mock.Instance
-- 3.2.0엔 isClaimed op가 없다 — 대조 실행에선 잔여를 "고친 재시도"로만 판정
local function claimed(i) return q.Backend.isClaimed ~= nil and q.Backend.isClaimed(i) end

local function tmpl()
	local root = Instance.new("Frame")
	local title = Instance.new("TextLabel"); title.Name = "Title"; title.Parent = root
	local img = Instance.new("ImageLabel"); img.Name = "Kid"; img.Parent = root
	return root, title, img
end

print("--- F8: Claim 실패(키 부재·클래스 불일치·재사용·같은 자식 둘)가 아무것도 안 남김, 고친 재시도 성공 ---")
for _, case in {
	{ "missing key", function() return M.Frame(M.Root)({ M.TextLabel("Title")({ Name = "t" }), M.Frame("Nope")({}) }) end },
	{ "class mismatch", function() return M.Frame(M.Root)({ M.TextLabel("Title")({ Name = "t" }), M.TextLabel("Kid")({}) }) end },
	{ "descriptor reuse", function() local d = M.TextLabel("Title")({ Name = "t" }); return M.Frame(M.Root)({ d, d }) end },
	{ "two descs same child", function() return M.Frame(M.Root)({ M.TextLabel("Title")({ Name = "a" }), M.TextLabel("Title")({ Name = "b" }) }) end },
} do L.section(function()
	local root, title = tmpl()
	local m, id = L.err("F8 " .. case[1], function() q.Claim(root, case[2]()) end)
	L.check("F8 " .. case[1] .. ": no residue", not claimed(root) and not claimed(title) and title.Name == "Title", id)
	local ok, e = pcall(function() q.Claim(root, M.Frame(M.Root)({ M.TextLabel("Title")({ Name = "fixed" }) })) end)
	L.check("F8 " .. case[1] .. ": fixed retry ok", ok and title.Name == "fixed", ok and "ok" or L.first(e))
end) end
L.section(function() -- already-claimed root leaves nothing
	local root, title = tmpl()
	q.Backend.nativeClaim(root)
	local m, id = L.err("F8 claimed root", function() q.Claim(root, M.Frame(M.Root)({ M.TextLabel("Title")({ Name = "t" }) })) end)
	L.check("F8 claimed root: child untouched", title.Name == "Title" and not claimed(title), id)
end)

print("--- F9: [0]/[-1]/[1.5] 디스크립터 → 해석 단계 거부 ---")
for _, k in { 0, -1, 1.5 } do L.section(function()
	local root, title = tmpl()
	local m, id = L.err("F9 key " .. k, function() q.Claim(root, M.Frame(M.Root)({ [k] = M.TextLabel("Title")({ Name = "z" }) })) end)
	L.check("F9 key " .. k .. " message", L.has(m, "Claim: array keys must be positive integers (got " .. tostring(k) .. ")"), id)
	L.check("F9 key " .. k .. " nothing left", not claimed(root) and title.Name == "Title", "")
end) end

print("--- F35: 매퍼 키 부재 → Claim: no child matched key; 클래스 다른 자식도 같은 에러 ---")
L.section(function()
	local root = tmpl()
	local m, id = L.err("F35 missing", function() q.Claim(root, M.Frame(M.Root)({ M.Frame("Nope")({}) })) end)
	L.check("F35 message names key", L.has(m, "Claim: no child matched key Nope under"), id)
	local root2 = tmpl()
	local m2, id2 = L.err("F35 class mismatch (Kid is ImageLabel)", function() q.Claim(root2, M.Frame(M.Root)({ M.TextLabel("Kid")({}) })) end)
	L.check("F35 class mismatch same error", id2 == id and L.has(m2, "no child matched key Kid"), id2)
	-- 3-arg nativeFindChild contract
	local seen
	local orig = q.Backend.nativeFindChild
	q.Backend.nativeFindChild = function(inst, key, cls) seen = cls; return orig(inst, key, cls) end
	local root3 = tmpl()
	pcall(function() q.Claim(root3, M.Frame(M.Root)({ M.TextLabel("Title")({}) })) end)
	q.Backend.nativeFindChild = orig
	L.check("F35 nativeFindChild receives className", seen == "TextLabel", tostring(seen))
end)

print("--- F41: q.debug가 켜지면 Claim이 두 실수를 print ---")
L.section(function()
	local log = {}
	local origPrint = print
	q.debug = true
	local root = tmpl()
	getfenv(q.Claim).print = function(...) table.insert(log, table.concat({ ... }, " ")) end
	pcall(function() q.Claim(root, M.Frame("Name")({})) end)
	local root2 = tmpl()
	pcall(function() q.Claim(root2, M.Frame(M.Root)({ M.TextLabel(M.Root)({}) })) end)
	getfenv(q.Claim).print = origPrint
	q.debug = false
	for _, l in log do print("  debug: " .. l) end
	L.check("F41 root string key noted", log[1] ~= nil and L.has(log[1], "root descriptor's key"), log[1])
	L.check("F41 non-string child key noted", log[2] ~= nil and L.has(log[2], "child descriptor key is a"), log[2])
end)

print("--- C28: 이미 quad 소유인 자식/루트 거부, 루트·형제 무손상, 빼면 재시도 가능 ---")
L.section(function()
	local root, title = tmpl()
	local w = D.Frame { Name = "Widget" }
	w.Parent = root
	local m, id = L.err("C28 owned child", function() q.Claim(root, M.Frame(M.Root)({ M.TextLabel("Title")({ Name = "t" }), M.Frame("Widget")({}) })) end)
	L.check("C28 message shape", L.has(m, "Claim: Widget is already claimed by quad"), id)
	L.check("C28 root/sibling untouched", not claimed(root) and not claimed(title) and title.Name == "Title", "")
	local ok = pcall(function() q.Claim(root, M.Frame(M.Root)({ M.TextLabel("Title")({ Name = "t" }) })) end)
	L.check("C28 retry without it ok", ok and title.Name == "t", "")
	local wr = D.Frame {}
	local m2, id2 = L.err("C28 owned root", function() q.Claim(wr, M.Frame(M.Root)({})) end)
	L.check("C28 owned root message", L.has(m2, "is already claimed by quad"), id2)
end)
L.done()
