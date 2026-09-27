--!nocheck
-- E77: the partial tree left by a Declaration that throws mid-build (sugar/05 34 "알려진 구멍", core/06 609) —
-- does it keep REACTING to module-lived sources after the boundary swallowed the error?
local H = require("./harness")
local q, D, mock = H.q, H.D, H.mock
local pulse, flag = q.Source(0), q.Source(true)
local n = { obs = 0, eff = 0, cl = 0 }
local Card = q.Fallback(function()
	local child = D.Frame({ Name = "orphanChild",
		pulse:Observer(function() n.obs += 1 end),
		q.Effect(function() n.eff += 1; return function() n.cl += 1; if n.cl == 2 then error("boom-from-orphan") end end end, flag),
	})
	-- the parent throws after the child was placed: two Attr groups claim the same name on one instance
	return D.Frame({ child, q.Attr({ A = 1 }), q.Attr({ A = 2 }) })
end, function(err) print("fallback got:", H.first(err)); return D.Frame({ Name = "fallbackUI" }) end)
local ui = Card()
print("returned", ui.Name)
local o0, e0 = n.obs, n.eff
for i = 1, 3 do pulse:Set(i) end
print("orphan Observer fires after swallow:", n.obs - o0, "(3 Sets)")
local ok, err = pcall(function() flag:Set(false) end)
print("flag:Set #1 ok", ok, n.eff - e0, "reruns")
ok, err = pcall(function() flag:Set(true) end)
print("flag:Set #2 (orphan cleanup throws) ok", ok, ok and "" or H.first(err))
