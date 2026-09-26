--!nocheck
local Err = { errorBeforeNearest = function(...) end }
local QuadTypes = { ERROR_LEVEL_SURFACE = 1 }
local providerRelate = { GetStrong = function() return nil end, SetStrong = function() end }
local module = {}
local function mergeExtension(...) end

function module.UseProvider(self, providerFn)
	if type(providerFn) ~= "function" then
		Err.errorBeforeNearest(`Quad0212 UseProvider: provider must be a function (got {typeof(providerFn)})`, QuadTypes.ERROR_LEVEL_SURFACE)
	end
	local current = providerRelate:GetStrong(self, "provider")
	if current == providerFn then
		return self :: any -- 같은 프로바이더 재호출 — 멱등 no-op
	end
	if current ~= nil then
		Err.errorBeforeNearest(
			"Quad0213 UseProvider: this Quad module already has a provider — a module cannot serve two backends",
			QuadTypes.ERROR_LEVEL_SURFACE
		)
	end
	local extension = providerFn(self)
	mergeExtension(self, extension, "UseProvider")
	providerRelate:SetStrong(self, "provider", providerFn)
	return self :: any
end

print("parsed ok", module.UseProvider)
