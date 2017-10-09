local fs = require("filesystem")
local component = require("component")
local gpu = component.gpu
local ecs = require("ECSAPI")
local term = require("term")
local unicode = require("unicode")
local zygote = require("zygote")
local Math = math
local shell =  require("shell")
local pm = require("pm")
local oldPixelsM = {}
local w,h = gpu.getResolution()
local core = require("TabletOSCore")
OSAPI.init()
gpu.setBackground(0x610B5E)
gpu.setForeground(0xFFFFFF)
gpu.set(1,1,core.getLanguagePackages().fileManager)
component = nil
local form = zygote.addForm()
form.left=1
form.top=2
form.W=80
form.H=23
form.color=0xCCCCCC

local function setActiveForm()
form:setActive()
end
local function stopForm(view)
zygote.stop(form)
end
local currentPath = "/"
local oldFormPixels
shell.execute("cd" .. currentPath)	





local list = form:addList(1,2,function(view)
local value = view.items[view.index]

if value == ".." then 
shell.execute("cd ..")
currentPath = shell.getWorkingDirectory()
end
if fs.isDirectory(value) then
	oldPath = currentPath
	currentPath = value
	view:clear()
	view:insert("/","/")
	view:insert("..","..")
	for name in fs.list(currentPath) do
view:insert(name,currentPath .. name)
end
shell.execute("cd " .. value)
elseif fs.exists(value) then
oldFormPixels = ecs.rememberOldPixels(1,1,80,25)
local windowForm = zygote.addForm()
windowForm.left = 30
windowForm.top = 12-2
windowForm.W = 20
windowForm.H = 6

windowButton1 = windowForm:addButton(1,1,"Edit",function()
OSAPI.ignoreListeners()
shell.execute("edit " .. value)
OSAPI.init()
ecs.drawOldPixels(oldFormPixels)
setActiveForm()
end)
windowButton2 = windowForm:addButton(1,2,"Execute",function()
term.clear()
OSAPI.ignoreListeners()
local success, reason = shell.execute(value)
if not success then ecs.error(reason) end
OSAPI.init()
ecs.drawOldPixels(oldFormPixels)
setActiveForm()
end)
windowButton3 = windowForm:addButton(1,3,"Remove",function()
shell.execute("rm " .. value)
ecs.drawOldPixels(oldFormPixels)
setActiveForm()
end)
local function stopFormSS()
zygote.stop(windowForm)
end
windowButton4 = windowForm:addButton(1,4,"To workTable",function()
fs.remove("/usr/table/" .. fs.name(value))
local file = io.open("/usr/table/" .. fs.name(value),"w")
local str = ""
str = str .. "dofile(\"" .. value .. "\")"
file:write(str)
file:close()
ecs.drawOldPixels(oldFormPixels)
setActiveForm()
end)
windowButton5 = windowForm:addButton(1,6,"Exit",function()
ecs.drawOldPixels(oldFormPixels)
setActiveForm()
end)
windowButton6 = windowForm:addButton(1,5,"Install",function()
pm.installApp(value,fs.name(value))
ecs.drawOldPixels(oldFormPixels)
setActiveForm()
end)
windowButton1.W=20
windowButton2.W=20
windowButton3.W=20
windowButton4.W=20
windowButton5.W=20
windowButton6.W=20
zygote.run(windowForm)

setActiveForm()
end
end)




list.W = 80
list.H = 22
list.color = 0xCCCCCC
list.fontColor = (0xFFFFFF - 0xCCCCCC)
list.border = 0
local function updateFileList()
local listBackup = list
list:clear()
list:insert("/","/")
list:insert("..","..")
for name in fs.list(currentPath) do
list:insert(name,currentPath .. name)
end
listBackup = nil
end
local newFolder = form:addButton(1,1,core.getLanguagePackages().newFolder,function()
		oldFormPixels = ecs.rememberOldPixels(1,1,80,25)
		local windowForm = zygote.addForm()
		windowForm.left = 30
		windowForm.top = 25/2-2
		windowForm.W = 20
		windowForm.H = 4

		local editor = windowForm:addEdit(1,1,function(view)
			local value = view.text
			if value then
				local newFolder = currentPath .. value
				fs.makeDirectory(newFolder)
				ecs.drawOldPixels(oldFormPixels)
				setActiveForm()
				updateFileList()
			end
		end)
		zygote.run(windowForm)
end)
newFolder.W = 20


	local newFile = form:addButton(21,1,core.getLanguagePackages().newFile,function()
		oldFormPixels = ecs.rememberOldPixels(1,1,80,25)
		local windowForm = zygote.addForm()
		windowForm.left = 30
		windowForm.top = 25/2-2
		windowForm.W = 20
		windowForm.H = 4

		local editor = windowForm:addEdit(1,1,function(view)
			local value = view.text
			if value then
				local newFile = currentPath .. value
				local f = io.open(newFile,"w")
				if f then
					f:write("")
					f:close()
				end
				ecs.drawOldPixels(oldFormPixels)
				setActiveForm()
				updateFileList()
			end
		end)
		zygote.run(windowForm)
	end)
newFile.W = 20

local updateButton = form:addButton(41,1,core.getLanguagePackages().updateFileList,updateFileList)
updateButton.W = 20
updateFileList()
local oldPixelsM
local function eventListener(_,_,x,y,button,_)
	if button == 0 and (x == 40 or x == 35) and y == 25 then
		local success, reason = pcall(stopForm)
		if not success then
			if reason then
				ecs.error("Unable to exit program:" .. reason)
			end
		end
	end
end

local event = form:addEvent("touch",eventListener)
zygote.run(form)
