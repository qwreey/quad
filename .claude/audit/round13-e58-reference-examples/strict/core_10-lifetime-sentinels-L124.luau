--!strict
-- E58 strict (generated) — core_10-lifetime-sentinels-L124
-- ==== page prologue core/10-lifetime-sentinels.md (core_10-lifetime-sentinels-L13.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
-- ==== doc block core/10-lifetime-sentinels.md:124 (line offset marker) ====
local slot = q.Slot()
local child = D.Frame {}
slot:Add(child)

slot:Extract(1) -- 파괴하지 않고 자리에서 뺀다(Remove는 파괴한다)
q.dispose(child) -- 그 다음에 파괴
