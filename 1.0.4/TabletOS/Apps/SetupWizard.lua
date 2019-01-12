local buffer = require("doubleBuffering")
local graphics = require("TabletOSGraphics")
local core = require("TabletOSCore")
local unicode = require("unicode")
local event = require("event")
buffer.drawChanges(true)
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

local langW = 2
for _, value in pairs(core.languages) do
	langW = math.max(unicode.len(value),langW)
end
local sW,sH = buffer.getResolution()
--local _1 = graphics.theme.bars.background
--graphics.theme.bars.background = theme.bar.graphBack
--graphics.drawBars()
buffer.drawRectangle(1,1,sW,1,theme.bar.graphBack,0x0," ")
buffer.drawRectangle(1,2,sW,3,theme.bar.background,0x0," ")
buffer.drawText(2,3,theme.bar.foreground,"Setup Wizard")
buffer.drawChanges()
local appSandbox = {1,5,sW,sH}
buffer.setDrawLimit(table.unpack(appSandbox))
buffer.drawRectangle(1,5,sW,sH-3,theme.sandbox.background,0x0," ")
graphics.centerText(sW/2,6,theme.sandbox.foreground,"Welcome!")
graphics.centerText(sW/2,sH-3,theme.sandbox.foreground,"Next>")
graphics.centerText(sW/2,sH-1,theme.sandbox.background-0x444444,"Help ")
buffer.drawChanges()
local languages = {}
for _,value in pairs(core.languages) do
	table.insert(languages,value)
	--print(value)
end
--os.sleep(0.5)
local cY = math.floor((sH-#languages)/2)

local function drawLanguages(scroll)
	local selected = ""
	buffer.drawRectangle(1,5,sW,sH-3,theme.sandbox.background,0x0," ")
	graphics.centerText(sW/2,6,theme.sandbox.foreground,"Welcome!")
	graphics.centerText(sW/2,sH-3,theme.sandbox.foreground,"Next>")
	graphics.centerText(sW/2,sH-1,theme.sandbox.background-0x444444,"Help ")
	local y = cY+scroll
	buffer.setDrawLimit(1,7,sW,sH-6)
	for i = 1, #languages do
		graphics.centerText(sW/2,sH-i+1,0xFFFFFF,tostring(y).." "..tostring(#languages).." "..tostring(scroll).." "..tostring(i).." "..tostring(cY))
		local lang = tostring(languages[i])
		if i+cY-1+scroll == cY then
			graphics.centerText(sW/2,i+cY-1+scroll,theme.sandbox.foreground,">"..lang.."<")
			selected = lang
		elseif i+cY+scroll == cY or i+cY-2+scroll == cY then
			graphics.centerText(sW/2,i+cY-1+scroll,theme.sandbox.foreground,lang,0.25)
		end
	end
	buffer.setDrawLimit(table.unpack(appSandbox))
	return selected
end
local scr = 0
drawLanguages(scr)
buffer.drawChanges()
local selectedLanguage = ""
for _, value in pairs(core.languages) do
	selectedLanguage = value
	break
end
while true do
	local sig = {event.pull()}
	if sig[1] == "key_up" then
		local dir = 0
		if sig[4] == 200 then dir = 1 end
		if sig[4] == 208 then dir = -1 end
		scr = scr + dir
	elseif sig[1] == "scroll" then
		local dir = sig[5]
		scr = scr + dir
	elseif sig[1] == "touch" then
		if graphics.clickedAtArea(sW/2-3,sH-3,sW/2+3,sH-3,sig[3],sig[4]) then
			break
		elseif graphics.clickedAtArea(sW/2-3,sH-1,sW/2+3,sH-1,sig[3],sig[4]) then
			graphics.drawInfo("Help",{"Use mouse wheel or up/down arrows for select a language"})
		end
	end
	scr = math.max(scr,-(#languages-1))
	scr = math.min(scr,math.max(0,(#languages-2)))
	selectedLanguage = drawLanguages(scr)
	buffer.drawChanges()
end

for key, value in pairs(core.languages) do
	if value == selectedLanguage then 
		core.loadLanguage(key)
	end
end

buffer.drawRectangle(1,5,sW,sH-3,theme.sandbox.background,0x0," ")
local timezone = graphics.drawEdit(core.getLanguagePackages().OS_enteringTimezone,{core.getLanguagePackages().OS_enterTimezone,
	"",
	core.getLanguagePackages().OS_enterForEnd},"0")
core.settings.timezone = tonumber(timezone)
core.settings.userInit = true
core.saveSettings()
--end--
--graphics.theme.bars.background = _1
buffer.setDrawLimit(1,1,sW,sH)
