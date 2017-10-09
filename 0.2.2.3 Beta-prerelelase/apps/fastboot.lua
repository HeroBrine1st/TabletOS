local component = require("component")
local computer = require("computer")
local modem = component.modem
local fs = require("filesystem")
if not fs.exists("/lib/forms.lua") then os.execute("pastebin get iKzRve2g lib/forms.lua") end
local forms = require("forms")

local w, h  = component.gpu.getResolution()
io.write("Enter port:")
local port = io.read()
port = tonumber(port)
local form1 = forms.addForm()

local forceUpdate = form1:addButton(1,1,"Repair/update system",function()
modem.broadcast(port,[[local function internetRequest(url)
  local success, response = pcall(component.proxy(component.list("internet")()).request, url)
  if success then
    local responseData = ""
    while true do
      local data, responseChunk = response.read()
      if data then
        responseData = responseData .. data
      else
        if responseChunk then
         return false, responseChunk
        else
      return true, responseData
    end
    end
    end
  else
    return false, reason
  end
end




local function getFile(url,filepath)
  fastboot.print("Downloading " .. filepath)
  local success, reason = internetRequest(url)
  if success then
    filesystem.makeDirectory(filepath .. "dir")
    filesystem.remove(filepath .. "dir")
    filesystem.remove(filepath)
    local file = filesystem.open(filepath, "w")
    if file then
    filesystem.write(file,reason)
    filesystem.close(file)
    end
  else
    error(reason)
  end
end

fastboot.print("Downloading file list    ")

local success1, string = internetRequest("https://raw.githubusercontent.com/HeroBrine1st/OpenComputers/master/TabletOS/applications.txt")
if not success1 then error(string) end
local downloads = load("return" .. string,"=filelistloader")()




for i = 1, #downloads do
getFile(downloads[i].url,downloads[i].path)
end]])
end)


forceUpdate.W = w


local uninstallButton = form1:addButton(1,2,"Uninstall OS",function()
	modem.broadcast(port,[[local function internetRequest(url)
  local success, response = pcall(component.proxy(component.list("internet")()).request, url)
  if success then
    local responseData = ""
    while true do
      local data, responseChunk = response.read()
      if data then
        responseData = responseData .. data
      else
        if responseChunk then
         return false, responseChunk
        else
      return true, responseData
    end
    end
    end
  else
    return false, reason
  end
end




fastboot.print("Uninstalling OS...")
fastboot.print("Downloading file list    ")

local success1, string = internetRequest("https://raw.githubusercontent.com/HeroBrine1st/OpenComputers/master/TabletOS/applications.txt")
if not success1 then error(string) end
local downloads = load("return" .. string,"=filelistloader")()




for i = 1,#downloads do
	fastboot.print("Deleting " .. downloads[i].path)
	filesystem.remove(downloads[i].path)
end

local function getFile(url,filepath)
  fastboot.print("Downloading " .. filepath)
  local success, reason = internetRequest(url)
  if success then
    filesystem.makeDirectory(filepath .. "dir")
    filesystem.remove(filepath .. "dir")
    filesystem.remove(filepath)
    local file = filesystem.open(filepath, "w")
    if file then
    filesystem.write(file,reason)
    filesystem.close(file)
    end
  else
    error(reason)
  end
end

getFile("https://raw.githubusercontent.com/HeroBrine1st/OpenComputers/master/TabletOS/initBackup.lua","init.lua")

]])
end)


uninstallButton.W = w

local rebootButton = form1:addButton(1,3,"Reboot",function() modem.broadcast(port,[[computer.shutdown(true)]]) end)
rebootButton.W = w
local rebootButton1 = form1:addButton(1,4,"Shutdown",function() modem.broadcast(port,[[computer.shutdown()]]) end)
rebootButton1.W = w

local exitButton = form1:addButton(1,h,"Exit",function() require("term").clear() forms.stop(form1) end)
exitButton.W = w
forms.run(form1)