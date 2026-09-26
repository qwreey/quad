local btn = D.TextButton { buttonMod, sameRuntimeValue, checked }
print("BT", btn.BackgroundTransparency, "Text", btn.Text, "Visible", btn.Visible)
print("label visible:", D.TextLabel { unchecked }.Visible)
