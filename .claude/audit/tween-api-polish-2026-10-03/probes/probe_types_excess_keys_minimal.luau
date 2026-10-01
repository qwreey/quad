--!strict
type Opts = { read Value: number, read Time: number? }
local function f(o: Opts) end
f({ Value = 1, Duration = 2 })
local function g<T>(o: { read Value: T, read Time: number? }) end
g({ Value = 1, Duration = 2 })
type Opts2 = { Value: number, Time: number? }
local function h(o: Opts2) end
h({ Value = 1, Duration = 2 })
