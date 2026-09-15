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
print("=== 5. 같은 플러그인 두 번 — identity dedup, 표시는 성공 후(2026-09-15 사용자 결정) ===")
do
	local m: any = Quad.New()
	local runs = 0
	local function counting(_self: any)
		runs += 1
		return { Counted = runs }
	end
	m:AddPlugin(counting):AddPlugin(counting)
	assert(runs == 1, "같은 pluginFn은 한 번만 실행돼야 함")
	assert(m.Counted == 1, "확장은 첫 설치 그대로")
	local other: any = Quad.New()
	other:AddPlugin(counting)
	assert(runs == 2, "다른 모듈 인스턴스엔 따로 설치된다")

	local failing = true
	local function flaky(_self: any)
		if failing then
			error("install exploded", 0)
		end
		return { Flaky = true }
	end
	local m2: any = Quad.New()
	assert(not pcall(function()
		m2:AddPlugin(flaky)
	end), "던지는 플러그인은 에러를 전파")
	failing = false
	m2:AddPlugin(flaky)
	assert(m2.Flaky == true, "실패한 설치는 표시되지 않아 재시도가 완주한다")
	print("PASS")
end

print()
print("=== 6. debug 층 — 모르는 옵션 키는 경고만 하고 실행은 계속(2026-09-15 사용자 결정) ===")
do
	local m: any = Quad.New()
	m.debug = true
	print("(아래 unknown option 경고 셋은 의도된 출력이다 — print 캡처가 안 돼 육안 확인)")
	local gate = m.Debounce({ Time = 0.3, leading = true })
	assert(gate ~= nil, "Debounce: 오타 키가 있어도 만들어진다")
	local throttle = m.Throttle({ Time = 0.3, trailing = false })
	assert(throttle ~= nil, "Throttle: 오타 키가 있어도 만들어진다")
	local slot = m.Slot():List({}, function(_ctx: any)
		return nil
	end, nil, { Owned = false })
	assert(slot._owned ~= false, "옛 키 Owned는 무시되고 기본값(소유)으로 남는다")
	local quiet: any = Quad.New()
	local s2 = quiet.Slot():List({}, function(_ctx: any)
		return nil
	end, nil, { OwnsElements = false })
	assert(s2._owned == false, "OwnsElements = false는 그대로 먹는다(debug 꺼짐 — 출력 없음)")
	print("PASS")
end

print()
print("=== ALL PASS ===")
