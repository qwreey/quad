--!strict
-- E58 strict (generated) — core_08-modifier-L103
-- ==== page prologue core/08-modifier.md (core_08-modifier-L18.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local QuadTypes = require("../../../../quad-roblox/luau_packages/quad_types") -- 설정 모듈이 다시 내보내지 않는 타입(`QuadTypes.FieldOut<T>` 등)
local D = q.Declaration
-- ==== doc block core/08-modifier.md:103 (line offset marker) ====
local card = q.Modifier {
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
}
local wide = q.Modifier(card, { Size = UDim2.fromScale(1, 0.4) }) -- card를 깔고 Size를 얹는다
local panel = D.Frame { wide }
