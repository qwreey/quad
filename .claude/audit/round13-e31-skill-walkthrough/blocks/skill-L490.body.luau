-- source: SKILL.md:490-496
local searchInput = q.Source("")
local debouncedQuery = searchInput:Apply(q.Debounce { Time = 0.3, MaxTime = 1.0 })

local scrollPos = q.Source(0)
local throttledScroll = scrollPos:Apply(q.Throttle { Time = 0.05 })
