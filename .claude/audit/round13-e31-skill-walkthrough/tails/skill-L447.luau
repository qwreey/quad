local c = InteractiveCard()
c.Activated:Fire("i", 1)
print("color after click R:", c.BackgroundColor3.R)
