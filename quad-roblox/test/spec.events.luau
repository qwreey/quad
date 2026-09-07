--!nocheck
--[[
	M10 엔진 축 둘째 단위(2026-09-03) — `Handlers/Event.luau`(문자열 키 +
	`GetEventsOfClass` 리플렉션, self 미전달, `None`/`nil`이면 Connect 안 함)와
	`Handlers/OnChange.luau`(`OnChange(name, fn)` 배열부 디스크립터 —
	2026-09-03 역전 — + `GetPropertyChangedSignal` 바인딩, 초기값 발화 계약).
	정본: `base/event-plan.md` 두 절, `base/onchange-plan.md` "확정" 절,
	`bind-system-plan.md` "인스턴스 생성 / 이벤트 네이밍 인체공학" 절.

	CLI 실주행 심(spec.handlers 관용구): `getfenv(install).game`에 mock의
	`gameShim` — Property 심(디스크립터 배열)과 이벤트 심(`mock.declareEvents`
	한 레지스트리에서 `inst[name]` 시그널과 `GetEventsOfClass` 둘 다). 실물
	RBXScriptSignal/Reflection 회귀는 Studio 실측(`audit/m10-events-studio-*`).
]]

local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local installProperty = require("../src/Handlers/Property")
local installEvent = require("../src/Handlers/Event")
local mock = require("../../quad-base/test/mock")

local SPEC_FILE = "spec.events.luau"

local W = { Write = "" }
local REFLECTED = {
	TextButton = {
		{ Name = "Name", Permits = W },
		{ Name = "Text", Permits = W },
		{ Name = "Visible", Permits = W },
	},
	Frame = {
		{ Name = "Name", Permits = W },
		{ Name = "Visible", Permits = W },
	},
}
mock.declareEvents("TextButton", { "MouseButton1Click", "Activated" })
mock.declareEvents("Frame", { "MouseEnter" })
local gameShim = mock.gameShim(REFLECTED)

local q = Quad.New():UseProvider(QuadRoblox)
;(getfenv(installProperty)).game = gameShim
;(getfenv(installEvent)).game = gameShim
;(getfenv(q.D.New)).Instance = { new = mock.Instance.new }
q.isInst = mock.isMockInstance
q.errorNamespace.setFuncLevel(q.isInst, require("../luau_packages/quad_types").ERROR_LEVEL_SURFACE)

-- 살아있는 연결 수(mock Signal 내부 — 관측 전용). mock의 Disconnect/
-- DisconnectAll이 끊긴 항목을 배열에서 바로 빼므로 길이가 곧 생존 수다.
local function liveConnections(sig)
	return #sig.connections
end

print("=== 1. Event — 리플렉션 매치로 Connect, 엔진 인자만 그대로(self 없음) ===")
do
	local got = nil
	local b = q.D.TextButton({
		Name = "Btn",
		Activated = function(...)
			got = { n = select("#", ...), ... }
		end,
	})
	assert(b.Name == "Btn", "sibling property still assigned (Property/Event sets disjoint)")
	b.Activated:Fire("inputObject", 2)
	assert(got and got.n == 2 and got[1] == "inputObject" and got[2] == 2, "callback received exactly the engine args — no self prepended")
	print("PASS")
end

print()
print("=== 2. 클래스별 판별 — 다른 클래스의 이벤트 이름은 매치 안 됨(no-match error, 사용자 blame) ===")
do
	local ok, err = pcall(function()
		q.D.Frame({ MouseButton1Click = function() end })
	end)
	assert(not ok, "MouseButton1Click is not a Frame event")
	mock.assertBlamesUser(err, SPEC_FILE, "foreign event key")
	print("PASS")
end

print()
print("=== 3. Event store-bind — None으로 끄면 Connect 안 함(nil 매치), 다시 켜면 재연결 ===")
do
	local calls = 0
	local src = q.Source(function()
		calls += 1
	end)
	local b = q.D.TextButton({ MouseButton1Click = src })
	local sig = b.MouseButton1Click
	assert(liveConnections(sig) == 1, "reactive callback connected once")
	sig:Fire()
	assert(calls == 1, "reactive callback fired")

	src:Set(q.None) -- NoneHandler → nil 재귀 → EventHandler(v == nil)
	assert(liveConnections(sig) == 0, "None disconnected and did NOT plant a new connection")
	sig:Fire()
	assert(calls == 1, "nothing runs while off (and no nil-call crash)")

	src:Set(function()
		calls += 10
	end)
	assert(liveConnections(sig) == 1, "re-enabled: exactly one live connection")
	sig:Fire()
	assert(calls == 11, "the NEW callback runs, the old one is gone")

	-- 평문 교체(디스패치 직접) — 옛 연결은 끊기고 하나만 남는다
	q.Dispatch.process(b, "MouseButton1Click", function()
		calls += 100
	end, 1)
	assert(liveConnections(sig) == 1, "plain replacement keeps a single connection")
	sig:Fire()
	assert(calls == 111, "replacement callback runs alone")
	-- 철거
	q.Dispatch.retractFrom(b, "MouseButton1Click", 1)
	assert(liveConnections(sig) == 0, "retraction disconnects")
	print("PASS")
end

print()
print("=== 4. OnChange — 배열부 디스크립터, 초기값 발화 계약(배열→해시 순서), 같은 이름 둘 ===")
do
	local OnChange = q.OnChange
	local seen = {}
	local seen2 = {}
	local b = q.D.TextButton({
		Text = "a", -- 해시 파트 — 배열부의 Connect 뒤에 대입되므로 초기값도 콜백에 닿는다(계약)
		OnChange("Text", function(v)
			table.insert(seen, v)
		end),
		OnChange("Text", function(v)
			table.insert(seen2, v)
		end),
	})
	assert(#seen == 1 and seen[1] == "a", "initial-value firing: the same props' property write reaches the callback (array before hash)")
	assert(#seen2 == 1 and seen2[1] == "a", "same name twice — both bound (no silent last-wins)")
	b.Text = "b"
	assert(#seen == 2 and seen[2] == "b" and #seen2 == 2, "later changes reach both")
	b.Name = "x"
	assert(#seen == 2, "other properties do not trigger it")
	-- 길이 0 말단: 형제 자식 오프셋에 기여하지 않는다(H-39)
	assert(q.Dispatch.getOffsetAt(b, 3) == 0, "descriptors contribute length 0")

	local d = OnChange("Text", function() end)
	assert(d.Name == "Text" and type(d.Callback) == "function", "descriptor shape { Name, Callback }")
	assert(OnChange("Text", function() end) ~= d, "no cache — every call is a fresh value")
	local ok, err = pcall(function()
		return OnChange(42, function() end)
	end)
	assert(not ok, "non-string name rejected")
	mock.assertBlamesUser(err, SPEC_FILE, "OnChange(42)")
	local ok2, err2 = pcall(function()
		return OnChange("Text", "nope")
	end)
	assert(not ok2, "non-function callback rejected")
	mock.assertBlamesUser(err2, SPEC_FILE, "OnChange(name, non-fn)")
	print("PASS")
end

print()
print("=== 5. OnChange store-bind — State<디스크립터> 교체·None으로 끄기·재연결·철거 ===")
do
	local calls = 0
	local src = q.Source(q.OnChange("Text", function()
		calls += 1
	end))
	local b = q.D.TextButton({ src })
	local sig = b:GetPropertyChangedSignal("Text")
	assert(liveConnections(sig) == 1, "connected once through StoreBind unwrap")
	b.Text = "b"
	assert(calls == 1, "reactive descriptor fired")

	src:Set(q.None) -- NoneHandler → nil → NilHandler(길이 0) — OnChange 핸들러엔 안 닿는다
	assert(liveConnections(sig) == 0, "None disconnects, nothing new connected")
	b.Text = "c"
	assert(calls == 1, "off: nothing runs, nothing crashes")

	src:Set(q.OnChange("Text", function()
		calls += 10
	end))
	b.Text = "d"
	assert(calls == 11 and liveConnections(sig) == 1, "re-enabled with a single connection")

	q.Dispatch.retractFrom(b, 1, 1)
	assert(liveConnections(sig) == 0, "retraction disconnects")
	print("PASS")
end

print()
print("=== 6. 교대 — 같은 이벤트 자리의 평문/State 교체가 연결을 하나로 유지, OnChange 팩토리는 quad 간 공유 ===")
do
	local b = q.D.TextButton({ MouseButton1Click = function() end })
	local sig = b.MouseButton1Click
	local src = q.Source(function() end)
	q.Dispatch.process(b, "MouseButton1Click", src, 1) -- 평문 → State
	assert(liveConnections(sig) == 1, "plain → reactive keeps one connection")
	src:Set(function() end) -- 같은 자리 재발행: Disconnect+Connect 1회(churn 허용, dedup 없음)
	assert(liveConnections(sig) == 1, "re-emission keeps one connection")

	local q2 = Quad.New():UseProvider(QuadRoblox)
	assert(q2.OnChange == q.OnChange, "module-level factory shared across quad instances")
	print("PASS")
end

print("=== 7. round3 H-440 (외부 리뷰 G-10, H-417 짝) — OnChange(\"\", fn)은 생성자에서 거부(엔진 GetPropertyChangedSignal에 디스패치 깊이로 닿던 것) ===")
do
	local ok, err = pcall(function()
		return q.OnChange("", function() end)
	end)
	assert(not ok and string.find(tostring(err), "must be a non-empty string", 1, true) ~= nil, "empty name rejected: " .. tostring(err))
	mock.assertBlamesUser(err, "spec.events.luau", "OnChange empty-name blame")
	print("PASS")
end

print()
print("=== ALL PASS ===")
