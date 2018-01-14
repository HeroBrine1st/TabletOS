local fs = require("filesystem")
local version = ({...})[1]
local strTW = "return \"" .. version .. "\""
fs.remove("/.version")
local f = io.open("/.version","w")
f:write(strTW)
f:close()
