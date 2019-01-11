os.sleep(0.1) --от двойного клика
local core = require("TabletOSCore")
local computer = require("computer")
local event = require("event")
local event1 = event
local fs = require("filesystem")
local serial = require("serialization")
local graphics = require("TabletOSGraphics")
local buffer = require("doubleBuffering")
local w,h = buffer.getResolution()
local program = {theme={0xCCCCCC,0xFFFFFF-0xCCCCCC},actionBar={background=0xFFFFFF,foreground=0x000000,statusBarFore=0x000000}}

local function drawScreen(screen)
	buffer.drawRectangle(1,2,w,h-2,program.theme[1],program.theme[2]," ")
	local sET = {screen = screen}
	local y = 5
	for i = 1, #screen do
		local e = screen[i] --element
		if e.type == "Button" then
			table.insert(sET,{type="Button",cT=graphics.drawButton(1,y,w,1,e.name(),program.theme[1],program.theme[2]),onClick=e.onClick})
		elseif e.type == "Label" then
			buffer.drawRectangle(1,y,w,1,program.theme[1],program.theme[2]," ")
			graphics.centerText(w/2,y,program.theme[2],e.name())
		elseif e.type == "Event" then
			table.insert(sET,{type="Event",listener=e.listener})
			y = y - 1
		elseif e.type == "Separator" then 
			buffer.drawRectangle(1,y,w,1,program.theme[1],program.theme[2],"—")
		elseif e.type == "Label+" then
			buffer.drawRectangle(1,y,w,1,program.theme[1],program.theme[2],"—")
			graphics.centerText(w/2,y,program.theme[2],e.name())
		end
		y = y + 1
	end
	graphics.drawActionBar({
		color=program.actionBar.background,
		text=core.getLanguagePackages().OS_settings,
		textColor=program.actionBar.foreground,
		statusBarFore=program.actionBar.statusBarFore,
	})
	buffer.drawChanges()
	return sET
end
local actions = {
	drag = "MOVE",
	drop = "UP",
	touch = "DOWN",
}
local function executeScreen(sET)
	local selButton
	while true do
		local event = {event.pull()}
		if event[3]==1 and event[4]==h then
			local file = graphics.drawMenu()
			if file then 
				event1.timer(0,function() 
					core.executeFile(file)
				end)
				os.exit()
				break
			end
		elseif event[1] == "ESS" then 
			computer.pushSignal("REDRAW_ALL")
			break 
		elseif event[1] == "CLOSE" then
			os.exit()
		elseif event[1] == "REDRAW_ALL" then
			selButton = nil
			drawScreen(sET.screen)
			graphics.drawChanges()
		elseif event[1] == "touch" then
			if graphics.clickedToBarButton(event[3],event[4]) == "HOME" then
				os.exit()
			elseif graphics.clickedToBarButton(event[3],event[4]) == "BACK" then
				computer.pushSignal("ESS")
			elseif event[4] == 1 then
				graphics.processStatusBar(event[3],event[4])
			end
		end
		if event[1] == "touch" or event[1] == "drag" or event[1] == "drop" then
			local _event = {}
			_event.action = actions[event[1]]
			_event.x = event[3]
			_event.y = event[4]
			_event.button = event[5]
			_event.nick = event[6]
			for i = 1, #sET do
				if sET[i].type == "Button" then
					local doOnClick = sET[i].cT(event[3],event[4])
					if doOnClick then 
						if selButton and not i == selButton then 
							if sET[selButton].onDrop then
								sET[selButton].onDrop()
							end
						end
						if selButton == i or event[1] == "touch" then
							sET[i].onClick(_event)
							selButton = i
						end
					end
				end
			end
		end
		for i = 1, #sET do
			if sET[i].type == "Event" then
				sET[i].listener(event)
			end
		end
	end
end
local moduleEnv = _G
function moduleEnv.setContentView(screen)
	return executeScreen(drawScreen(screen))
end

local modules = {}
local pkgDir = core.getPackageDirectory()
for file in fs.list(fs.concat(pkgDir,"Modules")) do
	local _file = fs.concat(pkgDir,"Modules",file)
	local _module = assert(loadfile(_file,_,_,moduleEnv))()
	table.insert(modules,_module)
end
local mainScreen = {}
for _, _module in pairs(modules) do
	table.insert(mainScreen,{type="Button",name=_module.name,onClick=_module.onClick})
end
modules = nil
setContentView(mainScreen)
