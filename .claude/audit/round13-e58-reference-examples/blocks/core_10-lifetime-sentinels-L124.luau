local slot = q.Slot()
local child = D.Frame {}
slot:Add(child)

slot:Extract(1) -- 파괴하지 않고 자리에서 뺀다(Remove는 파괴한다)
q.dispose(child) -- 그 다음에 파괴
