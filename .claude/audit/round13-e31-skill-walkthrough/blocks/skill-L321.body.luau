-- source: SKILL.md:321-326
local selected = q.Source<<Instance?>>(nil)
local slot = q.Slot<<Instance>>()
slot:Single(selected, nil, { OwnsElements = false })
-- selected:Set(other) now unparents the previous element instead of destroying it
