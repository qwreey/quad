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
local event = require "event"; ---@module src.event
local store = require "store"; ---@module src.store
--local style = require("style");
local class = require "class"; ---@module src.class
local mount = require "mount"; ---@module src.mount
local _,advancedTween = pcall(require,"src.libs.AdvancedTween"); ---@module src.libs.AdvancedTween

local idSpace = {};
function module.init(id)
	local last = idSpace[id];
	if last then
		return last;
	end
	local this = {items = {}};

	this.require = require;
	this.advancedTween = type(advancedTween) == "table" and advancedTween;
	this.event = event.init(this);
	this.store = store.init(this);
	--this.style = style.init(this);
	this.class = class.init(this);
	this.mount = mount.init(this);

	--this.makeClass = makeClass;
	--this.tween = tween;
	--this.plugin = plugin;

	idSpace[id] = this;
	return this;
end

return module;
