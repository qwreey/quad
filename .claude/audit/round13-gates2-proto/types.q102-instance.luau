--!strict
local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local q = Quad.New():UseProvider(QuadRoblox)
local P = q.Context.Provider<<number>>("n")
local c1 = q.Context({ [P] = 1 })             -- L6 EXPECT-ERR
local Q2 = Quad.New()
local c2 = Q2.Context({ [P] = 1 })            -- L8 EXPECT-ERR
local c3 = Quad.Context({ [P] = 1 })          -- L9 EXPECT-ERR
local _ = { c1, c2, c3 }
