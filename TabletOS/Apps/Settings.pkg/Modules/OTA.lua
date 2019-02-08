local core = require("TabletOSCore")
local graphics = require("TabletOSGraphics")
local buffer = require("doubleBuffering")
local internet = require("internet")
local w,h = buffer.getResolution()
local function request(options,handler)
  local success,response = pcall(internet.request,options.url,options.post,options.headers)
  if success then
    if response then
      local responseCode, responseName, responseHeaders
      while not responseCode do
        responseCode, responseName, responseHeaders = response.response()
      end
      local buffer = ""
      repeat
        local data, reason = response.read()
        if data then
          --print("Downloaded packet size ",#data)
          buffer = buffer .. data
        elseif reason then 
          response.close() 
          error(tostring(reason))
        end
      until not data
      response.close()
      --print("Download complete")
      return handler(buffer,responseCode,responseName,responseHeaders)
    else
      error("No response!")
    end
  else
    error(tostring(responce))
  end
end

local updateChannelSelectScreen = {}

do
	local data = request({url="https://raw.githubusercontent.com/HeroBrine1st/UniversalInstaller/master/projects.list"},function(data)
		local f, r = load("return " .. data)
		if not f then error(r) end
		return f() 
	end)
	local channels = {}
	for i = 1, #data do
		if data[i].name == "TabletOS" then
			channels = data[i].channels
		end
	end
	table.insert(updateChannelSelectScreen,{type="Label",name = function() 
		return core.getLanguagePackages().Settings_currUpdateChannel .. tostring(channels[core.settings.updateChannel].name)
	end})
	for i = 1, #channels do
		table.insert(updateChannelSelectScreen,{type="Button",name=function() return channels[i].name end,onClick = function() core.settings.updateChannel = i end})
	end
end

local main = {
	{name=function() return core.getLanguagePackages().Settings_OTADescription end, type="Label"},
	{name=function() return core.getLanguagePackages().Settings_prepareUpdates end, onClick=function() updater.prepare() end,type="Button"},
	{name=function() return core.getLanguagePackages().Settings_getChangelog end, onClick=function(event)
		if event.action == "UP" then 
			request({
				url = "https://raw.githubusercontent.com/HeroBrine1st/TabletOS/Stable-(meta)/changelog_" .. core.settings.language .. ".txt"
			},function(data)
				graphics.drawScrollingInfoWindow(w*0.75,h*0.6,core.getLanguagePackages().Settings_getChangelog,data)
			end)
		end
	end,type="Button"},
	{name=function() return core.getLanguagePackages().Settings_updateChannel end, onClick = function(event)
		setContentView(updateChannelSelectScreen)
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