local hp = q.Source(100)
local blocker = q.Blocker()
local shown: q.State<number> = hp:Apply(blocker)

blocker:On()
hp:Set(80)
blocker:OffWithoutEmit() -- 80이라는 통지는 나가지 않는다
print(shown:Get()) --> 80 (값은 언제나 최신)
