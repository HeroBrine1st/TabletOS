local core = require("TabletOSCore")

local main = {
	{name=function() return core.getLanguagePackages().Settings_installUpdates end, onClick=function() updater.update() end,type="Button"},
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
		if updater.hasUpdates then
			setContentView(main)
		else
			setContentView(noUpdates)
		end
	end,
	section = function() return "2" end,
}
