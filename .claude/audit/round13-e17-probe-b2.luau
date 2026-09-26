--!nocheck
-- round13 E17 B2 — a Slot nested in a host that is torn down by q.dispose (quad's own path) vs inst:Destroy(); reuse options
local H = require("./round13-e17-probe-setup")
local q, D, try = H.q, H.D, H.try
local M = D.Mapper

local function mk(n)
	local listCalls = 0
	local data = q.Source({ "a" })
	local s = q.Slot():List(data, function(ctx)
		listCalls += 1
		if ctx.Item == q.KeyGone then return nil, ctx.UserData end
		if ctx.Prev then return ctx.Prev, ctx.UserData end
		return D.TextLabel { Name = ctx.Item }, nil
	end)
	return s, data, function() return listCalls end
end

for _, how in { "Destroy", "q.dispose", "q.dispose(claimed root)" } do
	print("== host torn down by " .. how .. " ==")
	local s, data, calls = mk()
	local host
	if how == "q.dispose(claimed root)" then
		host = H.foreign({ "Frame", children = { { "Frame", name = "Content" } } })
		q.Claim(host, M.Frame(M.Root)({ M.Frame("Content")({ s }) }))
	else
		host = D.Frame { D.Frame { Name = "Content", s } }
	end
	if how == "Destroy" then host:Destroy() else q.dispose(host) end
	local c0 = calls()
	data:Set({ "a", "b" })
	print("  :List reconciles after teardown?", calls() - c0 > 0)
	try("  slot:Add after teardown", function() s:Add(D.TextLabel {}) end)
	try("  mount same Slot in a new host", function() D.Frame { s } end)
	try("  q.dispose(slot)", function() q.dispose(s) end)
	try("  mount after q.dispose(slot)", function() D.Frame { s } end)
end

print("== State<Slot> seat: unseat before teardown, then reuse ==")
local s, data = mk()
local seat = q.Source(s)
local host = D.Frame { seat }
seat:Set(nil)
host:Destroy()
try("  reuse after Set(nil) + Destroy", function() local h2 = D.Frame { s }; data:Set({ "z" }); print("   kids", #h2:GetChildren()) end)
