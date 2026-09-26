--!nocheck
-- E29 probe (not a spec): what the unmodified mock accepts where the engine would reject or differ.
-- Run from repo root after ./scripts/relink.sh:  luau .claude/audit/round13-e29-mock-fidelity/probe-mock-surface.luau
local mock = require("../../../quad-base/test/mock")
local I = mock.Instance
local function try(label, f)
	local ok, err = pcall(f)
	print(`{label}: {ok and "ACCEPTED" or ("rejected: " .. tostring(err))}`)
end
try("Instance.new of a non-class name", function() return I.new("NotARobloxClass") end)
try("write an unknown member", function() I.new("Frame").Bogus = 1 end)
try("read an unknown member (returns nil?)", function() assert(I.new("Frame").Bogus == nil) end)
try("write a ReadOnly property (AbsoluteSize)", function() I.new("Frame").AbsoluteSize = 1 end)
try("write ClassName", function() local f = I.new("Frame"); f.ClassName = "X"; assert(f.ClassName == "Frame") end)
try("write wrong type (Size = 42)", function() I.new("Frame").Size = 42 end)
try("write nil to a non-nullable property (Visible = nil)", function() I.new("Frame").Visible = nil end)
do
	local f = I.new("Frame")
	print("default read Frame.Visible (engine default true):", f.Visible)
end
try("Parent cycle (a under b under a)", function() local a, b = I.new("Frame"), I.new("Frame"); b.Parent = a; a.Parent = b end)
try("Parent = self", function() local a = I.new("Frame"); a.Parent = a end)
try("re-Parent after Destroy", function() local a, p = I.new("Frame"), I.new("Frame"); a:Destroy(); a.Parent = p; assert(a.Parent == p) end)
do
	local f, n = I.new("Frame"), 0
	f:GetPropertyChangedSignal("Visible"):Connect(function() n += 1 end)
	f.Visible = true; f.Visible = true
	print("same-value writes fire (engine: 0 for a repeat, measured 2026-09-10):", n)
end
do
	local p, a, b = I.new("Frame"), I.new("Frame"), I.new("Frame")
	a.Name, b.Name = "a", "b"
	a.Parent = p; b.Parent = p; a.Parent = p
	local names = {}
	for _, c in p:GetChildren() do table.insert(names, c.Name) end
	print("same-Parent reassignment reorders GetChildren:", table.concat(names, ","))
end
do
	local f, order = I.new("Frame"), {}
	f:GetPropertyChangedSignal("Name"):Connect(function() table.insert(order, "first") end)
	f:GetPropertyChangedSignal("Name"):Connect(function() table.insert(order, "second") end)
	f.Name = "x"
	print("listener order (mock = reverse of Connect):", table.concat(order, ","))
end
do
	local f, fired = I.new("Frame"), false
	f:GetPropertyChangedSignal("Name"):Connect(function() fired = true end)
	f.Name = "y"
	print("delivery is synchronous (engine Deferred, measured 2026-09-02):", fired)
end
try("GetPropertyChangedSignal of an unknown property", function() I.new("Frame"):GetPropertyChangedSignal("Bogus") end)
try("read Changed / AncestryChanged (engine events)", function() local f = I.new("Frame"); assert(f.Changed ~= nil and f.AncestryChanged ~= nil) end)
try("IsA a superclass (Frame IsA GuiObject)", function() assert(I.new("Frame"):IsA("GuiObject")) end)
try("Name = 5 (number to string property)", function() I.new("Frame").Name = 5 end)
try("SetAttribute invalid names", function() local f = I.new("Frame"); f:SetAttribute("has space", 1); f:SetAttribute("RBXx", 1); f:SetAttribute(string.rep("a", 101), 1) end)
try("SetAttribute table", function() I.new("Frame"):SetAttribute("T", {}) end)
do
	local tw = mock.gameShim({}):GetService("TweenService")
	try("TweenService:Create on a string property / unknown property", function() tw:Create(I.new("TextLabel"), mock.tweenInfoShim.new(1), { Text = "x", Bogus = 1 }) end)
	try("TweenInfo.new with an explicit nil in the middle", function() mock.tweenInfoShim.new(1, nil, nil, 0) end)
end
