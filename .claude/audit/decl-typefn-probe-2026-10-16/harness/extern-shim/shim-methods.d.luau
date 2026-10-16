-- Same as shim.d.luau but with `function` METHOD declarations — reproduces
-- "'Build' type function errored at runtime: … unsupported type pack type" when Lib calls
-- conn:parameters() on the extern's Connect (luau-lsp 1.70.1 and 1.69.0, 2026-10-16).
declare extern type ProbeSignal with
	function Connect(self, callback: (number, string) -> ()): RBXScriptConnection
	function Once(self, callback: (number, string) -> ()): RBXScriptConnection
end

declare extern type ProbeButton extends GuiButton with
	Clicked: ProbeSignal
	Label: string
end
