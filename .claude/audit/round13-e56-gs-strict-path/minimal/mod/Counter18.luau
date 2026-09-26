--!strict
-- GS 18 (HEAD 문서 지시 — 16장의 settings 셋도 지우고 +1로 되돌림; E27 A3 이후 문서가 고쳐짐) — E56 주석판
const q = require("./Quad")
const D = q.Declaration
return function(): Frame -- props 없음(18장 "props 없이 값을 직접 박은 단독 카운터")
    const count = q.Source(10)
    const unit = q.Source("점")
    const blocker = q.Blocker()
    const countText= count:Compute(function(c, prev, u) -- [§6 + core/03 deps 주석]
        return `{c:Get()} {u:Get()}`
    end, unit):Apply(blocker)
    return D.Frame {
        D.TextLabel { Text = countText },
        D.TextButton {
            BackgroundColor3 = Color3.fromRGB(0, 162, 255),
            Text = "+ 1",
            Activated = function()
                count:Set(count:Get() + 1)
            end,
        },
        D.TextButton {
            Text = "단위 바꾸기",
            Activated = function()
                blocker:On()
                const toPoint = unit:Get() == "점"
                count:Set(if toPoint then count:Get() * 10 else count:Get() // 10)
                unit:Set(if toPoint then "포인트" else "점")
                blocker:Off()
            end,
        },
        D.TextButton {
            Text = "일시정지",
            Activated = function()
                if blocker.Blocking then blocker:Off() else blocker:On() end
            end,
        },
    }
end
