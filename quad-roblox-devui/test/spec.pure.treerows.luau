--!strict
-- TreeRows (tree flattening), ported from devplorer `Rows/Flatten` with its spec (2026-10-21); comments kept as written there.
local TreeRows = require("../src/TreeRows")

type Node = { Name: string, Kids: { Node }? }

local accessor: TreeRows.Accessor<Node> = {
	Children = function(node: Node): { Node }
		return node.Kids or {}
	end,
	Key = function(node: Node): any
		return node.Name
	end,
}

local function leaf(name: string): Node
	return { Name = name }
end

local function names(rows: { TreeRows.Row<Node> }): string
	local parts: { string } = {}
	for _, row in rows do
		table.insert(parts, `{row.Depth}:{row.Node.Name}`)
	end
	return table.concat(parts, " ")
end

-- a(b(c d) e) f
local function sample(): { Node }
	return {
		{ Name = "a", Kids = { { Name = "b", Kids = { leaf("c"), leaf("d") } }, leaf("e") } },
		leaf("f"),
	}
end

local function run(test: (string, () -> ()) -> ())
	test("collapsed roots give one row each with hasChildren flags", function()
		local rows = TreeRows.flatten(sample(), accessor, {})
		assert(names(rows) == "0:a 0:f", names(rows))
		assert(rows[1].HasChildren and not rows[1].Expanded)
		assert(not rows[2].HasChildren)
	end)

	test("expanded nodes show their children depth-first", function()
		local rows = TreeRows.flatten(sample(), accessor, { a = true, b = true })
		assert(names(rows) == "0:a 1:b 2:c 2:d 1:e 0:f", names(rows))
		assert(rows[1].Expanded and rows[2].Expanded and not rows[5].Expanded)
	end)

	test("an expanded key under a collapsed parent stays hidden", function()
		local rows = TreeRows.flatten(sample(), accessor, { b = true })
		assert(names(rows) == "0:a 0:f")
	end)

	test("a leaf with an expanded key is not shown as expanded", function()
		local rows = TreeRows.flatten(sample(), accessor, { f = true })
		assert(not rows[2].Expanded)
	end)

	test("HasChildren accessor avoids calling Children on collapsed nodes", function()
		local childCalls = 0
		local lazy: TreeRows.Accessor<Node> = {
			Children = function(node: Node): { Node }
				childCalls += 1
				return node.Kids or {}
			end,
			Key = accessor.Key,
			HasChildren = function(node: Node): boolean
				return node.Kids ~= nil
			end,
		}
		local rows = TreeRows.flatten(sample(), lazy, {})
		assert(childCalls == 0 and rows[1].HasChildren)
	end)

	test("toggle flips and reports the new state", function()
		local set: TreeRows.ExpandedSet = {}
		assert(TreeRows.toggle(set, "a") == true and set.a == true)
		assert(TreeRows.toggle(set, "a") == false and set.a == nil)
	end)

	test("reveal expands ancestors so the target gets a row", function()
		local set: TreeRows.ExpandedSet = {}
		TreeRows.reveal(set, { "a", "b" })
		local rows = TreeRows.flatten(sample(), accessor, set)
		assert(TreeRows.indexOf(rows, "d", accessor) == 4)
		assert(TreeRows.indexOf(rows, "zzz", accessor) == nil)
	end)

	test("indexByKey maps every key to its row", function()
		local rows = TreeRows.flatten(sample(), accessor, { a = true })
		local map = TreeRows.indexByKey(rows, accessor)
		assert(map.a == 1 and map.b == 2 and map.e == 3 and map.f == 4)
	end)

	test("expand and collapse match a fresh flatten", function()
		local set: TreeRows.ExpandedSet = { b = true }
		local roots = sample()
		local rows = TreeRows.flatten(roots, accessor, set)
		-- b는 a가 접혀 있어 숨은 상태. a를 펼치면 b의 기록이 살아나 c d까지 나온다
		assert(TreeRows.expand(rows, 1, accessor, set) == 4)
		assert(names(rows) == names(TreeRows.flatten(roots, accessor, set)))
		assert(names(rows) == "0:a 1:b 2:c 2:d 1:e 0:f", names(rows))
		assert(TreeRows.expand(rows, 1, accessor, set) == 0) -- 이미 펼침
		-- b를 접으면 c d가 빠지고, 다시 펼치면 돌아온다
		assert(TreeRows.collapse(rows, 2, accessor, set) == 2)
		assert(names(rows) == names(TreeRows.flatten(roots, accessor, set)))
		assert(TreeRows.expand(rows, 2, accessor, set) == 2)
		-- a를 접으면 자손 전부가 빠지고 b의 펼침 기록은 남는다
		assert(TreeRows.collapse(rows, 1, accessor, set) == 4)
		assert(names(rows) == "0:a 0:f" and #rows == 2)
		assert(set.b == true and set.a == nil)
	end)

	test("expand on a leaf inserts nothing", function()
		local set: TreeRows.ExpandedSet = {}
		local rows = TreeRows.flatten(sample(), accessor, set)
		assert(TreeRows.expand(rows, 2, accessor, set) == 0)
		assert(not rows[2].Expanded and not rows[2].HasChildren)
	end)

	test("deep chains do not overflow the stack", function()
		local root: Node = leaf("n1")
		local set: TreeRows.ExpandedSet = { n1 = true }
		local cursor = root
		for i = 2, 20000 do
			local nextNode = leaf(`n{i}`)
			cursor.Kids = { nextNode }
			set[`n{i}`] = true
			cursor = nextNode
		end
		local rows = TreeRows.flatten({ root }, accessor, set)
		assert(#rows == 20000 and rows[20000].Depth == 19999)
	end)

	test("flattening 50k children is fast and expand/collapse stay cheap", function()
		local kids: { Node } = {}
		for i = 1, 50000 do
			kids[i] = { Name = `k{i}`, Kids = if i % 10 == 0 then { leaf(`g{i}`) } else nil }
		end
		local roots: { Node } = { { Name = "root", Kids = kids } }
		local set: TreeRows.ExpandedSet = { root = true }

		local t0 = os.clock()
		local rows = TreeRows.flatten(roots, accessor, set)
		local full = os.clock() - t0
		assert(#rows == 50001)
		assert(full < 0.5, `full flatten took {full}s`)
		print(`     50k flatten: {math.floor(full * 1000)} ms`)

		-- 한 노드를 펼치고 접는 증분 갱신도 전체 재평탄화보다 훨씬 싸야 한다
		local t1 = os.clock()
		assert(TreeRows.expand(rows, 11, accessor, set) == 1) -- k10
		assert(TreeRows.collapse(rows, 11, accessor, set) == 1)
		local incremental = os.clock() - t1
		assert(incremental < 0.1, `incremental took {incremental}s`)
		assert(#rows == 50001)
	end)

	-- 자식 n개를 가진 root: r(k1..kn)
	local function fan(n: number): { Node }
		local kids: { Node } = {}
		for i = 1, n do
			kids[i] = leaf(`k{i}`)
		end
		return { { Name = "r", Kids = kids } }
	end

	test("paging shows the first page and a placeholder with the remaining count", function()
		local paging = TreeRows.newPaging(3)
		local rows = TreeRows.flatten(fan(8), accessor, { r = true }, paging)
		assert(names(rows) == "0:r 1:k1 1:k2 1:k3 1:r", names(rows))
		local more = rows[5]
		assert(more.More == 5 and more.Node.Name == "r" and not more.HasChildren and not more.Expanded)
		assert(rows[1].More == nil and rows[2].More == nil)
	end)

	test("loadMore grows the shown count per node until the placeholder disappears", function()
		local paging = TreeRows.newPaging(3)
		local roots = fan(8)
		assert(TreeRows.loadMore(paging, "r") == 6)
		local rows = TreeRows.flatten(roots, accessor, { r = true }, paging)
		assert(#rows == 8 and rows[8].More == 2, names(rows))
		assert(TreeRows.loadMore(paging, "r") == 9)
		rows = TreeRows.flatten(roots, accessor, { r = true }, paging)
		assert(#rows == 9 and rows[9].More == nil, names(rows))
	end)

	test("a node at exactly the page size gets no placeholder", function()
		local rows = TreeRows.flatten(fan(3), accessor, { r = true }, TreeRows.newPaging(3))
		assert(#rows == 4 and rows[4].More == nil)
	end)

	test("paging applies per node and nested placeholders sit at the children depth", function()
		-- a(b(c1 c2 c3) d1 d2 d3), 페이지 2
		local roots: { Node } = {
			{
				Name = "a",
				Kids = {
					{ Name = "b", Kids = { leaf("c1"), leaf("c2"), leaf("c3") } },
					leaf("d1"),
					leaf("d2"),
					leaf("d3"),
				},
			},
		}
		local paging = TreeRows.newPaging(2)
		local rows = TreeRows.flatten(roots, accessor, { a = true, b = true }, paging)
		-- b의 자식은 2개만, 그 뒤 자리표시(깊이 2). a의 자식은 b와 d1 둘만, 그 뒤 자리표시(깊이 1)
		assert(names(rows) == "0:a 1:b 2:c1 2:c2 2:b 1:d1 1:a", names(rows))
		assert(rows[5].More == 1 and rows[7].More == 2)
	end)

	test("indexOf and indexByKey skip placeholder rows", function()
		local rows = TreeRows.flatten(fan(5), accessor, { r = true }, TreeRows.newPaging(2))
		assert(rows[#rows].More == 3)
		assert(TreeRows.indexOf(rows, "r", accessor) == 1)
		assert(TreeRows.indexByKey(rows, accessor).r == 1)
	end)

	test("expand with paging matches a fresh paged flatten and collapse ignores placeholders", function()
		local roots = fan(6)
		local paging = TreeRows.newPaging(2)
		local set: TreeRows.ExpandedSet = {}
		local rows = TreeRows.flatten(roots, accessor, set, paging)
		assert(TreeRows.expand(rows, 1, accessor, set, paging) == 3)
		assert(names(rows) == names(TreeRows.flatten(roots, accessor, set, paging)), names(rows))
		assert(TreeRows.expand(rows, 4, accessor, set, paging) == 0) -- 자리표시 행은 펼치지 않는다
		assert(TreeRows.collapse(rows, 4, accessor, set) == 0 and set.r == true)
		assert(TreeRows.collapse(rows, 1, accessor, set) == 3 and #rows == 1)
	end)

	test("paging 5000 children keeps the row count at page + 1", function()
		local rows = TreeRows.flatten(fan(5000), accessor, { r = true }, TreeRows.newPaging(2000))
		assert(#rows == 2002 and rows[2002].More == 3000)
	end)
	test("MoreCount adds a placeholder after the last child (unknown count = math.huge)", function()
		local extraAccessor: TreeRows.Accessor<Node> = {
			Children = accessor.Children,
			Key = accessor.Key,
			MoreCount = function(node: Node): number?
				return if node.Name == "r" then math.huge else nil
			end,
		}
		local rows = TreeRows.flatten(fan(3), extraAccessor, { r = true }, nil)
		assert(
			#rows == 5 and rows[5].More == math.huge and rows[5].Depth == 1 and rows[5].Node.Name == "r",
			names(rows)
		)
		-- 접혀 있으면 자리표시 행도 없다
		assert(#TreeRows.flatten(fan(3), extraAccessor, {}, nil) == 1)
		-- 펼침 끼우기도 새로 평탄화한 것과 같다
		local set: TreeRows.ExpandedSet = {}
		local base = TreeRows.flatten(fan(3), extraAccessor, set, nil)
		TreeRows.expand(base, 1, extraAccessor, set, nil)
		assert(names(base) == names(TreeRows.flatten(fan(3), extraAccessor, set, nil)))
	end)

	test("sameRows compares structure, ignores table identity, and honors signatures", function()
		local set: TreeRows.ExpandedSet = { a = true }
		local one = TreeRows.flatten(sample(), accessor, set)
		local two = TreeRows.flatten(sample(), accessor, set)
		-- 노드 표가 다르면(여기서는 sample()이 새 표를 만든다) 다른 행이다
		assert(not TreeRows.sameRows(one, two))
		assert(TreeRows.sameRows(one, one))
		local tree = sample()
		local first = TreeRows.flatten(tree, accessor, set)
		local again = TreeRows.flatten(tree, accessor, set)
		assert(TreeRows.sameRows(first, again))
		-- 펼침이 다르면 다르다
		assert(not TreeRows.sameRows(first, TreeRows.flatten(tree, accessor, {})))
		-- 길이만 다른 경우
		assert(not TreeRows.sameRows(first, { first[1] }))
		-- 제자리에서 이름이 바뀌어도 지문이 다르면 다르다
		local sigOf = function(row: TreeRows.Row<Node>): any
			return row.Node.Name
		end
		local before = TreeRows.signatures(first, sigOf)
		tree[2].Name = "g"
		local after = TreeRows.signatures(TreeRows.flatten(tree, accessor, set), sigOf)
		assert(TreeRows.sameRows(first, again, before, before))
		assert(not TreeRows.sameRows(first, again, before, after))
	end)
end

run(function(name: string, fn: () -> ())
	fn()
	print("PASS " .. name)
end)
