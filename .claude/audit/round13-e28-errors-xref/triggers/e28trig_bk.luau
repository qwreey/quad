--!nocheck
local mock = require("./mock")
local q = mock.newQuad()
local Instance = mock.Instance
local BK = q.Bookkeeping
local function case(name, fn)
	local ok, err = pcall(fn)
	print("@@RESULT\t" .. name .. "\t" .. (ok and "NO-ERROR" or tostring(err):gsub("\n", "\\n")))
end
case("0229 a", function() local i = Instance.new("Frame"); BK.setLength(i, 1, 1); BK.setLength(i, 3, 1); print(BK.getOffsetAt(i, 3)) end)
case("0229 b", function() local i = Instance.new("Frame"); BK.setLength(i, 3, 1); print(BK.getOffsetAt(i, 3)) end)
case("0229 c", function() local i = Instance.new("Frame"); BK.setLength(i, 1, 1); BK.setLength(i, 2, 1); BK.setLength(i, 3, 1); BK.setEmpty(i, 2); print(BK.getOffsetAt(i, 3)) end)
case("0024 a", function() local i = Instance.new("Frame"); BK.setLength(i, 1, 1); BK.setOffsetSource(i, 2, q.Source(0)); print("ok-a") end)
case("0024 b", function() local i = Instance.new("Frame"); local s = q.Source(0); BK.setOffsetSource(i, 1, s); BK.setLength(i, 1, 1); BK.setOffsetSource(i, 2, q.Source(0)); BK.setLength(i, 1, 2); print("ok-b") end)
case("0024 c", function() local i = Instance.new("Frame"); BK.setOffsetSource(i, 1, q.Source(0)); print("ok-c1"); BK.setLength(i, 2, 1); print("ok-c") end)
