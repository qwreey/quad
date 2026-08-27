--!nocheck
local q = require("./core")

-- 가짜 시계/타이머 (luau CLI엔 task가 없다 — 주입 op setTimeout/clearTimeout 자리)
local now, timers, seq = 0, {}, 0
local function setTimeout(fn, d) seq += 1; timers[seq] = {at = now + d, fn = fn}; return seq end
local function clearTimeout(t) if t then timers[t] = nil end end
local function advance(to)
    while true do
        local best, bestId
        for id, t in timers do
            if t.at <= to and (best == nil or t.at < best.at or (t.at == best.at and id < bestId)) then best, bestId = t, id end
        end
        if not best then break end
        timers[bestId] = nil
        now = best.at
        best.fn()
    end
    now = to
end

-- 확정된 재작성 방향(gate-plan.md 5번) 그대로: 정책은 emit을 안 쥐고 Blocker만 조종한다.
-- variant "nopending": 문서가 확정한 대로 pending을 정책에서 없앤 형태
--   ("보류된 게 있는가는 Blocker의 HasBlockedEmit이 이미 들고 있다")
-- variant "localpending": 정책이 자기 pending 플래그를 따로 드는 형태
local function Throttle(state, Time, variant)
    return q.Gate(state, function(emit)
        local b = q.Blocker()
        local pass = b:Policy(emit)
        local window, pending = nil, false
        local openWindow, onWindowEnd
        function onWindowEnd()
            window = nil
            if variant == "nopending" then
                -- HasBlockedEmit을 읽을 수 없으므로 무조건 푼다 → 빈 배치면 no-op(8번)
                b:Off()        -- 보류분 방출(있으면)
                b:On()         -- 다음 창을 위해 다시 막음
                openWindow()   -- "통과했으니 창을 다시 엶" — pending 여부를 알 수 없어 항상
            else
                if pending then
                    pending = false
                    b:Off(); b:On()
                    openWindow()
                end -- pending 없으면 창을 안 열고 idle 복귀
            end
        end
        function openWindow() window = setTimeout(onWindowEnd, Time) end
        return function()      -- 상류 emit 도착
            if window == nil then
                -- 창 밖(idle) → leading 즉시 통과
                b:Off()        -- 안 막힌 상태로 만들고
                pass()         -- 통과
                b:On()         -- 창 동안 막음
                openWindow()
            else
                pending = true
                pass()         -- 막혀 있으므로 보류됨
            end
        end
    end, "throttle")
end

local function run(variant)
    print(("=== variant = %s ==="):format(variant))
    now = 0; timers = {}
    local S = q.Source(0)
    local g = Throttle(S, 1.0, variant)
    local hits = {}
    local o = q.Observer(g, function() table.insert(hits, ("t=%.2f v=%d"):format(now, g:Get())) end)
    S:Set(1)            -- t=0.0  leading 통과 기대
    advance(0.1); S:Set(2)
    advance(1.0)        -- 창 끝 → trailing 통과 기대
    advance(3.0)        -- 조용 → idle 복귀 기대
    print("  타이머 살아있는 개수(idle이면 0):", (function() local n=0 for _ in timers do n+=1 end return n end)())
    S:Set(3)            -- t=3.0  다시 leading 즉시 통과 기대
    print("  통과:", table.concat(hits, " | "))
    advance(5.0)
    print("  최종 통과:", table.concat(hits, " | "))
    print("  t=5까지 살아있는 타이머:", (function() local n=0 for _ in timers do n+=1 end return n end)())
end

run("localpending")
print()
run("nopending")
