--!strict
-- E58 strict (generated) — core_09-tag-attr-L213
-- ==== page prologue core/09-tag-attr.md (core_09-tag-attr-L20.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local QuadTypes = require("../../../../quad-roblox/luau_packages/quad_types") -- 설정 모듈이 다시 내보내지 않는 타입(`QuadTypes.None` 등)
local D = q.Declaration
-- ==== doc block core/09-tag-attr.md:213 (line offset marker) ====
local a, b = q.Tag("x"), q.Tag("y")
local merged = q.Tag.Merged(a, b)  -- {x, y}
local same = q.Tag(a, b)           -- 같은 결과, 느슨한 철자
