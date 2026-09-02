--[[
	The one shared error namespace (`H-231`, user-designed shape) — created
	here once at module scope, like the Brand instances: every quad-base file
	tags its public surface functions into THIS namespace and raises through
	it, and backends receive it as `Quad.errorNamespace` (never build one from
	their own quad-error copy — pesde gives each package its own copy of the
	util, so per-copy maps would silently split the tag space).

	Layer scheme (round12 `H-231`, user-confirmed): one layer for now —
	`ERROR_LEVEL_SURFACE` (quad-types): every public surface function + the
	handler functions `Dispatch.addHandler` receives. User-input and
	provider-contract errors raise `errorBeforeNearest(msg, SURFACE)` (the
	nearest enclosing surface's caller — a depth-proof level 2); errors that
	must climb wrappers to the user's entry (dispatch match failure) use
	`errorBefore(msg, SURFACE)` (outermost). Internal invariants stay plain
	`error(msg, 1)`.

	Like `Brand`, two coexisting quad-base copies get separate namespaces —
	the documented copy-split caveat applies as-is.
]]

local QuadError = require("../luau_packages/quad_error")

export type ErrorNamespace = QuadError.Namespace

return QuadError.new()
