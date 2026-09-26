--!strict
-- round13 E13 type probe. command (repo root):
-- mise exec -- luau-lsp analyze --flag:LuauSolverV2=true --platform=standard --ignore '**/luau_packages/**' .claude/audit/round13-e13-types-probe.luau
-- expected lines with errors are marked EXPECT-ERR; anything else reported is a finding.
local q = require("../../quad-base/src")
local QT = require("../../quad-base/luau_packages/quad_types")
local Op = q.Operator

local price = q.Source(10)
local t1 = price:Apply(Op.Sum)                         -- T1 uncalled curried factory, no annotation (silent?)
local t2: QT.State<number> = price:Apply(Op.Sum)       -- T2 annotated — EXPECT-ERR
local t3 = price:Apply(Op.Clamp)                       -- T3 — EXPECT-ERR
local t4 = price:Apply(Op.Alternative)                 -- T4 — EXPECT-ERR
local t5 = price:Apply(Op.Indexed)                     -- T5 uncalled Indexed (silent?)
local t6 = price:Apply(Op.Shl)                         -- T6 uncalled Shl (silent?)
local s1 = q.Store({ x = 5 })                          -- T7 raw value default (store-plan says type requires Source<T>)
local s2 = q.Store({ c = q.Context() })                -- T8 Context default
local s3 = q.Store({ n = q.Store({ a = q.Source(1) }) }) -- T9 nested Store
local s4 = q.Store({ Of = q.Source(1) })               -- T10 reserved — EXPECT-ERR
local v: number = s1.x                                 -- T11 consequence: s1.x typed number but runtime never gets here
local P = q.Context.Provider<<number>>("n")
local c = q.Context():Set(P, 1)
local g: string = c:Get(P)                             -- T12 — EXPECT-ERR
return t1, t2, t3, t4, t5, t6, s1, s2, s3, s4, v, g
