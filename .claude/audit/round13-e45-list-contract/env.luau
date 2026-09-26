--!nocheck
-- E45 shared env: base quad on the mock provider (quad-base/test/mock), no quad-roblox.
local mock = require("../../../quad-base/test/mock")
local I = mock.Instance
local M = {}
M.mock = mock
M.I = I
function M.newQ() return mock.newQuad() end
function M.mk(name) local f = I.new("Frame"); f.Name = name; return f end
function M.order(s)
	local t = {}
	for i = 1, #s._elements do
		local v = s:Get(i)
		if type(v) == "table" and v.Name == nil then
			t[i] = tostring(v)
		else
			t[i] = v and v.Name or "nil"
		end
	end
	return table.concat(t, ",")
end
function M.kids(p)
	local t = {}
	for _, c in p:GetChildren() do table.insert(t, c.Name) end
	table.sort(t)
	return table.concat(t, ",")
end
function M.id(err)
	local e = tostring(err)
	return string.match(e, "Quad%d%d%d%d") or ("raw: " .. string.sub((e:gsub("\n.*", "")), 1, 110))
end
function M.try(fn)
	local ok, err = pcall(fn)
	if ok then return "ok" end
	return M.id(err)
end
function M.dead(inst) return mock.isDestroyed(inst) end
function M.row(cell, obs) print(`R | {cell} | {obs}`) end
return M
