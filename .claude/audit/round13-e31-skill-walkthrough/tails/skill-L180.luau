local got
local b = Button { Text = "Go", OnClick = function(i, c) got = { i, c } end, Modifier = nil }
b.Activated:Fire("inputObj", 2); print("Button click args:", got[1], got[2], "Text:", b.Text)
local b2 = Button { Text = q.Source("s"), OnClick = function() end, Modifier = D.Modifier.TextButton():BackgroundTransparency(0.3) }
print("Button with modifier:", b2.BackgroundTransparency, b2.Text)
