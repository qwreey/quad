--!nocheck
-- E26 p2 — app-facing BREAKING lines on quad-base (HEAD mock): old 3.2.0 shape vs migrated shape.
local mock = require("../../../quad-base/test/mock")
local QT = require("../../../quad-base/luau_packages/quad_types")
local q = mock.newQuad()
local function first(e) return (tostring(e):gsub("\n.*", "")) end
local function step(name, fn)
	local ok, r = pcall(fn)
	print(name .. ": " .. (ok and ("OK " .. tostring(r)) or ("ERR " .. first(r))))
end

print("== Compute reentrance")
step("old: self-cycle via downstream", function()
	local src = q.Source(1)
	local a
	local b = src:Compute(function(_, _, v) return (a and a:Get() or 0) + v end, src)
	a = b:Compute(function() return b:Get() + 1 end)
	-- a reads b which (through closure) reads a
	return a:Get()
end)
step("old: retry-after-throw same generation", function()
	local src = q.Source(0)
	local fail = true
	local c = src:Compute(function(_, _, v) if fail then error("boom") end return v end, src)
	pcall(function() return c:Get() end)
	fail = false
	return c:Get()
end)
step("migrated: Set upstream then read", function()
	local src = q.Source(0)
	local fail = true
	local c = src:Compute(function(self) local v = self:Get() if fail then error("boom") end return v end)
	pcall(function() return c:Get() end)
	fail = false
	src:Set(1)
	return c:Get()
end)
step("migrated(same-value Set): src:Set(0) (same value) then read", function()
	local src = q.Source(0)
	local fail = true
	local c = src:Compute(function(self) local v = self:Get() if fail then error("boom") end return v end)
	pcall(function() return c:Get() end)
	fail = false
	src:Set(0)
	return c:Get()
end)

print("== With -> Depend")
step("old s:With(dep)", function() local s, d = q.Source(1), q.Source(2) return s:With(d):Get() end)
step("new s:Depend(dep)", function() local s, d = q.Source(1), q.Source(2) return s:Depend(d):Get() end)

print("== Blocker")
step("old blocker:IsOn()", function() local b = q.Blocker() b:On() return b:IsOn() end)
step("old blocker.IsBlocked (after :On())", function() local b = q.Blocker() b:On() return b.IsBlocked end)
step("new blocker.Blocking (after :On())", function() local b = q.Blocker() b:On() return b.Blocking end)

print("== Tag")
step("old for n in tag:Names()", function() local t = q.Tag("a") for n in t:Names() do end end)
step("new for n in tag", function() local t = q.Tag("a", "b") local out = {} for n in t do table.insert(out, n) end table.sort(out) return table.concat(out, ",") end)
step("pairs(tag) (doc: does not iterate names)", function() local t = q.Tag("a") local out = {} for k in pairs(t) do table.insert(out, tostring(k)) end return table.concat(out, ",") end)

print("== Store __ prefix")
step("old q.Store({ __meta = 1 })", function() return q.Store({ __meta = 1 }) end)
step("old store:Of? (Store with __ via Of)", function() local s = q.Store({ a = 1 }) return s:Of({ __x = 1 }) end)

print("== Brand")
step("old Brand():register", function() local b = QT.Brand() b:register({}) end)
step("new Brand():Register/Is", function() local b = QT.Brand() local x = {} b:Register(x) return b:Is(x) end)

print("== Backend/Bookkeeping app/handler side")
step("old q.Dispatch.setLength", function() q.Dispatch.setLength({}, 1, 1) end)
step("old q.bindLifetime", function() q.bindLifetime(mock.Instance.new("Frame"), q.Effect(function() end)) end)
step("new q.Backend.bindLifetime", function() q.Backend.bindLifetime(mock.Instance.new("Frame"), q.Effect(function() end)) end)
step("old q.nativeInsert = fn (provider write)", function() q.nativeInsert = function() end return rawget(q, "nativeInsert") ~= nil end)

print("== read fields (runtime)")
step("old ref.Value = 5", function() local r = q.Ref() r.Value = 5 return r.Value end)
step("old blocker.Blocking = true (write)", function() local b = q.Blocker() b.Blocking = true return b.Blocking end)
step("old src.Revision write", function() local s = q.Source(1) s.Revision = 99 s:Set(2) return s.Revision end)

print("== Slot unclaimed")
step("old q.Slot({ foreign })", function() return q.Slot({ mock.Instance.foreign("Frame") }) end)
step("old slot:Add(foreign)", function() local s = q.Slot() s:Add(mock.Instance.foreign("Frame")) end)
step("migrated: nativeClaim(foreign) then Add", function() local f = mock.Instance.foreign("Frame") q.Backend.nativeClaim(f) local s = q.Slot() s:Add(f) return "added" end)

print("== static child twice / dispose seated (base drive)")
local c = mock.Instance.new("Frame")
step("drive(p1,{c})", function() q.Dispatch.drive(mock.Instance.new("Frame"), { c }) end)
step("old drive(p2,{c}) second parent", function() q.Dispatch.drive(mock.Instance.new("Frame"), { c }) end)
step("old drive(p,{c2,c2})", function() local c2 = mock.Instance.new("Frame") q.Dispatch.drive(mock.Instance.new("Frame"), { c2, c2 }) end)
step("old q.dispose(seated c)", function() q.dispose(c) end)
step("migrated: State<Instance?> seat, :Set(nil) then place elsewhere", function()
	local c3 = mock.Instance.new("Frame")
	local seat = q.Source(c3)
	q.Dispatch.drive(mock.Instance.new("Frame"), { seat })
	seat:Set(nil)
	q.Dispatch.drive(mock.Instance.new("Frame"), { c3 })
	return "moved"
end)
