-- 예시 컴포넌트 — Text가 비어 있으면 던진다(던지는 쪽은 아무 컴포넌트여도 됩니다)
local function Card(props: { read Text: string }): Frame
    if props.Text == "" then
        error("Card: Text must not be empty")
    end
    return D.Frame {
        D.TextLabel { Text = props.Text },
    }
end

const errorState = q.Source<<any>>(nil)

local function onError(err: any): Instance
    errorState:Set(err)
    return D.Frame {} -- 자리표시 값 — Card가 있어야 할 자리를 채우기만 한다
end

const SafeCard = q.Fallback(Card, onError)
