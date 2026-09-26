--!strict
-- E27 최소 재현: GS 06 §5 "strict에서 타입 검사가 먼저 막는다" — 문서 그대로(무주석 derived)는 통과, State 주석을 달면 거부
const q = require("./s10-config")
const D = q.Declaration
const name = q.Source("quad")
const derived = name:Compute(function(n) return n:Get() end)
const derived2: q.State<string> = name:Compute(function(n) return n:Get() end)
const box = D.TextBox { q.Out("Text", derived) }
const box2 = D.TextBox { q.Out("Text", derived2) }
const box3 = q.Out("Text", derived)
print(box, box2, box3)
