--!strict
--[[
	Slot/Owner.luau — the elementOwner ownership ops (claimOwner / claimOwnerAt /
	releaseOwner): who holds a given element, and the "already mounted" raises.

	Installed by `Slot/init.luau` with `(S, module)` (see its header for the split
	and the `S` protocol). Behaviour and comments are the moved originals.
]]

return function(S: any, module: any)
	local elementOwner = S.elementOwner
	local OWNER, OWNER_POS = S.OWNER, S.OWNER_POS
	local ZOMBIE_NOTE = S.ZOMBIE_NOTE
	local Err = S.Err
	local SURFACE = S.SURFACE

	local function claimOwner(element: any, ownerKey: any, fromDetached: boolean?)
		local cur = elementOwner:GetWeak(element, OWNER)
		if cur ~= nil then
			if not (fromDetached and cur == ownerKey) then
				Err.errorBefore("Slot: this element is already mounted — multiple mounts are not allowed" .. ZOMBIE_NOTE, SURFACE)
			end
			return
		end
		elementOwner:SetWeak(element, OWNER, ownerKey)
	end

	local function claimOwnerAt(element: any, inst: any, k: any): boolean
		local current = elementOwner:GetWeak(element, OWNER)
		if current == inst and elementOwner:GetWeak(element, OWNER_POS) == k then
			return false -- exactly this position already holds it — re-confirm, no-op
		end
		if current ~= nil then
			Err.errorBefore("Slot: this element is already mounted elsewhere — multiple mounts are not allowed" .. ZOMBIE_NOTE, SURFACE)
		end
		elementOwner:SetWeak(element, OWNER, inst)
		elementOwner:SetWeak(element, OWNER_POS, k)
		return true
	end

	local function releaseOwner(element: any, ownerKey: any)
		local current = elementOwner:GetWeak(element, OWNER)
		if current ~= ownerKey then
			error("releaseOwner: this element is not owned by this ownerKey — ownership tracking is broken", 1)
		end
		elementOwner:SetWeak(element, OWNER, nil)
		elementOwner:SetWeak(element, OWNER_POS, nil)
	end

	S.claimOwner = claimOwner
	S.claimOwnerAt = claimOwnerAt
	S.releaseOwner = releaseOwner
end
