local function Rows(props: { read Items: { string } })
    local rows = q.Slot<<Instance>>()
    for _, text in props.Items do
        rows:Add(D.TextLabel { Text = text })
    end
    return rows
end

local list = D.Frame {
    D.TextLabel { Text = "머리" },
    Rows { Items = { "a", "b" } },   -- 자식 셋: 머리 + a + b
}
