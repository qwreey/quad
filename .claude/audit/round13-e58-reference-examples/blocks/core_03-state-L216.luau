local raw = q.Source(0)
local release: ((commit: boolean?) -> boolean)?

-- 상류 변경을 무조건 붙잡아 두고, release()를 부를 때만 흘려보내는 정책
local held: q.State<number> = raw:Gate(function(emit)
	release = emit
	return function() end -- 상류 emit이 와도 아무것도 하지 않는다 = 유보
end)

local seen = {}
held:Observer(function(target)
	table.insert(seen, target:Get())
end):Subscribe()

raw:Set(1)
raw:Set(2)
print(#seen, held:Get()) --> 1  2   (통지는 설치 발화 한 번뿐, 값은 이미 최신)
print((release :: any)()) --> true (모아둔 배치를 흘려보냄 → 구독자 1회 발화)
