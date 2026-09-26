--!nocheck
-- E27: GS 16 §1 두 번째 블록(`settings.Step:Set(5)`, "확인용·지운다" 표시 없음)을 남긴 채 §3 stepButton을 만들면
local H = require("./harness")
local q, D = H.q, H.D
const settings = q.Store({ Step = q.Source(1) })
print(settings.Step:Get())   --> 1
settings.Step:Set(5)
const stepButton = D.TextButton {
    Text = settings.Step:Compute(function(s) return `보폭: {s:Get()}` end),
    Activated = function() settings.Step:Set(settings.Step:Get() % 5 + 1) end,
}
local seq = { stepButton.Text }
for _ = 1, 5 do stepButton.Activated:Fire(); table.insert(seq, stepButton.Text) end
print(table.concat(seq, " → "))
