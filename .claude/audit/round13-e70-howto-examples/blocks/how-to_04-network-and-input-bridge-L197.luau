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
