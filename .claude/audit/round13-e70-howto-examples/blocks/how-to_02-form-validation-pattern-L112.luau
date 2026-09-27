-- 폼 상태만 모아 둔 모듈(예: ReplicatedStorage/Client/UI/RegistrationFormState).
-- 화면을 만들지 않으므로 UI 없이도 require해서 검증할 수 있습니다.
type Submission = { Username: string, Password: string }

local function makeFormState()
    -- [1] 원본 입력값
    local store = q.Store({
        Username = q.Source(""),
        Password = q.Source(""),
    })

    -- [2] 필드별 판정 — 순수 파생 상태
    local isUsernameValid = store.Username:Compute(function(self)
        return #self:Get() >= 4
    end)

    local isPasswordValid = store.Password:Compute(function(self)
        local text = self:Get()
        return #text >= 8 and string.find(text, "%d") ~= nil
    end)

    -- [3] 둘을 하나로 — 후행 의존성으로 노드 하나만 더 만든다
    local canSubmit = isUsernameValid:Compute(function(validUser, _previous, validPass)
        return validUser:Get() and validPass:Get()
    end, isPasswordValid)

    -- [4] 제출 결과가 담기는 자리 — 바깥으로 나가는 하나뿐인 출구
    local submitted = q.Source<<Submission?>>(nil)

    return {
        Store = store,
        IsUsernameValid = isUsernameValid,
        IsPasswordValid = isPasswordValid,
        CanSubmit = canSubmit,
        Submitted = submitted,
    }
end

type FormState = typeof(makeFormState())
