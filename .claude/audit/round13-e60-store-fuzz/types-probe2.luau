--!strict
-- E60 (a) second type probe: direct writes (Store.luau:25-26 header "the type surface is the gate").
local q = require("../../../quad-base/src")
local store = q.Store({ hp = q.Source(100) })
store.hp = q.Source(7)          -- B1 replace a declared field with another Source of the same type — silent?
store.zz = q.Source(1)          -- B2 new undeclared field
store.hp = nil                  -- B3 delete a declared field
store.Of = nil                  -- B4 shadow/delete a method
store.__x = q.Source(1)         -- B5 reserved __ write
local e = q.Store()
e.x = q.Source(1)               -- B6 new field on an empty Store
return store, e
