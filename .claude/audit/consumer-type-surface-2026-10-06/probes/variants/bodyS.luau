local mk: <T>(v: T) -> Source<T> = (nil :: any)
local function idS<T>(x: Source<T>): Source<T> return x end
local _a1s = idS(mk(1))
local function idSt<T>(x: State<T>): State<T> return x end
local _a1 = idSt(mk(1))
