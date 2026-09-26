--!nocheck
local H = require("./harness")
local q, D = H.q, H.D

local function ButtonGroup()
	return q.Slot({
		D.TextButton { Name = "SaveButton", Text = "Save" },
		D.TextButton { Name = "CancelButton", Text = "Cancel" },
	})
end

local group = ButtonGroup()
local host = D.Frame { group }
for _, c in host:GetChildren() do
	print(c.Name, c.Text)
end
