local label = q.Source("hero")
local card = D.Frame {
    q.StringAttr("Label", label),
    q.StringAttr("Kind", "unit"),
}
label:Set("villain")                                    -- 속성 Label이 따라 바뀐다
local blank = D.Frame { q.StringAttr("Label", q.None) } -- 값 자리의 None: 그 속성을 지운다
