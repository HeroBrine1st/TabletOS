local buffer = require("doubleBuffering")
local graphics = require("TabletOSGraphics")
local core = require("TabletOSCore")
local unicode = require("unicode")
local event = require("event")
buffer.drawChanges(true)
local appSandbox = {1,5,sW,sH}
local theme = {
	bar = {
		background = 0x888888,
		foreground = 0xFFFFFF,
		graphBack = 0x777777,
	},
	sandbox = {
		background = 0xCCCCCC,
		foreground = 0x333333,
	}
}



local function drawSelector(options,list)
	local scroll = options.scroll
	local label = options.label or "Welcome!"
	local nextButtonLabel = options.nextButtonLabel or "Next>"
	local helpButtonLabel = options.helpButtonLabel or "Help "
	local selected = {"",0}
	scroll = math.max(scr,-(#list-1))
	scroll = math.min(scr,math.max(0,(#list-2)))
	local cY = math.floor((sH-#list)/2)
	local y = cY+scroll

	buffer.drawRectangle(1,5,sW,sH-3,theme.sandbox.background,0x0," ")
	graphics.centerText(sW/2,6,theme.sandbox.foreground,label)
	graphics.centerText(sW/2,sH-3,theme.sandbox.foreground,nextButtonLabel)
	graphics.centerText(sW/2,sH-1,theme.sandbox.background-0x444444,helpButtonLabel)
	buffer.setDrawLimit(1,7,sW,sH-6)
	for i = 1, #list do
		--graphics.centerText(sW/2,sH-i+1,0xFFFFFF,tostring(y).." "..tostring(#list).." "..tostring(scroll).." "..tostring(i).." "..tostring(cY))
		local elem = tostring(list[i])
		if i+cY-1+scroll == cY then
			graphics.centerText(sW/2,i+cY-1+scroll,theme.sandbox.foreground,">"..elem.."<")
			selected = {elem,i}
		elseif i+cY+scroll == cY or i+cY-2+scroll == cY then
			graphics.centerText(sW/2,i+cY-1+scroll,theme.sandbox.foreground,elem,0.25)
		end
	end
	buffer.setDrawLimit(table.unpack(appSandbox))
	return table.unpack(selected)
end

local function processList(options,list)
	options.scroll = options.scroll or 0
	options.helpWindowContent = options.helpWindowContent or {"Use mouse wheel or up/down arrows for select a element"}
	local nextButtonArea = {
		(sW-unicode.len(options.nextButtonLabel))/2,
		sH-3,
		(sW+unicode.len(options.nextButtonLabel))/2,
		sH-3,
	}
	local helpButtonArea = {
		(sW-unicode.len(options.nextButtonLabel))/2,
		sH-3,
		(sW+unicode.len(options.nextButtonLabel))/2,
		sH-3,
	}
	local result = {}
	while
	 true do
		result = {drawSelector(options,list)}
		buffer.drawChanges()
		local sig = {event.pull()}
		if sig[1] == "key_up" then
			local dir = 0
			if sig[4] == 200 then dir = 1 end
			if sig[4] == 208 then dir = -1 end
			options.scroll = options.scroll + dir
		elseif sig[1] == "scroll" then
			local dir = sig[5]
			scr = scr + dir
		elseif sig[1] == "touch" then
			if graphics.clickedAtArea(nextButtonArea[1],nextButtonArea[2],nextButtonArea[3],nextButtonArea[4],sig[3],sig[4]) then
				return table.unpack(result)
			elseif graphics.clickedAtArea(helpButtonArea[1],helpButtonArea[2],helpButtonArea[3],helpButtonArea[4],sig[3],sig[4]) then
				graphics.drawInfo(options.helpButtonLabel,options.helpWindowContent)
			end
		end
	end
end
local sW,sH = buffer.getResolution()
buffer.drawRectangle(1,1,sW,1,theme.bar.graphBack,0x0," ")
buffer.drawRectangle(1,2,sW,3,theme.bar.background,0x0," ")
buffer.drawText(2,3,theme.bar.foreground,"Setup Wizard")
buffer.drawChanges()
buffer.setDrawLimit(table.unpack(appSandbox))
buffer.drawChanges()
local languages = {}
local languages2 = {}
for key,value in pairs(core.languages) do
	table.insert(languages,value)
	table.insert(languages2,key)
end
local selectedLanguage,index = processList({},languages)
core.loadLanguage(languages2[i])
-- buffer.drawRectangle(1,5,sW,sH-3,theme.sandbox.background,0x0," ")
-- local timezone = graphics.drawEdit(core.getLanguagePackages().OS_enteringTimezone,{core.getLanguagePackages().OS_enterTimezone,
-- 	"",
-- 	core.getLanguagePackages().OS_enterForEnd},"0")

local timezones = {}
for i = -12,12 do
	table.insert(timezones,tostring(i))
end
local timezone,index = processList({
	scroll = 0,
	label = core.getLanguagePackages().SetuoWizard_selectTimezone,
	helpWindowContent = core.getLanguagePackages().SetupWizard_helpWindowContext,
	helpButtonLabel = core.getLanguagePackages().SetupWizard_helpButtonLabel,
},timezones)
core.settings.timezone = tonumber(timezone)

core.settings.userInit = true
core.saveSettings()
buffer.setDrawLimit(1,1,sW,sH)