local mock = require("./mock")
local q = mock.newQuad()
local root = mock.Instance.foreign("Frame")
local c = mock.Instance.foreign("Frame"); c.Name = "X"; c.Parent = root
local M = q.newMapperClass("Frame")
local d = M("X")({})
print("0027 same tree", pcall(function() return q.Claim(root, M(q.MapperRoot)({ d, d })) end))
