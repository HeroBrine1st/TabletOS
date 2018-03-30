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
_G.isInHome = true
local apps = {}
local shell =  require("shell")
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
local dmh
local function clickedAtArea(x,y,x2,y2,touchX,touchY)
	if (touchX >= x) and (touchX <= x2) and (touchY >= y) and (touchY <= y2) then 
		return true 
	end 
	return false
end
function drawMenu()
	local oldPixelsM = {}
	local wereInHome = _G.isInHome
	_G.isInHome = false
	if wereInHome then oldPixelsM = ecs.rememberOldPixels(1,15,15,25) end
	local objects = {
		{y=19,name=core.getLanguagePackages().fileManager,callback=function() 	
			dofile("/apps/fileManager.lua") end},
		{y=20,name=core.getLanguagePackages().monitorOnline,callback=function() 
			dofile("/apps/monitorOnline.lua")
		end},
		{y=21,name=core.getLanguagePackages().settings,callback=function()
			dofile("/apps/settings.lua")
		end},
	 	{y=22,name=core.getLanguagePackages().appsLauncher,callback=function()
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

	--oldPixels = ecs.rememberOldPixels(1,10,15,24)
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
				pcall(callback1)
				if wereInHome then drawWorkTable() else ecs.drawOldPixels(oldPixelsM) end
				_G.isInHome = wereInHome
				break
			end
		else
			--ecs.drawOldPixels(oldPixels)
			oldPixels = {}
			computer.pushSignal(table.unpack(touch))
			if type(dmh) == "function" then dmh() end
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
dmh = drawWorkTable
local function updateWindow(version,changelog)
	print(core.getLanguagePackages().update)
	print(version)
	print(changelog)
	io.write("Install? [Y/N]:")
	local result = io.read()
	local ret = false
	if not result or result == "" or result:sub(1, 1):lower() == "y" then
		ret = true
	end
	print(ret)
	return ret

end
local function installUpdate(updates)
	term.clear()
	for i = 1, #updates do
		print("Installing " .. updates[i].version)
		core.downloadFileListAndDownloadFiles(updates[i].raw,true)
		local strTW = "return \"" .. updates[i].version .. "\""
		fs.remove("/.version")
		local f = io.open("/.version","w")
		f:write(strTW)
		f:close()
	end
	computer.shutdown(true)
end
local args = {...}
local function checkUpdate()
	local installedVersion = dofile("/.version")
	local versionsRAW = "https://raw.githubusercontent.com/HeroBrine1st/TabletOS/master/VERSIONS.txt"
	local success, reason = core.internetRequest(versionsRAW)
	if not success then error(reason) end
	local versions = load("return " .. reason)()
	local updates = {}
	local changelog = ""
	local m = false
	if args[1] == "--forceupdate" then m = true end
	for _, version in pairs(versions) do
		if not m then
			if version.version == installedVersion then m = true end
		elseif not version.exp then
			table.insert(updates,version)
			changelog = changelog .. version.description[core.getLanguage()] .. " "
		end
	end
	local g = not not updates[1]
	if g then
		if args[1] == "--forceupdate" then
			installUpdate(updates)
		end
		local install = updateWindow(updates[#updates].version,changelog)
		if install then 
			installUpdate(updates)
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
		_G.OSAPI.ignoreListeners()
		drawMenu()
		_G.OSAPI.init()
	elseif touch[3] == 45 and touch[4] == 25 then
		_G.OSAPI.ignoreListeners()
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
			_G.isInHome = false
			local success, successShell, reason = core.saveDisplayAndCallFunction(button.callback)
			OSAPI.init()
			if not successShell then
				ecs.error(reason)
			end
			drawWorkTable()
			_G.isInHome = true
		end
	end
end
