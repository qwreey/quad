local bumped = D.Modifier.Frame():ZIndex(2):ZIndex(function(old)
	if type(old) == "number" then
		return old + 1
	end
	return 1
end)
-- bumped의 ZIndex는 3, 원본은 그대로 2
