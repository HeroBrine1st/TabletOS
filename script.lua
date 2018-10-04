local fs = require("filesystem")
local args = ({...})
local strTW = "return \"" .. args[2] .. "\""
local f = io.open("/TabletOS/.version","w")
f:write(strTW)
f:close()
