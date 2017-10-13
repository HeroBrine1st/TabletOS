local component = require("component")
local gpu = component.gpu
local GUI = require("gui")
local core = require("TabletOSCore")
local computer = require("computer")
local ecs = require("ECSAPI")
local event = require("event")
local program = {theme={0xCCCCCC,0xFFFFFF-0xCCCCCC}}
local BT = require("bluetooth")
local w,h = gpu.getResolution()
local shell = require("shell")
local forms = require("zygote")
local fs = require("filesystem")

local function drawScreen(screen)
	gui.setColors(table.unpack(program.theme))
	gpu.fill(1,1,80,23)
	local sET = {screen = screen}
	local y = 2
	for i = 1, #screen do
		local e = screen[i]

		if e.type == "Button" then
			table.insert(sET,{type="Button",cT=GUI.drawButton(1,y,w,1,e.name(),program.theme[1],program.theme[2]),onClick=e.onClick})
		elseif e.type == "Label" then
			gpu.fill(1,y,w,1," ")
			gui.centerText(w/2,y,e.name())
		elseif e.type == "Event" then
			table.insert(sET,{type="Event",listener=e.listener})
		elseif e.type == "Separator" then 
			gpu.fill(1,y,w,1,"-")
		end
		y = y + 1
	end
	return sET
end

local function executeScreen(sET)
	local oldPixels = ecs.rememberOldPixels(x,y,w,h)
	while true do
		local event = {event.pull()}
		if event[1] == "ESS" then 
			ecs.drawOldPixels(oldPixels) 
			break 
		end
		if event[1] == "changeLanguage" then 
			drawScreen(sET.screen) 
		end
		if event[1] == "touch" then
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
			for i = 1, #sET do
				if sET[i].type == "Event" then
					sET[i].listener(event)
				end
			end
		end
	end
end

program.mainMenu = {
	{name=function() return "Bluetooth" end,onClick=function() core.SaveDisplayAndCallFunction(program.bluetoothScreen) end,type="Button"},
	{type="Separator"},
	{name=function() return core.getLanguagePackages().language end,onClick=function() executeScreen(drawScreen(program.languageScreen)) end,type="Button"},
}

program.languageScreen = {
	{name = function() return core.getLanguagePackages().selLanguage end,type="Label"},
	{type="Separator"}, 
}

for key,value in pairs(core.languagesFS) do
	table.insert(program.languageScreen,{name=function() return value end,onClick = function() core.changeLanguage(key) computer.pushSignal("ESS") end,type="Button"})
end

program.bluetoothScreen = function()
	local form = forms.addForm()
	form.left = 1
	form.top = 2
	form.W = 80
	form.H = 23
	local buttononoff = form:addButton(1,1,"On/Off",function() if BT.state then BT.off() else BT.on() end end)
	local buttonopenclose = form:addButton(1,2,"Open/Close",function() if BT.opened then BT.close() else BT.open() end end)
	local buttonReceive = form:addButton(1,3,"Receive file",function()
		local dialogWait = function()
			 ecs.universalWindow("auto","auto",60,0xCCCCCC,true,
 			{"CenterText", 0x333333, },
 			{"CenterText", 0x333333, version},
			{"TextField", 10, 0xCCCCCC, 0x333333, 0xFF0000, 0x00FF00,changelog},
			{"Button", {0x00FF00, 0xFF00FF, "Install"}, {0xFF0000, 0x00FFFF, "Not install"}})
		end
		BT.receiveFile() 
	end)
	local list = form:addList(1,2,function(view)
		local address = view.items[view.index]
		local windowForm = forms.addForm()
		windowForm.left = 30
		windowForm.top = 12-1
		windowForm.W = 20
		windowForm.H = 2
		windowButton1 = windowForm:addButton(1,1,"Send file",function()
			oldFormPixels = ecs.rememberOldPixels(1,1,80,25)
			local windowForm = zygote.addForm()
			windowForm.left = 30
			windowForm.top = 25/2-2
			windowForm.W = 20
			windowForm.H = 5
			form:addLabel(1,1,core.getLanguagePackages().enterPath)
			local editor = windowForm:addEdit(1,2,function(view1)
				local value = view1.text
				if value and fs.exists(value) then
					BT.sendFile(value,address,function(size,totalSize)
						gui.centerText(40,12,"Sending file")
						gui.drawPrograssBar(1,13,80,0xFF0000,0x00FF00,size,totalSize)
					end)
					ecs.drawOldPixels(oldFormPixels)
					setActiveForm()
					updateFileList()
				end
			end)
			windowButton2 = windowForm:addButton(1,3,"Exit",function()
				form:setActive()
			end)
		end)
		windowButton1.W=20
		windowButton2.W=20
		forms.run(windowForm)
	end)
	function updateList()
		list:clear()
		BT.on()
		local BTDev = BT.scan()
		for _, value in pairs(BTDev) do
			list:insert(value.name,value.address)
		end
	end
	list.W = 80
	list.H = 20
	list.color = 0xCCCCCC
	list.fontColor = (0xFFFFFF - 0xCCCCCC)
	list.border = 0
	local function eventListener(_,_,x,y,button,_)
		if button == 0 and x == 35 and y == 25 then
			local success, reason = pcall(forms.stop,form)
			if not success then
				if reason then
					ecs.error("Unable to exit program:" .. reason)
				end
			end
		end
	end

	local event = form:addEvent("touch",eventListener)
	updateList()
	forms.run(form)
end
