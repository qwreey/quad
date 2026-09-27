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
