import sys, subprocess, re, time, os
# Q87 spike driver (2026-09-26). Re-run: copy candidates/probe.q87types.luau into quad-roblox/test/, ./scripts/relink.sh, then python3 <this> [cand...] from repo root (writes quad-roblox/test/probe.q87.<cand>.luau — delete afterwards). run_copy.sh/summarize.py drove the patched scratch copies (outfn-*.diff).
ROOT="/code/Projects/quad"
HEAD='''--!strict
-- Q87 spike (2026-09-26): candidate {name}
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
'''
CASES='''
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
'''
def cand(name, body):
    return HEAD.format(name=name) + body + "\n" + CASES
C = {}
C["base_qOut"] = "local out = q.Out -- current q.Out through the extension merge\n"
C["base_OutFn"] = "local out: R.OutFn = nil :: any\n"
C["A_typefn_anyunion"] = '''type function AnyIfAny(t)
	if t.tag == "any" then return types.any end
	return types.never
end
type Cand = <K>(name: K & keyof<P>, src: Source<index<P, K>> | AnyIfAny<index<P, K>>) -> Desc<K>
local out: Cand = nil :: any
'''
C["A2_typefn_overload_SourceAny"] = '''type function AnyKeys(tbl)
	local ks = {}
	for k, v in tbl:properties() do
		if v.read and v.read.tag == "any" then table.insert(ks, k) end
	end
	return types.unionof(table.unpack(ks))
end
type Cand = (<K>(name: K & keyof<P>, src: Source<index<P, K>>) -> Desc<K>) & (<K>(name: K & AnyKeys<P>, src: Source<any>) -> Desc<K>)
local out: Cand = nil :: any
'''
C["B_literal_overload_SourceAny"] = '''type Cand = (<K>(name: K & keyof<P>, src: Source<index<P, K>>) -> Desc<K>) & (<K>(name: K & Conflict, src: Source<any>) -> Desc<K>)
local out: Cand = nil :: any
'''
C["B2_literal_overload_first"] = '''type Cand = (<K>(name: K & Conflict, src: Source<any>) -> Desc<K>) & (<K>(name: K & keyof<P>, src: Source<index<P, K>>) -> Desc<K>)
local out: Cand = nil :: any
'''
C["B3_literal_nongeneric_SourceAny"] = '''type Cand = (<K>(name: K & keyof<P>, src: Source<index<P, K>>) -> Desc<K>) & ((name: Conflict, src: Source<any>) -> Desc<Conflict>)
local out: Cand = nil :: any
'''
C["B4_literal_overload_anysrc"] = '''type Cand = (<K>(name: K & keyof<P>, src: Source<index<P, K>>) -> Desc<K>) & (<K>(name: K & Conflict, src: any) -> Desc<K>)
local out: Cand = nil :: any
'''
C["C_union_map"] = '''type Cand = <K>(name: K & keyof<PU>, src: Source<index<PU, K>>) -> Desc<K>
local out: Cand = nil :: any
local function _onchangeUnion()
	local oc: <K>(name: K & keyof<PU>, fn: (index<PU, K>) -> ()) -> Desc<K> = nil :: any
	local _x1 = oc("Color", function(v: Color3) end) -- #X1 OnChange on union map, Color3 callback
	local _x2 = oc("Text", function(v: string) end) -- #X2 OnChange on union map, Text
end
'''
C["C2_union_of_sources_overload"] = '''type ConflictSrc = {
	CanvasSize: Source<UDim2> | Source<Vector2>,
	Color: Source<Color3> | Source<ColorSequence>,
	Offset: Source<Vector2> | Source<UDim2>,
	Padding: Source<UDim> | Source<UDim2>,
	Style: Source<Enum.FrameStyle> | Source<Enum.ButtonStyle>,
	Transparency: Source<number> | Source<NumberSequence>,
}
type Cand = (<K>(name: K & keyof<P>, src: Source<index<P, K>>) -> Desc<K>) & (<K>(name: K & keyof<ConflictSrc>, src: index<ConflictSrc, K>) -> Desc<K>)
local out: Cand = nil :: any
'''
C["C3_unionmap_plus_conflictsrc"] = '''type Cand = <K>(name: K & keyof<PU>, src: index<U.ConflictSrc & { [string]: never }, K> | Source<index<PU, K>>) -> Desc<K>
local out: Cand = nil :: any
'''
C["C4_anymap_plus_conflictsrc"] = '''type Cand = <K>(name: K & keyof<P>, src: index<U.ConflictSrc & { [string]: never }, K> | Source<index<P, K>>) -> Desc<K>
local out: Cand = nil :: any
'''
C["C6_full_source_map"] = '''type Cand = <K>(name: K & keyof<U.OutSrcU>, src: index<U.OutSrcU, K>) -> Desc<K>
local out: Cand = nil :: any
'''
C["D_marker_readSet_overload"] = '''type Cand = (<K>(name: K & keyof<P>, src: Source<index<P, K>>) -> Desc<K>) & (<K>(name: K & Conflict, src: QuadTypes.StateMarker<any> & { read Set: (self: any, v: any) -> any }) -> Desc<K>)
local out: Cand = nil :: any
'''
C["D2_marker_readSet_onetable_overload"] = '''type Cand = (<K>(name: K & keyof<P>, src: Source<index<P, K>>) -> Desc<K>) & (<K>(name: K & Conflict, src: { read __quadState: true, read Set: (self: any, v: any) -> any }) -> Desc<K>)
local out: Cand = nil :: any
'''
C["E_free_T_nonconflict_check"] = '''type function Pick(want, got)
	-- any in the map -> accept whatever T was inferred; otherwise demand the map type
	if want.tag == "any" then return got end
	return want
end
type Cand = <K, T>(name: K & keyof<P>, src: Source<T> & Source<Pick<index<P, K>, T>>) -> Desc<K>
local out: Cand = nil :: any
'''
C["E2_generic_T_pick"] = '''type function Pick(want, got)
	if want.tag == "any" then return got end
	return want
end
type Cand = <K, T>(name: K & keyof<P>, src: Source<Pick<index<P, K>, T>>) -> Desc<K>
local out: Cand = nil :: any
'''
C["A3_typefn_union_SourceAny"] = '''type function IfAny(t, then_)
	if t.tag == "any" then return then_ end
	return types.never
end
type Cand = <K>(name: K & keyof<P>, src: Source<index<P, K>> | IfAny<index<P, K>, Source<any>>) -> Desc<K>
local out: Cand = nil :: any
'''
C["A4_typefn_select"] = '''type function Sel(t, whenAny, otherwise)
	if t.tag == "any" then return whenAny end
	return otherwise
end
type Cand = <K>(name: K & keyof<P>, src: Sel<index<P, K>, Source<any>, Source<index<P, K>>>) -> Desc<K>
local out: Cand = nil :: any
'''
C["A5_typefn_union_marker_readSet"] = '''type function IfAny(t, then_)
	if t.tag == "any" then return then_ end
	return types.never
end
type Cand = <K>(name: K & keyof<P>, src: Source<index<P, K>> | IfAny<index<P, K>, QuadTypes.StateMarker<any> & { read Set: (self: any, v: any) -> any }>) -> Desc<K>
local out: Cand = nil :: any
'''
C["C4b_anymap_conflictsrc_noindexer"] = '''type Cand = <K>(name: K & keyof<P>, src: index<U.ConflictSrc, K> | Source<index<P, K>>) -> Desc<K>
local out: Cand = nil :: any
'''
FLAGS=["--flag:LuauSolverV2=true","--flag:LuauTarjanChildLimit=160000","--flag:LuauSubtypingIterationLimit=100000","--flag:LuauTypeInferIterationLimit=1000000","--definitions=scripts/roblox-defs/globalTypes.d.luau","--ignore","**/luau_packages/**"]
only = sys.argv[1:]
for name, body in C.items():
    if only and name not in only: continue
    fn = f"quad-roblox/test/probe.q87.{name}.luau"
    src = cand(name, body)
    open(os.path.join(ROOT, fn), "w").write(src)
    lines = src.split("\n")
    t=time.time()
    r = subprocess.run(["mise","exec","--","luau-lsp","analyze",*FLAGS,fn], cwd=ROOT, capture_output=True, text=True)
    dt=time.time()-t
    out = r.stdout + r.stderr
    open(f"/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/q87/{name}.out","w").write(out)
    tagline={}
    for i,l in enumerate(lines):
        mm=re.search(r"#(\w+)",l)
        if mm: tagline[mm.group(1)]=i+1
    open(f"/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/q87/{name}.lines","w").write(repr(tagline))
    diags = [l for l in out.split("\n") if l.startswith(fn) or "probe.q87" in l and "(" in l]
    per = {}
    other=[]
    for d in diags:
        m = re.search(r"probe\.q87\.[^(]*\((\d+),(\d+)\)[^:]*: (.*)", d)
        if not m: other.append(d); continue
        ln = int(m.group(1)); tag = re.search(r"#(\w+)", lines[ln-1])
        key = tag.group(1) if tag else f"L{ln}"
        per.setdefault(key, []).append(m.group(3))
    print(f"##### {name}  ({dt:.2f}s, diags {len(diags)})")
    for k in sorted(per, key=lambda s:(s[0], s)):
        print(f"  {k}: {len(per[k])} | {per[k][0][:230]}")
    for o in other[:5]: print("  ?", o[:200])
