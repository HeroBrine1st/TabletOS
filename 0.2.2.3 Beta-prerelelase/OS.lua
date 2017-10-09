local computer = require("computer")
local component = require("component")
local gpu = component.gpu
local event = require("event")
local ecs = require("ECSAPI")
local term = require("term")
local unicode = require("unicode")
local fs = require("filesystem")
local core = require("TabletOSCore")
local gui = require("gui")
_G.Math = math
local apps = {}
local shell =  require("shell")
local oldPixelsM = {}
term.clear()
local w,h = gpu.getResolution()


local function drawBar()
gpu.setBackground(0x610B5E)
gpu.fill(1,25,80,1," ")
gpu.set(40,25,"●")
gpu.set(35,25,"◀")
gpu.set(45,25,"▶")
gpu.setBackground(0xFFFF00)
gpu.setForeground(0x610B5E)
gpu.set(1,25,"M")
gpu.setBackground(0x000000)
gpu.setForeground(0xFFFFFF)
end

local function clickedAtArea(x,y,x2,y2,touchX,touchY)
if (touchX >= x) and (touchX <= x2) and (touchY >= y) and (touchY <= y2) then 
return true 
end 
return false
end
local oldPixels = {}
function drawMenu()
	local objects = {
		{y=19,name=core.getLanguagePackages().fileManager,callback=function() 	
			ecs.drawOldPixels(oldPixelsM)
			dofile("/apps/fileManager.lua") drawWorkTable() end},
		{y=20,name=core.getLanguagePackages().monitorOnline,callback=function() 
			dofile("/apps/monitorOnline.lua")
			gpu.setBackground(0x610B5E)
			gpu.setForeground(0xFFFFFF)
			gpu.fill(1,1,70,1," ")
			gpu.setBackground(0x000000)
			gpu.fill(1,2,80,23," ")
			drawWorkTable()
		end},
		{y=21,name=core.getLanguagePackages().settings,callback=function()
			dofile("/apps/settings.lua")
		end},
	 	{y=22,name=core.getLanguagePackages().appsLauncher,callback=function()
		ecs.drawOldPixels(oldPixelsM)
		dofile("/apps/appsLauncher.lua")
		end},
		{y=23,name=core.getLanguagePackages().reboot,callback=function() computer.shutdown(true) end},
	 	{y=24,name=core.getLanguagePackages().shutdown,callback=function() computer.shutdown() end},
	}

	local function checkTouch(y)
		for i = 1, #objects do
			if y == objects[i].y then
				return true, objects[i].callback
			end
		end
		return false, function() return false end
	end

oldPixels = ecs.rememberOldPixels(1,10,15,24)
	local oldb = gpu.setBackground(0xFFFFFF)
	local oldf = gpu.setForeground(0x000000)

	gpu.fill(1,10,15,15," ")
	for i = 1, #objects do
		gpu.set(1,objects[i].y,objects[i].name)
	end
	gpu.setForeground(oldf)
	gpu.setBackground(oldb)
		while true do
		local touch = {event.pull("touch")}
		if clickedAtArea(1,10,15,24,touch[3],touch[4]) then
			local success1, callback1 = checkTouch(touch[4])
			if success1 then
				ecs.drawOldPixels(oldPixelsM)
				local oldPixelsMS = ecs.rememberOldPixels(1,1,80,25)
				pcall(callback1)
				ecs.drawOldPixels(oldPixelsMS)
				drawWorkTable()
				break
			end
		else
			ecs.drawOldPixels(oldPixels)
			oldPixels = {}
			computer.pushSignal(table.unpack(touch))
			break
		end
	end
end



local function centerText(y,text)
local x = Math.floor(w/2-unicode.len(text)/2)
gpu.set(x,y,text)
end













_G.oldEnergy = 100
_G.timerID = 100
function statusBar()
local component = require("component")
local gpu = component.gpu
local energy = Math.ceil((computer.energy()/computer.maxEnergy())*100)
local str = string.gsub(string.format("%q",math.ceil(computer.energy()/computer.maxEnergy()*100)),"\"","")
local len = unicode.len(str)
local oldBackground = gpu.setBackground(0x610B5E)
local oldForeground = gpu.setForeground(0xFFFFFF)
gpu.fill(77,1,80,1," ")
gpu.set(80-len,1,str)
gpu.set(80,1,"%")
gpu.setBackground(oldBackground)
gpu.setForeground(oldForeground)
if energy < 6 then
require("term").clear()
print("Not enough energy! Shutdown tablet... ")
require("computer").shutdown()
end
if not energy == oldEnergy then
computer.pushSignal("energyChange",oldEnergy,energy)
end
oldEnergy = energy
end
local function drawStatusBar()
gpu.setBackground(0x610B5E)
gpu.setForeground(0xFFFFFF)
gpu.fill(1,1,80,1," ")
local power = core.getLanguagePackages().power
local len = unicode.len(power)
gpu.setBackground(0xFFFF00)
gpu.setForeground(0x610B5E)
gpu.set(76-len,1,power)
gpu.setBackground(0x000000)
gpu.setForeground(0xFFFFFF)
_G.timerID = event.timer(1,statusBar,math.huge)
timerID = _G.timerID
end
workTable={}
function drawWorkTable()
	workTable = {}
	gui.setColors(0x000000,0xFFFFFF)
	gpu.fill(1,2,80,23," ")
	local function getFilesTable()
		local tableFolder = "/usr/table/"
		fs.makeDirectory(tableFolder)
		local files = {}
		for elem in fs.list(tableFolder) do
			if fs.exists(tableFolder .. elem) and not fs.isDirectory(tableFolder .. elem) then
				table.insert(files,tableFolder .. elem)
			end
		end
		return files
	end
	local files = getFilesTable()
	for i = 1, #files do
		local stroka = math.ceil(i/4)+1
		local w = 20
		local h = 1
		local xCoord = ((i-1)*w+1) - ((stroka - 2)*(w*4)) - 1
		local yCoord = stroka
		local callback = function() term.clear() return shell.execute(files[i]) end
		local color1 = math.floor(math.random()*0xFFFFFF)
		local color2 = 0xFFFFFF - color1
		gui.drawButton(xCoord+1,yCoord,w,h,fs.name(files[i]),color1,color2)
		local insertTable = {
		x = xCoord,
		y = yCoord,
		w = w,
		h = h,
		callback = callback,
		}
		table.insert(workTable,insertTable)
	end

end

local function windowUpdate(version,changelog)
require("term").clear()
 return ecs.universalWindow("auto","auto",60,0xCCCCCC,true,
 			{"CenterText", 0x333333, core.getLanguagePackages().update},
 			{"CenterText", 0x333333, version},
			{"TextField", 10, 0xCCCCCC, 0x333333, 0xFF0000, 0x00FF00,changelog},
			{"Button", {0x00FF00, 0xFF00FF, "Install"}, {0xFF0000, 0x00FFFF, "Not install"}})
end

local function checkUpdate()
	ecs.prepareToExit()
	local windowInput
	local doUpdate
	if not fs.exists("/version.lua") then
		windowInput = windowUpdate("Please update OS","Please update OS")
		doUpdate = true
	else
		local version = dofile("/version.lua")
		core.getFile("https://raw.githubusercontent.com/HeroBrine1st/OpenComputers/master/TabletOS/version.lua","/usr/newVersion.lua")
		local newVersion = dofile("/usr/newVersion.lua")
		fs.remove("/usr/newVersion.lua")
		local cache = version.version == newVersion.version
		if not cache then
			windowInput = windowUpdate(newVersion.version,newVersion.changelog[core.getLanguage()])
			doUpdate = true
		end
	end
	if doUpdate then
		gui.setColors(0x000000,0xFFFFFF)
		term.clear()
		term.setCursor(1,2)
		if windowInput[1] == "Install" then
			local totalBytes = 0
			local function internetRequest(url)
				local success, response = pcall(component.internet.request, url)
				if success then
					local responseData = ""
					while true do
						local data, responseChunk = response.read()
						if data then
							responseData = responseData .. data
							totalBytes = totalBytes + data:len()
							gui.setColors(0x000000,0xFFFFFF)

							gui.setColors(0xFFFFFF,0x000000)
							gpu.fill(1,1,w,1," ")
							gui.centerText(w/2,1,"Installing update...")
							gui.drawProgressBar(1,2,w,0xFF0000,0x00FF00,totalBytes,140000)
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
			local function getFile(url,filepath)
				local success, reason = internetRequest(url)
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
			local fileListUrl = "https://raw.githubusercontent.com/HeroBrine1st/OpenComputers/master/TabletOS/applications.txt"
			gui.setColors(0x000000,0xFFFFFF)
			print("")
			print("")
			print("Updating OS: receiving updates")
			gui.setColors(0xFFFFFF,0x000000)
			gpu.fill(1,1,w,1," ")
			gui.centerText(w/2,1,"Installing update...")
			gui.drawProgressBar(1,2,w,0xFF0000,0x00FF00,totalBytes,140000)
			local success, string = core.internetRequest(fileListUrl)
			if success then
				local fileListLoader = load("return " .. string)
				local success, fileList = pcall(fileListLoader)
				gui.setColors(0x000000,0xFFFFFF)
				print("Updating OS: installing updates")
				gui.setColors(0xFFFFFF,0x000000)
				gpu.fill(1,1,w,1," ")
				gui.centerText(w/2,1,"Installing update...")
				gui.drawProgressBar(1,2,w,0xFF0000,0x00FF00,totalBytes,140000)
				if success then
					for i = 1, #fileList do
						getFile(fileList[i].url,fileList[i].path)
					end
				else 
					error(fileList) 
				end
			else 
				error(string) 
			end
			gui.setColors(0x000000,0xFFFFFF)
			print("Success. Rebooting system")
			computer.shutdown(true)
		end
	end	
end
checkUpdate()
drawStatusBar()
drawBar()
drawWorkTable()




listener = function(...)
	local touch = {...}
	if touch[3] == 1 and touch[4] == 25 then
		oldPixelsM = ecs.rememberOldPixels(1,2,80,24)
		drawMenu()
		ecs.drawOldPixels(oldPixelsM)
	elseif touch[3] == 45 and touch[4] == 25 then
		event.cancel(timerID)
		event.ignore("touch",listener)
		term.clear()
		while true do
  local result, reason = xpcall(loadfile("/apps/shell.lua"), function(msg)
    return tostring(msg).."\n"..debug.traceback()
  end)
  if not result then
    io.stderr:write((reason ~= nil and tostring(reason) or "unknown error") .. "\n")
    io.write("Press any key to continue.\n")
    os.sleep(0.5)
    require("event").pull("key")
  end
end
	end
	local power = core.getLanguagePackages().power
	local len = unicode.len(power)
	if clickedAtArea(76-len,1,76,1,touch[3],touch[4]) then
		local oldPixelsScreen = ecs.rememberOldPixels(1,1,80,25)
		ecs.clearScreen(0x000000)
		ecs.waitForTouchOrClick()
		ecs.drawOldPixels(oldPixelsScreen)
	end
end
event.listen("touch",listener)
OSAPI = {}

function OSAPI.init()
	drawBar()
	if _G.timerActive then event.cancel(timerID) end
	drawStatusBar()
	event.listen("touch",listener)
	_G.timerActive = true
end

function OSAPI.ignoreListeners()
	event.cancel(timerID)
	event.ignore("touch",listener)
	_G.timerActive = false
end
_G.OSAPI = OSAPI
while true do
	local touch = {event.pull("touch")}
	for i = 1, #workTable do
		local button = workTable[i]
		if clickedAtArea(button.x,button.y,button.x+button.w-1,button.y+button.h-1,touch[3],touch[4]) then
			OSAPI.ignoreListeners()
			local success, successShell, reason = core.saveDisplayAndCallFunction(button.callback)
			drawWorkTable()
			OSAPI.init()
			if not successShell then
				core.saveDisplayAndCallFunction(ecs.error,reason)
			end
			drawWorkTable()
		end
	end
end