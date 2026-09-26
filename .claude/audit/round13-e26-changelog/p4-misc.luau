--!nocheck
-- E26 p4 — unlabeled behavior changes + provider nativeFindChild className (E15 harness).
local H = require("../round13-e15-probe-setup")
local q, D, mock, try = H.q, H.D, H.mock, H.try
local M = D.Mapper

print("== Operator.Sum with a nil-valued State (Fixed: now throws; 3.2.0 skipped it)")
try("Sum(State nil)", function()
	local a, b = q.Source(1), q.Source(nil)
	return a:Apply(q.Operator.Sum(b)):Get()
end)

print("== Store: __ via :Of")
try("store:Of('__x')", function() local s = q.Store({ a = q.Source(1) }) return s:Of("__x") end)

print("== nativeFindChild: 3.2.0-shaped (2-arg) backend op — class mismatch in Claim")
do
	local real = q.Backend.nativeFindChild
	q.Backend.nativeFindChild = function(inst, key) return real(inst, key) end -- ignores className (old contract)
	local root = mock.Instance.foreign("Frame")
	local kid = mock.Instance.foreign("Frame")
	kid.Name = "Kid"
	kid.Parent = root
	try("Claim(M.TextLabel('Kid')) on a Frame child, old 2-arg op", function()
		q.Claim(root, M.Frame(M.Root)({ M.TextLabel("Kid")({ Text = "hi" }) }))
		return "claimed; kid.Text=" .. tostring(kid.Text)
	end)
	q.Backend.nativeFindChild = real
	local root2 = mock.Instance.foreign("Frame")
	local kid2 = mock.Instance.foreign("Frame")
	kid2.Name = "Kid"
	kid2.Parent = root2
	try("same, HEAD op (className honored)", function()
		q.Claim(root2, M.Frame(M.Root)({ M.TextLabel("Kid")({ Text = "hi" }) }))
	end)
end

print("== Effect returning a connection, no deps (Changed, not tagged BREAKING)")
try("Effect(fn -> connection) on a frame", function()
	local f = D.Frame {}
	local conn = f.Changed:Connect(function() end)
	D.Frame { q.Effect(function() return conn end) }
end)
