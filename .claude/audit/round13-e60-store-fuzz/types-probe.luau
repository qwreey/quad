--!strict
-- E60 (a) strict type probe. command (repo root):
-- mise exec -- luau-lsp analyze --flag:LuauSolverV2=true --platform=standard --ignore '**/luau_packages/**' .claude/audit/round13-e60-store-fuzz/types-probe.luau
-- EXPECT-ERR marks lines the docs say the type side rejects; OPEN marks lines the docs do not decide.
local q = require("../../../quad-base/src")
local QT = require("../../../quad-base/luau_packages/quad_types")

local store = q.Store({ hp = q.Source(100), name = q.Source("p") })
local a1: QT.Source<number> = store.hp                  -- A1 declared field is the Source itself (core/04:78)
local a2: number = store.hp:Get()                       -- A2
local a3 = store.mp                                      -- A3 undeclared dot read — EXPECT-ERR (core/04:84 casts to any)
local a4: QT.Source<number> = store:Of("mp")            -- A4 :Of without type arg, annotated target
local a5 = store:Of<<number>>("mp")                     -- A5
local a5b: string = a5:Get()                            -- A5b Of<<number>> then read as string — EXPECT-ERR
local a6 = store:Of<<string>>("hp")                     -- A6 unchecked cast of an existing field (core/04:110 — silent by design)
local a7 = store:Of("Of")                               -- A7 reserved literal through :Of — OPEN (runtime Quad0194 only?)
local a8 = store:Of(1 :: any)                           -- A8
local a9: { string } = store:Names()                    -- A9
store.hp = q.Source(5)                                  -- A10 direct field write of a Source — OPEN (core/04:156 "not blocked")
store.hp = 5 :: any                                     -- A11 (any)
store.name = 5                                          -- A12 wrong-type write — EXPECT-ERR
local r1 = q.Store({ __x = q.Source(1) })               -- A13 __ prefix — EXPECT-ERR (type function print, core/04:161)
local r2 = q.Store({ Names = q.Source(1) })             -- A14 — EXPECT-ERR
local r3 = q.Store({ __reservedCheck = q.Source(1) })   -- A15 — EXPECT-ERR
local r4 = q.Store({ [""] = q.Source(1) })              -- A16 empty name — OPEN (runtime Quad0193)
local r5 = q.Store()                                    -- A17 empty
local r6 = r5:Of<<number>>("x")                          -- A18
local r7 = r5.x                                         -- A19 undeclared read on empty store — EXPECT-ERR?
for k, v in store do                                    -- A20 generalized iteration over a Store
	local kk: string = k
	local _ = kk, v
end
local ts: string = tostring(store)                      -- A21
local at = q.Attr(store)                                -- A22 Attr(store)
local st2 = q.Store({ inner = q.Source(store) })        -- A23 Source holding a Store
local innerHp: number = st2.inner:Get().hp:Get()        -- A24
local bad = q.Store({ inner = store })                  -- A25 Store as a default — runtime Quad0198 (H-666 family: type silent)
local shared = q.Store({ a = store.hp, b = store.hp })  -- A26
return a1, a2, a3, a4, a5, a5b, a6, a7, a8, a9, r1, r2, r3, r4, r5, r6, r7, ts, at, st2, innerHp, bad, shared
