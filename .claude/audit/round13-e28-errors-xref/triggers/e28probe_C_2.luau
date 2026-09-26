local mock = require("./mock")
local Instance = mock.Instance
local q = mock.newQuad()
local Quad = require("../src")
local function t(name, f) local ok, e = pcall(f); print(name, ok, (tostring(e):gsub("\n"," "))) end
t("process k=0", function() q.Dispatch.process(Instance.new("Frame"), 0, q.Slot(), 1) end)
t("process k=-2", function() q.Dispatch.process(Instance.new("Frame"), -2, q.Slot(), 1) end)
local bare = Quad.new and Quad.new() or nil
print("bare", bare)
