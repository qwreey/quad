--!strict
--[[
	GlobalInput — the kit's long-lived global input connections (internal, not exported from init.luau).

		local off = GlobalInput.connect(Input.service(), "InputBegan", fn)   -- returns the disconnect function
		GlobalInput.rebind(service)                                         -- Input.use calls this

	Why: a connection made on `Input.service()` stays on THAT service, and `Input.use` swaps the service at run time (a
	story host installs its listener, or restores the engine service at cleanup, while windows are open). Every
	connection that outlives one gesture is listed here and re-made on the new service. Short-lived ones (a drag between
	press and release, a popup's Escape listener) connect directly.

	Input requires this module (not the other way round), so the service is passed in.
]]

type Sub = { Signal: string, Fn: (...any) -> (), Conn: RBXScriptConnection? }

local GlobalInput = {}

local subs: { [Sub]: true } = {}

function GlobalInput.connect(service: any, signal: string, fn: (...any) -> ()): () -> ()
	local sub: Sub = { Signal = signal, Fn = fn, Conn = service[signal]:Connect(fn) }
	subs[sub] = true
	return function()
		if subs[sub] == nil then
			return
		end
		subs[sub] = nil
		local c = sub.Conn
		sub.Conn = nil
		if c then
			c:Disconnect()
		end
	end
end

function GlobalInput.rebind(service: any)
	for sub in subs do
		local c = sub.Conn
		if c then
			c:Disconnect()
		end
		sub.Conn = service[sub.Signal]:Connect(sub.Fn)
	end
end

return GlobalInput
