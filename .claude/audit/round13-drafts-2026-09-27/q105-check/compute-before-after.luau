--!strict
-- BEFORE/AFTER for a representative GS-shape :Compute binding (GS03:72 style).
-- q105-check scratch, not repo source.
local Setup = require("./_setup")
local QT = require("../../../../quad-roblox/luau_packages/quad_types")
local q = Setup.q

local count = q.Source(0)

-- BEFORE (docs/getting-started/03-flowing-values.md:72 as written today)
local countTextBefore = count:Compute(function(c)
	return `카운트: {c:Get()}`
end)
local before_bad: number = countTextBefore -- expect: SILENT (the hole)
local before_bad2: number = countTextBefore:Get() -- expect: SILENT (the hole)

-- AFTER (Q105 (b) draft)
local countTextAfter: QT.State<string> = count:Compute(function(c)
	return `카운트: {c:Get()}`
end)
local after_bad: number = countTextAfter -- expect: TypeError (constrained)
local after_bad2: number = countTextAfter:Get() -- expect: TypeError (constrained)
local after_ok: string = countTextAfter:Get() -- expect: clean

print(before_bad, before_bad2, after_bad, after_bad2, after_ok)
