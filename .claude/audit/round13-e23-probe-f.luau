--!nocheck
-- round13 E23 F — GC: replaced inner States / old wrappers collectable; steady memory under swaps
local H = require("./round13-e15-probe-setup")
local q, D, mock = H.q, H.D, H.mock
local KEEP = {}
local weak = setmetatable({}, { __mode = "k" })
local function gc() for _ = 1, 4 do collectgarbage("collect") end end
local function count() gc(); local n = 0 for _ in weak do n += 1 end return n end
local function nsubs(s) gc(); local n = 0 for _ in s._subs do n += 1 end return n end

do -- F1 property: inner replaced by plain; inner collectable
	local which = q.Source(q.Source("x"))
	weak[which:Get()] = true
	local l = D.TextLabel { Text = which }
	which:Set("plain")
	print("F1 old inner alive after swap-to-plain:", count())
	KEEP.keep1 = l
end
do -- F2 many swaps between fresh inners: memory steady?
	local which = q.Source(q.Source("0"))
	local l = D.TextLabel { Text = which }
	gc(); local m0 = collectgarbage("count")
	for i = 1, 20000 do which:Set(q.Source(tostring(i))) end
	gc(); local m1 = collectgarbage("count")
	print(("F2 20000 inner swaps: KB before %.0f after %.0f, which subs %d"):format(m0, m1, nsubs(which)))
	KEEP.keep2 = l
end
do -- F3 same inner re-emitted 20000 times (outer:Emit): observer churn steady?
	local inner = q.Source("i")
	local which = q.Source(inner)
	local l = D.TextLabel { Text = which }
	gc(); local m0 = collectgarbage("count")
	for i = 1, 20000 do which:Emit() end
	gc(); local m1 = collectgarbage("count")
	print(("F3 20000 same-inner re-emits: KB before %.0f after %.0f, inner subs %d"):format(m0, m1, nsubs(inner)))
	KEEP.keep3 = l
end
do -- F4 numeric slot: State<State<Instance>> swaps with fresh frames
	local which = q.Source(q.Source(D.Frame { Name = "0" }))
	local host = D.Frame { which }
	gc(); local m0 = collectgarbage("count")
	for i = 1, 5000 do local f = D.Frame { Name = tostring(i) }; weak[f] = true; which:Set(q.Source(f)) end
	gc(); local m1 = collectgarbage("count")
	print(("F4 5000 child inner swaps: KB before %.0f after %.0f, frames alive %d (1 expected: mounted)"):format(m0, m1, count()))
	KEEP.keep4 = host
end
for k in weak do weak[k] = nil end
do -- F5 host destroyed: outer/inner/observers collectable; subs on long-lived inner drop
	local inner = q.Source("keep")
	local which = q.Source(inner)
	local l = D.TextLabel { Text = which }
	print("F5 before destroy inner subs", nsubs(inner), "which subs", nsubs(which))
	l:Destroy()
	print("F5 after Destroy inner subs", nsubs(inner), "which subs", nsubs(which))
	KEEP.keepInner = inner
end
do -- F6 host unreferenced (never parented) with a long-lived outer: host collectable?
	local inner = q.Source("keep")
	local which = q.Source(inner)
	do local l = D.TextLabel { Text = which }; weak[l] = true end
	print("F6 unreferenced host alive", count(), "inner subs", nsubs(inner), "which subs", nsubs(which))
	KEEP.keepW = which
end
do -- F7 Slot element State<State>: swap inners many times
	for k in weak do weak[k] = nil end
	local which = q.Source(q.Source(D.Frame { Name = "0" }))
	local sl = q.Slot { which }
	local host = D.Frame { sl }
	gc(); local m0 = collectgarbage("count")
	for i = 1, 3000 do local f = D.Frame { Name = tostring(i) }; weak[f] = true; which:Set(q.Source(f)) end
	gc(); local m1 = collectgarbage("count")
	print(("F7 3000 Slot inner swaps: KB before %.0f after %.0f, frames alive %d"):format(m0, m1, count()))
	KEEP.keep7 = host
end
