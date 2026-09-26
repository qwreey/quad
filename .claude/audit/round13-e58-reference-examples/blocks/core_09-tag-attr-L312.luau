local attr = q.Attr({ A = 1, B = q.Source("x"), C = q.None })
local map = attr:NameMap()
print(map.A)          -- 1
print(map.C == q.None) -- true (:Get()을 부르지 않는다)
