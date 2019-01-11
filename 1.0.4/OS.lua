local event     =   require "event"
local buffer    =   require "doubleBuffering"
local core      =   require "TabletOSCore"
local graphics  =   require "TabletOSGraphics"
local context   =   require "TabletOSContextMenu"
local fs        =   require "filesystem"
local event     =   require "event"
local shell     =   require "shell"
local unicode   =   require "unicode"
local computer  =   require "computer"
local crypt     =   require "crypt"
local dirs      =   {
      desctop   =   "/TabletOS/Desctop/",
}

for _, dir in pairs(dirs) do
    fs.makeDirectory(dir)
end

local backgrounds = {{0x888888,0xFFFFFF},
                     {0x555555,0xFFFFFF}}
local buttonW = 20
local buttonH = 1
local function drawTable(tbl,options)
    options = options or {}
    options.deltaX = options.deltaX or 0
    options.deltaY = options.deltaY or 0
    local w,h = buffer.getResolution()
    local buttons = {}
    for i = 1, #tbl do
        local x = (i-1)*buttonW%w+1 + options.deltaX
        local y = math.floor((i-1)*buttonW/w)*buttonH+2+options.deltaY -- local y = ((i-1)*buttonW//w)*buttonH+2
        local background,foreground = table.unpack(backgrounds[i%2+1])
        local touchChecker = graphics.drawButton(x,y,buttonW,buttonH,tbl[i].name,background,foreground)
        table.insert(buttons,{check=touchChecker,callback=tbl[i].callback})
    end
    buffer.setDrawLimit(1,1,w,h)
    return buttons
end

local function drawDir(dir,page,options)
    local w,h = buffer.getResolution()
    graphics.clearSandbox()
    local files = {}
    for file in fs.list(dir) do
        files[#files+1] = file
    end
    table.sort(files)
    local bIOP = (w/buttonW)*(h-3)/buttonH --buttons in one page
    local min = bIOP*(page-1)
    local max = bIOP*page
    local files2 = {}
    for i = min, max do
        files2[#files2+1] = files[i]
    end
    files = nil
    local callbacks = {}
    local prevDir = fs.concat(dir,"..")
    callbacks[1] = {name="[..]",callback=function() return prevDir end}
    for i = 1, #files2 do
        local file = files2[i]
        local path = fs.concat(dir,file)
        local callback = function() return path end
        local name = file:sub(1,buttonW-3) .. (#file > buttonW-3 and "…" or "")
        if file:sub(-1,-1) == "/" then
            file = file:sub(1,-2)
            name = "[" .. file:sub(1,buttonW-5) .. (#file > buttonW-5 and "…" or "") .. "]"
        end
        callbacks[#callbacks+1] = {name=name,callback=callback}
    end
    local buttons = drawTable(callbacks,options)
    graphics.drawButton(1,h-1,w/2,1,core.getLanguagePackages().OS_prevPage,backgrounds[1][1],backgrounds[1][2])
    graphics.drawButton(w/2+1,h-1,w/2,1,core.getLanguagePackages().OS_nextPage,backgrounds[2][1],backgrounds[2][2])
    -- buffer.drawText(35-unicode.len(prevPage)+1,24,0xFFFFFF,prevPage)
    -- buffer.drawText(45,24,0xFFFFFF,core.getLanguagePackages().OS_nextPage)
    return buttons,bIOP
end

-------------------------------GLOBAL FUNCTIONS-------------------------------

function errorReport(file,success,reason,...)
    if success then return success,reason, ... end
    if type(reason) == "table" and reason.reason == "terminated" then return nil, "terminated" end --нахер в reason делать таблицу с единственным ключом reason?
    if reason == "interrupted" then return nil, "terminated" end
    local str = core.getLanguagePackages().OS_errorIn
    str=str:gsub("?",tostring(file))
    core.newNotification(0,"E",str,reason)
end
_G.errorReport = errorReport
function association(file)
    return core.associations[tostring(file:match("%.(%a+)$"))]
end
_G.association = association

function event.disableInterrupt()
    local event.data_signalBackup = require("process").info().data.signal
    require("process").info().data.signal = function() return false end
end

function event.enableInterrupt()
    require("process").info().data.signal = event.data_signalBackup
    event.data_signalBackup = nil
end

function screenLock()
    event.disableInterrupt()
    graphics.drawBars()
    graphics.clearSandbox()
    if core.settings.lockType == "password" then
        local accept = false
        while not accept do
            if core.settings.lockHash and #core.settings.lockHash > 0 then
                local password = graphics.drawEdit(core.getLanguagePackages().Settings_verificatingUser,{
                    core.getLanguagePackages().Settings_enterPassword,
                })
                local hash = crypt.md5(password)
                accept = hash == core.settings.lockHash
            else
                accept = true
            end
            if accept then
                event.enableInterrupt()
                return
            else
                graphics.drawInfo(core.getLanguagePackages().Settings_verificatingUser,core.getLanguagePackages().Settings_accessDenied)
            end
        end
    end
end

----------------------------------UPDATING----------------------------------
local success, reason = core.pcall(dofile,"/TabletOS/Service/Updater.lua")
if not success then
    errorReport("/TabletOS/Service/Updater.lua",success,reason)
    core.newNotification(10,"D",core.getLanguagePackages().OS_updateServiceUnavailable,reason)
    _G.updater = {}
else
    _G.updater = reason
    if updater.hasUpdate then
        core.newNotification(10,"U",core.getLanguagePackages().OS_updateAvailable,updater.lastVersName)
    end
end
----------------------------------PROGRAM LOGIC----------------------------------
screenLock()
if core.settings.userInit == "false" or not core.settings.userInit then
    local sW,sH = buffer.getResolution()
    errorReport("/TabletOS/Apps/SetupWizard.lua",core.pcall(dofile,"/TabletOS/Apps/SetupWizard.lua"))
    graphics.drawBars()
    graphics.clearSandbox()
    graphics.drawChanges()
    graphics.drawScrollingInfoWindow(sW*0.75,sH*0.6,core.getLanguagePackages().OS_faqLabel,core.getLanguagePackages().OS_faq)
end
local page = 1
local dir = dirs.desctop
local cache = {}
while true do
    local w,h = buffer.getResolution()
    local count = 0
    for file in fs.list(dir) do
        count = count + 1
    end
    graphics.clearSandbox()
    local buttons,bIOP = drawDir(dir,page)
    graphics.drawBars()
    graphics.drawChanges()
    local name,_,x,y,button,nickname = event.pull(0.5)
    if name == "touch" then
        if y == 1 and button == 0 then 
            graphics.processStatusBar(x,y)
            graphics.drawBars()
            graphics.drawChanges()
        elseif graphics.clickedAtArea(1,2,w,h-2,x,y) then

        end
    elseif name == "drop" then
        if x == 1 and y == h then
            local file = graphics.drawMenu()
            if file then 
                core.executeFile(file)
            end
        elseif y == h-1 then
            if x < w/2+1 then 
                page = math.max(1,page-1)
            elseif x > w/2 then
                page = math.min(math.ceil(count/bIOP),page+1)
            end
        elseif graphics.clickedAtArea(1,2,w,h-2,x,y) then
            local xFile
            local noContext
            for i = 1, #buttons do
                if buttons[i].check(x,y) then
                    xFile = buttons[i].callback()
                    if i == 1 then noContext = true end
                    break
                end
            end
            if xFile then
                local pathToLink
                local isFromLink = false
                local pathToFile
                if xFile:sub(-4) == ".lnk" and not fs.isDirectory(xFile) then
                    local success, reason = core.pcall(dofile,xFile)
                    errorReport(xFile,success,reason)
                    if success then
                        isFromLink = true
                        pathToFile = fs.path(reason)
                        pathToLink = xFile
                        xFile = reason
                    end
                end
                if button == 0 then
                    if not fs.isDirectory(xFile) then
                        if association(xFile) == "execute" then 
                            local success, reason = core.pcall(dofile,xFile)
                            errorReport(xFile,success,reason)
                        elseif association(xFile) == "edit" then
                            os.execute("edit " .. "\"" .. xFile .. "\"")
                        end
                        buffer.drawChanges(true)
                    else
                        if xFile:sub(-4) == ".pkg" and not noContext then
                            core.executeFile(xFile)
                        else
                            page = 1
                            dir = xFile
                        end
                    end
                elseif button == 1 and not noContext then
                    local cX,cY = x+1,y+1
                    local contextMenu
                    if not fs.isDirectory(xFile) then
                        contextMenu = context.contextMenuForFile(xFile)
                    else
                        contextMenu = context.contextMenuForDir(xFile)
                    end
                    if isFromLink then
                        table.insert(contextMenu,2,{name = core.getLanguagePackages().OS_pathToElement,
                            callback = function()
                                return "newdir", pathToFile
                            end
                        })
                        local pos
                        for i = 1, #contextMenu do
                            if contextMenu[i].name == core.getLanguagePackages().OS_remove then pos = i break end
                        end
                        contextMenu[pos]={name = core.getLanguagePackages().OS_remove,
                            callback = function()
                                fs.remove(pathToLink)
                            end
                        }
                    end
                    local action, meta = graphics.drawContextMenu(cX,cY,contextMenu)
                    if action == "newdir" then dir = meta end
                end
            else
                if button == 1 then
                    local cX,cY = x+1,y+1
                    graphics.drawContextMenu(cX,cY,context.contextMenuForThis(dir))
                end
            end
        end
    end
end