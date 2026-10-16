--!strict
type function tagOf(c: type, k: type)
	local p = c:readproperty(k)
	print(`[TAG] {k:value()} -> tag={p and p.tag or "nil"} str={p and tostring(p) or "nil"}`)
	return c
end
type _a = tagOf<Frame, "NextSelectionUp">
type _b = tagOf<Frame, "Size">
type _c = tagOf<Frame, "Parent">
return {}
