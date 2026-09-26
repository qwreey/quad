--!nocheck
-- round13 E20 probe D3 — dead (thrown) strong Effect / Observer: Unsubscribe releases upstream? (built inside a function to avoid dead-register artifacts)
local mock = require("../../quad-base/test/mock")
local q = mock.newQuad()
local function gc() for _ = 1, 4 do collectgarbage("collect") end end
local tracked = setmetatable({}, { __mode = "k" })
local function alive(tag) gc(); local n = 0 for _, t in tracked do if t == tag then n += 1 end end return n end
local function build(kind)
	local src = q.Source(0); tracked[src] = kind .. "s"
	local h
	if kind == "E" then
		h = q.Effect(function() if src:Get() == 1 then error("x") end end, src):Subscribe()
	else
		h = src:Observer(function(t) if t:Get() == 1 then error("x") end end):Subscribe()
	end
	tracked[h] = kind .. "h"
	local ok = pcall(src.Set, src, 1)
	return h, ok
end
for _, kind in { "E", "O" } do
	local h, ok = build(kind)
	print(kind, "Set threw:", not ok, "src alive:", alive(kind .. "s"), "handle running:", h._running)
	h:Unsubscribe()
	h = nil
	print(kind, "after Unsubscribe+drop: src alive", alive(kind .. "s"), "handle alive", alive(kind .. "h"))
end
