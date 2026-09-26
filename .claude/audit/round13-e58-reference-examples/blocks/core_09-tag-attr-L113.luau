local base = q.Tag("card")
local selected = base:Added("selected")
local both = base:Added({ "selected", "hovered" })
local maybe = base:Added(if isSelected then "selected" else nil) -- 조건은 인자 안에 — 결과는 늘 새 Tag
