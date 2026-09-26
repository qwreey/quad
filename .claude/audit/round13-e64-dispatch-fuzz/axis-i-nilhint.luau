--!nocheck
-- axis i: extend/02:161-165 Quad0076 nil tail, both install modes; None at a string key unwraps to nil at depth 2
local E = require("./env")
for _, mk in { "newBase", "newProv" } do
	local q = E[mk]()
	local inst = if mk == "newProv" then q.Declaration.Frame {} else E.mock.Instance.new("Frame")
	for _, case in { { "nil", nil }, { "None", q.None }, { "State(nil)", q.Source(nil) }, { "number", 5 } } do
		local ok, e = pcall(q.Dispatch.process, inst, "Foo", case[2], 1)
		local s = tostring(e):gsub("\n.*", "")
		print(mk, case[1], ok, E.id(e), "nil-tail:", s:find("unwrapped None", 1, true) ~= nil)
	end
end
