--!strict
-- E70 strict (generated) — how-to_04-network-and-input-bridge-L197
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_04-network-and-input-bridge-L22) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
--[[E70 보강 pre]]
local SomeSignal: RBXScriptSignal = nil :: any
-- ==== doc block how-to/04-network-and-input-bridge.md:197 ====
local function StatusPanel()
    -- 컴포넌트를 만들 때 연결하고, 파괴될 때 끊는다
    local conn = SomeSignal:Connect(function(...) --[[ … ]] end)

    return D.Frame {
        -- 숫자 키 자리에 둔다 — 돌려주는 Effect이 이 인스턴스의 수명에 묶여야 파괴 때 돈다
        q.OnDestroyed(function()
            conn:Disconnect()
        end),
        -- …나머지 자식·프로퍼티…
    }
end
