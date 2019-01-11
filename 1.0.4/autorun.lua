xpcall(loadfile("/OS.lua"),function(...)
	local str = ""
	for i = 1, #{...} do
		str = str .. " " .. ({...})[i]
	end
	io.write(str)
	if os.sleep then os.sleep(1) end
end)