local args = ({...})[1]
local channel = args.channel
local filelist = args.filelist
local build = filelist.build

local metadata = {}
metadata.channel = channel.index
metadata.build = build
metadata.filelist = {}
for key, value in pairs(filelist) do
	if key ~= "build" then
		table.insert(filelist,key)
	end
end
local path = "/TabletOS/.vMetadata"
local f = io.open(path,"w")
f:write(require("serialization").serialize(metadata))
f:close()
