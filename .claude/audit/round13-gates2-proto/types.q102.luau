--!strict
-- P-gates2 Q102 type probe. EXPECT-ERR marks lines that should error.
local q = require("../quad-base/src")
local P = q.Context.Provider<<number>>("n")
local c0 = q.Context()                        -- OK
local c1 = q.Context({ [P] = 1 })             -- L6 EXPECT-ERR (extra arg)
local c2 = q.Context(1, 2)                    -- L7 EXPECT-ERR
local c3 = q.Context(nil)                     -- L8 EXPECT-ERR? (nil literal)
local _ = c0:Set(P, 1)
local _ = { c1, c2, c3 }
-- isolated variants (no quad types involved)
type Ctx = { tag: true }
local A: setmetatable<{}, { __call: (self: any) -> Ctx }> = nil :: any
local B: setmetatable<{}, { __call: () -> Ctx }> = nil :: any
local C: setmetatable<{}, { __call: (self: any, ...never) -> Ctx }> = nil :: any
local a1 = A({})                               -- L17 EXPECT-ERR
local b1 = B({})                               -- L18 EXPECT-ERR
local c4 = C({})                               -- L19 EXPECT-ERR
local _ = { a1, b1, c4 }
