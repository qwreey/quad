---@class quad
local module = {};

local require = require(script.require);
local event = require "event";
local store = require "store";
local class = require "class";
local mount = require "mount";
local _,advancedTween = pcall(require,"libs.AdvancedTween");
local _,round = pcall(require,"libs.round");

local idSpace = {};

---@return quad_export this
---@return quad_module_round round
---@return quad_module_tween tween
function module.init(id)
	if id then
		local this = idSpace[id];
		if this then
			return this,this.round,this.class,this.mount,this.store,this.event,this.tween;
		end
	end

	---@class quad_export
	local this = {__type = "quad_module_init",items = {}};

	this.require = require;
	this.round = type(round) == "table" and round; ---@type quad_module_round
	this.tween = type(advancedTween) == "table" and advancedTween; ---@type quad_module_tween
	this.event = event.init(this); ---@type quad_module_event
	this.store = store.init(this); ---@type quad_module_store
	this.mount = mount.init(this); ---@type quad_module_mount
	this.class = class.init(this); ---@type quad_module_class

	if id then
		idSpace[id] = this;
	end
	return this,this.round,this.class,this.mount,this.store,this.event,this.tween;
end

function module.uninit(id)
	idSpace[id] = nil;
end

return module;
