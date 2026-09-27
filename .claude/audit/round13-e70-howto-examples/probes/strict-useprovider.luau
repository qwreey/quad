--!strict
-- E70 strict probe: how-to 06 §3 `Quad.New():UseProvider(myProvider)` — myProvider 타입별로 q.Source가 읽히는가
local Quad = require("../../../../quad-roblox/luau_packages/quad_base")
local QuadRoblox = require("../../../../quad-roblox/src").QuadRoblox
local function pEmpty(_q: any) return {} end
local function pIndexer(_q: any): { [any]: any } return {} end        -- quad-base/test/mock.luau mockProvider와 같은 반환 주석
local function pRecord(_q: any): { Foo: number } return { Foo = 1 } end
local pAny: any = nil
local _1 = Quad.New():UseProvider(pEmpty).Source(1)   -- V1 {}
local _2 = Quad.New():UseProvider(pIndexer).Source(1) -- V2 { [any]: any }
local _3 = Quad.New():UseProvider(pRecord).Source(1)  -- V3 { Foo: number }
local _4 = Quad.New():UseProvider(pAny).Source(1)     -- V4 any
local _5 = Quad.New():UseProvider(QuadRoblox).Source(1) -- V5 실제 quad_roblox
