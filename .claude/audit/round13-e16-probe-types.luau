--!strict
-- round13 E16 type probe (2026-09-27): Tag/Attr/Ref/hook placement. Run:
-- mise exec -- luau-lsp analyze --flag:LuauSolverV2=true --flag:LuauTarjanChildLimit=160000 --flag:LuauSubtypingIterationLimit=100000 --flag:LuauTypeInferIterationLimit=1000000 --definitions=scripts/roblox-defs/globalTypes.d.luau --ignore "**/luau_packages/**" .claude/audit/round13-e16-probe-types.luau
local q = require("./round13-e16-probe-types-settings")
local D = q.Declaration

local tagState = q.Source(q.Tag("a"))
local _p1 = D.Frame { tagState } -- expect OK: State<Tag> at numeric key
local _p2 = D.Frame { q.Source(q.PreRef<<Frame?>>(nil)) } -- runtime Quad0136: does the type reject?
local _p3 = D.Frame { q.Source(q.OnCreated<<Frame>>(function(_i) end)) } -- runtime Quad0136
local _p4 = D.Frame { Foo = q.Tag("x") } -- expect-error unknown key
local _p5 = D.Frame { q.Source(q.Attr({ X = 1 })) } -- expect OK
local _p6 = D.Frame { q.StringAttr("S", q.Source(1)) } -- expect-error State<number> into StringAttr
local _p7 = D.Frame { q.Source(q.Ref<<Frame?>>(nil)) } -- runtime OK
local _p8 = D.TextLabel { q.Ref<<Frame?>>(nil) } -- expect-error class mismatch (Ref<Frame?> on TextLabel)
local _p9 = D.Frame { q.OnDestroyed(function() end), q.OnRendered<<TextLabel>>(function(_i) end) } -- OnRendered<<TextLabel>> on Frame: rejected?
local _p10 = D.Frame { q.Tag("a"):Added(nil) } -- OK
local _p11 = D.Frame { q.Source(q.Tag("a")):Compute(function(s) return if s:Get():Contains("a") then q.Tag("b") else nil end) } -- State<Tag?> at numeric key
local _p12 = D.Frame { q.Source(5) } -- expect-error number at numeric key
local _p13 = D.Frame { q.Attr({ X = q.Source({}) }) } -- runtime: table attr value via State (engine error) — type?
return nil
