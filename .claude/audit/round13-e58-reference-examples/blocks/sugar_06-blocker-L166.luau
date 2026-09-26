state:Apply(blocker)
-- ≡
state:Gate(function(emit)
	return blocker:Policy(emit)
end)
