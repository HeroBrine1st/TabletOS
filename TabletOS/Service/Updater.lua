local component = require("component")
local serial = require("serialization")
local core = require("TabletOSCore")
local updater = {}
local fs = require("filesystem")
local serialization = require("serialization")
local thread = require("thread")
local internet
local pjctsURL = "https://raw.githubusercontent.com/HeroBrine1st/UniversalInstaller/master/projects.list"
if component.isAvailable("internet") then
	internet = component.internet
else
	--internet = require("TabletOSNetwork").tryToInetConnect()
	error("NO INTERNET CARD // NO INTERNET CONNECTION")
end
local metadata
if fs.exists("/TabletOS/.vMetadata") then
	local f = io.open("/TabletOS/.vMetadata","r")
	local data = f:read("*a")
	f:close()
	metadata = assert(load("return " .. data))()
end
if not metadata then
	metadata = {}
end
if not core.settings.updateChannel then
	core.settings.updateChannel = metadata.channel
else
	metadata.channel = core.settings.updateChannel
end
if not metadata.channel then
	metadata.channel = 1
	metadata.build = 0
end
local function request(options,handler)
	local success,response = pcall(internet.request,options.url,options.post,options.headers)
	if success then
		if response then
			local responseCode, responseName, responseHeaders
			while not responseCode do
				os.sleep(0)
				responseCode, responseName, responseHeaders = response.response()
			end
			local buffer = ""
			repeat
				os.sleep(0)
				local data, reason = response.read()
				if data then
					--print("Downloaded packet size ",#data)
					buffer = buffer .. data
				elseif reason then 
					response.close() 
					error(reason) 
				end
			until not data
			response.close()
			--print("Download complete")
			return handler(buffer,responseCode,responseName,responseHeaders)
		else
			error("No response!")
		end
	else
		--print("error",responce)
		--os.sleep(1)
		error(responce)
	end
end

local function findUpdates()
	--print("Finding updates")
	return request({
		url = pjctsURL,
	},function(data)
		--print("Updates got")
		data = assert(load("return " .. data))()
		for i = 1, #data do
			if data[i].name == "TabletOS" then
				local project = data[i]
				local channel = project.channels[metadata.channel]
				local filelist = channel.filelist
				return request({
					url = filelist,
				},function(data)
					data = assert(load("return " .. data))()
					if data.build > metadata.build then
						return data
					end
					return false
				end)
			end
		end
	end)
end

local function prepareToUpdate(filelist)
	os.sleep(0.1) --от даблклика, здесь реально важно
	thread.create(function()
		core.newNotification(0,"U",core.getLanguagePackages().Updater_downloadingUpdateStart,core.getLanguagePackages().Updater_downloadingUpdateStartDescription)
		local success, reason = pcall(function()
			fs.makeDirectory("/TabletOS/UpdateCache/")
			local f = io.open("/TabletOS/UpdateCache/updater-script","w")
			f:write([[local metafile = read_file("/TabletOS/.vMetadata")
metadata = parse(metafile)
echo("Backing system up")
for i = 1, #metadata.filelist do
	local file = metadata.filelist[i]
	local backpath = "/TabletOS/UpdateCache/Backup" .. file
	copy(file,backpath)
	progress(i/#metadata.filelist*0.3)
end
onError(function()
	package_extract_dir("Backup","/")
end)
echo("Installing update")
]])
			local cache = {}
			for i = 1, #filelist do
				local file = filelist[i]
				request({
					url = file.url,
				},function(data)
					local path = fs.concat("/TabletOS/UpdateCache/Files/",file.path)
					fs.makeDirectory(fs.path(path))
					local fileStream = io.open(path,"w")
					fileStream:write(data)
					fileStream:close()
					f:write("copy(\"" .. path .. "\",\"" .. file.path .. "\")\n")
					f:write("progress(" .. tostring(i/#filelist*0.5+0.3) .. ")\n")
				end)
				cache[file.path] = true
			end
			for i = 1, #metadata.filelist do
				local filepath = metadata.filelist[i]
				core.log(2,"Updater",serialization.serialize(filepath))
				if not cache[filepath] then
					f:write("delete(\"" .. filepath .. "\")\n")
					f:write("progress(" .. tostring(i/#metadata.filelist*0.1+0.8) .. ")\n")
				end
			end
			local _filelist = {}
			for i = 1, #filelist do
				local file = filelist[i]
				table.insert(_filelist,file.path)
			end
			f:write("echo(\"Updating metadata\")\n")
			f:write("metadata[\"build\"] = " .. tostring(filelist.build) .. "\n")
			f:write("metadata[\"filelist\"] = " .. serialization.serialize(_filelist) .. "\n")
			f:write("local file = stringify(metadata);\n")
			f:write("write_file(\"/TabletOS/.vMetadata\",file)\n")
			f:write("progress(1)\n")
			f:write("echo(\"Success\")\n")
			f:close()
			local f2 = io.open("/TabletOS/UpdateCache/updater-binary","w")
			f2:write([[
				local a=require("filesystem")local b=require("serialization")local c=require("component").gpu;local d=require("term")d.clear()d.setCursor(1,2)local e,f=c.getResolution()_G.progress=function(progress)local g=0x000000;local h=0xFFFFFF;progress=progress or 0;local i=math.floor(e*progress+0.5)local j=c.setBackground(g)c.fill(1,1,e,1," ")c.setBackground(h)c.fill(1,1,i,1," ")c.setBackground(j)end;local k={}local l=print;local function print(...)l(...)progress(k.progress)end;local m={progress=function(progress)progress=math.min(1,math.max(progress,0))k.progress=progress;if _G.progress then _G.progress(progress)end end,write_file=function(n,o)print("Writing "..tostring(#o).." bytes to "..n)a.makeDirectory(a.path(n))local p=io.open(n,"w")p:write(o)p:close()end,read_file=function(n)print("Reading "..n)local p=io.open(n)local o=p:read("*a")p:close()return o end,echo=function(q)print(q)end,copy=function(r,s)print("Copying "..r.." to "..s)a.makeDirectory(a.path(s))a.copy(r,s)end,delete=function(n)print("Deleting "..n)a.remove(n)end,abort=function(t)error(t)end,parse=function(u)return b.unserialize(u)end,stringify=function(v)return b.serialize(v)end,assert=assert,onError=function(w)k.onError=w end,package_extract_dir=function(x,y)local z,z,A=require("TabletOSCore").getPackageDirectory()local B=a.concat(A,x)print("Extracting "..x.." to "..y)os.execute("cp "..B.."/* "..y.." -r")end}local z,z,y=require("TabletOSCore").getPackageDirectory()local p,C=loadfile(a.concat(a.path(y),"updater-script"),z,m)if not p then error(C)end;local D,E=pcall(p)if not D then pcall(k.onError)error(E)end
			]])
			f2:close()
			core.newNotification(0,"U",core.getLanguagePackages().Updater_updateDownloaded,core.getLanguagePackages().Updater_rebootSystem)
		end)
		if not success then
			core.newNotification(0,"U",core.getLanguagePackages().Updater_failedPreparingUpdates,reason)
		end
	end):detach()
end

local updates = findUpdates()
if updates then
	--print("Updates got #2")
	updater.hasUpdate = true
	updater.lastVersName = updates.name or "No version name downloaded"
	updater.prepare = function()
		prepareToUpdate(updates)
	end
else
	updater.prepare = function() end
end

return updater