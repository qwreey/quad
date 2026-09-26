--!strict
-- E58 strict (generated) — core_08-modifier-L335
-- ==== page prologue core/08-modifier.md (core_08-modifier-L18.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local QuadTypes = require("../../../../quad-roblox/luau_packages/quad_types") -- 설정 모듈이 다시 내보내지 않는 타입(`QuadTypes.FieldOut<T>` 등)
local D = q.Declaration
-- ==== doc block core/08-modifier.md:335 (line offset marker) ====
local theme = q.Modifier { BackgroundTransparency = 0.2 }
local danger = q.Modifier { BackgroundTransparency = 0 }

local merged = q.Modifier.Overridden(theme, danger) -- danger가 이긴다
local same = theme:Overridden(danger)               -- 같은 함수, 같은 결과
