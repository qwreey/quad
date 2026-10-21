--!strict
--[[
	KeyedSlot: the "data array -> one element per key" pattern shared by `Table` and `Combo` (internal to the kit; the
	material kit has its own copy — the two kits do not depend on each other).

	    local slot = KeyedSlot.new(rows, function(row) return row.Id end, function(item, order)
	        return Frame({ LayoutOrder = order, ... item:Compute(...) ... })
	    end)

	`items` is an array or a State of one; `key(item)` must be unique per element. Each key is rendered ONCE: its element
	survives later data changes (reused through `ctx.Prev`, so its identity and any hover / pressed state stay), and
	what changes is delivered through two States handed to `render`:
	  item    State<T>       the current row for this key (a new table = a publish; unchanged rows do not republish)
	  order   State<number>  the key's 1-based position in the array — plug it into `LayoutOrder`
	A key that leaves the array destroys its element (`q.KeyGone` branch, returning no UserData so the gone key's
	Sources are not kept). Returns the Slot to place in a parent's array part (it mounts its elements directly under
	that parent, no container Frame).
]]

local Quad = require("./Quad")
local q = Quad

export type Render<T> = (item: Quad.State<T>, order: Quad.State<number>) -> Instance

type UD<T> = { item: Quad.Source<T>, order: Quad.Source<number> }
type Ctx<T> = Quad.SlotCtx<T, UD<T>, Instance>

local function new<T>(items: Quad.State<{ T }> | { T }, key: (item: T) -> any, render: Render<T>): Quad.Slot<Instance>
	local slot = q.Slot<<Instance>>()
	slot:List<<T, UD<T>>>(items, function(ctx: Ctx<T>): (any, UD<T>?)
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
