-- module name : handling rojo tree changes

if false then if not task then _G.task = {} end end
---@class tracker_rojo
local module = {}
module.__index = module

module.scheduleDelay = 0.1

function module:__emit(eventName,...)
	for _,func in ipairs(self.events[eventName]) do
		func(...)
	end
end

function module:__update()
	-- do updates
	self:__emit("updated")
end

function module:__scheduleUpdate()
	-- already timer setted
	if self.__onTimer then return end

	self.__onTimer = true
	task.delay(self.scheduleDelay,function ()
		self.__onTimer = false
		self:__update()
	end)
end

function module:__track(ins)
	self.connections[ins] = ins.Changed:Connect(function ()
		self:__scheduleUpdate()
	end)
end

function module:__drop(ins)
	local signal = self.connections[ins]
	if type(signal) == "table" then
		for _,v in pairs(signal) do
			v:Disconnect()
		end
		self.connections[ins] = nil
	elseif signal then
		signal:Disconnect()
		self.connections[ins] = nil
	end
end

function module:init()
	local mainConnections = {}
	self.connections[self.main] = mainConnections

	mainConnections[1] = self.main.DescendantAdded:Connect(function (ins)
		self:__track(ins)
		self:__scheduleUpdate()
	end)

	for _,ins in pairs(self.main:GetDescendants()) do
		self:__track(ins)
	end

	mainConnections[2] = self.main.DescendantRemoving:Connect(function (ins)
		self:__drop(ins)
		self:__scheduleUpdate()
	end)

	self:__track(self.main)
	mainConnections[3] = self.main.Destroying:Connect(function ()
		self:__drop(self.main)
	end)
	self:__scheduleUpdate()

	return self
end

function module:connect(eventName,func)
	table.insert(self.events[eventName],func)
end

function module:deinit()
	for i,signal in pairs(self.connections) do
		if type(signal) == "table" then
			for _,v in pairs(signal) do
				signal:Disconnect()
			end
			self.connections[i] = nil
		elseif signal then
			signal:Disconnect()
			self.connections[i] = nil
		end
	end
end

---@return tracker_rojo
function module.new(ins)
	local this = {
		main = ins,
		connections = {},
		events = {
			updated = {},
		},
		__onTimer = false,
	}

	setmetatable(this,module)
	return this
end

return module
