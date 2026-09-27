-- ❌ 수동으로 시작했다가 나중에 :List로 갈아타기
local s = q.Slot()
s:Add(D.Frame {})
s:List(items, function(ctx) return D.Frame { Text = ctx.Item } end) -- 에러

-- ✅ 데이터 배열이 있다면 처음부터 :List
local s2 = q.Slot()
s2:List(items, function(ctx) return D.Frame { Text = ctx.Item } end)
