local core = require("TabletOSCore")
local component = require("component")
local event = require("event")
local buffer = require("doubleBuffering")
local unicode = require("unicode")
local serialization = require("serialization")
local computer = require("computer")
local text = require("text")
local graphics = {
	theme = {
		bars = {
			foreground = 0xFFFFFF,
			background = 0x610B5E,
		},
		menuButton = {
			background = 0xFFFF00,
			foreground = 0x610B5E,
		},
		notifications = {
			nameFore = 0xFFFFFF,
			foreground = 0xCCCCCC,
			background = 0x610B5E,
		},
		contextMenu = {
			foreground = 0x000000,
			background = 0xFFFFFF,
			pressedFore = 0xFFFFFF,
			pressedBack = 0x00FF00,
		},
		editMenu = {
			foreground = 0xFFFFFF,
			background = 0x888888,
			barBack = 0x555555,
			barFore = 0xFFFFFF,
		},
		infoWindow ={
			foreground = 0xFFFFFF,
			background = 0x888888,
			buttonFore = 0xFFFFFF,
			buttonBack = 0x555555,
		},
	},
}

function graphics.drawButton(x,y,w,h,text,buttonColor,textColor)
  buffer.drawRectangle(x,y,w,h,buttonColor,textColor," ")
  local textX = x + math.floor(w/2)
  local textY = y + math.floor(h/2)
  graphics.centerText(textX,textY,textColor,text)
  local function checkTouch(touchX,touchY)
    local x,y,w,h = x,y,w,h
    local x2 = x+w-1
    local y2 = y+h-1
    if (touchX >= x) and (touchX <= x2) and (touchY >= y) and (touchY <= y2) then
      return true
    end
    return false
  end
  return checkTouch
end

function graphics.centerText(x,y,fore,text,trancparency)
  local x1 = x - math.floor(unicode.len(text)/2+0.5)
  buffer.drawText(x1,y,fore,text,trancparency)
end

function graphics.clickedAtArea(x,y,x2,y2,touchX,touchY)
  if (touchX >= x) and (touchX <= x2) and (touchY >= y) and (touchY <= y2) then return true end
  return false
end

function graphics.drawMenu()
	local sW,sH = buffer.getResolution()	
	local menu = core.settings.menu or {
		{name = core.getLanguagePackages().OS_settings,callback = function() return "/TabletOS/Apps/Settings.lua" end},
		{name = core.getLanguagePackages().OS_shutdown,contextMenu ={
			{name=core.getLanguagePackages().OS_reboot, callback = function() return "/bin/reboot.lua" end},
			{name=core.getLanguagePackages().OS_shutdown2, callback = function() return "/bin/shutdown.lua" end},
		}},
	}
	if type(menu) == "string" then
		menu,reason = serialization.unserialize(menu)
		if not menu then error(reason) end 
		for key, value in pairs(menu) do
			if not menu[key].callback and menu[key].file then
				menu[key].callback = function() return value.file end
				menu[key].file = nil
			end
		end
	end
	-- local sW, sH = buffer.getResolution()
	-- local maxW = 15
	-- for i = 1, #menu do
	-- 	maxW = math.max(maxW,unicode.len(core.getLanguagePackages()[menu[i].name])+1)
	-- end
	-- local x,y,w,h = 1,sH - #menu, maxW, #menu
	-- local screen = buffer.copy(x,y,w,h)
	-- buffer.drawRectangle(x,y,w,h,0xFFFFFF,0x000000," ")
	-- for i = 1, #menu do
	-- 	local tY = y + i - 1
	-- 	buffer.drawText(x,tY,0x000000,core.getLanguagePackages()[menu[i].name])
	-- end
	-- buffer.drawChanges()
	-- while true do
	-- 	local _1,_2,tX,tY,_5,_6 = event.pull("touch")
	-- 	if graphics.clickedAtArea(x,y,x+w-1,y+h-1,tX,tY) then
	-- 		buffer.paste(x,y,screen)
	-- 		buffer.drawChanges()
	-- 		return menu[#menu-(sH-tY)+1].path
	-- 	else
	-- 		buffer.paste(x,y,screen)
	-- 		buffer.drawChanges()
	-- 		if not (tX == 1 and tY == sH) then
	-- 			require("computer").pushSignal(_1,_2,tX,tY,_5,_6)
	-- 		end
	-- 		break
	-- 	end
	-- end
	return graphics.drawContextMenu(1,sH,menu)
end

local function braileSymbol(a, b, c, d, e, f, g, h) --https://pastebin.com/5FzEuqs8 94 строка
    return unicode.char(10240 + 128*h + 64*d + 32*g + 16*f + 8*e + 4*c + 2*b + a);
end

function graphics.clickedToBarButton(x,y)
	local w,h = buffer.getResolution()
	if y ~= h then return nil end
	local home = {math.floor(w/2),math.floor(w/2+1)}
	local back = math.floor(w/2-w*0.0625)
	local forward = math.floor(w/2+w*0.0625+1)
	if x == home[1] or x == home[2] then return "HOME" end
	if x == back then return "BACK" end
	if x == forward then return "NEXT" end
end



function graphics.drawBars(nPO)
	local w,h = buffer.getResolution()
	local notifications = core.getNotifications()
	buffer.drawRectangle(1,1,w,1,graphics.theme.bars.background,graphics.theme.bars.foreground," ")
	buffer.drawRectangle(1,h,w,1,graphics.theme.bars.background,graphics.theme.bars.foreground," ")
	buffer.set(w/2,h,graphics.theme.bars.background,graphics.theme.bars.foreground,braileSymbol(0,1,1,0,1,1,1,1))
	buffer.set(w/2+1,h,graphics.theme.bars.background,graphics.theme.bars.foreground,braileSymbol(1,1,1,1,0,1,1,0))
	buffer.set(math.floor(w/2-w*0.0625),h,graphics.theme.bars.background,graphics.theme.bars.foreground,"◀")
	buffer.set(math.floor(w/2+w*0.0625+1),h,graphics.theme.bars.background,graphics.theme.bars.foreground,"▶")
	local nStr = ""
	for i = 1, math.min(#notifications,math.floor(w*0.875)) do
		nStr = nStr .. notifications[i].icon
	end
	nStr = nStr:sub(1,70)
	if #notifications > 70 then nStr = nStr .. "…" end
	if nPO then nStr = core.getLanguagePackages().OS_notifications end
	buffer.drawText(1,1,0xFFFFFF,nStr)
	buffer.set(1,h,graphics.theme.menuButton.background,graphics.theme.menuButton.foreground,"M")
	if not nPO then
		local charge = computer.energy()/computer.maxEnergy()*100
		local str = text.padLeft(tostring(charge) .. "%",4)
		buffer.drawText(1,w-3,0xFFFFFFF,str)
		local fore = 0x000000
		--if network.isActive() then fore = 0x888888 end
		--if network.isConnected() then fore = 0xFFFFFF end
		buffer.set(1,w-5,graphics.theme.bars.background,fore,"N")
	end
end

function graphics.openNotifications(y,noProcess)
	local sW, sH = buffer.getResolution()
	local notifications = core.getNotifications()
	if y then
		buffer.drawRectangle(1,2,sW,y-1,graphics.theme.notifications.background,graphics.theme.notifications.foreground," ")
		graphics.centerText(sW/2+1,y,graphics.theme.notifications.foreground,"====")
		buffer.setDrawLimit(1,2,sW,y-1)
	else
		buffer.drawRectangle(1,2,sW,sH-1,graphics.theme.notifications.background,graphics.theme.notifications.foreground," ")
		graphics.centerText(sW/2+1,sH,graphics.theme.notifications.foreground,"====")
		buffer.setDrawLimit(1,2,sW,sH-1)
	end
	local visible = {}
	for i = 1, #notifications do
		local y1 = (i-1)*3+2
		buffer.drawText(1,y1,graphics.theme.notifications.nameFore,notifications[i].name)
		local text1 = notifications[i].description
		local text2 = ""
		if #text1 > sW then text2 = text1:sub(sW+1) text1 = text1:sub(1,sW) end
		buffer.drawText(1,y1+1,graphics.theme.notifications.foreground,text1)
		buffer.drawText(1,y1+2,graphics.theme.notifications.foreground,text2)	
		local notif = {x1 = 1, x2 = sW, y1 = y1, y2 = y1+2, index = i,}
		local bX1, bY1, bX2, bY2 = buffer.getDrawLimit() 
		if notif.y2 < bY2 then 
			table.insert(visible,notif)
		end
	end
	buffer.setDrawLimit(1,1,sW,sH)
	graphics.centerText(1,sW/2,0x0,"    ")
	if (not y or y == sH) and not noProcess then
		buffer.drawChanges()
		while true do
			local _,_,x,y,_,_ = event.pull("touch")
			if y == sH then
				return
			elseif y > 1 and y < sH then
				for i = 1, #visible do
					local e = visible[i]
					if graphics.clickedAtArea(e.x1,e.y1,e.x2,e.y2,x,y) then
						core.removeNotification(e.index)
						visible = {}
						for i = 1, #notifications do
							local y1 = (i-1)*3+2
							local notif = {x1 = 1, x2 = sW, y1 = y1, y2 = y1+2, index = i,}
							local bX1, bY1, bX2, bY2 = buffer.getDrawLimit()
							if notif.y2 < bY2 then 
								table.insert(visible,notif)
							end
						end
						graphics.openNotifications(sH,true)
						buffer.drawChanges()
						break
					end
				end
			end
		end
	end
end

function graphics.processStatusBar(x,y)
	local sW, sH = buffer.getResolution()
	local screen = buffer.copy(1,2,sW,sH)
	graphics.drawBars(true)
	graphics.openNotifications(3)
	buffer.drawChanges()
	local touchX,touchY = x or 1, y or 1
	local opened = false
	while true do
		local signal,_,x,y,_,_ = event.pull()
		if signal == "touch" then
			touchX, touchY = x, y
		elseif signal == "drag" then
			if y < 3 then y = 3 end
			buffer.paste(1,2,screen)
			graphics.openNotifications(y)
			buffer.drawChanges()
		elseif signal == "drop" then
			if not opened then
				if y > touchY and y-touchY > 2 then
					for i = y, sH do
						os.sleep(0.01)
						graphics.openNotifications(i)
						buffer.drawChanges()
					end
					opened = true
				else
					for i = -y, -1 do
						local j = -i
						os.sleep(0.01)
						buffer.paste(1,2,screen)
						graphics.openNotifications(j)
						buffer.drawChanges()
					end
					graphics.drawBars()
					return
				end
			elseif opened then
				if y < sH-1 then
					for i = -y, -1 do
						local j = -i
						os.sleep(0.01)
						buffer.paste(1,2,screen)
						graphics.openNotifications(j)
						buffer.drawChanges()
					end
					graphics.drawBars()
					buffer.drawChanges()
					return
				end
			end
		end
	end
	graphics.drawBars()
	buffer.drawChanges()
end

local function createTableExemplar(tbl) --мегакостыль и нигде не юзается, но пусть лежит
	local tbl2 = {}
	for key, value in pairs(tbl) do
		local k,v = key,value
		tbl2[k]=v
	end
	return tbl2
end

function graphics.drawContextMenu(x,y,elements,...)
	local w,h = 1, #elements
	local sW,sH = buffer.getResolution()
	for i = 1, #elements do
		local element = elements[i]
		w = math.max(w,unicode.len(element.name) + (element.contextMenu and 3 or 2))
	end
	if x+w > sW then 
		x = sW-w
		if elements["repeat"] then y = y + 1 end
	end
	if y+h > sH then
		y = sH-h
	end
	local screen = buffer.copy(x,y,w,h)
	buffer.drawRectangle(x,y,w,h,graphics.theme.contextMenu.background,0x000000," ")
	local coordIndexes = {}
	for i = 1, #elements do
		local element = elements[i]
		local name = element.name
		local contextMenu = element.contextMenu
		name = " " .. name
		if contextMenu then 
			name = text.padRight(name,w-1).."▶" 
		end
		elements[i].newname = name
		buffer.drawText(x,y+i-1,graphics.theme.contextMenu.foreground,name)
		coordIndexes[y+i-1] = i
	end
	graphics.drawChanges()
	while true do
		local _1,_2,tX,tY,button,nickname = event.pull("touch")
		if button == 0 and graphics.clickedAtArea(x,y,x+w-1,y+h-1,tX,tY) then
			local index = coordIndexes[tY]
			local element = rawget(elements,index)
			buffer.drawRectangle(x,tY,w,1,graphics.theme.contextMenu.pressedBack,0x0," ")
			buffer.drawText(x,tY,graphics.theme.contextMenu.pressedFore,element.newname)
			graphics.drawChanges()
			os.sleep(0.1)
			buffer.drawRectangle(x,tY,w,1,graphics.theme.contextMenu.background,0x0," ")
			buffer.drawText(x,tY,graphics.theme.contextMenu.foreground,element.newname)
			graphics.drawChanges()
			if element.contextMenu then
				local cX,cY = x+w,tY
				element.contextMenu["repeat"] = true
				local res = {graphics.drawContextMenu(cX,cY,element.contextMenu,...)}
				if #res > 0 then
					buffer.paste(x,y,screen)
					buffer.drawChanges()
					return table.unpack(res) 
				end
			elseif element.callback then
				buffer.paste(x,y,screen)
				buffer.drawChanges()
				local res = {element.callback(tX,tY,...)}
				return table.unpack(res)
			elseif element.action then
				buffer.paste(x,y,screen)
				buffer.drawChanges()
				local res = {element.action(tX,tY,...)}
				return table.unpack(res)
			end
		elseif not graphics.clickedAtArea(x,y,x+w-1,y+h-1,tX,tY) then
			buffer.paste(x,y,screen)
			buffer.drawChanges()
			require("computer").pushSignal(_1,_2,tX,tY,button,nickname)
			break
		end
	end
end

local function convertCode(code)
	local symbol = ""
	if code ~= 0 and code ~= 13 and code ~= 8 and code ~= 9 and code ~= 200 and code ~= 208 and code ~= 203 and code ~= 205 and code ~= 0x9D and code ~= 0x1D and code ~= 0x1D and code ~= 0x36 and code ~= 0x38 and code ~= 0xB8 and code ~= 0x2A and code ~= 0x9D then
		symbol = unicode.char(code)
		if require("keyboard").isShiftDown() then symbol = unicode.upper(symbol) end
	end
	return symbol
end

function graphics.drawEdit(label0,label,text)
	text = text or ""
	if type(label) == "string" then label = {label} end
	local len = 0
	for i = 1, #label do
		len = math.max(unicode.len(label[i]),len)
	end
	local w = math.max(len+2,20)
	w = w+w%2 --если число нечетное - добавится 1 и станет четным
	local h = 3 + #label
	local sW, sH = buffer.getResolution()
	local x,y = sW/2-w/2+1,sH/2-h/2+1
	x,y,w,h = math.floor(x+0.5),math.floor(y+0.5),math.floor(w+0.5),math.floor(h+0.5)
	buffer.drawRectangle(x,y,w,h,graphics.theme.editMenu.background,0x0," ")
	buffer.drawRectangle(x,y,w,1,graphics.theme.editMenu.barBack,0x0," ")
	buffer.drawText(x,y,graphics.theme.editMenu.barFore,label0)
	for i = 1, #label do
		graphics.centerText(sW/2,y+i,graphics.theme.editMenu.foreground,label[i])
	end
	buffer.drawText(x,y+h-2,0xFFFFFF,">")
	local visibleLen = w-2
	local visible = text:sub(-visibleLen)
	local cursor = false
	while true do
		visible = text:sub(-visibleLen)
		buffer.drawRectangle(x+1,y+h-2,w-2,1,graphics.theme.editMenu.background,0x0," ")
		visible = visible .. (cursor and "█" or " ")
		buffer.drawText(x+1,y+h-2,graphics.theme.editMenu.foreground,visible)
		buffer.drawChanges()
		local signal = {event.pull(0.5,"key_down")}
		cursor = not cursor
		if #signal > 0 then
			cursor = false
			if signal[4] == 28 then 
				return text
			elseif signal[4] == 14 then 
				text = text:sub(1,-2)  
			else
				text = text .. tostring(convertCode(signal[3]))
			end
		end
	end
end

function graphics.drawInfo(label,strTbl)
	local h = #strTbl + 2
	local w =  unicode.len(label)+2
	for _, str in pairs(strTbl) do
		w = math.max(w,unicode.len(str)+2)
	end
	local sW,sH = buffer.getResolution()
	local x,y = (sW-w)/2,(sH-h)/2
	x,y,w,h = math.floor(x+0.5),math.floor(y+0.5),math.floor(w+0.5),math.floor(h+0.5)
	local screen = buffer.copy(x,y,w,h)
	buffer.drawRectangle(x,y,w,h,graphics.theme.infoWindow.background,0x0," ")
	for i = 1, #strTbl do
		buffer.drawText(x+1,y+i,graphics.theme.infoWindow.foreground,strTbl[i])
	end
	graphics.drawButton(x,y,w,1,label,graphics.theme.infoWindow.background,graphics.theme.infoWindow.foreground)
	graphics.drawButton(x,y+h-1,w,1,core.getLanguagePackages().OS_close,graphics.theme.infoWindow.buttonBack,graphics.theme.infoWindow.buttonFore)
	graphics.drawChanges()
	event.pull("touch")
	buffer.paste(x,y,screen)
	graphics.drawChanges()
end

local float = {}
function graphics.addDrawDaemon(name,func)
	float[name] = func
end

function graphics.resetDrawDaemons()
	float = {}
end

function graphics.drawChanges()
	for _, value in pairs(float) do
		core.pcall(value)
	end
	buffer.drawChanges()
end

function graphics.clearSandbox()
	local sW, sH = buffer.getResolution()
	buffer.drawRectangle(1,2,sW,sH-2,0x000000,0xFFFFFF," ")
end

return graphics
