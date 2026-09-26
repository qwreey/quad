local hp = q.Source(100)

local effect = q.Effect(function(self)
	local value = hp:Get()
	print("hp:", value)
	return function()
		print("정리:", value) -- 다음 실행 직전 / 해제 / 파괴 때 정확히 한 번
	end
end, hp)
-- 여기서 이미 한 번 돌았다

effect:Subscribe()
hp:Set(80) -- 정리 → 재실행
effect:Unsubscribe() -- 마지막 정리 1회
