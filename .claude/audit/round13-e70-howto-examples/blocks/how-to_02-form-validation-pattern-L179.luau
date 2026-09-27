-- makeFormState 안에서, [3] 대신
local canSubmit = isUsernameValid:Depend(isPasswordValid):Compute(function(validUser)
    return validUser:Get() and isPasswordValid:Get()   -- :Depend한 값은 클로저로 읽는다
end)
