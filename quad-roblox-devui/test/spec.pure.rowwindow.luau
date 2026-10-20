--!strict
-- RowWindow (VirtualRows arithmetic), ported with the module from devplorer (2026-10-20); comments kept as written there.
local RowWindow = require("../src/RowWindow")

local function run(test: (string, () -> ()) -> ())
	test("visible at the top covers the viewport plus overscan", function()
		-- 높이 20px, 창 100px, 오프셋 0: 행 1..5가 보이고 overscan 2는 아래로만 붙는다
		local first, last = RowWindow.visible(1000, 20, 100, 0, 2)
		assert(first == 1 and last == 7, `{first}..{last}`)
	end)

	test("visible mid-list includes partial rows on both ends", function()
		-- 오프셋 50: 행 3(40..60)이 일부 걸쳐 시작, 창 끝 150은 행 8(140..160) 안
		local first, last = RowWindow.visible(1000, 20, 100, 50, 0)
		assert(first == 3 and last == 8, `{first}..{last}`)
	end)

	test("visible ends exactly on a row boundary without an extra row", function()
		local first, last = RowWindow.visible(1000, 20, 100, 40, 0)
		assert(first == 3 and last == 7, `{first}..{last}`)
	end)

	test("visible clamps to the row count", function()
		local first, last = RowWindow.visible(4, 20, 100, 0, 3)
		assert(first == 1 and last == 4)
		local f2, l2 = RowWindow.visible(100, 20, 100, 99999, 2)
		assert(l2 == 100 and f2 >= 1 and f2 <= 100)
	end)

	test("visible clamps a negative (bounce) offset", function()
		local first, last = RowWindow.visible(100, 20, 100, -300, 0)
		assert(first == 1 and last == 5)
	end)

	test("visible is empty without rows or viewport", function()
		local first, last = RowWindow.visible(0, 20, 100, 0, 2)
		assert(first == 1 and last == 0)
		first, last = RowWindow.visible(10, 20, 0, 0, 2)
		assert(first == 1 and last == 0)
	end)

	test("canvasHeight is count times row height", function()
		assert(RowWindow.canvasHeight(50000, 15) == 750000)
		assert(RowWindow.canvasHeight(0, 15) == 0)
		assert(RowWindow.canvasHeight(-3, 15) == 0)
	end)

	test("poolSize bounds the visible range for every offset", function()
		local rowHeight, viewport, overscan, count = 17, 230, 2, 5000
		local bound = RowWindow.poolSize(viewport, rowHeight, overscan)
		local widest = 0
		for offset = 0, count * rowHeight, 3 do
			local first, last = RowWindow.visible(count, rowHeight, viewport, offset, overscan)
			widest = math.max(widest, last - first + 1)
			assert(last - first + 1 <= bound, `offset {offset}`)
		end
		assert(widest > 0)
		assert(RowWindow.poolSize(0, 20, 2) == 0)
	end)

	test("assign fills a fresh pool in ascending order", function()
		local out = RowWindow.assign({}, 5, 10, 14)
		for i = 1, 5 do
			assert(out[i] == 9 + i)
		end
	end)

	test("assign keeps slots whose index is still visible", function()
		local prev: { number? } = { 1, 2, 3, 4, 5 }
		-- 한 칸 스크롤: 6이 들어오고 1이 나간다. 2..5를 들고 있던 슬롯은 그대로
		local out = RowWindow.assign(prev, 5, 2, 6)
		assert(out[1] == 6)
		for i = 2, 5 do
			assert(out[i] == i)
		end
	end)

	test("assign recycles freed slots on a big jump", function()
		local prev: { number? } = { 1, 2, 3 }
		local out = RowWindow.assign(prev, 3, 100, 102)
		local seen: { [number]: boolean } = {}
		for i = 1, 3 do
			local v = out[i]
			assert(v ~= nil and v >= 100 and v <= 102 and not seen[v])
			seen[v] = true
		end
	end)

	test("assign leaves extra slots nil and handles an empty range", function()
		local out = RowWindow.assign({ 1, 2, 3, 4 }, 4, 1, 2)
		assert(out[1] == 1 and out[2] == 2 and out[3] == nil and out[4] == nil)
		local empty = RowWindow.assign({ 1, 2 }, 2, 1, 0)
		assert(empty[1] == nil and empty[2] == nil)
	end)

	test("assign drops duplicate or stale indices", function()
		local out = RowWindow.assign({ 3, 3, 99 }, 3, 3, 5)
		assert(out[1] == 3)
		local seen: { [number]: boolean } = {}
		for i = 1, 3 do
			local v = out[i]
			assert(v ~= nil and v >= 3 and v <= 5 and not seen[v])
			seen[v] = true
		end
	end)

	test("assign over a long scroll never duplicates and covers the range", function()
		local pool: { number? } = {}
		local size = RowWindow.poolSize(200, 20, 2)
		for offset = 0, 4000, 7 do
			local first, last = RowWindow.visible(1000, 20, 200, offset, 2)
			pool = RowWindow.assign(pool, size, first, last)
			local seen: { [number]: boolean } = {}
			for i = 1, size do
				local v = pool[i]
				if v ~= nil then
					assert(v >= first and v <= last and not seen[v])
					seen[v] = true
				end
			end
			for index = first, last do
				assert(seen[index], `missing {index} at offset {offset}`)
			end
		end
	end)

	test("scrollIntoView leaves a visible row alone and nudges minimally otherwise", function()
		-- 행 높이 20, 창 100, 오프셋 100(행 6..10 보임)
		assert(RowWindow.scrollIntoView(7, 100, 20, 100, 100) == 100)
		assert(RowWindow.scrollIntoView(3, 100, 20, 100, 100) == 40) -- 위로: 행 3의 top
		assert(RowWindow.scrollIntoView(12, 100, 20, 100, 100) == 140) -- 아래로: 행 12의 bottom(240) - 창(100)
	end)

	test("scrollIntoView clamps to the canvas", function()
		assert(RowWindow.scrollIntoView(100, 100, 20, 100, 0) == 1900)
		assert(RowWindow.scrollIntoView(1, 3, 20, 100, 0) == 0)
	end)
end

run(function(name: string, fn: () -> ())
	fn()
	print("PASS " .. name)
end)
