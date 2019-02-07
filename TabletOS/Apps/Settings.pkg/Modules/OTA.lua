local core = require("TabletOSCore")
local graphics = require("TabletOSGraphics")
local buffer = require("doubleBuffering")
local internet = require("internet")
local w,h = buffer.getResolution()
local main = {
	{name=function() return core.getLanguagePackages().Settings_OTADescription end, type="Label"},
	{name=function() return core.getLanguagePackages().Settings_prepareUpdates end, onClick=function() updater.prepare() end,type="Button"},
	{name=function() return core.getLanguagePackages().Settings_getChangelog end, onClick=function(event)
		if event.action == "UP" then 
			local data = ""
			for chunk in internet.request("https://raw.githubusercontent.com/HeroBrine1st/TabletOS/Stable-(meta)/changelog_" .. core.settings.language .. ".txt") do
				data = data .. chunk
			end
			graphics.drawScrollingInfoWindow(w*0.75,h*0.6,core.getLanguagePackages().Settings_getChangelog,data)
		end
	end,type="Button"},
	name = function() return core.getLanguagePackages().Settings_updates end,
}

return {
	name = function() return core.getLanguagePackages().Settings_updates end,
	onClick = function()
		if not updater.hasUpdate then
			main[2] = {name=function() return core.getLanguagePackages().Settings_updates_nothing end,type="Label"}
		end
		setContentView(main)
	end,
	section = function() return "2" end,
}