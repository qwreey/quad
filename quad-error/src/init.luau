--[[
	quad-error — level-tag based error raising. Design and API are the user's
	own experiment, taken as-is (2026-08-31, round12 `H-231` — the experiment
	file measured the frame math; its assertions live on as spec.errorutil).

	Why: `error(msg, n)` counts frames, so the correct `n` depends on how many
	wrappers sit between the raise site and the frame you mean — hand-counting
	(2 vs 3) breaks whenever a helper frame is added, and cannot reach through
	a variable-depth pipeline at all. Instead, tag functions with a *layer
	number* once (`setFuncLevel`); at raise time the util walks the live stack
	with `debug.info(i, "f")` **from the top down** and finds the outermost
	frame whose function is tagged with the requested layer:

	  errorAt(msg, layer)     -- blame the line *inside* that frame
	  errorBefore(msg, layer) -- blame that frame's *caller* (one frame out)

	Untagged functions count as layer 0 (`ERROR_LEVEL_DEFAULT`); if no frame
	matches, the error falls back to the raise site. Errors are cold paths, so
	the walk cost is irrelevant. The tag map is weak-keyed — tagging
	per-instance closures (e.g. an InitXxx(module)'s functions) does not pin
	them.
]]

local module = {}

-- Index of the topmost (outermost) live frame, from the caller's perspective
-- of nothing in particular — callers inside this module account for their own
-- extra frame; external callers rarely need this directly.
function module.getToplevel(): number
	local curr = 2 -- 1: getToplevel
	while debug.info(curr, "f") ~= nil do
		curr += 1
	end
	return curr - 1
end

local funcLevels = setmetatable({}, { __mode = "k" }) :: { [any]: number }

module.ERROR_LEVEL_DEFAULT = 0

function module.setFuncLevel(func: any, level: number)
	funcLevels[func] = level
end

function module.getFuncLevel(func: any): number
	return funcLevels[func] or module.ERROR_LEVEL_DEFAULT
end

-- The error() level that points at the outermost frame tagged `level`,
-- as seen from this function's caller (errorAt/errorBefore). Scans from the
-- stack top down, so an untagged closure sandwiched between tagged layers
-- can never cut the search short. No match -> 1 (the raise site).
function module.getFirstMatch(level: number): number
	-- ignore getFirstMatch (2)
	for i = module.getToplevel(), 2, -1 do
		if module.getFuncLevel(debug.info(i, "f")) == level then
			return i - 1
		end
	end

	return 1
end

function module.errorAt(content: any, level: number)
	error(content, module.getFirstMatch(level))
end

function module.errorBefore(content: any, level: number)
	error(content, module.getFirstMatch(level) + 1)
end

return module
