--!nocheck
-- E80 helpers: labelled checks + error capture (first line only, Quad ID extracted)
local L = {}
L.results = {}
function L.check(label, cond, detail)
	local tag = if cond then "PASS" else "FAIL"
	print(string.format("[%s] %s %s", tag, label, detail and ("— " .. tostring(detail)) or ""))
	table.insert(L.results, { label = label, ok = cond })
	return cond
end
function L.first(err)
	return (tostring(err):gsub("\n.*", ""))
end
function L.id(msg)
	return string.match(tostring(msg), "(Quad%d%d%d%d)")
end
-- run fn expecting an error; returns (message, id); prints it
function L.err(label, fn, ...)
	local ok, e = pcall(fn, ...)
	if ok then
		print("  " .. label .. ": NO ERROR")
		return nil, nil
	end
	local m = L.first(e)
	print("  " .. label .. ": " .. m)
	return m, L.id(m)
end
function L.has(s, needle)
	return s ~= nil and string.find(s, needle, 1, true) ~= nil
end
-- run one top-level probe section; a crash is reported, not fatal (3.2.0 대조에서 앞 절이 죽어도 뒤 절이 돈다)
function L.section(fn)
	local ok, e = pcall(fn)
	if not ok then
		print("[CRASH] " .. L.first(e))
		table.insert(L.results, { label = "crash", ok = false })
	end
end
function L.done()
	local p, f = 0, 0
	for _, r in L.results do if r.ok then p += 1 else f += 1 end end
	print(string.format("<<END>> pass=%d fail=%d", p, f))
end
return L
