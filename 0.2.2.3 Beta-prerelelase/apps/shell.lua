local component = require("component")
local computer = require("computer")
local gpu = component.gpu
local term = require("term")
local shell = require("shell")
local ecs = require("ECSAPI")
local event = require("event")
Math = math
gpu.setResolution(gpu.maxResolution())
gpu.setBackground(0x000000)
term.clear()
local w,h = gpu.getResolution()
local function redrawBar()
	local oldB = gpu.setBackground(0xFFFFFF)
	local oldF = gpu.setForeground(0xFFFFFF-0xCCCCCC)
	if w == 160 then
		gpu.fill(1,1,w,5," ")
		local str = "Material terminal"
		gpu.set(w/2-math.floor(string.len(str)/2),3,str)
	else
		gpu.fill(1,1,w,3," ")
		local str = "Material terminal"
		gpu.set(w/2-math.floor(string.len(str)/2),2,str)
	end
	gpu.setBackground(0xCCCCCC)
	gpu.setForeground(0xFFFFFF-0xCCCCCC)
	gpu.fill(1,1,w,1," ")
	gpu.set(1,1,"Working directory: " .. require("shell").getWorkingDirectory())
	local energy = Math.floor((computer.energy()/computer.maxEnergy())*100+1)
	local str = string.gsub(string.format("%q",math.floor(computer.energy()/computer.maxEnergy()*100)+1),"\"","")
	local len = string.len(str)
	gpu.set(w-len,1,str)
	gpu.set(w,1,"%")
	gpu.setBackground(oldB)
	gpu.setForeground(oldF)
end

local function drawInput()
	local oldPixels = ecs.rememberOldPixels(1,w == 160 and h-5 or h-3,w,h)
	local oldB = gpu.setBackground(0xFFFFFF)
	local oldF = gpu.setForeground(0xFFFFFF-0xCCCCCC)
	gpu.fill(1,w == 160 and h-4 or h-2,w,w == 160 and 5 or 3," ")
	gpu.set(1,h,"Made by HeroBrine1")
	local function input()
		gpu.set(1,w == 160 and h-2 or h-1,">")
		return ecs.inputText(2,w == 160 and h-2 or h-1,w-1)
	end

	while true do
		result = input()
		if result ~= nil and result ~= "" then
			ecs.drawOldPixels(oldPixels)
			gpu.setBackground(oldB)
			gpu.setForeground(oldF)
			return result 
		end
	end
end


local function execute(command)
	local success, reason = shell.execute(command)
	if not success and not reason == "file not found" and not reason == "interrupted" then
		reason = debug.traceback(reason)
	end
	return success, reason
end

redrawBar()
while true do
	redrawBar()
	local xC, yC = term.getCursor()
	if yC < 6 then term.setCursor(1,6) end
	local path = shell.getWorkingDirectory()
	local result = drawInput()



	gpu.setBackground(0x000000)
	gpu.setForeground(0xFFFFFF)
	term.clear()
	redrawBar()
	term.setCursor(1,w == 160 and 6 or 4)

	local success, reason = execute(result)
	if not success then
		ecs.error(reason)
	end

end