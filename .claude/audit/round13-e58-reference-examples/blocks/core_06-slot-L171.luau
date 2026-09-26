local slot = q.Slot<<Instance>>()
slot:Add(D.TextLabel { Text = "끝에" })
slot:Add(D.TextLabel { Text = "앞에" }, 1)
local root = D.Frame { slot }
