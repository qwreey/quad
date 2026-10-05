--!strict
--[[
	StoryKit — the one adapter between UI Labs "Generic" stories and quad (https://ui-labs.luau.page/docs/stories/advanced/generic).

	The idea it demonstrates: **the UI Labs control panel IS a set of Sources.** Every control value becomes a
	`q.Source`; UI Labs' `subscribe` callback only `:SetIfChanged`s those Sources, and the component is written
	exactly as an app would write it (`Label = c.Label`, `Disabled = c.Disabled`) — no story-specific code paths,
	no re-render. Cleanup is `q.dispose` on what the story mounted, nothing else.

		local StoryKit = require("./StoryKit")
		return StoryKit.story({
			controls = { Label = "Save", Disabled = false, Variant = StoryKit.Choose({ "Filled", "Tonal" }) },
			render = function(c, ctx)
				return Material.Button({ Label = c.Label, Disabled = c.Disabled, Variant = c.Variant })
			end,
		})

	StoryKit.rebuild(c.Variant, function(v) return Material.Button({ Variant = v, … }) end) — for props a component
	takes as a plain value: a `Slot:Single` over the control's Source rebuilds that part when the control changes.

	render(c, ctx) receives:
	  c     — { [controlName]: Source<any> } (one Source per control, seeded with the control's starting value)
	  ctx   — { Target = props.target, Overlay = a fresh Overlay whose layer is mounted in the target }
	and returns the root Instance (StoryKit parents it into the target). Pass `Overlay = ctx.Overlay` to anything
	that opens popups so they draw inside the story view.

	Input: UI Labs runs stories in a plugin widget where `UserInputService` gets no input. StoryKit reads UI Labs'
	injected environment (the raw global `__hotreload_env_global_injection__` — the same lookup the optional
	ui-labs-utils package performs; no third-party code is vendored) and installs its `InputListener` through the
	kit's `Input.use`, restoring the engine service on cleanup. Outside UI Labs (the Lune specs) the environment is
	absent and nothing is installed.

	Controls: literal values (string/number/boolean/Color3) are UI Labs primitive controls. `StoryKit.Slider` and
	`StoryKit.Choose` build UI Labs advanced-control objects as plain tables — the data shape ui-labs-utils builds
	(`EntryType = "Control"`, `Type`, `ControlValue`, …). That shape is not part of the documented API; if a UI Labs
	update changes it, these two helpers are the only place to fix.
]]

local q = require("../src/Quad")
local Input = require("../src/Input")
local Overlay = require("../src/Overlay")

export type Controls = { [string]: any }
export type Sources = { [string]: q.Source<any> }
export type Context = {
	Target: Instance,
	Overlay: Overlay.Overlay,
}
export type Spec = {
	controls: Controls?,
	render: (c: Sources, ctx: Context) -> Instance,
}
-- what UI Labs calls `render` with (Generic story props)
export type Props = {
	target: Instance,
	controls: { [string]: any },
	converted: any,
	subscribe: (listener: (values: { [string]: any }, infos: { [string]: any }?) -> ()) -> () -> (),
}
export type Story = {
	controls: Controls,
	render: (props: Props) -> () -> (),
}

local INJECTION_KEY = "__hotreload_env_global_injection__"

local StoryKit = {}

-- UI Labs advanced controls as plain data (see header)
function StoryKit.Slider(def: number, min: number, max: number, step: number?): any
	return { EntryType = "Control", Type = "Slider", ControlValue = def, Min = min, Max = max, Step = step }
end

function StoryKit.Choose(list: { any }, index: number?): any
	local i = index or 1
	return { EntryType = "Control", Type = "Choose", ControlValue = list[i], List = list, DefIndex = i }
end

-- Some props are plain values on purpose (e.g. Button `Variant`, chosen once at construction). For those, the story
-- rebuilds that part when the control changes — the quad way, a `Slot:Single` over the control's Source, so the old
-- element is disposed by its owner and nothing is re-parented by hand.
-- The host defaults to full width, height following the content (`AutomaticSize = Y`), so it works inside list
-- layouts; pass `Size`/`AutomaticSize`/`LayoutOrder` for another shape. Callers write T explicitly when T is a
-- table type (`StoryKit.rebuild<<Look>>(look, …)` — quad's generic-State inference limit).
export type RebuildOptions = {
	read Size: UDim2?,
	read AutomaticSize: Enum.AutomaticSize?,
	read LayoutOrder: number?,
}
function StoryKit.rebuild<T>(key: q.State<T>, build: (value: T) -> Instance, options: RebuildOptions?): Frame
	local slot = q.Slot<<Instance>>()
	slot:Single<<T, nil>>(key, function(ctx): (Instance?, nil)
		return build(ctx.Item :: T), nil
	end)
	local o: RebuildOptions = options or {}
	return q.Declaration.Frame({
		Name = "Rebuild",
		BackgroundTransparency = 1,
		Size = o.Size or UDim2.fromScale(1, 0),
		AutomaticSize = o.AutomaticSize or Enum.AutomaticSize.Y,
		LayoutOrder = o.LayoutOrder or 0,
		slot,
	})
end

-- UI Labs' injected story environment, or nil outside UI Labs
local function environment(): any?
	local ok, env = pcall(getfenv, 1)
	if not ok or type(env) ~= "table" then
		return nil
	end
	return (env :: any)[INJECTION_KEY]
end

function StoryKit.story(spec: Spec): Story
	return {
		controls = spec.controls or {},
		render = function(props: Props): () -> ()
			local env = environment()
			local listener = if env ~= nil then env.InputListener else nil
			if listener ~= nil then
				Input.use(listener)
			end

			local sources: Sources = {}
			for name, value in props.controls do
				sources[name] = q.Source(value)
			end

			local overlay = Overlay.new()
			local root = spec.render(sources, { Target = props.target, Overlay = overlay })
			root.Parent = props.target
			overlay.Layer.Parent = props.target

			-- the control panel writes the Sources; nothing else reacts to UI Labs
			local unsubscribe = props.subscribe(function(values: { [string]: any }, infos: { [string]: any }?)
				for name, source in sources do
					local info = if infos ~= nil then infos[name] else nil
					local new = if info ~= nil then info.__new else values[name]
					source:SetIfChanged(new)
				end
			end)

			return function()
				unsubscribe()
				q.dispose(root)
				q.dispose(overlay.Layer)
				if listener ~= nil then
					Input.use(nil)
				end
			end
		end,
	}
end

return StoryKit
