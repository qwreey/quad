-- CLI-only definitions shim (2026-10-16): emulates Studio's shape for events — the signal is an
-- EXTERN type (Studio: `extern:RBXScriptSignal`, 2026-09-16 [P3-c]/[P6]) instead of the luau-lsp defs'
-- table-with-Connect. Lets the Linux run exercise Lib's extern branch of callbackOf().
-- ⚠ Members are written as function-typed PROPERTIES. Written as `function Connect(self, cb: …)` methods,
-- `conn:parameters()` inside a type function dies with "unsupported type pack type" (luau-lsp 1.70.1, 2026-10-16
-- run — kept as harness/extern-shim/shim-methods.d.luau). Studio's native extern signal did not hit that
-- (2026-09-16 [P6-5]: parameters() gave 2 entries).
declare extern type ProbeSignal with
	Connect: (self: ProbeSignal, callback: (number, string) -> ()) -> RBXScriptConnection
	Once: (self: ProbeSignal, callback: (number, string) -> ()) -> RBXScriptConnection
end

declare extern type ProbeButton extends GuiButton with
	Clicked: ProbeSignal
	Label: string
end
