--!strict
-- E58 strict (generated) — roblox_04-claim-mapper-L221
-- ==== page prologue roblox/04-claim-mapper.md (roblox_04-claim-mapper-L20.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
local M = D.Mapper
-- ==== doc block roblox/04-claim-mapper.md:221 (line offset marker) ====
local MapPart = q.newMapperClass("Part")

local function bindModel(model: Model)
	return q.Claim(model, q.newMapperClass("Model")(q.MapperRoot)({
		MapPart("Body")({ Anchored = true }),
	}))
end
