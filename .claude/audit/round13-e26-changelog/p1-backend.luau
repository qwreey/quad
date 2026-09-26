--!nocheck
-- E26 p1 — provider-author BREAKING lines: (a) 3.2.0 mock provider verbatim (top-level ops),
-- (b) the same provider after applying ONLY the "q.Backend로" line mechanically (quad.X = → quad.Backend.X =),
-- (c) HEAD mock (fully migrated: hold ops + isClaimed + nativeFindChild className).
local function first(e) return (tostring(e):gsub("\n.*", "")) end
local function scenario(label, mockPath)
	print("==== " .. label)
	local ok, mock = pcall(require, mockPath)
	if not ok then print("  require ERR: " .. first(mock)) return end
	local ok2, q = pcall(mock.newQuad)
	if not ok2 then print("  newQuad ERR: " .. first(q)) return end
	local function step(name, fn)
		local s, e = pcall(fn)
		print("  " .. name .. ": " .. (s and "OK" or ("ERR " .. first(e))))
	end
	local host = mock.Instance.new("Frame")
	local log = {}
	step("Effect bound to host", function()
		q.Dispatch.drive(host, { q.Effect(function() table.insert(log, "run") return function(dying) table.insert(log, "cleanup:" .. tostring(dying)) end end) })
	end)
	step("slot:Add(child) mounted", function()
		local s = q.Slot()
		local host2 = mock.Instance.new("Frame")
		q.Dispatch.drive(host2, { s })
		s:Add(mock.Instance.new("Frame"))
	end)
	step("host:Destroy()", function() host:Destroy() end)
	print("  log: " .. table.concat(log, ","))
	step("q.Backend.isClaimed(inst)", function() return q.Backend.isClaimed(mock.Instance.new("Frame")) end)
	step("q.Backend.isHeld(x)", function() return q.Backend.isHeld({}) end)
end
scenario("A 3.2.0 provider verbatim", "./mock320")
scenario("B 3.2.0 provider, only q.Backend relocation applied", "./mock320-backendmoved")
scenario("C HEAD mock", "../../../quad-base/test/mock")
