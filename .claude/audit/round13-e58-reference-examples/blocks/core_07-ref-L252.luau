local ref = q.Ref(0)
ref:Callback(function(v) print("값", v) end) -- 등록 즉시 0으로 한 번 불린다
ref:Set(1):Set(2)                            -- 체이닝
