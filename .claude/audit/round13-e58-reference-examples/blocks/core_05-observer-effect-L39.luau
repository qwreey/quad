local hp = q.Source(100)

local label = D.TextLabel {
	Text = hp:Compute(function(self: q.StateData<number>)
		return `HP {self:Get()}`
	end),

	-- 숫자 키 자리: 이 인스턴스의 수명에 매달린다
	-- (strict: 이 자리의 무주석 콜백은 target의 타입을 잃습니다 — 값을 쓰려면 `target: q.StateData<number>`처럼 주석을 달 것)
	hp:Observer(function(target)
		print("hp is now", target:Get())
	end),
	q.Effect(function()
		print("effect sees", hp:Get())
	end, hp),
}
