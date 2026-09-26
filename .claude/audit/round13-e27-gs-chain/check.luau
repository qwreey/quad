--!nocheck
-- E27 shared assert helper: check(id, ok, detail) prints PASS/FAIL lines; summary() prints totals.
local n, fails = 0, {}
local function check(id, ok, detail)
	n += 1
	if ok then
		print("PASS " .. id .. (detail and (" — " .. tostring(detail)) or ""))
	else
		table.insert(fails, id)
		print("FAIL " .. id .. (detail and (" — " .. tostring(detail)) or ""))
	end
end
local function expectErr(id, fn, needle)
	local ok, err = pcall(fn)
	local msg = tostring(err):gsub("\n.*", "")
	check(id, (not ok) and string.find(msg, needle, 1, true) ~= nil, if ok then "no error" else msg)
	return msg
end
local function summary(name)
	print(("== %s: %d checks, %d FAIL %s"):format(name, n, #fails, table.concat(fails, ",")))
end
return { check = check, expectErr = expectErr, summary = summary }
