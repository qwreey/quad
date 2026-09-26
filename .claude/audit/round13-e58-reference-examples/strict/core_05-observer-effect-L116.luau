--!strict
-- E58 strict (generated) — core_05-observer-effect-L116
-- ==== page prologue core/05-observer-effect.md (core_05-observer-effect-L16.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
-- ==== doc block core/05-observer-effect.md:116 (line offset marker) ====
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
