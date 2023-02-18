
local module = {}

local running = coroutine.running
local resume = coroutine.resume
local yield = coroutine.yield
local insert = table.insert
local remove = table.remove

function module.init(shared)
	---@class quad_module_signal
	local new = {}
	local warn = shared.warn

	-- roblox connections disconnecter
	local disconnecters = {}
	new.disconnecters = disconnecters
	local disconnecterClass = {__type = "quad_disconnecter"}
	disconnecterClass.__index = disconnecterClass
	function disconnecterClass:Add(connection)
		insert(self,connection)
	end
	function disconnecterClass:Disconnect()
		for i,v in pairs(self) do
			pcall(v.Disconnect,v)
			self[i] = nil
		end
	end
	function disconnecterClass:Destroy()
		local id = self.id
		if id then
			disconnecters[id] = nil
		end
		for i,v in pairs(self) do
			pcall(v.Disconnect,v)
			self[i] = nil
		end
	end
	function disconnecterClass.New(id)
		if id then
			local old = disconnecters[id];
			if old then
				return old;
			end
		end
		local this = setmetatable({id = id},disconnecterClass);
		if id then
			disconnecters[id] = this;
		end
		return this;
	end
	new.Disconnecter = disconnecterClass

	local connection = {}
	connection.__index = connection
	function connection.New(signal,func)
		return setmetatable({signal = signal,func = func},connection)
	end
	function connection:Disconnect(slient)
		local signal = self.signal
		local onceConnection = signal.onceConnection
		local connection = signal.connection

		for i,v in pairs(connection) do
			if v.connection == self then
				remove(connection,i)
				return
			end
		end
		for i,v in pairs(onceConnection) do
			if v.connection == self then
				remove(onceConnection,i)
				return
			end
		end

		if not slient then
			warn(("Connection %s is not found from signal %s, but tried :Disconnect(). Maybe disconnected aleady?"):format(tostring(self),tostring(signal)))
		end
	end
	function connection:Destroy()
		return self:Disconnect(true)
	end
	new.Connection = connection

	local signals = {}
	local signal = {}
	signal.__index = signal
	function signal:Fire(...)
		local waitting = self.waitting
		local onceConnection = self.onceConnection
		self.waitting = {}
		self.onceConnection = {}

		for _,v in pairs(waitting) do
			task.spawn(resume,v,...)
		end

		for _,v in pairs(self.connection) do
			task.spawn(v.func,...)
		end

		for _,v in pairs(onceConnection) do
			task.spawn(v.func,...)
		end
	end
	function signal:Wait()
		insert(self.waitting,running())
		return yield()
	end
	function signal:CheckConnected(func)
		local onceConnection = self.onceConnection
		local connection = self.connection
		for _,v in pairs(connection) do
			if v.func == func then
				return true
			end
		end
		for _,v in pairs(onceConnection) do
			if v.func == func then
				return true
			end
		end
		return false
	end
	function signal:Connect(func)
		if self:CheckConnected(func) then
			warn(("[Quad] Function %s Connected already on signal %s"):format(tostring(func),tostring(self)))
		end
		local thisConnection = connection.New(self,func)
		insert(self.connection,{func=func,connection=thisConnection})
		return thisConnection
	end
	function signal:Once(func)
		if self:CheckConnected(func) then
			warn(("[Quad] Function %s Connected already on signal %s"):format(tostring(func),tostring(self)))
		end
		local thisConnection = connection.New(self,func)
		insert(self.onceConnection,{func=func,connection=thisConnection})
		return thisConnection
	end
	function signal:Destroy()
		self.waitting = nil
		self.onceConnection = nil
		self.connection = nil
		setmetatable(self,nil)
	end
	function signal.New(id)
		if id and signals[id] then
			return signals[id]
		end
		local this = {waitting={},onceConnection={},connection={}}
		setmetatable(this,signal)
		if id then
			signals[id] = this
		end
		return this
	end
	new.Bindable = signal

	return new
end

return module

