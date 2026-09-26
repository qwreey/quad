--!strict
-- round13 E23 type probe: State<State<T>> / State<None> placement. Run (test.sh line-79 flags):
-- mise exec -- luau-lsp analyze --flag:LuauSolverV2=true --flag:LuauTarjanChildLimit=160000 --flag:LuauSubtypingIterationLimit=100000 --flag:LuauTypeInferIterationLimit=1000000 --definitions=scripts/roblox-defs/globalTypes.d.luau --ignore "**/luau_packages/**" .claude/audit/round13-e23-probe-types.luau
local q = require("./round13-e16-probe-types-settings")
local D = q.Declaration

local a: q.Source<string> = q.Source("A")
local which: q.Source<q.Source<string>> = q.Source(a)
local _t1 = D.TextLabel { Text = which } -- T1 State<State<string>> at string property (GS 20 shape, annotated)
local which2 = q.Source(a)
local _t1b = D.TextLabel { Text = which2 } -- T1b GS 20 verbatim (unannotated)
local _t2 = D.TextLabel { Text = q.Source(q.None) } -- T2 State<None> at string property
local _t3 = D.TextLabel { Text = q.Source<<string?>>(nil) } -- T3 State<string?> at string property
local frame = D.Frame {}
local _t4 = D.Frame { q.Source(q.Source(frame)) } -- T4 State<State<Frame>> at numeric key
local _t5 = q.Slot { q.Source(q.Source(frame)) } -- T5 State<State<Frame>> as Slot element
local _t6 = D.Frame { q.Attr({ Hp = q.Source(q.Source(1)) }) } -- T6 group value (known untyped)
local _t7 = D.Frame { [q.AttrKey("K")] = q.Source(q.Source(1)) } -- T7 AttrKey hash key (known 8.17)
local _t8 = q.Modifier({ Text = q.Source(q.Source("x")) }) -- T8 Modifier field
local _t8b = D.Modifier.TextLabel({ Text = q.Source(q.Source("x")) }) -- T8b typed modifier field
local _t9 = D.Frame { q.Source(q.None) } -- T9 State<None> at numeric key
local _t10 = q.Source(q.Modifier({})) -- T10 Source(Modifier) (runtime Quad0182)
local st = q.Store({ y = q.Source(q.Source("n")) })
local _t11 = D.TextLabel { Text = st.y } -- T11 store field holding State<State>
local flag = q.Source(true)
local sw: q.State<q.Source<string>> = flag:Compute(function(f) return if f:Get() then a else q.Source("B") end)
local _t12 = D.TextLabel { Text = sw } -- T12 Compute returning a State
local _t13 = D.TextLabel { Text = q.Source(q.Source(5)) } -- T13 State<State<number>> at string property (should be rejected: number into Text)
local _t14 = D.Frame { Size = q.Source(q.Source("wrong")) } -- T14 State<State<string>> at UDim2 property (should be rejected)
local _t15 = D.Frame { q.Source(q.Source(q.Tag("t"))) } -- T15 State<State<Tag>> numeric
local _t16 = D.Frame { q.Source(q.Source(q.Slot {})) } -- T16 State<State<Slot>> numeric
local _t17 = D.Frame { q.Source(q.Source(q.Ref<<Frame?>>(nil))) } -- T17 State<State<Ref>> numeric
local selfish = q.Source(0 :: any)
selfish:Set(selfish) -- T18 self-holding (runtime Quad0070) via any
local _t19 = D.TextLabel { Text = q.Source(q.Source(q.None)) } -- T19 State<State<None>> string key
return nil
