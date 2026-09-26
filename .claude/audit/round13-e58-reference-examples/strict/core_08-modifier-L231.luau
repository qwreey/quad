--!strict
-- E58 strict (generated) — core_08-modifier-L231
-- ==== page prologue core/08-modifier.md (core_08-modifier-L18.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local QuadTypes = require("../../../../quad-roblox/luau_packages/quad_types") -- 설정 모듈이 다시 내보내지 않는 타입(`QuadTypes.FieldOut<T>` 등)
local D = q.Declaration
-- ==== doc block core/08-modifier.md:231 (line offset marker) ====
local function rounded(mod: any)
    return mod:BorderSizePixel(0):BackgroundTransparency(0.1)
end

local styled = q.Modifier():Apply(rounded)
