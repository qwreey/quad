local seen = {}
debouncedQuery:Observer(function(t) table.insert(seen, t:Get()) end):Subscribe()
searchInput:Set("a"); searchInput:Set("ab"); H.runTask(0.1); print("before 0.3:", table.concat(seen, "|"))
H.runTask(0.5); print("after:", table.concat(seen, "|"))
print("throttled init:", throttledScroll:Get())
