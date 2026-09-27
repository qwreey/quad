--!strict
-- E70 strict (generated) — how-to_01-component-conventions-L290
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_01-component-conventions-L14) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
local None = q.None

-- 값이 아니라 '타입 이름'을 가져오는 모듈
local QuadTypes = require("../../../../quad-roblox/luau_packages/quad_types") -- 설정 모듈이 다시 내보내지 않는 타입(`QuadTypes.StateMarker<T>` 등)
-- 클래스별 Modifier·요소 타입(`TextButtonModifier`/`IntoTextButton`/`FrameElem` 등)은 quad_roblox 패키지 루트가 내보낸다
local RobloxModule = require("../../../../quad-roblox/src")
-- ==== doc block how-to/01-component-conventions.md:290 ====
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
