-- v1: local myStore = Store.GetStore("myStore")  — 이름으로 찾는 전역 스토어는 없다
-- defaults의 값은 반드시 Source다(평범한 값을 주면 생성자가 그 자리에서 에러)
local store = q.Store { Color = q.Source(Color3.fromRGB(255, 255, 255)) }
store.Color:Set(Color3.fromRGB(0, 0, 0))

-- v1: 선언한 적 없는 키를 그냥 대입(myStore.Text = "...")  → :Of가 유일한 문
local text = store:Of<<string>>("Text") -- 타입 인자를 빼면 Source<any>가 된다
text:Set("0 sec")

local label = D.TextLabel { Text = text, BackgroundColor3 = store.Color }
