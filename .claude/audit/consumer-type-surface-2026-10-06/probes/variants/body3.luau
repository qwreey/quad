local mk: <T>(v: T) -> Source<T> = (nil :: any)
local function opt(_v: State<boolean>?) end
opt(mk(true))
local function req(_v: State<boolean>) end
req(mk(true))
type P = { Open: State<boolean>? }
local _p: P = { Open = mk(true) }
