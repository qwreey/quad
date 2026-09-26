local Impl = {}
Impl.__index = Impl
Impl._moduleIdentity = q.moduleIdentity -- 값마다가 아니라 메타테이블에 한 번

local function assertOwn(value)
	if value._moduleIdentity ~= q.moduleIdentity then
		error("MyPlugin: value belongs to another quad instance", 2)
	end
end
