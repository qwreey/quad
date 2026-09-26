local tag = q.Tag("card", "selected")
print(tag:Contains("card"))               -- true
print(tag:Contains("card", "selected"))   -- true (전부 있어야 참)
print(tag:Contains("card", "missing"))    -- false
