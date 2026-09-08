--!strict
--[[
	Fallback / Traceback — component error isolation, as pure functions over
	`pcall` / `xpcall`+`debug.traceback`. `.claude/base/fallback-plan.md`
	"메커니즘 스케치", transcribed as-is:

	  Fallback(base, onError)  -> function(...) -- pcall(base, ...); on error onError(err)
	  Traceback(base, onError) -> function(...) -- xpcall; on error onError(err, trace)

	`err` is `any` — Luau `error()` throws arbitrary values and this layer does
	NOT massage them (no string assumption, no prefix stripping; the plan's
	"`err: any`임을 반드시 문서화" caveat). `trace` is always a string for
	Traceback (`debug.traceback(nil, 2)` taken inside the xpcall handler, i.e.
	at the throw site — `audit/fallback-xpcall-verification.md`).

	Known gap (plan "미해결" — backlog, decided at implementation time): a
	partial tree built before the throw is not reclaimed (instances made so far
	hold themselves through gcconn). Nothing here hides that.

	Dependency-free leaf — shared across quad instances like `Ref`.
]]

local QuadTypes = require("../luau_packages/quad_types")
local Err = require("./ErrorNamespace")

local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

local function checkArgs(name: string, base: any, onError: any)
	if type(base) ~= "function" then
		Err.errorBeforeNearest(`{name}: base must be a function (got {typeof(base)})`, SURFACE)
	end
	if type(onError) ~= "function" then
		Err.errorBeforeNearest(`{name}: onError must be a function (got {typeof(onError)})`, SURFACE)
	end
end

local function Fallback(base: any, onError: any): any
	checkArgs("Fallback", base, onError)
	return function(...: any): any
		local ok, resultOrErr = pcall(base, ...)
		if ok then
			return resultOrErr
		end
		return onError(resultOrErr)
	end
end

local function Traceback(base: any, onError: any): any
	checkArgs("Traceback", base, onError)
	return function(...: any): any
		local trace: string? = nil
		local ok, resultOrErr = xpcall(base, function(err: any): any
			trace = debug.traceback(nil, 2)
			return err
		end, ...)
		if ok then
			return resultOrErr
		end
		return onError(resultOrErr, trace :: string)
	end
end

Err.setFuncLevel(SURFACE, Fallback, Traceback) -- `H-231`

return { Fallback = Fallback, Traceback = Traceback }
