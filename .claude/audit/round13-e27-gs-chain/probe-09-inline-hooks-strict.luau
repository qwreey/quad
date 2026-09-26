--!strict
-- E27: 생성자 테이블 안 인라인 훅 — <<Frame>> 타입 인자가 콜백 파라미터에 안 닿음(typing-limits 8.20과 같은 증상)
const q = require("./s10-config")
const D = q.Declaration
const f = D.Frame { q.OnRendered<<Frame>>(function(inst) const kids = inst:GetChildren(); print(#kids) end) }
const g = D.Frame { q.OnRendered<<Frame>>(function(inst: Frame) const kids = inst:GetChildren(); print(#kids) end) }
const h = D.Frame { q.OnCreated<<Frame>>(function(inst) local x: number = inst.ClassName end) }
print(f, g, h)
