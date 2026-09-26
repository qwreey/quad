--!nocheck
-- quad-error blame measurement (pure Luau, no mock). Run: luau [-O2] [--codegen] quad_error_blame.luau
local QE = require("../../../quad-error/src")
local SURF, INNER = 2, 1
local LINES = {}
local M = {}
function M.mark(k) LINES[k] = debug.info(2, "l") end

local ns = QE.new()
local api = {}
-- api.f1 .. api.f4 tagged SURF; each calls the next (or the raiser) on the SAME line as M.mark(k)
local DEPTH, MODE, LEVEL = 0, "errorAt", SURF
function api.raise()
	M.mark("raise"); ns[MODE]("boom", LEVEL)
end
function api.f1() M.mark(1); if DEPTH > 1 then api.f2() else api.helper() end end
function api.f2() M.mark(2); if DEPTH > 2 then api.f3() else api.helper() end end
function api.f3() M.mark(3); if DEPTH > 3 then api.f4() else api.helper() end end
function api.f4() M.mark(4); api.helper() end
function api.helper() M.mark("helper"); api.raise() end -- untagged
ns.setFuncLevel(SURF, api.f1, api.f2, api.f3, api.f4)

local function lineOf(err)
	return tonumber(string.match(tostring(err), ":(%d+): boom$")), tostring(err)
end

local function run(depth, mode, level)
	DEPTH, MODE, LEVEL = depth, mode, level
	table.clear(LINES)
	local ok, err = pcall(function()
		M.mark(0); if depth == 0 then api.helper() else api.f1() end
	end)
	assert(not ok)
	return lineOf(err)
end

-- expectations from the docs: At = line inside the matched tagged frame (its call to the next frame),
-- Before = the line that called the matched frame; outermost = f1, nearest = f<depth>; no match = raise site
local fails, total = 0, 0
for _, mode in { "errorAt", "errorBefore", "errorAtNearest", "errorBeforeNearest" } do
	for depth = 0, 4 do
		local got, raw = run(depth, mode, SURF)
		local k = if depth == 0 then nil elseif string.find(mode, "Nearest") then depth else 1
		local want
		if k == nil then
			want = LINES.raise
		elseif string.find(mode, "Before") then
			want = LINES[k - 1]
		else
			want = LINES[k]
		end
		total += 1
		local ok = got == want
		if not ok then fails += 1 end
		print(string.format("%-19s depth=%d  got line %s  want %s  %s", mode, depth, tostring(got), tostring(want), if ok then "OK" else "FAIL " .. raw))
	end
end
print(string.format("blame table: %d/%d as documented", total - fails, total))

-- edge levels: 0 (= untagged default), -1, NaN-tag, unmatched 99
print("-- edge levels (depth 2, tagged SURF); 'raise' line =", "see below")
for _, level in { 0, -1, 99, INNER } do
	for _, mode in { "errorAt", "errorBefore", "errorAtNearest", "errorBeforeNearest" } do
		local got, raw = run(2, mode, level)
		local where = "?"
		for key, l in LINES do if l == got then where = tostring(key) end end
		print(string.format("level=%-3s %-19s -> line %s (%s)  %s", tostring(level), mode, tostring(got), where, raw))
	end
end

-- setFuncLevel argument handling
local function try(label, f)
	local ok, err = pcall(f)
	print(string.format("%-44s ok=%s  %s", label, tostring(ok), tostring(err)))
end
local ns2 = QE.new()
local a, b = {}, {}
function a.g() end
function a.h() end
try("setFuncLevel(1)  -- no fns", function() ns2.setFuncLevel(1) end)
try("setFuncLevel('1', a.g)", function() ns2.setFuncLevel("1", a.g) end)
try("setFuncLevel(1, a.g, nil, a.h)", function() ns2.setFuncLevel(1, a.g, nil, a.h) end)
print("  after nil-hole throw: getFuncLevel(a.g) =", ns2.getFuncLevel(a.g), " getFuncLevel(a.h) =", ns2.getFuncLevel(a.h))
try("setFuncLevel(1, a.g, nil)  -- trailing nil", function() ns2.setFuncLevel(3, a.g, nil) end)
try("setFuncLevel(1, {})", function() ns2.setFuncLevel(1, {}) end)
try("setFuncLevel(1, print)  -- C function", function() ns2.setFuncLevel(1, print) end)
try("setFuncLevel(0/0, a.h)  -- NaN level", function() ns2.setFuncLevel(0 / 0, a.h) end)
print("  getFuncLevel(a.h) after NaN =", ns2.getFuncLevel(a.h))
-- which line does setFuncLevel's own error blame? (level 2 = the caller of setFuncLevel)
local function callSite() M.mark("sfl"); ns2.setFuncLevel(1, nil) end
local ok, err = pcall(callSite)
print("  setFuncLevel error blames line", string.match(tostring(err), ":(%d+):"), "call line", LINES.sfl)

-- old idiom from quadnomicon 11: `for _, fn in { f, nil, g } do ... end` — does it stop at the hole or skip it?
local seen = {}
local x, y = function() end, function() end
for _, fn in { x, nil, y } do table.insert(seen, fn) end
print("old idiom over {x, nil, y}: visited", #seen, "(2 = hole skipped, later entries still tagged; 1 = stops at hole)")
