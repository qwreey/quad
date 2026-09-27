const q = require("@game/ReplicatedStorage/Client/UI/Quad")
const D = q.Declaration

const count = q.Source(0)                       -- ① 값의 원천
const countText = count:Compute(function(c)     -- ② 파이프: 숫자를 글자로 처리한다
    return `카운트: {c:Get()}`
end)

const CardStyle = D.Modifier.Frame {             -- 스타일은 값 하나로
    BackgroundColor3 = Color3.fromRGB(35, 35, 42),
    BorderSizePixel = 0,
}

const card = D.Frame {
    CardStyle,                                    -- 숫자 키: 스타일을 놓는다
    Size = UDim2.fromOffset(220, 120),
    UICorner = 12,
    D.TextLabel { BackgroundTransparency = 1, Text = countText },  -- ③ 파이프 끝을 프로퍼티에 꽂는다
    D.TextButton {
        Text = "+ 1",
        Activated = function() count:Set(count:Get() + 1) end,     -- 이벤트도 문자 키에 이름으로
    },
}
