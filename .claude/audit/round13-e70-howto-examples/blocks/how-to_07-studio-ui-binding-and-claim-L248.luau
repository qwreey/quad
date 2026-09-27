local function ShopWindow(isOpen: q.Source<boolean>, rows: q.Slot<Instance>)
    local window = ReplicatedStorage:WaitForChild("Templates"):WaitForChild("ShopWindow"):Clone()

    q.Claim(window, M.Frame(M.Root)({
        M.TextButton("CloseButton")({
            Activated = function()
                isOpen:Set(false)
            end,
        }),
        -- 그려지는 직계 자식은 전부 적는다. 손댈 것이 없으면 빈 props로
        M.TextLabel("TitleText")({}),
        M.Frame("ContentArea")({ rows }),
        Visible = isOpen,
    }))

    return window
end
