local store = q.Store({
	hp = q.Source(100),
	name = q.Source("player"),
})

print(store.hp:Get()) --> 100
store.hp:Set(80)
