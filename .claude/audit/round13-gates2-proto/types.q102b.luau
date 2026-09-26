--!strict
type Ctx = { tag: true }
local B: setmetatable<{}, { __call: () -> Ctx }> = nil :: any
local A: setmetatable<{}, { __call: (self: any) -> Ctx }> = nil :: any
local b0 = B()     -- L5 no-arg call with () -> Ctx
local a0 = A()     -- L6
local _ = { b0, a0 }
