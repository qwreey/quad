--!strict
--[[
	TreeRows — flattens a tree into the array of rows shown now: the data side of a virtual tree (pair it with
	VirtualRows). Pure (no Roblox API). Ported from devplorer (the user's project, `Rows/Flatten`) — 2026-10-21 user
	decision with the candidate list; names by a three-model review (audit/naming-devui-2026-10-21d/).

	It knows nodes only through an accessor, so an Instance tree and nodes received from a server are the same to it:
		Accessor<N> = {
			Children: (node: N) -> { N },          -- the children; called only for expanded nodes
			Key: (node: N) -> any,                  -- the node's identity (the expanded set's key), unique in the whole tree
			HasChildren: ((node: N) -> boolean)?,   -- for a collapsed node's arrow; without it `#Children(node) > 0`
			MoreCount: ((node: N) -> number?)?,     -- children beyond the given list (a server tree: not fetched yet;
			                                        -- math.huge = unknown); a placeholder row follows the last child
		}
	Without HasChildren every collapsed node's Children is called for its length (linear in the tree): a tree that loads
	children lazily must give it.

	Row<N> = { Node, Depth (0-based), HasChildren, Expanded, More? }. The expanded set is a plain `{ [key]: boolean }`
	(TreeRows.toggle / setExpanded / reveal write it). Collapsing keeps the descendants' expanded entries, so expanding
	again brings them back.

	PAGING (optional). Given Paging, flatten/expand show a node's first children up to its shown count
	(Paging.Shown[key], else Paging.Page) and then a "load more" placeholder row: Node = the parent node, Depth = the
	children's depth, HasChildren = false, Expanded = false, More = how many children are not shown (always > 0). An
	ordinary row has More = nil. MoreCount (a server tree) is separate from paging: with every given child shown but
	more said to exist, the same placeholder row is added. TreeRows.loadMore(paging, key) grows that node's shown count by
	one Page. Top-level roots are not paged. indexOf / indexByKey skip placeholder rows (they share the parent's key and
	must not overwrite the parent row's index).

	Cost: flatten is linear in the shown rows and walks with an explicit stack (deep trees are safe). expand / collapse
	of one node splice only that node's subtree in or out, never rebuilding the whole; the result always equals a fresh
	flatten.

		TreeRows.flatten(roots, accessor, expanded, paging?) -> { Row }
		TreeRows.expand(rows, index, accessor, expanded, paging?) -> inserted   (rows[index] expanded in place)
		TreeRows.collapse(rows, index, accessor, expanded) -> removed
		TreeRows.toggle(expanded, key) -> isExpanded    TreeRows.setExpanded(expanded, key, value)
		TreeRows.reveal(expanded, ancestorKeys)          (expands the ancestors so a node gets a row)
		TreeRows.indexOf(rows, key, accessor) -> number?    TreeRows.indexByKey(rows, accessor) -> { [key]: index }
		TreeRows.newPaging(page) -> Paging              TreeRows.loadMore(paging, key) -> newShownCount
		TreeRows.signatures(rows, signature) -> { any } / TreeRows.sameRows(a, b, sigsA?, sigsB?) -> boolean
		    (whether a new flatten changed anything shown, so `rows:Set` can be skipped)
]]

export type Accessor<N> = {
	Children: (node: N) -> { N },
	Key: (node: N) -> any,
	HasChildren: ((node: N) -> boolean)?,
	-- children beyond the list (math.huge: unknown) — a placeholder row for what a server tree has not sent yet
	MoreCount: ((node: N) -> number?)?,
}

export type Row<N> = {
	Node: N,
	Depth: number,
	HasChildren: boolean,
	Expanded: boolean,
	-- only on a placeholder row: how many children are not shown (always > 0)
	More: number?,
}

export type Paging = {
	Page: number,
	-- node key -> the children shown so far; absent: Page
	Shown: { [any]: number },
}

export type ExpandedSet = { [any]: boolean }

local TreeRows = {}

-- one node's row; expanded with children, the children too
local function makeRow<N>(node: N, depth: number, accessor: Accessor<N>, expanded: ExpandedSet): (Row<N>, { N }?)
	local isExpanded = expanded[accessor.Key(node)] == true
	local children: { N }? = nil
	local hasChildren: boolean
	if isExpanded then
		children = accessor.Children(node)
		hasChildren = #(children :: { N }) > 0
	else
		local probe = accessor.HasChildren
		if probe then
			hasChildren = probe(node)
		else
			hasChildren = #accessor.Children(node) > 0
		end
	end
	-- a node without children is not counted as expanded even when its key is in the set
	local showExpanded = isExpanded and hasChildren
	return {
		Node = node,
		Depth = depth,
		HasChildren = hasChildren,
		Expanded = showExpanded,
	},
		if showExpanded then children else nil
end

-- appends `roots` depth-first after `out`. An explicit stack: no recursion limit.
-- with `owner` (the roots' parent) and paging, only the shown count of roots is appended, then a placeholder row.
local function appendTree<N>(
	out: { Row<N> },
	roots: { N },
	depth: number,
	accessor: Accessor<N>,
	expanded: ExpandedSet,
	owner: N?,
	paging: Paging?
)
	local function limitOf(list: { N }, parent: N?): number
		if paging == nil or parent == nil then
			return #list
		end
		return math.min(#list, paging.Shown[accessor.Key(parent)] or paging.Page)
	end

	local lists: { { N } } = { roots }
	local limits: { number } = { limitOf(roots, owner) }
	local owners: { N? } = { owner }
	local cursors: { number } = { 0 }
	local depths: { number } = { depth }
	local top = 1
	local size = #out
	while top > 0 do
		local list = lists[top]
		local at = cursors[top] + 1
		if at > limits[top] then
			local rest = #list - limits[top]
			local parent = owners[top]
			if rest <= 0 and parent ~= nil and accessor.MoreCount ~= nil then
				rest = accessor.MoreCount(parent) or 0
			end
			if rest > 0 and parent ~= nil then
				size += 1
				out[size] = { Node = parent, Depth = depths[top], HasChildren = false, Expanded = false, More = rest }
			end
			lists[top] = nil :: any
			limits[top] = nil :: any
			owners[top] = nil :: any
			cursors[top] = nil :: any
			depths[top] = nil :: any
			top -= 1
		else
			cursors[top] = at
			local d = depths[top]
			local node = list[at]
			local row, children = makeRow(node, d, accessor, expanded)
			size += 1
			out[size] = row
			if children then
				top += 1
				lists[top] = children
				limits[top] = limitOf(children, node)
				owners[top] = node
				cursors[top] = 0
				depths[top] = d + 1
			end
		end
	end
end

function TreeRows.flatten<N>(roots: { N }, accessor: Accessor<N>, expanded: ExpandedSet, paging: Paging?): { Row<N> }
	local out: { Row<N> } = {}
	appendTree(out, roots, 0, accessor, expanded, nil, paging)
	return out
end

-- collects each row's fingerprint of what it shows (values that change inside a node: a name, a class), for sameRows.
function TreeRows.signatures<N>(rows: { Row<N> }, signature: (row: Row<N>) -> any): { any }
	local out: { any } = table.create(#rows)
	for i, row in rows do
		out[i] = signature(row)
	end
	return out
end

-- whether two row lists are the same (Node identity, Depth, HasChildren, Expanded, More, and the fingerprints at the same place when given). Same: `rows:Set` can be skipped.
-- Nodes are edited in place, so a value such as a name does not show in the row structure: collect those with signatures and pass them as sigsA / sigsB.
function TreeRows.sameRows<N>(a: { Row<N> }, b: { Row<N> }, sigsA: { any }?, sigsB: { any }?): boolean
	if a == b then
		return true
	end
	if #a ~= #b then
		return false
	end
	for i = 1, #a do
		if sigsA ~= nil and sigsB ~= nil and sigsA[i] ~= sigsB[i] then
			return false
		end
		local x, y = a[i], b[i]
		if
			x.Node ~= y.Node
			or x.Depth ~= y.Depth
			or x.HasChildren ~= y.HasChildren
			or x.Expanded ~= y.Expanded
			or x.More ~= y.More
		then
			return false
		end
	end
	return true
end

function TreeRows.newPaging(page: number): Paging
	return { Page = math.max(1, math.floor(page)), Shown = {} }
end

-- grows the shown child count of node `key` by one page; returns the new count
function TreeRows.loadMore(paging: Paging, key: any): number
	local shown = (paging.Shown[key] or paging.Page) + paging.Page
	paging.Shown[key] = shown
	return shown
end

function TreeRows.toggle(expanded: ExpandedSet, key: any): boolean
	local nextState = expanded[key] ~= true
	expanded[key] = if nextState then true else nil :: any
	return nextState
end

function TreeRows.setExpanded(expanded: ExpandedSet, key: any, value: boolean)
	expanded[key] = if value then true else nil :: any
end

-- expands every ancestor key (to "reveal" a selected node). The node itself is not expanded
function TreeRows.reveal(expanded: ExpandedSet, ancestorKeys: { any })
	for _, key in ancestorKeys do
		expanded[key] = true
	end
end

-- the index of the first row with that key (nil if none). Linear: for repeated lookups use indexByKey
function TreeRows.indexOf<N>(rows: { Row<N> }, key: any, accessor: Accessor<N>): number?
	for i, row in rows do
		if row.More == nil and accessor.Key(row.Node) == key then
			return i
		end
	end
	return nil
end

function TreeRows.indexByKey<N>(rows: { Row<N> }, accessor: Accessor<N>): { [any]: number }
	local map: { [any]: number } = {}
	for i, row in rows do
		if row.More == nil then
			map[accessor.Key(row.Node)] = i
		end
	end
	return map
end

-- expands rows[index] and inserts the rows under it; returns how many were inserted (0 if already expanded or no children)
function TreeRows.expand<N>(
	rows: { Row<N> },
	index: number,
	accessor: Accessor<N>,
	expanded: ExpandedSet,
	paging: Paging?
): number
	local row = rows[index]
	if row == nil or row.Expanded or row.More ~= nil then
		return 0
	end
	expanded[accessor.Key(row.Node)] = true
	local children = accessor.Children(row.Node)
	if #children == 0 then
		row.HasChildren = false
		return 0
	end
	row.HasChildren = true
	row.Expanded = true
	local added: { Row<N> } = {}
	appendTree(added, children, row.Depth + 1, accessor, expanded, row.Node, paging)
	local count = #added
	local total = #rows
	-- shift the tail once and insert (table.move handles the overlap)
	table.move(rows, index + 1, total, index + 1 + count)
	table.move(added, 1, count, index + 1, rows)
	return count
end

-- collapses rows[index] and removes its descendant rows; returns how many were removed. Descendants keep their expanded entries
function TreeRows.collapse<N>(rows: { Row<N> }, index: number, accessor: Accessor<N>, expanded: ExpandedSet): number
	local row = rows[index]
	if row == nil or row.More ~= nil then
		return 0
	end
	expanded[accessor.Key(row.Node)] = nil :: any
	if not row.Expanded then
		return 0
	end
	row.Expanded = false
	local total = #rows
	local last = index
	while last < total and rows[last + 1].Depth > row.Depth do
		last += 1
	end
	local removed = last - index
	if removed > 0 then
		table.move(rows, last + 1, total, index + 1)
		for i = total - removed + 1, total do
			rows[i] = nil :: any
		end
	end
	return removed
end

return TreeRows
