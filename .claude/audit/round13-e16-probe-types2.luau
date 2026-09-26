--!strict
-- round13 E16 type probe 2: isolated State<PreRef|PostRef> at numeric key (runtime always Quad0136). Same command as round13-e16-probe-types.luau.
local q = require("./round13-e16-probe-types-settings")
local D = q.Declaration
local pre = q.PreRef<<Frame?>>(nil)
local st = q.Source(pre)
local _a = D.Frame { st }
local _b = D.Frame { q.Source(q.PostRef<<Frame?>>(nil)) }
local _c: number = st -- control: must error (proves the file is checked)
return nil
