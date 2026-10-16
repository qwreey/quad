--!strict
local Ext = require("./Ext")
local QT = require("../../../../../../quad-types/src")
local q = (nil :: any) :: Ext.Q
local qb = (nil :: any) :: QT.Quad
local baseM = q.Modifier()
local plainM = qb.Modifier()
local n1: number = baseM -- error message reveals the merged type
local n2: number = plainM -- control: base-only q
local okM: QT.Modifier = baseM
local typed = q.Modifier "Frame"
local n3: number = typed
return { baseM, plainM, n1, n2, okM, typed, n3 }
