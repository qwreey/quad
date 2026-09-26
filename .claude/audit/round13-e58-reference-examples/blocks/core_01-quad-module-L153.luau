local q = Quad:UseProvider(QuadRoblox)
local q2 = q:UseProvider(QuadRoblox) -- 같은 함수 — 멱등 no-op
print(q2 == q) --> true
