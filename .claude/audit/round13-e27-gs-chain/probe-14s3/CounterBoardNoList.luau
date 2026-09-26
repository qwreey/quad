--!nonstrict
-- E27 최소 재현: GS 14 §2 CounterBoard + §3 "+ 카운터" 버튼(문서 그대로, Counter 대신 라벨) — nonstrict 신 솔버 진단
const q = require("./Quad")
const D = q.Declaration
return function(props)
    const list = q.Slot()
    return D.Frame {
        list,
        D.TextButton {
            Size = UDim2.fromOffset(120, 40),
            Text = "+ 카운터",
            Activated = function()
                const nextRows = table.clone(props.Rows:Get())
                table.insert(nextRows, { Id = `c{#nextRows}`, Label = "새 카운터", Start = 0 })
                props.Rows:Set(nextRows)
            end,
        },
    }
end
