local contextMenu = {}
local core = require "TabletOSCore"
local graphics = require "TabletOSGraphics"
local fs = require "filesystem"
local buffer = require "doubleBuffering"
local a = {}
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
						if not fs.isDirectory(file) then os.execute("edit \"" .. fs.concat(dir,file) .. "\"") end
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
		{name = core.getLanguagePackages().OS_properties,
		 callback = function()
		 	local data, time = core.getEditTime(xFile)
		 	--if not dir == "/" then data, time =  end
		 	local properties = {
		 		core.getLanguagePackages().OS_name .. tostring(fs.name(xFile)),
		 		core.getLanguagePackages().OS_path .. tostring(fs.path(xFile)),
		 		"",
		 		core.getLanguagePackages().OS_edited .. tostring(data) .. " " .. tostring(time),
		 		core.getLanguagePackages().OS_folderType,
		 	}
		 	if not dir == "/" then 
		 		properties[3] = core.getLanguagePackages().OS_size .. tostring(a.calculateSize(xFile)) .. " " .. core.getLanguagePackages().OS_byte 
		 	end
		 	graphics.drawInfo(core.getLanguagePackages().OS_properties,properties)
		 end
		},
	}
end 




function contextMenu.contextMenuForDir(xFile)
	return {
		{name = core.getLanguagePackages().OS_open,
			callback = function() 
				return "newdir",xFile
			end 
		},
		{name=""},
		{name = core.getLanguagePackages().OS_rename,
			callback = function() 
				local newName = graphics.drawEdit(core.getLanguagePackages().OS_folderRenaming,{"",core.getLanguagePackages().OS_enterNewFolderName}) 
				return fs.rename(fs.concat(dir,xFile),fs.concat(dir,newName),fs.name(xFile))
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
			contextMenu = contextMenu.contextMenuForThis(dir)
		},
	}
end

function contextMenu.contextMenuForFile(xFile)
	return {
		{name = core.getLanguagePackages().OS_execute,
			callback = function() 
				return core.pcall(dofile,xFile)
			end 
		},
		{name=core.getLanguagePackages().OS_edit,
			callback=function() os.execute("edit " .. "\"" .. xFile .. "\"") buffer.drawChanges(true) end
		},
		{name=""},
		{name = core.getLanguagePackages().OS_rename,
			callback = function() 
				local newName = graphics.drawEdit(core.getLanguagePackages().OS_fileRenaming,{"",core.getLanguagePackages().OS_enterNewFileName}) 
				return fs.rename(fs.concat(dir,xFile),fs.concat(fir,newName),fs.name(xFile))
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
			contextMenu = contextMenu.contextMenuForThis(dir)
		},
	}
end

return contextMenu
