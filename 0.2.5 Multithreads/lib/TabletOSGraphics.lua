local core = require("TabletOSCore")
local component = require("component")
local event = require("event")
local buffer = require("doubleBuffering")
local unicode = require("unicode")

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
	buffer.square(x,y,w,h,0xFFFFFF,0x000000," ")
	for i = 1, #menu do
		local tY = y + i - 1
		buffer.text(x,tY,0x000000,core.getLanguagePackages()[menu[i].name] or menu[i].name)
	end
	buffer.draw()
	while true do
		local _,_,tX,tY,_,_ = event.pull("touch")
		if gui.clickedAtArea(x,y,x+w-1,y+h-1,tX,tY) then
			return menu[#menu-(sH-tY)+1].path
		else
			break
		end
	end
end

function graphics.drawBars(nPO,draw)
	local notifications = core.getNotifications()
	--gui.setColors(graphics.theme.bars.background,graphics.theme.bars.foreground)
	buffer.square(1,1,80,1,graphics.theme.bars.background,graphics.theme.bars.foreground," ")
	buffer.square(1,25,80,1,graphics.theme.bars.background,graphics.theme.bars.foreground," ")
	buffer.set(40,25,graphics.theme.bars.background,graphics.theme.bars.foreground,"●")
	buffer.set(35,25,graphics.theme.bars.background,graphics.theme.bars.foreground,"◀")
	buffer.set(45,25,graphics.theme.bars.background,graphics.theme.bars.foreground,"▶")
	local nStr = ""
	for i = 1, math.min(#notifications,70) do
		nStr = nStr .. notifications[i].icon
	end
	if #notifications > 70 then nStr = nStr .. "..." end
	if nPO then nStr = core.getLanguagePackages().notifications end
	buffer.text(1,1,graphics.theme.bars.foreground,nStr)
	buffer.set(1,25,graphics.theme.menuButton.background,graphics.theme.menuButton.foreground,"M")
	if draw then buffer.draw() end
end

function graphics.openNotifications(y)
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
	for i = 1, #notifications do
		local y1 = (i-1)*3+2
		buffer.text(1,y1,graphics.theme.notifications.nameFore,notifications[i].name)
		local text1 = notifications[i].description
		local text2 = ""
		if #text1 > sW then text2 = text1:sub(sW+1) text1 = text1:sub(1,sW) end
		buffer.text(1,y1+1,graphics.theme.notifications.foreground,text1)
		buffer.text(1,y1+2,graphics.theme.notifications.foreground,text2)	
	end
	buffer.setDrawLimit(1,1,sW,sH)
end

function graphics.clearSandbox(draw)
	buffer.square(1,2,80,23,0x000000,0xFFFFFF," ")
	if draw then buffer.draw() end
end

return graphics
