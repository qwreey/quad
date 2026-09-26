--!strict
-- E58 strict (generated) — core_06-slot-L82
-- ==== page prologue core/06-slot.md (core_06-slot-L16.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local QuadTypes = require("../../../../quad-roblox/luau_packages/quad_types") -- 설정 모듈이 다시 내보내지 않는 타입(`QuadTypes.SlotItem<T>`·`QuadTypes.KeyGone`)
local D = q.Declaration
-- ==== doc block core/06-slot.md:82 (line offset marker) ====
local list = q.Slot<<Instance>>()      -- 빈 Slot(아직 수동/재조정 모드 미정)
local fixed = q.Slot<<Instance>>({     -- 초기 원소 둘, 수동 CRUD Slot으로 고정
    D.TextLabel { Text = "A" },
    D.TextLabel { Text = "B" },
})

local panel = D.Frame { list, fixed }  -- 숫자 키에 놓으면 그 자리가 Slot의 자식 구간이 된다
