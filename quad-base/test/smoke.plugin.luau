--[[ 임시 스모크 테스트 — Quad.Version/AddPlugin이 실제로 동작하는지 확인 ]]

local Quad = require("../src")

print("=== 1. Version 필드가 pesde.toml과 맞음 ===")
assert(Quad.Version == "0.0.0", "quad-base/pesde.toml의 version과 일치해야 함")
print("PASS")

print()
print("=== 2. AddPlugin이 원본 identity를 유지한 채(mutate) 확장 필드를 추가함 ===")
do
	local function springPlugin(_self)
		return {
			Spring = function(_selfArg, v)
				return v * 2
			end,
		}
	end

	local withSpring = Quad:AddPlugin(springPlugin)
	assert(withSpring == Quad, "AddPlugin은 원본 module을 그대로 mutate+반환해야 함(RunInit 추적이 identity에 의존)")
	assert(withSpring:Spring(21) == 42, "확장된 메소드가 실제로 동작해야 함")
	assert(withSpring.debug == false, "원본 필드는 그대로 남아있어야 함")
	print("PASS")
end

print()
print("=== 3. 체이닝 — 여러 플러그인을 연속으로 추가해도 전부 누적됨 ===")
do
	local m = Quad.New()

	local function pluginA(_self)
		return {
			A = function(_selfArg)
				return "a"
			end,
		}
	end
	local function pluginB(_self)
		return {
			B = function(_selfArg)
				return "b"
			end,
		}
	end

	local withBoth = m:AddPlugin(pluginA):AddPlugin(pluginB)
	assert(withBoth:A() == "a", "pluginA의 확장 메소드가 동작해야 함")
	assert(withBoth:B() == "b", "pluginB의 확장 메소드가 동작해야 함")
	assert(withBoth.debug == false, "원본 필드는 체이닝 후에도 남아있어야 함")
	print("PASS")
end

print()
print("=== ALL PASS ===")
