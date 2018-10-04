local core = require("TabletOSCore")
local computer = require("computer")
local event = require("event")
local fs = require("filesystem")
local graphics = require("TabletOSGraphics")
local buffer = require("doubleBuffering")
local w,h = buffer.getResolution()
local program = {theme={0xCCCCCC,0xFFFFFF-0xCCCCCC}}

local function drawScreen(screen)
	--gui.setColors(table.unpack(program.theme))
	--gpu.fill(1,2,80,23," ")
	buffer.drawRectangle(1,2,w,h-2,program.theme[1],program.theme[2]," ")
	local sET = {screen = screen}
	local y = 2
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
		end
		y = y + 1
	end
	buffer.drawChanges()
	return sET
end

local function executeScreen(sET)
	while true do
		local event = {event.pull()}
		if graphics.clickedToBarButton(event[3],event[4]) == "HOME" then 
			os.exit() 
		end
		if event[1] == "ESS" then 
			computer.pushSignal("REDRAW_ALL")
			break 
		elseif event[1] == "CLOSE" then
			os.exit()
		end
		if event[1] == "REDRAW_ALL" then 
			drawScreen(sET.screen)
			graphics.drawBars()
			buffer.drawChanges()
		end
		if event[1] == "touch" then
			if event[4] == 1 then
				graphics.processStatusBar(event[3],event[4])
			else 
				for i = 1, #sET do
					if sET[i].type ~= "Event" then
						if sET[i].type == "Button" then
							local doOnClick = sET[i].cT(event[3],event[4])
							if doOnClick then 
								sET[i].onClick() 
							end
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

program.mainMenu = {
	{name=function() return core.getLanguagePackages().Settings_langin end, onClick=function() executeScreen(drawScreen(program.langAndInput)) end,type="Button"},
	{name=function() return core.getLanguagePackages().Settings_network end, onClick=function() graphics.drawInfo("Work in progress",{}) end,type="Button"},
	{listener = function(s) if s[1] == "touch" and graphics.clickedToBarButton(s[3],s[4]) == "BACK" then computer.pushSignal("ESS") end end,type="Event"},
}

program.langAndInput = {
	{name=function() return core.getLanguagePackages().Settings_langsel end,onClick=function() executeScreen(drawScreen(program.languageScreen)) end,type="Button"},
	{listener = function(s) if s[1] == "touch" and graphics.clickedToBarButton(s[3],s[4]) == "BACK" then computer.pushSignal("ESS") end end,type="Event"},
}

program.languageScreen = {
	{name = function() return core.getLanguagePackages().Settings_langsel end,type="Label"},
	{type="Separator"}, 
	{listener = function(s) 
		if s[1] == "touch" and graphics.clickedToBarButton(s[3],s[4]) == "BACK" then 
			computer.pushSignal("ESS")
		end
	end,type="Event"},
}

for key,value in pairs(core.languages) do
	table.insert(program.languageScreen,{name=function() return value end,onClick = function()  computer.pushSignal("ESS") core.loadLanguage(key) end,type="Button"})
end
graphics.drawBars()
executeScreen(drawScreen(program.mainMenu))
