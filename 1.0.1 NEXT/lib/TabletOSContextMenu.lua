local contextMenu = {}
local core = require "TabletOSCore"
local graphics = require "TabletOSGraphics"
local fs = require "filesystem"
local buffer = require "doubleBuffering"
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
		{name = core.getLanguagePackages().OS_paste,
			callback = function()
				while fs.exists(fs.concat(dir,fs.name(copyingFile))) do
					copyingFile = copyingFile .. tostring(math.floor(math.random()*1000))
				end
				os.execute("cp -rw " .. copyingFile .. " " .. fs.concat(dir,fs.name(copyingFile)))
				if cutting then
					os.execute("rm -rf " .. copyingFile)
				end
				copyingFile = nil
				cutting = false
			end
		},
		{name = core.getLanguagePackages().OS_pastelnk,
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
			contextMenu = contextMenu.contextMenuForThis(fs.path(xFile))
		},
	}
end

function contextMenu.contextMenuForFile(xFile)
	return {
		{name = core.getLanguagePackages().OS_execute,
			callback = function() 
				return _G.errorReport(xFile,core.pcall(dofile,xFile))
			end 
		},
		{name=core.getLanguagePackages().OS_edit,
			callback=function() os.execute("edit " .. "\"" .. xFile .. "\"") buffer.drawChanges(true) end
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
				local newName = graphics.drawEdit(core.getLanguagePackages().OS_fileRenaming,{"",core.getLanguagePackages().OS_enterNewFileName}) 
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

return contextMenu
