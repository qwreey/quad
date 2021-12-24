local IsRoblox = version and version() or nil

-- 로블록스 이외의 다른 lua 플렛폼을 위한 바인드 스탭,
-- 여기에다 프레임 앞에 실행되는 이벤트를 핸들링해서 StepFunction 을
-- 연동해주면 됨,

-- 이 함수는 한 프레임마다 트윈들을 가져와서 실행시켜줌, (만약 트윈 효과가 하나도 없으면 그냥 건너뜀)

local module = {}
function module.BindStep(StepFunction)
    if IsRoblox then
        local RunService = game:GetService("RunService")
        if RunService:IsStudio() and (not RunService:IsRunning()) and RunService:IsEdit() then
            RunService.Heartbeat:Connect(StepFunction)
        else
            RunService.Stepped:Connect(StepFunction)
        end
    else
        -- do something here
    end
end

return module
