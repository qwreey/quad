--!nocheck
-- round13 E15 S5 — cross-part CRUD during teardown: a card's OnDestroyed / Effect cleanup(dying) pushes a toast into a
-- module-scope toast Slot:List whose host is inside the SAME screen being destroyed. Both sibling orders.
local H = require("./round13-e15-probe-setup")
local q, D, mock, try, track, alive = H.q, H.D, H.mock, H.try, H.track, H.alive

local function scenario(toastFirst, hook)
	local toasts = q.Source({})
	local nextId = 0
	local made = {}
	local toastList = q.Slot():List(toasts, function(ctx)
		if ctx.Item == q.KeyGone then return nil, ctx.UserData end
		if ctx.Prev then return ctx.Prev, ctx.UserData end
		local l = D.TextLabel { Name = "toast" .. ctx.Item.Id, Text = ctx.Item.Text }
		table.insert(made, l)
		track("S5.toast", l)
		return l, ctx.UserData
	end, function(it) return it.Id end)
	local function push(text)
		nextId += 1
		local nxt = table.clone(toasts:Get())
		table.insert(nxt, { Id = nextId, Text = text })
		toasts:Set(nxt)
	end
	local function Card(name)
		return D.Frame { Name = name,
			(if hook == "OnDestroyed" then q.OnDestroyed(function() push(name .. " removed") end)
				else q.Effect(function() return function(dying) if dying then push(name .. " removed") end end end)),
		}
	end
	local toastHost = D.Frame { Name = "Toasts", toastList }
	local cards = D.Frame { Name = "Cards", Card("c1"), Card("c2") }
	local screen = if toastFirst then D.ScreenGui { toastHost, cards } else D.ScreenGui { cards, toastHost }
	local ok, err = pcall(function() screen:Destroy() end)
	local orphans, undestroyed = 0, 0
	for _, l in made do
		if not mock.isDestroyed(l) then undestroyed += 1 end
		if l.Parent ~= nil and mock.isDestroyed(l.Parent) and not mock.isDestroyed(l) then orphans += 1 end
	end
	print(("toastFirst=%s hook=%s destroy=%s made=%d undestroyed=%d parentedToDeadHost=%d toastData=%d"):format(
		tostring(toastFirst), hook, ok and "OK" or ("ERR " .. H.first(err)), #made, undestroyed, orphans, #toasts:Get()))
	-- try disposing the slot afterwards (the only recovery the Slot reference names)
	local ok2, err2 = pcall(function() q.dispose(toastList) end)
	print("   dispose(toastList):", ok2 and "OK" or H.first(err2))
end
for _, hook in { "OnDestroyed", "EffectCleanup" } do
	scenario(true, hook)
	scenario(false, hook)
end
print("alive", alive("S5."))
