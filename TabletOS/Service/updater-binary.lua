local fs = require("filesystem")
local serialization = require("serialization")
local gpu = require("gpu")
local cache = {}
local env = {
	progress = function(progress)
		progress = math.min(1,math.max(progress,0))
		cache.progress = progress
		if _G.progress then _G.progress(progress) end
	end,
	write_file = function(file,data)
		local f = io.open(file,"w")
		f:write(data)
		f:close()
	end,
	read_file = function(file)
		local f = io.open(file)
		local data = f:read("*a")
		f:close()
		return data
	end,
	echo = function(value)
		print(value)
	end,
	copy = function(file1,file2)
		fs.copy(file1,file2)
	end,
	delete = function(file)
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

}
local f, r = loadfile("updater-script",_,_,env)
if not f then echo(r) return end
local success, reason = pcall(f)
if not success then echo(reason) end