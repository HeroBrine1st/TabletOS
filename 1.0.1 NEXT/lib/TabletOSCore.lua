local fs = require("filesystem")
local serial = require("serialization")
local computer = require("computer")
local core = {}
local languages = {
	["eu_EN"] = "English",
	["eu_RU"] = "Русский",
}
core.settings = {
	langPath = "/TabletOS/Lang/",
	language = "eu_EN",
	userInit = false,
	package = {},
	timezone = "0",
}
setmetatable(languages,{
	__index = function(self,key) 
		if rawget(self,key) then return rawget(self,key) end
		return key 
	end
})
core.languages = languages
function core.loadLanguage(lang)
	core.settings.language = lang
	local package = {}
	for dir in fs.list(core.settings.langPath) do
		if dir:sub(-1,-1) == "/" then
			local path = core.settings.langPath .. dir .. lang .. ".lang"
			if fs.exists(path) then
				for line in io.lines(path) do
					local key, value = line:match("\"(.+)\"%s\"(.+)\"")
					if key then
						package[dir:sub(1,-2) .. "_" .. key] = value
					end
				end
			end
		end
	end
	setmetatable(package,{
		__index = function(self,key) 
			if rawget(self,key) then return rawget(self,key) end
			return "lang." .. key
		end
	})
	core.settings.package = package
	computer.pushSignal("REDRAW_ALL")
end

function core.getLanguagePackages() return core.settings.package end

function core.saveData(name,data)
	checkArg(2,data,"table")
	checkArg(1,name,"string")
	data = serial.serialize(data)
	local path = fs.concat("/TabletOS/db/",name)
	fs.makeDirectory("/TabletOS/db/")
	local handle, reason = io.open(path,"w")
	if not handle then return nil, reason end
	handle:write(data)
	handle:close()
	return true
end
function core.readData(name)
	checkArg(1,name,"string")
	local path = fs.concat("/TabletOS/db/",name)
	local handle, reason = io.open(path,"r")
	if not handle then return nil, reason end
	local buffer = ""
	repeat
		local data,reason = handle:read()
		if data then buffer = buffer .. data end
		if not data and reason then handle:close() return nil, reason end
	until not data
	handle:close()
	return serial.unserialize(buffer)
end

function core.getEditTime(path)
	local t_correction = tonumber(core.settings.timezone) * 3600 
    local lastmod = fs.lastModified(path) + t_correction
    local data = os.date('%x', lastmod)
    local time = os.date('%X', lastmod)
    return data, time, lastmod
end
function core.getTime()
	local f = io.open("/.UNIX","w")
	f:write(" ")
	f:close()
	local _1 = {core.getEditTime("/.UNIX")}
	fs.remove("/.UNIX")
	return table.unpack(_1)
end
local notifications = {}
function core.newNotification(priority,icon,name,description)
	local notification = {priority=priority,icon=icon,name=name,description=description}
	table.insert(notifications,notification)
	table.sort(notifications,function(a,b) return a.priority < b.priority end)
end
function core.getNotifications() return notifications end
function core.removeNotification(index)
	table.remove(notifications,index)
end
local priors = {
	"Verbose",
	"Debug",
	"Info",
	"Warning",
	"Error",
	"Fatal",
	"Slient",
}
function core.log(priority,app,log)
	priority = priority > 1 and (priority < 7 and priority or 6) and priority or 2
	priority = priors[priority]
	local str = "[" .. ({core.getTime()})[2] .. "] [" .. tostring(priority) .. "] " .. app .. ": " .. log
	local f = io.open("/TabletOS/logs.log","a")
	f:write(str)
	f:close()
end
function core.pcall(...)
	local result = {pcall(...)}
	if not result[1] then
		local str = "ERROR IN "
		for i = 1, #{...} do
			str = str .. tostring(({...})[i]) .. " "
		end
		str = str .. " REASON: " .. tostring(result[2]) .. "\n"
		local app = "CORE_PCALL"
		for i = 1, #{...} do
			if ({...})[i] == tostring(({...})[i]) then app = ({...})[i] end
		end
		if fs.exists(app) then app = fs.name(app) end
		core.log(6,app,str)
	end
	return table.unpack(result)
end

function core.resetSettings(save) --fs.remove не нужен, ибо перезаписываем файл
	local package = core.settings.package
	core.settings.package = nil
	if not save then
		core.settings = {}
		core.settings.language = "eu_EN"
		core.settings.langPath = "/TabletOS/Lang/"
	end
	local str = ""
	for key, value in pairs(core.settings) do --сериализация в файл
		str = str .. "\"" .. tostring(key) .. "\" \"" .. tostring(value) .. "\"\n"
	end
	fs.makeDirectory("/TabletOS/")
	local f,r = io.open("/TabletOS/settings.bin","w")
	if not f then return f, r end
	f:write(str)
	f:close()
	core.settings.package = package
	package = nil
	return true
end

function core.init()
	computer.setArchitecture("Lua 5.3")
	if fs.exists("/TabletOS/settings.bin") then
		for line in io.lines("/TabletOS/settings.bin") do
			local key, value = line:match("\"(.+)\"%s\"(.+)\"")
			if key then
				core.settings[key] = value
			end
		end
	else
		core.resetSettings()
	end
	core.loadLanguage(core.settings.language)
	fs.remove("/TabletOS/logs.log")
end

core.init()
return core
