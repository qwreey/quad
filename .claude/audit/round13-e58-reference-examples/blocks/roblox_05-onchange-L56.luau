local size = q.Source(UDim2.fromScale(1, 0))

local box = D.Frame({
	Size = size,
	q.OnChange("AbsoluteSize", function(v: Vector2) -- 읽기 전용 프로퍼티도 된다
		print(v.X, v.Y)
	end),
	q.OnChange("Visible", function(v)               -- 주석을 생략해도 boolean으로 추론된다
		local _: boolean = v
	end),
})
