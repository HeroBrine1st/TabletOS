local fs = require("filesystem")
if fs.exists("/TabletOS/UpdateCache/updater-binary") then
	
	pcall(dofile,"/TabletOS/UpdateCache/updater-binary")
	os.execute("rm -r /TabletOS/UpdateCache")
	require("computer").shutdown(true)
end


local f,r = loadfile("/OS.lua")
if not f then error(r) end
xpcall(f,function(...)
	local str = ""
	for i = 1, #{...} do
		str = str .. " " .. ({...})[i]
	end
	io.write(str)
	if os.sleep then os.sleep(1) end
end)