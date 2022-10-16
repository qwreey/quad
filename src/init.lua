---@class quad
local module = {};

-- TODO : style should be can edited with anytimes, and the object's styles can be changed (add, remove ...)
--        and also, styles can be affect by the objects sorts
--[[
this feature should be like :

local style_all = style {
  BackgroundTransparency = 0.2;
}

frame{
  Size = UDim2.new(1,0,1,0);
  textBox "#Input" {
    [event.property "Text"] = function (this,text)
      print(this,"의 글자가",text,"로 변경됨");
    end;
  };
  [style.set] = {
		style_all
	};
};

]]

local require = require(script.require);
local event = require "event"; ---@module "src.event"
local store = require "store"; ---@module "src.store"
local class = require "class"; ---@module "src.class"
local mount = require "mount"; ---@module "src.mount"
local _,advancedTween = pcall(require,"libs.AdvancedTween"); ---@module "src.libs.AdvancedTween"
local _,round = pcall(require,"libs.round"); ---@module "src.libs.round"

local idSpace = {};

---@return quadexport this
---@return quad_module_round round
---@return quad_module_tween tween
function module.init(id)
	if id then
		local this = idSpace[id];
		if this then
			return this,this.round,this.class,this.mount,this.store,this.event,this.tween;
		end
	end

	---@class quadexport
	local this = {items = {}};

	this.require = require;
	this.round = type(round) == "table" and round; ---@type quad_module_round
	this.tween = type(advancedTween) == "table" and advancedTween; ---@type quad_module_tween
	this.event = event.init(this);
	this.store = store.init(this);
	this.mount = mount.init(this);
	this.class = class.init(this);

	--this.plugin = plugin;

	if id then
		idSpace[id] = this;
	end
	return this,this.round,this.class,this.mount,this.store,this.event,this.tween;
end

function module.uninit(id)
	idSpace[id] = nil;
end

return module;
