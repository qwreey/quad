--!strict
--[[
	Selection — the multi-selection rules of an explorer-style list, as pure functions over keys (any value: an
	Instance, an id). Ported from devplorer (the user's project, `Rows/Select`) — 2026-10-21 user decision with the
	candidate list; names by a three-model review (audit/naming-devui-2026-10-21d/).

		Selection.apply(current: { key }, anchor: key?, order: { key }, index: number, mode: Mode) -> (next, anchor)
			order: the keys of the rows shown now, in order; index: the clicked row's place in `order`.
			"Replace": the clicked key alone, and it becomes the anchor (a plain click).
			"Toggle":  add or remove the clicked key; the anchor moves to it (Ctrl / Cmd + click).
			"Extend":  every key from the anchor to the clicked row, in shown order; the anchor stays (Shift + click).
			           With no anchor, or one not shown now, it acts as "Replace".
		Selection.prune(current, keep: (key) -> boolean) -> (next, changed)
			drops the keys `keep` rejects (a destroyed Instance); unchanged, it returns the same table.
		Selection.toSet(list) -> { [key]: true }
		Selection.modeFromKeys(service: UserInputService?) -> Mode
			the mode the modifier keys held now ask for: Shift -> "Extend", Ctrl or Cmd -> "Toggle", else "Replace"
			(`service` defaults to `Devui.Input.service()`).

	The caller keeps `current` and `anchor` (a Source, a field) and writes back what `apply` returns.
]]

local Input = require("./Input")

local Selection = {}

export type Mode = "Replace" | "Toggle" | "Extend"

function Selection.toSet(list: { any }): { [any]: boolean }
	local set: { [any]: boolean } = {}
	for _, key in list do
		set[key] = true
	end
	return set
end

function Selection.apply(current: { any }, anchor: any?, order: { any }, index: number, mode: Mode): ({ any }, any?)
	local clicked = order[index]
	if clicked == nil then
		return current, anchor
	end
	if mode == "Toggle" then
		local out: { any } = {}
		local found = false
		for _, key in current do
			if key == clicked then
				found = true
			else
				table.insert(out, key)
			end
		end
		if not found then
			table.insert(out, clicked)
		end
		return out, clicked
	elseif mode == "Extend" and anchor ~= nil then
		local anchorIndex = table.find(order, anchor)
		if anchorIndex then
			local out: { any } = {}
			for i = math.min(anchorIndex, index), math.max(anchorIndex, index) do
				table.insert(out, order[i])
			end
			return out, anchor
		end
	end
	return { clicked }, clicked
end

function Selection.prune(current: { any }, keep: (any) -> boolean): ({ any }, boolean)
	local out: { any } = {}
	for _, key in current do
		if keep(key) then
			table.insert(out, key)
		end
	end
	if #out == #current then
		return current, false
	end
	return out, true
end

function Selection.modeFromKeys(service: UserInputService?): Mode
	local s: any = service or Input.service()
	local function down(a: Enum.KeyCode, b: Enum.KeyCode): boolean
		return s:IsKeyDown(a) or s:IsKeyDown(b)
	end
	if down(Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift) then
		return "Extend"
	elseif down(Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl) or down(Enum.KeyCode.LeftSuper, Enum.KeyCode.RightSuper) then
		return "Toggle"
	end
	return "Replace"
end

return Selection
