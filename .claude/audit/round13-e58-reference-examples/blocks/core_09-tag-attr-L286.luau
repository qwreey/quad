local hp = q.Source<<number | QuadTypes.None>>(100)
local stats = D.Frame {
    q.Attr({ Hp = hp, Name = "hero" }),
    D.TextLabel { Text = "체력" },
}
hp:Set(80)      -- 속성 Hp가 따라 바뀐다
hp:Set(q.None)  -- 속성 Hp가 삭제된다
