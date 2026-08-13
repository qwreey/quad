--!strict
-- 07(통과)과 04(실패)의 유일한 구조적 차이는: State는 자기 자신을 참조하는
-- 메소드 필드(Get: (self:State)->T)를 갖고 있고, Box는 순수 데이터 필드뿐.
-- 그 가설을 검증: Box에 자기참조 메소드 필드(Get)를 추가하되, Compute는
-- 여전히 필드가 아니라 자유 함수로 둔 채로도 깨지는지 확인.

type Box3 = {
	value: number,
	Get: (self: Box3) -> number, -- 자기참조 메소드 필드 추가
}

local function Compute<U>(self: Box3, fn: (self: Box3) -> U): U
	return fn(self)
end

local box: Box3 = (nil :: any) :: Box3

local doubled = Compute(box, function(s) return s:Get() * 2 end)

print("10 done")
