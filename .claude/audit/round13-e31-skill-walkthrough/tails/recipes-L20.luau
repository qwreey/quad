local gui = Counter()
local frame = gui:GetChildren()[1]
local label, button
for _, c in frame:GetChildren() do if c.ClassName == "TextLabel" then label = c else button = c end end
for _ = 1, 6 do button.Activated:Fire("i", 1) end
print("label:", label.Text, "tweens:", #mock.tweenLog)
