local items = q.Source({ "a" })
table.insert(items:Get(), "b") -- 제자리 변경 — 이것만으로는 아무도 모른다
items:Emit()                   -- 이제 하류가 안다
