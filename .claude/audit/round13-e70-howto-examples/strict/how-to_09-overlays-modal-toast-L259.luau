--!strict
-- E70 strict (generated) — how-to_09-overlays-modal-toast-L259
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_09-overlays-modal-toast-L10) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
const q = require("./Quad")
const D = q.Declaration
const None = q.None
-- ==== doc block how-to/09-overlays-modal-toast.md:259 ====
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
