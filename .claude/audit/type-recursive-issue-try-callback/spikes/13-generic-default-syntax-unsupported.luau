--!strict
local function Foo<T = number>(x: T): T
    return x
end
local a = Foo(1)
local b: string = Foo("hi")
