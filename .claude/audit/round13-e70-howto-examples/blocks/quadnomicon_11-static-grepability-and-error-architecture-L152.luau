function ns.setFuncLevel(level: number, ...: any)
	if type(level) ~= "number" then
		error(`setFuncLevel: level must be a number (got {typeof(level)}) — the signature is setFuncLevel(level, ...fns)`, 2)
	end
	for i = 1, select("#", ...) do
		local func = select(i, ...)
		if type(func) ~= "function" then
			error(`setFuncLevel: argument #{i + 1} must be a function (got {typeof(func)}) — a renamed or missing method?`, 2)
		end
		funcLevels[func] = level
	end
end
