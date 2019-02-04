local core = require("TabletOSCore")
local graphics = require("TabletOSGraphics")
local buffer = require("doubleBuffering")
local w,h = buffer.getResolution()
local main = {
	{name=function() return core.getLanguagePackages().Settings_OTADescription end, type="Label"}
	{name=function() return core.getLanguagePackages().Settings_prepareUpdates end, onClick=function() updater.prepare() end,type="Button"},
	{name=function() return core.getLanguagePackages().Settings_getChangelog end, onClick=function() 
		graphics.drawScrollingInfoWindow(w*0.75,h*0.6,core.getLanguagePackages().Settings_getChangelog,updater.changelog)
	end,type="Button"},
}

local noUpdates = {
	{name=function() return core.getLanguagePackages().Settings_updates_nothing end,type="Label"},
}

return {
	name = function() return core.getLanguagePackages().Settings_updates end,
	onClick = function()
		if updater.hasUpdate then
			setContentView(main)
		else
			setContentView(noUpdates)
		end
	end,
	section = function() return "2" end,
}