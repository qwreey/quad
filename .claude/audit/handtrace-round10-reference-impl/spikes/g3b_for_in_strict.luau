--!strict
local seen: { [string]: boolean } = { a = true }
for d in seen do print(d) end
for d in pairs(seen) do print(d) end
