local mock = require("./mock")
local Instance = mock.Instance
local q = mock.newQuad()
local function t(name, f) local ok, e = pcall(f); print(name, ok, (tostring(e):gsub("\n"," "))) end
-- 0141 number keys
t("0141 k=0", function() q.Dispatch.drive(Instance.new("Frame"), { [0] = q.Slot() }) end)
t("0141 k=1.5", function() q.Dispatch.drive(Instance.new("Frame"), { [1.5] = q.Slot() }) end)
t("0141 state str", function() q.Dispatch.drive(Instance.new("Frame"), { X = q.Source(q.Slot()) }) end)
-- 0140
t("0140", function() local s = q.Slot(); q.dispose(s); q.Dispatch.drive(Instance.new("Frame"), { s }) end)
t("0140 state", function() local s = q.Slot(); q.dispose(s); q.Dispatch.drive(Instance.new("Frame"), { q.Source(s) }) end)
-- 0169 vs 0242
t("raw destroyed", function() local s = q.Slot(); q.dispose(s); q.Slot():Add(s) end)
t("state destroyed", function() local s = q.Slot(); q.dispose(s); q.Slot():Add(q.Source(s)) end)
t("ctor state destroyed", function() local s = q.Slot(); q.dispose(s); q.Slot({q.Source(s)}) end)
-- 0142 via State
t("0142 state nil", function() local d = q.Source({1}); local s = q.Slot(); s:List(d, function(c) return Instance.new("Frame") end); q.Dispatch.drive(Instance.new("Frame"), { s }); d:Set(nil) end)
t("0142 plain setmt", function() local d = {1}; local s = q.Slot(); s:List(d, function(c) return Instance.new("Frame") end); setmetatable(d, {}); q.Dispatch.drive(Instance.new("Frame"), { s }) end)
-- 0149 empty ctor
t("0149 empty", function() q.Slot({}):List({}, function() return nil end) end)
t("0149 after failed add", function() local s=q.Slot(); pcall(function() s:Add(nil) end); s:List({}, function() return nil end); print("ok") end)
-- 0167 vs 0166 own list
t("own list crud", function() local s = q.Slot(); s:List({1}, function(c) s:Add(Instance.new("Frame")); return Instance.new("Frame") end); q.Dispatch.drive(Instance.new("Frame"), { s }) end)
t("ancestor crud", function() local outer = q.Slot(); local inner = q.Slot(); inner:List({1}, function(c) outer:Add(Instance.new("Frame")); return Instance.new("Frame") end); outer:Add(inner); q.Dispatch.drive(Instance.new("Frame"), { outer }) end)
-- 0145
t("0145", function() local s = q.Slot(); s:List({1,2}, function() return Instance.new("Frame") end, function() return "a" end); q.Dispatch.drive(Instance.new("Frame"), { s }) end)
-- 0163
t("0163", function() local f = Instance.new("Frame"); local p = Instance.new("Frame"); q.Bookkeeping.claimOwnerAt(f, p, 1); q.Bookkeeping.releaseOwner(f, Instance.new("Frame")) end)
t("0163 unowned", function() q.Bookkeeping.releaseOwner(Instance.new("Frame"), Instance.new("Frame")) end)
-- 0156
t("0156", function() local f = Instance.new("Frame"); q.Slot():Add(f); local s = q.Slot(); s:List({1}, function() return f end); q.Dispatch.drive(Instance.new("Frame"), { s }) end)
-- 0180
t("0180 num", function() q.dispose(5) end)
t("0180 state", function() q.dispose(q.Source(1)) end)
t("0180 table", function() q.dispose({}) end)
-- 0168 negative/huge/NaN
t("0168 -1", function() local s=q.Slot({Instance.new("Frame")}); s:Remove(-1) end)
t("0168 nan", function() local s=q.Slot({Instance.new("Frame")}); s:Remove(0/0) end)
t("0168 str", function() local s=q.Slot({Instance.new("Frame")}); s:Remove("1") end)
-- 0174
t("0174 nil", function() local s=q.Slot({Instance.new("Frame")}); s:Splice(1) end)
-- 0241 foreign
t("0241", function() q.Slot():Add(Instance.foreign("Frame")) end)
-- 0238 via Extract
t("0238 extract", function() local s=q.Slot({Instance.new("Frame")}); s:Extract(1, q.Ref()) end)
-- 0170 Extract same
t("0170 extract", function() local f=Instance.new("Frame"); local s=q.Slot({f}); s:Extract(1, f) end)
-- 0171 ctor
t("0171 ctor", function() local f=Instance.new("Frame"); q.Slot({f,f}) end)
-- 0172 static child then add
t("0172", function() local f=Instance.new("Frame"); q.Slot({f}); q.Slot():Add(f) end)
-- 0179 held
t("0179", function() local f=Instance.new("Frame"); q.Slot({f}); q.dispose(f) end)
-- 0176 branded
t("0176 slot", function() q.Slot(q.Slot()) end)
-- 0177 string key
t("0177", function() q.Slot({ a = 1 }) end)
-- Single data state with bad value (0142 unreachable?)
t("single state tbl", function() local st=q.Source(5); local s=q.Slot(); s:Single(st); q.Dispatch.drive(Instance.new("Frame"), { s }) end)
