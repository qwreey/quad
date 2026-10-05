--!strict
--[[
	KeyedSlot: the "data array -> one element per key" pattern shared by `ChipSet` and `Tabs` (internal to the kit).

	    local slot = KeyedSlot.new(items, function(item) return item.Id end, function(item, order)
	        return Chip.Assist({ Label = item:Compute(...), Modifier = D.Modifier.TextButton():LayoutOrder(order) })
	    end)

	`items` is a State of an array; `key(item)` must be unique per element. Each key is rendered ONCE: its element
	survives later data changes (reused through `ctx.Prev`, so its identity and any pressed/animating state stay),
	and what changes is delivered through two States handed to `render`:
	  item    State<T>       the current row for this key (a new table = a publish; unchanged rows do not republish)
	  order   State<number>  the key's 1-based position in the array — plug it into `LayoutOrder`
	A key that leaves the array destroys its element (`q.KeyGone` branch). Returns the Slot to place in a parent's
	array part (it mounts its elements directly under that parent, no container Frame).
]]

local q = require("../Quad")

export type Render<T> = (item: q.State<T>, order: q.State<number>) -> Instance

type UD<T> = { item: q.Source<T>, order: q.Source<number> }
type Ctx<T> = {
	Item: T | q.KeyGone,
	Index: number,
	Offset: q.State<number>,
	Prev: q.SlotItem<Instance>?,
	UserData: UD<T>?,
}

local function new<T>(items: q.State<{ T }>, key: (item: T) -> string | number, render: Render<T>): q.Slot<Instance>
	local slot = q.Slot<<Instance>>()
	slot:List(items, function(ctx: Ctx<T>): (any, UD<T>?)
		if ctx.Item == q.KeyGone then
			return nil
		end
		local data = ctx.Item :: T
		local prev, ud = ctx.Prev, ctx.UserData
		if prev and ud then
			ud.item:SetIfChanged(data)
			ud.order:SetIfChanged(ctx.Index)
			return prev, ud
		end
		local itemSrc = q.Source(data)
		local orderSrc = q.Source(ctx.Index)
		return render(itemSrc, orderSrc), { item = itemSrc, order = orderSrc }
	end, function(item: T, _index: number): any
		return key(item)
	end)
	return slot
end

return {
	new = new,
}
