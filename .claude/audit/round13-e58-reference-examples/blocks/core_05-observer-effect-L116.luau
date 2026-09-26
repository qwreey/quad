local hp = q.Source(100)
local log = {}

local observer = hp:Observer(function(target, self, emitFrom)
	table.insert(log, target:Get())
end)
print(#log) --> 1 (등록 즉시 1회)

hp:Set(80)
print(#log) --> 1 (아직 살아나지 않았다 — 보류)

observer:Subscribe()
print(#log) --> 2 (보류분 1회 재생, 최신값 80)

hp:Set(60)
print(#log) --> 3
