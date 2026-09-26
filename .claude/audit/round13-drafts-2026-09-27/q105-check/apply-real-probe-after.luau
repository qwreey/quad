--!strict
-- AFTER: same four :Apply(object/complex-return factory) calls, now with a binding
-- annotation. Expect: no diagnostic on the correctly-typed follow-up (line marked OK),
-- but a deliberately wrong follow-up (line marked BAD) still throws -- proves the
-- checker is alive downstream once the binding carries the type.
local Setup = require("./_setup")
local q = Setup.q
local QT = require("../../../../quad-roblox/luau_packages/quad_types")
-- (Animate/Tween omitted here -- Tween<T> lives in quad-roblox's own module type,
--  not quad_types; the before-hole was confirmed directly in apply-real-probe.luau
--  and the fix is the same §1① binding-annotation pattern, not re-verified here.)

local raw = q.Source(0)
local blocker = q.Blocker()
local r3: QT.State<number> = raw:Apply(blocker)
local ok3: number = r3:Get() -- OK

local searchInput = q.Source("")
local r4: QT.State<string> = searchInput:Apply(q.Debounce({ Time = 0.2 }))
local ok4: string = r4:Get() -- OK
local bad4: boolean = r4:Get() -- BAD: should error (string ~= boolean)

print(ok3, ok4, bad4)
