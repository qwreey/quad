--!strict
-- E58 strict (generated) — core_09-tag-attr-L113
-- ==== page prologue core/09-tag-attr.md (core_09-tag-attr-L20.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local QuadTypes = require("../../../../quad-roblox/luau_packages/quad_types") -- 설정 모듈이 다시 내보내지 않는 타입(`QuadTypes.None` 등)
local D = q.Declaration
--[[E58 보강 pre]]
local isSelected = true
-- ==== doc block core/09-tag-attr.md:113 (line offset marker) ====
local base = q.Tag("card")
local selected = base:Added("selected")
local both = base:Added({ "selected", "hovered" })
local maybe = base:Added(if isSelected then "selected" else nil) -- 조건은 인자 안에 — 결과는 늘 새 Tag
