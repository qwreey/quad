--!strict
--[[
	Slot/Owner.luau — the elementOwner ownership ops (claimOwner / claimOwnerAt /
	releaseOwner): who holds a given element, and the "already mounted" raises.

	Installed by `Slot/init.luau` with `(S, module)` (see its header for the split
	and the `S` protocol). Behaviour and comments are the moved originals.

	[2026-09-17 round10 Q48 (a) — user decision] ONE registry for every mount site.
	`claimOwnerAt`/`releaseOwner` are published on `module.Bookkeeping` so quad-roblox's
	static-child and shorthand-managed-child handlers register their `(inst, k)` seats in
	the same `elementOwner` the Slot paths use — a value can be held by exactly one seat
	(Slot element, top-level Slot mount, static child, managed child) and `dispose`
	refuses it while held. Before, only the Slot paths were inside the single-mount
	invariant and a static child could be silently double-mounted (round10 §4). The
	messages below are prefixed `Bookkeeping.<op>:` because they now raise from any of
	those seats, not from Slot alone.
]]

local Types = require("./types")

return function(S: Types.SlotInternal, module: any)

	local function claimOwner(element: any, ownerKey: any, fromDetached: boolean?)
		local cur = S.elementOwner:GetWeak(element, S.OWNER)
		if cur ~= nil then
			if not (fromDetached and cur == ownerKey) then
				S.Err.errorBefore("Slot: this element is already mounted — multiple mounts are not allowed" .. S.ZOMBIE_NOTE, S.SURFACE)
			end
			return
		end
		S.elementOwner:SetWeak(element, S.OWNER, ownerKey)
	end

	local function claimOwnerAt(element: any, inst: any, k: any): boolean
		local current = S.elementOwner:GetWeak(element, S.OWNER)
		if current == inst and S.elementOwner:GetWeak(element, S.OWNER_POS) == k then
			return false -- exactly this position already holds it — re-confirm, no-op
		end
		if current ~= nil then
			S.Err.errorBefore("Bookkeeping.claimOwnerAt: this element is already mounted elsewhere — multiple mounts are not allowed" .. S.ZOMBIE_NOTE, S.SURFACE)
		end
		S.elementOwner:SetWeak(element, S.OWNER, inst)
		S.elementOwner:SetWeak(element, S.OWNER_POS, k)
		return true
	end

	local function releaseOwner(element: any, ownerKey: any)
		local current = S.elementOwner:GetWeak(element, S.OWNER)
		if current ~= ownerKey then
			-- public since Q48 (a): a handler author releasing what they never claimed lands here
			-- with the same tracking-broken meaning — nearest blame (their retractor line)
			S.Err.errorBeforeNearest("Bookkeeping.releaseOwner: this element is not owned by this ownerKey — ownership tracking is broken", S.SURFACE)
		end
		S.elementOwner:SetWeak(element, S.OWNER, nil)
		S.elementOwner:SetWeak(element, S.OWNER_POS, nil)
	end

	S.claimOwner = claimOwner
	S.claimOwnerAt = claimOwnerAt
	S.releaseOwner = releaseOwner
end
