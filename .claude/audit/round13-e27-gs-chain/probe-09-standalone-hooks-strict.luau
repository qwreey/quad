--!strict
-- E27: 테이블 밖에서 부른 훅 — <<Frame>>가 콜백 파라미터를 Frame으로 고정한다(대조군)
const q = require("./s10-config")
const r = q.OnRendered<<Frame>>(function(inst)
	local t: number = inst
	const kids = inst:GetChildren()
	print(#kids, t)
end)
const c = q.OnCreated<<Frame>>(function(inst)
	local t: number = inst
	print(t)
end)
print(r, c)
