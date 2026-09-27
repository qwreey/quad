--!strict
-- E70 strict (generated) — how-to_02-form-validation-pattern-L179
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_02-form-validation-pattern-L27) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
--[[E70 보강 pre]]
local __u, __p = q.Source(""), q.Source("")
local isUsernameValid: q.State<boolean> = __u:Compute(function(s: q.StateData<string>): boolean return #s:Get() >= 4 end)
local isPasswordValid: q.State<boolean> = __p:Compute(function(s: q.StateData<string>): boolean return #s:Get() >= 8 end)
-- ==== doc block how-to/02-form-validation-pattern.md:179 ====
-- makeFormState 안에서, [3] 대신
local canSubmit = isUsernameValid:Depend(isPasswordValid):Compute(function(validUser)
    return validUser:Get() and isPasswordValid:Get()   -- :Depend한 값은 클로저로 읽는다
end)
