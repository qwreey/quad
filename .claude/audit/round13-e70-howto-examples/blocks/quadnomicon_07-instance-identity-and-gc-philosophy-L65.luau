local nop = (false or function(...) end)  -- `false or`: local 함수가 상수 접힘/인라인되는 것을 막는다(-O2)

local gchold = {}                          -- 이 inst에 매달린 값들의 강참조 홀더
local gcconn = inst:GetPropertyChangedSignal("ClassName"):Connect(function()
    nop(gchold, inst)  -- 절대 발화하지 않는다. 클로저가 둘을 업밸류로 잡는 것이 전부
end)
gchold[1] = gcconn                         -- 배열 1번 자리는 gcconn 전용

InstData:SetWeak(inst, "gchold", gchold)
InstData:SetWeak(inst, "gcconn", gcconn)
