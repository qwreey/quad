--!nocheck
-- E75 group A: docs/reference/errors/01-core-reactive.md + 09-sugar.md
local H = require("../harness")
local R = require("../runner")
local q = H.q
local O = q.Operator

-- subscribed observer that records every value it sees (initial fire included)
local function watch(state)
	local seen = {}
	local obs = state:Observer(function(s) table.insert(seen, s:Get()) end)
	obs:Subscribe()
	return seen, obs
end

-- ===== Blocker =====
R.case({ id = "Quad0017",
	trigger = function()
		local b = q.Blocker()
		b:Policy(5) -- line: user passes non-function
	end,
	fix = function()
		-- "게이트의 setup이 넘겨준 emit 함수를 그대로 넘기세요"
		local b = q.Blocker()
		local src = q.Source(0)
		local g = src:Gate(function(emit) return b:Policy(emit) end)
		local seen = watch(g)
		b:On(); src:Set(1); src:Set(2)
		local during = #seen
		b:Off()
		return during == 1 and #seen == 2 and seen[2] == 2, ("seen during=%d after=%d last=%s"):format(during, #seen, tostring(seen[#seen]))
	end })

R.case({ id = "Quad0018",
	trigger = function()
		local b = q.Blocker()
		b:__apply(5)
	end,
	fix = function()
		local b = q.Blocker()
		local src = q.Source(0)
		local g = src:Apply(b)
		local seen = watch(g)
		b:On(); src:Set(1); src:Set(2)
		local during = #seen
		b:Off()
		return during == 1 and #seen == 2 and seen[2] == 2, ("during=%d after=%d"):format(during, #seen)
	end })

-- ===== Context =====
R.case({ id = "Quad0035",
	trigger = function() q.Context.Provider(5) end,
	fix = function()
		local p1 = q.Context.Provider("Theme")
		local p2 = q.Context.Provider(nil)
		local ctx = q.Context():Set(p1, "dark"):Set(p2, 1)
		return ctx:Get(p1) == "dark" and ctx:Get(p2) == 1 and tostring(p1) == "Provider(Theme)", tostring(p1) .. "/" .. tostring(p2)
	end })

R.case({ id = "Quad0036",
	trigger = function() q.Context():Set("Theme", "dark") end,
	fix = function()
		local Theme = q.Context.Provider("Theme")
		local ctx = q.Context():Set(Theme, "dark")
		return ctx:Get(Theme) == "dark", "Get=" .. tostring(ctx:Get(Theme))
	end })

R.case({ id = "Quad0037", note = "a: fresh bag, intent = leave unset",
	trigger = function()
		local P = q.Context.Provider("Theme")
		q.Context():Set(P, nil)
	end,
	fix = function()
		local P = q.Context.Provider("Theme")
		local ctx = q.Context() -- :Set not called
		return ctx:Peek(P) == nil, "Peek=" .. tostring(ctx:Peek(P))
	end })

R.case({ id = "Quad0037", note = "b: bag already has a value, intent = clear it",
	trigger = function()
		local P = q.Context.Provider("Theme")
		local ctx = q.Context():Set(P, "dark")
		ctx:Set(P, nil)
	end,
	fix = function()
		local P = q.Context.Provider("Theme")
		local ctx = q.Context():Set(P, "dark")
		-- literal fix: "지우려는 의도라면 :Set을 아예 부르지 마세요" — we simply don't call it
		return ctx:Peek(P) == nil, "after not calling :Set, Peek=" .. tostring(ctx:Peek(P)) .. " (value still there — no removal path on this page)"
	end })

R.case({ id = "Quad0038", note = "a: Set first",
	trigger = function()
		local P = q.Context.Provider("Locale")
		q.Context():Get(P)
	end,
	fix = function()
		local P = q.Context.Provider("Locale")
		local ctx = q.Context():Set(P, "ko")
		return ctx:Get(P) == "ko", "Get=" .. tostring(ctx:Get(P))
	end })
R.case({ id = "Quad0038", note = "b: Peek instead",
	trigger = function()
		local P = q.Context.Provider("Locale")
		q.Context():Get(P)
	end,
	fix = function()
		local P = q.Context.Provider("Locale")
		local ctx = q.Context()
		local v = ctx:Peek(P) or "en"
		return v == "en", "Peek-or-default=" .. v
	end })

-- ===== Debounce / Throttle =====
R.case({ id = "Quad0039",
	trigger = function()
		local t = q.Source("0.1")
		local src = q.Source(0)
		local d = src:Apply(q.Debounce({ Time = t }))
		watch(d)
		src:Set(1)
	end,
	fix = function()
		local t = q.Source(0.1)
		local src = q.Source(0)
		local d = src:Apply(q.Debounce({ Time = t }))
		local seen = watch(d)
		src:Set(1); src:Set(2)
		local mid = #seen
		H.runTask(0.2)
		return mid == 1 and #seen == 2 and seen[2] == 2, ("mid=%d after=%d last=%s"):format(mid, #seen, tostring(seen[#seen]))
	end })

R.case({ id = "Quad0040",
	trigger = function() q.Debounce({}) end,
	fix = function()
		local src = q.Source(0)
		local d = src:Apply(q.Debounce({ Time = 0.1 }))
		local seen = watch(d)
		src:Set(1); H.runTask(0.2)
		return #seen == 2 and seen[2] == 1, "after=" .. #seen
	end })

R.case({ id = "Quad0041",
	trigger = function() q.Throttle({ Time = -1 }) end,
	fix = function()
		local src = q.Source(0)
		local d = src:Apply(q.Throttle({ Time = 0.1 }))
		local seen = watch(d)
		src:Set(1); H.runTask(0.2)
		return #seen >= 2 and seen[#seen] == 1, "after=" .. #seen
	end })

R.case({ id = "Quad0042",
	trigger = function() q.Debounce({ Time = 0.1, Leading = "yes" }) end,
	fix = function()
		local src = q.Source(0)
		local d = src:Apply(q.Debounce({ Time = 0.1, Leading = true }))
		local seen = watch(d)
		src:Set(1)
		return #seen == 2 and seen[2] == 1, "leading passes immediately, seen=" .. #seen
	end })

R.case({ id = "Quad0043",
	trigger = function()
		local f = q.Debounce({ Time = 0.1 })
		f:__apply(5)
	end,
	fix = function()
		local f = q.Debounce({ Time = 0.1 })
		local src = q.Source(0)
		local d = src:Apply(f)
		local seen = watch(d)
		src:Set(1); H.runTask(0.2)
		return #seen == 2, "after=" .. #seen
	end })

R.case({ id = "Quad0044", note = "a: one Ref reused across two :Apply; fix = new Ref",
	trigger = function()
		local ref = q.Ref(nil)
		local f = q.Debounce({ Time = 0.1, Handle = ref })
		q.Source(0):Apply(f)
		q.Source(0):Apply(f)
	end,
	fix = function()
		-- "새 Ref를 만들거나": a shared factory carries ONE Handle in its opts, so a new Ref means a new factory
		local r1, r2 = q.Ref(nil), q.Ref(nil)
		local a, b = q.Source(0), q.Source(0)
		local da = a:Apply(q.Debounce({ Time = 0.1, Handle = r1 }))
		local db = b:Apply(q.Debounce({ Time = 0.1, Handle = r2 }))
		local sa, sb = watch(da), watch(db)
		a:Set(1); b:Set(1)
		r1.Value:Flush()
		return #sa == 2 and #sb == 1 and r1.Value ~= r2.Value, ("a=%d b=%d"):format(#sa, #sb)
	end })
R.case({ id = "Quad0044", note = "b: drop Handle, broadcast Flush",
	trigger = function()
		local ref = q.Ref(nil)
		local f = q.Debounce({ Time = 0.1, Handle = ref })
		q.Source(0):Apply(f)
		q.Source(0):Apply(f)
	end,
	fix = function()
		local f = q.Debounce({ Time = 0.1 })
		local a, b = q.Source(0), q.Source(0)
		local sa, sb = watch(a:Apply(f)), watch(b:Apply(f))
		a:Set(1); b:Set(1)
		f:Flush()
		return #sa == 2 and #sb == 2, ("a=%d b=%d"):format(#sa, #sb)
	end })
R.case({ id = "Quad0044", note = "c: Ref with non-nil default",
	trigger = function()
		local ref = q.Ref(false)
		q.Source(0):Apply(q.Debounce({ Time = 0.1, Handle = ref }))
	end,
	fix = function()
		local ref = q.Ref(nil)
		local src = q.Source(0)
		local seen = watch(src:Apply(q.Debounce({ Time = 0.1, Handle = ref })))
		src:Set(1); ref.Value:Flush()
		return #seen == 2, "seen=" .. #seen
	end })

R.case({ id = "Quad0045",
	trigger = function() q.Debounce(0.1) end,
	fix = function()
		local src = q.Source(0)
		local seen = watch(src:Apply(q.Debounce({ Time = 0.1 })))
		src:Set(1); H.runTask(0.2)
		return #seen == 2, "seen=" .. #seen
	end })

R.case({ id = "Quad0046",
	trigger = function() q.Throttle({ Time = 0.1, MaxTime = 1 }) end,
	fix = function()
		local src = q.Source(0)
		local seen = watch(src:Apply(q.Throttle({ Time = 0.1 })))
		src:Set(1); H.runTask(0.2)
		return #seen >= 2, "seen=" .. #seen
	end })

R.case({ id = "Quad0047",
	trigger = function() q.Debounce({ Time = 0.1, Handle = {} }) end,
	fix = function()
		local ref = q.Ref(nil) -- q.Ref<<QuadTypes.GateHandle?>>(nil) at runtime
		local src = q.Source(0)
		local seen = watch(src:Apply(q.Debounce({ Time = 0.1, Handle = ref })))
		src:Set(1); ref.Value:Flush()
		return #seen == 2, "seen=" .. #seen
	end })

R.case({ id = "Quad0048", note = "a: Debounce Trailing=false only; fix Leading=true",
	trigger = function() q.Debounce({ Time = 0.1, Trailing = false }) end,
	fix = function()
		local src = q.Source(0)
		local seen = watch(src:Apply(q.Debounce({ Time = 0.1, Trailing = false, Leading = true })))
		src:Set(1); src:Set(2); H.runTask(0.2)
		return #seen == 2 and seen[2] == 1, ("seen=%d last=%s"):format(#seen, tostring(seen[#seen]))
	end })
R.case({ id = "Quad0048", note = "b: Throttle both false; fix = leave defaults",
	trigger = function() q.Throttle({ Time = 0.1, Leading = false, Trailing = false }) end,
	fix = function()
		local src = q.Source(0)
		local seen = watch(src:Apply(q.Throttle({ Time = 0.1 })))
		src:Set(1); H.runTask(0.2)
		return #seen >= 2, "seen=" .. #seen
	end })

-- ===== Operator =====
R.case({ id = "Quad0118",
	trigger = function() q.Source(1):Apply(O.Sum(1, nil)) end,
	fix = function()
		local s = q.Source(1):Apply(O.Sum(1, 2))
		return s:Get() == 4, "Get=" .. tostring(s:Get())
	end })

R.case({ id = "Quad0119",
	trigger = function() q.Source(1):Apply(O.Sum("2")) end,
	fix = function()
		local s = q.Source(1):Apply(O.Sum(2))
		return s:Get() == 3, "Get=" .. tostring(s:Get())
	end })

R.case({ id = "Quad0120", note = "a: store:Of fresh; fix default value",
	trigger = function()
		local store = q.Store({})
		q.Source(1):Apply(O.Sum(store:Of("tax"))):Get()
	end,
	fix = function()
		local store = q.Store({ tax = q.Source(0) })
		local s = q.Source(1):Apply(O.Sum(store:Of("tax")))
		store.tax:Set(2)
		return s:Get() == 3, "Get=" .. tostring(s:Get())
	end })
R.case({ id = "Quad0120", note = "b: fix via Operator.Alternative",
	trigger = function()
		local store = q.Store({})
		q.Source(1):Apply(O.Sum(store:Of("tax"))):Get()
	end,
	fix = function()
		local store = q.Store({})
		local tax = store:Of("tax"):Apply(O.Alternative(0))
		local s = q.Source(1):Apply(O.Sum(tax))
		local v1 = s:Get()
		store:Of("tax"):Set(5)
		return v1 == 1 and s:Get() == 6, ("v1=%s v2=%s"):format(tostring(v1), tostring(s:Get()))
	end })

R.case({ id = "Quad0121",
	trigger = function() q.Source(1):Apply(O.Sum(q.Source("2"))):Get() end,
	fix = function()
		local s = q.Source(1):Apply(O.Sum(q.Source(2)))
		return s:Get() == 3, "Get=" .. tostring(s:Get())
	end })

R.case({ id = "Quad0122",
	trigger = function() q.Source("1"):Apply(O.Sum(1)):Get() end,
	fix = function()
		local s = q.Source(1):Apply(O.Sum(1))
		return s:Get() == 2, "Get=" .. tostring(s:Get())
	end })

R.case({ id = "Quad0123", note = "a: direct call Operator.Not(5)",
	trigger = function() O.Not(5) end,
	fix = function()
		local s = q.Source(true):Apply(O.Not)
		return s:Get() == false, "Get=" .. tostring(s:Get())
	end })
R.case({ id = "Quad0123", note = "b: tag:Apply(Operator.Not) — blame check",
	trigger = function() q.Tag("A"):Apply(O.Not) end,
	fixnote = "same prescription as a (state:Apply only); intent of negating a Tag has no State equivalent — n/a",
})
R.case({ id = "Quad0123", note = "c: modifier:Apply(Operator.Bnot) — blame check",
	trigger = function() q.Modifier():Apply(O.Bnot) end,
	fixnote = "n/a (see b)",
})

R.case({ id = "Quad0124", note = "a: transient crossing recovers next generation",
	trigger = function()
		local lo, hi = q.Source(0), q.Source(10)
		local s = q.Source(5):Apply(O.Clamp(lo, hi))
		s:Get()
		lo:Set(20) -- hi not yet moved
		s:Get()
	end,
	fix = function()
		local lo, hi = q.Source(0), q.Source(10)
		local s = q.Source(5):Apply(O.Clamp(lo, hi))
		s:Get()
		lo:Set(20)
		pcall(function() s:Get() end) -- the transient read throws
		hi:Set(30) -- "다음 세대에 돌아오면 회복"
		local ok, v = pcall(function() return s:Get() end)
		return ok and v == 20, "after hi moves: ok=" .. tostring(ok) .. " v=" .. tostring(v)
	end })
R.case({ id = "Quad0124", note = "b: constant lo>hi; fix = fix relation",
	trigger = function() q.Source(5):Apply(O.Clamp(10, 0)):Get() end,
	fix = function()
		local s = q.Source(5):Apply(O.Clamp(0, 3))
		return s:Get() == 3, "Get=" .. tostring(s:Get())
	end })

R.case({ id = "Quad0125",
	trigger = function() O.Indexed(nil) end,
	fix = function()
		local s = q.Source({ hp = 3 }):Apply(O.Indexed("hp"))
		return s:Get() == 3, "Get=" .. tostring(s:Get())
	end })

R.case({ id = "Quad0126",
	trigger = function() O.Indexed(q.Source("hp")) end,
	fix = function()
		local s = q.Source({ hp = 3 }):Apply(O.Indexed("hp"))
		return s:Get() == 3, "Get=" .. tostring(s:Get()) .. " (a reactive key needs :Compute — page does not say)"
	end })

R.case({ id = "Quad0127",
	trigger = function() q.Source(5):Apply(O.Indexed("hp")):Get() end,
	fix = function()
		local s = q.Source({ hp = 5 }):Apply(O.Indexed("hp"))
		return s:Get() == 5, "Get=" .. tostring(s:Get())
	end })

R.case({ id = "Quad0128",
	trigger = function() O.Alternative(nil) end,
	fix = function()
		local s = q.Source(nil):Apply(O.Alternative(0))
		return s:Get() == 0, "Get=" .. tostring(s:Get())
	end })

R.case({ id = "Quad0129",
	trigger = function()
		local store = q.Store({})
		q.Source(nil):Apply(O.Alternative(store:Of("d"))):Get()
	end,
	fix = function()
		local store = q.Store({ d = q.Source(7) })
		local s = q.Source(nil):Apply(O.Alternative(store:Of("d")))
		return s:Get() == 7, "Get=" .. tostring(s:Get())
	end })

-- ===== Source =====
R.case({ id = "Quad0181",
	trigger = function() q.Source(0):Set(q.Modifier()) end,
	fix = function()
		local s = q.Source(0); s:Set(5)
		return s:Get() == 5, "Get=" .. tostring(s:Get())
	end })
R.case({ id = "Quad0182",
	trigger = function() q.Source(q.Modifier()) end,
	fix = function()
		local s = q.Source(5)
		return s:Get() == 5, "Get=" .. tostring(s:Get())
	end })

-- ===== State =====
R.case({ id = "Quad0183",
	trigger = function() q.Source(1):Compute(function(a, _, b) return a:Get() + b:Get() end, 2) end,
	fix = function()
		local s = q.Source(1):Compute(function(a, _, b) return a:Get() + b:Get() end, q.Source(2))
		return s:Get() == 3, "Get=" .. tostring(s:Get())
	end })
R.case({ id = "Quad0183", note = "b: Depend with non-State",
	trigger = function() q.Source(1):Depend({}) end,
	fix = function()
		local other = q.Source(0)
		local s = q.Source(1):Depend(other)
		local seen = watch(s)
		other:Set(1)
		return s:Get() == 1 and #seen == 2, "Get=" .. tostring(s:Get()) .. " seen=" .. #seen
	end })

R.case({ id = "Quad0184", note = "a: self-read cycle (intent: accumulate over previous value)",
	trigger = function()
		local src = q.Source(1)
		local total
		total = src:Compute(function(s)
			return (total:Get() or 0) + s:Get()
		end)
		total:Get()
	end,
	fix = function()
		-- "자기 자신을 순환 참조하지 않게": the accumulation intent is served by `previous`
		-- (2nd arg; the page's fix does not name it)
		local src = q.Source(1)
		local total = src:Compute(function(s, prev) return (prev or 0) + s:Get() end)
		local a = total:Get(); src:Set(2)
		local b = total:Get()
		return a == 1 and b == 3, ("a=%s b=%s"):format(tostring(a), tostring(b))
	end })
R.case({ id = "Quad0184", note = "b: yield inside fn, another coroutine reads",
	trigger = function()
		local src = q.Source(1)
		local s = src:Compute(function(h) coroutine.yield(); return h:Get() end)
		local co = coroutine.create(function() return s:Get() end)
		coroutine.resume(co)
		s:Get()
	end,
	fix = function()
		local src = q.Source(1)
		local s = src:Compute(function(h) return h:Get() end)
		local co = coroutine.create(function() return s:Get() end)
		local ok, v = coroutine.resume(co)
		return ok and v == 1 and s:Get() == 1, "v=" .. tostring(v)
	end })
R.case({ id = "Quad0184", note = "c: earlier read threw; same generation re-read",
	trigger = function()
		local src = q.Source(0)
		local s = src:Compute(function(h)
			local v = h:Get()
			if v == 0 then error("bad value") end
			return 10 / v
		end)
		pcall(function() s:Get() end)
		s:Get()
	end,
	fix = function()
		local src = q.Source(0)
		local s = src:Compute(function(h)
			local v = h:Get()
			if v == 0 then error("bad value") end
			return 10 / v
		end)
		pcall(function() s:Get() end)
		src:Set(2) -- "상류 값을 고쳐 :Set하면 회복"
		return s:Get() == 5, "Get=" .. tostring(s:Get())
	end })

R.case({ id = "Quad0185", note = "a: Compute returns Modifier",
	trigger = function() q.Source(1):Compute(function() return q.Modifier() end):Get() end,
	fix = function()
		local s = q.Source(1):Compute(function(h) return h:Get() * 2 end)
		return s:Get() == 2, "Get=" .. tostring(s:Get())
	end })
R.case({ id = "Quad0185", note = "b: Alternative(modifier default)",
	trigger = function() q.Source(nil):Apply(O.Alternative(q.Modifier())):Get() end,
	fix = function()
		local s = q.Source(nil):Apply(O.Alternative(0))
		return s:Get() == 0, "Get=" .. tostring(s:Get())
	end })

R.case({ id = "Quad0186",
	trigger = function()
		local maybe = nil
		q.Source(1):Compute(function(a) return a:Get() end, maybe, q.Source(2))
	end,
	fix = function()
		local s = q.Source(1):Compute(function(a, _, b) return a:Get() + b:Get() end, q.Source(2))
		return s:Get() == 3, "Get=" .. tostring(s:Get())
	end })

R.case({ id = "Quad0187",
	trigger = function() q.Source(1):Compute(5) end,
	fix = function()
		local s = q.Source(1):Compute(function(h) return h:Get() + 1 end)
		return s:Get() == 2, "Get=" .. tostring(s:Get())
	end })

R.case({ id = "Quad0188",
	trigger = function() q.Source(1):Gate(5) end,
	fix = function()
		local src = q.Source(1)
		local g = src:Gate(function(emit) return function() emit() end end)
		local seen = watch(g)
		src:Set(2)
		return #seen == 2 and seen[2] == 2, "seen=" .. #seen
	end })

R.case({ id = "Quad0189",
	trigger = function() q.Source(1):Gate(function(emit) end) end,
	fix = function()
		local src = q.Source(1)
		local g = src:Gate(function(emit) return function() emit() end end)
		local seen = watch(g)
		src:Set(2)
		return #seen == 2, "seen=" .. #seen
	end })

R.case({ id = "Quad0190",
	trigger = function() q.Source(1):Observer(5) end,
	fix = function()
		local src = q.Source(1)
		local n = 0
		local o = src:Observer(function() n += 1 end):Subscribe()
		src:Set(2)
		local o2 = src:Observer(nil):Subscribe()
		return n == 2 and o2 ~= nil, "calls=" .. n
	end })

R.case({ id = "Quad0191",
	trigger = function() q.Source(1):Apply(5) end,
	fix = function()
		local s = q.Source(1):Apply(function(self) return self:Compute(function(h) return h:Get() * 10 end) end)
		local b = q.Source(1):Apply(q.Blocker())
		return s:Get() == 10 and b:Get() == 1, "Get=" .. tostring(s:Get())
	end })

R.case({ id = "Quad0192", note = "unreachable via public API (E28): only caller Source.luau Init runs State Init first",
	fixnote = "page says (문서 미정)" })

-- ===== Store =====
R.case({ id = "Quad0193", note = "a: ctor empty key",
	trigger = function() q.Store({ [""] = q.Source(1) }) end,
	fix = function()
		local s = q.Store({ hp = q.Source(1) })
		return s.hp:Get() == 1, "hp=" .. tostring(s.hp:Get())
	end })
R.case({ id = "Quad0193", note = "b: :Of non-string",
	trigger = function() q.Store({}):Of(5) end,
	fix = function()
		local st = q.Store({})
		local src = st:Of("slot5")
		src:Set(1)
		return st.slot5:Get() == 1, "slot5=" .. tostring(st.slot5:Get())
	end })

R.case({ id = "Quad0194", note = "a: Of('Names')",
	trigger = function() q.Store({}):Of("Names") end,
	fix = function()
		local st = q.Store({})
		st:Of("PlayerNames"):Set({ "a" })
		return #st:Names() == 1, "Names=" .. #st:Names()
	end })
R.case({ id = "Quad0194", note = "b: ctor '__x'",
	trigger = function() q.Store({ __x = q.Source(1) }) end,
	fix = function()
		local st = q.Store({ x = q.Source(1) })
		return st.x:Get() == 1, "ok"
	end })

R.case({ id = "Quad0195",
	trigger = function() q.Store(5) end,
	fix = function()
		local a = q.Store({ hp = q.Source(1) })
		local b = q.Store()
		return a.hp:Get() == 1 and #b:Names() == 0, "ok"
	end })

R.case({ id = "Quad0196",
	trigger = function() q.Store(q.Source(1)) end,
	fix = function()
		local src = q.Source(1)
		local st = q.Store({ hp = src })
		return st.hp == src, "ok"
	end })

R.case({ id = "Quad0197",
	trigger = function() q.Store(q.AttrKey("Hp")) end,
	fix = function()
		local st = q.Store({ Hp = q.Source(1) })
		return st.Hp:Get() == 1, "ok"
	end })

R.case({ id = "Quad0198",
	trigger = function() q.Store({ hp = 1 }) end,
	fix = function()
		local st = q.Store({ hp = q.Source(1) })
		return st.hp:Get() == 1, "ok"
	end })

-- ===== 09-sugar: Fallback/Traceback =====
local function Comp(props) error("boom") end
R.case({ id = "Quad0099",
	trigger = function() q.Fallback(nil, function() return "fallback" end) end,
	fix = function()
		local safe = q.Fallback(Comp, function() return "fallback" end)
		local tb = q.Traceback(Comp, function(err) return "tb" end)
		return safe({}) == "fallback" and tb({}) == "tb", "ok"
	end })
R.case({ id = "Quad0100",
	trigger = function() q.Traceback(Comp, "fallback") end,
	fix = function()
		local safe = q.Traceback(Comp, function(err) return "fallback" end)
		return safe({}) == "fallback", "ok"
	end })

-- ===== extra probes (A-notes) =====
R.case({ id = "Quad0044", note = "d: literal 'new Ref' while KEEPING the shared factory — only route is mutating the opts table the factory aliases",
	trigger = function()
		local f = q.Debounce({ Time = 0.1, Handle = q.Ref(nil) })
		q.Source(0):Apply(f); q.Source(0):Apply(f)
	end,
	fix = function()
		local opts = { Time = 0.1, Handle = q.Ref(nil) }
		local f = q.Debounce(opts)
		local r1 = opts.Handle
		q.Source(0):Apply(f)
		local r2 = q.Ref(nil)
		opts.Handle = r2 -- not a documented route; works only because the factory keeps `opts` by reference
		q.Source(0):Apply(f)
		return r2.Value ~= nil and r1.Value ~= r2.Value, "opts-alias route filled r2=" .. tostring(r2.Value ~= nil)
	end })
R.case({ id = "Quad0124", note = "e: after a 0124 throw, same-generation re-read reports which id?",
	trigger = function()
		local lo, hi = q.Source(0), q.Source(10)
		local s = q.Source(5):Apply(O.Clamp(lo, hi))
		s:Get(); lo:Set(20)
		pcall(function() s:Get() end)
		s:Get() -- second read, nothing moved
	end,
	fixnote = "probe only — trigger line shows which id the re-read raises" })

R.done()
