--[[ Void 계약 — `H-162`: 단일 no-op 함수, 반환값 없음, 항상 같은 함수 ]]

local Quad = require("../src")
local Void = require("../src/Void")

print("=== 1. 항등 — Quad.Void와 Void.luau가 같은 함수, 매 require도 같음 ===")
do
	assert(Quad.Void == Void, "Quad.Void is the very same function as Void.luau")
	assert(require("../src/Void") == Void, "module caching keeps one identity")
	print("PASS")
end

print()
print("=== 2. no-op — 어떤 인자로 불러도 아무것도 반환하지 않음 ===")
do
	assert(select("#", Void()) == 0, "Void() returns nothing")
	assert(select("#", Void(1, "a", {}, nil)) == 0, "Void(...) returns nothing regardless of args")
	print("PASS")
end

print()
print("=== ALL PASS ===")
