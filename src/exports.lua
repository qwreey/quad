---@class quad
local module = {}

-- TODO: outside ui building
-- if not Instance then
-- 	print("Instance is not exist, Using custom Instance and print result as string . . .")
-- end

local require = require(script.Parent.libs.require)
local style   = require "style"
local event   = require "event"
local store   = require "store"
local class   = require "class"
local mount   = require "mount"
local signal  = require "signal"
local lang    = require "lang"

-- submodule
local advancedTween = require "libs.AdvancedTween"
local round         = require "libs.round"
local customWarn    = require "libs.customWarn"

local IS_TEST = false
local VER = "2.25" .. (IS_TEST and "B" or "")
if IS_TEST then
	warn("You are using BETA version of quad now. Many features may change in the future and unstable. AS USING BETA VERSION OF QUAD, YOU SHOULD KNOW IT WILL BUGGY SOMETIME. still on development - you can ignore this message if have no issue. if you have issue on using quad, please report issue on github. VERSION: "..VER)
end
module.VER = VER

local idSpace = {}

---@return quad_export this
---@return quad_module_round round
---@return quad_module_tween tween
function module.Init(id)
	-- return old items
	if id then
		local this = idSpace[id]
		if this then
			return this,this.round,this.class,this.mount,this.store,this.event,this.tween
		end
	end

	---@class quad_export
	local this = {__type = "quad_module_init"}

	this.require = require
	this.warn    = customWarn or warn
	this.Round   = type(round) == "table" and round ---@type quad_module_round
	this.Tween   = type(advancedTween) == "table" and advancedTween ---@type quad_module_tween
	this.Signal  = signal.init(this) ---@type quad_module_signal
	this.Style   = style.init(this) ---@type quad_module_style
	this.Event   = event.init(this) ---@type quad_module_event
	this.Store   = store.init(this) ---@type quad_module_store
	this.Mount   = mount.init(this) ---@type quad_module_mount
	this.Class   = class.init(this) ---@type quad_module_class
	this.Lang    = lang.init(this) ---@type quad_module_lang

	-- save
	if id then
		idSpace[id] = this
	end

	return this
end

local function cleanup(space)
	-- TODO : Destroy objects
end

function module.Uninit(id)
	pcall(cleanup,idSpace[id])
	idSpace[id] = nil
end

return module
