--!strict
-- GS 18: 문서 지시(props·Ctx 줄·Theme require 삭제, 버튼 색 리터럴)를 16/17 모양에 문자 그대로 적용 + §1~§3
const q = require("./Quad")
const D = q.Declaration
return function()
    const count = q.Source(10)
    const unit = q.Source("점")
    const blocker = q.Blocker()
    const countText = count:Compute(function(c, prev, u)
        return `{c:Get()} {u:Get()}`
    end, unit):Apply(blocker)
    return D.Frame {
        D.TextLabel { Text = countText },
        D.TextButton {
            BackgroundColor3 = Color3.fromRGB(0, 162, 255),
            Text = "+ 1",
            Activated = function()
                count:Set(count:Get() + 1) -- [E56: HEAD 18장 지시로 갱신(H-739 반영분)]
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
