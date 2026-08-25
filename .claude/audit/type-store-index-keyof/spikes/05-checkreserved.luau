--!strict
type Source<T> = { Value: T, Get: (self: Source<T>) -> T, Set: (self: Source<T>, v: T) -> Source<T> }

type function CheckReserved(t: type): type
	if t:is("table") then
		for k in t:properties() do
			if k:is("singleton") then
				local name = k:value()
				if name == "Of" or name == "__store" then
					print("quad.Store: \"" .. tostring(name) .. "\" is a reserved key")
					return types.never
				end
			end
		end
	end
	return t
end

type StoreOf<T> = {
	__store: T,
	Of: <Self, K>(self: Self, key: K & keyof<index<Self, "__store">>)
	     -> Source<index<index<Self, "__store">, K>>,
} & T
type Store<T> = StoreOf<CheckReserved<T>>

-- 정상
local good = (nil :: any) :: Store<{ hp: number, name: string? }>
local a: number = good.hp
local b: string? = good.name
local c: Source<number> = good:Of("hp")
local d: Source<string?> = good:Of("name")
local e: Source<number> = good:Of("name")     -- 음성 대조군

-- 예약 키 충돌 → never 로 무너뜨림
local bad = (nil :: any) :: Store<{ Of: number }>
local f = bad.Of
