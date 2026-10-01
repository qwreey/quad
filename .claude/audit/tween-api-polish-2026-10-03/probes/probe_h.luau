-- shared probe harness (copied from spec.tweenproperty header)
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
		{ Name = "Position", Permits = W },
		{ Name = "BackgroundTransparency", Permits = W },
		{ Name = "Visible", Permits = W },
		{ Name = "Rotation", Permits = W },
	},
	UICorner = { { Name = "Name", Permits = W }, { Name = "CornerRadius", Permits = W } },
	UIPadding = {
		{ Name = "Name", Permits = W },
		{ Name = "PaddingLeft", Permits = W }, { Name = "PaddingRight", Permits = W },
		{ Name = "PaddingTop", Permits = W }, { Name = "PaddingBottom", Permits = W },
	},
	UIScale = { { Name = "Name", Permits = W }, { Name = "Scale", Permits = W } },
}
local gameShim = mock.gameShim(REFLECTED)
local q: any = Quad.New():UseProvider(QuadRoblox)
;(getfenv(installProperty) :: any).game = gameShim
;(getfenv(installProperty) :: any).TweenInfo = mock.tweenInfoShim
;(getfenv(installProperty) :: any).Enum = { EasingStyle = { Quad = "Quad" }, EasingDirection = { Out = "Out" }, PlaybackState = { Completed = "Completed", Cancelled = "Cancelled" } }
;(getfenv(installEvent) :: any).game = gameShim
;(getfenv(q.Declaration.New) :: any).Instance = { new = mock.Instance.new }
q.Backend.isInst = mock.isMockInstance

local H = {}
H.q = q
H.mock = mock
H.log = mock.tweenLog
function H.last(): any
	local log = mock.tweenLog
	return log[#log] and log[#log].tween
end
H.seen = {} :: { string }
function H.mk(tag: string, ev: string): any
	return function(inst: any, prop: string, v: any)
		table.insert(H.seen, `{tag}:{ev}({inst and inst.Name},{prop},{tostring(v)})`)
	end
end
function H.tw(tag: string, value: any, extra: any?): any
	local opts: any = { Value = value, Time = 0.3, Started = H.mk(tag, "S"), Completed = H.mk(tag, "C"), Cancelled = H.mk(tag, "X") }
	if extra then for k2, v2 in extra do opts[k2] = v2 end end
	return q.Tween(opts)
end
function H.take(): string
	local s = table.concat(H.seen, " ")
	table.clear(H.seen)
	return s
end
-- engine natural finish: write the target like the engine does, then fire
function H.finish(t: any)
	for k, v in t.PropertyTable do
		local inst = t.Instance
		if inst then inst[k] = v end
	end
	t:simulateCompleted()
end
function H.playing(): { any }
	local out = {}
	for _, e in mock.tweenLog do
		if e.tween.PlaybackState == "Playing" then table.insert(out, e) end
	end
	return out
end
function H.playingStr(): string
	local out = {}
	for _, e in H.playing() do
		for k, v in e.props do table.insert(out, `{e.inst.Name}.{k}->{tostring(v)}`) end
	end
	return table.concat(out, ",")
end
return H
