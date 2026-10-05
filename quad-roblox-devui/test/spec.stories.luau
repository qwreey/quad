--!strict
--[[
	Every UI Labs story in `../stories` (`*.story.luau`) is rendered the way UI Labs' Generic mounter does it — fake
	`target`, the controls' starting values, a fake `subscribe` — then every control is changed once through the
	subscribe listener (the "control panel writes Sources" path), time advances, and the story's cleanup runs.
	Asserted per story: no throw, no `q.debug` output, the target is EMPTY after cleanup (nothing leaked),
	the subscription was released, the injected input listener was installed while rendering and removed after,
	and global input connections / timers are back to baseline.

	UI Labs' injected environment is simulated with the same raw global UI Labs sets
	(`__hotreload_env_global_injection__`) — see `stories/StoryKit.luau`.
]]

local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
local Input = require("../src/Input")
q.debug = true

local lune = require :: any
local fs = lune("@lune/fs")

-- stories folder next to this test folder (absolute path of this file → kit root)
local here = debug.info(1, "s")
local kitRoot = string.match(here, "^(.*)/test/[^/]*$") :: string
local storyDir = kitRoot .. "/stories"

-- fake UI Labs InputListener, installed as the injected environment global
local listener = {
	InputBegan = H.mock.newSignal(),
	InputChanged = H.mock.newSignal(),
	InputEnded = H.mock.newSignal(),
	MouseMoved = H.mock.newSignal(),
}
;(_G :: any).__hotreload_env_global_injection__ = { InputListener = listener }
;(getfenv(1) :: any).__hotreload_env_global_injection__ = { InputListener = listener }

local function startValue(control: any): any
	if type(control) == "table" and control.EntryType == "Control" then
		return control.ControlValue
	end
	return control
end

local function changedValue(control: any, current: any): any
	if type(control) == "table" and control.EntryType == "Control" then
		if control.Type == "Choose" then
			return control.List[#control.List]
		elseif control.Type == "Slider" then
			return if current == control.Max then control.Min else control.Max
		end
		return current
	end
	local t = typeof(current)
	if t == "string" then
		return current .. "!"
	elseif t == "number" then
		return current + 1
	elseif t == "boolean" then
		return not current
	elseif t == "Color3" then
		return Color3.new(0.1, 0.6, 0.3)
	end
	return current
end

local function connections(signal: any): number
	return #signal.connections
end

local names: { string } = {}
for _, entry in fs.readDir(storyDir) do
	if string.match(entry, "%.story%.luau$") then
		table.insert(names, entry)
	end
end
table.sort(names)

H.section("stories exist", function()
	assert(#names > 0, "no *.story.luau found in " .. storyDir)
end)

for _, file in names do
	local moduleName = string.gsub(file, "%.luau$", "")
	H.section("story " .. moduleName, function()
		local baseBegan = connections(H.UserInputService.InputBegan)
		local baseChanged = connections(H.UserInputService.InputChanged)
		local baseEnded = connections(H.UserInputService.InputEnded)
		local timersBefore = H.pendingTimers()

		local story: any = lune("../stories/" .. moduleName)
		local renderKind: string = type(story) == "table" and type(story.render) or type(story)
		assert(renderKind == "function", "a Generic story (controls + render)")

		local controls = story.controls or {}
		local values: { [string]: any } = {}
		for name, control in controls do
			values[name] = startValue(control)
		end

		local target = H.mock.Instance.foreign("Frame")
		H.setAbs(target, 0, 0, 800, 600)
		local subscribed: ((any, any) -> ())? = nil
		local released = false
		local props = {
			target = target,
			controls = table.clone(values),
			converted = controls,
			subscribe = function(fn: (any, any) -> ()): () -> ()
				subscribed = fn
				return function()
					released = true
				end
			end,
		}

		local cleanup: any = story.render(props)
		local cleanupKind: string = type(cleanup)
		assert(cleanupKind == "function", "render returns a cleanup")
		assert(#target:GetChildren() > 0, "something was mounted into the target")
		assert(Input.isOverridden(), "the injected InputListener was installed")
		assert(subscribed ~= nil, "the story subscribed to control changes")

		-- the control panel changes every control once
		local infos: { [string]: any } = {}
		for name, control in controls do
			local old = values[name]
			local new = changedValue(control, old)
			values[name] = new
			infos[name] = { __old = old, __new = new }
		end
		;(subscribed :: any)(table.clone(values), infos)
		H.advance(0.5)
		H.finishTweens()
		H.advance(1)

		cleanup()
		H.advance(2)
		H.finishTweens()

		assert(released, "the subscription was released")
		assert(not Input.isOverridden(), "the engine input service was restored")
		assert(H.countDescendants(target) == 0, `target empty after cleanup (left {H.countDescendants(target)})`)
		assert(connections(H.UserInputService.InputBegan) == baseBegan, "InputBegan baseline")
		assert(connections(H.UserInputService.InputChanged) == baseChanged, "InputChanged baseline")
		assert(connections(H.UserInputService.InputEnded) == baseEnded, "InputEnded baseline")
		assert(connections(listener.InputBegan) == 0 and connections(listener.InputChanged) == 0, "listener connections released")
		assert(H.pendingTimers() <= timersBefore, "no timers left behind")
		H.assertNoDebugOutput(moduleName)
	end)
end

H.done()
