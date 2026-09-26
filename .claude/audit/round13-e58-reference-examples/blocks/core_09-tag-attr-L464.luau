local hp = q.Source(100)
local alive = D.Frame {
    q.NumberAttr("Hp", hp),
    q.BooleanAttr("Friendly", true),
}
