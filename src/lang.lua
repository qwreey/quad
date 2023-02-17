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
	new.Lang = game:GetService("LocalizationService").RobloxLocaleId
	new.Default = new.Locales.English

	local lang = {}
	lang.__index = lang
	function lang.New(id,handlers)
		local this = {handlers=handlers,id=id,store=store.New(),index=1}
		lang[id] = this
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
				local default = option.dvalue
				local with = option.wfunc
				local tstore = option.store
				local rawKey = option.key
				local value = tstore[rawKey]
				if value == nil then
					value = default
				elseif with then
					value = with(tstore,value,rawKey)
				end
				formatted = value
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

	function lang:Format(options)
		-- find handler
		local handler = self.handlers[new.Lang]
		if not handler then
			handler = self.handlers[new.Default]
		end
		if not handler then
			warn(("Langauge handle %s is not found on Localization %s"):format(new.Default,self.id))
		end
		local index = self.index
		self.index = index + 1

		-- setup updater
		for _,option in pairs(options) do
			local quadType = PcallGetProperty(option,"__type")
			-- if it is register, setup updater
			if quadType == "quad_register" then
				local function regFn()
					-- !HOLD IT SELF TO PREVENT THIS REGISTER BEGIN REMOVED FROM MEMORY
					Update(self.store,handler,index,options)
				end
				option:Register(regFn)
				insert(self.store.__keep,regFn)
			end
		end

		-- update once
		Update(self.store,handler,index,options)
		
		-- return resiter
		return self.store(tostring(index))
	end

	function new.New(id,handlers)
		return lang.New(id,handlers)
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
	})

	return new
end

return module
