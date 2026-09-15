--[[ 임시 스모크 테스트 — Quad.Version/AddPlugin이 실제로 동작하는지 확인 ]]

local Quad = require("../src")

print("=== 1. Version 필드가 pesde.toml과 맞음 ===")
assert(Quad.Version == "3.2.0", "quad-base/pesde.toml의 version과 일치해야 함")
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
print("=== 4. 기존 필드 덮어쓰기 — 허용하되 debug일 때 경고(2026-09-15 사용자 결정) ===")
do
	local m = Quad.New()
	m.debug = true
	local replacement = function() end
	print("(아래 AddPlugin 덮어쓰기 경고 한 줄은 의도된 출력이다 — print 캡처가 안 돼 육안 확인)")
	m:AddPlugin(function(_self)
		return { Effect = replacement, Fresh = true }
	end)
	assert((m :: any).Effect == replacement, "덮어쓰기는 막지 않는다 — 플러그인 값이 이겨야 함")
	assert((m :: any).Fresh == true, "새 필드는 경고 없이 병합돼야 함")
	print("PASS")
end

print()
print("=== ALL PASS ===")
