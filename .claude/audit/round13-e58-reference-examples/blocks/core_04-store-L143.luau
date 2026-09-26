local store = q.Store({ hp = q.Source(100) })
store:Of("mp")

local names = store:Names()
table.sort(names)
print(table.concat(names, ",")) --> hp,mp
