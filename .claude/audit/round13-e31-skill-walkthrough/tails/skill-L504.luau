print("SafeProfile:", SafeProfile(1).Text, "Traced:", Traced(2).Text)
local Bad = q.Fallback(function(): TextLabel error("boom") end, function(err) return D.TextLabel { Text = "caught " .. typeof(err) } end)
print("Fallback caught:", Bad().Text)
