local hp = q.Source(100)
local mp = q.Source(50)
local blocker = q.Blocker()

local shownHp: q.State<number> = hp:Apply(blocker)
local shownMp: q.State<number> = mp:Apply(blocker)

blocker:On()
hp:Set(80)
mp:Set(40) -- 아직 아무도 통지받지 않았다
blocker:Off() -- 두 게이트가 각각 한 번씩 통지
