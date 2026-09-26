--!strict
-- E58 strict (generated) — extend_02-dispatch-handler-contract-L353
-- ==== page prologue extend/02-dispatch-handler-contract.md (extend_02-dispatch-handler-contract-L13.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
-- ==== doc block extend/02-dispatch-handler-contract.md:353 (line offset marker) ====
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
