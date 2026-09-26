--!strict
-- E58 strict (generated) — sugar_04-lifecycle-hooks-L98
-- ==== page prologue sugar/04-lifecycle-hooks.md (sugar_04-lifecycle-hooks-L13.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
-- ==== doc block sugar/04-lifecycle-hooks.md:98 (line offset marker) ====
local function AnimatedBox(): Frame
    return D.Frame {
        Size = UDim2.fromOffset(100, 100),

        q.OnCreated<<Frame>>(function(inst)
            print("생성됨:", inst.ClassName)
        end),

        q.OnRendered<<Frame>>(function(inst)
            print("자기 서브트리 완성:", inst.Size)
        end),

        q.OnDestroyed(function()
            print("파괴 및 정리됨")
        end),
    }
end
