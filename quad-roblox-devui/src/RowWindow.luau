--!strict
--[[
	RowWindow — the pure arithmetic of VirtualRows (internal, not exported from init.luau; no Roblox API, no quad).
	Ported from devplorer (the user's project, 2026-10-20 user decision: "목록 가상화는 그대로 올려도 될 듯해").

		RowWindow.visible(rowCount, rowHeight, viewport, offset, overscan) -> (first, last)
			the rows the viewport touches (1-based, clamped to [1, rowCount], overscan included); empty = (1, 0)
		RowWindow.canvasHeight(rowCount, rowHeight) -> number
		RowWindow.poolSize(viewport, rowHeight, overscan) -> number
			an upper bound of the visible range's length at any scroll position (the pool size)
		RowWindow.assign(prev, poolSize, first, last) -> { number? }
			pool slot -> row index. A slot that still holds an index in view keeps it; only freed slots take new ones.
		RowWindow.scrollIntoView(index, rowCount, rowHeight, viewport, offset) -> number
			the smallest scroll offset that shows row `index` (the same offset when it is already in view)

	Units are px. A rowHeight <= 0 or non-finite is the caller's mistake (raised to 1 here only to avoid dividing by 0).
	The array `assign` returns may have nil holes: walk 1..poolSize, never `#`.
]]

local RowWindow = {}

local function safeHeight(rowHeight: number): number
	return math.max(1, rowHeight)
end

function RowWindow.canvasHeight(rowCount: number, rowHeight: number): number
	return math.max(0, rowCount) * safeHeight(rowHeight)
end

function RowWindow.visible(
	rowCount: number,
	rowHeight: number,
	viewport: number,
	offset: number,
	overscan: number
): (number, number)
	if rowCount <= 0 or viewport <= 0 then
		return 1, 0
	end
	local h = safeHeight(rowHeight)
	-- a bounce scroll can put the offset below 0 or past the canvas: clamp
	local maxOffset = math.max(0, rowCount * h - viewport)
	local o = math.clamp(offset, 0, maxOffset)
	local pad = math.max(0, overscan)
	local first = math.max(1, math.floor(o / h) + 1 - pad)
	local last = math.min(rowCount, math.ceil((o + viewport) / h) + pad)
	if first > last then
		return 1, 0
	end
	return first, last
end

function RowWindow.poolSize(viewport: number, rowHeight: number, overscan: number): number
	if viewport <= 0 then
		return 0
	end
	return math.ceil(viewport / safeHeight(rowHeight)) + 1 + 2 * math.max(0, overscan)
end

function RowWindow.assign(prev: { number? }, poolSize: number, first: number, last: number): { number? }
	local out: { number? } = {}
	local count = last - first + 1
	-- claimed[k]: some slot already holds index first + k - 1
	local claimed: { boolean } = {}
	-- pass 1: a slot that holds an index still in view keeps it (a duplicate keeps the first slot only)
	for slot = 1, poolSize do
		local had = prev[slot]
		if had ~= nil and count > 0 and had >= first and had <= last and not claimed[had - first + 1] then
			claimed[had - first + 1] = true
			out[slot] = had
		end
	end
	-- pass 2: free slots take the unclaimed indices in ascending order
	local cursor = 1
	for slot = 1, poolSize do
		if out[slot] == nil and count > 0 then
			while cursor <= count and claimed[cursor] do
				cursor += 1
			end
			if cursor <= count then
				claimed[cursor] = true
				out[slot] = first + cursor - 1
			end
		end
	end
	return out
end

function RowWindow.scrollIntoView(
	index: number,
	rowCount: number,
	rowHeight: number,
	viewport: number,
	offset: number
): number
	local h = safeHeight(rowHeight)
	local maxOffset = math.max(0, rowCount * h - viewport)
	local top = (math.clamp(index, 1, math.max(1, rowCount)) - 1) * h
	local bottom = top + h
	local target = offset
	if top < offset then
		target = top
	elseif bottom > offset + viewport then
		target = bottom - viewport
	end
	return math.clamp(target, 0, maxOffset)
end

return RowWindow
