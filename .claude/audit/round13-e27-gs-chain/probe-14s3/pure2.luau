--!nonstrict
return function(props)
    local nextRows = table.clone(props.Rows:Get())
    props.Rows:Set(nextRows)
end
