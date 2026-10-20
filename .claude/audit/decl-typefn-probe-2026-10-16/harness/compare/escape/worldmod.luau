--!strict
-- [2026-10-20 module form of usermap.luau] escape probe] User-supplied class map: one escape returns the curried surface bound to the user's own small map.
local F = require("../../../src/FullMapsKeep")
type Surface<M> = {
	Elem: <K>(name: K & keyof<M>) -> (F.FProps<index<M, K>>) -> index<M, K>,
	Modifier: <K>(name: K & keyof<M>) -> (...any) -> F.FModifierAs0<index<M, K>>,
	Spread: <K>(name: K & keyof<M>) -> (F.FProps<index<M, K>>) -> F.FSpread<index<M, K>>,
}
local With = (nil :: any) :: <M>() -> Surface<M>
type World = { Part: Part, Beam: Beam, MeshPart: MeshPart, VehicleSeat: VehicleSeat, Tool: Tool, BasePart: BasePart }
return With<<World>>()
