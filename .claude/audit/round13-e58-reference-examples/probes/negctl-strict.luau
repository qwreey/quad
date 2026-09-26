--!strict
-- 음성 대조: 진단이 나야 한다
local q = require("../strict/Quad")
local s = q.Source(1)
s:Set("x")
local D = q.Declaration
local _f = D.TextLabel { Text = 42 }
