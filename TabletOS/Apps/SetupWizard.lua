local buffer = require("doubleBuffering")
local graphics = require("TabletOSGraphics")
local core = require("TabletOSCore")
local unicode = require("unicode")
local event = require("event")
buffer.drawChanges(true)
local sW,sH = buffer.getResolution()
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
	scroll = math.max(scroll,-(#list-1))
	scroll = math.min(scroll,0)
	local centerIndex = scroll + #list
	local cY = math.floor(sH/2)
	local y = cY+scroll
	buffer.drawRectangle(1,5,sW,sH-3,theme.sandbox.background,0x0," ")
	graphics.centerText(sW/2,6,theme.sandbox.foreground,label)
	graphics.centerText(sW/2,sH-3,theme.sandbox.foreground,nextButtonLabel)
	graphics.centerText(sW/2,sH-1,theme.sandbox.background-0x444444,helpButtonLabel)
	--graphics.centerText(sW/2,sH,0x000000,tostring(scroll))
	buffer.setDrawLimit(1,7,sW,sH-6)
	for i = 1, #list do
		--graphics.centerText(sW/2,sH-i+1,0x000000,tostring(y).." "..tostring(#list).." "..tostring(scroll).." "..tostring(i).." "..tostring(cY).." "..tostring(i+cY-1+scroll))
		local elem = tostring(list[i])
		if i == centerIndex then
			graphics.centerText(sW/2,cY,theme.sandbox.foreground,">"..elem.."<")
			selected = {elem,i}
			graphics.centerText(sW/2,sH,0x000000,elem)
		elseif i == centerIndex + 1 or i == centerIndex-1 then
			graphics.centerText(sW/2,cY + (centerIndex-i),theme.sandbox.foreground,elem,0.25)
		end
	end
	buffer.setDrawLimit(table.unpack(appSandbox))
	return table.unpack(selected)
end

local function processList(options,list)
	options.scroll = options.scroll or 0
	options.helpWindowContent = options.helpWindowContent or {"Use mouse wheel or up/down arrows for select a element"}
	options.nextButtonLabel = options.nextButtonLabel or "Next>"
	options.helpButtonLabel = options.helpButtonLabel or "Help "
	local nextButtonArea = {
		(sW-unicode.len(options.nextButtonLabel))/2,
		sH-3,
		(sW+unicode.len(options.nextButtonLabel))/2,
		sH-3,
	}
	local helpButtonArea = {
		(sW-unicode.len(options.nextButtonLabel))/2,
		sH-1,
		(sW+unicode.len(options.nextButtonLabel))/2,
		sH-1,
	}
	local result = {}
	while true do
		options.scroll = math.max(options.scroll,-(#list-1))
		options.scroll = math.min(options.scroll,0)
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
			options.scroll = options.scroll + dir
		elseif sig[1] == "touch" then
			if graphics.clickedAtArea(nextButtonArea[1],nextButtonArea[2],nextButtonArea[3],nextButtonArea[4],sig[3],sig[4]) then
				return table.unpack(result)
			elseif graphics.clickedAtArea(helpButtonArea[1],helpButtonArea[2],helpButtonArea[3],helpButtonArea[4],sig[3],sig[4]) then
				graphics.drawInfo(options.helpButtonLabel,options.helpWindowContent)
			end
		end
	end
end
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
core.loadLanguage(languages2[index])
-- buffer.drawRectangle(1,5,sW,sH-3,theme.sandbox.background,0x0," ")
-- local timezone = graphics.drawEdit(core.getLanguagePackages().OS_enteringTimezone,{core.getLanguagePackages().OS_enterTimezone,
-- 	"",
-- 	core.getLanguagePackages().OS_enterForEnd},"0")

local timezones = {}
for i = -12,12 do
	local zone = i
	if i > 0 then zone = "+" .. tostring(zone) end
	zone = "GMT" .. zone
	if i == 0 then zone = "ZERO" end
	table.insert(timezones,zone)
end
local timezone,index = processList({
	scroll = -12,
	label = core.getLanguagePackages().SetupWizard_selectTimezone,
	helpWindowContent = core.getLanguagePackages().SetupWizard_helpWindowContent,
	helpButtonLabel = core.getLanguagePackages().SetupWizard_helpButtonLabel,
	nextButtonLabel = core.getLanguagePackages().SetupWizard_nextButtonLabel,
},timezones)
core.settings.timezone = index-13

core.settings.userInit = true
buffer.setDrawLimit(1,1,sW,sH)