local theme = q.Source({ Primary = "red", Size = 10 })
local primary: q.State<string> = theme:Apply(q.Operator.Indexed<<string>>("Primary"))
-- theme:Set({ Primary = "blue", Size = 12 }) → primary:Get() == "blue"
