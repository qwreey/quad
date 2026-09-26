--!strict
-- E58: roblox/05:95 State에 담은 OnChange 디스크립터를 숫자 키에 — 어떤 타입 인자로 통과하나
local q = require("../strict/Quad")
local RobloxModule = require("../../../../quad-roblox/src")
local D = q.Declaration
local fn = function(v: boolean) end
-- V1 문서 그대로(비제네릭 재수출)
local s1 = q.Source<<RobloxModule.OnChangeDescriptor>>(q.OnChange("Visible", fn))
local _b1 = D.Frame({ s1 })
-- V2 무주석
local s2 = q.Source(q.OnChange("Visible", fn))
local _b2 = D.Frame({ s2 })
-- V3 FrameElem(루트 재수출)
local s3 = q.Source<<RobloxModule.FrameElem?>>(q.OnChange("Visible", fn))
local _b3 = D.Frame({ s3 })
-- V4 any
local s4 = q.Source<<any>>(q.OnChange("Visible", fn))
local _b4 = D.Frame({ s4 })
