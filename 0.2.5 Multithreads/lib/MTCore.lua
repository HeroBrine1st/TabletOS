if not coroutine then coroutine = require("coroutine") end
local ecs = require("ECSAPI")
local computer = require("computer")
local multithread = {yielding={},all={}}
local gui = require("gui")
local gpu = require("component").gpu
local core = require("TabletOSCore")
local event = require("event")
function multithread.create(f,name)
	local thread = coroutine.create(f)
	table.insert(multithread.all,{thread=thread,name=name})
	multithread.yielding[#multithread.all] = {thread=thread,name=name,index=#multithread.all}
	return #multithread.all
end

function multithread.run(index)
	if multithread.running then 
		local thread = multithread.running.thread
		local name = multithread.running.name
		local indexR = multithread.running.index
		coroutine.yield(thread)
		multithread.running = nil
		multithread.yielding[indexR] = {thread=thread,name=name,index=indexR}
	end
	local thread, name, index = multithread.yielding[index].thread, multithread.yielding[index].name, multithread.yielding[index].index
	multithread.yielding[index] = nil
	multithread.running = {thread=thread,name=name,index=index}
	return coroutine.resume(thread,index)
end

function multithread.yield(...)
	if multithread.running then 
		local thread = multithread.running.thread
		local name = multithread.running.name
		local indexR = multithread.running.index
		coroutine.yield(...)
		multithread.running = nil
		multithread.yielding[indexR] = {thread=thread,name=name,index=indexR}
	end
end

return multithread
