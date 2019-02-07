local contextMenu   =   {}
local core          =   require "TabletOSCore"
local graphics      =   require "TabletOSGraphics"
local fs            =   require "filesystem"
local buffer        =   require "doubleBuffering"
local computer      =   require "computer"
local shell         =   require "shell"
local term          =   require "term"
local event         =   require "event"
local a = {}
local copyingFile
local cutting
function a.calculateSize(path)
    local size = 0
    for file in fs.list(path) do
        if fs.isDirectory(fs.concat(path,file)) then
            size = size + a.calculateSize(fs.concat(path,file))
        else
            size = size + fs.size(fs.concat(path,file))
        end
    end
    return size
end

function contextMenu.contextMenuForThis(dir)
    local xFile = dir
    return {
        {name = core.getLanguagePackages().OS_create,
            contextMenu = {
                {name = core.getLanguagePackages().OS_newfile,
                    callback = function()
                        local file = graphics.drawEdit(core.getLanguagePackages().OS_creatingFile,{core.getLanguagePackages().OS_enterFileName,
                            "",
                            core.getLanguagePackages().OS_enterForEnd})
                        local path = fs.concat(dir,file)
                        if not fs.isDirectory(path) then  
                            fs.makeDirectory(fs.name(path))
                            local f = io.open(path,"w") 
                            f:write("")
                            f:close()
                        end
                        buffer.drawChanges(true) 
                        return true
                    end 
                },
                {name = core.getLanguagePackages().OS_newfolder,
                    callback = function()
                        local folder = graphics.drawEdit(core.getLanguagePackages().OS_creatingFolder,{core.getLanguagePackages().OS_enterFolderName,
                            "",
                        core.getLanguagePackages().OS_enterForEnd})
                        os.execute("mkdir \"" .. fs.concat(dir,folder) .. "\"") 
                        return true
                    end
                },
            }
        },
        {name = core.getLanguagePackages().OS_paste,
            inactive = not copyingFile,
            callback = function()
                if copyingFile then
                    local name = fs.name(copyingFile)
                    local newname = name
                    local i = 1
                    while fs.exists(fs.concat(dir,newname)) do
                        local point = newname:find(".")
                        name = name:sub(1,point-1) .. " (" .. tostring(i) .. ")" .. name:sub(point)
                    end
                    os.execute("cp -rw " .. copyingFile .. " " .. fs.concat(dir,name))
                    if cutting then
                        os.execute("rm -rf " .. copyingFile)
                        copyingFile = nil
                        cutting = false
                    end
                end
            end
        },
        {name = core.getLanguagePackages().OS_pastelnk,
            inactive = not copyingFile,
            callback = function()
                if copyingFile then
                    local f = io.open(fs.concat(dir,fs.name(copyingFile)) .. ".lnk","w")
                    f:write("return \"" .. copyingFile .. "\"")
                    f:close()
                end
            end
        },
        {name = core.getLanguagePackages().OS_properties,
         callback = function()
            local data, time = core.getEditTime(xFile)
            --if not dir == "/" then data, time =  end
            local properties = {
                core.getLanguagePackages().OS_name .. tostring(fs.name(xFile)),
                core.getLanguagePackages().OS_path .. tostring(fs.path(xFile)),
                core.getLanguagePackages().OS_edited .. tostring(data) .. " " .. tostring(time),
                core.getLanguagePackages().OS_folderType,
            }
            if not dir == "/" then 
                table.insert(properties,3,core.getLanguagePackages().OS_size .. tostring(a.calculateSize(xFile)) .. " " .. core.getLanguagePackages().OS_byte)
            end
            graphics.drawInfo(core.getLanguagePackages().OS_properties,properties)
         end
        },
        {name=""},
        {name=core.getLanguagePackages().OS_executeCommand,
        callback = function()
            local _tmp = shell.getWorkingDirectory()
            shell.setWorkingDirectory(dir)
            local io_write = io.write
            local writtedToShell = false
            io.write = function(...)
                if not writtedToShell and ({...})[1]:len() > 0 then
                    term.clear()
                    writtedToShell = true
                end
                io_write(...)
            end
            local command = graphics.drawEdit(core.getLanguagePackages().OS_executingCommand,{core.getLanguagePackages().OS_enterCommand,
                "",
                core.getLanguagePackages().OS_enterForEnd})
            local success, reason = shell.execute(command)
            shell.setWorkingDirectory(_tmp)
            io.write = io_write
            if writtedToShell then
                print(core.getLanguagePackages().OS_enterForEnd)
                event.pull("key_down")
            end
            if not success then
                if not reason:match("interrupted") then
                    local str = core.getLanguagePackages().OS_errorInCommand
                    str=str:gsub("?",command)
                    core.newNotification(0,"E",str,reason)
                end
            end
            buffer.drawChanges(true)
        end}
    }
end 




function contextMenu.contextMenuForDir(xFile)
    local conMenu = {
        {name = core.getLanguagePackages().OS_open,
            callback = function() 
                return "newdir",xFile
            end 
        },
        {name=""},
        {name=core.getLanguagePackages().OS_copy,
            callback = function()
                copyingFile = xFile
                cutting = false
            end,
        },
        {name=core.getLanguagePackages().OS_cut,
            callback = function()
                copyingFile = xFile
                cutting = true
            end,
        },
        {name=""},
        {name = core.getLanguagePackages().OS_rename,
            callback = function() 
                local newName = graphics.drawEdit(core.getLanguagePackages().OS_folderRenaming,{"",core.getLanguagePackages().OS_enterNewFolderName}) 
                return fs.rename(xFile,fs.concat(fs.path(xFile),newName))
            end 
        },
        {name = core.getLanguagePackages().OS_remove,
            callback = function() 
                return os.execute("rm \"" .. xFile .. "\" -r")
            end 
        },
        {name = core.getLanguagePackages().OS_properties,
         callback = function()
            local data, time = core.getEditTime(xFile)
            local properties = {
                core.getLanguagePackages().OS_name .. tostring(fs.name(xFile)),
                core.getLanguagePackages().OS_path .. tostring(fs.path(xFile)),
                core.getLanguagePackages().OS_size .. tostring(a.calculateSize(xFile)) .. " " .. core.getLanguagePackages().OS_byte,
                core.getLanguagePackages().OS_edited .. tostring(data) .. " " .. tostring(time),
                core.getLanguagePackages().OS_folderType,
            }
            graphics.drawInfo(core.getLanguagePackages().OS_properties,properties)
         end
        },
        {name=""},
        {name = core.getLanguagePackages().OS_this,
            contextMenu = contextMenu.contextMenuForThis(fs.path(xFile))
        },
    }
    if xFile:sub(-4) == ".pkg" then
        conMenu[1] = {name = core.getLanguagePackages().OS_open,
            callback = function() 
                return core.executeFile(xFile)
            end 
        }
        table.insert(conMenu,2,{name = core.getLanguagePackages().OS_openAsDir,
            callback = function() 
                return "newdir",xFile
            end
        })
    end
    return conMenu
end

function contextMenu.contextMenuForFile(xFile)
    return {
        {name = core.getLanguagePackages().OS_execute,
            callback = function()
                local _a = {_G.errorReport(xFile,core.pcall(dofile,xFile))}
                buffer.drawChanges(true)
                return table.unpack(_a)
            end 
        },
        {name=core.getLanguagePackages().OS_edit,
            callback=function() os.execute("edit " .. "\"" .. xFile .. "\"") buffer.drawChanges(true) return true end
        },
        {name=core.getLanguagePackages().OS_rewrite,
            callback=function()
                fs.remove(xFile)
                os.execute("edit " .. "\"" .. xFile .. "\"") 
                buffer.drawChanges(true)
            end
        },
        {name=""},
        {name=core.getLanguagePackages().OS_copy,
            callback = function()
                copyingFile = xFile
                cutting = false
            end,
        },
        {name=core.getLanguagePackages().OS_cut,
            callback = function()
                copyingFile = xFile
                cutting = true
            end,
        },
        {name=""},
        {name = core.getLanguagePackages().OS_rename,
            callback = function() 
                local newName = graphics.drawEdit(core.getLanguagePackages().OS_fileRenaming,{"",core.getLanguagePackages().OS_enterNewFileName},fs.name(xFile)) 
                return fs.rename(xFile,fs.concat(fs.path(xFile),newName))
            end 
        },
        {name = core.getLanguagePackages().OS_remove,
            callback = function() 
                return fs.remove(xFile)
            end 
        },
        {name = core.getLanguagePackages().OS_properties,
         callback = function()
            local data, time = core.getEditTime(xFile)
            local properties = {
                core.getLanguagePackages().OS_name .. fs.name(xFile),
                core.getLanguagePackages().OS_path .. fs.path(xFile),
                core.getLanguagePackages().OS_size .. tostring(fs.size(xFile)) .. " " .. core.getLanguagePackages().OS_byte,
                core.getLanguagePackages().OS_edited .. tostring(data) .. " " .. tostring(time),
                core.getLanguagePackages().OS_fileType .. tostring(xFile:match("%.(%a+)$")):upper()
            }
            graphics.drawInfo(core.getLanguagePackages().OS_properties,properties)
         end
        },
        {name=""},
        {name = core.getLanguagePackages().OS_this,
            contextMenu = contextMenu.contextMenuForThis(fs.path(xFile))
        },
    }
end

function contextMenu.contextFromDir(dir)
    local context = {}
    fs.makeDirectory(dir)
    local hasFiles
    for file in fs.list(dir) do
        hasFiles = true
        local obj = fs.concat(dir,file)
        if fs.isDirectory(obj) then
            if obj:sub(-4) == ".pkg" then
                table.insert(context,{name=file:sub(1,-2),callback = function() return obj end})
            else
                table.insert(context,{name=file:sub(1,-2),contextMenu=function() return contextMenu.contextFromDir(obj) end})
            end
        else
            table.insert(context,{name=file,callback=function()
                if file:sub(-3,-1) == "lnk" then
                    local success, reason = core.pcall(dofile,obj)
                    errorReport(file,success,reason)
                    if success then return reason end
                elseif _G.association(obj) == "EXECUTE" then
                    return obj
                elseif _G.association(obj) == "EDIT" then
                    os.execute("edit \"" .. obj .. "\"")
                else
                    return obj
                end
                buffer.drawChanges(true)
                return false --что бы цепочка завершилась
            end,contextMenu = function()
                return contextMenu.contextMenuForFile(obj)
            end})
        end
    end
    if not hasFiles then table.insert(context,{name=core.getLanguagePackages().OS_empty}) end
    table.sort(context,function(a,b) return a.name < b.name end)
    return context
end

return contextMenu