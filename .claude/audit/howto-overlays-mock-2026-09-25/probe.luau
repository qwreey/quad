--!nocheck
--[[
	how-to 09 신설(모달과 토스트) — mock 검증 스크래치. docs-review 2-4 브리프의 5핵심을 CLI로 확인한다.
	하네스는 spec.component.luau/spec.timers.luau 관용구(mock.gameShim + REFLECTED + 가상 시계)를 그대로 쓴다.
	실행 뒤 `.claude/audit/howto-overlays-mock-2026-09-25/`로 옮기고 test 폴더엔 남기지 않는다(브리프 지시).
]]

local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local installProperty = require("../src/Handlers/Property")
local installEvent = require("../src/Handlers/Event")
local mock = require("../../quad-base/test/mock")

local W = { Write = "" }
local REFLECTED: { [string]: { any } } = {
	Frame = {
		{ Name = "Name", Permits = W },
		{ Name = "Size", Permits = W },
		{ Name = "Visible", Permits = W },
		{ Name = "BackgroundTransparency", Permits = W },
	},
	TextLabel = {
		{ Name = "Name", Permits = W },
		{ Name = "Text", Permits = W },
		{ Name = "Visible", Permits = W },
	},
	TextButton = {
		{ Name = "Name", Permits = W },
		{ Name = "Text", Permits = W },
	},
}
mock.declareEvents("TextButton", { "Activated" })
local gameShim = mock.gameShim(REFLECTED)

local q: any = Quad.New():UseProvider(QuadRoblox)
;(getfenv(installProperty) :: any).game = gameShim
;(getfenv(installEvent) :: any).game = gameShim
;(getfenv(q.Declaration.New) :: any).Instance = { new = mock.Instance.new }
q.Backend.isInst = mock.isMockInstance

local D, None = q.Declaration, q.None

-- 문서 코드가 그대로 참조하는 `task` 전역 — 가상 시계(quad 내부 EngineOps와 무관, 유저 코드가 직접 부른다).
local vqueue: { { at: number, thread: thread } } = {}
local vclock = 0
task = {
	delay = function(delay: number, fn: () -> ()): thread
		local th = coroutine.create(fn)
		table.insert(vqueue, { at = vclock + delay, thread = th })
		return th
	end,
	cancel = function(th: thread)
		if coroutine.status(th) ~= "dead" then
			coroutine.close(th)
		end
	end,
}
local function advance(dt: number)
	local target = vclock + dt
	while true do
		local best, bi = nil, 0
		for i, t in vqueue do
			if t.at <= target and (best == nil or t.at < best.at) then
				best, bi = t, i
			end
		end
		if best == nil then
			break
		end
		table.remove(vqueue, bi)
		vclock = best.at
		if coroutine.status(best.thread) ~= "dead" then
			assert(coroutine.resume(best.thread))
		end
	end
	vclock = target
end

print("=== (a) open Source -> Visible 바인딩 ===")
do
	local open = q.Source(false)
	local modal = D.Frame({ Visible = open })
	assert(modal.Visible == false, "starts closed")
	open:Set(true)
	assert(modal.Visible == true, "Visible follows :Set(true)")
	open:Set(false)
	assert(modal.Visible == false, "Visible follows :Set(false)")
	print("PASS")
end

print()
print("=== (b) 조건부 자식 — State<Instance?>가 nil<->인스턴스로 붙고 떨어짐 ===")
do
	local cur = q.Source(nil :: any)
	local host = D.Frame({ D.TextLabel({ Text = "머리" }), cur })
	assert(#host:GetChildren() == 1, "empty slot starts with no child")
	local a = D.TextLabel({ Text = "A" })
	cur:Set(a)
	assert(#host:GetChildren() == 2 and host:GetChildren()[2] == a, "a attached")
	local bInst = D.TextLabel({ Text = "B" })
	cur:Set(bInst)
	assert(#host:GetChildren() == 2 and host:GetChildren()[2] == bInst, "swapped to b")
	assert(a.Parent == nil, "old element (a) detached, not destroyed")
	assert(not mock.isDestroyed(a), "a survives (dispose ownership stays with caller)")
	cur:Set(nil)
	assert(#host:GetChildren() == 1, "cleared back to just the head label")
	print("PASS")
end

print()
print("=== (c) Slot:List 토스트 — push로 늘고, 가상 시계로 task.delay 만료 뒤 줄어듦 ===")
do
	local toasts = q.Source({} :: { { Id: number, Text: string } })
	local toastList = q.Slot()
	toastList:List(toasts, function(ctx)
		if ctx.Item == q.KeyGone then
			return nil, ctx.UserData
		end
		if ctx.Prev then
			return ctx.Prev, ctx.UserData
		end
		return D.TextLabel({ Text = ctx.Item.Text }), ctx.UserData
	end, function(item)
		return item.Id
	end)
	local toastHost = D.Frame({ toastList })
	assert(#toastHost:GetChildren() == 0, "no toasts yet")

	local nextToastId = 0
	local function pushToast(text: string)
		nextToastId += 1
		local id = nextToastId
		local next_ = table.clone(toasts:Get())
		table.insert(next_, { Id = id, Text = text })
		toasts:Set(next_)
		task.delay(3, function()
			local kept = {}
			for _, item in toasts:Get() do
				if item.Id ~= id then
					table.insert(kept, item)
				end
			end
			toasts:Set(kept)
		end)
	end

	pushToast("첫 번째")
	assert(#toastHost:GetChildren() == 1, "one toast mounted")
	advance(1)
	pushToast("두 번째")
	assert(#toastHost:GetChildren() == 2, "two toasts mounted")
	advance(2.1) -- t=3.1: first toast's 3s timer has fired, second's (started at t=1) has not
	assert(#toastHost:GetChildren() == 1, "first toast expired and was removed")
	assert(toastHost:GetChildren()[1].Text == "두 번째", "remaining toast is the second one")
	advance(1) -- t=4.1: second toast's timer (fires at t=4) has now fired
	assert(#toastHost:GetChildren() == 0, "second toast expired too")
	print("PASS")
end

print()
print("=== (d) Context — 깊은 곳에서 open Source를 꺼내 연다 ===")
do
	type ModalBag = { Open: any }
	local ModalProvider = q.Context.Provider("Modal")
	local open = q.Source(false)
	local ctx = q.Context():Set(ModalProvider, { Open = open } :: ModalBag)

	-- 중간 레이어를 흉내: DeepPanel은 Ctx를 안 열고 그대로 한 층 더 내려보낸다
	local function DeepButton(props: { Ctx: any }): any
		local modal = props.Ctx:Get(ModalProvider)
		return D.TextButton({
			Text = "삭제",
			Activated = function()
				modal.Open:Set(true)
			end,
		})
	end
	local btn = DeepButton({ Ctx = ctx })
	assert(open:Get() == false, "closed before click")
	btn.Activated:Fire()
	assert(open:Get() == true, "deep trigger opened the root's Source through the bag")
	print("PASS")
end

print()
print("=== (e) Fallback — 던진 컴포넌트를 잡아 errorState를 채우고 자리표시 값을 돌려준다 ===")
do
	local function Card(props: { Text: string }): any
		if props.Text == "" then
			error("Card: Text must not be empty")
		end
		return D.TextLabel({ Text = props.Text })
	end

	local errorState = q.Source(nil :: any)
	local function onError(err: any): any
		errorState:Set(err)
		return D.Frame({})
	end
	local SafeCard = q.Fallback(Card, onError)

	local ok1 = SafeCard({ Text = "안녕" })
	assert(ok1.ClassName == "TextLabel" and ok1.Text == "안녕", "success path passes through untouched")
	assert(errorState:Get() == nil, "no error recorded on success")

	local ok2 = SafeCard({ Text = "" })
	assert(ok2.ClassName == "Frame", "thrown path returns the placeholder Frame")
	assert(errorState:Get() ~= nil and string.find(tostring(errorState:Get()), "Text must not be empty", 1, true) ~= nil, "errorState captured the thrown message")

	-- ErrorModal이 errorState를 받아 여닫히는 모양
	local reported: any = nil
	local function ErrorModal(props: { Error: any, OnReport: (any) -> (), OnConfirm: () -> () }): any
		return D.Frame({
			Visible = props.Error:Compute(function(e)
				return e:Get() ~= nil
			end),
		})
	end
	local modal = ErrorModal({
		Error = errorState,
		OnReport = function(err) reported = err end,
		OnConfirm = function() errorState:Set(nil) end,
	})
	assert(modal.Visible == true, "ErrorModal opened because errorState is non-nil")
	errorState:Set(nil)
	assert(modal.Visible == false, "ErrorModal closes once errorState is cleared")
	print("PASS")
end

print()
print("=== 전부 통과 ===")
