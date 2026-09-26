--!strict
-- E58 strict (generated) — core_08-modifier-L200
-- ==== page prologue core/08-modifier.md (core_08-modifier-L18.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local QuadTypes = require("../../../../quad-roblox/luau_packages/quad_types") -- 설정 모듈이 다시 내보내지 않는 타입(`QuadTypes.FieldOut<T>` 등)
local D = q.Declaration
-- ==== doc block core/08-modifier.md:200 (line offset marker) ====
local size = q.Source(UDim2.fromOffset(100, 40))
local mod = q.Modifier { Size = size, Visible = true }

local storedSize = mod:Peek<<UDim2>>("Size")   -- Source 핸들 자체가 나온다
local visible = mod:Peek<<boolean>>("Visible") -- true
local missing = mod:Peek<<string>>("Text")     -- nil
