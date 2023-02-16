
local function remove()
	local lastModule = _G.uilastmodule
	if lastModule then
		require(lastModule).deinit()
	end
end

local function reload()
	local lastModule = _G.uilastmodule
	if lastModule then
		local passed,module = pcall(require,lastModule)
		if passed then
			pcall(module.deinit)
			_G.uiloaded = false
		end
		lastModule:Destroy()
	end
	_G.uilastmodule = nil

	lastModule = script.Parent:Clone()
	lastModule.Archivable = false
	lastModule.Name = "testing_" .. lastModule.Name
	if lastModule:FindFirstChild("loader") then
		lastModule.loader.Disabled = true
	end
	lastModule.Parent = script.Parent.Parent
	_G.uilastmodule = lastModule

	local module = require(lastModule)
	if _G.uiloaded then
		pcall(module.deinit)
		_G.uiloaded = false
	end

	module.init()
	_G.uiloaded = true
end

return {
	track = function ()

		reload()

		if not _G.uichangetracker then
			local tracker =  require(script.tracker)
			local changeTracker = tracker.new(script.Parent)

			changeTracker:connect("updated",function ()
				reload()
			end)
			changeTracker:init()
			_G.uichangetracker = changeTracker
		end
	end,
	untrack = function ()
		_G.uichangetracker:deinit()
		_G.uichangetracker = nil
		remove()
	end
}



