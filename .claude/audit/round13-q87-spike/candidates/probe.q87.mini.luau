--!strict
local QuadTypes = require("../luau_packages/quad_types")
type Source<T> = QuadTypes.Source<T>
type P = { A: any, B: number }
type function Id(t) return t end
local function _(sU: Source<UDim2>, sN: Source<number>)
	local f1: (x: Source<index<P, "A">>) -> () = nil :: any
	f1(sU) -- M1 non-generic, index reduces to any at annotation time
	local f2: (x: Source<Id<any>>) -> () = nil :: any
	f2(sU) -- M2 non-generic type-function-produced any
	local g1: <K>(k: K & keyof<P>, x: Source<index<P, K>>) -> () = nil :: any
	g1("A", sU) -- M3 generic, index<P,K> -> any after K solved
	g1("B", sN) -- M4 generic, index<P,K> -> number
	local g2: <K>(k: K, x: Source<any>) -> () = nil :: any
	g2("A", sU) -- M5 generic, plain Source<any>
	local g3: <K>(k: K & keyof<P>, x: Source<Id<any>>) -> () = nil :: any
	g3("A", sU) -- M6 generic fn, K-independent type function -> any
	local g4: <K>(k: K & keyof<P>, x: Source<Id<K>>) -> () = nil :: any
	local sA: Source<"A"> = nil :: any
	g4("A", sA) -- M7 generic, K-dependent tf, reduces to singleton (not any)
	local g5: <K>(k: K & keyof<P>, x: index<{ A: Source<any>, B: Source<number> }, K>) -> () = nil :: any
	g5("A", sU) -- M8 generic, Source<any> produced whole by index (tf outside Source)
end
