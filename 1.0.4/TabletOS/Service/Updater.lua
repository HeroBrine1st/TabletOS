local component = require("component")
local serial = require("serialization")
local core = require("TabletOSCore")
local updater = {}
local fs = require("filesystem")
local internet
if component.isAvailable("internet") then
	internet = component.internet
else
	--internet = require("TabletOSNetwork").tryToInetConnect()
	error("NO INTERNET CARD // NO INTERNET CONNECTION")
end

local versions = "https://raw.githubusercontent.com/HeroBrine1st/TabletOS/master/VERSIONS.txt"
local version = dofile("/TabletOS/.version")

local function request(uri,post,headers)
	local success, handle = core.pcall(internet.request,uri,post,headers)
	if success then
		local buffer = ""
		repeat
			local chunk,reason=handle.read()
			if reason then error(tostring(reason)) end
			if chunk then buffer = buffer .. chunk end
		until not chunk
		return buffer
	else
		error(handle)
	end
end
local vers1 = request(versions)
local vers,reason = serial.unserialize(vers1)
assert(vers,reason)
local new = {}
for i = version + 1, #vers do
	table.insert(new,vers[i])
end
local changelog = ""
local filelist = {}
local hasUpdate
local lastVersion = #vers
local lastVersName
for i = 1, #new do
	if not new[i].exp then
		hasUpdate = true
		changelog = changelog .. tostring(new[i].version) .. ":" .. tostring(new[i].description[core.settings.language]) .. "\n"
		local filels,reason = serial.unserialize(request(new[i].raw))
		assert(filels,reason)
		for i = 1, #filels do
			filelist[filels[i].path] = filels[i].url
		end
		lastVersName = new[i].version
		updater.force = updater.force == nil and new.force
	end
end

updater.changelog = changelog
updater.lastVersName = lastVersName
updater.filelist = filelist
updater.hasUpdate = hasUpdate
updater.lastVersion = lastVersion
vers = nil
filelist = nil
changelog = nil

---------------------------------------------UPDATE---------------------------------------------
local term = require("term")
local text = require("text")

local function write(text)
  local _, y = term.getCursor()
  term.setCursor(1, y)
  term.write(text)
end

local function getBar(progress)
	progress = progress < 0 and 0 or progress
	progress = progress > 100 and 100 or progress
	local bar = ""
	local barCount = 15/100*progress
	for i = 1, barCount do
		bar = bar .. "="
	end
	bar = text.padRight(bar,15)
	return bar
end

local function shellProgressBar(file,progress)
	local text1 = ""
	if progress == -1 then 
		text1 = file .. " " .. " [" .. getBar(progress) .. "] 0%   " .. core.getLanguagePackages().Updater_connecting
	elseif progress >= 0 and progress < 100 then
		text1 = file .. " [" .. getBar(progress) .. "] " .. text.padRight(tostring(progress) .. "%",4) .. " " .. core.getLanguagePackages().Updater_downloading
	elseif progress == 100 then
		text1 = file .. " [" .. getBar(progress) .. "] 100%  " .. core.getLanguagePackages().Updater_downloadDone
	end
	write(text1)
end

local function download(url,path)
	fs.remove(path)
	fs.makeDirectory(fs.path(path))
	local name = fs.name(path)
	local file, reason = io.open(path,"w")
	if not file then error(tostring(reason)) end
	shellProgressBar(name,-1)
	local success, reqH = pcall(internet.request,url)
	if success then
		if reqH then
			local resCode, _1, resData
			while not resCode do
				resCode, _1, resData = reqH:response()
			end
			if resData and resData["Content-Length"] then
				local contentLength = tonumber(resData["Content-Length"][1])
				local downloadedLength = 0
				while downloadedLength < contentLength do
					local data, reason = reqH.read()
					if not data and reason then reqH.close() error(tostring(reason)) end 
					downloadedLength = downloadedLength + #data
					file:write(data)
					shellProgressBar(name,math.floor(downloadedLength/contentLength*100+0.5))
				end
				io.write("\n")
				reqH.close()
				file:close()
				if buff then return buffer end			
			else
				error(tostring(resCode) .. " " .. tostring(_1) .. " " .. ": Content-Lenght absent")
			end
		end
	else
		error(reqH)
	end
end

function updater.update()
	component.gpu.setBackground(0)
	component.gpu.setForeground(0xFFFFFF)
	require("term").clear()
	for key, value in pairs(updater.filelist) do
		download(value,key)
	end
	local f = io.open("/TabletOS/.version","w")
	f:write("return " .. tostring(updater.lastVersion))
	f:close()
	require("computer").shutdown(true)
end

if updater.force then updater.update() end

return updater
