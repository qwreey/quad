--!strict
local q = require("./s10-config")
local _a = q.Tag(42) -- V1 number arg
local _b = q.Tag(q.None) -- V2 None arg
local _c = q.Tag("A", 42) -- V3 second arg number
local _d = q.Tag.Merged(q.None) -- V4 Merged None
