local core = require("TabletOSCore")
local fs = require("filesystem")
local computer = require("computer")
local component = require("component")
local graphics = require("TabletOSGraphics")
local crypt = require("crypt")

local screenLock = {
	{type="Button",name=function() return core.getLanguagePackages().Settings_none end, onClick = function(event) 
		if not event.action == "UP" then return end
		core.settings.lockType = nil
		core.settings.lockHash = nil
		computer.pushSignal("ESS")
	end},
	{type="Button",name=function() return core.getLanguagePackages().Settings_password end, onClick = function(event)
		if not event.action == "UP" then return end
		local tmp = {}
		local password = graphics.drawEdit(core.getLanguagePackages().Settings_setupSecurity,{
				core.getLanguagePackages().Settings_enterNewPasswordStep1,
			})
		local passwordConfirmed = graphics.drawEdit(core.getLanguagePackages().Settings_setupSecurity,{
				core.getLanguagePackages().Settings_enterNewPasswordStep2,
			})
		if password == passwordConfirmed then
			core.settings.lockType = "password"
			core.settings.lockHash = crypt.md5(password)
			graphics.drawInfo(core.getLanguagePackages().Settings_setupSecurity,{core.getLanguagePackages().Settings_passwordInstalled})
			computer.pushSignal("ESS")
		else
			graphics.drawInfo(core.getLanguagePackages().Settings_setupSecurity,{core.getLanguagePackages().Settings_passwordNotMatch})
			computer.pushSignal("REDRAW_ALL")
		end
	end},
}

local mainScreen = {
	{type="Button",name = function() return core.getLanguagePackages().Settings_screenLock end, onClick = function(event)
		if event.action == "UP" then
			local accept = false
			if core.settings.lockType == "password" then
				if core.settings.lockHash and #core.settings.lockHash > 0 then
					local password = graphics.drawEdit(core.getLanguagePackages().Settings_verificatingUser,{
						core.getLanguagePackages().Settings_enterPassword,
					})
					local hash = crypt.md5(password)
					accept = hash == core.settings.lockHash
				end
			else
				accept = true
			end
			if accept then
				setContentView(screenLock)
			else
				graphics.drawInfo(core.getLanguagePackages().Settings_verificatingUser,core.getLanguagePackages().Settings_accessDenied)
			end
		end
	end},
}

return {
	name = function() return core.getLanguagePackages().Settings_security end,
	onClick = function() setContentView(mainScreen) end,
	section = function() return "3" end,
}