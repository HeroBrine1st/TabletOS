local core = require("TabletOSCore")
local ecs = require("ECSAPI")
local args = {...}
local languagePackages = {
	ru = {available = "FOTAUpdate: Доступно обновление! Откройте приложение для установки",
	available2 = "Версия: ",
	available3 = "Изменения: ",
	confirmation = "Установить обновление?",
	nothing = "Обновлений нет.",
	},
	en = {available = "FOTAUpdate: New update available! Open app for install this update",
	available2 = "Version: ",
	available3 = "Changes: ",
	confirmation = "Install update?",
	nothing = "No updates."
	}
}

languagePackages = languagePackages[core.getLanguage()]
local function checkUpdate()
	local installedVersion = dofile("/.version")
	local versionsRAW = "https://raw.githubusercontent.com/HeroBrine1st/TabletOS/master/VERSIONS.txt"
	local success, reason = core.internetRequest(versionsRAW)
	if not success then error(reason) end
	local versions = load("return " .. reason)()
	local updates = {}
	local changelog = ""
	local m = false
	local last = ""
	for _, version in pairs(versions) do
		if not m then
			if version.version == installedVersion then m = true end
		elseif not version.exp then
			table.insert(updates,version)
			changelog = changelog .. version.description[core.getLanguage()] .. " "
		end
		last = version.version
	end
	if updates[1] then 
		local str = languagePackages.available2 .. last .. languagePackages.available3 .. changelog
		core.newNotification(10,"#0000FF",languagePackages.available,str)
		_G.updates = updates
		_G.changelog = str
	end
end

local function write(text)
  local _, y = term.getCursor()
  term.setCursor(1, y)
  term.write(text)
end

local function getBar(progress)
	progress = progress < 0 and 0 or progress
	progress = progress > 100 and 100 or progress
	local bar = ""
	local barCount = 15/100*progress
	for i = 1, barCount do
		bar = bar .. "="
	end
	bar = text.padRight(bar,15)
	return bar
end

local function shellProgressBar(file,progress)
	local text1 = ""
	if progress == -1 then 
		text1 = file .. "  [" .. getBar(progress) .. "] 0  %   CONNECTING"
	elseif progress >= 0 and progress < 100 then
		text1 = file .. " [" .. getBar(progress) .. "] " .. text.padRight(tostring(progress) .. "%",4) .. " DOWNLOADING"
	elseif progress == 100 then
		text1 = file .. " [" .. getBar(progress) .. "] 100%  DOWNLOAD DONE"
	end
	write(text1)
end
local function download(url,path,buff)
	fs.remove(path)
	fs.makeDirectory(fs.path(path))
	local name = fs.name(path)
	local file, reason = io.open(path,"w")
	if not file then error("Error opening file for writing: " .. tostring(reason)) end
	shellProgressBar(name,-1)
	local success, reqH = pcall(component.internet.request,url)
	if success then
		if reqH then
			local resCode, _, resData
			while not resCode do
				resCode, _, resData = reqH:response()
			end
			if resData and resData["Content-Length"] then
				local contentLength = tonumber(resData["Content-Length"][1])
				local downloadedLength = 0
				local buffer = ""
				while downloadedLength < contentLength do
					local data, reason = reqH.read()
					if not data and reason then reqH.close() error("Error downloading file: " .. tostring(reason)) end 
					downloadedLength = downloadedLength + #data
					file:write(data)
					shellProgressBar(name,math.floor(downloadedLength/contentLength*100+0.5))
					if buff then buffer = buffer .. data end
				end
				io.write("\n")
				reqH.close()
				file:close()
				if buff then return buffer end
			else
				error("Content-Length header absent.")
			end
		else 
			error("Connection error: invalid URL address or server offline.")
		end
	else
		error(reqH)
	end
end


local function installUpdate(updates)
	local tryupdates = {}
	for i = 1, #updates do
		local url = updates[i].raw
		local success, buffer = core.internetRequest(url)
		local update
		if success then
			update = load("return " .. buffer)()
		else error(buffer) end
		for j = 1, #update do
			local url = update[j].url
			local path = update[j].path
			tryupdates[path] = url
		end
	end
	require("term").clear()
	for path, url in pairs(tryupdates) do
		download(url,path)
	end
	require("computer").shutdown(true)
end

---------------------------------------------------------

local buffer = require("doubleBuffering")

local function updateWindow()
	if not _G.updates then 
		local oldpixels = ecs.info("auto","auto","",languagePackages.nothing) 
		require("event").pull("touch")
		ecs.drawOldPixels(oldpixels)
		return 
	end
	local str = languagePackages.confirmation
	local x,y
	local w,h = math.floor(str:len()/2+0.5)*2+2,5
	local sW,sH = buffer.getResolution()
	x = math.floor(sW/2-w/2+0.5)
	y = math.floor(sH/2-h/2+0.5)
	local textX = math.floor(sW/2-str:len()/2+0.5)
	local textY = math.floor(sH/2+0.5)
	buffer.square(x,y,w,h,0xFFFFFF,0x000000," ")
	buffer.text(textX,textY,0x000000,str)
	local buttonsW = w/2
	local buttonsY =  y+h-1
	buffer.square(x,buttonsY,buttonsW,1,0x00FF00,0x000000," ")
	buffer.square(x+buttonsW,buttonsY,buttonsW,1,0xFF0000,0x000000," ")
	local text1,text2 = "√","×"
	local text1X = x + math.floor(buttonsW/2-text1:len()/2+0.5)
	local text2X = x + buttonsW + math.floor(buttonsW/2-text2:len()/2+0.5)
	buffer.text(text1X,buttonsY,0xFFFFFF,text1)
	buffer.text(text2X,buttonsY,0xFFFFFF,text2)
	buffer.draw()
	local install = false
	while true do
		local _,_,tx,ty= event.pull("touch")
		if ty == buttonsY then
			if tx >= x and tx < text2X then 
				install = true
				break
			elseif tx >= text2X and tx < text2X+buttonsW then
				break
			end 
		end
	end
	if install then

	end
end

checkUpdate()
if args[1] then
	updateWindow()
end
