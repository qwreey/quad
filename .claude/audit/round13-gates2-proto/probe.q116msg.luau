--!nocheck
local H = require("./probe-setup")
local q, D = H.q, H.D
local function m(f) local ok, e = pcall(f); print(ok and "OK" or (tostring(e):gsub("\n.*", ""):gsub("^.-/p%-gates2/", ""))) end
m(function() q.Animate({ CanAnimate = "no" }) end)
m(function() q.Animate({ CanAnimate = function() return false end }) end)
m(function() q.Animate({ CanAnimate = q.None }) end)
m(function() D.Frame({ BackgroundTransparency = q.Source(0):Apply(q.Animate({ CanAnimate = q.Source("no") })) }) end)
m(function() q.Animate({ Started = q.Source(function() end) }) end)
