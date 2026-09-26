-- 이 확장이 다루는 값
local function LogValue(text: string)
	return table.freeze({ __logValue = text })
end

q.Dispatch.addHandler({
	name = "LogValueHandler",
	keyType = "string", -- 문자 키에서만 경쟁한다
	isHandlable = function(_inst: any, key: any, value: any): boolean
		return type(key) == "string" and type(value) == "table" and (value :: any).__logValue ~= nil
	end,
	priority = q.Dispatch.HANDLER_PRIORITY_NORMAL,
	process = function(_inst: any, key: any, value: any, _index: number)
		print(`mount {key} = {(value :: any).__logValue}`)
		return function(_nextValue: any?, retracting: boolean)
			print(`unmount {key} (retracting = {tostring(retracting)})`)
		end
	end,
})
