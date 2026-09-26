local store = q.Store({ hp = q.Source(100) })

local mp = store:Of<<number>>("mp") -- 결과 타입은 호출자가 직접 준다
mp:Set(50) -- 갓 만들어진 Source의 값은 nil이므로 먼저 채운다
print(store:Of<<number>>("mp") == mp) --> true (같은 객체)
