--!strict
--[[
	TweenOptions — the option vocabulary `Tween(opts)` and `Animate(info)` share: one ordered list, so the
	debug "unknown option" lines and the per-field loops of both constructors cannot drift apart (adding an
	option used to mean editing five lists). `Value` is Tween's own and `CanAnimate` is Animate's own; the
	typed side of the same names is `types.luau` (`TweenOptions`/`AnimateInfo`). Ref: H-927
]]

-- every option both constructors accept, in the order the debug lines list them
local OPTION_FIELDS: { string } = table.freeze({
	"Info", "Time", "Style", "Direction", "RepeatCount", "Reverses", "DelayTime", "Override", "Dedup",
	"Started", "Completed", "Cancelled",
})

-- the callback subset — functions, never States (round13 Q115 (a))
local CALLBACK_FIELDS: { string } = table.freeze({ "Started", "Completed", "Cancelled" })

return table.freeze({
	OPTION_FIELDS = OPTION_FIELDS,
	CALLBACK_FIELDS = CALLBACK_FIELDS,
})
