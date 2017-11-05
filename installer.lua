local component = require("component")
local computer = require("computer")
local fs = require("filesystem")
local shell = require("shell")
local event = require("event")
local unicode = require("unicode")
 local write = io.write
local read = io.read
local gpu = component.gpu
local w,h = gpu.getResolution()
gpu.setResolution(w,h)
local totalLen = 0

local function drawProgressBar(x,y,w,colorEmpty,colorFilled,progress,maxProgress)
  colorEmpty = colorEmpty or 0x000000
  colorFilled = colorFilled or 0xFFFFFF
  progress = progress or 0
  maxProgress = maxProgress or 100
  local h = 1
  local coff = w/maxProgress
  local celoe, drobnoe = math.modf(coff*progress)
  local progressVCordax
  if drobnoe > 0.5 then progressVCordax = celoe+1 else progressVCordax = celoe end
  local oldBackground = gpu.setBackground(colorEmpty)
  gpu.fill(x,y,w,1," ")
  gpu.setBackground(colorFilled)
  gpu.fill(x,y,progressVCordax,1," ")
  gpu.setBackground(oldBackground)
end

local function internetRequest(url)
  local success, response = pcall(component.internet.request, url)
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
 local success, reason = internetRequest(url)
 if success then
   fs.makeDirectory(fs.path(filepath) or "")
   fs.remove(filepath)
   local file = io.open(filepath, "w")
   if file then
   file:write(reason)
   file:close()
    end
   return reason
 else
    print("")
   error(reason)
 end
end

local versionsRAW = "https://raw.githubusercontent.com/HeroBrine1st/TabletOS/master/VERSIONS.txt"
print("Downloading versions list...")
local success, reason = internetRequest(versionsRAW)
if not success then error(reason) end
local versions = load("return " .. reason)()
gpu.setBackground(0xCCCCCC)
gpu.setForeground(0xFFFFFF-0xCCCCCC)
gpu.fill(1,1,w,h," ")
gpu.setBackground(0xFFFFFF-0xCCCCCC)
gpu.fill(31,1,1,h," ")
gpu.setBackground(0xCCCCCC)
gpu.set(1,1,"Version")
gpu.set(32,1,"Description")
local backColor = 0xCCCCCC
local foreColor = 0xFFFFFF-0xCCCCCC
local selectColor = 0x008000
local y = 2
local screen = {}
local selectedVersion
for _, version in pairs(versions) do
  table.insert(screen,{
    description = version.description,
    version = version.version, -- первая вершн - название в таблице, вторая - название переменной с таблицей, третья - название в таблице, см. вторую вершн
    raw = version.raw,
    exp = version.exp
  })
  local addly = ""
  if version.exp then addly = " EXP" end
  gpu.set(1,y,version.version .. addly)
  os.sleep(0.1)
  y = y + 1
end
gpu.setBackground(foreColor)
gpu.setForeground(backColor)
gpu.fill(1,h,w,1," ")

local function centerText(x,y,text)
  local x1 = x - math.floor(unicode.len(text)/2+0.5)
  gpu.set(x1,y,text)
end
centerText(40,h,"Install")
gpu.setBackground(backColor)
gpu.setForeground(foreColor)
local f = {}
local desy = 2
function f.printDescription(description)
  checkArg(1,description,"string")
  gpu.set(32,desy,tostring(description:sub(1,49)))
  desy = desy + 1
  if #description > 49 then f.printDescription(description:sub(50)) end
end
while true do
  local signal = {event.pull()}
  if signal[1] == "touch" and signal[4] == 25 then 
    if selectedVersion then
      local AVTU = {}
      for i = 1, #versions do
        table.insert(AVTU,versions[i])
        if versions[i].version == selectedVersion.version then break end
      end
      local FLAV = {}
      for i = 1, #AVTU do
        local success, reason = internetRequest(AVTU[i].raw)
        if not success then error(reason) end
        local filelist1,reason2 = load("return " .. reason)
        local filelist = filelist1()
        table.insert(FLAV,filelist)
      end
      local CFC = 0
      local CFD = 0
      for i = 1, #FLAV do
        for r = 1, #FLAV[i] do
          CFC = CFC + #FLAV[i][r]
        end
      end
      drawProgressBar(1,25,80,0xFF0000,0x00FF00,CFD,CFC)
      for i = 1, #FLAV do
        for r = 1, #FLAV[i] do
          gpu.fill(1,1,80,24," ")
          centerText(40,12,"Downloading " .. tostring(FLAV[i][r].path))
          getFile(FLAV[i][r].url,FLAV[i][r].path)
          CFD = CFD + 1
          drawProgressBar(1,25,80,0xFF0000,0x00FF00,CFD,CFC)
        end
      end
      local strTW = "return \"" .. selectedVersion.version .. "\""
      fs.remove("/.version")
      local f = io.open("/.version","w")
      f:write(strTW)
      f:close()
      break
    end
  elseif signal[1] == "touch" and signal[3] < 31 then
    y = 2
    gpu.fill(1,2,30,h-2," ")
    for _, version in pairs(versions) do
      local addly = ""
      if version.exp then addly = " EXP" end
      gpu.set(1,y,version.version .. addly)
      y = y + 1
    end
    desy = 2
    selectedVersion = screen[signal[4]-1]
    if selectedVersion then
      gpu.fill(32,2,49,h-2," ")
      f.printDescription(selectedVersion.description.en)
      gpu.setBackground(selectColor)
      gpu.setForeground(0xFFFFFF-selectColor)
      gpu.fill(1,signal[4],30,1," ")
      local addly = ""
      if selectedVersion.exp then 
        addly = " EXP" 
      end
      gpu.set(1,signal[4],selectedVersion.version .. addly)
      gpu.setBackground(0xCCCCCC)
      gpu.setForeground(0xFFFFFF-0xCCCCCC)
    end
  end
end

computer.shutdown(true)
