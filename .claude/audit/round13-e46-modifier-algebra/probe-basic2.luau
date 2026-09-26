--!nocheck
local H = require("./harness")
local q, D, None = H.q, H.D, H.None
local function try(label, f)
	local ok, r = pcall(f)
	print(label, ok and "ok" or "ERR", ok and tostring(r) or H.first(r))
end
local sn = q.Source(nil)
try("Alt State mount initial", function() local m = q.Modifier{ZIndex=sn}:ZIndex(q.Operator.Alternative(5)); local f = D.Frame{m}; local a = f.ZIndex; sn:Set(7); return tostring(a) .. " -> " .. tostring(f.ZIndex) end)
local s = q.Source(2)
try("state xform throws mount", function() local m = q.Modifier{ZIndex=s}:ZIndex(function(o) error("boom") end); local f = D.Frame{m}; return tostring(f.ZIndex) end)
local s2 = q.Source(2)
local cnt = 0
local m = q.Modifier{ZIndex=s2}:ZIndex(function(o) cnt += 1; if o:Get() == 3 then error("boom3") end return o:Get()*10 end)
try("xform-throw-later mount", function() local f = D.Frame{m}; local a = f.ZIndex; local ok, e = pcall(function() s2:Set(3) end); local b = f.ZIndex; s2:Set(4); return ("%s set3ok=%s(%s) after=%s then4=%s cnt=%d"):format(tostring(a), tostring(ok), H.first(e), tostring(b), tostring(f.ZIndex), cnt) end)
-- transform lazy? count calls before mount
local c2 = 0
local s3 = q.Source(1)
local m3 = q.Modifier{ZIndex=s3}:ZIndex(function(o) c2 += 1; return o:Get()+1 end)
print("calls before mount", c2)
local f1 = D.Frame{m3}; local f2 = D.Frame{m3}
print("after 2 mounts", c2, f1.ZIndex, f2.ZIndex)
s3:Set(5); print("after set", c2, f1.ZIndex, f2.ZIndex)
f1:Destroy(); s3:Set(9); print("after destroy f1, set 9", c2, f2.ZIndex)
