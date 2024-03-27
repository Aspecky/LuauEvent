local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LuauEvent = require(ReplicatedStorage.LuauEvent)

return function()
	local event = LuauEvent.new()

	event.Event:Connect(function(...)
		print(...) --> 1 2 3
	end, 1)

	event:Fire(2, 3)

	return function()
		event:Destroy()
	end
end
