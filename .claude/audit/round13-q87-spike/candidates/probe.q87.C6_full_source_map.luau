--!strict
-- Q87 spike (2026-09-26): candidate C6_full_source_map
local Quad = require("../luau_packages/quad_base")
local R = require("../src")
local QuadRoblox = R.QuadRoblox
local DM = require("../src/Declaration")
local QuadTypes = require("../luau_packages/quad_types")
local U = require("./probe.q87types")
local q = Quad.New():UseProvider(QuadRoblox)
type Source<T> = QuadTypes.Source<T>
type State<T> = QuadTypes.State<T>
type P = DM.PropTypesRead
type PU = U.PropTypesReadU
type Desc<K> = DM.OnChangeDescriptor<K>
type Conflict = "CanvasSize" | "Color" | "Offset" | "Padding" | "Style" | "Transparency"
local _u: PU? = nil
type Cand = <K>(name: K & keyof<U.OutSrcU>, src: index<U.OutSrcU, K>) -> Desc<K>
local out: Cand = nil :: any


local function _cases()
	local D = q.Declaration
	local _p1 = out("Text", q.Source("")) -- #P1 Text Source<string>
	local _p2 = out("Visible", q.Source(true)) -- #P2 Visible Source<boolean>
	local _p3 = out("CanvasSize", q.Source(UDim2.new())) -- #P3 CanvasSize Source<UDim2>
	local _p4 = out("Color", q.Source(Color3.new())) -- #P4 Color Source<Color3>
	local _p5 = out("Transparency", q.Source(0)) -- #P5 Transparency Source<number>
	local sU: Source<UDim2> = q.Source(UDim2.new())
	local _p6 = out("CanvasSize", sU) -- #P6 CanvasSize annotated Source<UDim2> variable
	local _c1 = D.TextBox({ Text = "a", out("Text", q.Source("")) }) -- #C1 D ctx Text
	local _c3 = D.ScrollingFrame({ out("CanvasSize", q.Source(UDim2.new())) }) -- #C3 D ctx CanvasSize
	local _c4 = D.UIStroke({ out("Color", q.Source(Color3.new())) }) -- #C4 D ctx Color
	local _c5 = D.UIStroke({ out("Transparency", q.Source(0)) }) -- #C5 D ctx Transparency
	local _n1 = out("Text", q.Source(1)) -- #N1 NEG Text Source<number>
	local computed = (nil :: any) :: State<string>
	local _n2 = out("Text", computed) -- #N2 NEG Text read-only State<string>
	local _n3 = out("Nope", q.Source(1)) -- #N3 NEG unknown name
	local _n4 = out("Size", q.Source(Vector2.new())) -- #N4 NEG Size Source<Vector2>
	local roU = (nil :: any) :: State<UDim2>
	local _n5 = out("CanvasSize", roU) -- #N5 NEG(extra) CanvasSize read-only State<UDim2>
	local _n6 = out("CanvasSize", q.Source("x")) -- #N6 NEG(extra) CanvasSize Source<string> (no class has string)
	local _n7 = out("Color", q.Source(1)) -- #N7 NEG(extra) Color Source<number>
end
