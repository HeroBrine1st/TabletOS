local core = require("TabletOSCore")
local computer = require("computer")

local langSelect = {
	{name = function() return core.getLanguagePackages().Settings_langsel end,type="Label"},
	{type="Separator"}, 
}

for key,value in pairs(core.languages) do
	table.insert(langSelect,{name=function() return value end,onClick = function()  computer.pushSignal("ESS") core.loadLanguage(key) core.saveSettings() end,type="Button"})
end

local langAndInput = {
	{name=function() return core.getLanguagePackages().Settings_langsel end,onClick=function() setContentView(langSelect) end,type="Button"},
}

return {
	name = function() return core.getLanguagePackages().Settings_langin end,
	onClick = function()
		setContentView(langAndInput)
	end,
	section = function() return "1" end,
}