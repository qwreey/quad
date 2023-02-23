local module = {}
local pack = table.pack
local match = string.match
local insert = table.insert
local gsub = string.gsub

---@param shared quad_export
---@return quad_module_class
function module.init(shared)
	local warn = shared.warn
	---@class quad_module_class
	local new = {__type = "quad_module_class"}
	local InstanceNew = Instance.new
	local event = shared.Event ---@type quad_module_event
	local bind = event.Bind
	local store = shared.Store ---@type quad_module_store
	local initStoreRegisterBinding = store.__initStoreRegisterBinding
	local addObject = store.AddObject
	local storeNew = store.New
	local mount = shared.Mount ---@type quad_module_mount
	local getHolder = mount.GetHolder
	local mountfunc = mount.MountOne
	local style = shared.Style ---@type quad_module_style
	local styleList = style.Styles
	local parseStyles = style.ParseStyles
	local advancedTween = shared.Tween ---@type quad_module_tween
	local round = shared.Round ---@type quad_module_round
	local signal = shared.Signal ---@type quad_module_signal
	local bindable = signal.Bindable
	local PcallGetProperty = store.PcallGetProperty

	local function InstanceNewWithName(classname,parent,name)
		local item = InstanceNew(classname,parent)
		item.Name = name
		return item
	end

	local function GetProperty(item,index,ClassName)
		if type(item) == "table" then return item[index] end
		ClassName = ClassName or item.ClassName
		local isImage = (ClassName == "ImageLabel" or ClassName == "ImageButton")
		if (index == "RoundSize") and isImage then
			if not round then
				error("module 'round' needs to be loaded for get image round size but it is not found on 'src.libs'. you should adding that to src.libs directory")
			end
			return round.GetRound(item)
		elseif index == "Corner" then
			local target = (ClassName == "UICorner" and item) or item:FindFirstChildOfClass("UICorner")
			return (target and target.CornerRadius.Offset) or 0
		elseif index == "PaddingAll" then
			local target = (ClassName == "UIPadding" and item) or item:FindFirstChildOfClass("UIPadding")
			return (target and target.PaddingLeft) or UDim.new(0,0)
		elseif index == "PaddingAllOffset" then
			local target = (ClassName == "UIPadding" and item) or item:FindFirstChildOfClass("UIPadding")
			return (target and target.PaddingLeft.Offset) or 0
		elseif index == "Scale" then
			local target = (ClassName == "UIScale" and item) or item:FindFirstChildOfClass("UIScale")
			return (target and target.Scale) or 1
		end
		return item[index]
	end
	new.GetProperty = GetProperty

	local function SetProperty(item,index,value,ClassName)
		-- if it is not a roblox instance, just call __index
		if type(item) == "table" then
			item[index] = value
			return
		end

		-- check class name
		ClassName = ClassName or item.ClassName
		-- check is ImageLabel or ImageButton
		local isImage = (ClassName == "ImageLabel" or ClassName == "ImageButton")

		-- Round Image
		if index == "RoundSize" and isImage then
			if not round then
				error("[QUAD] module 'round' needs to be loaded for set image round size but it is not found on 'src.libs'. you should adding that to src.libs directory")
			end
			round.SetRound(item,value)
		-- UIRound
		elseif index == "Corner" then
			local uiCorner = (ClassName == "UICorner" and item) or item:FindFirstChildOfClass("UICorner") or InstanceNewWithName("UICorner",item,"_quad_round")
			uiCorner.CornerRadius = UDim.new(0,value)
		-- PaddingAll
		elseif index == "PaddingAll" then
			local target = (ClassName == "UIPadding" and item) or item:FindFirstChildOfClass("UIPadding") or InstanceNewWithName("UIPadding",item,"_quad_padding")
			target.PaddingLeft = value
			target.PaddingRight = value
			target.PaddingTop = value
			target.PaddingBottom = value
		-- PaddingAll with Offset
		elseif index == "PaddingAllOffset" then
			local target = (ClassName == "UIPadding" and item) or item:FindFirstChildOfClass("UIPadding") or InstanceNewWithName("UIPadding",item,"_quad_padding")
			local padding = UDim.new(0,value)
			target.PaddingLeft = padding
			target.PaddingRight = padding
			target.PaddingTop = padding
			target.PaddingBottom = padding
		-- Scale
		elseif index == "Scale" then
			local target = (ClassName == "UIScale" and item) or item:FindFirstChildOfClass("UIScale") or InstanceNewWithName("UIScale",item,"_quad_scale")
			target.Scale = value
		else
			-- other, just set property
			item[index] = value
		end
	end
	new.SetProperty = SetProperty

	local function Link(linker,item,index,indexType)
		local target = linker.target
		local name = linker.name
		if indexType == "number" then
			-- set
			-- if rawget(target,name) ~= nil then
			-- 	warn(("%s is exist already. Overwrite it"))
			-- end
			rawset(target,name,item)
			-- target[name] = item
		elseif indexType == "string" then
			local targetSignal = target:GetPropertyChangedSignal(name)
			local fire = PcallGetProperty(targetSignal,"Fire")
			local ok = fire and bind(item,index,function(...)
				fire(targetSignal,...)
			end,"function")
			if not ok then
				warn("Failed to bind linker event")
			end
		end
	end

	local function ProcessQuadProperty(processedProperty,iprop,holder,item,className,index,value)
		if processedProperty[index] then
			return
		end

		local valueType = typeof(value)
		local indexType = typeof(index)
		local quadType = valueType == "table" and PcallGetProperty(value,"__type")

		if quadType == "quad_linker" then
			-- linking
			Link(value,item,index,indexType)
		elseif indexType == "string" and quadType == "quad_register" then
			-- register (bind to store event)

			processedProperty[index] = true -- ignore next

			-- store reading
			do
				local setValue = value:CalcWithDefault(item)
				if setValue == nil then
					warn "[Quad] register return value must not be nil, but got nil. did you inited values before?"
				end
				SetProperty(item,index,setValue,className)
			end

			-- adding handle function (binding)
			local function regFn(_,newValue,key)
				local setValue,tween = value:CalcWithNewValue(item,newValue,key)
				if tween then
					if not advancedTween then
						return warn "[QUAD] module 'AdvancedTween' needs to be loaded for tween properties but it is not found on 'src.libs'. you should adding that to src.libs directory"
					end
					-- local ended, onStepped
					-- if tween.Ended then
					-- 	ended = function (...)
					-- 		tween.Ended(item,...)
					-- 	end
					-- end
					-- if tween.OnStepped then
					-- 	onStepped = function (...)
					-- 		tween.OnStepped(item,...)
					-- 	end
					-- end
					advancedTween.RunTween(item,tween,{[index] = setValue},nil,nil,SetProperty,GetProperty)
				else
					SetProperty(item,index,setValue,className)
				end
			end
			value:Register(regFn)

			-- this is using hacky of roblox instance
			-- this is will keep reference from week table until
			-- inscance got GCed
			item:GetPropertyChangedSignal("ClassName"):Connect(regFn)
		elseif (valueType == "function" or valueType == "table") and indexType == "string" and bind(item,index,value,valueType) then -- connect event
			-- event binding
		elseif indexType == "string" then
			processedProperty[index] = true -- ignore next
			-- prop set
			SetProperty(item,index,value,className)
		elseif indexType == "number" and valueType == "table" and quadType == "quad_style" then -- style
			-- style parsing
			for _,thisStyle in ipairs(parseStyles(value)) do
				if not processedProperty[thisStyle] then
					processedProperty[thisStyle] = true
					for styleIndex,styleValue in pairs(thisStyle) do
						if PcallGetProperty(styleValue,"__type") ~= "quad_style" then
							ProcessQuadProperty(processedProperty,iprop,holder,item,className,styleIndex,styleValue)
						end
					end
				end
			end
		elseif indexType == "number" and valueType ~= "boolean" then -- object
			-- child object
			if iprop ~= 1 then
				value = value:Clone()
			end
			mountfunc(item,value,holder,true)
		end
	end

	-- make object that from instance, class and more
	function new.Make(ClassName,...) -- render object
		-- make object from ClassName
		local item
		local classOfClassName = type(ClassName)
		if classOfClassName == "string" then -- if classname is a string value, cdall instance.new for making new roblox instance
			item = InstanceNew(ClassName)
		elseif classOfClassName == "function" then -- if classname is a function value, call it for making new object (OOP object)
			item = ClassName()
		elseif classOfClassName == "table" then -- if classname is a calss what is included new function, call it for making new object (object)
			local func = ClassName.new or ClassName.New or ClassName.__new
			if ClassName.__noSetup then -- if is support initing props
				local childs,props,parsed,binds,links,processed,styles = {},pack(...),{},{},{},{},{}
				for iprop = props.n,1,-1 do
					local prop = props[iprop]
					if prop then
						for i,v in pairs(prop) do
							local quadType = PcallGetProperty(v,"__type")
							if bind(i) then
								binds[i] = v
							elseif quadType == "quad_linker" then
								links[i] = v
							elseif quadType == "quad_style" then
								insert(styles,v)
							elseif type(i) == "number" then
								insert(childs,(iprop == 1) and v or v:Clone())
							else
								processed[i] = true
								parsed[i] = v
							end
						end
					end
				end
				for _,v in ipairs(styles) do
					for _,thisStyle in ipairs(parseStyles(v)) do
						for styleIndex,styleValue in pairs(thisStyle) do
							if not processed[styleIndex] then
								processed[styleIndex] = true
								parsed[styleIndex] = styleValue
							end
						end
					end
				end
				item = func(parsed)
				local holder = getHolder(item)
				for _,v in ipairs(childs) do
					mountfunc(item,v,holder)
				end
				for i,v in pairs(links) do
					Link(v,item,i,type(i))
				end
				for i,v in pairs(binds) do
					bind(item,i,v)
				end
				return item
			end
			item = func()
		end
		if not item then -- if cannot make new object, ignore this call
			local str = tostring(ClassName)
			warn(("[Quad] fail to make item '%s', did you forget to checking the class '%s' is exist?"):format(str,str))
		end

		-- set property and adding child and binding functions
		local holder = getHolder(item) -- to __holder or holder or it self (for tabled)
		-- for iprop,prop in ipairs({...}) do
		local propsListArray = pack(...)
		local processedProperty = {}
		for iprop = 1,propsListArray.n do
			local prop = propsListArray[iprop]
			if prop then
				local binding = {}
				-- set property
				for index,value in pairs(prop) do
					if bind(index) then
						binding[index] = value
					elseif type(index) ~= "number" then
						ProcessQuadProperty(processedProperty,iprop,holder,item,ClassName,index,value)
					end
				end
				-- childs
				for index,value in ipairs(prop) do
					ProcessQuadProperty(processedProperty,iprop,holder,item,ClassName,index,value)
				end
				-- bindings
				for index,value in pairs(binding) do
					bind(item,index,value)
				end
			end
		end
		return item
	end
	local make = new.Make

	-- import quad object
	function new.Import(ClassName,defaultProperties) -- make new quad class object
		if type(ClassName) == "userdata" and ClassName.ClassName == "ModuleScript" then
			ClassName = require(ClassName)
		end
		local this = defaultProperties or {}
		setmetatable(this,{
			__type = "quad_imported_class",
			__call = function (self,prop,...)
				local propType = type(prop)
				if propType == "string" then
					local lastName = prop
					return function (nprop,...)
						nprop = nprop or {}
						if not nprop.Name then
							nprop.Name = gsub(gsub(match(lastName,"[^,]+")," +$",""),"^ +","")
						end
						for styleName,styleObj in pairs(styleList) do
							if match(prop,styleName) then
								insert(nprop,styleObj)
							end
						end
						local item = make(ClassName,nprop,...,this)
						addObject(lastName,item)
						return item
					end
				elseif propType == "nil" then
					return make(ClassName,this)
				end
				return make(ClassName,prop,...,this)
			end
		})
		return this
	end

	-- set module calling function
	setmetatable(new,{
		__call = function (self,...)
			return new.Import(...)
		end
	})

	local function Linker(target,name)
		return {
			__type = "quad_linker";
			target = target;
			name = name;
		}
	end

	-- make class
	function new.Extend()
		local this = {__type = "quad_extend"}

		--- make new object
		function this.New(prop)
			-- make metatable
			prop = storeNew(prop,nil)
			local parent = prop and (prop.Parent or prop.parent)
			local self = {
				__prop = prop;
				__parent = parent;
				ChildAdded = signal.Bindable.New();
			}
			local init = this.Init
			if init then
				init(self,prop)
			end
			setmetatable(self,this)
			initStoreRegisterBinding(prop,self,self)

			-- render that
			local object = self:Render(prop)
			rawset(self,"__object",object)
			rawset(self,"__holder",object)
			if parent then
				rawset(self,"__parent",parent)
				mountfunc(self,parent)
			end
			-- prevent gc
			((type(object) == "table" and object.__object) or object)
			:GetPropertyChangedSignal "ClassName":Connect(function()
				return self
			end)

			--after render
			local afterRender = this.AfterRender
			if afterRender then
				afterRender(self,object,prop)
			end
			return self
		end

		function this:GetPropertyChangedSignal(propertyName)
			local propertySignalList = rawget(self,"__propertyChangedSignals")
			if not propertySignalList then
				propertySignalList = {}
				rawset(self,"__propertyChangedSignals",propertySignalList)
			end

			local thisSignal = propertySignalList[propertyName]
			if thisSignal then
				return thisSignal
			end
			thisSignal = bindable.New()
			propertySignalList[propertyName] = thisSignal
			return thisSignal
		end

		function this:EmitPropertyChangedSignal(propertyName,value)
			local propertySignalList = rawget(self,"__propertyChangedSignals")
			if not propertySignalList then
				return
			end

			local thisSignal = propertySignalList[propertyName]
			if not thisSignal then
				return
			end
			if not value then
				value = self[propertyName]
			end
			thisSignal:Fire(value)
		end

		function this:GetChildren()
			local children = rawget(self,"__child")
			if not children then
				return {}
			end
			local newChildren = {}
			for _,v in pairs(children) do
				insert(newChildren,v)
			end
			return newChildren
		end

		--- re-render object (if some props chaged, call this to render again)
		function this:Update() -- swap object
			local object = rawget(self,"__object") -- get last instance
			local parent = object and object.Parent -- date parent
			if not object then
				parent = rawget(self,"__parent")
			end
			local lastObject = object
			if lastObject then
				lastObject.Parent = nil
			end

			object = self:Render(self.__prop) -- new instance
			rawset(self,"__holder",object)
			rawset(self,"__object",object)
			object.Parent = getHolder(parent) -- update parent

			-- restore childs
			local child = rawget(self,"__child")
			if child then
				for _,v in pairs(child) do
					if v then
						v.Parent = object
					end
				end
			end

			-- prevnet gc
			((type(object) == "table" and object.__object) or object):GetPropertyChangedSignal "ClassName":Connect(function()
				return self
			end)
			if lastObject then -- remove old instance
				self:Destroy(lastObject)
			end

			--after render
			local afterRender = this.AfterRender
			if afterRender then
				afterRender(self,object)
			end
		end

		-- define destroy method
		function this:Destroy(object)
			local unload = this.Unload
			object = object or rawget(self,"__object")
			if object then
				if unload then
					unload(self,object)
				else
					local destroy = (object.Destroy or object.destroy)
					if destroy then
						pcall(destroy,object)
					end
				end
			end
			self = nil
		end

		--- link to new
		function this.__call(self,...)
			if self == this then
				return (self.new or self.New or self.__new)(...)
			end

			local name = select(1,...)
			if type(name) ~= "string" then
				error(("Name must be string, but got %s"):format(type(name)))
			end
			return Linker(self,name)
		end

		-- indexer (getter)
		function this:__index(k)
			local getter = this.Getter[k]
			if getter then
				return getter(self,rawget(self,"__object"))
			end

			-- from this (have more priority)
			local fromThis = this[k]
			if fromThis then
				return fromThis
			end

			-- from prop, not start with '_' (private value)
			if k:sub(1,1) ~= "_" then
				return self.__prop[k]
			end
		end

		--- new indexer (setter)
		function this:__newindex(k,v)
			-- from setter
			local setter = this.Setter[k]
			if setter then
				return setter(self,v,rawget(self,"__object"))
			end

			-- is private (self value)
			if k:sub(1,1) == "_" then
				return rawset(self,k,v)
			end

			-- prop update
			local lastValue = self[k]
			self.__prop[k] = v
			if this.UpdateTriggers[k] then
				self:Update()
			end

			-- call PropertyChangedSignal
			if lastValue ~= v then
				self:EmitPropertyChangedSignal(k,v)
			end
		end

		this.Getter = {
			Parent = function(self)
				return rawget(self,"__parent")
			end
		}
		this.Setter = {
			Parent = function(self,parent,object)
				rawset(self,"__parent",parent)
				if object then
					object.Parent = getHolder(parent)
				end
			end
		}
		this.UpdateTriggers = {}
		this.__noSetup = true
		return this
	end

	local function ApplyNewProps(Item,NewProps)
		local quadType = PcallGetProperty(Item, "__type")
		if quadType == "quad_extend" then
			local prop = Item.__prop
			local propKeep = prop.__keep
			local propTweens = prop.__tweens
			local propValues = prop.__self
			for index,value in pairs(NewProps) do
				-- if new value is register
				if PcallGetProperty(value,"__type") == "quad_register" then
					-- remove old register
					for keepIndex,keepValue in pairs(propKeep) do
						if type(keepValue) == "table" and PcallGetProperty(keepValue,"key") == index then
							keepValue.register:Unregister(keepValue.func)
							propKeep[keepIndex] = nil
						end
					end

					-- calc value
					do
						local setValue,tween = value:CalcWithDefault(Item)
						propValues[index] = setValue
						propTweens[index] = tween
					end

					-- make event connection
					local function regFn(_,newValue,eventKey)
						-- !HOLD IT SELF TO PREVENT THIS REGISTER BEGIN REMOVED FROM MEMORY
						local setValue = value:CalcWithNewValue(Item,newValue,eventKey)
						prop[index] = setValue
					end
					value:Register(regFn)
					insert(propKeep,{func=regFn,register=value,key=index})
				end
				
			end
		end
	end
	local function Apply(Item)
		return function (Props)
			ApplyNewProps(Item,Props)
		end
	end
	new.Apply = Apply

	return new
end

return module
