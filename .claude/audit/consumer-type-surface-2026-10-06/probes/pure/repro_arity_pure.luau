--!strict
-- keyFn family, quad-free: a function VALUE with fewer parameters is not accepted where a function type with more
-- parameters is expected (lambda literals are adapted; typed function values are not). Not generic-specific.
local R: (k: ((string, number) -> any)?) -> () = (nil :: any)
local function h(key: (string) -> string) R(key) end -- FAIL
local function h2(key: (string, number) -> string) R(key) end -- ok
R(function(s) return s end) -- ok (literal)
