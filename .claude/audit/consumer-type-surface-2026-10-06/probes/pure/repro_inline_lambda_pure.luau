--!strict
-- F1/A5b/8.13/8.30 root, quad-free: a lambda passed to a call that sits inside a table literal which is itself
-- an argument of another call does not get its parameter typed from the expected function type.
type Fr = { Visible: boolean, Name: string }
local cb: (fn: (value: Fr?) -> ()) -> number = (nil :: any)
local function take(_x: any) end
local _ok = { cb(function(inst) if inst then inst.Visible = true end end) } -- ok: table literal not an argument
take(cb(function(inst) if inst then inst.Visible = true end end)) -- ok: no table in between
take({ cb(function(inst) if inst then inst.Visible = true end end) }) -- FAIL: inst typed from usage as { Visible: boolean }
take({ x = cb(function(inst) if inst then inst.Visible = true end end) }) -- FAIL (named field too)
