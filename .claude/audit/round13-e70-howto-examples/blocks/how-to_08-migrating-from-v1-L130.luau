local Op = q.Operator

-- v1: register:Add(500)  (숫자일 때만 성립한다)
local price = q.Source(100)
local total = price:Apply(Op.Sum(500))

-- v1: register:Default("Guest")
local nickname = q.Source<<string?>>(nil)
local shown = nickname:Apply(Op.Alternative("Guest"))

-- v1: register:With(테이블)  — 테이블 한 칸을 반응형으로 읽기
local theme = q.Source({ Primary = Color3.fromRGB(0, 120, 255) })
local primary = theme:Apply(Op.Indexed<<Color3>>("Primary"))

-- v1의 UDim2/Color3 덧셈은 Operator가 아니라 :Compute로
local base = q.Source(UDim2.fromOffset(0, 0))
local offset = q.Source(UDim2.fromOffset(0, 40))
local moved = base:Compute(function(
	self: q.StateData<UDim2>,
	_prev: UDim2?,
	off: q.StateData<UDim2>
): UDim2
	return self:Get() + off:Get()
end, offset)
