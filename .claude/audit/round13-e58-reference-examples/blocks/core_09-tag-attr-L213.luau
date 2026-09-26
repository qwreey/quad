local a, b = q.Tag("x"), q.Tag("y")
local merged = q.Tag.Merged(a, b)  -- {x, y}
local same = q.Tag(a, b)           -- 같은 결과, 느슨한 철자
