local graphics = require("TabletOSGraphics")
local buffer = require("DoubleBuffering")
local image = require("image")
local desctop = "/usr/Desctop/"
local apps = _G.applications
local fs = require("filesystem")
local event = require("event")
local MT = require("MTCore")
local keyboard = require("keyboard")
fs.makeDirectory(desctop)

local function centerText(x,y,fore,text)
  local x1 = x - math.floor(unicode.len(text)/2+0.5)
  buffer.text(x1,y,fore,text)
end

function drawTextTable(table1)
	local sW,sH = buffer.getResolution()
	local returning = {}
	for i = 1, #table1 do
		local stroka = math.ceil(i/4)+1
		local w = 20
		local h = 1
		local xCoord = ((i-1)*w+1) - ((stroka - 2)*sW)
		local yCoord = stroka
		local text1 = table1[i]:len() > 15 and table1[i]:sub(1,14) .. "…" or table1[i]
		if xCoord+w-1 < sW and yCoord < sH-1 then
			centerText(xCoord+math.floor(w/2),yCoord,0xFFFFFF,text1)
			local insertTable = {
			x = xCoord,
			y = yCoord,
			w = w,
			h = h,
			index = i
			}
			table.insert(returning,insertTable)
		end
	end
	return returning
end

local function clickedTo(table1,touchX,touchY)
	for i = 1, #table1 do
		local e = table1[i]
		local x = e.x
		local y = e.y
		local w = e.w
		local h = e.h
		if touchX <= x+w-1 and touchX >= x and touchY <= y+h-1 and touchY >= y then
			return i
		end
	end
	return false
end

local function main()
	graphics.clearSandbox()
	local files = {}
	for file in fs.list(desctop) do
		if not fs.isDirectory(file) then
			table.insert(files,file)
		end
	end
	if _G.wallpaper then buffer.image(1,2,image.load(_G.wallpaper)) graphics.drawBars() end
	return drawTextTable(files,1),files
end

local function allApps()
	graphics.clearSandbox()
	if _G.wallpaper then buffer.image(1,2,image.load(_G.wallpaper)) graphics.drawBars() end
	local table1 = {}
	local table2 = {}
	for name, path in pairs(_G.applications) do
		table.insert(table1,name)
		table2[name] = path
	end
end

local function convertCode(code)
	local symbol
	if code ~= 0 and code ~= 13 and code ~= 8 and code ~= 9 and code ~= 200 and code ~= 208 and code ~= 203 and code ~= 205 and code ~= 0x9D and code ~= 0x1D and code ~= 0x1D and code ~= 0x36 and code ~= 0x38 and code ~= 0xB8 and code ~= 0x2A and code ~= 0x9D then
		symbol = unicode.char(code) 
		if keyboard.isShiftDown() then symbol = unicode.upper(symbol) end
	end
	return (symbol or "")
end

local args = {...}
local thisScreen = "MAIN"
if args[1] == "OPEN_APP" then
	local desctopTable,files = main()
	while true do
		local signal, arg1,arg2,arg3,arg4,arg5 = event.pull()
		if signal == "touch" then
			local x = arg2
			local y = arg3
			if x == 35 and y == 25 then
				if thisScreen == "APP_LIST" then
					desctopTable,files = main()
					thisScreen = "MAIN"
				end
			else
				local file = files[clickedTo(desctopTable,x,y)]
				file = fs.concat(desctop,file)
				coroutine.yield(file)
			end
		elseif signal == "key_down" then
			if arg3 == 30 and keyboard.isControlDown() then
				desctopTable,files = allApps()
			end
		end
	end
end
