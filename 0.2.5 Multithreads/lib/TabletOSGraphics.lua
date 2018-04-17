local core = require("TabletOSCore")
local component = require("component")
local event = require("event")
local buffer = require("doubleBuffering")
local unicode = require("unicode")
local ecs = require("ECSAPI")
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
		}
	},
}

local function centerText(x,y,fore,text)
  local x1 = x - math.floor(unicode.len(text)/2+0.5)
  buffer.text(x1,y,fore,text)
end

local function clickedAtArea(x,y,x2,y2,touchX,touchY)
  if (touchX >= x) and (touchX <= x2) and (touchY >= y) and (touchY <= y2) then return true end
  return false
end


function graphics.drawMenu()
	local menu = core.readData("menuData") or {
		{name = "fileManager",path="/apps/fileManager.lua"},
		{name = "settings",path = "/apps/settings.lua"},
		{name = "reboot", path = "/bin/reboot.lua"},
		{name = "shutdown", path = "/bin/shutdown.lua"},
	}
	core.saveData("menuData",menu)
	local sW, sH = buffer.getResolution()
	local x,y,w,h = 1,sH - #menu, 15, #menu
	local screen = buffer.copy(x,y,80,15)
	buffer.square(x,y,w,h,0xFFFFFF,0x000000," ")
	for i = 1, #menu do
		local tY = y + i - 1
		buffer.text(x,tY,0x000000,core.getLanguagePackages()[menu[i].name] or menu[i].name)
	end
	buffer.draw()
	while true do
		local _,_,tX,tY,_,_ = event.pull("touch")
		if gui.clickedAtArea(x,y,x+w-1,y+h-1,tX,tY) then
			buffer.paste(x,y,screen)
			buffer.draw()
			return menu[#menu-(sH-tY)+1].path
		else
			buffer.paste(x,y,screen)
			buffer.draw()
			break
		end
	end
end

function graphics.drawBars(nPO)
	local notifications = core.getNotifications()
	buffer.square(1,1,80,1,graphics.theme.bars.background,graphics.theme.bars.foreground," ")
	buffer.square(1,25,80,1,graphics.theme.bars.background,graphics.theme.bars.foreground," ")
	buffer.set(40,25,graphics.theme.bars.background,graphics.theme.bars.foreground,"●")
	buffer.set(35,25,graphics.theme.bars.background,graphics.theme.bars.foreground,"◀")
	buffer.set(45,25,graphics.theme.bars.background,graphics.theme.bars.foreground,"▶")
	local nStr = "#FFFFFF"
	for i = 1, math.min(#notifications,70) do
		nStr = nStr .. notifications[i].icon
	end
	nStr = nStr:sub(1,70)
	if #notifications > 70 then nStr = nStr .. "…" end
	if nPO then nStr = core.getLanguagePackages().notifications end
	buffer.formattedText(1,1,nStr)
	buffer.set(1,25,graphics.theme.menuButton.background,graphics.theme.menuButton.foreground,"M")
end

function graphics.openNotifications(y,noProcess)
	local sW, sH = buffer.getResolution()
	local notifications = core.getNotifications()
	if y then
		buffer.square(1,2,sW,y-1,graphics.theme.notifications.background,graphics.theme.notifications.foreground," ")
		centerText(sW/2,y,graphics.theme.notifications.foreground,"====")
		buffer.setDrawLimit(1,2,sW,y-1)
	else
		buffer.square(1,2,sW,sH-1,graphics.theme.notifications.background,graphics.theme.notifications.foreground," ")
		centerText(sW/2,sH,graphics.theme.notifications.foreground,"====")
		buffer.setDrawLimit(1,2,sW,sH-1)
	end
	local visible = {}
	for i = 1, #notifications do
		local y1 = (i-1)*3+2
		buffer.text(1,y1,graphics.theme.notifications.nameFore,notifications[i].name)
		local text1 = notifications[i].description
		local text2 = ""
		if #text1 > sW then text2 = text1:sub(sW+1) text1 = text1:sub(1,sW) end
		buffer.text(1,y1+1,graphics.theme.notifications.foreground,text1)
		buffer.text(1,y1+2,graphics.theme.notifications.foreground,text2)	
		local notif = {x1 = 1, x2 = sW, y1 = y1, y2 = y1+2, index = i,}
		local bX1, bY1, bX2, bY2 = buffer.getDrawLimit() 
		if notif.y2 < bY2 then 
			table.insert(visible,notif)
		end
	end
	buffer.setDrawLimit(1,1,sW,sH)
	centerText(1,sW/2,0x0,"    ")
	if (not y or y == sH) and not noProcess then
		buffer.draw()
		while true do
			local _,_,x,y,_,_ = event.pull("touch")
			if y == sH then
				return
			elseif y > 1 and y < sH then
				for i = 1, #visible do
					local e = visible[i]
					if clickedAtArea(e.x1,e.y1,e.x2,e.y2,x,y) then
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
						for i = 1, sH do
							graphics.openNotifications(i,true)
							buffer.draw()
						end
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
	buffer.draw()
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
			buffer.draw()
		elseif signal == "drop" then
			if not opened then
				if y > touchY and y-touchY > 2 then
					for i = y, sH do
						os.sleep(0.01)
						graphics.openNotifications(i)
						buffer.draw()
					end
					opened = true
				else
					for i = -y, -1 do
						local j = -i
						os.sleep(0.01)
						buffer.paste(1,2,screen)
						graphics.openNotifications(j)
						buffer.draw()
					end
					return
				end 
			elseif opened then
				if y < 23 then
					for i = -y, -1 do
						local j = -i
						os.sleep(0.01)
						buffer.paste(1,2,screen)
						graphics.openNotifications(j)
						buffer.draw()
					end
					graphics.drawBars()
					buffer.draw()
					return
				end
			end
		end
	end
end

function graphics.errorFrame(name)
	
end

function graphics.clearSandbox()
	local sW, sH = buffer.getResolution()
	buffer.square(1,2,sW,sH-2,0x000000,0xFFFFFF," ")
end

return graphics
