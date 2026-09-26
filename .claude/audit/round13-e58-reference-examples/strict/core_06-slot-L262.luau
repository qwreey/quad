--!strict
-- E58 strict (generated) — core_06-slot-L262
-- ==== page prologue core/06-slot.md (core_06-slot-L16.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local QuadTypes = require("../../../../quad-roblox/luau_packages/quad_types") -- 설정 모듈이 다시 내보내지 않는 타입(`QuadTypes.SlotItem<T>`·`QuadTypes.KeyGone`)
local D = q.Declaration
-- ==== doc block core/06-slot.md:262 (line offset marker) ====
local slot = q.Slot<<Instance>>({ D.Frame {}, D.Frame {}, D.Frame {} })
local removed = slot:Splice(2, 1, D.Frame {}, D.Frame {}) -- 2번을 빼고 그 자리에 둘을 넣는다
-- removed[1] 은 살아 있는 채로 손에 들어온다
