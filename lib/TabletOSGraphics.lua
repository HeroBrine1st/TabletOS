local core = require("TabletOSCore")
local component = require("component")
local unicode = require("unicode")
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
		-- notificationsCenter = {
		-- 	background = 0xFFFFFF,
		-- 	label = 0,
		-- 	context = 0x444444,
		-- },
		contextMenu = {
			foreground = 0x000000,
			background = 0xFFFFFF,
			pressedFore = 0xFFFFFF,
			pressedBack = 0x00FF00,
			inactiveFore = 0xCCCCCC,
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
			scrollBarFront = 0x00FF00,
			scrollBarBack = 0xFF0000,
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
	local menu = {
		{name = core.getLanguagePackages().OS_settings,callback = function() return "/TabletOS/Apps/Settings.pkg" end},
		{name = core.getLanguagePackages().OS_shutdown,contextMenu = {
			{name=core.getLanguagePackages().OS_lock,callback=function() screenLock() return false end},
			{name=core.getLanguagePackages().OS_reboot, callback = function() return "/bin/reboot.lua" end},
			{name=core.getLanguagePackages().OS_shutdown2, callback = function() return "/bin/shutdown.lua" end},},
		},
		{name=core.getLanguagePackages().OS_allPrograms,contextMenu=require("TabletOSContextMenu").contextFromDir("/TabletOS/Menu/")},
	}
	return graphics.drawContextMenu(1,sH,menu)
end

local function braileSymbol(a, b, c, d, e, f, g, h) --https://pastebin.com/5FzEuqs8 94 строка
    return unicode.char(10240 + 128*h + 64*d + 32*g + 16*f + 8*e + 4*c + 2*b + a);
end

function graphics.clickedToBarButton(x,y)
	local w,h = buffer.getResolution()
	if y == 1 then return "STATUS_BAR" end
	if y ~= h then return nil end
	local home = {math.floor(w/2),math.floor(w/2+1)}
	local back = math.floor(w/2-w*0.0625)
	local forward = math.floor(w/2+w*0.0625+1)
	if x == home[1] or x == home[2] then return "HOME" end
	if x == back then return "BACK" end
	if x == forward then return "NEXT" end
	if x == 1 then return "MENU" end
end

-- local function touchListener(name,address,x,y,button,nickname)
-- 	if button == 0 then
-- 		local result = graphics.clickedToBarButton(x,y)
-- 		if result then
-- 			event.push("TabletOS_BarClick",result)
-- 		end
-- 	end
-- end

function graphics.drawActionBar(options)
	local color = options.color
	local text = options.text
	local sW, sH = buffer.getResolution()
	local statusBarColor = color - 0x222222
	graphics.drawBars({
		statusBarBack=statusBarColor,
		statusBarFore=options.statusBarFore or (0xFFFFFF-statusBarColor),
	})
	buffer.drawRectangle(1,2,sW,3,color,0," ")
	buffer.drawText(2,3,options.textColor or 0xFFFFFF,text)
end

function graphics.drawBars(options)
	options = options or {}
	graphics.barOptions = options
	local w,h = buffer.getResolution()
	local notifications = core.getNotifications()
	local statusBarBack = options.statusBarBack or graphics.theme.bars.background
	local statusBarFore = options.statusBarFore or graphics.theme.bars.foreground
	local navBarBack = options.navBarBack or graphics.theme.bars.background
	local navBarFore = options.navBarFore or graphics.theme.bars.foreground
	if options.notifCenter then 
		statusBarBack = graphics.theme.bars.background
		statusBarFore = graphics.theme.bars.foreground
		navBarFore = graphics.theme.bars.foreground
		navBarBack = graphics.theme.bars.background
	end
	buffer.drawRectangle(1,1,w,1,statusBarBack,statusBarFore," ")
	buffer.drawRectangle(1,h,w,1,navBarBack,navBarFore," ")
	buffer.set(w/2,h,navBarBack,navBarFore,braileSymbol(0,1,1,0,1,1,1,1))
	buffer.set(w/2+1,h,navBarBack,navBarFore,braileSymbol(1,1,1,1,0,1,1,0))
	buffer.set(math.floor(w/2-w*0.0625),h,navBarBack,navBarFore,"◀")
	buffer.set(math.floor(w/2+w*0.0625+1),h,navBarBack,navBarFore,"▶")
	local nStr = ""
	for i = 1, math.min(#notifications,math.floor(w*0.875)) do
		nStr = nStr .. notifications[i].icon
	end
	nStr = nStr:sub(1,w*0.875)
	if #notifications > (w*0.875) then nStr = nStr .. "…" end
	if options.notifCenter then nStr = core.getLanguagePackages().OS_notifications end
	buffer.drawText(1,1,statusBarFore,nStr)
	buffer.set(1,h,graphics.theme.menuButton.background,graphics.theme.menuButton.foreground,"M")
	do
		local charge = math.floor(computer.energy()/computer.maxEnergy()*100+0.5)
		local str = braileSymbol(1,1,1,1,1,1,1,1) .. braileSymbol(1,1,1,1,1,1,1,1) .. braileSymbol(1,1,1,1,1,1,1,1) .. braileSymbol(0,1,1,0,0,0,0,0) .. tostring(charge) .. "%"
		core.memorySpectre()
		local RAM = "RAM:" .. text.padLeft(tostring(math.floor(computer.freeMemory()/computer.totalMemory()*100+0.5)),3) .. "%"
		if core.lowMemory then RAM = "RAM: LOW" end
		str = RAM .. " " .. str
		buffer.drawText(w-unicode.len(str)+1,1,statusBarFore,str)
		-- local fore = options.statusBarBack or graphics.theme.bars.background
		-- --if network.isActive() then fore = 0x000000 end
		-- --if network.isConnected() then fore = 0xFFFFFF end
		-- buffer.set(w-5,1,options.statusBarBack or graphics.theme.bars.background,fore,"N")
	end
end

local function padLeft(value, length, symbol)
  checkArg(1, value, "string", "nil")
  checkArg(2, length, "number")
  if not value or unicode.wlen(value) == 0 then
    return string.rep(symbol, length)
  else
    return string.rep(symbol, length - unicode.wlen(value)) .. value
  end
end


function graphics.openNotifications(y,noProcess)
	local sW, sH = buffer.getResolution()
	local notifications = core.getNotifications()
	y = y or sH
	buffer.drawRectangle(1,2,sW,y-1,graphics.theme.notifications.background,graphics.theme.notifications.foreground," ")
	graphics.centerText(sW/2+1,y,graphics.theme.notifications.foreground,"====")
	buffer.setDrawLimit(1,2,sW,y-1)
	local visible = {}
	local function redraw()
		buffer.drawRectangle(1,2,sW,y-1,graphics.theme.notifications.background,graphics.theme.notifications.foreground," ")
		graphics.centerText(sW/2+1,y,graphics.theme.notifications.foreground,"====")
		buffer.setDrawLimit(1,2,sW,y-1)
		visible = {}
		for i = 1, #notifications do
			local y1 = (i-1)*3+2
			local label = notifications[i].name
			local time = computer.uptime() - notifications[i].created
			local hours,minutes,seconds = math.floor(time/3600),math.floor(time%3600/60),math.floor(time%3600%60)
			time = padLeft(tostring(hours),2,"0") .. ":" .. padLeft(tostring(minutes),2,"0") .. ":" .. padLeft(tostring(seconds),2,"0")
			local label2 = label .. " • " .. time
			if unicode.len(label2) > sW-2 then
				label2 = unicode.sub(label,1,sW-unicode.len(time)-6) .. "… • " .. time
			end
			local text1 = tostring(notifications[i].description or "Nothing to display")
			local text2 = ""
			local textTbl = string.wrap(text1,sW)
			text1,text2 = textTbl[1] or "", textTbl[2] or ""
			if textTbl[3] then
				text2 = unicode.sub(text2,1,sW-1) .. "…"
			end
			buffer.drawText(1,y1,graphics.theme.notifications.nameFore,label2)
			buffer.drawText(sW,y1,graphics.theme.notifications.nameFore,"×")
			buffer.drawText(1,y1+1,graphics.theme.notifications.foreground,text1)
			buffer.drawText(1,y1+2,graphics.theme.notifications.foreground,text2)
			local notif = {x1 = 1, x2 = sW, y1 = y1, y2 = y1+2, index = i, text = textTbl, label = label}
			local bX1, bY1, bX2, bY2 = buffer.getDrawLimit() 
			if notif.y2 < bY2 then 
				table.insert(visible,notif)
			end
		end
		buffer.setDrawLimit(1,1,sW,sH)
	end
	redraw()
	buffer.setDrawLimit(1,1,sW,sH)
	graphics.centerText(1,sW/2,0x0,"    ")
	if (not y or y == sH) and not noProcess then
		buffer.drawChanges()
		while true do
			local name,_,x,y,_,_ = event.pull(0.5)
			if name == "touch" then
				if y == sH then
					return
				end
			elseif name == "drop" then
				if y > 1 and y < sH then
					for i = 1, #visible do
						local e = visible[i]
						if graphics.clickedAtArea(e.x1,e.y1,e.x2,e.y2,x,y) then
							if x == e.x2 and y == e.y1 then
								core.removeNotification(e.index)
							else
								graphics.drawInfo(e.label,e.text)
							end
							break
						end
					end
				end
			end
			graphics.drawBars(graphics.barOptions)
			redraw()
			buffer.drawChanges()
		end
	end
end

function graphics.processStatusBar(x,y)
	local sW, sH = buffer.getResolution()
	local copyY = 2 --поставить на 1 в случае багов
	local screen
	local bOp = graphics.barOptions
	local oldBOp = graphics.barOptions
	bOp.notifCenter = true
	local noAnimations = false
	local function preventDefault()
		oldBOp.notifCenter = false
		graphics.drawBars(oldBOp)
		buffer.paste(1,copyY,screen)
		buffer.drawChanges()
	end
	local function memorySpectre()
		if core.lowMemory then
			noAnimations = true
			screen = nil
		end
	end
	if not core.lowMemory then
		screen = buffer.copy(1,copyY,sW,sH)
	else
		noAnimations = true
	end
	graphics.drawBars(bOp)
	graphics.openNotifications(3)
	buffer.drawChanges()
	local touchX,touchY = x or 1, y or 1
	local opened = false
	while true do
		memorySpectre()
		if noAnimations then graphics.openNotifications() return end
		local signal,_,x,y,_,_ = event.pull()
		if signal == "touch" then
			touchX, touchY = x, y
		elseif signal == "drag" then
			if y < 3 then y = 3 end
			buffer.paste(1,copyY,screen)
			graphics.drawBars(bOp)
			graphics.openNotifications(y,true)
			buffer.drawChanges()
		elseif signal == "drop" then
			if y == sH then
				graphics.openNotifications(y)
				opened = true
			elseif not opened then
				if y > touchY and y-touchY > 2 then
					for i = y, sH do
						os.sleep(0.01)
						graphics.openNotifications(i)
						buffer.drawChanges()
					end
					opened = true
				else
					for j = y, 1, -1 do
						os.sleep(0.01)
						buffer.paste(1,copyY,screen)
						graphics.drawBars(bOp)
						graphics.openNotifications(j)
						buffer.drawChanges()
					end
					preventDefault()
					return
				end
			elseif opened then
				if y < sH-1 then
					for j = y, 1, -1 do
						os.sleep(0.01)
						buffer.paste(1,copyY,screen)
						graphics.drawBars(bOp)
						graphics.openNotifications(j)
						buffer.drawChanges()
					end
					preventDefault()
					return
				else
					for i = y, sH do
						os.sleep(0.01)
						graphics.openNotifications(i)
						buffer.drawChanges()
					end
					opened = true
				end
			end
		end
	end
	preventDefault()
end


-- function graphics.drawNotificationCenter(y,options)
-- 	local visible = {}
-- 	local sW,sH = buffer.getResolution()
-- 	local function drawNotification(x,y,notification,options)
-- 		local label
-- 		local height = options.height or 3
-- 		local width = options.width or sW
-- 		local textTbl = string.wrap(notification.description,width)
-- 		do
-- 			local time = computer.uptime() - notification.created
-- 			local hours,minutes,seconds = math.floor(time/3600),math.floor(time%3600/60),math.floor(time%3600%60)
-- 			time = padLeft(tostring(hours),2,"0") .. ":" .. padLeft(tostring(minutes),2,"0") .. ":" .. padLeft(tostring(seconds),2,"0")
-- 			label = unicode.sub(notification.name,1,width-unicode.len(time)-3) .. " • " .. time
-- 			if unicode.len(label) > width-2 then
-- 				label = unicode.sub(label,1,width-unicode.len(time)-5) .. " • " .. time .. "…"
-- 			end
-- 		end
-- 		buffer.drawRectangle(x,y,width,height,graphics.theme.notificationsCenter.background)
--  		buffer.drawText(x+width-1,y,graphics.theme.notificationsCenter.label,"×")
--  		buffer.drawText(x,y,graphics.theme.notificationsCenter.label,label)
--  		for i = 1, #width do
--  			local text = textTbl[i]
--  			if text then
--  				local textY = y+i
--  				local textX = x
--  				if i == #width and textTbl[i+1] then
--  					text = unicode.sub(text,1,width-1) .. "…"
--  				end
--  				buffer.drawText(textX,textY,graphics.theme.notificationsCenter.content,text)
--  			end
--  		end
-- 	end
-- 	local notifications = core.getNotifications()
-- 	local extended = options.extended
-- 	local cacheY = 2
-- 	local width = options.width or sW-4
-- 	local x = math.floor(sW/2-width/2)+1
-- 	graphics.drawBars({notifCenter = true})
-- 	buffer.setDrawLimit(1,2,sW,y)
-- 	for i = 1, notifications do
-- 		local notification = notifications[i]
-- 		notification.label = tostring(notification.label)
-- 		notification.description = tostring(notification.description)
-- 		local h = 3
-- 		if i == extended then
-- 			h = #string.wrap(notification.description,width)
-- 		end
-- 		drawNotification(x,cacheY,notification,{
-- 			height = h,
-- 			width = width,
-- 		})
-- 		cacheY = cacheY + h
-- 	end
-- 	buffer.resetDrawLimit()
-- end

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
	buffer.drawRectangle(x,y,w,h,graphics.theme.contextMenu.background,0," ")
	local coordIndexes = {}
	for i = 1, #elements do
		local element = elements[i]
		local name = " " .. element.name
		local contextMenu = element.contextMenu
		if contextMenu then 
			name = text.padRight(name,w-1).."▶"
			if element.callback then core.showGuide("ContextMenuDoubleAction") end
		end
		elements[i].newname = name
		local fore = graphics.theme.contextMenu.foreground
		if elements[i].inactive then fore = graphics.theme.contextMenu.inactiveFore end
		buffer.drawText(x,y+i-1,fore,name)
		coordIndexes[y+i-1] = i
	end
	graphics.drawChanges()
	local function isComplexElement(index)
		local element = elements[index]
		return element.contextMenu and element.callback
	end
	local function drawElement(index,selected,context)
		if index and type(index) == "number" then
			local elementY = y+index-1
			local element = elements[index]
	 		local back = selected and graphics.theme.contextMenu.pressedBack or graphics.theme.contextMenu.background
			local fore = selected and graphics.theme.contextMenu.pressedFore or graphics.theme.contextMenu.foreground
			local useContext = isComplexElement(index)
			if useContext then
				local recX = selected and (context and x+w-2 or x) or x
				local recY = elementY
				local recW = selected and (context and 2 or unicode.len(element.name) + 2) or w
				local recH = 1
				if context then
					buffer.set(x+w-2,elementY,back,fore,"▶")
					buffer.set(x+w-1,elementY,back,graphics.theme.contextMenu.foreground,"▶")
				else
					buffer.drawRectangle(recX,recY,recW,recH,back,fore," ")
					buffer.drawText(recX,recY,fore,element.newname)
					buffer.set(x+w-1,elementY,graphics.theme.contextMenu.background,graphics.theme.contextMenu.foreground,"▶")
				end
			else
	 			buffer.drawRectangle(x,elementY,w,1,back,0x0," ")
	 			buffer.drawText(x,elementY,fore,element.newname)
			end
		end
	end
	local selectedElement
	while true do
		local eventName,_2,touchX,touchY,button,nickname = event.pull(0.5)
		graphics.drawBars(graphics.barOptions)
		if eventName == "touch" then
			if button == 0 and graphics.clickedAtArea(x,y,x+w-1,y+h-1,touchX,touchY) then
				local selectedContext = touchX == x+w-1 or touchX == x+w-2
				local index = coordIndexes[touchY]
				local element = rawget(elements,index)
				if not element.inactive then
					drawElement(index,true,selectedContext)
					graphics.drawChanges()
					selectedElement = index
				end
			elseif not graphics.clickedAtArea(x,y,x+w-1,y+h-1,touchX,touchY) then
				buffer.paste(x,y,screen)
				buffer.drawChanges()
				require("computer").pushSignal(eventName,_2,touchX,touchY,button,nickname)
				break
			end
		elseif eventName == "drag" then
			if button == 0 and graphics.clickedAtArea(x,y,x+w-1,y+h-1,touchX,touchY) then
				local selectedContext = touchX == x+w-1 or touchX == x+w-2
				drawElement(selectedElement,false)
				local index = coordIndexes[touchY]
				local element = rawget(elements,index)
				if not element.inactive then
					drawElement(index,true,selectedContext)
					selectedElement = index
				else
					selectedElement = nil
				end
			else
				drawElement(selectedElement,false)
				selectedElement = nil
			end
		elseif eventName == "drop" then
			if button == 0 and graphics.clickedAtArea(x,y,x+w-1,y+h-1,touchX,touchY) then
				local selectedContext = touchX == x+w-1 or touchX == x+w-2
				selectedElement = nil
				local index = coordIndexes[touchY]
				local element = rawget(elements,index)
				if not element.inactive then
					local whatToExecute = "any"
					if element.contextMenu and element.callback then
						whatToExecute = selectedContext and "contextMenu" or "callback"
					end
					if element.contextMenu and (whatToExecute == "any" or whatToExecute == "contextMenu")then
						local cX,cY = x+w,touchY
						local contextMenu  = element.contextMenu
						if type(element.contextMenu) == "function" then
							contextMenu = contextMenu(...)
						end
						contextMenu["repeat"] = true
						local res = {graphics.drawContextMenu(cX,cY,contextMenu,...)}
						if #res > 0 then
							buffer.paste(x,y,screen)
							buffer.drawChanges()
							return table.unpack(res)
						end
					elseif element.callback and (whatToExecute == "any" or whatToExecute == "callback") then
						buffer.paste(x,y,screen)
						buffer.drawChanges()
						local res = {element.callback(...)}
						return table.unpack(res)
					end
					buffer.drawRectangle(x,touchY,w,1,graphics.theme.contextMenu.background,0x0," ")
					buffer.drawText(x,touchY,graphics.theme.contextMenu.foreground,element.newname)
				end
			end
		end
		graphics.drawChanges()
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
	local len = unicode.len(label0)
	for i = 1, #label do
		len = math.max(unicode.len(label[i]),len)
	end
	local w = math.max(len+2,20)
	w = w+w%2 --если число нечетное - добавится 1 и станет четным
	local h = 3 + #label
	local sW, sH = buffer.getResolution()
	local x,y = (sW-w)/2+1,(sH-h)/2+1
	x,y,w,h = math.floor(x+0.5),math.floor(y+0.5),math.floor(w+0.5),math.floor(h+0.5)
	local screen = buffer.copy(x,y,w,h)
	buffer.drawRectangle(x,y,w,h,graphics.theme.editMenu.background,0x0," ")
	buffer.drawRectangle(x,y,w,1,graphics.theme.editMenu.barBack,0x0," ")
	buffer.drawText(x,y,graphics.theme.editMenu.barFore,label0)
	local checkTouch = graphics.drawButton(x,y+h-1,w,1,core.getLanguagePackages().OS_continue,graphics.theme.editMenu.barBack,graphics.theme.editMenu.barFore)
	for i = 1, #label do
		graphics.centerText(sW/2,y+i,graphics.theme.editMenu.foreground,label[i])
	end
	buffer.drawText(x,y+h-2,0xFFFFFF,">")
	local visibleLen = w-2
	local cursor = true
	local textX = x+1
	local textY = y+h-2
	local fore = graphics.theme.editMenu.foreground
	local function draw()
		buffer.drawRectangle(textX,textY,w-2,1,graphics.theme.editMenu.background,0x0," ")
		local textVisible = unicode.sub(text,-visibleLen)
		textVisible = textVisible .. (cursor and " " or "█")
		buffer.drawText(textX,textY,fore,textVisible)
		buffer.drawChanges()
	end
	while true do
		draw()
		local eventName, meta0,meta1,meta2,meta3,meta4 = event.pull(0.5)
		if not eventName then cursor = not cursor else cursor = false end
		if eventName == "key_down" then
			local eventData = {
				address = meta0,
				char = meta1,
				code = meta2,
				player = meta3,
			}
			if eventData.code == 28 then
				buffer.paste(x,y,screen)
				graphics.drawChanges()
				return text
			elseif eventData.code == 14 then
				text = unicode.sub(text,1,-2)
			else
				text = text .. convertCode(eventData.char)
			end
		elseif eventName == "clipboard" then
			local eventData = {
				address = meta0,
				value = meta1,
				nickname = meta2,
			}
			text = text .. tostring(eventData.value)
		elseif eventName == "drop" then
			if checkTouch(meta1,meta2) then
				buffer.paste(x,y,screen)
				graphics.drawChanges()
				return text
			end
		elseif eventName == "touch" then
			if not graphics.clickedAtArea(x,y,x+w-1,y+h-1,meta1,meta2) then 
				buffer.paste(x,y,screen)
				graphics.drawChanges()
				return
			end
		end
	end
end

function graphics.drawInfo(label,strTbl)
	local sW,sH = buffer.getResolution()
	if type(strTbl) == "string" then strTbl = {strTbl} end
	if unicode.len(label) > sW then
		label = unicode.sub(label,1,sW-1) .. "…"
	end
	local h = #strTbl + 2
	local w =  unicode.len(label)+2
	for _, str in pairs(strTbl) do
		w = math.max(w,unicode.len(str)+2)
	end
	w = w+w%2 --если число нечетное - добавится 1 и станет четным
	local x,y = (sW-w)/2+1,(sH-h)/2+1
	x,y,w,h = math.floor(x+0.5),math.floor(y+0.5),math.floor(w+0.5),math.floor(h+0.5)
	local screen = buffer.copy(x,y,w,h)
	buffer.drawRectangle(x,y,w,h,graphics.theme.infoWindow.background,0x0," ")
	for i = 1, #strTbl do
		buffer.drawText(x+1,y+i,graphics.theme.infoWindow.foreground,strTbl[i])
	end
	graphics.drawButton(x,y,w,1,label,graphics.theme.infoWindow.background,graphics.theme.infoWindow.foreground)
	local checkTouch = graphics.drawButton(x,y+h-1,w,1,core.getLanguagePackages().OS_close,graphics.theme.infoWindow.buttonBack,graphics.theme.infoWindow.buttonFore)
	graphics.drawChanges()
	while true do
		graphics.drawBars(graphics.barOptions)
		local e = {event.pull(0.5)}
		if e[1] == "drop" then 
			if checkTouch(e[3],e[4]) then
				break
			end
		elseif e[1] == "touch" then
			if not graphics.clickedAtArea(x,y,x+w-1,y+h-1,e[3],e[4]) then break end
		elseif e[1] == "key_down" and e[4] == 28 then break end
	end
	buffer.paste(x,y,screen)
	graphics.drawChanges()
end

local function drawScrollBar(x,y,h,max,scroll,displayedH)
	if not displayedH then displayedH = 1 end
	local pos = math.floor(y+h*(scroll/max))
	local scrH = math.min(h,math.ceil(h*math.min(1,displayedH/max)))
	buffer.drawRectangle(x,y,1,h,graphics.theme.infoWindow.scrollBarBack,0x0," ")
	buffer.drawRectangle(x,pos,1,scrH,graphics.theme.infoWindow.scrollBarFront,0x0," ")
end

function graphics.drawScrollingInfoWindow(w,h,label,text)
	local sW, sH = buffer.getResolution()
	local x,y = (sW-w)/2+1,(sH-h)/2+1
	text = text:gsub("\\n","\n")
	local textTable = string.wrap(text,w-2)
	x,y,w,h = math.floor(x+0.5),math.floor(y+0.5),math.floor(w+0.5),math.floor(h+0.5)
	local screen = buffer.copy(x,y,w,h)
	local scroll = 0
	buffer.drawRectangle(x,y,w,h,graphics.theme.infoWindow.background,0x0," ")
	graphics.drawButton(x,y,w,1,label,graphics.theme.infoWindow.background,graphics.theme.infoWindow.foreground)
	local checkTouch = graphics.drawButton(x,y+h-1,w,1,core.getLanguagePackages().OS_close,graphics.theme.infoWindow.buttonBack,graphics.theme.infoWindow.buttonFore)
	for i = scroll+1, scroll+h-2 do
		buffer.drawText(x+1,y+i,graphics.theme.infoWindow.foreground,textTable[i] or "")
	end
	drawScrollBar(x+w-1,y+1,h-2,#textTable,scroll,h-2)
	buffer.drawChanges()
	buffer.setDrawLimit(x,y+1,x+w-1,y+h-2)
	while true do
		local signal, _, _x, _y, direction = event.pull(0.5)
		graphics.drawBars(graphics.barOptions)
		if signal == "scroll" then
			scroll = scroll - direction
			scroll = math.max(0,scroll)
			scroll = math.min(math.max(0,#textTable-h+2),scroll)
			buffer.drawRectangle(x,y+1,w,h-2,graphics.theme.infoWindow.background,0x0," ")
			local posY = y+1
			for i = (scroll+1), (scroll+h-2) do
				if textTable[i] then
					buffer.drawText(x+1,posY,graphics.theme.infoWindow.foreground,textTable[i])
					posY = posY+1
				else
					break
				end
			end
			drawScrollBar(x+w-1,y+1,h-2,#textTable,scroll,h-2)
		elseif signal == "drop" then
			if checkTouch(_x,_y) then
				buffer.resetDrawLimit()
				buffer.paste(x,y,screen)
				graphics.drawChanges()
				break
			end
		elseif signal == "touch" then
			if not graphics.clickedAtArea(x,y,x+w-1,y+h-1,_x,_y) then
				buffer.resetDrawLimit()
				buffer.paste(x,y,screen)
				graphics.drawChanges()
				break
			end
		end
		graphics.drawChanges()
	end
end

local float = {}
function graphics.addDrawDaemon(name,func)
	float[name] = func
end

function graphics.resetDrawDaemons()
	float = {}
end

function graphics.drawChanges(_123)
	for name, value in pairs(float) do
		core.pcall(value,name)
	end
	buffer.drawChanges(_123)
end

function graphics.clearSandbox()
	local sW, sH = buffer.getResolution()
	buffer.drawRectangle(1,2,sW,sH-2,0x000000,0xFFFFFF," ")
end

return graphics
