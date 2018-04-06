local args = {...}
local buffer = require("buffer")
local image = require("image")
local graphics = require("TabletOSGraphics")
local event = require("event")
local MT = require("MTCore")
local zygote = {}
function zygote.listener(...)
	local signal = {...}
	if signal[1] == "touch" then
		local x,y = signal[3],signal[4]
		if y == 1 then
			event.ignore("touch",zygote.listener)
			graphics.processStatusBar(x,y)
			event.listen("touch",zygote.listener)
		elseif y == 25 and x == 1 then
			local path = graphics.drawMenu()
			if path then
				event.ignore("touch",zygote.listener)
				MT.yield(path)
				event.listen("touch",zygote.listener)
			end
		elseif
			y == 25 and x == 40 then
				event.ignore("touch",zygote.listener)
				MT.yield()
				event.listen("touch",zygote.listener)
			end
		end
	end
end

if type(args[1]) == "function" then
	event.listen("touch",zygote.listener)
	local result = {args[1](args[2])}
	event.ignore("touch",zygote.listener)
	return table.unpack(result)
end
