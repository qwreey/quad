local module = {};
local pack = table.pack;
local match = string.match;

---@param shared quad_export
---@return quad_module_class
function module.init(shared)
	---@class quad_module_class
	local new = {__type = "quad_module_class"};
	local InstanceNew = Instance.new;
	local event = shared.event; ---@type quad_module_event
	local bind = event.bind;
	local store = shared.store; ---@type quad_module_store
	local addObject = store.addObject;
	local storeNew = store.new;
	local mount = shared.mount; ---@type quad_module_mount
	local getHolder = mount.getHolder;
	local mountfunc = mount.mount;
	local style = shared.style; ---@type quad_module_style
	local styleList = style.styles;
	local parseStyles = style.parseStyles;
	local advancedTween = shared.tween; ---@type quad_module_tween
	local round = shared.round; ---@type quad_module_round

	local function InstanceNewWithName(classname,parent,name)
		local item = InstanceNew(classname,parent);
		item.Name = name;
		return item;
	end

	-- TODO: refactor getProperty
	-- local propertyGetterRaw = {}
	-- local propertySetterRaw = {}

	local function getProperty(item,index,ClassName)
		if type(item) == "table" then return item[index]; end
		ClassName = ClassName or item.ClassName;
		local isImage = (ClassName == "ImageLabel" or ClassName == "ImageButton");
		if (index == "RoundSize" or index == "roundSize") and isImage then
			if not round then
				error("module 'round' needs to be loaded for get image round size but it is not found on 'src.libs'. you should adding that to src.libs directory");
			end
			return round.getRound(item);
		elseif index == "UiRoundSize" or index == "uiRoundSize" or index == "UIRoundSize" then
			local target = (ClassName == "UICorner" and item) or item:FindFirstChildOfClass("UICorner");
			return (target and target.CornerRadius.Offset) or 0;
		elseif index == "PaddingAll" or index == "paddingAll" then
			local target = (ClassName == "UIPadding" and item) or item:FindFirstChildOfClass("UIPadding");
			return (target and target.PaddingLeft) or UDim.new(0,0);
		elseif index == "PaddingAllOffset" or index == "paddingAllOffset" then
			local target = (ClassName == "UIPadding" and item) or item:FindFirstChildOfClass("UIPadding");
			return (target and target.PaddingLeft.Offset) or 0;
		elseif index == "Scale" then
			local target = (ClassName == "UIScale" and item) or item:FindFirstChildOfClass("UIScale");
			return (target and target.Scale) or 1;
		end
		return item[index];
	end

	local function setProperty(item,index,value,ClassName)
		if type(item) == "table" then item[index] = value; return; end
		ClassName = ClassName or item.ClassName;
		local isImage = (ClassName == "ImageLabel" or ClassName == "ImageButton");
		if (index == "RoundSize" or index == "roundSize") and isImage then
			if not round then
				error("[QUAD] module 'round' needs to be loaded for set image round size but it is not found on 'src.libs'. you should adding that to src.libs directory");
			end
			round.setRound(item,value);
		elseif index == "UiRoundSize" or index == "uiRoundSize" or index == "UIRoundSize" then
			local uiCorner = (ClassName == "UICorner" and item) or item:FindFirstChildOfClass("UICorner") or InstanceNewWithName("UICorner",item,"_quad_round");
			uiCorner.CornerRadius = UDim.new(0,value);
		elseif index == "PaddingAll" or index == "paddingAll" then
			local target = (ClassName == "UIPadding" and item) or item:FindFirstChildOfClass("UIPadding") or InstanceNewWithName("UIPadding",item,"_quad_padding");
			target.PaddingLeft = value;
			target.PaddingRight = value;
			target.PaddingTop = value;
			target.PaddingBottom = value;
		elseif index == "PaddingAllOffset" or index == "paddingAllOffset" then
			local target = (ClassName == "UIPadding" and item) or item:FindFirstChildOfClass("UIPadding") or InstanceNewWithName("UIPadding",item,"_quad_padding");
			local padding = UDim.new(0,value);
			target.PaddingLeft = padding;
			target.PaddingRight = padding;
			target.PaddingTop = padding;
			target.PaddingBottom = padding;
		elseif index == "Scale" then
			local target = (ClassName == "UIScale" and item) or item:FindFirstChildOfClass("UIScale") or InstanceNewWithName("UIScale",item,"_quad_scale");
			target.Scale = value;
		else
			item[index] = value; -- set property
		end
	end

	local function processQuadProperty(processedProperty,iprop,holder,item,className,index,value)
		if processedProperty[index] then return; end

		local valueType = typeof(value);
		local indexType = typeof(index);

		-- child
		if indexType == "string" and valueType == "table" and value.t == "reg" then -- register (bind to store event)
			processedProperty[index] = true; -- ignore next
			-- store binding
			local with = value.wfunc;
			local tstore = value.store;
			local rawKey = value.key;
			local tween = value.tvalue;
			local from = value.fvalue;
			local add = value.avalue;
			local set = tstore[rawKey];
			if set ~= nil or (rawKey:match(",") and with) then
				if add then
					set = set + add;
				end
				if from then
					set = from[set];
				end
				if with then
					set = with(tstore,set,value.key,item);
				end
				setProperty(item,index,set,className);
			else
				local dset = value.dvalue;
				if dset then
					setProperty(item,index,dset,className);
				end
			end

			-- adding event function
			local function regFn(_,newValue,key)
				if add then
					newValue = newValue + add;
				end
				if from then
					newValue = from[newValue];
				end
				if with then
					newValue = with(tstore,newValue,key,item);
				end
				if tween then
					if not advancedTween then
						return warn "[QUAD] module 'AdvancedTween' needs to be loaded for tween properties but it is not found on 'src.libs'. you should adding that to src.libs directory";
					end
					local ended, onStepped;
					if tween.Ended then
						ended = function (...)
							tween.Ended(item,...);
						end
					end
					if tween.OnStepped then
						onStepped = function (...)
							tween.OnStepped(item,...);
						end
					end
					advancedTween.RunTween(item,tween,{[index] = newValue},ended,onStepped,setProperty,getProperty);
				else
					setProperty(item,index,newValue,className);
				end
			end
			value:register(regFn);

			-- this is using hacky of roblox instance
			-- this is will keep reference from week table until
			-- inscance got GCed
			item:GetPropertyChangedSignal("ClassName"):Connect(regFn);
		elseif (valueType == "function" or valueType == "table") and indexType == "string" and bind(item,index,value,valueType) then -- connect event
			-- event binding
		elseif indexType == "string" then
			processedProperty[index] = true; -- ignore next
			-- prop set
			setProperty(item,index,value,className);
		elseif indexType == "number" and valueType == "table" and value.__type == "quad_style" then -- style
			-- style parsing
			for _,thisStyle in ipairs(parseStyles(value)) do
				for styleIndex,styleValue in pairs(thisStyle) do
					if type(styleValue) ~= "table" or styleValue.__type ~= "quad_style" then
						processQuadProperty(processedProperty,iprop,holder,item,className,styleIndex,styleValue);
					end
				end
			end
		elseif indexType == "number" and valueType ~= "boolean" then -- object
			-- child object
			mountfunc(item,((iprop == 1) and value or value:Clone()),holder);
		end
	end

	-- make object that from instance, class and more
	function new.make(ClassName,...) -- render object
		-- make object from ClassName
		local item;
		local classOfClassName = type(ClassName);
		if classOfClassName == "string" then -- if classname is a string value, cdall instance.new for making new roblox instance
			item = InstanceNew(ClassName);
		elseif classOfClassName == "function" then -- if classname is a function value, call it for making new object (OOP object)
			item = ClassName();
		elseif classOfClassName == "table" then -- if classname is a calss what is included new function, call it for making new object (object)
			local func = ClassName.new or ClassName.New or ClassName.__new;
			if ClassName.__noSetup then -- if is support initing props
				local childs,props,parsed,binds = {},pack(...),{},{};
				for iprop = props.n,1,-1 do
					local prop = props[iprop];
					if prop then
						for i,v in pairs(prop) do
							if type(i) == "number" then
								childs[i] = ((iprop == 1) and v or v:Clone());
							elseif bind(i) then
								binds[i] = v;
							else
								parsed[i] = v;
							end
						end
					end
				end
				item = func(parsed);
				local holder = getHolder(item);
				for _,v in ipairs(childs) do
					mountfunc(item,v,holder);
				end
				for i,v in pairs(binds) do
					bind(item,i,v);
				end
				return item;
			end
			item = func();
		end
		if not item then -- if cannot make new object, ignore this call
			local str = tostring(ClassName);
			warn(("[Quad] fail to make item '%s', did you forget to checking the class '%s' is exist?"):format(str,str));
		end

		-- set property and adding child and binding functions
		local holder = getHolder(item); -- to __holder or holder or it self (for tabled)
		-- for iprop,prop in ipairs({...}) do
		local propsListArray = pack(...);
		local processedProperty = {};
		for iprop = 1,propsListArray.n do
			local prop = propsListArray[iprop]
			if prop then
				for index,value in pairs(prop) do
					processQuadProperty(processedProperty,iprop,holder,item,ClassName,index,value);
				end
			end
		end
		return item;
	end
	local make = new.make;

	-- import quad object
	function new.import(ClassName,defaultProperties) -- make new quad class object
		if type(ClassName) == "userdata" and ClassName.ClassName == "ModuleScript" then
			ClassName = require(ClassName);
		end
		local this = defaultProperties or {};
		setmetatable(this,{
			__type = "quad_imported_class",
			__call = function (self,prop,...)
				local propType = type(prop);
				if propType == "string" then
					local lastName = prop;
					return function (nprop,...)
						nprop = nprop or {};
						nprop.Name = lastName;
						for styleName,styleObj in pairs(styleList) do
							if match(prop,styleName) then
								insert(nprop,styleObj);
							end
						end
						local item = make(ClassName,nprop,...,this);
						addObject(lastName,item);
						return item;
					end;
				elseif propType == "nil" then
					return make(ClassName,this);
				end
				return make(ClassName,prop,...,this);
			end;
		});
		return this;
	end

	-- set module calling function
	setmetatable(new,{
		__call = function (self,...)
			return new.import(...);
		end;
	});

	-- make class
	function new.extend()
		local this = {__type = "quad_extend"};

		--- make new object
		function this.new(prop)
			-- make metatable
			prop = storeNew(prop);
			local parent = prop and (prop.Parent or prop.parent);
			local self = {__prop = prop; __parent = parent};
			local init = this.init;
			if init then
				init(self,prop);
			end
			setmetatable(self,this);

			-- render that
			local object = self:render(prop);
			rawset(self,"__object",object);
			rawset(self,"__holder",object);
			if parent then
				rawset(self,"__parent",parent);
				mountfunc(self,parent)
			end
			-- prevent gc
			((type(object) == "table" and object.__object) or object):GetPropertyChangedSignal "ClassName":Connect(function()
				return self;
			end);

			--after render
			local afterRender = this.afterRender;
			if afterRender then
				afterRender(self,object);
			end
			return self;
		end

		--- re-render object (if some props chaged, call this to render again)
		function this:update() -- swap object
			local object = rawget(self,"__object"); -- get last instance
			local parent = object and object.Parent; -- date parent
			if not object then
				parent = rawget(self,"__parent");
			end
			local lastObject = object;
			if lastObject then
				lastObject.Parent = nil;
			end

			object = self:render(self.__prop); -- new instance
			rawset(self,"__holder",object);
			rawset(self,"__object",object);
			object.Parent = getHolder(parent); -- update parent

			-- restore childs
			local child = rawget(self,"__child");
			if child then
				for _,v in pairs(child) do
					if v then
						v.Parent = object;
					end
				end
			end

			-- prevnet gc
			((type(object) == "table" and object.__object) or object):GetPropertyChangedSignal "ClassName":Connect(function()
				return self;
			end);
			if lastObject then -- remove old instance
				self:Destroy(lastObject);
			end

			--after render
			local afterRender = this.afterRender;
			if afterRender then
				afterRender(self,object);
			end
		end

		-- define destroy method
		function this:Destroy(object)
			local unload = rawget(self,"unload");
			object = object or rawget(self,"__object");
			if object then
				if unload then
					unload(self,object);
				else
					local destroy = (object.Destroy or object.destroy);
					if destroy then
						pcall(destroy,object);
					end
				end
			end
			self = nil;
		end

		--- link to new
		function this.__call(self,...)
			return (self.new or self.New or self.__new)(...);
		end;

		-- indexer (getter)
		function this:__index(k)
			if k == "destroy" then
				return self.Destroy;
			end
			local getter = this.getter[k];
			if getter then
				return getter(self,rawget(self,"__object"));
			end

			-- from this (have more priority)
			local fromThis = this[k];
			if fromThis then
				return fromThis;
			end

			-- from prop, not start with '_' (private value)
			if k:sub(1,1) ~= "_" then
				return self.__prop[k];
			end
		end

		--- new indexer (setter)
		function this:__newindex(k,v)
			-- from setter
			local setter = this.setter[k];
			if setter then
				return setter(self,v,rawget(self,"__object"));
			end

			-- is private (self value)
			if k == "holder" or k:sub(1,1) == "_" then
				return rawset(self,k,v);
			end

			-- prop update
			self.__prop[k] = v;
			if this.updateTriggers[k] then
				self:update();
			end
		end

		this.getter = {};
		this.setter = {
			Parent = function(self,parent,object)
				rawset(self,"__parent",parent);
				if object then
					object.Parent = getHolder(parent);
				end
			end;
		};
		this.updateTriggers = {};
		this.__noSetup = true;
		return this;
	end

	return new;
end

return module;
