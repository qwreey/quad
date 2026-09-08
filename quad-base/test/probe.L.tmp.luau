--!nocheck
local mock = require("./mock")
local q = mock.newQuad()
local Instance = mock.Instance
local Slot, dispatch = q.Slot, q.Dispatch
local gc = (_G :: any).collectgarbage
local function clean() gc("collect"); gc("collect") end
local function kb() gc("collect"); gc("collect"); gc("collect"); return gc("count") end

print("=== 1. Modifier 필드 N개 체이닝 배가 곡선 ===")
for _, N in ipairs({ 250, 500, 1000, 2000, 4000 }) do
	local keys = table.create(N)
	for i = 1, N do keys[i] = "F" .. i end
	local best = math.huge
	for _ = 1, 3 do
		clean()
		local t0 = os.clock()
		local m = q.Modifier()
		for i = 1, N do m = m[keys[i]](m, i) end
		local dt = (os.clock()-t0)*1000
		if dt < best then best = dt end
	end
	print(string.format("  N=%-5d %.1f ms", N, best))
end

print()
print("=== 2. Relate 에페메론 대조군 (Relate를 밖에 유지) ===")
do
	local R1 = q.Relate()
	local w1 = setmetatable({}, { __mode = "v" })
	do local p = Instance.new("Folder"); w1[1] = p; R1:SetStrong(p, "k", { back = p }) end
	gc("collect"); gc("collect"); gc("collect")
	print("  SetStrong 값이 키를 되참조:", w1[1] == nil and "회수됨" or "★남아있음")
	local R2 = q.Relate()
	local w2 = setmetatable({}, { __mode = "v" })
	do local p = Instance.new("Folder"); w2[1] = p; R2:SetStrong(p, "k", { nothing = true }) end
	gc("collect"); gc("collect"); gc("collect")
	print("  SetStrong 값이 되참조 없음:  ", w2[1] == nil and "회수됨" or "★남아있음")
	local R3 = q.Relate()
	local w3 = setmetatable({}, { __mode = "v" })
	do local p = Instance.new("Folder"); w3[1] = p; R3:SetWeak(p, "k", { back = p }) end
	gc("collect"); gc("collect"); gc("collect")
	print("  SetWeak 값이 키를 되참조:  ", w3[1] == nil and "회수됨" or "★남아있음")
	local _ = R1, R2, R3
end

print()
print("=== 3. 같은 Slot 마운트→언마운트→재마운트 10,000 사이클 ===")
do
	local s = Slot()
	s:Add(Instance.new("Frame")); s:Add(Instance.new("Frame"))
	local holder = q.Source(s)
	local p = Instance.new("Folder")
	dispatch.drive(p, { holder })
	for i = 1, 200 do holder:Set(nil); holder:Set(s) end
	local base = kb()
	for m = 1, 5 do
		for i = 1, 2000 do holder:Set(nil); holder:Set(s) end
		print(string.format("  사이클 %6d  +%.0f KB  (Length=%d)", m * 2000, kb() - base, s.Length:Get()))
	end
	local t0 = os.clock()
	for i = 1, 2000 do holder:Set(nil); holder:Set(s) end
	print(string.format("  2000 사이클 시간: %.1f ms", (os.clock()-t0)*1000))
end

print()
print("=== 4. 같은 Slot(요소 100개) 재마운트 사이클 비용 ===")
do
	local s = Slot()
	local f = {} for i = 1, 100 do f[i] = Instance.new("Frame") end
	s:Splice(1, 0, table.unpack(f))
	local holder = q.Source(s)
	local p = Instance.new("Folder")
	dispatch.drive(p, { holder })
	for i = 1, 100 do holder:Set(nil); holder:Set(s) end
	local base = kb()
	local t0 = os.clock()
	for i = 1, 2000 do holder:Set(nil); holder:Set(s) end
	print(string.format("  2000 사이클: %.1f ms, +%.0f KB", (os.clock()-t0)*1000, kb() - base))
end
