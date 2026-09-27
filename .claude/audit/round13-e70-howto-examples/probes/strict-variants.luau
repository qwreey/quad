--!strict
-- E70 strict probe: (1) qn05:92 myInstanceState 모양별, (2) how-to 06 §3 myProvider 모양별, (3) how-to 10:205 TextLabel 대체
local q = require("../strict/Quad")
local D = q.Declaration
local Quad = require("../../../../quad-roblox/luau_packages/quad_base")
-- (1)
local s1 = q.Source<<Instance?>>(nil)
local s2 = q.Source<<Instance>>(D.Frame {})
local s3: q.State<Instance> = q.Source(D.Frame {} :: Instance)
local _a = D.Frame { q.Slot<<Instance>> { s1 } }   -- V1 Instance?
local _b = D.Frame { q.Slot<<Instance>> { s2 } }   -- V2 Instance
local _c = D.Frame { q.Slot<<Instance>> { s3 } }   -- V3 State<Instance>
-- (2)
local p1: any = nil
local p2 = function(_quad: any): { [any]: any } return {} end
local qa = Quad.New():UseProvider(p1)
local qb = Quad.New():UseProvider(p2)
local _x = qa.Source(1)                              -- V4 myProvider: any
local _y = qb.Source(1)                              -- V5 myProvider: 함수 타입
local _z = Quad.New().Source(1)                      -- V6 UseProvider 없이
-- (3)
local items = q.Source({ "a", "b" })
local s = q.Slot()
s:List(items, function(ctx) return D.TextLabel { Text = ctx.Item } end) -- V7
