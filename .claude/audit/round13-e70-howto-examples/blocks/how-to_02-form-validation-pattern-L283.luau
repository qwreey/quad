-- 진입점(예: Main.client.luau)
local form = makeFormState()

local screen = D.ScreenGui {
    RegistrationForm { Form = form },

    -- 숫자 키 자리의 Observer — 이 ScreenGui가 사는 동안만 관측한다
    -- (파라미터 타입을 적어야 strict가 payload의 필드를 검사합니다 — 인라인 자리에선 타입이 unknown으로 굳습니다)
    form.Submitted:Observer(function(target: q.StateData<Submission?>)
        local payload = target:Get()
        if payload == nil then
            return -- 묶이는 순간의 첫 발화 — 아직 제출 전이다
        end
        -- 여기서 서버로 보내거나 다음 화면으로 넘긴다
        print("가입 요청:", payload.Username)
    end),
}
