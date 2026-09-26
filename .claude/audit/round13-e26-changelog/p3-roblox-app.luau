--!nocheck
-- E26 p3 — app-facing BREAKING lines that need quad-roblox (E15 harness).
local H = require("../round13-e15-probe-setup")
local q, D, mock, try = H.q, H.D, H.mock, H.try
local M = D.Mapper

print("== static child: two parents / {c,c} / dispose seated")
local c = D.TextLabel {}
try("D.Frame{c} first", function() return D.Frame { c } end)
local ok1, e1 = try("old D.Frame{c} second", function() return D.Frame { c } end)
try("old D.Frame{c2,c2}", function() local c2 = D.TextLabel {} return D.Frame { c2, c2 } end)
try("old q.dispose(seated c)", function() q.dispose(c) end)
try("shorthand managed child dispose", function()
	local f = D.Frame { UICorner = 8 }
	local kid = f:FindFirstChild("_quad_round")
	print("   managed child:", kid)
	if kid then q.dispose(kid) end
end)
try("migrated: seat State, :Set(nil), then elsewhere", function()
	local c3 = D.TextLabel {}
	local seat = q.Source(c3)
	D.Frame { seat }
	seat:Set(nil)
	return D.Frame { c3 }
end)
try("migrated: two Instances", function() return D.Frame { D.TextLabel {} }, D.Frame { D.TextLabel {} } end)

print("== unclaimed static child / State :Set(foreign)")
try("old D.Frame{ foreign }", function() return D.Frame { mock.Instance.foreign("TextLabel") } end)
do
	local old = D.TextLabel { Name = "Old" }
	local seat = q.Source(old)
	local host = D.Frame { seat }
	try("old seat:Set(foreign)", function() seat:Set(mock.Instance.foreign("TextLabel")) end)
	print("   host children after:", #host:GetChildren(), "old.Parent:", old.Parent)
end
try("migrated: Claim(foreign) then place", function()
	local f = mock.Instance.foreign("Frame")
	q.Claim(f, M.Frame(M.Root)({}))
	local s = q.Slot({ f })
	return D.Frame { s }
end)
try("migrated: Claim(foreign TextLabel) then static child", function()
	local f = mock.Instance.foreign("TextLabel")
	q.Claim(f, M.TextLabel(M.Root)({}))
	return D.Frame { f }
end)

print("== updateFn positional -> ctx")
do
	local data = q.Source({ { id = "a", label = "A" }, { id = "b", label = "B" } })
	local list = q.Slot()
	local host = D.Frame { list }
	try("old updateFn(item, index, offset, prev, ud)", function()
		list:List(data, function(item, index, offset, prev, ud)
			if item == q.KeyGone then return nil end
			if prev then return prev end
			return D.TextLabel { Text = item.label, LayoutOrder = index }
		end, function(item) return item.id end)
	end)
	print("   children:", #host:GetChildren())
	for _, ch in host:GetChildren() do print("   text=", ch.Text, "order=", ch.LayoutOrder) end
	try("old updateFn: data:Set (re-run, prev reuse?)", function() data:Set({ { id = "a", label = "A2" }, { id = "b", label = "B" } }) end)
	print("   children:", #host:GetChildren())
	try("old updateFn: key removal", function() data:Set({ { id = "a", label = "A2" } }) end)
	print("   children:", #host:GetChildren())
end
do
	local data = q.Source({ { id = "a", label = "A" }, { id = "b", label = "B" } })
	local list = q.Slot()
	local host = D.Frame { list }
	try("migrated updateFn(ctx)", function()
		list:List(data, function(ctx)
			return D.TextLabel { Text = ctx.Item.label, LayoutOrder = ctx.Index }
		end, function(item) return item.id end)
	end)
	for _, ch in host:GetChildren() do print("   text=", ch.Text, "order=", ch.LayoutOrder) end
end
do
	local cur = q.Source({ id = "x", label = "X" })
	local single = q.Slot()
	D.Frame { single }
	try("old :Single updateFn(item, offset, prev, ud)", function()
		single:Single(cur, function(item, offset, prev, ud)
			return D.TextLabel { Text = item.label }
		end)
	end)
end

print("== Owned -> OwnsElements")
do
	local data = q.Source({ "a" })
	local list = q.Slot()
	D.Frame { list }
	local row
	try("old { Owned = false } (debug off)", function()
		list:List(data, function(ctx) if ctx.Item == q.KeyGone then return nil end row = D.TextLabel { Text = ctx.Item } return row end, nil, { Owned = false })
	end)
	data:Set({})
	print("   old Owned=false: row destroyed? parent=", row and row.Parent, "isDestroyed=", row and mock.isDestroyed(row))
	q.debug = true
	local list2 = q.Slot()
	D.Frame { list2 }
	try("old { Owned = false } (debug on)", function()
		list2:List(q.Source({ "a" }), function(ctx) if ctx.Item == q.KeyGone then return nil end return D.TextLabel { Text = ctx.Item } end, nil, { Owned = false })
	end)
	q.debug = false
end

print("== Effect returning non-function (unlabeled Changed line)")
try("old q.Effect(fn returning connection-like)", function()
	local sig = q.Source(0)
	return D.Frame { q.Effect(function() return { Disconnect = function() end } end, sig) }
end)

print("== Tag nil args (loosening)")
try("q.Tag('a', nil)", function() return q.Tag("a", nil) end)
