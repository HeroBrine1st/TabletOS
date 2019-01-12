local component = require("component")
local modem = component.modem
local network = {}
local ports = {}
local connectedRouter
local networkPort = 443
local function listener(_,receiver,sender,port,distance,...)
	if port ~= networkPort then return end
	local msg = {...}
	if not ports[msg[1]] then return end
	local _port,_type,_sender = table.unpack(msg)
	
end