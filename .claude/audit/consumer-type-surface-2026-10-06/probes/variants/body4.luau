local mk: <T>(v: T) -> Source<T> = (nil :: any)
type C1<T> = { Value: State<T>, Options: { T } }
local function Combo1<T>(_p: C1<T>) end
Combo1({ Value = mk(1), Options = { 1, 2 } })
type C2<T> = { read Value: State<T>, read Options: { read [number]: T } }
local function Combo2<T>(_p: C2<T>) end
Combo2({ Value = mk(1), Options = { 1, 2 } })
type C3<T> = { read Value: State<T>, read OnChange: ((T) -> ())? }
local function Combo3<T>(_p: C3<T>) end
Combo3({ Value = mk(1), OnChange = function(_n: number) end })
Combo3({ Value = mk(1), OnChange = function(_n: string) end }) -- EXPECT
