local event     =   require "event"
local buffer    =   require "doubleBuffering"
local graphics  =   require "TabletOSGraphics"
local core      =   require "TabletOSCore"
local context   =   require "TabletOSContextMenu"
local fs        =   require "filesystem"
local event     =   require "event"
local shell     =   require "shell"
local unicode   =   require "unicode"
local dirs      =   {
      desctop   =   "/TabletOS/Desctop/",
}

for _, dir in pairs(dirs) do
    fs.makeDirectory(dir)
end

local backgrounds = {{0x888888,0xFFFFFF},
                     {0x555555,0xFFFFFF}}
local w,h = buffer.getResolution()
local buttonW = 20
local buttonH = 1
local bIOL = w/buttonW --buttons in one layer
local function drawTable(tbl)
    buffer.setDrawLimit(1,2,w,h-1) --защита от дурака. Мало ли..
    local buttons = {}
    for i = 1, #tbl do
        local x = (i-1)*buttonW%w+1
        local y = (i-1)*buttonW//w+2
        local background,foreground = table.unpack(backgrounds[i%2+1])
        local touchChecker = graphics.drawButton(x,y,buttonW,buttonH,tbl[i].name,background,foreground)
        table.insert(buttons,{check=touchChecker,callback=tbl[i].callback})
    end
    buffer.setDrawLimit(1,1,w,h)
    return buttons
end

local function drawDir(dir,page)
    graphics.clearSandbox()
    local files = {}
    for file in fs.list(dir) do
        files[#files+1] = file
    end
    table.sort(files)
    local bIOP = bIOL*(w-3) --buttons in one page
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
        local name = file:sub(1,17) .. (#file > 17 and "…" or "")
        callbacks[#callbacks+1] = {name=name,callback=callback}
    end
    local buttons = drawTable(callbacks)
    graphics.drawButton(1,h-1,w/2,1,core.getLanguagePackages().OS_prevPage,backgrounds[1][1],backgrounds[1][2])
    graphics.drawButton(w/2+1,h-1,w/2,1,core.getLanguagePackages().OS_nextPage,backgrounds[2][1],backgrounds[2][2])
    -- buffer.drawText(35-unicode.len(prevPage)+1,24,0xFFFFFF,prevPage)
    -- buffer.drawText(45,24,0xFFFFFF,core.getLanguagePackages().OS_nextPage)
    return buttons,bIOP
end

local associations = {
    txt = "edit",
    lua = "execute",
}

function errorReport(file,success,reason,...)
    if success then return success,reason, ... end
    if type(reason) == "table" and reason.reason == "terminated" then return nil, "terminated" end --нахер в reason делать таблицу с единственным ключом reason?
    local str = core.getLanguagePackages().OS_errorIn
    str=str:gsub("?",file)
    core.newNotification(0,"E",str,reason)
end
_G.errorReport = errorReport

----------------------------------UPDATING----------------------------------
local success, reason = core.pcall(dofile,"/TabletOS/Service/Updater.lua")
if not success then
    errorReport("/TabletOS/Service/Updater.lua",success,reason)
    core.newNotification(10,"D",core.getLanguagePackages().OS_updateServiceUnavailable,reason)
else
    _G.updater = reason
    if updater.hasUpdate then
        core.newNotification(10,"U",core.getLanguagePackages().OS_updateAvailable,updater.lastVersName)
    end
end
----------------------------------PROGRAM LOGIC----------------------------------
local page = 1
local dir = dirs.desctop
while true do
    local count = 0
    for file in fs.list(dir) do
        count = count + 1
    end
    graphics.clearSandbox()
    if core.settings.userInit == "false" or not core.settings.userInit then
        errorReport("/TabletOS/Apps/SetupWizard.lua",core.pcall(dofile,"/TabletOS/Apps/SetupWizard.lua"))
        graphics.drawBars()
        graphics.clearSandbox()
        graphics.drawChanges()
        graphics.drawInfo(core.getLanguagePackages().OS_faq1,{core.getLanguagePackages().OS_faq2,
            core.getLanguagePackages().OS_faq3,
            core.getLanguagePackages().OS_faq4,
            core.getLanguagePackages().OS_faq5,})
    end
    local buttons,bIOP = drawDir(dir,page)
    graphics.drawBars()
    graphics.drawChanges()
    local _,_,x,y,button,nickname = event.pull "touch"
    if y == 1 then 
        graphics.processStatusBar(x,y)
        graphics.drawBars()
        graphics.drawChanges()
    elseif x == 1 and y == h then
        local file = graphics.drawMenu()
        if file then 
            errorReport(file,core.pcall(dofile,file))
        end
    elseif y == h-1 then
        if x < w/2+1 then 
            page = math.max(1,page-1)
        elseif x > w/2 then
            page = math.min(math.ceil(count/bIOP),page+1)
        end
    elseif graphics.clickedAtArea(1,2,w,h-2,x,y) then
        local xFile
        for i = 1, #buttons do
            if buttons[i].check(x,y) then
                xFile = buttons[i].callback()
                break
            end
        end
        if xFile then
            if button == 0 then
                if not fs.isDirectory(xFile) then
                    if xFile:sub(-3,-1) == "lnk" then
                        local success, reason = core.pcall(dofile,xFile)
                        errorReport(xFile,success,reason)
                        if success then
                            if fs.isDirectory(reason) then
                                dir = reason
                            else
                                local success1, reason1 = core.pcall(dofile,reason)
                                errorReport(reason,success1,reason1)
                            end
                        end
                    elseif associations[tostring(xFile:match("%.(%a+)$"))] == "execute" then 
                        local success, reason = core.pcall(dofile,xFile)
                        errorReport(xFile,success,reason)
                    elseif associations[tostring(xFile:match("%.(%a+)$"))] == "edit" then
                        os.execute("edit " .. "\"" .. xFile .. "\"")
                    end
                    buffer.drawChanges(true)
                else
                    dir = xFile
                end
            elseif button == 1 then
                local cX,cY = x+1,y+1
                local contextMenu
                if not fs.isDirectory(xFile) then
                    contextMenu = context.contextMenuForFile(xFile)
                else
                    contextMenu = context.contextMenuForDir(xFile)
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
