--!strict
-- E70 strict (generated) — quadnomicon_11-static-grepability-and-error-architecture-L19
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (DEFAULT) ====
-- [E70 기본 프롤로그 — GS 01 설정 모듈 관용구]
local q = require("./Quad")
local D = q.Declaration
-- ==== doc block quadnomicon/11-static-grepability-and-error-architecture.md:19 ====
-- 흔한 유혹(quad는 이 길을 가지 않는다)
local function formatError(subject: string, reason: string, got: any): string
	return string.format("%s: %s (got %s)", subject, reason, typeof(got))
end

local function addDep(dep: any)
	if dep == nil then
		error(formatError("State", "dependency must not be nil", dep), 2)
	end
end

addDep(nil) -- State: dependency must not be nil (got nil)
