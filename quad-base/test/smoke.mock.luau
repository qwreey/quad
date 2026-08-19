--[[ 임시 스모크 테스트 — mock.luau 자체가 기대대로 동작하는지 확인 ]]

local mock = require("./mock")
local Instance = mock.Instance

print("=== 1. property bag + changed signal ===")
do
	local frame = Instance.new("Frame")
	local fired = {}
	frame:GetPropertyChangedSignal("Visible"):Connect(function()
		table.insert(fired, frame.Visible)
	end)
	frame.Visible = false
	frame.Visible = true
	assert(#fired == 2 and fired[1] == false and fired[2] == true, "changed signal must fire per write with the new value visible")
	print("PASS")
end

print()
print("=== 2. parent/children tree ===")
do
	local root = Instance.new("Frame")
	local child1 = Instance.new("Frame")
	local child2 = Instance.new("Frame")
	child1.Name = "A"
	child2.Name = "B"
	child1.Parent = root
	child2.Parent = root

	local children = root:GetChildren()
	assert(#children == 2, "expected 2 children")
	assert(root:FindFirstChild("A") == child1)
	assert(root:FindFirstChild("B") == child2)
	assert(child1.Parent == root)

	child1.Parent = nil
	assert(#root:GetChildren() == 1, "removing Parent must detach from old parent's children")
	print("PASS")
end

print()
print("=== 3. Destroy fires Destroying + detaches ===")
do
	local root = Instance.new("Frame")
	local child = Instance.new("Frame")
	child.Parent = root

	local destroyed = false
	child.Destroying:Connect(function()
		destroyed = true
	end)
	child:Destroy()
	assert(destroyed, "Destroying must fire on Destroy")
	assert(#root:GetChildren() == 0, "Destroy must detach from parent")
	print("PASS")
end

print()
print("=== ALL PASS ===")
