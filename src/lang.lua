local module = {}

local insert = table.insert
local gsub = string.gsub

function module.init(shared)
	---@class quad_module_lang
	local new = {}
	local warn = shared.warn
	local store = shared.Store
	local class = shared.Class
	local PcallGetProperty = class.PcallGetProperty

	new.Locales = {
		["Default"] = "default";
		["English"] = "en_us";
		["Spanish"] = "es_es";
		["French"] = "fr_fr";
		["Indonesian"] = "id_id";
		["Italian"] = "it_it";
		["Japanese"] = "ja_jp";
		["Korean"] = "ko_kr";
		["Russian"] = "ru_ru";
		["Thai"] = "th_th";
		["Turkish"] = "tr_tr";
		["Vietnamese"] = "vi_vn";
		["Portuguese"] = "pt_br";
		["German"] = "de_de";
		["ChineseSimplified"] = "zh_cn";
		["ChineseTraditional"] = "zh_tw";
		["Bulgarian"] = "bg_bg";
		["Bengali"] = "bn_bd";
		["Czech"] = "cs_cz";
		["Danish"] = "da_dk";
		["Greek"] = "el_gr";
		["Estonian"] = "et_ee";
		["Finnish"] = "fi_fi";
		["Hindi"] = "hi_in";
		["Croatian"] = "hr_hr";
		["Hungarian"] = "hu_hu";
		["Georgian"] = "ka_ge";
		["Kazakh"] = "kk_kz";
		["Khmer"] = "km_kh";
		["Lithuanian"] = "lt_lt";
		["Latvian"] = "lv_lv";
		["Malay"] = "ms_my";
		["Burmese"] = "my_mm";
		["Bokmal"] = "nb_no";
		["Dutch"] = "nl_nl";
		["Filipino"] = "fil_ph";
		["Polish"] = "pl_pl";
		["Romanian"] = "ro_ro";
		["Ukrainian"] = "uk_ua";
		["Sinhala"] = "si_lk";
		["Slovak"] = "sk_sk";
		["Slovenian"] = "sl_sl";
		["Albanian"] = "sq_al";
		["Bosnian"] = "bs_ba";
		["Serbian"] = "sr_rs";
		["Swedish"] = "sv_se";
		["Arabic"] = "ar_001";
	}

	local function GetLocale()
		return game:GetService("LocalizationService").RobloxLocaleId
	end
	local function PcallGetLocale()
		local passed,result = pcall(GetLocale)
		if passed then return result end
		return false
	end

	local CurrentLocale = PcallGetLocale() or "en_us"
	local FailedMessage = "<Localization Failed>"

	local weak = {__mode = "v"}
	local lang = {}
	lang.__index = lang
	function lang.New(id,handlers)
		local this = {
			handlers=handlers;
			id=id;
			store=store.New();
			index=1;
			registers = setmetatable({},weak);
		}
		lang[id] = this
		if not handlers[new.Locales.Default] then
			warn(("Localization %s have no Default value, Did you missed '[Lang.Locales.Default] = ...' ? It may make Localization fail on other languages"))
		end
		setmetatable(this,lang)
	end

	-- read options, and make string and save into store for updating
	function lang.Update(valueStore,handler,index,options)
		if not index then
			error(("Index must be a number, but got %s"):format(type(index)))
		end
		index = tostring(index)

		-- parsing options
		local parsedOptions = {}
		for optionName,option in pairs(options) do
			local quadType = PcallGetProperty(option,"__type")
			local optionType = type(option)
			local formatted
			if quadType == "quad_register" then
				formatted = option:CalcWithDefault(nil)
			elseif optionType == "number" then
				if option%1 == 0 then
					-- int
					formatted = ("%d"):format(option)
				else
					-- float
					formatted = tostring(option)
				end
			else
				formatted = tostring(option)
			end
			parsedOptions[optionName] = formatted
		end

		-- set store value
		local handlerType = type(handler)
		if handlerType == "function" then
			valueStore[index] = handler(parsedOptions)
		elseif handlerType == "string" then
			valueStore[index] = gsub(handler,"{(.-)}",parsedOptions)
		end
	end
	local Update = lang.Update

	function lang:UpdateAll()
		-- find handler
		local handler = self.handlers[CurrentLocale]
		if not handler then
			handler = self.handlers[new.Locales.Default]
		end

		for index,register in pairs(self.registers) do
			if handler then
				Update(self.store,handler,index,register.options)
			else
				self.store[tostring(index)] = FailedMessage
			end
		end
	end

	function lang:Format(options)
		-- find handler
		local handler = self.handlers[CurrentLocale]
		if not handler then
			handler = self.handlers[new.Locales.Default]
		end
		if not handler then
			warn(("Langauge handle Lang.Locales.Default is not found on Localization %s"):format(self.id))
		end
		local index = self.index
		self.index = index + 1

		-- setup updater
		local registerKeep = {}
		-- this table will destroyed when parent register was destroyed
		for _,option in pairs(options) do
			local quadType = PcallGetProperty(option,"__type")
			-- if it is register, setup updater
			if quadType == "quad_register" then
				local function regFn()
					-- update handler
					handler = self.handlers[new.Lang]
					if not handler then
						handler = self.handlers[new.Locales.Default]
					end
					if not handler then
						self.store[tostring(index)] = FailedMessage
					else
						Update(self.store,handler,index,options)
					end
					-- !HOLD IT SELF TO PREVENT THIS REGISTER BEGIN REMOVED FROM MEMORY
				end
				option:Register(regFn)
				insert(registerKeep,regFn)
			end
		end

		-- update once
		if handler then
			Update(self.store,handler,index,options)
		else
			self.store[tostring(index)] = FailedMessage
		end

		-- return resiter
		local register = self.store(tostring(index))
		register.registerKeep = registerKeep
		register.__rtype = "LangUpdater"
		register.index = index
		register.options = options
		self.registers[index] = register
		return register
	end

	function new.New(id,handlers)
		return lang.New(id,handlers)
	end

	function new.Update()
		for _,this in pairs(lang) do
			this:UpdateAll()
		end
	end

	setmetatable(new,{
		__call = function(_,id)
			return function (options)
				local data = lang[id]
				if not data then
					error(("Localization %s is not definded"):format(id))
				end
				return data:Format(options)
			end
		end;
		__index = function (self,key)
			if key == "CurrentLocale" then
				return CurrentLocale
			end
			if key == "FailedMessage" then
				return FailedMessage
			end
		end;
		__newindex = function (self,key,value)
			if key == "CurrentLocale" then
				CurrentLocale = value
				new.Update()
				return
			end
			if key == "FailedMessage" then
				FailedMessage = value
				new.Update()
				return
			end
			rawset(self,key,value)
		end
	})

	return new
end

return module