--!strict
local q = require("./s10-config")
local D = q.Declaration

local function ButtonGroup()
	return q.Slot<<Instance>>({
		D.TextButton { Name = "SaveButton", Text = "Save" },
		D.TextButton { Name = "CancelButton", Text = "Cancel" },
	})
end
print(ButtonGroup())
