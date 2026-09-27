--!nocheck
-- E75 case runner. Each case = { id, trigger = fn, fix = fn, note? }.
--   trigger(): must raise an error whose first line contains the id (pcall'd).
--   fix(): the page's "고치려면" prescription applied literally to the same program.
--          Must NOT raise; returns (intentOk: boolean, detail: string?) — whether the
--          program now does what the user presumably wanted (checked by the case).
-- Output lines (tab separated), one per case:
--   @@E75  id  TRIG=<ok|miss|noerr>  <trigger first line>  FIX=<ok|intent-fail|err|skip>  <detail or error first line>
-- Blame: the "file:line:" prefix of the trigger message is kept verbatim so the reader can see
-- whether it lands in the case file (user code) or inside quad.
local R = {}

local function first(e)
	return (tostring(e):gsub("\n.*", ""))
end
R.first = first

local results = {}

function R.case(c)
	local id = c.id
	local tstat, tmsg
	if c.trigger then
		local ok, err = pcall(c.trigger)
		if ok then
			tstat, tmsg = "noerr", tostring(err)
		elseif string.find(first(err), id, 1, true) then
			tstat, tmsg = "ok", first(err)
		else
			tstat, tmsg = "miss", first(err)
		end
	else
		tstat, tmsg = "skip", c.note or ""
	end
	local fstat, fmsg
	if c.fix then
		local ok, a, b = pcall(c.fix)
		if not ok then
			fstat, fmsg = "err", first(a)
		elseif a == false then
			fstat, fmsg = "intent-fail", tostring(b)
		else
			fstat, fmsg = "ok", tostring(b or "")
		end
	else
		fstat, fmsg = "skip", c.fixnote or ""
	end
	local line = table.concat({ "@@E75", id, "TRIG=" .. tstat, tmsg, "FIX=" .. fstat, fmsg }, "\t")
	print(line)
	table.insert(results, { id = id, t = tstat, f = fstat })
end

-- expect(fn, id): run fn, return true iff it raised an error containing id (used inside fixes to
-- assert a *different* error is gone / present)
function R.raises(fn, id)
	local ok, err = pcall(fn)
	if ok then
		return false, nil
	end
	return (id == nil) or string.find(first(err), id, 1, true) ~= nil, first(err)
end

function R.done()
	print("<<END>>", #results)
end

return R
