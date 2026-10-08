--!strict
--[[
	Navigation destinations: the one item model the kit's navigation components share — the navigation drawer's
	`NavigationDrawerItems` now, and the navigation bar / rail when they come (they take the same `{ Key, Label, Icon,
	Badge }` items and the same selection rule). Selection follows `Tabs`: ONE `Selected: Source<K>` for the whole set, a
	click does `Selected:SetIfChanged(key)`, then `OnChange(key)` when that changed the selection (the kit-wide meaning of
	OnChange: user-originated changes only), then `OnClick(key)` on every click (also on the selected one).

	    export type Destination<K> = { Key: K, Label: string | State<string>, Icon: string?, Badge: (string | State<string>)? }
	    Destination.isSelected(selected, key) -> State<boolean>
	    Destination.click(selected, key, onChange, onClick)        the click rule above

	`Icon` is an icon prop (Icons.resolve: an `Icons` name, an asset URL, or a glyph). `Badge` is the drawer item's trailing
	badge text (Compose NavigationDrawerItem `badge`); a bar / rail badge is a separate shape there.
]]

local q = require("../Quad")

export type Destination<K> = {
	read Key: K,
	read Label: string | q.State<string>,
	read Icon: (string | q.State<string>)?,
	read Badge: (string | q.State<string>)?,
}

local function isSelected<K>(selected: q.State<K>, key: K): q.State<boolean>
	return selected:Compute(function(self)
		return self:Get() == key
	end)
end

local function click<K>(selected: q.Source<K>, key: K, onChange: ((key: K) -> ())?, onClick: ((key: K) -> ())?)
	local changed = selected:Get() ~= key
	selected:SetIfChanged(key)
	if changed and onChange then
		onChange(key)
	end
	if onClick then
		onClick(key)
	end
end

return {
	isSelected = isSelected,
	click = click,
}
