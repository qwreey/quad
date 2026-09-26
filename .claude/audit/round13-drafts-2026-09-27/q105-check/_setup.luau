--!strict
-- 공유 설치 헬퍼(round13-s6b-compute-hole/_setup.luau과 동일, 경로만 한 단계 더 깊음).
-- 이 폴더는 round13 Q105 배치 프로브 스크래치이며 레포 소스가 아니다.
local Quad = require("../../../../quad-roblox/luau_packages/quad_base")
local QuadRoblox = require("../../../../quad-roblox/src").QuadRoblox
local QuadTypes = require("../../../../quad-roblox/luau_packages/quad_types")

local q = Quad.New():UseProvider(QuadRoblox)

return {
	q = q,
	QuadTypes = QuadTypes,
}
