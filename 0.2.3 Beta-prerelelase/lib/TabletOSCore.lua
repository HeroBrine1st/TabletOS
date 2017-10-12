local core = {}
local fs = require("filesystem")
local computer = require("computer")
local component = require("component")
local ecs = require("ECSAPI")
local term = require("term")
local gpu = component.gpu
core.languagePackages = {
	en={
	settings="Settings",
	shutdown="Shutdown",
	reboot="Reboot",
	language="Language",
	selLanguage="Select language",
	monitorOnline="Monitor",
	enterNickname="Enter nickname:",
	newFolder="New folder",
	newFile="New file",
	updateFileList="Update files",
	fileManager="File Manager",
	power="Sleep",
	update = "Update avaliable!",
	appsLauncher = "All apps",
	appInstall = "Install",
	appUninstall = "Uninstall",
	appInstalled="Installed",
	receiveFile = "Receive file?",
	enterPath = "Enter a path of file"
	},
	ru={
	settings="Настройки",
	shutdown="Выключить",
	reboot="Перезагрузить",
	language="Язык",
	selLanguage="Выберите язык",
	monitorOnline="Монитор",
	enterNickname="Введите никнейм игрока:",
	newFolder="Новая папка",
	newFile="Новый файл",
	updateFileList="Обновить",
	fileManager="Файлы",
	power="Сон",
	update = "Доступно обновление!",
	appsLauncher = "Все программы",
	appInstall="Установить",
	appUninstall="Удалить",
	appInstalled="Установлено",
	receiveFile="Принять файл?",
	enterPath="Введите путь к файлу"
	}
}
core.languages = {"en","ru"}
core.languagesFS = {["en"] = "English",["ru"] = "Russian"}
core.language = "en"

function core.getLanguage()
	local f, r = io.open("/.tabletos","r")
	if f then
		core.language = f:read(fs.size("/.tabletos")+1)
		f:close()
		return core.language
	else
		local f = io.open("/.tabletos","w")
		f:write("en")
		f:close()
		return "en"
	end
end

function core.saveLanguage()
	fs.remove("/.tabletos")
	local f = io.open("/.tabletos","w")
	f:write(core.language)
	f:close()
end

function core.changeLanguage(language)
	if language then
		computer.pushSignal("changeLanguage",core.language,language)
		core.language = language
		core.saveLanguage()
	end
end



function core.getLanguagePackages()
	return core.languagePackages[core.getLanguage()]
end

function core.internetRequest(url)
	local success, response = pcall(component.internet.request, url)
	if success then
		local responseData = ""
		while true do
			local data, responseChunk = response.read()
			if data then
				responseData = responseData .. data
			else
				if responseChunk then
					return false, responseChunk
				else
					return true, responseData
				end
			end
		end
	else
		return false, response
	end
end

function core.getFile(url,filepath)
 local success, reason = core.internetRequest(url)
 if success then
   fs.makeDirectory(fs.path(filepath) or "")
   fs.remove(filepath)
   local file = io.open(filepath, "w")
   if file then
   file:write(reason)
   file:close()
    end
   return true, reason
 else
   return false, reason
 end
end


function core.downloadFileListAndDownloadFiles(fileListUrl,debug)
	if debug then	
		print("Downloading file list") 
	end
	local success, string = core.internetRequest(fileListUrl)
	if success then
		local fileListLoader = load("return " .. string)
		local success, fileList = pcall(fileListLoader)
		if success then
			for i = 1, #fileList do
				core.getFile(fileList[i].url,fileList[i].path)
				if debug then 
					print("Downloading " .. fileList[i].path) 
				end
			end
		else 
			error(fileList) 
		end
	else 
		error(string) 
	end
end

function core.saveDisplayAndCallFunction(...)
local w, h = component.gpu.getResolution()
local oldPixels = ecs.rememberOldPixels(1,1,w,h)
local result = {pcall(...)}
ecs.drawOldPixels(oldPixels)
return table.unpack(result)
end

return core
