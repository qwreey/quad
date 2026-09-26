--!nocheck
-- P-gates2 Q102 runtime probe. Run from scratch root: luau probes/probe.q102.luau
local Quad = require("../quad-roblox/luau_packages/quad_base")
local function E(f) local ok, err = pcall(f); if ok then return "ok" end; return (tostring(err):gsub("^.-/p%-gates2/", "")):sub(1, 260) end
local function T(n, f) print(n .. " => " .. E(f)) end
local q = Quad.New()
local P = q.Context.Provider("P")
T("C1 Context({[P]=1})", function() local c = q.Context({ [P] = 1 }); print("   Peek:", c:Peek(P)) end)
T("C1b Context(nil)", function() q.Context(nil) end)
T("C1c Context(1,2)", function() q.Context(1, 2) end)
T("C1d Context:(colon) q.Context:Provider? n/a — Context()", function() local c = q.Context(); print("   ok bag", tostring(c)) end)
T("C1e root Quad.Context({})", function() Quad.Context({}) end)
