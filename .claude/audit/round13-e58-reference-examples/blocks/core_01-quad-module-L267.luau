local rel = q.Relate()
local host = D.Frame {}

rel:SetStrong(host, "meta", { label = "hello" })
print(rel:GetStrong(host, "meta").label) --> hello
