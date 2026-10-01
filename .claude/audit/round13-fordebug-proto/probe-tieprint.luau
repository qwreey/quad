--!nocheck
-- Does turning q.debug on BEFORE UseProvider make the six debug filters (all at NORMAL + 2, mutually
-- exclusive predicates) print tie lines among themselves? Compared with HEAD's own FALLBACK guard ties.
-- usage (repo root, after relink): luau .claude/audit/round13-fordebug-proto/probe-tieprint.luau
local E = require("../round13-e66-handlers-fuzz/env")
local q = E.Quad.New()
q.debug = true
local env = getfenv(q.Dispatch.addHandler)
local lines = {}
env.print = function(...) table.insert(lines, table.concat({ ... }, " ")) end
q:UseProvider(E.mock.mockProvider)
env.print = nil
print(`tie lines after UseProvider with debug on: {#lines}`)
for _, l in lines do print("  " .. l) end
