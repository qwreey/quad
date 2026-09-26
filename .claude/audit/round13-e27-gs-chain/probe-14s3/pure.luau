--!nonstrict
-- E27: quad 없이 같은 모양 — 무주석 props의 메소드 콜 추론
return function(props)
    local nextRows = table.clone(props.Rows:Get())
    table.insert(nextRows, { Id = `c{#nextRows}` })
    props.Rows:Set(nextRows)
end
