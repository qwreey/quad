--!strict
-- E70 strict (generated) — overview_01-why-quad-L116
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (DEFAULT) ====
-- [E70 기본 프롤로그 — GS 01 설정 모듈 관용구]
local q = require("./Quad")
local D = q.Declaration
--[[E70 보강 pre]]
local count = q.Source(3)
-- ==== doc block overview/01-why-quad.md:116 ====
local suffix = q.Source("회")

local both = count:Compute(function(c, previous, s)
    return `{c:Get()}{s:Get()}`
end, suffix)                      -- ← suffix를 적어야 suffix가 움직일 때도 다시 흐른다
