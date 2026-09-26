local store = q.Store({ hp = q.Source(100) })
print(store.hp:Get()) --> 100
print((store :: any).mp) --> nil (선언 안 한 이름 — 만들어지지 않는다)
