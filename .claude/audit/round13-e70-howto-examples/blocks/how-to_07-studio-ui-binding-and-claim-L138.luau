local function ItemCard(item: { id: string, label: string }, label: q.Source<string>)
    local card = ItemTemplate:Clone()          -- 정적 프로퍼티는 이미 들어가 있다
    return q.Claim(card, M.Frame(M.Root)({     -- 디스크립터는 사본마다 새로 만든다
        M.TextLabel("ItemName")({ Text = label }),
        M.TextButton("ActionButton")({
            Activated = function()
                print("Selected:", item.id)
            end,
        }),
    }))
end
