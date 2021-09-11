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

function module.init()
	local this = {items = {}};

	local event = require(script.event).init(this); if false then event = require("src.event").init(this); end
	local class = require(script.class).init(this); if false then class = require("src.class").init(this); end
	local store = require(script.store).init(this); if false then store = require("src.store").init(this); end
	local style = require(script.style).init(this); if false then style = require("src.style").init(this); end

	this.event = event;
	this.class = class;
	this.store = store;
	this.style = style;
	--this.makeClass = makeClass;
	--this.tween = tween;
	--this.plugin = plugin;

	return this;
end

return module;
