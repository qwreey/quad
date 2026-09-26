local Boldify = function(mod: RobloxModule.TextButtonModifier): RobloxModule.TextButtonModifier
	return mod:TextSize(20)
end
local bold = D.Modifier.TextButton():Text("go"):Apply(Boldify)
