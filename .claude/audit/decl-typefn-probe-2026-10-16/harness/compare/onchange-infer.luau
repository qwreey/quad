--!strict
-- [2026-10-16] What does an UNANNOTATED callback of today's generated OnChange actually get? (typing-limits 8.7 (3) claim)
local DM = require("../../../../../quad-roblox/src/Declaration")
local OnChange: DM.OnChangeFn = nil :: any
local a = OnChange("Visible", function(v) end) -- @h(plain-v) at='v) end'
local b = OnChange("AbsoluteSize", function(v)
	local _ = v.X -- @c(member-dot) at='v.' ins='X'
end)
local c = OnChange("Visible", function(v)
	local s: string = v -- misuse: should be an error
end)
local d = OnChange("Visible", function(v: string) end) -- wrong annotation: should be an error
local e = OnChange("AbsoluteSize", function(v)
	local n: number = v.X -- correct use: should be clean
end)
local f = OnChange("AbsoluteSize", function(v)
	local s: string = v.X -- misuse through member: should be an error
end)
return { a, b, c, d, e, f }
