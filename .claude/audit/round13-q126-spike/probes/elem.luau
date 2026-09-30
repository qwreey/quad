--!strict
-- Q126 spike — numeric-key State arms outside NewChild (OnChange descriptor / Ref marker) — out of the requested scope, measured for the report
local q = require("./config")
local QT = require("../quad-types/src")
local D = q.Declaration
type None = QT.None

local d = q.OnChange("Text", function(_v: string) end)
local _e1 = D.TextBox { q.Source(d) } -- P1 control: State<descriptor>
local _e2 = D.TextBox { q.Source(d :: typeof(d)?) } -- P2 State<descriptor?> (runtime: nil disconnects)
local r = q.Ref(nil :: TextBox?)
local _e3 = D.TextBox { q.Source(r) } -- P3 control: State<Ref>
local _e4 = D.TextBox { q.Source(r :: typeof(r)?) } -- P4 State<Ref?> (runtime: nil empties)
local _e5 = D.TextBox { q.Source(nil :: Instance?) } -- P5 NewChild arm (already nil-capable)
