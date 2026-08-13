-- 스파이크: research/component-fallback-plan.md의 Fallback 메커니즘 의사코드가
-- 실제 Luau에서 그대로 동작하는지 실측. 열린 질문:
--   "xpcall 에러 핸들러 배선의 실측 — 에러 핸들러 안에서 클로저 업밸류에 쓴
--    값이 바깥에서 제대로 보이는지, debug.traceback이 에러 시점 스택을 정확히
--    찍는지"
-- luau fallback-xpcall-spike.luau 로 실행

local failures = 0
local function check(name, cond)
    if cond then
        print("[PASS] " .. name)
    else
        failures += 1
        print("[FAIL] " .. name)
    end
end

-- 문서의 의사코드 그대로 옮김
local function Fallback(original, onError)
    return function(...)
        local trace: string? = nil
        local ok, resultOrErr = xpcall(original, function(err)
            trace = debug.traceback(nil, 2)
            return err
        end, ...)
        if ok then
            return resultOrErr
        end
        return onError(resultOrErr, trace)
    end
end

-- 1) 성공 경로 — onError 호출 안 되고 원래 값 그대로 통과하는지
do
    local Widget = function(props)
        return "OK:" .. props.name
    end
    local calledOnError = false
    local SafeWidget = Fallback(Widget, function(msg, trace)
        calledOnError = true
        return "ERR"
    end)
    local result = SafeWidget({ name = "widget1" })
    check("성공 경로 — 원래 반환값 그대로 통과", result == "OK:widget1")
    check("성공 경로 — onError 호출 안 됨", calledOnError == false)
end

-- 2) 실패 경로 — 업밸류 trace가 onError 호출 시점에 이미 채워져 있는지
do
    local Widget = function(props)
        error("boom: " .. props.name)
    end
    local capturedMsg, capturedTrace = nil, nil
    local SafeWidget = Fallback(Widget, function(msg, trace)
        capturedMsg = msg
        capturedTrace = trace
        return "PLACEHOLDER"
    end)
    local result = SafeWidget({ name = "widget2" })
    check("실패 경로 — onError의 반환값이 최종 결과", result == "PLACEHOLDER")
    check("실패 경로 — 에러 메시지가 onError에 전달됨", capturedMsg ~= nil and string.find(capturedMsg, "boom: widget2") ~= nil)
    check("실패 경로 — trace 업밸류가 onError 호출 시점에 nil이 아님(클로저 배선 정상)", capturedTrace ~= nil)
    if capturedTrace then
        print("  captured trace:\n" .. capturedTrace)
    end
end

-- 3) 깊은 중첩 호출에서도 traceback이 실패 지점까지 스택을 담는지
do
    local function level3(props)
        error("deep failure")
    end
    local function level2(props)
        return level3(props)
    end
    local function level1(props)
        return level2(props)
    end
    local capturedTrace = nil
    local SafeWidget = Fallback(level1, function(msg, trace)
        capturedTrace = trace
        return "PLACEHOLDER"
    end)
    SafeWidget({})
    local mentionsLevel3 = capturedTrace ~= nil and string.find(capturedTrace, "level3") ~= nil
    check("깊은 중첩 — traceback에 실패 지점 함수(level3)가 보임", mentionsLevel3)
    if capturedTrace then
        print("  nested trace:\n" .. capturedTrace)
    end
end

-- 4) 문자열이 아닌 에러 값(table)도 onError로 그대로 전달되는지
do
    local Widget = function(props)
        error({ code = 42, reason = "custom" })
    end
    local capturedMsg = nil
    local SafeWidget = Fallback(Widget, function(msg, trace)
        capturedMsg = msg
        return "PLACEHOLDER"
    end)
    SafeWidget({})
    check("비-문자열 에러 값(table)도 onError에 그대로 전달됨", type(capturedMsg) == "table" and capturedMsg.code == 42)
end

-- 5) onError 자체가 커링된 클로저인 경우(문서의 "추가 상태 필요하면 커링" 관용구)
do
    local Widget = function(props)
        error("ctx-fail")
    end
    local function makeErrorHandler(context)
        return function(message, trace)
            return "PLACEHOLDER(" .. context .. "):" .. message
        end
    end
    local SafeWidget = Fallback(Widget, makeErrorHandler("someContext"))
    local result = SafeWidget({})
    -- error("ctx-fail")의 기본 level(=1)이 "파일:줄: " 접두를 붙이므로
    -- message가 정확히 "ctx-fail"이 아님 — 아래 6번에서 별도로 실측/확정.
    check("커링된 onError 관용구가 그대로 동작(접두 포함 메시지가 이어붙여짐)",
        string.find(result, "^PLACEHOLDER%(someContext%):.*ctx%-fail$") ~= nil)
end

-- 6) error(msg)의 기본 동작 — onError가 받는 message에 "파일:줄: " 접두가
--    자동으로 붙는지(레벨 지정 없이 호출한 경우), error(msg, 0)으로 접두를
--    끌 수 있는지
do
    local defaultLevelMsg = nil
    do
        local Widget = function()
            error("no-level-specified")
        end
        local SafeWidget = Fallback(Widget, function(msg) return msg end)
        defaultLevelMsg = SafeWidget()
    end
    check("error(msg) 기본 호출 — onError가 받는 message에 위치 접두(\"파일:줄: \")가 자동으로 붙음",
        defaultLevelMsg ~= defaultLevelMsg:match("^no%-level%-specified$")
            and string.find(defaultLevelMsg, "no%-level%-specified$") ~= nil
            and defaultLevelMsg ~= "no-level-specified")
    print("  defaultLevelMsg = " .. tostring(defaultLevelMsg))

    local zeroLevelMsg = nil
    do
        local Widget = function()
            error("no-level-specified", 0)
        end
        local SafeWidget = Fallback(Widget, function(msg) return msg end)
        zeroLevelMsg = SafeWidget()
    end
    check("error(msg, 0) — 위치 접두 없이 순수 메시지만 onError에 전달됨",
        zeroLevelMsg == "no-level-specified")
    print("  zeroLevelMsg = " .. tostring(zeroLevelMsg))
end

-- 6) original에 여러 인자를 넘기는 vararg 경로(문서 시그니처 (T...) -> Comp)
do
    local Widget = function(a, b, c)
        if c == nil then
            error("missing c")
        end
        return a + b + c
    end
    local SafeWidget = Fallback(Widget, function(msg, trace)
        return -1
    end)
    check("vararg 성공 경로", SafeWidget(1, 2, 3) == 6)
    check("vararg 실패 경로", SafeWidget(1, 2) == -1)
end

print("")
if failures == 0 then
    print("=== ALL PASS ===")
else
    print("=== " .. failures .. " FAILURE(S) ===")
end
