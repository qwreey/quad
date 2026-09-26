import sys,re
src=open('/code/Projects/quad/quad-base/test/mock.luau').read()
mode=sys.argv[1]; out=sys.argv[2]
helper = r'''
local E29DUMP = require("./e29dump")
local function e29loc(): string
	local tb = debug.traceback()
	for line in string.gmatch(tb, "[^\n]+") do
		local m = string.match(line, "(test/spec%.[%w_]+%.luau:%d+)") or string.match(line, "(test/smoke%.[%w_]+%.luau:%d+)") or string.match(line, "(e29probe[%w_]*%.luau:%d+)")
		if m then return m end
	end
	return "?"
end
local function e29(kind: string, detail: string)
	print(`E29HIT|{kind}|{detail}|{e29loc()}`)
end
local function e29cls(cn: string): any
	return E29DUMP[cn]
end
local function e29typeok(t: string, v: any): string?
	local vt = typeof(v)
	if v == nil then return "nil" end
	if t == "boolean" then return if vt == "boolean" then nil else "mismatch" end
	if t == "number" then return if vt == "number" then nil else "mismatch" end
	if t == "string" then
		if vt == "string" then return nil end
		if vt == "number" then return "coerce" end
		return "mismatch"
	end
	if string.sub(t, 1, 5) == "Enum." then
		if vt == "string" or vt == "number" then return "enum-coerce" end
		return "standin"
	end
	if t == "Content" and vt == "string" then return nil end
	if vt == "number" or vt == "string" or vt == "boolean" then return "standin" end
	return "standin"
end
'''
# insert helper after the dataOf/proxyOf decls
src=src.replace('local methods = {}\n', 'local methods = {}\n'+helper,1)
if mode=='instr':
    # __index hooks
    src=src.replace('''				return data.properties[key]
			end
		end,''','''				local c = e29cls(data.className)
				if c ~= nil and type(key) == "string" then
					if c.w[key] == nil and c.r[key] == nil and c.e[key] == nil then
						e29("read-unknown-member", `{data.className}.{key}`)
					elseif c.e[key] ~= nil then
						e29("read-undeclared-engine-event", `{data.className}.{key}`)
					elseif data.properties[key] == nil then
						e29("read-default-nil", `{data.className}.{key} ({c.w[key] or c.r[key]})`)
					end
				end
				return data.properties[key]
			end
		end,''',1)
    # __newindex hooks
    src=src.replace('''		__newindex = function(_, key, value)
''','''		__newindex = function(_, key, value)
			do
				local c = e29cls(data.className)
				if key == "Parent" then
					if data.destroyed then e29("parent-after-destroy", data.className) end
					if value ~= nil and dataOf[value] ~= nil then
						local p = dataOf[value]
						local walk: any = p
						while walk ~= nil do
							if walk == data then e29("parent-cycle", data.className); break end
							walk = walk.parent
						end
						if p == data.parent then
							e29("parent-same", data.className .. (if #data.changed == 0 and data.changed.Parent ~= nil and #((data.changed.Parent :: any).connections) > 0 then "+listener" else ""))
						end
					elseif value == nil and data.parent == nil then
						e29("parent-same-nil", data.className)
					end
				elseif key == "Name" then
					if value == data.name then
						local sig = data.changed.Name
						if sig and #((sig :: any).connections) > 0 then e29("same-value-fire", `{data.className}.Name`) end
					end
				elseif c ~= nil and type(key) == "string" then
					if c.w[key] == nil then
						if c.r[key] ~= nil then
							e29("write-readonly", `{data.className}.{key}`)
						elseif c.e[key] == nil then
							local dr = E29DUMP.__dropped[data.className]
							e29("write-unknown-member", `{data.className}.{key}` .. (if dr and dr[key] then " [dropped: " .. dr[key] .. "]" else ""))
						end
					else
						local tk = e29typeok(c.w[key], value)
						if tk ~= nil then e29("write-type-" .. tk, `{data.className}.{key}:{c.w[key]}<-{typeof(value)}`) end
					end
				end
				if key ~= "Parent" and key ~= "Name" and data.properties[key] == value and value ~= nil then
					local sig = data.changed[key]
					if sig and #((sig :: any).connections) > 0 then e29("same-value-fire", `{data.className}.{tostring(key)}`) end
				end
			end
''',1)
    src=src.replace('''function Instance.new(className: string): MockInstance
''','''function Instance.new(className: string): MockInstance
	if E29DUMP[className] == nil then e29("new-nondump-class", className) end
''',1)
    src=src.replace('''function Instance.foreign(className: string): MockInstance
''','''function Instance.foreign(className: string): MockInstance
	if E29DUMP[className] == nil then e29("new-nondump-class", className) end
''',1)
    src=src.replace('''function methods.SetAttribute(inst: any, name: string, v: any)
''','''function methods.SetAttribute(inst: any, name: string, v: any)
	if type(name) ~= "string" or #name > 100 or string.find(name, "[^%w_]") or string.sub(name, 1, 3) == "RBX" or #name == 0 then e29("attr-name-rule", tostring(name)) end
	do local t = typeof(v); if t ~= "nil" and t ~= "string" and t ~= "number" and t ~= "boolean" and t ~= "table" and t ~= "function" and t ~= "thread" then e29("attr-value-other", t) end end
''',1)
    src=src.replace('''function methods.GetPropertyChangedSignal(inst: any, property: string): Signal
	local data = getData(inst)
''','''function methods.GetPropertyChangedSignal(inst: any, property: string): Signal
	local data = getData(inst)
	do local c = e29cls(data.className); if c ~= nil and c.w[property] == nil and c.r[property] == nil and property ~= "Name" and property ~= "Parent" and property ~= "ClassName" then e29("gpcs-unknown", `{data.className}.{property}`) end end
''',1)
    src=src.replace('''function methods.IsA(inst: any, className: string): boolean
''','''function methods.IsA(inst: any, className: string): boolean
	if inst.ClassName ~= className then e29("isa-false", `{inst.ClassName} IsA {className}`) end
''',1)
    src=src.replace('''	local function setAttr(inst: any, name: string, v: any)
''','''	local function setAttr(inst: any, name: string, v: any)
		do local t = type(v); if t == "table" or t == "function" or t == "thread" then e29("setattr-op-unsupported", `{name}={t}`) end end
		if type(name) ~= "string" or #name > 100 or string.find(name, "[^%w_]") or string.sub(name, 1, 3) == "RBX" or #name == 0 then e29("setattr-op-name-rule", tostring(name)) end
''',1)
    src=src.replace('''	Create = function(_self: any, inst: any, info: any, props: { [string]: any }): any
''','''	Create = function(_self: any, inst: any, info: any, props: { [string]: any }): any
		do
			local c = e29cls(inst.ClassName)
			for k, v in props do
				if c ~= nil and c.w[k] == nil then e29("tween-unknown-prop", `{inst.ClassName}.{k}`) end
				if type(v) == "string" then e29("tween-string-value", `{inst.ClassName}.{k}`) end
				if v == nil then e29("tween-nil", `{inst.ClassName}.{k}`) end
			end
			if getData(inst).destroyed then e29("tween-create-destroyed", inst.ClassName) end
		end
''',1)
    src=src.replace('''	new = function(...: any): any
''','''	new = function(...: any): any
		do local n = select("#", ...); for i = 1, n do if select(i, ...) == nil then e29("tweeninfo-explicit-nil", tostring(i)) end end end
''',1)
elif mode=='forward':
    src=src.replace('for i = #snapshot, 1, -1 do','for i = 1, #snapshot do',1)
elif mode=='samevalue':
    src=src.replace('''				data.properties[key] = value
			end
			fireChanged(data, key)''','''				if data.properties[key] == value then return end
				data.properties[key] = value
			end
			fireChanged(data, key)''',1)
    src=src.replace('''				if type(value) ~= "string" then
					error("Name must be a string", 2)
				end
				data.name = value''','''				if type(value) ~= "string" then
					error("Name must be a string", 2)
				end
				if data.name == value then return end
				data.name = value''',1)
elif mode=='parentlock':
    src=src.replace('''				assert(value == nil or dataOf[value] ~= nil, "attempt to set non-instance as Parent")
''','''				assert(value == nil or dataOf[value] ~= nil, "attempt to set non-instance as Parent")
				if data.destroyed then error(`The Parent property of {data.name} is locked (E29 parentlock variant)`, 2) end
				if value ~= nil then local w: any = dataOf[value]; while w ~= nil do if w == data then error("E29 circular reference", 2) end; w = w.parent end end
				if value ~= nil and dataOf[value] == data.parent then return end
''',1)
elif mode=='nilreject':
    src=src.replace('''				data.properties[key] = value
			end
			fireChanged(data, key)''','''				do
					local c = e29cls(data.className)
					local NULLABLE = { ["Instance?"] = true, Instance = true, GuiObject = true, GuiBase2d = true, BasePart = true, Camera = true, LocalizationTable = true, HapticEffect = true }
					if value == nil and c ~= nil and c.w[key] ~= nil and not NULLABLE[c.w[key]] then
						error("Unable to assign property " .. tostring(key) .. ". " .. c.w[key] .. " expected, got nil (E29 nilreject variant)", 2)
					end
				end
				data.properties[key] = value
			end
			fireChanged(data, key)''',1)
elif mode=='classcheck':
    # reject non-dump classes except common known real classes
    src=src.replace('''function Instance.new(className: string): MockInstance
''','''function Instance.new(className: string): MockInstance
	if E29DUMP[className] == nil then error(`E29 classcheck: Unable to create an Instance of type "{className}"`, 2) end
''',1)
open(out,'w').write(src)
