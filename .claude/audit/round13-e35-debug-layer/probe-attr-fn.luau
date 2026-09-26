--!nocheck
local H = require("./harness")
local q, D = H.q, H.D
print(pcall(function() local f = D.Frame { q.Attr { Hp = function() end } } end))
print(pcall(function() local f = D.Frame { q.Attr { Hp = newproxy() } } end))
