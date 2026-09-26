--!strict
-- E58 strict (generated) — core_02-source-L110
-- ==== page prologue core/02-source.md (core_02-source-L11.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
--[[E58 보강 pre]]
local __n = 0
-- ==== doc block core/02-source.md:110 (line offset marker) ====
local items = q.Source({ "a" })
table.insert(items:Get(), "b") -- 제자리 변경 — 이것만으로는 아무도 모른다
items:Emit()                   -- 이제 하류가 안다
