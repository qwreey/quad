--!nocheck
local H = require("./harness")
local D = H.D

local bad1 = D.Modifier.TextButton{ Sise = 1 }
local ok1, err1 = pcall(function() return D.TextButton { bad1 } end)
print("Sise typo ok:", ok1, "err:", ok1 and "" or tostring(err1):gsub("\n.*",""))

local bad2 = D.Modifier.TextButton{ Size = "x" }
local ok2, err2 = pcall(function() return D.TextButton { bad2 } end)
print("Size wrong type ok:", ok2, "err:", ok2 and "" or tostring(err2):gsub("\n.*",""))
