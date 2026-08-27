--!nocheck
local seen = { a = true }
local ok, err = pcall(function() for d in seen do print(d) end end)
print("for d in seen do (일반화 반복):", ok, err)
