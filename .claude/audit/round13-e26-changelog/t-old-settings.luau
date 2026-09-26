--!strict
-- E26: 3.2.0-era settings module line (EffectHandle re-export) — expect error at HEAD
local QuadTypes = require("../../../quad-roblox/luau_packages/quad_types")
export type EffectHandle = QuadTypes.EffectHandle -- E: old name
export type Effect = QuadTypes.Effect -- OK: migrated
return nil
