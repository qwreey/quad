--!strict
--[[
	Every UI Labs story in `../stories` (`*.story.luau`) is rendered the way UI Labs' Generic mounter does it — fake
	`target`, the controls' starting values, a fake `subscribe` — then every control is changed once through the
	subscribe listener (the "control panel writes Sources" path), time advances, and the story's cleanup runs.
	Asserted per story: no throw, no `q.debug` output, the target is EMPTY after cleanup (nothing leaked),
	the subscription was released, the injected input listener was installed while rendering and removed after,
	and global input connections / timers are back to baseline.

	The stories are loaded the way UI Labs loads them (ui-labs@1e8f45f:src/Utils/HotReloader/Utils.ts `SetEnvironment`):
	each module under `stories/` is compiled from source and run in its OWN environment whose `require` is the
	loader's and whose globals fall back to an injection table holding `__hotreload_env_global_injection__` — the
	injection is NOT a real global, so a lookup that reads the thread's globals instead of the module's environment
	(`pcall(getfenv, 1)`, the 2026-10-08 bug) misses it, as it did in UI Labs. Paths outside `stories/` ("../src",
	"../gallery", quad) are ordinary requires (UI Labs loads those virtually too; one copy per environment either way).
	Last section: the Slider story dragged through the fake listener only — the engine service's signals stay unused.
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
local injection = setmetatable({ __hotreload_env_global_injection__ = { InputListener = listener } }, { __index = getfenv(1) })
assert((getfenv(1) :: any).__hotreload_env_global_injection__ == nil, "the injection is not a real global")

-- UI Labs' virtual require: `./X` from a story = stories/X.luau compiled into its own environment (cached per name);
-- anything else resolves from this folder, a sibling of `stories/` (so "../src" means the same folder)
local virtualCache: { [string]: any } = {}
local function virtualRequire(path: string): any
	if string.sub(path, 1, 2) ~= "./" then
		return lune(path)
	end
	local name = string.sub(path, 3)
	local cached = virtualCache[name]
	if cached ~= nil then
		return cached
	end
	-- loadstring + setfenv like UI Labs (Lune's `luau.load` copies the environment's own fields and drops its __index)
	local chunk, err = loadstring(fs.readFile(storyDir .. "/" .. name .. ".luau"), "stories/" .. name)
	assert(chunk ~= nil, err)
	setfenv(chunk, setmetatable({ require = virtualRequire }, { __index = injection }))
	local result = chunk()
	virtualCache[name] = result
	return result
end

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

		local story: any = virtualRequire("./" .. moduleName)
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

H.section("Slider story: a drag runs on the injected listener alone (UI Labs widget — the engine service gets nothing)", function()
	local baseChanged = connections(H.UserInputService.InputChanged)
	local baseEnded = connections(H.UserInputService.InputEnded)
	local story: any = virtualRequire("./Slider.story")
	local values: { [string]: any } = {}
	for name, control in story.controls do
		values[name] = startValue(control)
	end
	local target = H.mock.Instance.foreign("Frame")
	H.setAbs(target, 0, 0, 800, 600)
	local cleanup = story.render({
		target = target,
		controls = values,
		converted = story.controls,
		subscribe = function(_fn: any): () -> ()
			return function() end
		end,
	})
	assert(Input.isOverridden(), "the listener was installed")
	local slider = H.find(target, "Slider")
	assert(slider ~= nil, "the story's slider")
	local function label(prefix: string): string?
		local found = H.findAll(target, function(d: any): boolean
			return d.ClassName == "TextLabel" and string.sub(d.Text, 1, #prefix) == prefix
		end)
		return if found[1] ~= nil then found[1].Text else nil
	end
	assert(label("Value = ") == "Value = 30.00", tostring(label("Value = ")))
	-- the M3 handle inset is 6: a 200 px rail from x = 110
	H.setAbs(slider, 104, 50, 212, 40)
	H.fire(slider, "InputBegan", H.input({ Position = Vector3.new(110, 60, 0) }))
	assert(connections(H.UserInputService.InputChanged) == baseChanged, "the drag did not connect to the engine service")
	assert(connections(listener.InputChanged) == 1 and connections(listener.InputEnded) == 2, "drag + button tracking on the listener")
	listener.InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(210, 60, 0) }), false)
	H.advance(0.05)
	assert(label("Value = ") == "Value = 50.00", `moved: {label("Value = ")}`)
	listener.InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(310, 60, 0) }), false)
	listener.InputEnded:Fire(H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(310, 60, 0) }), false)
	H.advance(0.5)
	H.finishTweens()
	assert(label("Value = ") == "Value = 100.00", `released: {label("Value = ")}`)
	assert(label("Last drag ended at ") == "Last drag ended at 100", tostring(label("Last drag ended at ")))
	assert(connections(listener.InputChanged) == 0, "the drag released its listener connection")
	cleanup()
	H.advance(2)
	H.finishTweens()
	assert(not Input.isOverridden())
	assert(connections(H.UserInputService.InputChanged) == baseChanged and connections(H.UserInputService.InputEnded) == baseEnded)
	assert(H.countDescendants(target) == 0)
	H.assertNoDebugOutput("slider story drag")
end)

H.done()
