--!nocheck
-- E31: every q.* / D.* name SKILL.md + references mention, checked for existence on the live module.
local H = require("./harness")
local q = H.q
local names = { "Source", "Store", "Context", "Slot", "Modifier", "Ref", "PreRef", "PostRef", "Tween", "Animate", "Debounce", "Throttle",
	"Operator", "Claim", "OnChange", "Out", "OnCreated", "OnRendered", "OnDestroyed", "Effect", "Tag", "Attr", "StringAttr", "NumberAttr",
	"BooleanAttr", "AttrKey", "None", "Detach", "KeyGone", "dispose", "Fallback", "Traceback", "Declaration", "isTween", "Backend",
	"Bookkeeping", "New", "UseProvider", "D", "With", "EffectHandle" }
local missing = {}
for _, n in names do if q[n] == nil then table.insert(missing, n) end end
print("missing on q:", table.concat(missing, ","))
local D = q.Declaration
print("D.Mapper", D.Mapper ~= nil, "D.Modifier", D.Modifier ~= nil, "D.New", D.New ~= nil, "Mapper.Root", D.Mapper.Root ~= nil)
print("Context.Provider", q.Context.Provider ~= nil, "Modifier.Overridden", q.Modifier.Overridden ~= nil, "TypedFactory", q.Modifier.TypedFactory ~= nil, "DefineSubtype", q.Modifier.DefineSubtype ~= nil)
local Op = q.Operator
local om = {}
for _, n in { "Not", "Sum", "Product", "Min", "Max", "Clamp", "Band", "Bor", "Bxor", "Bnot", "Shl", "Shr", "Alternative", "Indexed" } do if Op[n] == nil then table.insert(om, n) end end
print("missing Operator:", table.concat(om, ","))
local s = q.Source(1)
print("State methods:", s.Compute ~= nil, s.Depend ~= nil, s.Apply ~= nil, s.Observer ~= nil, s.Gate ~= nil, "With:", s.With)
local st = q.Store { A = q.Source(1) }
print("store:Of", st.Of ~= nil)
local sl = q.Slot()
local sm = {}
for _, n in { "Add", "Remove", "Replace", "Splice", "Clear", "List", "Single", "IndexOf", "Extract", "ExtractAll", "Move", "Swap", "Get" } do if sl[n] == nil then table.insert(sm, n) end end
print("missing Slot:", table.concat(sm, ","))
local r = q.Ref(nil)
print("Ref:", r.Unwrap ~= nil, r.Wait ~= nil, r.Set ~= nil)
local t = q.Tag("a"); print("tag:Names", t.Names)
