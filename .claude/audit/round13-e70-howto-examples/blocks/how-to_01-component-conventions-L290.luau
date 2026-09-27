local function newCounter(initial: number)
    local count = q.Source(initial)
    -- --!strict에서는 :Compute 콜백 파라미터에 주석이 필요하다
    local isEven: q.State<boolean> = count:Compute(function(c: q.StateData<number>): boolean
        return c:Get() % 2 == 0
    end)

    local function increment()
        count:Set(count:Get() + 1)
    end

    return { count = count, isEven = isEven, increment = increment }
end

-- 컴포넌트 안에서, 조건문 안에서, 루프 안에서 아무 제약 없이 호출 가능
local left, right = newCounter(0), newCounter(10)
