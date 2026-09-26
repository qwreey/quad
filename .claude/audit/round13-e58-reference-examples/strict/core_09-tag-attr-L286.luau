--!strict
-- E58 strict (generated) — core_09-tag-attr-L286
-- ==== page prologue core/09-tag-attr.md (core_09-tag-attr-L20.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local QuadTypes = require("../../../../quad-roblox/luau_packages/quad_types") -- 설정 모듈이 다시 내보내지 않는 타입(`QuadTypes.None` 등)
local D = q.Declaration
-- ==== doc block core/09-tag-attr.md:286 (line offset marker) ====
local hp = q.Source<<number | QuadTypes.None>>(100)
local stats = D.Frame {
    q.Attr({ Hp = hp, Name = "hero" }),
    D.TextLabel { Text = "체력" },
}
hp:Set(80)      -- 속성 Hp가 따라 바뀐다
hp:Set(q.None)  -- 속성 Hp가 삭제된다
