--!strict
--[[
	Lifecycle hook sugar — `OnCreated` / `OnRendered` / `OnDestroyed`.
	`.claude/base/lifecycle-hooks-plan.md` "핵심 논지" sketch, transcribed as-is:

	  OnCreated(fn)   -> PreRef():Callback(guard(fn))    -- before anything happens to the inst
	  OnRendered(fn)  -> PostRef():Callback(guard(fn))   -- after its own subtree/props/events;
	                                                     -- NOT "attached to a parent" (plan ①)
	  OnDestroyed(fn) -> Effect(function() return function(dying) if dying then fn() end end end)
	                                                     -- fn runs once, at the leaf's death only

	These are plain factories: the value that lands in the children array is
	the PreRef/PostRef/Effect itself — no new brand, no dispatch concept,
	multiple registrations are just multiple array slots (relative order among
	the same kind = array index order, the Ref pre-pass contract).

	`guard` (`H-120`, mandatory): a Ref callback fires once at registration with
	the current value, so a default-less PreRef would call `fn(nil)` before the
	pre-pass — the guard drops the nil call and forwards BOTH arguments
	(`fn(value, ref)`, `H-107` — a 1-arg wrapper would swallow the Epoch).
	`OnDestroyed`'s wrapper only returns a cleanup at install (no side effect); `fn`
	itself runs when the bound instance dies (`effect-plan.md` deps-less contract).
	round10 Q57 (2026-09-17): the cleanup keys on Effect's `dying` argument — leaving a
	`State` seat alive (`st:Set(q.None)`) or `Unsubscribe` consumes the cleanup with
	`dying = false` and fn does NOT run; re-seating re-installs it; death runs it once.
]]

local QuadTypes = require("../luau_packages/quad_types")
local Err = require("./ErrorNamespace")

local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

local function checkFn(name: string, fn: any)
	if type(fn) ~= "function" then
		Err.errorBeforeNearest(`Quad0101 {name}: fn must be a function (got {typeof(fn)})`, SURFACE)
	end
end

local function guard(fn: any): (any, any) -> ()
	return function(v: any, r: any)
		if v ~= nil then
			fn(v, r)
		end
	end
end

-- Per-instance (`H-174` idiom): PreRef/PostRef are instance-shared leaves but
-- `Effect` is per module instance, so all three read the module at call time.
local function Init(module: any)
	local function OnCreated(fn: any): any
		checkFn("OnCreated", fn)
		return module.PreRef(nil):Callback(guard(fn))
	end
	local function OnRendered(fn: any): any
		checkFn("OnRendered", fn)
		return module.PostRef(nil):Callback(guard(fn))
	end
	local function OnDestroyed(fn: any): any
		checkFn("OnDestroyed", fn)
		return module.Effect(function()
			return function(dying: boolean)
				if dying then
					fn()
				end
			end
		end)
	end
	module.OnCreated = OnCreated
	module.OnRendered = OnRendered
	module.OnDestroyed = OnDestroyed
	Err.setFuncLevel(SURFACE, OnCreated, OnRendered, OnDestroyed) -- `H-231`
end

return { Init = Init }
