-- 실행: quad-base/test/ 아래로 복사한 뒤 `./scripts/test.sh`로 relink된 상태에서 `luau -O2 quad-base/test/<이 파일>` (require("./mock") 경로 때문)
local mock = require("./mock")
local q = mock.newQuad()
local Instance = mock.Instance
local N, PASSES, RUNS = 1000, 30, 5

local function run(label, wrap)
	local rows = table.create(N)
	for i = 1, N do rows[i] = { id = i } end
	local data = q.Source(rows)
	local s = q.Slot()
	local inner = function(item, prev)
		if item == q.KeyGone then return nil end
		if prev then return prev end
		return Instance.new("Frame")
	end
	s:List(data, wrap(inner), function(item) return item.id end)
	local parent = Instance.new("Folder")
	q.Dispatch.drive(parent, { s })
	local ts = {}
	for r = 1, RUNS do
		collectgarbage("collect")
		local t0 = os.clock()
		for p = 1, PASSES do
			local copy = table.create(N)
			for i = 1, N do copy[i] = rows[i] end
			data:Set(copy) -- every key persists: pure update pass, updateFn returns prev
		end
		ts[r] = os.clock() - t0
	end
	table.sort(ts)
	local med = ts[math.ceil(RUNS / 2)]
	print(string.format("%-18s %7.1f ms  (%6.1f µs/item-pass)", label, med * 1000, med * 1e6 / (N * PASSES)))
end

run("positional", function(inner)
	return function(item, _i, _o, prev, ud) return inner(item, prev), ud end
end)
run("fresh table", function(inner)
	return function(item, i, o, prev, ud)
		local ctx = { item = item, index = i, offset = o, prev = prev, userdata = ud }
		return inner(ctx.item, ctx.prev), ctx.userdata
	end
end)
run("reuse overwrite", function(inner)
	local ctx = { item = false, index = 0, offset = false, prev = false, userdata = false }
	return function(item, i, o, prev, ud)
		ctx.item = item; ctx.index = i; ctx.offset = o; ctx.prev = prev; ctx.userdata = ud
		return inner(ctx.item, ctx.prev), ctx.userdata
	end
end)
