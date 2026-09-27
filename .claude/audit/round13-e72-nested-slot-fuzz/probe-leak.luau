--!nocheck
-- E72 harness check: heap retained per Quad.New() instance in one CLI process (explains the fuzzer's
-- superlinear time within a process — full GCs walk an ever-growing heap). Modes: bare / provider / drive / newQuad
local E = require("./env")
local mock = E.mock
local I = mock.Instance
local mode = ({ ... })[1] or "drive"
for round = 1, 4 do
	for _ = 1, 400 do
		if mode == "bare" then local q = E.Quad.New()
		elseif mode == "provider" then local q = E.Quad.New(); q:UseProvider(mock.mockProvider)
		elseif mode == "newQuad" then local q = mock.newQuad()
		elseif mode == "frameOnly" then
			local q = E.newBase({ plainNative = true }); local host = I.new("Frame")
		elseif mode == "driveDestroy" then
			local q, env = E.newBase({ plainNative = true })
			local host = I.new("Frame")
			q.Dispatch.drive(host, { q.Slot({ I.new("Frame") }) })
			host:Destroy()
		elseif mode == "emptySlot" then
			local q, env = E.newBase({ plainNative = true })
			local host = I.new("Frame")
			q.Dispatch.drive(host, { q.Slot() })
		else
			local q, env = E.newBase({ plainNative = true })
			local host = I.new("Frame")
			q.Dispatch.drive(host, { q.Slot({ I.new("Frame") }) })
		end
	end
	collectgarbage("collect")
	print(mode, round, math.floor(collectgarbage("count")) .. " KB")
end
