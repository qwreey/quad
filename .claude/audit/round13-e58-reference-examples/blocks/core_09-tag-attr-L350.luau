local theme = q.Attr({ Accent = "blue", Size = 1 })
local override = q.Attr({ Accent = "red" })

local final = q.Attr.Overridden(theme, override) -- Accent = "red"
-- q.Attr.Merged(theme, override) 였다면 겹침 에러
