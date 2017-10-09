local component = require("component")
local gpu = require("gpu")
local core = require("TabletOSCore")
local computer = require("computer")
local ecs = require("ECSAPI")
local event = require("event")
local program = {}
local function drawScreen(screen)
local BT = require("bluetooth")
end
program.mainMenu = {
	{name=function() return "Bluetooth" end,onClick=function() drawScreen(program.bluetoothScreen) end,type="Button"},
	{type="Separator"},
	{name=function() return core.getLanguagePackages().language end,onClick=function() drawScreen(program.languageScreen) end,type="Button"},
}

program.languageScreen = {
	
}

program.bluetoothScreen = {
	
}