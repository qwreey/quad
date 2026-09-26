--!nocheck
local G = require("./gclib")
local H = require("./harness")
local q, D = H.q, H.D
local mock = require("../../../quad-base/test/mock")
local M = q.Declaration.Mapper
local function tmpl()
	local root = mock.Instance.foreign("Frame")
	local title = mock.Instance.foreign("TextLabel"); title.Name = "Title"; title.Parent = root
	local list = mock.Instance.foreign("Frame"); list.Name = "List"; list.Parent = root
	return root, title, list
end
local up = q.Source("t")
G.measure("i1 Claim(template) with reactive props, root:Destroy()", function(N, track)
	for i = 1, N do
		local root, title, list = tmpl()
		local s = q.Slot { D.Frame {} }
		q.Claim(root, M.Frame(M.Root)({
			M.TextLabel("Title")({ Text = up:Compute(function(x) return x:Get() .. i end), up:Observer(function() end) }),
			M.Frame("List")({ s }),
			BackgroundTransparency = 0.5,
		}))
		track(root, "root"); track(title, "title"); track(list, "list"); track(s, "slot"); track(s:Get(1), "elem")
		root:Destroy()
	end
	up:Set("u" .. math.random())
end)
G.measure("i2 Claim then q.dispose(root)", function(N, track)
	for i = 1, N do
		local root, title = tmpl()
		q.Claim(root, M.Frame(M.Root)({ M.TextLabel("Title")({ Text = up }) }))
		track(root, "root"); track(title, "title")
		q.dispose(root)
	end
end)
G.measure("i3 foreign tree never claimed, dropped (control)", function(N, track)
	for i = 1, N do local root, title = tmpl(); track(root, "root"); track(title, "title") end
end)
G.measure("i4 Claim failing mid-way (bad mapping), root dropped w/o Destroy", function(N, track)
	for i = 1, N do
		local root, title = tmpl()
		pcall(function() q.Claim(root, M.Frame(M.Root)({ M.TextLabel("Nope")({ Text = "x" }) })) end)
		track(root, "root"); track(title, "title")
	end
end)
G.measure("i5 Claim throwing in pass 2 (prop Compute throws), root dropped w/o Destroy", function(N, track)
	for i = 1, N do
		local root, title = tmpl()
		local ok, err = pcall(function() q.Claim(root, M.Frame(M.Root)({ M.TextLabel("Title")({ Text = up:Compute(function() error("x") end) }) })) end)
		if i == 1 then print("  i5 err:", ok, tostring(err):sub(1, 90)) end
		track(root, "root"); track(title, "title")
	end
end)
G.measure("i6 same as i5 but root:Destroy() after the throw", function(N, track)
	for i = 1, N do
		local root, title = tmpl()
		pcall(function() q.Claim(root, M.Frame(M.Root)({ M.TextLabel("Title")({ Text = up:Compute(function() error("x") end) }) })) end)
		track(root, "root"); track(title, "title"); root:Destroy()
	end
end)
