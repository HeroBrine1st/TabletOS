local core = require("TabletOSCore")
local graphics = require("TabletOSGraphics")
local HOME = "/apps/Launcher.lua"
local apps = "/apps/"
_G.applications = {}
local fs = require("filesystem")
local MT = require("MTCore")

for file in fs.list(apps) do
	file = fs.concat(apps,file)
	if file ~= HOME then
		local success, name = pcall(dofile,file)
		table.insert(_G.applications,{file=file,name=name})
	end
end
table.sort(_G.applications,function(a,b) return a.name < b.name end)

while true do
	local nextFile = nextFile or HOME
	if MT.running == nil then
		local func = loadfile("/service/zygote.lua")
		local i = MT.create(func,nextFile)
		local success, reason = MT.resume(i,loadfile(nextFile),"OPEN_APP")
		graphics.clearSandbox()
		if success then nextFile = reason end
		--if not success then graphics.errorFrame(name,reason) end
	end
end
