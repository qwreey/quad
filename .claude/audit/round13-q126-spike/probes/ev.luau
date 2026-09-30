--!strict
-- Q126 spike — event slot arity probe (is P8/P9's failure about nil or about the annotated zero-arg callback?)
local q = require("./config")
local QT = require("../quad-types/src")
local D = q.Declaration
type None = QT.None
local _a = D.TextButton { Activated = q.Source(function() end :: () -> ()) } -- P1 annotated zero-arg cb, no nil
local _b = D.TextButton { Activated = q.Source(nil :: ((InputObject, number) -> ())?) } -- P2 exact sig + nil
local _c = D.TextButton { Activated = q.Source<<((InputObject, number) -> ()) | None>>(q.None) } -- P3 exact sig | None
local _d = D.TextButton { Activated = q.Source(nil :: ((InputObject) -> ())?) } -- P4 fewer params + nil
local _e = D.TextButton { Activated = q.Source(function(_i: InputObject) end) } -- P5 fewer params, inferred, no nil
local _f = D.TextButton { MouseEnter = q.Source(nil :: ((number, number) -> ())?) } -- P6 other event exact
local _g = D.Frame { Destroying = q.Source(nil :: (() -> ())?) } -- P7 zero-arg event + nil
local _h = D.TextButton { Activated = function() end } -- P8 plain zero-arg literal (doc: arity not checked)
