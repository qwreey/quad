local f = RegistrationForm()
local boxes, submit = {}, nil
for _, c in f:GetChildren() do if c.ClassName == "TextBox" then table.insert(boxes, c) else submit = c end end
boxes[1].Text = "ada"; boxes[2].Text = "secret1"
print("valid:", submit.AutoButtonColor, "color G:", submit.BackgroundColor3.G)
