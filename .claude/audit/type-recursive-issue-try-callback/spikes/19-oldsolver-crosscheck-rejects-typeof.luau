--!strict
-- `--solver=old` 교차검증. 17번(quad 실계약 실측 성공 사례)을 그대로
-- `--solver=old`로 돌리면 어떻게 되는지 확인 -- typeof 간접참조 자체가
-- 옛 솔버에서 선언 시점에 거부되는지(`typing-limits.md` §8이 이미 예견한
-- 것)를 이 실험 세트에서도 재확인하기 위함.
--
-- 실행: luau-analyze --solver=old --annotate 19-oldsolver-crosscheck-rejects-typeof.luau
--
-- 결과: `typeof(Get)`/`typeof(Compute)` 선언 자체가
-- "Recursive type being used with different parameters"로 거부됨(새 솔버는
-- 정상 통과). 이 실험 세트의 새 발견(08/09/17/18)은 전부 이 typeof 패턴
-- 위에 얹혀 있으므로, 옛 솔버에서는 전부 마찬가지로 무효 -- quad가 이미
-- 새 솔버를 전제로 하고 있다는 기존 결론(typing-limits.md §8)과 정합적.
local function Get<T>(self: State<T>): T
    return nil :: any
end
local function Compute<T, U>(self: State<T>, func: (State<T>) -> U): State<U>
    return nil :: any
end
type State<T> = {
    Get: typeof(Get),
    Compute: typeof(Compute),
}

local test: State<number> = (nil :: any) :: State<number>
local computeForNumber: <U>(self: State<number>, func: (State<number>) -> U) -> State<U> = Compute
local d1 = computeForNumber(test, function(a) return a:Get() > 0 end)
local ok1: boolean = d1:Get()
