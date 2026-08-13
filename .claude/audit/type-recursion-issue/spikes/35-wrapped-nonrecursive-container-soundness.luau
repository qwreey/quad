--!strict
-- 마지막 분리: "재귀"가 핵심 원인인지, 아니면 "로컬 제네릭 U를 아무
-- 컨테이너로든 감싸서 반환하면" 다 이 모양인지 확인. Box<U>는 자기 자신을
-- 재참조하지 않는 평범한 제네릭 컨테이너(Compute 필드 없음) -- 여기서도
-- Unifiable<Error>가 뜨면 "재귀"는 무관하고 "제네릭 U를 감싸서 반환"
-- 자체가 원인.

type Box<A> = { value: A }

local function Compute<T, U>(self: Box<T>, fn: (self: Box<T>) -> U): Box<U>
	return { value = fn(self) }
end

local box: Box<number> = { value = 5 }
local s = Compute(box, function(x) return tostring(x.value) end)

local wrong: number = s.value -- s가 Box<string>이어야 하므로 에러여야 함
local right: string = s.value

print("35 done", wrong, right)
