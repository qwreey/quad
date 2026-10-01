local H = require("./probe_h")
local q, mock = H.q, H.mock
local Tween = q.Tween
-- One State fanned out to two properties; the callback (filtered to Size) re-sets the same State.
-- Does Position end at the inner (latest) value?
local function run(label: string, ev: string, setup: (src: any) -> ())
	mock.resetTweenLog()
	local src = q.Source(0 :: any)
	local f = q.Declaration.Frame({ Name = "F", Size = src, Position = src }) :: any
	local once = false
	local cb = function(_inst, prop, _v)
		if prop == "Size" and not once then
			once = true
			src:Set(Tween({ Value = 77, Time = 0.3 }))
		end
	end
	setup(src)
	local opts: any = { Value = 20, Time = 0.3 }
	opts[ev] = cb
	src:Set(Tween(opts))
	local tgt = {}
	for _, e in H.playing() do for k, v in e.props do tgt[k] = v end end
	print(`{label}: src={src:Get().Value} playing Size->{tostring(tgt.Size)} Position->{tostring(tgt.Position)}  (props now Size={tostring(f.Size)} Position={tostring(f.Position)})`)
end
run("B1 Started(engine)", "Started", function(src) src:Set(Tween({ Value = 10, Time = 0.3 })) end)
run("B2 snap Started(zero-time)", "Started", function(src) src:Set(Tween({ Value = 10, Time = 0.3 })) end)
-- B2 uses Time=0 instead
do
	mock.resetTweenLog()
	local src = q.Source(0 :: any)
	local f = q.Declaration.Frame({ Name = "F", Size = src, Position = src }) :: any
	local once = false
	src:Set(Tween({ Value = 20, Time = 0, Completed = function(_, prop) if prop == "Size" and not once then once = true; src:Set(Tween({ Value = 77, Time = 0 })) end end }))
	print(`B2' zero-time snap Completed (Time=0 both): src={src:Get().Value} Size={tostring(f.Size)} Position={tostring(f.Position)}`)
end
-- B3 Cancelled on replacement: the PREVIOUS tween carries the Cancelled
do
	mock.resetTweenLog()
	local src = q.Source(0 :: any)
	local f = q.Declaration.Frame({ Name = "F", Size = src, Position = src }) :: any
	local once = false
	src:Set(Tween({ Value = 10, Time = 0.3, Cancelled = function(_, prop) if prop == "Size" and not once then once = true; src:Set(Tween({ Value = 77, Time = 0.3 })) end end }))
	src:Set(Tween({ Value = 20, Time = 0.3 }))
	local tgt = {}
	for _, e in H.playing() do for k, v in e.props do tgt[k] = v end end
	print(`B3 Cancelled(replacement): src={src:Get().Value} playing Size->{tostring(tgt.Size)} Position->{tostring(tgt.Position)}`)
end
-- B4 window Completed on replacement
do
	mock.resetTweenLog()
	local src = q.Source(0 :: any)
	local f = q.Declaration.Frame({ Name = "F", Size = src, Position = src }) :: any
	local once = false
	src:Set(Tween({ Value = 10, Time = 0.3, Completed = function(_, prop) if prop == "Size" and not once then once = true; src:Set(Tween({ Value = 77, Time = 0.3 })) end end }))
	for _, e in H.log do e.tween.PlaybackState = "Completed"; e.inst[next(e.props)] = 10 end
	src:Set(Tween({ Value = 20, Time = 0.3 }))
	local tgt = {}
	for _, e in H.playing() do for k, v in e.props do tgt[k] = v end end
	print(`B4 window Completed(replacement): src={src:Get().Value} playing Size->{tostring(tgt.Size)} Position->{tostring(tgt.Position)}`)
end
-- B5 engine Completed (async) — control
do
	mock.resetTweenLog()
	local src = q.Source(0 :: any)
	local f = q.Declaration.Frame({ Name = "F", Size = src, Position = src }) :: any
	local once = false
	src:Set(Tween({ Value = 10, Time = 0.3, Completed = function(_, prop) if prop == "Size" and not once then once = true; src:Set(Tween({ Value = 77, Time = 0.3 })) end end }))
	H.finish(H.log[1].tween)
	local tgt = {}
	for _, e in H.playing() do for k, v in e.props do tgt[k] = v end end
	print(`B5 engine Completed(async, control): src={src:Get().Value} playing Size->{tostring(tgt.Size)} Position->{tostring(tgt.Position)}`)
end
-- B6 Animate state fanned out, Started re-sets the underlying Source
do
	mock.resetTweenLog()
	local src = q.Source(0 :: any)
	local once = false
	local st = src:Apply(q.Animate({ Time = 0.3, Started = function(_, prop) if prop == "Size" and not once then once = true; src:Set(77) end end }))
	local f = q.Declaration.Frame({ Name = "F", Size = st, Position = st }) :: any
	src:Set(20)
	local tgt = {}
	for _, e in H.playing() do for k, v in e.props do tgt[k] = v end end
	print(`B6 Animate fan-out Started -> src:Set(77): src={src:Get()} playing Size->{tostring(tgt.Size)} Position->{tostring(tgt.Position)} props Size={f.Size} Position={f.Position}`)
end
