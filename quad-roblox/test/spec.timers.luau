--[[
	quad-roblox 시간 op 배선 — `.claude/base/debounce-throttle-plan.md` 6절: `setTimeout(func, delay)` →
	`task.delay(delay, func)`(인자 순서 반대), `clearTimeout(t)` → `task.cancel(t._native)`, `Timeout` 마커.
	CLI 실주행 심: `getfenv(EngineOps install).task`(spec.tagattribute의 `game` 심과 같은 자리).
	Debounce 위에서 한 번 끝까지 돌려 base 슈거가 이 배선으로 동작하는 것도 본다.
]]

local Quad = require("../luau_packages/quad_base")
local QuadTypes = require("../luau_packages/quad_types")
local QuadRoblox = require("../src").QuadRoblox
local installEngineOps = require("../src/EngineOps")

type State<T> = QuadTypes.State<T>
type Probe = { count: number, _receive: (self: Probe, from: any) -> () }

-- fake scheduler: `delay` records (delay, thread) in order; `run(dt)` resumes the threads
-- whose delay elapsed (virtual clock, like mock.advanceTime)
local queue: { { at: number, thread: thread } } = {}
local clock = 0
local log: { string } = {}
local taskShim = {
	delay = function(delay: number, fn: () -> ()): thread
		local th = coroutine.create(fn)
		queue[#queue + 1] = { at = clock + delay, thread = th }
		log[#log + 1] = `delay({delay})`
		return th
	end,
	cancel = function(th: thread)
		-- Studio 2026-09-08 실측: a dead thread is a silent no-op for `task.cancel`
		if coroutine.status(th) ~= "dead" then
			coroutine.close(th)
		end
		log[#log + 1] = "cancel"
	end,
}
local function run(dt: number)
	local target = clock + dt
	while true do
		local best, bi = nil, 0
		for i, t in queue do
			if t.at <= target and (best == nil or t.at < best.at) then
				best, bi = t, i
			end
		end
		if best == nil then
			break
		end
		table.remove(queue, bi)
		clock = best.at
		if coroutine.status(best.thread) ~= "dead" then
			assert(coroutine.resume(best.thread))
		end
	end
	clock = target
end

;(getfenv(installEngineOps) :: any).task = taskShim

local q = Quad.New():UseProvider(QuadRoblox)

print("=== 1. setTimeout — 인자 순서 뒤집어 task.delay로; Timeout 마커; 게이트(함수/음수) ===")
do
	local fired = 0
	local t = q.setTimeout(function()
		fired += 1
	end, 0.5)
	assert((t :: any).__quadTimeout == true and type((t :: any)._native) == "thread", "Timeout shape")
	assert(log[#log] == "delay(0.5)", "task.delay(delay, fn) — flipped")
	run(0.49)
	assert(fired == 0, "not yet")
	run(0.01)
	assert(fired == 1, "fired at 0.5")
	local ok, err = pcall(function()
		return q.setTimeout(5 :: any, 1)
	end)
	assert(not ok and string.find(tostring(err), "setTimeout: func must be a function", 1, true), tostring(err))
	ok, err = pcall(function()
		return q.setTimeout(function() end, -1)
	end)
	assert(not ok and string.find(tostring(err), "delay must be a non%-negative"), tostring(err))
	print("PASS")
end

print()
print("=== 2. clearTimeout — task.cancel; 이미 발화한 핸들도 그냥 넘긴다(dead thread cancel은 무해 — Studio 실측); 마커 없는 값 거부 ===")
do
	local fired = 0
	local t = q.setTimeout(function()
		fired += 1
	end, 1)
	q.clearTimeout(t)
	assert(log[#log] == "cancel", "cancelled")
	run(2)
	assert(fired == 0, "never fires")
	local t2 = q.setTimeout(function()
		fired += 1
	end, 1)
	run(1)
	assert(fired == 1, "fired")
	q.clearTimeout(t2) -- late clear on a fired handle: passes through to task.cancel (harmless — Studio 실측)
	assert(log[#log] == "cancel", "late clear forwarded")
	local ok, err = pcall(function()
		q.clearTimeout({} :: any)
	end)
	assert(not ok and string.find(tostring(err), "clearTimeout: expected a Timeout", 1, true), tostring(err))
	print("PASS")
end

print()
print("=== 3. Debounce 끝까지 — base 슈거가 이 배선 위에서 돈다(Time 0.3, 신호 둘 → 0.3 뒤 1회) ===")
do
	local s = q.Source(0)
	local g: State<number> = s:Apply(q.Debounce({ Time = 0.3 }))
	local p = { count = 0 } :: Probe
	function p._receive(self: Probe, _from: any)
		self.count += 1
	end
	;(g :: any)._subs[p] = true
	s:Set(1)
	s:Set(2)
	assert(p.count == 0 and g:Get() == 2, "withheld")
	run(0.3)
	assert(p.count == 1, "passed once")
	run(1)
	assert(#queue == 0, "no timer left")
	print("PASS")
end

print()
print("ALL PASS")
