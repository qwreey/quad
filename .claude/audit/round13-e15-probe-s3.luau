--!nocheck
-- round13 E15 S3 — how-to 09 overlays: Visible modal + Context trigger, conditional modal (State<Instance?>) with
-- dispose in its own callback, module-scope toast Slot:List + task.delay removal, Fallback -> ErrorModal.
local H = require("./round13-e15-probe-setup")
local q, D, mock, try, track, alive = H.q, H.D, H.mock, H.try, H.track, H.alive
local task = H.task
local None = q.None
local log = {}
local function L(s) table.insert(log, s) end
local function flush(label) print(label, table.concat(log, " | ")); table.clear(log) end

local function Modal(props)
	return D.Frame {
		Name = "Modal", Visible = props.Open,
		q.OnDestroyed(function() L("modal destroyed " .. props.Title) end),
		D.TextLabel { Text = props.Title },
		props.Children or None,
		D.TextButton { Name = "OK", Text = "ok", Activated = function() props.Open:Set(false); props.OnConfirm() end },
		D.TextButton { Name = "Cancel", Text = "cancel", Activated = function() props.Open:Set(false); props.OnCancel() end },
	}
end
local ModalProvider = q.Context.Provider("Modal")
local function DeleteButton(props)
	local modal = props.Ctx:Get(ModalProvider)
	return D.TextButton { Name = "Delete", Text = "del", Activated = function() modal.Open:Set(true) end }
end
local function DeepPanel(props) return D.Frame { Name = "Deep", D.Frame { DeleteButton { Ctx = props.Ctx } } } end

-- toast (how-to 09 §4, module scope)
local toasts = q.Source({})
local toastList = q.Slot()
local built = 0
local function Card(props)
	if props.Text == "" then error("Card: Text must not be empty") end
	return D.TextLabel { Text = props.Text }
end
local errorState = q.Source(nil)
local SafeCard = q.Fallback(Card, function(err) errorState:Set(err); return D.Frame { Name = "placeholder" } end)
toastList:List(toasts, function(ctx)
	if ctx.Item == q.KeyGone then return nil, ctx.UserData end
	if ctx.Prev then return ctx.Prev, ctx.UserData end
	built += 1
	return SafeCard { Text = ctx.Item.Text }, ctx.UserData
end, function(item) return item.Id end)
local nextToastId = 0
local function pushToast(text)
	nextToastId += 1
	local id = nextToastId
	local nxt = table.clone(toasts:Get())
	table.insert(nxt, { Id = id, Text = text })
	toasts:Set(nxt)
	task.delay(3, function()
		local kept = {}
		for _, item in toasts:Get() do if item.Id ~= id then table.insert(kept, item) end end
		toasts:Set(kept)
	end)
end
local function ErrorModal(props)
	local visible = props.Error:Compute(function(e) return e:Get() ~= nil end)
	local text = props.Error:Compute(function(e) local v = e:Get(); return if v == nil then "" else tostring(v) end)
	return D.Frame { Name = "ErrorModal", Visible = visible, D.TextLabel { Name = "Msg", Text = text },
		D.TextButton { Name = "OK", Text = "ok", Activated = function() props.OnConfirm() end } }
end

print("== S3a normal ==")
local open = q.Source(false)
local ctx = q.Context():Set(ModalProvider, { Open = open })
local toastHost = D.Frame { Name = "Toasts", toastList }
local screen = D.ScreenGui {
	DeepPanel { Ctx = ctx },
	Modal { Open = open, Title = "confirm", OnConfirm = function() L("confirmed") end, OnCancel = function() L("cancel") end },
	toastHost,
	ErrorModal { Error = errorState, OnConfirm = function() errorState:Set(nil) end },
}
local del = screen:FindFirstChild("Deep"):GetChildren()[1]:FindFirstChild("Delete")
local modal = screen:FindFirstChild("Modal")
print("modal visible", modal.Visible); del.Activated:Fire(); print("after delete click visible", modal.Visible)
modal:FindFirstChild("OK").Activated:Fire(); print("after OK visible", modal.Visible); flush("log")
pushToast("hello"); pushToast("world")
print("toasts", #toastHost:GetChildren(), "built", built)
H.run(1); pushToast("third"); H.run(2.1)
print("after 3.1s toasts", #toastHost:GetChildren())
pushToast("") -- Card throws -> Fallback placeholder + errorState
local em = screen:FindFirstChild("ErrorModal")
print("after throwing toast: children", #toastHost:GetChildren(), "placeholder?", toastHost:FindFirstChild("placeholder") ~= nil, "ErrorModal visible", em.Visible, "msg", em:FindFirstChild("Msg").Text:sub(1, 60))
em:FindFirstChild("OK").Activated:Fire(); print("error modal visible after OK", em.Visible)
H.run(3.1); print("after expiry toasts", #toastHost:GetChildren())

print("== S3c provider replaced after build: trigger captured the old bag value ==")
local open2 = q.Source(false)
ctx:Set(ModalProvider, { Open = open2 })
del.Activated:Fire()
print("old modal visible", modal.Visible, "open2", open2:Get(), "(read-once: DeleteButton holds the old bag value)")
modal:FindFirstChild("Cancel").Activated:Fire()

print("== S3c2 conditional modal: close + dispose from inside its own Activated ==")
local activeModal = q.Source(nil)
local slotHost = D.Frame { Name = "CondHost", activeModal }
local function openConfirm(withDispose)
	local m
	m = Modal { Open = q.Source(true), Title = "cond", OnConfirm = function()
		activeModal:Set(nil)
		if withDispose then q.dispose(m) end
	end, OnCancel = function() activeModal:Set(nil) end }
	track("S3.condModal", m)
	activeModal:Set(m)
	return m
end
local m1 = openConfirm(true)
try("OK click (Set nil + dispose self inside handler)", function() m1:FindFirstChild("OK").Activated:Fire() end)
print("m1 destroyed", mock.isDestroyed(m1), "host kids", #slotHost:GetChildren()); flush("log")
local m2 = openConfirm(false)
m2:FindFirstChild("Cancel").Activated:Fire()
print("m2 destroyed (no dispose)", mock.isDestroyed(m2), "parent", m2.Parent); flush("log")
-- reopen by setting the SAME demoted instance again
try("re-seat demoted m2", function() activeModal:Set(m2) end)
print("m2 parent after re-seat", m2.Parent and m2.Parent.Name)
-- swap directly m2 -> m3 without nil
local m3 = openConfirm(false)
print("m2 after swap parent", m2.Parent, "destroyed", mock.isDestroyed(m2))
try("dispose demoted m2", function() q.dispose(m2) end); flush("log")

print("== S3b teardown: destroy screen with toast timers pending; module-scope toastList reused in a new screen ==")
pushToast("a"); pushToast("b")
screen:Destroy()
flush("destroy log")
H.run(3.1)
print("toast data after timers", #toasts:Get(), "built", built)
try("push toast after host destroyed", function() pushToast("late") end)
print("built", built)
local host2
try("module-scope toastList into a new host (respawn rebuild)", function() host2 = D.Frame { toastList } end)
print("host2 kids", host2 and #host2:GetChildren())
H.run(3.1)
try("errorState:Set after ErrorModal destroyed", function() errorState:Set("x") end)
slotHost:Destroy()
flush("slotHost destroy log")
m1, m2, m3, modal, del, screen, toastHost, em = nil, nil, nil, nil, nil, nil, nil, nil
print("alive", alive("S3."))
