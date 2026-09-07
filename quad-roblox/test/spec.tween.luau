--!strict
--[[
	Tween 값 계약 (M11 단위 ①, round19; [2026-09-07] quad-base/test에서 이곳으로 — Tween은
	quad-roblox의 값, `base/tween-plan.md` "패키지 경계" 절) — "확정: `Tween{...}`
	최종 모양"(옵션 모양·`Override` 두 값)·"`Tween<T>:Mapped(fn)`"(clone + Value
	교체). 검증 범위는 brief §0 Q5 (a): 테이블·`Value` 필수·스칼라 타입·`Override` 센티널.
	엔진 타입(`Info`/`Style`/`Direction`)은 무검사(단위 ② PropertyHandler가 엔진에
	넘긴다). 소비(3-상태 슬롯·override 정책)는 단위 ② `spec.tweenproperty`.
	`q.Tween`/`q.isTween`은 프로바이더 확장(`RobloxExtension`)으로 실린다.
]]

local QuadBase = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local Types = require("../src/types")
local QuadTypes = require("../luau_packages/quad_types")
local mock = require("../../quad-base/test/mock")
local Quad = QuadBase.New():UseProvider(QuadRoblox)
local Tween = Quad.Tween

-- 타입 양성(strict — 본문 실행 없음): 생성자 제네릭 추론, `Mapped`의 U 전환,
-- 센티널 타입, `TweenData<T>` 자리(D 유니언 멤버)에 Tween 값이 들어간다
local function _types()
	local a: Types.Tween<number> = Tween({ Value = 1, Time = 0.3, Override = "Finish" })
	local b: Types.Tween<string> = a:Mapped(function(v: number): string
		return tostring(v)
	end)
	local c: Types.TweenData<string> = b
	local d: Types.TweenOverride = "Cancel"
	local e: number = a.Value
	return c, d, e
end

print("=== 1. 생성 — 브랜드·마커·frozen·옵션 보존·호출자 테이블 비-aliasing ===")
do
	local opts = { Value = 5, Time = 0.3, Reverses = true }
	local t = Tween(opts)
	assert(Quad.isTween(t), "brand")
	assert((t :: any).__quadTween == true, "H-300 marker readable")
	assert(t.Value == 5 and t.Time == 0.3 and t.Reverses == true, "options preserved")
	assert(t.Override == nil, "Override absent = default (Cancel is applied by the consumer)")
	assert(not pcall(function()
		(t :: any).Value = 9
	end), "frozen")
	opts.Value = 7
	assert(t.Value == 5, "caller's table is cloned, not aliased")
	assert(not Quad.isTween({ Value = 1 }), "a plain table is not a Tween")
	assert(not Quad.isTag(t) and not Quad.isModifier(t) and not Quad.isState(t), "brand is exclusive")
	print("PASS")
end

print()
print("=== 2. Override — 문자열 싱글톤 \"Cancel\"/\"Finish\"(H-343), Tween은 순수 함수 ===")
do
	assert(type(Tween) == "function", "Tween is a plain function — no namespace fields")
	local t = Tween({ Value = 1, Override = "Finish" })
	assert(t.Override == "Finish", "Override stored as the string")
	assert(Tween({ Value = 1 }).Override == nil, "absent = default (Cancel applied by the consumer)")
	print("PASS")
end

print()
print("=== 3. 검증 — 테이블·Value 필수·스칼라 타입·Override 멤버십, blame은 사용자 줄 ===")
do
	local cases: { { any } } = {
		{ 5, "expected an options table" },
		{ {}, "Value is required" },
		{ { Value = 1, Time = "0.3" }, "Time must be a number" },
		{ { Value = 1, RepeatCount = true }, "RepeatCount must be a number" },
		{ { Value = 1, DelayTime = {} }, "DelayTime must be a number" },
		{ { Value = 1, Reverses = 1 }, "Reverses must be a boolean" },
		{ { Value = 1, Override = "cancel" }, 'Override must be "Cancel" or "Finish"' },
	}
	for _, case in cases do
		local ok, err = pcall(function()
			return Tween(case[1])
		end)
		assert(not ok, "must reject: " .. tostring(case[2]))
		assert(string.find(tostring(err), case[2], 1, true) ~= nil, "message: " .. tostring(err))
		mock.assertBlamesUser(err, "spec.tween.luau", "validation blame")
	end
	-- 엔진 타입 자리는 무검사(Q5 (a)) — 엔진이 없는 CLI에선 아무 값이나 통과
	local t = Tween(({ Value = 1, Info = "not a TweenInfo", Style = 3 } :: any))
	assert((t :: any).Info == "not a TweenInfo" and (t :: any).Style == 3, "engine-typed fields pass through unchecked")
	print("PASS")
end

print()
print("=== 4. Mapped — 원본 불변·옵션 보존·Value만 교체·재검증·재브랜드 ===")
do
	local base = Tween({ Value = 4, Time = 0.15, Override = "Finish" })
	local mapped = base:Mapped(function(v: number): string
		return "v" .. v
	end)
	assert(mapped ~= base and base.Value == 4, "original untouched")
	assert(mapped.Value == "v4" and mapped.Time == 0.15 and mapped.Override == "Finish", "only Value replaced")
	assert(Quad.isTween(mapped) and table.isfrozen(mapped :: any), "result is a branded frozen Tween")
	local ok, err = pcall(function()
		return base:Mapped(function(_v: number): nil
			return nil
		end)
	end)
	assert(not ok and string.find(tostring(err), "Value is required", 1, true) ~= nil, "fn returning nil re-validates: " .. tostring(err))
	local ok2, err2 = pcall(function()
		return (base :: any):Mapped(5)
	end)
	assert(not ok2 and string.find(tostring(err2), "Tween:Mapped: fn must be a function (got number)", 1, true) ~= nil, "non-function rejected")
	mock.assertBlamesUser(err2, "spec.tween.luau", "Mapped blame")
	-- 상수 Tween 재사용 패턴(정본 "부수 효과")
	local FAST = Tween({ Value = 0, Time = 0.15 })
	local a, b = FAST:Mapped(function() return 10 end), FAST:Mapped(function() return 20 end)
	assert(a.Value == 10 and b.Value == 20 and a.Time == 0.15 and b.Time == 0.15, "reusable option preset")
	print("PASS")
end

print()
print("=== 5. 경계 — StoreBind는 Tween을 언랩하지 않는다(값 그대로 도착), Source 안의 Tween ===")
do
	local q = mock.newQuad()
	local src = q.Source(Tween({ Value = 1 }))
	assert(Quad.isTween(src:Get()), "a Tween inside a Source is a plain payload")
	local got: any = nil
	q.Dispatch.addHandler({
		name = "TweenProbe",
		isHandlable = function(_inst: any, k: any, v: any): boolean
			return k == "Probe"
		end,
		priority = q.Dispatch.HANDLER_PRIORITY_NORMAL,
		process = function(_inst: any, _k: any, v: any, _index: number): (any?, boolean) -> ()
			got = v
			return q.Void
		end,
	} :: QuadTypes.Handler)
	local inst = mock.Instance.new("Frame")
	q.Dispatch.drive(inst, { Probe = src })
	assert(got ~= nil and Quad.isTween(got) and got.Value == 1, "StoreBind unwrapped the Source and delivered the Tween value intact")
	print("PASS")
end

print("=== 6. 회신 3차 Q16 (b) — Tween{ Value = State }는 생성 시점에 거부(모든 필드는 plain — tween-plan 불변식), 사용자 줄 blame ===")
do
	-- the Source must come from the SAME quad-base copy the provider was installed on:
	-- `mock.newQuad()` builds on `quad-base/src`, `Quad` on the relinked `luau_packages`
	-- copy — two module files, two brand sets, so a Source from the other copy is not
	-- `isState` here (harness artifact of the relink, not a quad behaviour)
	local ok, err = pcall(function()
		return Tween({ Value = Quad.Source(1) })
	end)
	assert(not ok and string.find(tostring(err), "Value must be a plain value, not a State", 1, true) ~= nil, "State value rejected: " .. tostring(err))
	mock.assertBlamesUser(err, "spec.tween.luau", "Tween State value blame")
	assert(Quad.isTween(Tween({ Value = 1 })), "plain value untouched")
	-- `H-463`: the other two non-plain quad values — None and a nested Tween — same gate, same blame
	local okN, errN = pcall(function()
		return Tween({ Value = Quad.None })
	end)
	assert(not okN and string.find(tostring(errN), "not None or another Tween", 1, true) ~= nil, "None value rejected: " .. tostring(errN))
	mock.assertBlamesUser(errN, "spec.tween.luau", "Tween None value blame")
	local okT, errT = pcall(function()
		return Tween({ Value = Tween({ Value = 5 }) })
	end)
	assert(not okT and string.find(tostring(errT), "not None or another Tween", 1, true) ~= nil, "nested Tween rejected: " .. tostring(errT))
	mock.assertBlamesUser(errT, "spec.tween.luau", "Tween nested value blame")
	print("PASS")
end

print()
print("=== ALL PASS ===")
