local MapPart = q.newMapperClass("Part")

local function bindModel(model: Model)
	return q.Claim(model, q.newMapperClass("Model")(q.MapperRoot)({
		MapPart("Body")({ Anchored = true }),
	}))
end
