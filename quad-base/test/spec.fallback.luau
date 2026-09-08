--[[
	Fallback / Traceback 계약 — `.claude/base/fallback-plan.md` "API — 왜 둘로 나뉘는가"(pcall vs
	xpcall+traceback, `err: any` 무가공, trace는 항상 string), "메커니즘 스케치" 그대로. 배선 실측은
	`audit/fallback-xpcall-verification.md`.
]]

local Quad = require("../src")
local mock = require("./mock")

local SPEC_FILE = "spec.fallback.luau"
local Fallback, Traceback = Quad.Fallback, Quad.Traceback

print("=== 1. 인자 게이트 — base/onError는 함수(blame은 호출 줄) ===")
do
	local ok, err = pcall(function()
		return (Fallback :: any)(5, function() end)
	end)
	assert(not ok and string.find(tostring(err), "Fallback: base must be a function", 1, true), tostring(err))
	mock.assertBlamesUser(err, SPEC_FILE, "base")
	ok, err = pcall(function()
		return (Traceback :: any)(function() end, "x")
	end)
	assert(not ok and string.find(tostring(err), "Traceback: onError must be a function", 1, true), tostring(err))
	print("PASS")
end

print()
print("=== 2. Fallback — 정상이면 결과 그대로(인자 전달), 에러면 onError(err); err는 any(테이블도 손실 없이) ===")
do
	local function Widget(props: { n: number }): string
		if props.n < 0 then
			error({ code = props.n })
		end
		return `ok{props.n}`
	end
	local seen: any = nil
	local Safe = Fallback(Widget, function(err)
		seen = err
		return "placeholder"
	end)
	assert(Safe({ n = 1 }) == "ok1" and seen == nil, "pass-through")
	assert(Safe({ n = -2 }) == "placeholder" and type(seen) == "table" and seen.code == -2, "table error reaches onError intact")
	-- string error: Luau adds the position prefix (level 1) — NOT stripped here (plan caveat)
	local Safe2 = Fallback(function(): string
		error("boom")
	end, function(err: any): any
		return err
	end)
	local got = Safe2()
	assert(type(got) == "string" and string.find(got, "boom", 1, true) and string.find(got, SPEC_FILE, 1, true), `raw message kept: {got}`)
	-- level 0 → bare message
	local Safe3 = Fallback(function(): string
		error("bare", 0)
	end, function(err: any): any
		return err
	end)
	assert(Safe3() == "bare", "error(msg, 0) arrives bare")
	print("PASS")
end

print()
print("=== 3. Traceback — onError(err, trace); trace는 항상 string이고 던진 지점을 담는다; 정상 경로엔 비용 없음 ===")
do
	local function inner()
		error("deep")
	end
	local function Widget(): string
		inner()
		return "never"
	end
	local gotErr, gotTrace = nil, nil
	local Safe = Traceback(Widget, function(err, trace)
		gotErr, gotTrace = err, trace
		return "fallback"
	end)
	assert(Safe() == "fallback", "onError result returned")
	assert(type(gotErr) == "string" and string.find(gotErr, "deep", 1, true), "err")
	assert(type(gotTrace) == "string" and string.find(gotTrace, "inner", 1, true) ~= nil, `trace names the throw site: {tostring(gotTrace)}`)
	local calls = 0
	local Ok = Traceback(function(a: number, b: number): number
		calls += 1
		return a + b
	end, function(): number
		return -1
	end)
	assert(Ok(1, 2) == 3 and calls == 1, "normal path: args and result pass through")
	print("PASS")
end

print()
print("=== 4. 커링된 onError/중첩 — 바깥 Fallback이 안쪽 실패 컴포넌트의 placeholder를 그대로 받는다 ===")
do
	local function makeHandler(context: string)
		return function(err: any, trace: string): any
			return { context = context, err = err, hasTrace = type(trace) == "string" }
		end
	end
	local Broken = Traceback(function(): any
		error("inner")
	end, makeHandler("ctx"))
	local Parent = Fallback(function(): any
		return { child = Broken() }
	end, function(): any
		return "parent-placeholder"
	end)
	local r: any = Parent()
	assert(type(r) == "table" and r.child.context == "ctx" and r.child.hasTrace, "inner isolated, outer untouched")
	print("PASS")
end

print()
print("ALL PASS")
