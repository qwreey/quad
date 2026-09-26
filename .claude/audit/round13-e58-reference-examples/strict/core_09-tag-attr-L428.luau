--!strict
-- E58 strict (generated) — core_09-tag-attr-L428
-- ==== page prologue core/09-tag-attr.md (core_09-tag-attr-L20.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local QuadTypes = require("../../../../quad-roblox/luau_packages/quad_types") -- 설정 모듈이 다시 내보내지 않는 타입(`QuadTypes.None` 등)
local D = q.Declaration
-- ==== doc block core/09-tag-attr.md:428 (line offset marker) ====
local label = q.Source("hero")
local card = D.Frame {
    q.StringAttr("Label", label),
    q.StringAttr("Kind", "unit"),
}
label:Set("villain")                                    -- 속성 Label이 따라 바뀐다
local blank = D.Frame { q.StringAttr("Label", q.None) } -- 값 자리의 None: 그 속성을 지운다
