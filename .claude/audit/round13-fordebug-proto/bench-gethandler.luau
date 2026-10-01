--!nocheck
-- Micro bench: the public `q.Dispatch.getHandler(inst, k, v)` scan alone (no process), HEAD vs this tree
-- with debug off/on — isolates the one added branch. Same two-tree setup and args as bench.luau.
-- usage: luau -O2 .claude/audit/round13-fordebug-proto/bench-gethandler.luau -a <relpath-HEAD-e66-dir> [rounds]
local args = { ... }
local ENVS = { HEAD = require(assert(args[1]) .. "/env"), off = require("../round13-e66-handlers-fuzz/env") }
ENVS.on = ENVS.off
local ROUNDS = tonumber(args[2]) or 9
local MODES = { "HEAD", "off", "on" }
-- optional 3rd arg: CONTROL = a copy of this tree with getHandler's branch replaced by `local set = buckets`
-- (same code shape minus the `module.debug` read) — separates the branch from tree/layout noise
if args[3] then
	ENVS.control = require(args[3] .. "/env")
	MODES = { "HEAD", "control", "off", "on" }
end
local N = 1000000
local cases = {
	{ "string key, string value (Name)", "Name", "x" },
	{ "string key, table value (Size)", "Size", { 1 } },
	{ "number key, Instance-ish child", 1, nil }, -- filled with a mock Frame per module
	{ "number key, Tag (FALLBACK, last)", 1, "tag" },
}
local res = {}
for _, c in cases do res[c[1]] = { HEAD = {}, off = {}, on = {}, control = {} } end
for r = 1, ROUNDS do
	for mi = 1, #MODES do
		local mode = MODES[((mi + r - 2) % #MODES) + 1]
		local q = ENVS[mode].newProv()
		q.debug = (mode == "on")
		local inst = q.Declaration.Frame({})
		local child = q.Declaration.Frame({})
		local tag = q.Tag("t")
		local gh = q.Dispatch.getHandler
		for _, c in cases do
			local k, v = c[2], c[3]
			if c[1]:find("Instance") then v = child elseif v == "tag" then v = tag end
			for _ = 1, 1000 do gh(inst, k, v) end
			local t0 = os.clock()
			for _ = 1, N do gh(inst, k, v) end
			table.insert(res[c[1]][mode], (os.clock() - t0) / N * 1e9)
		end
		child:Destroy(); inst:Destroy()
		q, inst, child, tag, gh = nil, nil, nil, nil, nil
		collectgarbage("collect")
	end
end
local function median(t) table.sort(t); return t[(#t + 1) // 2] end
local header = string.format("%-36s", `getHandler (ns/call, median of {ROUNDS})`)
for _, m in MODES do header ..= string.format(" %9s", m) end
for i = 2, #MODES do header ..= string.format(" %12s", MODES[i] .. "/HEAD") end
print(header)
for _, c in cases do
	local h = median(res[c[1]].HEAD)
	local line = string.format("%-36s", c[1])
	for _, m in MODES do line ..= string.format(" %9.1f", median(res[c[1]][m])) end
	for i = 2, #MODES do line ..= string.format(" %12.3f", median(res[c[1]][MODES[i]]) / h) end
	print(line)
end
print(`heap {math.floor(collectgarbage("count"))} KB`)
