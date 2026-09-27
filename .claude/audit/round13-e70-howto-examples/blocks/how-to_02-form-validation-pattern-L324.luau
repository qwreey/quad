-- props에 콜백이 하나 늘고, makeFormState의 [4] Submitted 필드는 사라집니다
type Props = { read Form: FormState, read OnSubmit: (Submission) -> () }

local function submit(props: Props)
    if not props.Form.CanSubmit:Get() then
        return
    end
    props.OnSubmit({
        Username = props.Form.Store.Username:Get(),
        Password = props.Form.Store.Password:Get(),
    })
end
