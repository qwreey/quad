--!strict
-- E58 strict (generated) — core_06-slot-L171
-- ==== page prologue core/06-slot.md (core_06-slot-L16.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local QuadTypes = require("../../../../quad-roblox/luau_packages/quad_types") -- 설정 모듈이 다시 내보내지 않는 타입(`QuadTypes.SlotItem<T>`·`QuadTypes.KeyGone`)
local D = q.Declaration
-- ==== doc block core/06-slot.md:171 (line offset marker) ====
local slot = q.Slot<<Instance>>()
slot:Add(D.TextLabel { Text = "끝에" })
slot:Add(D.TextLabel { Text = "앞에" }, 1)
local root = D.Frame { slot }
