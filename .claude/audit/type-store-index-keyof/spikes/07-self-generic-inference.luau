--!strict
type State<T> = { Value: T, Get: (self: State<T>) -> T,
	Compute: <U>(self: State<T>, fn: (v: T) -> U) -> State<U> }
type Source<T> = State<T> & { Set: (self: Source<T>, v: T) -> Source<T> }
type Rec = { hp: number }

-- 1) 제네릭 없이 그냥 Source<number> 를 주는 함수
local function direct(): Source<number> return nil :: any end
local r1 = direct():Compute(function(v) return v + 1 end)

-- 2) index<> 만 거친 것 (Self 없음, K 없음)
local function viaIndex(): Source<index<Rec, "hp">> return nil :: any end
local r2 = viaIndex():Compute(function(v) return v + 1 end)

-- 3) K 제네릭 + index<T,K> (Self 없음)
local function viaK<K>(key: K & keyof<Rec>): Source<index<Rec, K>> return nil :: any end
local r3 = viaK("hp"):Compute(function(v) return v + 1 end)

-- 4) Self 제네릭까지 (지금 확정 형태)
type Store<T> = { __store: T,
	Of: <Self, K>(self: Self, key: K & keyof<index<Self, "__store">>)
	     -> Source<index<index<Self, "__store">, K>> } & T
local store = (nil :: any) :: Store<Rec>
local r4 = store:Of("hp"):Compute(function(v) return v + 1 end)

-- 5) 중간 변수에 명시 주석을 달면?
local s5: Source<number> = store:Of("hp")
local r5 = s5:Compute(function(v) return v + 1 end)

-- 6) 콜백 파라미터에 주석
local r6 = store:Of("hp"):Compute(function(v: number) return v + 1 end)
