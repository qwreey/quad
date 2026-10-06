local mk: <T>(v: T) -> Source<T> = (nil :: any)
local s = mk(5)
local f = function(st: State<number>): string return tostring(st:Get()) end
local ok1: string = s:Apply(f)
local bad1: number = s:Apply(f) -- EXPECT
local ok2: string = s:Apply(function(st: State<number>): string return tostring(st:Get()) end)
local bad2: number = s:Apply(function(st: State<number>): string return tostring(st:Get()) end) -- EXPECT
local NumOp: (self: StateData<number>) -> State<number> = (nil :: any)
local ok3: State<number> = s:Apply(NumOp)
local bad3: State<string> = s:Apply(NumOp) -- EXPECT
local _ = ok1; local _ = bad1; local _ = ok2; local _ = bad2; local _ = ok3; local _ = bad3
