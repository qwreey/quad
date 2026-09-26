--!strict
-- 공유 설치 헬퍼 — quad-roblox/test/spec.*.luau의 관용구를 빌림(설치 자체는 매 require마다
-- Quad.New()로 새 인스턴스를 만들어 다른 프로브 파일과 격리한다). 이 폴더는 round13 S6 프로브용
-- 스크래치이며 레포 소스가 아니다.
local Quad = require("../../../quad-roblox/luau_packages/quad_base")
local QuadRoblox = require("../../../quad-roblox/src").QuadRoblox
local QuadTypes = require("../../../quad-roblox/luau_packages/quad_types")

local q = Quad.New():UseProvider(QuadRoblox)

return {
	q = q,
	QuadTypes = QuadTypes,
}
