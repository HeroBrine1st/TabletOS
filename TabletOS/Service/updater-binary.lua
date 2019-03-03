local fs = require("filesystem")
local serialization = require("serialization")
local gpu = require("component").gpu
local term = require("term")
term.clear()
term.setCursor(1,2)
local w,h = gpu.getResolution()

_G.progress = function(progress)
 	local backLess = 0x000000
	local backMore = 0xFFFFFF
	progress = progress or 0
	local progWidth = math.floor(w*progress+0.5)
	local backup=gpu.setBackground(backLess)
	gpu.fill(1,1,w,1," ")
	gpu.setBackground(backMore)
	gpu.fill(1,1,progWidth,1," ")
	gpu.setBackground(backup)
end
local cache = {}
local origPrint = print
local function print(...)
	origPrint(...)
	progress(cache.progress)
end
local env = {
	progress = function(progress)
		progress = math.min(1,math.max(progress,0))
		cache.progress = progress
		if _G.progress then _G.progress(progress) end
	end,
	write_file = function(file,data)
		print("Writing " .. tostring(#data) .. " bytes to " .. file)
		fs.makeDirectory(fs.path(file))
		local f = io.open(file,"w")
		f:write(data)
		f:close()
	end,
	read_file = function(file)
		print("Reading " .. file)
		local f = io.open(file)
		local data = f:read("*a")
		f:close()
		return data
	end,
	echo = function(value)
		print(value)
	end,
	copy = function(file1,file2)
		print("Copying " .. file1 .. " to " .. file2)
		fs.makeDirectory(fs.path(file2))
		fs.copy(file1,file2)
	end,
	delete = function(file)
		print("Deleting " .. file)
		fs.remove(file)
	end,
	abort = function(err)
		error(err)
	end,
	parse = function(text)
		return serialization.unserialize(text)
	end,
	stringify = function(tbl)
		return serialization.serialize(tbl)
	end,
	assert = assert,
	onError = function(func)
		cache.onError = func
	end,
	package_extract_dir = function(dir,path)
		local _,_,packagePath = require("TabletOSCore").getPackageDirectory()
		local pathToDir = fs.concat(packagePath,dir)
		print("Extracting " .. dir .. " to " .. path)
		os.execute("cp " .. pathToDir .. "/* " .. path .. " -r")
	end,
}
local _,_,path = require("TabletOSCore").getPackageDirectory()
local f, r = loadfile(fs.concat(fs.path(path),"updater-script"),_,env)
if not f then 
	error(r) 
end
local success, reason = pcall(f)
if not success then  pcall(cache.onError) error(reason) end