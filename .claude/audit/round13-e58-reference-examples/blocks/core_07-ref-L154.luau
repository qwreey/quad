local doneRef = q.PostRef<<Frame?>>(nil)
local card = D.Frame {
    doneRef,
    D.TextLabel { Text = "A" },
    D.TextLabel { Text = "B" },
}
doneRef:Callback(function(inst)
    if inst then
        -- 자식 둘이 이미 다 붙어 있다
    end
end)
