--!nocheck
-- round13 E17 B3 — which error a user sees for the "claim again" cases how-to 07 §2/§3 and how-to 10 함정 4 quote as Quad0225
local H = require("./round13-e17-probe-setup")
local q, D, try = H.q, H.D, H.try
local M = D.Mapper
local t = H.foreign({ "Frame", children = { { "Frame", name = "ContentArea" } } })
q.Claim(t, M.Frame(M.Root)({ M.Frame("ContentArea")({}) }))
try("D-made instance", function() q.Claim(D.Frame {}, M.Frame(M.Root)({})) end)
try("same root twice", function() q.Claim(t, M.Frame(M.Root)({})) end)
try("mapped child claimed again separately (how-to 07 §4 warning)", function() q.Claim(t:FindFirstChild("ContentArea"), M.Frame(M.Root)({})) end)
local dead = D.Frame {}; dead:Destroy()
try("destroyed D-made instance, before GC", function() q.Claim(dead, M.Frame(M.Root)({})) end)
